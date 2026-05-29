---@class XUiTheatre6BubbleRelicDetail : XLuaUi 遗物气泡弹框
---@field _Control XTheatre6Control
---@field BubbleRelicDetail UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton

local XUiTheatre6BubbleRelicDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6BubbleRelicDetail")

function XUiTheatre6BubbleRelicDetail:OnAwake()
    ---@type XUiGridTheatre6RelicDetail
    self._Bubble = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6RelicDetail").New(self.BubbleRelicDetail, self)
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6BubbleRelicDetail:OnStart(attrPackId, tran, param, avoidTransforms)
    self._Bubble:Refresh(attrPackId, param)
    XUiHelper.ShowBubbleToTarget(self.BubbleRelicDetail, tran, self.Transform, avoidTransforms)
end

function XUiTheatre6BubbleRelicDetail:OnEnable()

end

return XUiTheatre6BubbleRelicDetail
