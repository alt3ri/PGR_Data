local XCommanderCollegeBannerControl = require("XModule/XCommanderCollege/SubControl/XCommanderCollegeBannerControl")

---@class XCommanderCollegeControl : XControl
---@field private _Model XCommanderCollegeModel
---@field BigWorldCollegeBannerSubControl XCommanderCollegeBannerControl
local XCommanderCollegeControl = XClass(XControl, "XCommanderCollegeControl")
function XCommanderCollegeControl:OnInit()
    --初始化内部变量
    self.CollegeBannerControl = self:AddSubControl(XCommanderCollegeBannerControl)
end

function XCommanderCollegeControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCommanderCollegeControl:RemoveAgencyEvent()

end

function XCommanderCollegeControl:OnRelease()
    self.CollegeBannerControl = nil
end

return XCommanderCollegeControl