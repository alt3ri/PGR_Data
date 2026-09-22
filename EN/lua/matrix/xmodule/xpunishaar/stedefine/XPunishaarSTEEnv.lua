local STEEnv = require("STEVM/STEEnv")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local BuffEntity = require("XModule/XPunishaar/STEDefine/Entities/BuffEntity")
local XPunishaarInstruction = require("XModule/XPunishaar/STEDefine/XPunishaarInstruction")
local XPresentEventBus = require("XModule/XPunishaar/STEDefine/XPresentEventBus")

--- 大巴扎业务派生 STE 环境
--- 在框架 STEEnv 之上挂载业务级 env 服务：目前是 BuffEntity 对象池（单局尺度）。
--- 好处：池天然拿到 env 生命周期（随 env 消亡、多局隔离），框架 STEEnv 保持不认识业务实体；
---   且 vm:GetEnv() 返回本派生实例，业务 Effect/Selector 可直接调 AcquireBuff/ReturnBuff。
---@class XPunishaarSTEEnv : STEEnv
---@field _BuffFreeStack XStack 空闲 BuffEntity 栈（复用空壳）
---@field _EventBus XPresentEventBus 表现层事件总线（单局尺度）
---@field _InstructionFreeStack XStack 空闲 XPunishaarInstruction 栈（复用，仿 _BuffFreeStack 范式）#76
---@field _SchedByTick table<number, XPunishaarInstruction[]> 时间轮分桶：landTick→bucket list（#77 替换 _SchedInstructions 有序列表）
---@field _TxnPendingSchedule XPunishaarInstruction[] 事务内暂存的排程指令（方式1：CommitTxn flush 入桶、RollbackTxn 回池）#76
local XPunishaarSTEEnv = XClass(STEEnv, "XPunishaarSTEEnv")

function XPunishaarSTEEnv:Ctor(seed)
    -- 父类 STEEnv:Ctor(seed) 由 XClass.New 自动调用（父先子后），此处只补业务字段。
    self._BuffFreeStack = XStack.New()
    -- 表现层事件总线：承接 vm:Emit，帧尾抽干派发
    self._EventBus = XPresentEventBus.New()

    -- 攻击特效 payload 帧级缓冲：[{ownerId, targetId}, ...]
    -- 复用 table（预分配槽，Drain 后 wipe 计数不清 table，零 GC）；与 groupIdBuffer 复用范式一致 #73
    self._AttackEffectList = {}
    self._AttackEffectCount = 0

    -- 落地伤害飘字缓冲（Instruction.Execute Append / 帧末 DrainDamageLanded 取；复用 table 零 GC，同 _AttackEffectList）
    self._DamageLandedList = {}
    self._DamageLandedCount = 0

    -- 待落地伤害时间轮（#77 优化：有序列表 _SchedInstructions + table.remove(1) pop 改 _SchedByTick hash map 分桶）
    -- _SchedByTick：landTick→bucket list，O(1) 入桶/空转/pop（Drain 命中 curTick 桶整桶清），O(n) 生效（遍历桶 Execute）
    --   同 landTick 多攻击共桶（一帧多卡打同 target 各算各 landTick，但 delay 常数一致→同桶）；无插入排序无 head 索引。
    -- _TxnPendingSchedule：事务内 ScheduleDamage 暂存（不入 _SchedByTick），CommitTxn flush 入桶、RollbackTxn 回池；
    -- _InstructionFreeStack：空闲 Instruction 栈（仿 _BuffFreeStack），Acquire 取/Return 归。
    -- 桶 table GC：per-frame 新 landTick 入桶 new bucket table（{ }），pop 后 _SchedByTick[curTick]=nil 桶 GC；
    --   per-frame 1 桶（同 landTick 共桶），微量 GC 可接受（bucket 小 table）；规模起再池化桶（_BucketFreeStack）。
    self._SchedByTick = {}
    self._TxnPendingSchedule = {}
    self._InstructionFreeStack = XStack.New()
end

