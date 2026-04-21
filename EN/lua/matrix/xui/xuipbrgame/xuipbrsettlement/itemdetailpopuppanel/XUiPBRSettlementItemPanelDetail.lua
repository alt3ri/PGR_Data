local XUiPBRItemDetailPopupPanel = require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiPBRItemDetailPopupPanel')

---@class XUiPBRSettlementItemPanelDetail : XUiPBRItemDetailPopupPanel
local XUiPBRSettlementItemPanelDetail = XClass(XUiPBRItemDetailPopupPanel, "XUiPBRSettlementItemPanelDetail")

---@overload
function XUiPBRSettlementItemPanelDetail:OnStart()
    XUiPBRItemDetailPopupPanel.OnStart(self)
    
    self:SetPopupPanelRectTrans(self.PanelDetail)
end

---@overload
---@param posUi UnityEngine.RectTransform
---@param itemId number
function XUiPBRSettlementItemPanelDetail:RefreshItemShow(posUi, itemId)
    self:_InitViewArea()
    XUiPBRItemDetailPopupPanel.RefreshItemShow(self, posUi, itemId)
end

function XUiPBRSettlementItemPanelDetail:_InitViewArea()
    if not self._IsInitViewArea then
        self._IsInitViewArea = true
        
        local width, height = self.Transform:GetUIRectWidthHeight()
        
        self:SetViewArea(width, height)
    end
end

return XUiPBRSettlementItemPanelDetail
