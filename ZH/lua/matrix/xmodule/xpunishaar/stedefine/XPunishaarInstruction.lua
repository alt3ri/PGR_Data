local STEEnum = require("STEVM/STEEnum")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local Effect = require("XModule/XPunishaar/STEDefine/Effect")

-- #76 延时落地架构修正：延时伤害指令从「env 级 6 并行标量 PropertyList」重构为 XClass + 对象池。
--   原因：STE 事务快照只对 Entity 内 PropertyList 生效，env 级 PropertyList 非法（精审误读"env 级参与事务"）；
--   6 并行索引同步脆弱。改 Instruction XClass（普通数据载体，非 STEVM.Entity/scope）+ env 对象池（仿 buff）+
--   方式1 回滚（ScheduleDamage 暂存 _TxnPendingSchedule，CommitTxn flush 入桶，RollbackTxn 回池丢弃）。
-- 本类不注册 scope、无 uid、无 property 对象——纯字段载体 + Execute 逻辑；池复用零 GC（ResetData 清字段）。
-- #77 队列机制优化：有序列表+table.remove(1) pop 改时间轮分桶。Instruction 从「delayFrames 倒计+Tick 推进」
--   改为「landTick 绝对到点（env:GetTick()+delayFrames 算好传入）+ skip 取消标记」。env 用 _SchedByTick hash map
--   按 landTick 分桶：O(1) 入桶/空转/pop + O(n) 生效，无插入排序无 head 索引。Instruction 不再持 Tick 方法。

--- 延时伤害指令（XClass，非 STEVM.Entity）。
--- 排程时由 env:ScheduleDamage → AcquireInstruction + Init 装载字段（含 landTick 绝对到点）；landTick 到点后由 pipeline 调 Execute 落地。
--- 字段：target/owner/atk/atkType/attackTimes/landTick（Init 设，Execute 读/CancelScheduledOnTarget 读 target，ResetData 清）+ skip（取消标记，CancelScheduledOnTarget 标 true，Drain 见 skip 回池不入 out）。
---@class XPunishaarInstruction
local XPunishaarInstruction = XClass(nil, "XPunishaarInstruction")

--- 装载一条延时伤害指令的字段（AcquireInstruction 后由 ScheduleDamage 调用）。
--- landTick 由调用方算好传入（env:GetTick()+delayFrames，绝对到点 tick），Instruction 不自管倒计时。
---@param target any 被击实体 entityId
---@param owner any 攻击者 entityId（TickDamageDealtDict 登记键）
---@param atk number 总伤害 atk*attackTimes（排程时快照锁定，源 ATK 后续变化不影响已排程指令）
---@param atkType number STECustomEnum.ConfigATKType（排程时锁定，落地不重读）
---@param attackTimes number 段数（TickDamageDealtDict 累加用）
---@param landTick number 落地绝对 tick（env:GetTick()+delayFrames，DrainScheduledDamages 按 curTick=GetTick() 命中桶）
function XPunishaarInstruction:Init(target, owner, atk, atkType, attackTimes, landTick)
    self.target = target
    self.owner = owner
    self.atk = atk
    self.atkType = atkType
    self.attackTimes = attackTimes
    self.landTick = landTick
    self.skip = false
end

