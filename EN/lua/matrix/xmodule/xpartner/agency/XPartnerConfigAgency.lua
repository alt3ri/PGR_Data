--- 辅助机配置子 Agency，负责配置表初始化与 CO 前缀的配置查询接口
---@class XPartnerConfigAgency : XAgency
---@field private _Model XPartnerModel
---@field private _MainAgency XPartnerAgency
local XPartnerConfigAgency = XClass(XAgency, "XPartnerConfigAgency")

local TableKey = {
    --示例: PartnerTemplate = { CacheType = XConfigUtil.CacheType.Normal },
}

function XPartnerConfigAgency:OnInit()
    --有配置表后再打开初始化
    --self:InitConfigByTabKey("Partner", TableKey)
end

--region ----------public start----------

--示例: 配置查询接口统一使用 CO 前缀
-----@param id number
-----@return any
--function XPartnerConfigAgency:GetCOPartnerTemplateById(id)
--    return self:GetConfigByTableKey(TableKey.PartnerTemplate, id)
--end

--endregion ----------public end----------

return XPartnerConfigAgency
