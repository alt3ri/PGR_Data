local XUiGridCommanderDIYShop = require("XUi/XUiShop/XUiGridCommanderDIYShop")
local XUiPanelShopListBase = require("XUi/XUiShop/XUiPanelShopListBase")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPanelCommanderDIYList = XClass(XUiPanelShopListBase, "XUiPanelCommanderDIYList")

function XUiPanelCommanderDIYList:Ctor(ui, parent, rootUi, uiParams, refreshCb)
    self.UiParams = uiParams
    self.RefreshCb = refreshCb
    self.Super.Ctor(self, ui, parent, rootUi)
end

function XUiPanelCommanderDIYList:Init()
    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiGridCommanderDIYShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelCommanderDIYList:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelCommanderDIYList:ShowScreenPanel(shopId, groupId, selectTag, isKeepOrder)
    self.GameObject:SetActive(true)
    self.GoodsList = XShopManager.GetScreenGoodsListByTag(shopId, groupId, selectTag)
    if isKeepOrder then
        self:SortByOldGoodsOrder()
    else
        self:SaveGoodsOrder()
    end
    self:ShowGoods()
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelCommanderDIYList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent, self.RootUi, self.UiParams)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GoodsList[index]
        grid:UpdateData(data, self.UiParams, self.Parent:GetCurShopId())
        if self.RefreshCb then
            self.RefreshCb(grid, index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

return XUiPanelCommanderDIYList
