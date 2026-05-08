---@class XLowMemoryControl : XControl
---@field private _Model XLowMemoryModel
local XLowMemoryControl = XClass(XControl, "XLowMemoryControl")

function XLowMemoryControl:OnInit()
end

function XLowMemoryControl:AddAgencyEvent()
end

function XLowMemoryControl:RemoveAgencyEvent()
end

function XLowMemoryControl:OnRelease()
end

return XLowMemoryControl
