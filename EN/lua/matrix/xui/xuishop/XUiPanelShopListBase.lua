local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelShopListBase = XClass(nil, "XUiPanelShopListBase")

function XUiPanelShopListBase:Ctor(ui, parent, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Ui = ui
    self.Parent = parent
    self.RootUi = rootUi or parent
    self.GoodsList = {}
    self.GoodsContainer = {}
    self.GoodsOrder = {}
    self:SetCountUpdateListener()
    self:Init()
end

function XUiPanelShopListBase:SetCountUpdateListener()
    XDataCenter.ItemManager.AddCountUpdateListener(
        XDataCenter.ItemManager.ItemId.FreeGem,
        function() self:RefreshGoodsPrice() end,
        self.Ui
    )
    XDataCenter.ItemManager.AddCountUpdateListener(
        XDataCenter.ItemManager.ItemId.Coin,
        function() self:RefreshGoodsPrice() end,
        self.Ui
    )
end

function XUiPanelShopListBase:RefreshGoodsPrice()
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        v:RefreshPrice()
    end
end

function XUiPanelShopListBase:Init()
    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelShopListBase:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelShopListBase:ShowPanel(id)
    self.GameObject:SetActive(true)
    self.GoodsList = XShopManager.GetShopGoodsList(id)

    self:ShowGoods()
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataASync()
end

--动态列表事件
function XUiPanelShopListBase:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GoodsList[index]
        grid:UpdateData(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

--初始化列表
function XUiPanelShopListBase:ShowGoods()
    --商品数量显示
    if not self.GoodsList or #self.GoodsList <= 0 then
        self.TxtDesc.gameObject:SetActive(true)
        self.TxtHint.text = CS.XTextManager.GetText("ShopNoGoodsDesc")
    else
        self.TxtDesc.gameObject:SetActive(false)
        self.TxtHint.text = ""
    end

    --self:UpdateGoods()
end

--更新商品信息
function XUiPanelShopListBase:UpdateGoods(goodsId)
    for k, v in pairs(self.GoodsList) do
        if v.Id == goodsId then
            local grid = self.DynamicTable:GetGridByIndex(k)
            grid:UpdateData(v)
        end
    end
end

function XUiPanelShopListBase:SaveGoodsOrder()
    self.GoodsOrder = {}
    XShopManager.SaveGoodsOrder(self.GoodsList, self.GoodsOrder)
end

function XUiPanelShopListBase:SortByOldGoodsOrder()
    self.GoodsList = XShopManager.SortByOldGoodsOrder(self.GoodsList, self.GoodsOrder)
end

return XUiPanelShopListBase
