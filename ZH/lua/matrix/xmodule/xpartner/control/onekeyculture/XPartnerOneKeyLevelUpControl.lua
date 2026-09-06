---@class XPartnerOneKeyLevelUpControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerControl
--- 业务型子 Control：辅助机一键升级（待接入）。
local XPartnerOneKeyLevelUpControl = XClass(XControl, "XPartnerOneKeyLevelUpControl")

function XPartnerOneKeyLevelUpControl:OnInit()
    --初始化内部变量
end

function XPartnerOneKeyLevelUpControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPartnerOneKeyLevelUpControl:RemoveAgencyEvent()
end

function XPartnerOneKeyLevelUpControl:OnRelease()
end

return XPartnerOneKeyLevelUpControl
