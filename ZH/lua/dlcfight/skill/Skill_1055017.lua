local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055017 : XSkillBase
local XSkill_1055017 = XDlcScriptManager.RegSkillScript(1055017, "XSkill_1055017", Base)

function XSkill_1055017:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 当前必须正在释放 whiteCombo4 的第 1 段
    self._whiteCombo4SkillIds = { 1055016, 1055017, 1055018, 1055019 }
    self._requiredWhiteComboIndex = 1
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 检查当前动作里的技能时间类型 = 14
    self._requiredActionTimingType = 14
    -- 属性 48 的最大值比例必须大于 0
    self._attribType48 = 48
    self._compareGreater = 2
    self._attribTargetZero = 0
    self._attribValueTypeCurrent = 0
    self._attribValueTypePermyriad = 1
end

function XSkill_1055017:IsCurrentActionMatched()
    return self._proxy:CheckNpcCurrentAction(self._uuid, self._whiteCombo4SkillIds[self._requiredWhiteComboIndex])
end

function XSkill_1055017:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055017:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055017:IsAttribMatched()
    local attribType48 = self._attribType48 or 48
    local attribValueTypeCurrent = self._attribValueTypeCurrent or 0
    local attribTargetZero = self._attribTargetZero or 0
    local value = self._proxy:GetNpcAttribValue(self._uuid, attribType48) or attribValueTypeCurrent
    local maxValue = self._proxy:GetNpcAttribMaxValue(self._uuid, attribType48) or attribValueTypeCurrent
    if maxValue <= attribValueTypeCurrent then
        value = attribValueTypeCurrent
    else
        value = value * 1000 / maxValue
    end
    return value > attribTargetZero
end

function XSkill_1055017:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055017 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：当前动作必须是 1055016
    if not self:IsCurrentActionMatched() then
        return false
    end

    -- 第三步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第四步：当前动作必须处在技能时间类型 14 内
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第五步：属性 48 的最大值比例必须大于 0
    if not self:IsAttribMatched() then
        return false
    end

    -- 第六步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055017