--- 落地一条伤害（land-time，TickScheduledDamages 调用）。
--- 原 Effect._LandDamageOne 逻辑移入此处（#76）；用 self 字段（Init 设），非参传。
--- ① M1 守卫：HP<=0 已死目标不 land（含 dict 不计，符合 T6「实际造成伤害」口径）；
--- ② dict 登记：TickDamageDealtDict[owner] += attackTimes（护盾减免不影响计数）；
--- ③ 重读护盾（实时——排程后可能被破盾/加盾）；attackType 锁定（排程时定）；
--- ④ 分支：NoHurtTimes>0 且非真伤→扣护盾+Emit ShieldChanged；否则→扣 HP+Emit HPChanged。
---@param vm STEVM.VM
---@param damageDict PropertyDict Global.TickDamageDealtDict
function XPunishaarInstruction:Execute(vm, damageDict)
    local env = vm:GetEnv()
    -- ⓪ 实体存在性守卫：排程后 landTick 前实体可能已销毁（被 RemoveScope），不存在静默跳过（不 Error/不 AbortTxn）
    if not env:GetScope(self.target) then
        return
    end
    -- ① M1 守卫：已死目标不再落地（post-death overkill 取消，含 dict 登记也跳过）#75 M1
    local hp = vm:Read(self.target, STECustomEnum.FieldNameType.HP)
    if not XTool.IsNumberValidEx(hp) or hp <= 0 then
        return
    end

    -- 甄别 0 段攻击/0 伤害：不消护盾不扣 HP（防骗盾——0 伤害消护盾层属骗盾；上游 AttackTarget 已拦，此处兜底）#护盾按段消
    if self.attackTimes <= 0 or self.atk <= 0 then
        return
    end

    -- ② 登记 TickDamageDealtDict[owner] += attackTimes（land-time；护盾不影响计数）
    vm:PropSet(damageDict, self.owner, (vm:PropGet(damageDict, self.owner) or 0) + self.attackTimes)
    -- ③ 重读护盾（实时）；单段伤害 = 总/段
    local noHurtTimes = vm:Read(self.target, STECustomEnum.FieldNameType.NoHurtTimes) or 0
    local atkPerHit = math.floor(self.atk / self.attackTimes)  -- 单段伤害（floor 保整数，对齐 HP 整数不变量 Effect:130；atk=总=单段×段数精确整除，floor 兜底防未来调用方破坏总契约致漂移）
    -- ④ 分支
    if noHurtTimes > 0 and self.atkType ~= STECustomEnum.ConfigATKType.IgnoreNoHurtTimes then
        -- 按段消护盾：护盾抵消段数 = min(攻击段数, 护盾层数)；每段消 1 层，突破后剩段扣 HP
        local shieldConsume = math.min(self.attackTimes, noHurtTimes)
        if shieldConsume > 0 then
            vm:Store(self.target, STECustomEnum.FieldNameType.NoHurtTimes, STEEnum.ValChangeType.Subtract, shieldConsume)
            Effect._EmitShieldChanged(vm, self.target)
        end
        -- 突破护盾后扣 HP：总伤害减护盾抵消段（self.atk - atkPerHit*shieldConsume），
        -- 保留 floor 余数（与无护盾路径 self.atk 口径一致——总减护盾抵消部分，余数归 HP）#护盾按段消
        local hpHits = self.attackTimes - shieldConsume
        if hpHits > 0 then
            vm:Store(self.target, STECustomEnum.FieldNameType.HP, STEEnum.ValChangeType.Subtract, self.atk - atkPerHit * shieldConsume)
            Effect._EmitHpChanged(vm, self.target)
            if atkPerHit > 0 then
                env:AppendDamageLanded(self.target, self.owner, hpHits, math.floor(atkPerHit))
            end
        end
    else
        -- 无护盾/真伤（IgnoreNoHurtTimes）：全段扣 HP
        vm:Store(self.target, STECustomEnum.FieldNameType.HP, STEEnum.ValChangeType.Subtract, self.atk)
        Effect._EmitHpChanged(vm, self.target)
        if atkPerHit > 0 then
            env:AppendDamageLanded(self.target, self.owner, self.attackTimes, math.floor(atkPerHit))
        end
    end
end

--- 清字段（池回收前调，drop 旧 entityId/landTick 引用便于 GC，避免空闲对象持有陈旧引用）。
--- #77：清 landTick（数字）+ skip（bool）+ 原6字段（target/owner 置 nil，atk/atkType/attackTimes/landTick 置 0，skip 置 false）。
function XPunishaarInstruction:ResetData()
    self.target = nil
    self.owner = nil
    self.atk = 0
    self.atkType = 0
    self.attackTimes = 0
    self.landTick = 0
    self.skip = false
end

return XPunishaarInstruction
