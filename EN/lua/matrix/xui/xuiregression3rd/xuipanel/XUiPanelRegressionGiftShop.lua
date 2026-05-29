local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")
local XUiGridRegressionGift = require("XUi/XUiRegression3rd/XUiGrid/XUiGridRegressionGift")

local XUiPanelRegressionGiftShop = XClass(XUiPanelRegressionBase, "XUiPanelRegressionGiftShop")

function XUiPanelRegressionGiftShop:Show()
    self:Open()
end

function XUiPanelRegressionGiftShop:Hide()
    self:Close()
end

function XUiPanelRegressionGiftShop:OnStart()
    self.ViewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self.GridShop.gameObject:SetActiveEx(false)
    self._DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self._DynamicTable:SetProxy(XUiGridRegressionGift)
    self._DynamicTable:SetDelegate(self)

    local uiType = self.ViewModel:GetPackageUiType()
    self.UiType = uiType
    self:_RefreshPurchaseList()

    XDataCenter.Regression3rdManager.MarkGiftShopRedPointData()
end

function XUiPanelRegressionGiftShop:_RefreshPurchaseList()
    local uiType = self.UiType
    XDataCenter.PurchaseManager.GetPurchaseListRequest( { uiType }, function()
        local purchaseList = XDataCenter.PurchaseManager.GetDatasByUiType(uiType) or {}
        self:_SetPurchaseList(purchaseList)
    end)
end

function XUiPanelRegressionGiftShop:_SetPurchaseList(purchaseList)
    table.sort(purchaseList, function(a, b)
        local aSellOut = a.BuyLimitTimes and a.BuyLimitTimes > 0 and a.BuyTimes >= a.BuyLimitTimes
        local bSellOut = b.BuyLimitTimes and b.BuyLimitTimes > 0 and b.BuyTimes >= b.BuyLimitTimes
        if aSellOut ~= bSellOut then
            return bSellOut
        end
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
        return a.Id < b.Id
    end)

    self._PurchaseList = purchaseList
    self._DynamicTable:SetDataSource(self._PurchaseList)
    self._DynamicTable:ReloadDataSync()
end

function XUiPanelRegressionGiftShop:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(handler(self, self._RefreshPurchaseList))
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._PurchaseList[idx])
    end
end

return XUiPanelRegressionGiftShop
