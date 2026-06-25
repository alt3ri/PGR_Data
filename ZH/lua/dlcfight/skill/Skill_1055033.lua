local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055033 : XSkillBase
local XSkill_1055033 = XDlcScriptManager.RegSkillScript(1055033, "XSkill_1055033", Base)

function XSkill_1055033:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- Normal branch: attack1 phase2 -> attack2 phase2.
    self._attack1Phase2Id = 1055032
    -- Offset branch: offset buff -> attack2 phase2.
    self._attack1ToAttack2OffsetBuff = 105501117
    self._buffStackEqualOne = 1
    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Timing for attack branch.
    self._requiredActionTimingType = 14
end

function XSkill_1055033:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055033:IsBuffStackEqual(buffId, stackCount)
    local stacks = self._proxy:GetBuffStacks(self._uuid, buffId) or self._baseTimingId
    return stacks == stackCount
end

function XSkill_1055033:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055033:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055033:HasAttackOffsetBuff()
    return self:IsBuffStackEqual(self._attack1ToAttack2OffsetBuff, self._buffStackEqualOne)
end

function XSkill_1055033:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055033 CheckCastCondition: Base.CheckCastCondition(actionId, 0) failed")
        return false
    end

    -- Step 2: must be on ground.
    if not self:IsGroundStateMatched() then
        return false
    end

    -- Step 3: normal phase2 attack branch needs timing14.
    if self:IsCurrentActionMatched(self._attack1Phase2Id) then
        return self:IsActionTimingMatched()
    end

    -- Step 4: offset marker buff must exist.
    if not self:HasAttackOffsetBuff() then
        return false
    end

    -- Step 5: offset buff passed.
    return true
end

return XSkill_1055033
