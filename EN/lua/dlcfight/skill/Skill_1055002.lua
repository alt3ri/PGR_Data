local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055002 : XSkillBase
local XSkill_1055002 = XDlcScriptManager.RegSkillScript(1055002, "XSkill_1055002", Base)

function XSkill_1055002:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- Normal branch: attack1 -> attack2.
    self._attack1Id = 1055001
    -- Offset branch: offset buff -> attack2.
    self._attack1ToAttack2OffsetBuff = 105501117
    self._buffStackEqualOne = 1
    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Timing for attack1.
    self._requiredActionTimingType = 14
end

function XSkill_1055002:IsAttack1ActionMatched()
    return self._proxy:CheckNpcCurrentAction(self._uuid, self._attack1Id)
end

function XSkill_1055002:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055002:IsAttackTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055002:HasAttackOffsetBuff()
    local stacks = self._proxy:GetBuffStacks(self._uuid, self._attack1ToAttack2OffsetBuff) or self._baseTimingId
    return stacks == self._buffStackEqualOne
end

function XSkill_1055002:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055002 CheckCastCondition: Base.CheckCastCondition(actionId, 0) failed")
        return false
    end

    -- Step 2: must be on ground.
    if not self:IsGroundStateMatched() then
        -- print("Skill_1055002 CheckCastCondition: ground failed")
        return false
    end

    -- Step 3: normal attack1 branch needs timing14.
    if self:IsAttack1ActionMatched() then
        return self:IsAttackTimingMatched()
    end

    -- Step 4: offset marker buff must exist.
    if not self:HasAttackOffsetBuff() then
        return false
    end

    -- Step 5: offset buff passed.
    return true
end

return XSkill_1055002
