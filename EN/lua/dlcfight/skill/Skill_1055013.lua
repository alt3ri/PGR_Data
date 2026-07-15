local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055013 : XSkillBase
local XSkill_1055013 = XDlcScriptManager.RegSkillScript(1055013, "XSkill_1055013", Base)

function XSkill_1055013:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- Attrib 50 must be full.
    self._attribType50 = 50
    self._invalidAttribValue = 0
    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Normal buff must have 1 stack.
    self._normalBuff = 105501103
    self._buffStackEqualOne = 1
end

function XSkill_1055013:IsAttribFull(attribType)
    attribType = attribType or self._attribType50
    local invalidAttribValue = self._invalidAttribValue
    local value = self._proxy:GetNpcAttribValue(self._uuid, attribType)
    local maxValue = self._proxy:GetNpcAttribMaxValue(self._uuid, attribType)
    if not value or not maxValue or maxValue <= invalidAttribValue then
        return false
    end

    return value >= maxValue
end

function XSkill_1055013:IsGroundStateMatched()
    local groundOnlyState = self._groundOnlyState
    local groundStateValue = self._groundStateValue
    if groundOnlyState == groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055013:IsBuffStackEqual(buffId, stackCount)
    local baseTimingId = self._baseTimingId
    buffId = buffId or self._normalBuff
    stackCount = stackCount or self._buffStackEqualOne
    local stacks = self._proxy:GetBuffStacks(self._uuid, buffId) or baseTimingId
    return stacks == stackCount
end

function XSkill_1055013:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055013 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- Step 2: attrib 50 must be full.
    if not self:IsAttribFull(self._attribType50) then
        return false
    end

    -- Step 3: must be on ground.
    if not self:IsGroundStateMatched() then
        return false
    end

    -- Step 4: normal buff must have 1 stack.
    if not self:IsBuffStackEqual(self._normalBuff, self._buffStackEqualOne) then
        return false
    end

    -- Step 5: all conditions passed.
    return true
end

return XSkill_1055013
