local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

--- 延伸块的延伸部分，标准尺寸的格子
---@class XUiGridDyeMergeExtendPart: XUiGridDyeMerge
---@field protected _Control
---@field Parent
local XUiGridDyeMergeExtendPart = XClass(XUiGridDyeMerge, "XUiGridDyeMergeExtendPart")

function XUiGridDyeMergeExtendPart:PlayEnableAnim(cb)
    if self:GetTimelineTransform("Enable") then
        self:Open()
        self:PlayAnimation("Enable", cb)
    else
        self:Open()
        if cb then cb() end
    end
end

function XUiGridDyeMergeExtendPart:PlayDisableAnim(cb)
    if self:GetTimelineTransform("Disable") then
        self:PlayAnimation("Disable", cb)
    else
        if cb then cb() end
    end
end

return XUiGridDyeMergeExtendPart