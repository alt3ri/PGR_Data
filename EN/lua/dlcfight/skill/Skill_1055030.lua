local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055030 : XSkillBase
local XSkill_1055030 = XDlcScriptManager.RegSkillScript(1055030, "XSkill_1055030", Base)

function XSkill_1055030:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 当前必须正在释放前闪或后闪
    self._frontDodgeId = 1055011
    self._backDodgeId = 1055012
    -- 检查当前闪避动作里的技能时间类型 = 12
    self._dodgeActionTimingType = 12
end

function XSkill_1055030:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055030:IsCurrentActionMatched(actionId)
    return self._proxy:CheckNpcCurrentAction(self._uuid, actionId)
end

function XSkill_1055030:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._dodgeActionTimingType)
end

function XSkill_1055030:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055030 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第三步：当前动作必须是前闪 1055011 或后闪 1055012
    local isDodgeAction = self:IsCurrentActionMatched(self._frontDodgeId)
        or self:IsCurrentActionMatched(self._backDodgeId)
    if not isDodgeAction then
        return false
    end

    -- 第四步：当前闪避动作必须处在技能时间类型 12 内
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第五步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055030
