local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055026 : XSkillBase
local XSkill_1055026 = XDlcScriptManager.RegSkillScript(1055026, "XSkill_1055026", Base)

function XSkill_1055026:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 当前必须正在释放 1055025
    self._attack5ExChargeId = 1055025
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 检查当前动作里的技能时间类型 = 14
    self._requiredActionTimingType = 14
end

function XSkill_1055026:IsCurrentActionMatched()
    return self._proxy:CheckNpcCurrentAction(self._uuid, self._attack5ExChargeId)
end

function XSkill_1055026:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055026:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055026:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055026 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：当前动作必须是 1055025
    if not self:IsCurrentActionMatched() then
        return false
    end

    -- 第三步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第四步：必须处在技能时间类型 14 内
    if not self:IsActionTimingMatched() then
        return false
    end

    -- 第五步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055026
