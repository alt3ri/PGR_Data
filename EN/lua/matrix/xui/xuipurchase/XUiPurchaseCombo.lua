local XUiPurchaseComboGrid = require("XUi/XUiPurchase/XUiPurchaseComboGrid")

---@class XUiPurchaseCombo:XUiNode
---@field GameObject UnityEngine.GameObject
---@field Parent XUiPurchase
local XUiPurchaseCombo = XClass(XUiNode, "XUiPurchaseCombo")

function XUiPurchaseCombo:OnStart(purchaseLBCb)
    self.PurchaseLBCb = purchaseLBCb
end

function XUiPurchaseCombo:OnEnable()
    self.GridBundleLb.gameObject:SetActiveEx(false)
end

function XUiPurchaseCombo:OnRefresh(uiType)
    uiType = uiType or self.CurUiType
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType)
    if not data then
        return
    end
    self:Open()

    if uiType then
        self.CurUiType = uiType
    end
    
    if not self.DynamicTableNormal then
        self.DynamicTableNormal = XUiHelper.DynamicTableNormal(self, self.DynamicTable, XUiPurchaseComboGrid, self.PurchaseLBCb)
    end
    local dataSource = XDataCenter.PurchaseManager.GetComboPurchaseData(uiType)
    self.DynamicTableNormal:SetDataSource(dataSource)
    self.DynamicTableNormal:ReloadDataSync()
end

-- 因为原本的panel不继承自XUiNode
function XUiPurchaseCombo:ShowPanel()
    self:Open()
end

function XUiPurchaseCombo:HidePanel()
    self:Close()
end

function XUiPurchaseCombo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTableNormal:GetData(index))
    end
end

return XUiPurchaseCombo