local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055021 : XSkillBase
local XSkill_1055021 = XDlcScriptManager.RegSkillScript(1055021, "XSkill_1055021", Base)

function XSkill_1055021:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- 属性49按最大值比例比较，当前值 / 最大值 * 1000 需要 >= 1000。
    self._attribType49 = 49
    self._attribTarget1000 = 1000
    self._attribPermyriadBase = 1000
    -- 只允许地面释放，2 表示地面。
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 当前动作是 core1 时，需要额外检查技能时间类型 14。
    self._core1Id = 1055020
    self._requiredActionTimingType = 14
end

function XSkill_1055021:IsAttribMatched()
    local value = self._proxy:GetNpcAttribValue(self._uuid, self._attribType49) or self._baseTimingId
    local maxValue = self._proxy:GetNpcAttribMaxValue(self._uuid, self._attribType49) or self._baseTimingId
    if maxValue <= self._baseTimingId then
        return false
    end

    local valuePermyriad = value * self._attribPermyriadBase / maxValue
    return valuePermyriad >= self._attribTarget1000
end

function XSkill_1055021:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055021:IsCurrentCore1Action()
    return self._proxy:CheckNpcCurrentAction(self._uuid, self._core1Id)
end

function XSkill_1055021:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055021:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查。
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055021 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：属性49的最大值比例需要达到 1000/1000。
    if not self:IsAttribMatched() then
        return false
    end

    -- 第三步：必须在地面。
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第四步：不在 core1 动作中时，不需要检查技能时间类型。
    if not self:IsCurrentCore1Action() then
        return true
    end

    -- 第五步：当前动作是 core1 时，必须处于技能时间类型 14。
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第六步：以上条件都满足时允许释放。
    return true
end

return XSkill_1055021
