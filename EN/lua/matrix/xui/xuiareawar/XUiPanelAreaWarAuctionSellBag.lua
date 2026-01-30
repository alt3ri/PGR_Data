---@class XUiPanelAreaWarAuctionSellBag : XUiNode
---@field private _Control XAreaWarControl
local XUiPanelAreaWarAuctionSellBag = XClass(XUiNode, "XUiPanelAreaWarAuctionSellBag")

function XUiPanelAreaWarAuctionSellBag:OnStart()
    self:InitDynamicTable()
    self:RegisterUiEvents()
end

function XUiPanelAreaWarAuctionSellBag:OnGetLuaEvents()
    return {
        XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE
    }
end

function XUiPanelAreaWarAuctionSellBag:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_ITEM_ROOM_ITEM_CHANGE then
        self:RefreshItemList()
    end
end

function XUiPanelAreaWarAuctionSellBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnAllSell, self.OnBtnAllSellClick, nil, true)
end

function XUiPanelAreaWarAuctionSellBag:OnBtnAllSellClick()
    XLuaUiManager.Open("UiAreaWarPopupSellAll")
end

function XUiPanelAreaWarAuctionSellBag:Refresh()
    self:RefreshItemList()
end

function XUiPanelAreaWarAuctionSellBag:InitDynamicTable()
    self.GridBag.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBagList)
    self.DynamicTable:SetProxy(XUiGridAreaWarItem, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新藏品列表
function XUiPanelAreaWarAuctionSellBag:RefreshItemList()
    local isInGuide = XDataCenter.GuideManager.CheckIsInGuide()
    self.ItemDataList = self._Control:GetOwnItemDataList(isInGuide)
    self.DynamicTable:SetDataSource(self.ItemDataList)
    self.DynamicTable:ReloadDataSync()
    self.TxtBagEmpty.gameObject:SetActiveEx(#self.ItemDataList == 0)
end

---@param grid XUiGridAreaWarItem
function XUiPanelAreaWarAuctionSellBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local item = self.ItemDataList[index]
        grid:RefreshItem(item.ItemId, item.Num)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnItemClick(index)
    end
end

function XUiPanelAreaWarAuctionSellBag:OnItemClick(index)
    local itemId = self.ItemDataList[index].ItemId
    XMVCA.XAreaWar:RequestAreaWar4AuctionInfo(function()
        XLuaUiManager.Open("UiAreaWarPopupSell", itemId)
    end)
end

return XUiPanelAreaWarAuctionSellBag
