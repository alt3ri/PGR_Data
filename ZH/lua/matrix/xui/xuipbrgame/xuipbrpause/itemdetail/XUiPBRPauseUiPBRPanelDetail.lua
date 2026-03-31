local XUiPBRItemDetailPopupPanel = require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiPBRItemDetailPopupPanel')

---@class XUiPBRPauseUiPBRPanelDetail : XUiPBRItemDetailPopupPanel
local XUiPBRPauseUiPBRPanelDetail = XClass(XUiPBRItemDetailPopupPanel, "XUiPBRPauseUiPBRPanelDetail")


---@overload
function XUiPBRPauseUiPBRPanelDetail:OnStart()
    XUiPBRItemDetailPopupPanel.OnStart(self)

    self:SetPopupPanelRectTrans(self.PanelDetail)
end

---@overload
---@param posUi UnityEngine.RectTransform
---@param itemId number
function XUiPBRPauseUiPBRPanelDetail:RefreshItemShow(posUi, itemId)
    self:_InitViewArea()
    XUiPBRItemDetailPopupPanel.RefreshItemShow(self, posUi, itemId)
end

function XUiPBRPauseUiPBRPanelDetail:_InitViewArea()
    if not self._IsInitViewArea then
        self._IsInitViewArea = true

        local width, height = self.Transform:GetUIRectWidthHeight()

        self:SetViewArea(width, height)
    end
end

return XUiPBRPauseUiPBRPanelDetail
