local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055022 : XSkillBase
local XSkill_1055022 = XDlcScriptManager.RegSkillScript(1055022, "XSkill_1055022", Base)

function XSkill_1055022:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- Buff 105501106 层数等于 1
    self._dodgeSuccessBuff = 105501106
    self._buffStackEqualOne = 1
end

function XSkill_1055022:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055022:IsBuffStackEqual()
    local stacks = self._proxy:GetBuffStacks(self._uuid, self._dodgeSuccessBuff) or self._baseTimingId
    return stacks == self._buffStackEqualOne
end

function XSkill_1055022:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055022 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第三步：必须拥有 105501106 的 1 层 Buff
    if not self:IsBuffStackEqual() then
        return false
    end

    -- 第四步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055022
