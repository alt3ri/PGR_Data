---@class XPartnerConfigControl : XControl
--- 配置唯一门面 + 来源隔离层：所有配置读取/修改都经此，调用方不需知道配置来源。
local XPartnerConfigControl = XClass(XControl, "XPartnerConfigControl")

function XPartnerConfigControl:OnInit()
end

function XPartnerConfigControl:AddAgencyEvent()
end

function XPartnerConfigControl:RemoveAgencyEvent()
end

function XPartnerConfigControl:OnRelease()
end

---region 配置表（转调 Agency 的 CO 接口）
--function XPartnerConfigControl:GetPartnerCOByid(idKey)
--    return self:GetAgency():COGetPartnerCOByid(idKey)
--end
---endregion

---region 全局常量读取（CS.XGame.Config / CS.XGame.ClientConfig）
--function XPartnerConfigControl:GetXxx()
--    return CS.XGame.Config:GetInt("PartnerXxx")
--end
---endregion

---region 辅助机技能常量
function XPartnerConfigControl:GetMainSkillCount()
    return XPartnerConfigs.MainSkillCount
end

function XPartnerConfigControl:GetPassiveSkillCount()
    return XPartnerConfigs.PassiveSkillCount
end

function XPartnerConfigControl:GetSkillType()
    return XPartnerConfigs.SkillType
end
---endregion

return XPartnerConfigControl
