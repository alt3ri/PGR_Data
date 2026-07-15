local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055020 : XSkillBase
local XSkill_1055020 = XDlcScriptManager.RegSkillScript(1055020, "XSkill_1055020", Base)

function XSkill_1055020:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 属性 49 当前值必须大于等于 100
    self._attribType49 = 49
    self._attribTarget100 = 100
    -- 只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    self._groundStateValue = 2
end

function XSkill_1055020:IsAttribMatched()
    local value = self._proxy:GetNpcAttribValue(self._uuid, self._attribType49 or 49) or (self._baseTimingId or 0)
    return value >= (self._attribTarget100 or 100)
end

function XSkill_1055020:IsGroundStateMatched()
    if self._groundOnlyState == self._groundStateValue then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055020:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055020 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：属性 49 当前值必须大于等于 100
    if not self:IsAttribMatched() then
        return false
    end

    -- 第三步：必须在地面
    if not self:IsGroundStateMatched() then
        return false
    end

    -- 第四步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055020
