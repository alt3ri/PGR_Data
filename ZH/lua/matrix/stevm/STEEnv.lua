local Random      = require('STEVM/Tools/Random')
local OrderedUtil = require('STEVM/Tools/OrderedUtil')
local Pools = require("STEVM/Tools/Pools")
local STEEnum = require("STEVM/STEEnum")
local VM = require("STEVM/Engine/VM")

---@class STEEnv STE运行环境，所有STE变量的管理都由STEEnv负责
---@field _EntityMap table<any, STEVM.Entity> scopeId -> STEVM.Entity 对象(纯 table;取有序列表时临时 SortedKeys)
---@field _Random STEVM.Random 单一随机源
---@field _tick number 逻辑时间(回合/逻辑步)
---@field _txnDepth number 事务嵌套深度(>0 即在原子组内)
---@field _journalStack table[] 写时日志帧栈(每层事务一帧)
---@field _Pools STEVM.Pools 框架内部对象池(仅框架内部用,不对玩法暴露;随 env 释放)
---@field _VM STEVM.VM 虚拟机，每个环境唯一持有一个实例
local STEEnv = XClass(nil, 'STEEnv')

---@param seed number|nil RNG 种子(回放复种用;缺省走 Random 默认常量)
function STEEnv:Ctor(seed)
    self._EntityMap = {} -- scopeId -> STEVM.Entity;遍历/取列表时临时按 id 排序保证确定性
    self._Random         = Random.New(seed)

    self._tick = 0
    self._txnDepth = 0 -- 事务嵌套深度(>0 表示在原子组内,AtomicGroup 用)
    self._journalStack = {} -- 写时日志帧栈(每层事务一帧,见 BeginTxn/JournalRecord)
    
    ---@type STEVM.Pools
    self._Pools = Pools.New()
    
    ---@type STEVM.VM
    self._VM = VM.New(self)
    
    self._UniqueNumCounter = 1
end

--- 释放环境:清空对象池 + 释放所有 STEVM.Entity。幂等。
function STEEnv:Release()
    local ids = OrderedUtil.SortedKeys(self._EntityMap)
    for i = 1, #ids do
        local scope = self._EntityMap[ids[i]]
        if scope and scope.Release then
            scope:Release()
        end
    end
    self._EntityMap = {}

    self._Pools = nil
end

--region 访问器 --------------------------------------------------------------

--- 获取事件系统
--- 暂无，子类可补充
function STEEnv:GetEventSystem()
    return nil
end

--- 获取随机数器
---@return STEVM.Random
function STEEnv:GetRandom() return self._Random end

---@return number
function STEEnv:GetTick() return self._tick end

--- 获取该环境持有的虚拟机
---@return STEVM.VM
function STEEnv:GetVM() return self._VM end

--- 推进逻辑时间(契约 D1:时间是逻辑步,不读真实时间)。
---@param delta number|nil 缺省 +1
function STEEnv:AdvanceTick(delta)
    self._tick = self._tick + (delta or 1)
end

--- 获取一个新的唯一值
function STEEnv:GetNewUniqueNumber()
    local num = self._UniqueNumCounter
    
    self._UniqueNumCounter = self._UniqueNumCounter + 1
    
    return num
end
--endregion

--region 事务(写时日志,AtomicGroup 用)-----------------------------------
-- 写时日志(copy-on-write undo-log):进事务不拷全部状态,只在某 property 首次被改时
--   记一份它的 Snapshot();中止按日志逐个 Restore,提交丢弃日志。拷贝量 = O(本次改动)。
-- 每帧结构:{ undo = {prop->snap}, rngState = rng:DumpState(), tick = self._tick, struct = {} }
--   undo 既是记录又兼判重(每帧首次改某 prop 才记);struct 记 scope 增删以便回滚。

--- 进入一层事务:压一帧(捕获 rng/tick)、深度 +1。
function STEEnv:BeginTxn()
    local stack = self._journalStack
    stack[#stack + 1] = {
        undo     = {},
        rngState = self._Random:DumpState(),
        tick     = self._tick,
        struct   = {},
    }
    self._txnDepth = self._txnDepth + 1