--- 覆写框架 STEEnv:GetEventSystem()：返回本局表现层事件总线。
--- 框架 STEEngine.Run 每次建 ctx 时调此方法注入 ctx.events，使 vm:Emit 生效。
--- 基类返回 nil（no-op）；派生返回总线即接通事件通道，无需改动框架。
---@return XPresentEventBus
function XPunishaarSTEEnv:GetEventSystem()
    return self._EventBus
end

---@overload
--- 覆写框架 STEEnv:GetNewUniqueNumber：跳过 GlobalEntityIds 保留段 [Begin,End]，
--- 防运行时动态分配的卡牌/Buff 实体 ID 与固定全局实体（Global/Player/Enemy）碰撞，致按 ID 寻址（GetScope/ReadProperty/Store）命中错误实体。
--- counter 从 1 自增，命中保留段时跳到段后继续分配；跳过逻辑确定（不读随机/时间），回放可复现。
--- 段界由 GlobalEntityIds.Begin/End 占位符显式标注（不依赖 Global/Enemy 顺序），新增固定实体 ID 须落在段内并同步更新 End。
---@return number
function XPunishaarSTEEnv:GetNewUniqueNumber()
    local num = self._UniqueNumCounter
    local reservedLo = STECustomEnum.GlobalEntityIds.Begin
    local reservedHi = STECustomEnum.GlobalEntityIds.End
    if num >= reservedLo and num <= reservedHi then
        num = reservedHi + 1
        self._UniqueNumCounter = num + 1
    else
        self._UniqueNumCounter = num + 1
    end
    return num
end

