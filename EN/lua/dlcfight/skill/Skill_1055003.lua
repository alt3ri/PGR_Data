local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055003 : XSkillBase
local XSkill_1055003 = XDlcScriptManager.RegSkillScript(1055003, "XSkill_1055003", Base)

function XSkill_1055003:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- Normal branch: attack2 -> attack3.
    self._attack2Id = 1055002
    -- Offset branch: offset buff -> attack3.
    self._attack2ToAttack3OffsetBuff = 105501118
    self._buffStackEqualOne = 1
    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Timing for attack2.
    self._requiredActionTimingType = 14
end

function XSkill_1055003:IsAttack2ActionMatched()
    return self._proxy:CheckNpcCurrentAction(self._uuid, self._attack2Id)
end

function XSkill_1055003:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055003:IsAttackTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055003:HasAttackOffsetBuff()
    local stacks = self._proxy:GetBuffStacks(self._uuid, self._attack2ToAttack3OffsetBuff) or self._baseTimingId
    return stacks == self._buffStackEqualOne
end

function XSkill_1055003:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055003 CheckCastCondition: Base.CheckCastCondition(actionId, 0) failed")
        return false
    end

    -- Step 2: must be on ground.
    if not self:IsGroundStateMatched() then
        -- print("Skill_1055003 CheckCastCondition: ground failed")
        return false
    end

    -- Step 3: normal attack2 branch needs timing14.
    if self:IsAttack2ActionMatched() then
        return self:IsAttackTimingMatched()
    end

    -- Step 4: offset marker buff must exist.
    if not self:HasAttackOffsetBuff() then
        return false
    end

    -- Step 5: offset buff passed.
    return true
end

return XSkill_1055003
