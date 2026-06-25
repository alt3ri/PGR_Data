local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055006 : XSkillBase
local XSkill_1055006 = XDlcScriptManager.RegSkillScript(1055006, "XSkill_1055006", Base)

function XSkill_1055006:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 当前必须正在释放 1055004 或 1055029
    self._attack4Id = 1055004
    self._attack4stId = 1055029
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 检查当前动作里的技能时间类型 = 14
    self._requiredActionTimingType = 14
    -- Buff 105501101 层数等于 0
    self._prisonCellBuff = 105501101
    self._buffStackEqualZero = 0
end

function XSkill_1055006:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055006:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055006:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055006:IsBuffStackEqual(buffId, stackCount)
    local stacks = self._proxy:GetBuffStacks(self._uuid, buffId) or self._buffStackEqualZero
    return stacks == stackCount
end

function XSkill_1055006:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查，失败时不再继续判断表条件
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055006 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第三步：当前动作必须处在技能时间类型 14 内
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第四步：105501101 的 Buff 层数必须等于 0
    if not self:IsBuffStackEqual(self._prisonCellBuff, self._buffStackEqualZero) then
        return false
    end

    -- 第五步：当前动作必须是 1055004 或 1055029
    local isRequiredAction = self:IsCurrentActionMatched(self._attack4Id)
        or self:IsCurrentActionMatched(self._attack4stId)
    if not isRequiredAction then
        return false
    end

    -- 第六步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055006
