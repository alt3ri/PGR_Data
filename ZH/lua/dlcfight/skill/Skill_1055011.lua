local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055011 : XSkillBase
local XSkill_1055011 = XDlcScriptManager.RegSkillScript(1055011, "XSkill_1055011", Base)

function XSkill_1055011:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 必须有摇杆输入
    self._stickExpectedHasInput = 1
    self._stickStateHasInput = 1
    self._stickInputThresholdSqr = 0.0001
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
end

function XSkill_1055011:IsStickStateMatched()
    local success, axis = self._proxy:TryGetQueryStickAxis()
    local hasInput = false
    if success and axis then
        local axisX = axis.x or 0
        local axisY = axis.y or 0
        hasInput = axisX * axisX + axisY * axisY > (self._stickInputThresholdSqr or 0.0001)
    end

    if (self._stickExpectedHasInput or 1) == (self._stickStateHasInput or 1) then
        return hasInput
    end

    return not hasInput
end

function XSkill_1055011:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055011:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055011 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须有摇杆输入
    if not self:IsStickStateMatched() then
        return false
    end

    -- 第三步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第四步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055011
