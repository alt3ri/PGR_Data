--- 通关攻略小窗
---@class XUiPanelTipsSmallWindow: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent
local XUiPanelTipsSmallWindow = XClass(XUiNode, "XUiPanelTipsSmallWindow")

function XUiPanelTipsSmallWindow:Refresh(tipsImg)
    self.Bg:SetRawImage(tipsImg)
end

return XUiPanelTipsSmallWindow