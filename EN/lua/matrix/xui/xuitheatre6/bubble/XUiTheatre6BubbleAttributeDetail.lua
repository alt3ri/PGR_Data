---@class XUiTheatre6BubbleAttributeDetail : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6BubbleAttributeDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6BubbleAttributeDetail")

function XUiTheatre6BubbleAttributeDetail:OnStart(attrIds, target)
    XUiHelper.ShowBubbleToTarget(self.PanelAttr, target, self.Transform)

    self.BubbleAttributeDetail.gameObject:SetActiveEx(true)
    ---@type XUiPanelTheatre6BubbleAttr
    self._AttrBubble = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BubbleAttr").New(self.BubbleAttributeDetail, self)
    self._AttrBubble:SetAttrIds(attrIds)

    if self._AttrBubble.BtnClose then
        self._AttrBubble.BtnClose.gameObject:SetActiveEx(false)
    end

    self.BtnClose:AddEventListener(handler(self, self.Close))
end

return XUiTheatre6BubbleAttributeDetail