local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055034 : XSkillBase
local XSkill_1055034 = XDlcScriptManager.RegSkillScript(1055034, "XSkill_1055034", Base)

function XSkill_1055034:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- Normal branch: attack2 phase2 -> attack3 phase2.
    self._attack2Phase2Id = 1055033
    -- Offset branch: offset buff -> attack3 phase2.
    self._attack2ToAttack3OffsetBuff = 105501118
    self._buffStackEqualOne = 1
    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Timing for attack branch.
    self._requiredActionTimingType = 14
end

function XSkill_1055034:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055034:IsBuffStackEqual(buffId, stackCount)
    local stacks = self._proxy:GetBuffStacks(self._uuid, buffId) or self._baseTimingId
    return stacks == stackCount
end

function XSkill_1055034:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055034:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055034:HasAttackOffsetBuff()
    return self:IsBuffStackEqual(self._attack2ToAttack3OffsetBuff, self._buffStackEqualOne)
end

function XSkill_1055034:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055034 CheckCastCondition: Base.CheckCastCondition(actionId, 0) failed")
        return false
    end

    -- Step 2: must be on ground.
    if not self:IsGroundStateMatched() then
        return false
    end

    -- Step 3: normal phase2 attack branch needs timing14.
    if self:IsCurrentActionMatched(self._attack2Phase2Id) then
        return self:IsActionTimingMatched()
    end

    -- Step 4: offset marker buff must exist.
    if not self:HasAttackOffsetBuff() then
        return false
    end

    -- Step 5: offset buff passed.
    return true
end

return XSkill_1055034
