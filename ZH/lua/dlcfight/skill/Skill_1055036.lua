local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055036 : XSkillBase
local XSkill_1055036 = XDlcScriptManager.RegSkillScript(1055036, "XSkill_1055036", Base)

function XSkill_1055036:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- Attrib 41 must be full.
    self._attribType41 = 41
    self._invalidAttribValue = 0
end

function XSkill_1055036:IsAttribFull()
    local value = self._proxy:GetNpcAttribValue(self._uuid, self._attribType41)
    local maxValue = self._proxy:GetNpcAttribMaxValue(self._uuid, self._attribType41)
    if not value or not maxValue or maxValue <= self._invalidAttribValue then
        return false
    end

    return value >= maxValue
end

function XSkill_1055036:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        return false
    end

    -- Step 2: attrib 41 must be at least 100% of max value.
    if not self:IsAttribFull() then
        return false
    end

    -- Step 3: all conditions passed.
    return true
end

return XSkill_1055036