--- 取一个 BuffEntity（池优先复用，池空则新建）。注册只发生一次。
--- 因 Entity:Ctor 构造即自注册，新建路径由 BuffEntity.New 内部注册；
---   复用路径先 ResetForReuse 写新 uid，再显式 RegisterScope（顺序不可反，避免撞 id 重复 assert）。
---@return BuffEntity
function XPunishaarSTEEnv:AcquireBuff(uid, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
    local buff = self._BuffFreeStack:Pop()
    if buff then
        buff:ResetForReuse(uid, self, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
        self:RegisterScope(buff)
    else
        buff = BuffEntity.New(uid, self, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
    end
    return buff
end

--- 归还一个 BuffEntity 到空闲栈（仅供 BuffEntity:Release 调用）。
--- 重复入池检查参照 XPool：同一空壳重复入池会导致后续被弹两次 → 别名灾难，editor 下拦下。
---@param buff BuffEntity
function XPunishaarSTEEnv:ReturnBuff(buff)
    if not buff then
        return
    end

    if XMain.IsEditorDebug then
        local isInPool = table.contains(self._BuffFreeStack:GetContainer(), buff)
        if isInPool then
            XLog.Error("[XPunishaarSTEEnv] BuffEntity 重复入池")
            return
        end
    end

    self._BuffFreeStack:Push(buff)
end

--region 延时伤害指令对象池（仿 AcquireBuff/ReturnBuff 范式）#76

--- 取一个 XPunishaarInstruction（池优先复用，池空则新建）。
--- Pop 路径 ResetData 清空陈旧字段（drop 旧 entityId 引用便于 GC）；调用方随后调 :Init 装载新字段。
--- 出池置 _IsInPool=false（供 ReturnInstruction 守卫判重复入池）#Instruction重复入池守卫
---@return XPunishaarInstruction
function XPunishaarSTEEnv:AcquireInstruction()
    local ins = self._InstructionFreeStack:Pop()
    if ins then
        ins._IsInPool = false
        ins:ResetData()
    else
        ins = XPunishaarInstruction.New()
        ins._IsInPool = false
    end
    return ins
end

--- 归还一个 XPunishaarInstruction 到空闲栈（TickScheduledDamages 落地后 / DrainScheduledDamages 见 skip 项 / RollbackTxn 暂存回池时调）。
--- 先 ResetData 清引用再入池（空闲对象不持有陈旧 entityId）。
--- 重复入池守卫：_IsInPool 标志位（生产也防、O(1)，替代原 editor-only table.contains）——同 ins 二次 Return 致别名灾难（弹两次被误作两个指令）#Instruction重复入池守卫
---@param ins XPunishaarInstruction
function XPunishaarSTEEnv:ReturnInstruction(ins)
    if not ins then
        return
    end
    -- 重复入池静默跳过（异步/难预测致重复 Return 时，入池动作本身已拦下防别名灾难，不报错）#Instruction重复入池守卫
    if ins._IsInPool then
        return
    end
    ins._IsInPool = true
    ins:ResetData()
    self._InstructionFreeStack:Push(ins)
end

--endregion

--region 攻击特效 payload 缓冲

-- ⚠️ 复用风险说明（无逻辑层硬性控制，靠约束）：
-- _AttackEffectList 的 item 是 STEEnv 内部复用 table（零 GC），DrainAttackEffects 把 item **引用**
-- 追加到调用方 out（非拷贝）——out 持内部 item 引用，存在外部错误持有/擅改风险。
-- 约束（调用方必须遵守）：
--   1. 当帧消费：Drain 后立即遍历 out 读取 item 字段，不跨帧持有 item 引用
--      （下帧 AppendAttackEffect 会覆写 item 字段，跨帧持有=脏读）
--   2. 只读不写：只读 item.ownerId/targetId/attackTimes/atkPerHit，禁止修改
--      （item 被下帧复用，擅改污染 STEEnv 后续 payload）
-- 硬性控制候选评估：Drain 拷贝（隔离但 N 个 new table GC，违背零 GC 范式）/ metatable 只读
--   （拦 STEEnv 自身覆写需 rawset 绕，丑且不防脏读）——均非"比较好"，故采注释约束。

--- 追加一条攻击记录（Effect.AttackTarget 内调用，STE 事务内，不做任何 UI 操作）。
--- 多目标由调方拆开逐个追加（每 (own, tgt) 对独立一条）。
--- attackTimes/atkPerHit 当前前端不消费（EffectPlayer 特效发射只用 ownerId/targetId）；
---   飘字走 SpawnDamageNumber 独立事件（payload 来自 _DamageLandedList），不经此 AttackEffect payload。
---@param ownerId number 攻击者 entityId（BlackBoard.OwnCardId）
---@param targetId number 单个目标 entityId
---@param attackTimes number 攻击段数
---@param atkPerHit number 单段伤害值（atk*attackTimes 前）
function XPunishaarSTEEnv:AppendAttackEffect(ownerId, targetId, attackTimes, atkPerHit)
    local n = self._AttackEffectCount + 1
    self._AttackEffectCount = n
    local item = self._AttackEffectList[n]
    if not item then
        item = {}
        self._AttackEffectList[n] = item
    end
    item.ownerId = ownerId
    item.targetId = targetId
    item.attackTimes = attackTimes
    item.atkPerHit = atkPerHit
end

--- 帧末 Drain：把本帧记录逐条追加到 out（item 引用，非拷贝——见 region 头复用风险说明），
--- 清空内部缓冲（wipe 计数保留 table，零 GC）。
--- 调用方须当帧消费 + 只读 item（不跨帧持有/擅改）。
---@param out XList 调用方提供并自清
---@return number count
function XPunishaarSTEEnv:DrainAttackEffects(out)
    local n = self._AttackEffectCount
    for i = 1, n do
        out:Append(self._AttackEffectList[i])
    end
    self._AttackEffectCount = 0
    return n
end

--endregion

--region 落地伤害飘字缓冲（Instruction.Execute 落地 Append，帧末 DrainDamageLanded 取）

--- 追加一条落地伤害记录（Instruction.Execute 调）。复用 table 零 GC，item 引用非拷贝勿跨帧持有（同 _AttackEffectList）。
function XPunishaarSTEEnv:AppendDamageLanded(targetId, ownerId, attackTimes, atkPerHit)
    local n = self._DamageLandedCount + 1
    self._DamageLandedCount = n
    local item = self._DamageLandedList[n]
    if not item then
        item = {}
        self._DamageLandedList[n] = item
    end
    item.targetId = targetId
    item.ownerId = ownerId
    item.attackTimes = attackTimes
    item.atkPerHit = atkPerHit
end

--- 帧末抽干本帧落地伤害到 out（item 引用，当帧消费+只读，同 DrainAttackEffects）。
---@param out XList 调用方提供并自清
---@return number count
function XPunishaarSTEEnv:DrainDamageLanded(out)
    local n = self._DamageLandedCount
    for i = 1, n do
        out:Append(self._DamageLandedList[i])
    end
    self._DamageLandedCount = 0
    return n
end

--endregion

--region 待落地伤害队列（Instruction XClass + 对象池 + 方式1 回滚 + 时间轮分桶）#76 #77

--- 排程一条待落地伤害（Effect.AttackTarget 内调用，STE 事务内，不做任何 UI 操作）。
--- 方式1：本事务内只暂存到 _TxnPendingSchedule，不入时间轮 _SchedByTick；
---   CommitTxn 时 flush 入桶（提交才可见），RollbackTxn 时回池丢弃（不入桶即自动撤销）。
--- landTick 由调用方算好传入（env:GetTick()+delayFrames，绝对到点 tick），Instruction 不自管倒计时 #77。
---@param targetId any 目标 entityId
---@param ownerId any 攻击者 entityId（TickDamageDealtDict 登记键）
---@param atk number 总伤害（atk*attackTimes，排程时算好）
---@param atkType number STECustomEnum.ConfigATKType（排程时锁定，落地不重读）
---@param attackTimes number 段数（TickDamageDealtDict 累加用）
---@param landTick number 落地绝对 tick（env:GetTick()+delayFrames，CommitTxn flush 时按此键分桶）
function XPunishaarSTEEnv:ScheduleDamage(targetId, ownerId, atk, atkType, attackTimes, landTick)
    local ins = self:AcquireInstruction()
    ins:Init(targetId, ownerId, atk, atkType, attackTimes, landTick)
    table.insert(self._TxnPendingSchedule, ins)
end

--- 帧内抽干当前 tick 桶的所有待落地指令到 out（时间轮 pop）。
--- curTick=GetTick()；bucket=_SchedByTick[curTick]；空桶 return 0（O(1) 空转，无遍历无 GC）。
--- 非空：count=#bucket；遍历桶（正序，无 table.remove——整桶 pop 不需防错位）：
---   ins.skip=true（CancelScheduledOnTarget 标记的取消项）→ ReturnInstruction 回池不入 out；
---   否则 out[i]=ins（入 out 待 Execute）。遍历完 _SchedByTick[curTick]=nil（整桶清 O(1) pop，桶 table GC）。
--- out 复用（持 Instruction 引用，零 per-tick GC）。**不回池**——Execute 后由 TickScheduledDamages
---   调 ReturnInstruction 回池（落地副作用与回收分离，Execute 抛错不影响已 Drain 状态）#76。
---@param out XPunishaarInstruction[] 调用方提供并持久的 buffer（数组，每项 Instruction 引用）
---@return number count 本帧落地条数
function XPunishaarSTEEnv:DrainScheduledDamages(out)
    local curTick = self:GetTick()
    local bucket = self._SchedByTick[curTick]
    if not bucket then
        return 0
    end
    local count = #bucket
    for i = 1, count do
        local ins = bucket[i]
        if ins.skip then
            self:ReturnInstruction(ins)
        else
            out[i] = ins
        end
    end
    self._SchedByTick[curTick] = nil  -- 整桶清 O(1) pop，桶 table GC（per-frame 1 桶微量 GC 可接受）
    return count
end

--- 取消某 target 在时间轮里剩余待落地的指令（overkill 取消，death gate 调用）。
--- 遍历 _SchedByTick 所有 landTick>curTick 的桶（已落地 tick 桶已 pop 清，不需处理），
---   桶内 ins.target==targetId 则标 ins.skip=true（惰性跳过，不移除——不破坏 hash map 结构）。
---   DrainScheduledDamages pop 桶时见 skip 直接回池不入 out（与正常路径一致）#77。
--- 同时标 _TxnPendingSchedule 内匹配项的 skip（保险——CheckBattleEnd 在事务提交后调，此时 pending 已 flush
---   清空理论上为空；标 skip 不移除，避免 CommitTxn/RollbackTxn 二次处理已取消指令致双入池）。
---@param targetId any 死亡目标的 entityId
function XPunishaarSTEEnv:CancelScheduledOnTarget(targetId)
    local curTick = self:GetTick()
    for landTick, bucket in pairs(self._SchedByTick) do
        if landTick > curTick then
            for i = 1, #bucket do
                local ins = bucket[i]
                if ins.target == targetId then
                    ins.skip = true
                end
            end
        end
    end
    -- 保险标 pending skip（正常路径为空；标 skip 不移除，CommitTxn flush 入桶后 skip 项 Drain 回池，RollbackTxn 直接回池）
    local pending = self._TxnPendingSchedule
    for i = 1, #pending do
        local ins = pending[i]
        if ins.target == targetId then
            ins.skip = true
        end
    end
end

--endregion

--region 事务覆写（方式1 回滚：排程暂存 flush 入桶 / 回池）#76 #77

--- 提交一层事务：父类快照提交（scope/property 合并、延迟释放）+ flush 暂存排程入时间轮分桶。
--- flush：逐个 pending ins 取 ins.landTick 为键，bucket=_SchedByTick[landTick] or {}；bucket[#bucket+1]=ins；
---   _SchedByTick[landTick]=bucket（同 landTick 多攻击共桶）。wipe pending 清空零 GC。
--- ⚠️ 嵌套事务边界：当前 _TxnPendingSchedule 为单列表简化——仅适配 ExecuteOneCardEffects 单层 atomic=true。
---   嵌套场景下内层 CommitTxn 会过早 flush（待 _SchedByTick 不该见）；将来引入嵌套事务须改栈式
---   （每层一列表，CommitTxn 合并入父、RollbackTxn 丢弃），届时同步改 RollbackTxn。
function XPunishaarSTEEnv:CommitTxn()
    -- 父类：journal 合并/延迟释放、depth-1（显式 self 调父类实现——XClass 的 self.Super:M() 在本实现下
    --   会以 class 对象为 self，不可用；ClassName.Method(self) 是 Lua 显式父类调用的标准写法，非静态方法调用）
    STEEnv.CommitTxn(self)
    -- 方式1 flush：暂存指令入时间轮分桶（提交才可见，回滚不入桶自动撤销）
    local pending = self._TxnPendingSchedule
    local n = #pending
    local byTick = self._SchedByTick
    for i = 1, n do
        local ins = pending[i]
        local bucket = byTick[ins.landTick] or {}
        bucket[#bucket + 1] = ins
        byTick[ins.landTick] = bucket
    end
    for i = 1, n do
        pending[i] = nil  -- wipe 原地清空，零 GC（STE tick 高频，免每次新建 table）#76 精审
    end
end

--- 回滚一层事务：暂存排程回池丢弃（未入 _SchedByTick，自动撤销）+ 父类快照还原。
--- ⚠️ 嵌套事务边界：见 CommitTxn 注释；单层路径正确，嵌套下 RollbackTxn 会清光整列表（含父层 pending），
---   须改栈式才正确。
function XPunishaarSTEEnv:RollbackTxn()
    -- 方式1：暂存指令回池丢弃（不污染 _SchedByTick——直到提交才入桶，回滚天然撤销）
    local pending = self._TxnPendingSchedule
    local n = #pending
    for i = 1, n do
        self:ReturnInstruction(pending[i])
        pending[i] = nil  -- wipe 原地清空，零 GC #76 精审
    end
    -- 父类：property/scope 快照还原、rng/tick 还原、depth-1
    STEEnv.RollbackTxn(self)
end

--endregion

return XPunishaarSTEEnv
