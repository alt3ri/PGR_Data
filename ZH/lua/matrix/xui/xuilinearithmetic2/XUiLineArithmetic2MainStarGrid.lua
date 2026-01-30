---@class XUiLineArithmetic2MainStarGrid : XUiNode
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2MainStarGrid = XClass(XUiNode, "XUiLineArithmetic2MainStarGrid")

function XUiLineArithmetic2MainStarGrid:Update(isActive)
    if isActive then
        self.ImgStarOff.gameObject:SetActiveEx(false)
        self.ImgStarOn.gameObject:SetActiveEx(true)
    else
        self.ImgStarOff.gameObject:SetActiveEx(true)
        self.ImgStarOn.gameObject:SetActiveEx(false)
    end
end

return XUiLineArithmetic2MainStarGrid