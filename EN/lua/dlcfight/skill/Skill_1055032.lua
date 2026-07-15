local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055032 : XSkillBase
local XSkill_1055032 = XDlcScriptManager.RegSkillScript(1055032, "XSkill_1055032", Base)

function XSkill_1055032:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
end

function XSkill_1055032:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055032:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055032 CheckCastCondition: Base.CheckCastCondition(actionId, 0) failed")
        return false
    end

    -- Step 2: must be on ground.
    if not self:IsGroundStateMatched() then
        return false
    end

    -- Step 3: base and ground checks are enough.
    return true
end

return XSkill_1055032
