---@class XCommanderCollegeBannerControl : XControl
---@field private _Model XCommanderCollegeModel
---@field _MainControl XCommanderCollegeBannerControl
local XCommanderCollegeBannerControl = XClass(XControl, "XCommanderCollegeBannerControl")
function XCommanderCollegeBannerControl:OnInit()
    --初始化内部变量
end

function XCommanderCollegeBannerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCommanderCollegeBannerControl:RemoveAgencyEvent()

end

function XCommanderCollegeBannerControl:OnRelease()
end

function XCommanderCollegeBannerControl:GetBigWorldOpenFunctionMainConfigByKey(functionKey)
    return self._Model:GetBigWorldOpenFunctionMainConfigByKey(functionKey)
end

return XCommanderCollegeBannerControl