end

--- 写前记录:property 在本帧首次被改时,记一份它的快照(prop 对象作 key,每帧只记一次)。
--- 由 PropertyBase:_BeforeWrite 在事务态下调用。
---@param prop PropertyBase
function STEEnv:JournalRecord(prop)
    local frame = self._journalStack[#self._journalStack]
    if frame == nil then
        return -- 非事务态(理论上 _BeforeWrite 已挡掉);防御性兜底。
    end
    if frame.undo[prop] == nil then
        frame.undo[prop] = prop:Snapshot()
    end
end

--- 提交一层事务:栈顶帧出栈并合并到父帧;深度 -1。
--- 最外层提交时处理 scope 延迟释放(合并后所有 remove 项真正 Release)。
function STEEnv:CommitTxn()
    local stack = self._journalStack
    local frame = stack[#stack]
    stack[#stack] = nil
    self._txnDepth = self._txnDepth - 1

    local parent = stack[#stack]
    if parent then
        -- 合并到父帧:父帧没记的 prop 接收 snap(移交,不释放)；父帧已有的内层 snap 丢弃→释放快照资源。
        for prop, snap in pairs(frame.undo) do
            if parent.undo[prop] == nil then
                parent.undo[prop] = snap
            else
                prop:ReleaseSnapshot(snap)
            end
        end
        -- struct(scope 增删)同理并入父帧(rngState/tick 不合并,各帧用自己的)。
        local pstruct = parent.struct
        for i = 1, #frame.struct do
            pstruct[#pstruct + 1] = frame.struct[i]
        end
    else
        -- 已是最外层:所有快照丢弃→释放资源；struct remove 项真正释放(事务内一直延迟到此)。
        for prop, snap in pairs(frame.undo) do
            prop:ReleaseSnapshot(snap)
        end
        for i = 1, #frame.struct do
            local rec = frame.struct[i]
            if rec.kind == 'remove' and rec.scope and rec.scope.Release then
                rec.scope:Release()
            end
        end
    end
end

--- 回滚一层事务:栈顶帧出栈;逐个 prop:Restore、还原 rng/tick、撤销 scope 增删。
function STEEnv:RollbackTxn()
    local stack = self._journalStack
    local frame = stack[#stack]
    stack[#stack] = nil

    -- 还原各 property + 释放快照资源(顺序无关,pairs 可用)。
    for prop, snap in pairs(frame.undo) do
        prop:Restore(snap)
        prop:ReleaseSnapshot(snap)
    end

    -- 还原 rng / tick(本帧捕获的起点状态)。
    self._Random:LoadState(frame.rngState)
    self._tick = frame.tick

    -- 撤销 scope 增删(逆序):add → 摘除该 scope 并 Release;remove → 把 scope 对象挂回。
    -- Release 是「对象确定性消失」的唯一钩子:commit(延迟释放)、非事务 remove、以及此处回滚,
    --   三条消失路径都必须兑现它(否则如对象池等挂在 Release 上的副作用会在回滚时漏执行)。
    local struct = frame.struct
    for i = #struct, 1, -1 do
        local rec = struct[i]
        if rec.kind == 'add' then
            local scope = self._EntityMap[rec.id]
            self._EntityMap[rec.id] = nil
            if scope and scope.Release then
                scope:Release()
            end
        elseif rec.kind == 'remove' then
            self._EntityMap[rec.id] = rec.scope
        end
    end

    self._txnDepth = self._txnDepth - 1
end

--- 是否处于事务中(原子组内)。
---@return boolean
function STEEnv:IsInTransaction()
    return self._txnDepth > 0
end

--- (测试用)栈顶帧已记录的 undo 条目数。供断言「只记改动量」。
---@return number
function STEEnv:_TxnTopRecordCount()
    local frame = self._journalStack[#self._journalStack]
    if frame == nil then
        return 0
    end
    local n = 0
    for _ in pairs(frame.undo) do
        n = n + 1
    end
    return n
end
--endregion

--region STEVM.Entity 管理 ----------------------------------------------------------

--- 取 STEVM.Entity(找不到返回 nil)。纯读。数据层依赖的唯一接口。
---@param scopeId any
---@return STEVM.Entity|nil
function STEEnv:GetScope(scopeId)
    if scopeId == nil then
        return nil
    end
    return self._EntityMap[scopeId]
end

--- 注册一个已构造好的 STEVM.Entity。id 重复视为配置错误(assert,避免静默覆盖引用)。
---@param scope STEVM.Entity
---@return STEVM.Entity scope 同传入对象
function STEEnv:RegisterScope(scope)
    assert(scope ~= nil, 'STEEnv:RegisterScope scope 不可为 nil')
    local id = scope:GetId()
    assert(id ~= nil, 'STEEnv:RegisterScope scope id 不可为 nil')
    assert(self._EntityMap[id] == nil, 'STEEnv:RegisterScope id 重复:' .. tostring(id))
    self._EntityMap[id] = scope
    -- 事务态:记一笔 add,以便回滚时摘除该 scope。
    if self:IsInTransaction() then
        local struct = self._journalStack[#self._journalStack].struct
        struct[#struct + 1] = { kind = 'add', id = id }
    end
    return scope
end

--- 注销并释放一个 STEVM.Entity。幂等(规范#40):不存在时无副作用。
--- 事务态:从映射摘除并记一笔 remove,延迟 Release(留待最外层提交时释放,中止则复活);
---   非事务态:摘除并立即 Release(维持现状)。
---@param scopeId any
function STEEnv:RemoveScope(scopeId)
    local scope = self._EntityMap[scopeId]
    if scope == nil then
        return
    end
    self._EntityMap[scopeId] = nil
    if self:IsInTransaction() then
        -- 延迟释放:不调 scope:Release(),把对象记进日志,便于中止时复活、提交时统一释放。
        local struct = self._journalStack[#self._journalStack].struct
        struct[#struct + 1] = { kind = 'remove', id = scopeId, scope = scope }
        return
    end
    if scope.Release then
        scope:Release()
    end
end

--- 取所有 scopeId(id 升序新数组)。纯读、转移所有权。
---@return any[]
function STEEnv:GetAllEntityIds()
    return OrderedUtil.SortedKeys(self._EntityMap)
end
--endregion

--region 对象池访问接口

---@return Blackboard
function STEEnv:GetPoolBlackBoard()
    return self._Pools:GetItemByPoolKey(STEEnum.InnerPoolsKey.BlackBoard)
end

---@return ExecContext
function STEEnv:GetPoolExecContext()
    return self._Pools:GetItemByPoolKey(STEEnum.InnerPoolsKey.ExecContext)
end

function STEEnv:ReturnPoolBlackBoard(blackboard)
    return self._Pools:ReturnItemByPoolKey(STEEnum.InnerPoolsKey.BlackBoard, blackboard)
end

function STEEnv:ReturnPoolExecContext(execContext)
    return self._Pools:ReturnItemByPoolKey(STEEnum.InnerPoolsKey.ExecContext, execContext)
end

function STEEnv:GetPoolModOp()
    return self._Pools:GetItemByPoolKey(STEEnum.InnerPoolsKey.ModOp)
end

function STEEnv:ReturnPoolModOp(modOp)
    return self._Pools:ReturnItemByPoolKey(STEEnum.InnerPoolsKey.ModOp, modOp)
end

function STEEnv:GetPoolDictSnap()
    return self._Pools:GetItemByPoolKey(STEEnum.InnerPoolsKey.DictSnap)
end

function STEEnv:ReturnPoolDictSnap(t)
    return self._Pools:ReturnItemByPoolKey(STEEnum.InnerPoolsKey.DictSnap, t)
end

function STEEnv:GetPoolListSnap()
    return self._Pools:GetItemByPoolKey(STEEnum.InnerPoolsKey.ListSnap)
end

function STEEnv:ReturnPoolListSnap(t)
    return self._Pools:ReturnItemByPoolKey(STEEnum.InnerPoolsKey.ListSnap, t)
end

--endregion

return STEEnv
