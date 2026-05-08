---@class XUiTheatre6BubbleTagDetail : XLuaUi 标签气泡弹框
---@field _Control XTheatre6Control
---@field BubbleTagDetail UiObject
---@field BtnClose XUiComponent.XUiButton

local XUiTheatre6BubbleTagDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6BubbleTagDetail")

function XUiTheatre6BubbleTagDetail:OnAwake()
    ---@type XUiPanelTheatre6TagDetail
    self._TagDetail = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6TagDetail").New(self.BubbleTagDetail, self)
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6BubbleTagDetail:OnStart(buildTagIds, target, keyWordIds)
    self._TagDetail:Refresh(buildTagIds, keyWordIds)
    XUiHelper.ShowBubbleToTarget(self._TagDetail.PanelTagDetail.transform, target, self.Transform)
end

function XUiTheatre6BubbleTagDetail:OnEnable()

end

return XUiTheatre6BubbleTagDetail
