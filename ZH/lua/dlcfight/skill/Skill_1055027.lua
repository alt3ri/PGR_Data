local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055027 : XSkillBase
local XSkill_1055027 = XDlcScriptManager.RegSkillScript(1055027, "XSkill_1055027", Base)

function XSkill_1055027:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._baseTimingId = 0
    -- 只能在空中释放，1 表示空中
    self._airOnlyState = 1
    self._airStateValue = 1
end

function XSkill_1055027:IsAirStateMatched()
    if self._airOnlyState == self._airStateValue then
        return self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055027:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查
    if not Base.CheckCastCondition(self, actionId, self._baseTimingId) then
        -- print("Skill_1055027 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须在空中
    if not self:IsAirStateMatched() then
        return false
    end

    -- 第三步：以上条件都满足时，允许释放
    return true
end

return XSkill_1055027
