local XUiPBRItemDetailPopupPanel = require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiPBRItemDetailPopupPanel')

---@class XUiPBRGeniusItemPopupPanelDetail : XUiPBRItemDetailPopupPanel
local XUiPBRGeniusItemPopupPanelDetail = XClass(XUiPBRItemDetailPopupPanel, "XUiPBRGeniusItemPopupPanelDetail")

---@overload
function XUiPBRGeniusItemPopupPanelDetail:OnStart()
    XUiPBRItemDetailPopupPanel.OnStart(self)
    
    self:SetPopupPanelRectTrans(self.PanelDetail)
end

---@overload
---@param posUi UnityEngine.RectTransform
---@param itemId number
function XUiPBRGeniusItemPopupPanelDetail:RefreshItemShow(posUi, itemId)
    self:_InitViewArea()
    XUiPBRItemDetailPopupPanel.RefreshItemShow(self, posUi, itemId)
end

function XUiPBRGeniusItemPopupPanelDetail:_InitViewArea()
    if not self._IsInitViewArea then
        self._IsInitViewArea = true
        
        local width, height = self.Transform:GetUIRectWidthHeight()
        
        self:SetViewArea(width, height)
    end
end

return XUiPBRGeniusItemPopupPanelDetail
