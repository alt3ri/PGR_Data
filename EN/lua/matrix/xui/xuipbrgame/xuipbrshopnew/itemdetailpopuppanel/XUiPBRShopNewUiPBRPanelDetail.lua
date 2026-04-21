local XUiPBRItemDetailPopupPanel = require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiPBRItemDetailPopupPanel')

---@class XUiPBRShopNewUiPBRPanelDetail : XUiPBRItemDetailPopupPanel
local XUiPBRShopNewUiPBRPanelDetail = XClass(XUiPBRItemDetailPopupPanel, "XUiPBRShopNewUiPBRPanelDetail")

---@overload
function XUiPBRShopNewUiPBRPanelDetail:OnStart()
    XUiPBRItemDetailPopupPanel.OnStart(self)
    
    self:SetPopupPanelRectTrans(self.PanelDetail)
end

---@overload
---@param posUi UnityEngine.RectTransform
---@param itemId number
function XUiPBRShopNewUiPBRPanelDetail:RefreshItemShow(posUi, itemId)
    self:_InitViewArea()
    XUiPBRItemDetailPopupPanel.RefreshItemShow(self, posUi, itemId)
end

function XUiPBRShopNewUiPBRPanelDetail:_InitViewArea()
    if not self._IsInitViewArea then
        self._IsInitViewArea = true
        
        local width, height = self.Transform:GetUIRectWidthHeight()
        
        self:SetViewArea(width, height)
    end
end

return XUiPBRShopNewUiPBRPanelDetail
