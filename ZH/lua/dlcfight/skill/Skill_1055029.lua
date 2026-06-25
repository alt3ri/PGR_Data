local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055029 : XSkillBase
local XSkill_1055029 = XDlcScriptManager.RegSkillScript(1055029, "XSkill_1055029", Base)

function XSkill_1055029:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0

    -- Normal branch: attack3/open-buff/attack3 phase branch -> attack4st.
    self._attack3Id = 1055003
    self._attack4OpenBuff = 105501107
    self._attack3Phase1Id = 1055034
    -- Offset branch: offset buff -> attack4st.
    self._attack3ToAttack4OffsetBuff = 105501119
    self._buffStackEqualOne = 1
    -- Ground only.
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Timing for normal branch.
    self._requiredActionTimingType = 14
end

function XSkill_1055029:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055029:IsBuffStackEqual(buffId, stackCount)
    local stacks = self._proxy:GetBuffStacks(self._uuid, buffId) or self._baseTimingId
    return stacks == stackCount
end

function XSkill_1055029:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055029:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055029:HasAttackOffsetBuff()
    return self:IsBuffStackEqual(self._attack3ToAttack4OffsetBuff, self._buffStackEqualOne)
end

function XSkill_1055029:IsNormalBranchSourceMatched()
    if self:IsCurrentActionMatched(self._attack3Id) then
        return true
    end

    if self:IsCurrentActionMatched(self._attack3Phase1Id) then
        return true
    end

    if self:IsBuffStackEqual(self._attack4OpenBuff, self._buffStackEqualOne) then
        return true
    end

    return false
end

function XSkill_1055029:CheckNormalBranch()
    if not self:IsNormalBranchSourceMatched() then
        return false
    end

    return self:IsActionTimingMatched()
end

function XSkill_1055029:CheckOffsetBranch()
    if not self:HasAttackOffsetBuff() then
        return false
    end

    return true
end

function XSkill_1055029:CheckCastCondition(actionId)
    -- Step 1: run base cast checks first.
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055029 CheckCastCondition: Base.CheckCastCondition(actionId, 0) failed")
        return false
    end

    -- Step 2: must be on ground.
    if not self:IsGroundStateMatched() then
        return false
    end

    -- Step 3: attack3/open-window branch must pass timing14.
    if self:IsNormalBranchSourceMatched() then
        return self:CheckNormalBranch()
    end

    -- Step 4: offset branch.
    return self:CheckOffsetBranch()
end

return XSkill_1055029
