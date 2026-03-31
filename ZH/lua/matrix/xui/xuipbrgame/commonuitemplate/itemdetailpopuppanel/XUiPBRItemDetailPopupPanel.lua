local XUiCommonPopupPanel = require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiCommonPopupPanel')

---@class XUiPBRItemDetailPopupPanel: XUiCommonPopupPanel
---@field protected _Control
---@field Parent
local XUiPBRItemDetailPopupPanel = XClass(XUiCommonPopupPanel, "XUiPBRItemDetailPopupPanel")

function XUiPBRItemDetailPopupPanel:OnStart()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    ---@type XUiPBRCommonItemDetailGrid
    self.ItemDetailGrid = self:GetItemDetailGridCls().New(self.PanelDetail, self)
end

---@param posUi UnityEngine.RectTransform
---@param itemId number
function XUiPBRItemDetailPopupPanel:RefreshItemShow(posUi, itemId)
    self.ItemDetailGrid:Refresh(itemId, true)
    self:SetPosition(posUi.position, posUi.pivot)
end

--- 子类可重写
function XUiPBRItemDetailPopupPanel:GetItemDetailGridCls()
    return require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiPBRCommonItemDetailGrid')
end

return XUiPBRItemDetailPopupPanel