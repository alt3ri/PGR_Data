local XUiPurchaseComboSubGrid = require("XUi/XUiPurchase/XUiPurchaseComboSubGrid")

---@class XUiPurchaseComboGrid : XUiNode
local XUiPurchaseComboGrid = XClass(XUiNode, "XUiPurchaseComboGrid")

function XUiPurchaseComboGrid:OnStart(purchaseCb)
    self._PurchaseCb = purchaseCb
    ---@type XUiPurchaseComboSubGrid
    self._GridMain = XUiPurchaseComboSubGrid.New(self.PanelLbItemMain, self, purchaseCb)
    ---@type XUiPurchaseComboSubGrid[]
    self._Grids = {}
    self.PanelLbItemSub.gameObject:SetActiveEx(false)
end

---@param data XPurchaseComboData
function XUiPurchaseComboGrid:Update(data)
    self._GridMain:Update(data)
    XTool.UpdateDynamicItem(self._Grids, data.SubDatas, self.PanelLbItemSub, XUiPurchaseComboSubGrid, self)

    if not XTool.IsTableEmpty(self._Grids) then
        for i, v in pairs(self._Grids) do
            v:SetCallBack(self._PurchaseCb)
        end
    end
end

function XUiPurchaseComboGrid:UpdateAllData()
    self.Parent:OnRefresh()
end

return XUiPurchaseComboGrid