local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055016 : XSkillBase
local XSkill_1055016 = XDlcScriptManager.RegSkillScript(1055016, "XSkill_1055016", Base)

function XSkill_1055016:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 属性 48 的最大值比例必须大于 0
    self._attribType48 = 48
    self._compareGreater = 2
    self._attribTargetZero = 0
    self._attribValueTypeCurrent = 0
    self._attribValueTypePermyriad = 1
end

function XSkill_1055016:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055016:IsAttribMatched(attribType, compareType, targetValue, valueType)
    local attribValueTypeCurrent = self._attribValueTypeCurrent or 0
    local attribValueTypePermyriad = self._attribValueTypePermyriad or 1
    local compareGreater = self._compareGreater or 2
    local value = self._proxy:GetNpcAttribValue(self._uuid, attribType) or attribValueTypeCurrent
    targetValue = targetValue or attribValueTypeCurrent
    if valueType == attribValueTypePermyriad then
        local maxValue = self._proxy:GetNpcAttribMaxValue(self._uuid, attribType) or attribValueTypeCurrent
        if maxValue <= attribValueTypeCurrent then
            value = attribValueTypeCurrent
        else
            value = value * 1000 / maxValue
        end
    end

    if compareType == compareGreater then
        return value > targetValue
    end

    return false
end

function XSkill_1055016:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055016 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第三步：属性 48 的最大值比例必须大于 0
    if not self:IsAttribMatched(self._attribType48, self._compareGreater, self._attribTargetZero, self._attribValueTypePermyriad) then
        return false
    end

    -- 第四步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055016
