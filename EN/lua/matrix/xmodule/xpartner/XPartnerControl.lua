---@class XPartnerControl : XControl
---@field private _Model XPartnerModel
---@field private _ConfigControl XPartnerConfigControl
---@field private _NetWorkControl XPartnerNetWorkControl
---@field private _SkillSelectViewControl XPartnerSkillSelectViewControl
local XPartnerControl = XClass(XControl, "XPartnerControl")

function XPartnerControl:OnInit()
    self._ConfigControl  = self:AddSubControl(require("XModule/XPartner/Control/XPartnerConfigControl"))
    self._NetWorkControl = self:AddSubControl(require("XModule/XPartner/Control/XPartnerNetWorkControl"))
    self._SkillSelectViewControl = self:AddSubControl(require("XModule/XPartner/Control/SkillSelect/XPartnerSkillSelectViewControl"))

    self._OneKeyCultureMainControl = self:AddSubControl(require("XModule/XPartner/Control/OneKeyCulture/XPartnerOneKeyCultureControl"))
end

function XPartnerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPartnerControl:RemoveAgencyEvent()

end

function XPartnerControl:OnRelease()
end

---region 获取子 Control
---@return XPartnerConfigControl
function XPartnerControl:GetConfigControl()
    return self._ConfigControl
end

---@return XPartnerNetWorkControl
function XPartnerControl:GetNetWorkControl()
    return self._NetWorkControl
end

---@return XPartnerSkillSelectViewControl
function XPartnerControl:GetSkillSelectViewControl()
    return self._SkillSelectViewControl
end

---@return XPartnerOneKeyCultureControl
function XPartnerControl:GetOneKeyCultureMainControl()
    return self._OneKeyCultureMainControl
end
---endregion

return XPartnerControl


