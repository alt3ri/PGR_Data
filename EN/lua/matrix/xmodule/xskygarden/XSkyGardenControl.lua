local XBigWorldControl = require("XModule/XBigWorld/XBigWorldControl")
---@class XSkyGardenControl : XBigWorldControl
---@field private _Model XSkyGardenModel
---@field private _Agency XSkyGardenAgency
local XSkyGardenControl = XClass(XBigWorldControl, "XSkyGardenControl")
function XSkyGardenControl:OnInit()
    XBigWorldControl.OnInit(self)
end

function XSkyGardenControl:OnRelease()
    XBigWorldControl.OnRelease(self)
end

return XSkyGardenControl