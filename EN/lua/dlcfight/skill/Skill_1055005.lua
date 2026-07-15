local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055005 : XSkillBase
local XSkill_1055005 = XDlcScriptManager.RegSkillScript(1055005, "XSkill_1055005", Base)

function XSkill_1055005:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 当前必须正在释放 1055004 或 1055005
    self._attack4Id = 1055004
    self._attack5ChargeId = 1055005
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 检查当前动作里的技能时间类型 = 14
    self._requiredActionTimingType = 14
    -- Buff 105501101 层数等于 1
    self._prisonCellBuff = 105501101
    self._buffStackEqualOne = 1
end

function XSkill_1055005:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055005:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055005:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055005:IsBuffStackEqual(buffId, stackCount)
    local stacks = self._proxy:GetBuffStacks(self._uuid, buffId) or self._baseTimingId
    return stacks == stackCount
end

function XSkill_1055005:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查，失败时不再继续判断表条件
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055005 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第三步：当前动作必须处在技能时间类型 14 内
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第四步：必须拥有 105501101 的 1 层 Buff
    if not self:IsBuffStackEqual(self._prisonCellBuff, self._buffStackEqualOne) then
        return false
    end

    -- 第五步：当前动作是 1055004 时通过
    if self:IsCurrentActionMatched(self._attack4Id) then
        return true
    end

    -- 第六步：当前动作是 1055005 时通过
    if self:IsCurrentActionMatched(self._attack5ChargeId) then
        return true
    end

    -- 第七步：当前动作不满足时，不允许释放
    return false
end

return XSkill_1055005
