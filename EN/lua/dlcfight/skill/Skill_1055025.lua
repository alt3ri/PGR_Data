local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055025 : XSkillBase
local XSkill_1055025 = XDlcScriptManager.RegSkillScript(1055025, "XSkill_1055025", Base)

function XSkill_1055025:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- 当前动作必须是 attack4 或 attack4st。
    self._attack4Id = 1055004
    self._attack4stId = 1055029
    -- 只允许地面释放，2 表示地面。
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 检查技能时间类型 14。
    self._requiredActionTimingType = 14
    -- 牢房 Buff 层数需要等于 1。
    self._prisonCellBuff = 105501101
    self._buffStackEqualOne = 1
end

function XSkill_1055025:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055025:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055025:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055025:IsBuffStackEqual()
    local stacks = self._proxy:GetBuffStacks(self._uuid, self._prisonCellBuff) or self._baseTimingId
    return stacks == self._buffStackEqualOne
end

function XSkill_1055025:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查。
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055025 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：当前动作必须是 attack4 或 attack4st。
    local isRequiredAction = self:IsCurrentActionMatched(self._attack4Id)
        or self:IsCurrentActionMatched(self._attack4stId)
    if not isRequiredAction then
        return false
    end

    -- 第三步：必须在地面。
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第四步：必须处于技能时间类型 14。
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第五步：必须拥有牢房 Buff 1 层。
    if not self:IsBuffStackEqual() then
        return false
    end

    -- 第六步：以上条件都满足时允许释放。
    return true
end

return XSkill_1055025
