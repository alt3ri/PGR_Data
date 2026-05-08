---@class XUiPanelRewardShopShop : XUiNode
---@field _Control XGameCollectionControl


local XUiPanelRewardShopShop = XLuaUiManager.Register(XUiNode, "XUiPanelRewardShopShop")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")

function XUiPanelRewardShopShop:InitComponents()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShopList.gameObject)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelRewardShopShop:OnStart(...)
    self:InitComponents()


end

function XUiPanelRewardShopShop:Refresh()
    self:RefreshGoodsList()
end

function XUiPanelRewardShopShop:RefreshGoodsList()
    local shopId = tonumber(self._Control:GetGameCollectionConfig("shopId"))
    if not XTool.IsNumberValid(shopId) then
        return
    end
    XShopManager.GetShopInfo(shopId, function()
        self.GoodsList = XShopManager.GetShopGoodsList(shopId)
        self.DynamicTable:SetDataSource(self.GoodsList)
        self.DynamicTable:ReloadDataASync(1)

        self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.GoodsList))
    end)
end

function XUiPanelRewardShopShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GoodsList[index]
        grid:UpdateData(data)
        grid:RefreshShowLock()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiPanelRewardShopShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, function()
        if cb then
            cb()
        end
        self:RefreshGoodsList()
        self.Parent.BtnShop:ShowReddot(XMVCA.XGameCollection:HasGoodCanBuy())
    end)
end

function XUiPanelRewardShopShop:SetUiSprite(imgQuality, spriteName)
    imgQuality:SetSprite(spriteName)
end

return XUiPanelRewardShopShop
