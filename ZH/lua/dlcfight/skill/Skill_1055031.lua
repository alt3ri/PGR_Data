local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055031 : XSkillBase
local XSkill_1055031 = XDlcScriptManager.RegSkillScript(1055031, "XSkill_1055031", Base)

function XSkill_1055031:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 当前必须正在释放蓝球1
    self._blue1Id = 1055030
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
    -- 检查当前动作里的技能时间类型 = 14
    self._requiredActionTimingType = 14
end

function XSkill_1055031:IsCurrentActionMatched()
    return self._proxy:CheckNpcCurrentAction(self._uuid, self._blue1Id)
end

function XSkill_1055031:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055031:IsActionTimingMatched()
    return self._proxy:CheckActionTiming(self._uuid, self._requiredActionTimingType)
end

function XSkill_1055031:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055031 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：当前动作必须是蓝球1
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

return XSkill_1055031
