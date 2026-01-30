
---@class XUiPopTeachDot : XUiNode
---@field ImgOff UnityEngine.UI.Image
---@field ImgOn UnityEngine.UI.Image
local XUiPopTeachDot = XClass(XUiNode, "XUiPopTeachDot")

function XUiPopTeachDot:Refresh(isCurrent)
    self.ImgOff.gameObject:SetActiveEx(not isCurrent)
    self.ImgOn.gameObject:SetActiveEx(isCurrent)
end

return XUiPopTeachDot
