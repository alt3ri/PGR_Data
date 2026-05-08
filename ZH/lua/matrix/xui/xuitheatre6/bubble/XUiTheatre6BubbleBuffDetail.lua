---@class XUiTheatre6BubbleBuffDetail : XLuaUi Buff气泡弹框
---@field _Control XTheatre6Control
local XUiTheatre6BubbleBuffDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6BubbleBuffDetail")

function XUiTheatre6BubbleBuffDetail:OnAwake()
    ---@type XUiPanelTheatre6BuffDetail
    self._BuffDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BuffDetail").New(self.BubbleBuffDetail, self)
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6BubbleBuffDetail:OnStart(buffId, target)
    self._BuffDetail:SetBuffId(buffId)
    self._BuffDetail:IsBuffCanClick(false)
    XUiHelper.ShowBubbleToTarget(self.BubbleBuffDetail, target, self.Transform)
end

return XUiTheatre6BubbleBuffDetail