local tableInsert = table.insert
local tableSort = table.sort
local stringFormat = string.format

---@class XUiPanelAreaWarAuctionBuy : XUiNode
---@field private _Control XAreaWarControl
---@field Parent XUiAreaWarAuction
local XUiPanelAreaWarAuctionBuy = XClass(XUiNode, "XUiPanelAreaWarAuctionBuy")

function XUiPanelAreaWarAuctionBuy:OnStart()
    self.BtnCloseDropdown.gameObject:SetActiveEx(false)
    self.QualityList.gameObject:SetActiveEx(false)
    self.TAB_ALL = 0
    self.IsOpenQualityDropdown = false
    self.SelectedQuality = self.TAB_ALL
    
    self:RegisterUiEvents()
    self:InitDynamicTable()
    self:InitQualityTabList()
end

function XUiPanelAreaWarAuctionBuy:OnDestroy()
    
end

function XUiPanelAreaWarAuctionBuy:OnGetLuaEvents()
    return {
        XEventId.EVENT_AREA_WAR_ITEM_ROOM_SHOP_CHANGE
    }
end

function XUiPanelAreaWarAuctionBuy:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_ITEM_ROOM_SHOP_CHANGE then
        self:RefreshItemList()
    end
end

function XUiPanelAreaWarAuctionBuy:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCurQuality, self.OnBtnCurQualityClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDropdown, self.CloseDropdown, nil, true)
end

function XUiPanelAreaWarAuctionBuy:OnBtnCurQualityClick()
    self.IsOpenQualityDropdown = not self.IsOpenQualityDropdown
    if self.IsOpenQualityDropdown then
        self:OpenDropdown()
        self:RefreshQualityTabSelected()
    else
        self:CloseDropdown()
    end
end

function XUiPanelAreaWarAuctionBuy:OpenDropdown()
    self.IsOpenQualityDropdown = true
    self:RefreshDropdown()
end

function XUiPanelAreaWarAuctionBuy:CloseDropdown()
    self.IsOpenQualityDropdown = false
    self:RefreshDropdown()
end

function XUiPanelAreaWarAuctionBuy:RefreshDropdown()
    local isOpen = self.IsOpenQualityDropdown
    self.BtnCloseDropdown.gameObject:SetActiveEx(isOpen)
    self.QualityList.gameObject:SetActiveEx(isOpen)
    self.ImgArrowDownNormal.gameObject:SetActiveEx(not isOpen)
    self.ImgArrowDownPress.gameObject:SetActiveEx(not isOpen)
    self.ImgArrowUpNormal.gameObject:SetActiveEx(isOpen)
    self.ImgArrowUpPress.gameObject:SetActiveEx(isOpen)
end

function XUiPanelAreaWarAuctionBuy:Refresh()
    XMVCA.XAreaWar:RequestAreaWar4AuctionInfo(function()
        self:OnQualityTabClick(self.SelectedQuality)
    end)
end

function XUiPanelAreaWarAuctionBuy:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridAreaWarBuyItem = require("XUi/XUiAreaWar/XUiGridAreaWarBuyItem")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelShoplist)
    self.DynamicTable:SetProxy(XUiGridAreaWarBuyItem, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新藏品列表
function XUiPanelAreaWarAuctionBuy:RefreshItemList()
    local skipBuyItemId = self.Parent:GetSkipBuyItemId()
    local itemConfigDic = self._Control:GetConfig():GetConfigItem()
    self.ItemConfigs = {}
    for _, itemConfig in pairs(itemConfigDic) do
        if itemConfig.Quality == self.SelectedQuality or self.SelectedQuality == self.TAB_ALL then
            tableInsert(self.ItemConfigs, itemConfig)
        end
    end
    tableSort(self.ItemConfigs, function(a, b)
        -- 跳转进来购买某个Id的商品，这个Id排最前面
        local isSkipItemA = a.ItemId == skipBuyItemId
        local isSkipItemB = b.ItemId == skipBuyItemId
        if isSkipItemA ~= isSkipItemB then
            return isSkipItemA
        end
        
        -- 已解锁的优先
        local isUnlockA = self._Control:IsItemUnlock(a.ItemId)
        local isUnlockB = self._Control:IsItemUnlock(b.ItemId)
        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end
        
        -- 品质高的排前面
        if a.Quality ~= b.Quality then
            return a.Quality > b.Quality
        end
        
        -- Id小的排前面
        return a.ItemId < b.ItemId
    end)
    
    self.DynamicTable:SetDataSource(self.ItemConfigs)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridAreaWarBuyItem
function XUiPanelAreaWarAuctionBuy:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local config = self.ItemConfigs[index]
        grid:SetItemId(config.ItemId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local itemId = self.ItemConfigs[index].ItemId

        -- 未解锁提示
        local isUnlock = self._Control:IsItemUnlock(itemId)
        if not isUnlock then
            local tips = XAreaWarConfigs.GetItemDetailUnlockTips()
            local unlockLv = self._Control:GetConfig():GetItemUnlockLv(itemId)
            XUiManager.TipError(stringFormat(tips, unlockLv))
            return
        end
        
        -- 已过期，重新请求数据
        local isDataValid = self._Control:GetAuction():IsDataValid()
        if not isDataValid then
            XMVCA.XAreaWar:RequestAreaWar4AuctionInfo(function()
                self:RefreshItemList()
                self:OnItemClick(itemId)
            end)
        else
            self:OnItemClick(itemId)
        end
    end
end

function XUiPanelAreaWarAuctionBuy:OnItemClick(itemId)
    -- 补货中提示
    local isExit = self._Control:GetAuction():IsExitItem(itemId)
    if not isExit then
        local tips = XAreaWarConfigs.GetAuctionBuyNoEnoughShopTips()
        XUiManager.TipError(tips)
        return
    end

    -- 弹出购买界面
    XMVCA.XAreaWar:RequestAreaWar4AuctionInfo(function()
        XLuaUiManager.Open("UiAreaWarPopupBuy", itemId)
    end)
end

function XUiPanelAreaWarAuctionBuy:InitQualityTabList()
    self.QualityObjDic = {}
    self.QualityItem.gameObject:SetActiveEx(false)
    local qualityIds = self._Control:GetConfig():GetItemQualityIdsWithOrder()
    tableInsert(qualityIds, 1, self.TAB_ALL)
    
    for _, qualityId in pairs(qualityIds) do
        local go = XUiHelper.Instantiate(self.QualityItem.gameObject, self.QualityItem.transform.parent)
        go.gameObject:SetActiveEx(true)
        local uiObj = go:GetComponent(typeof(CS.UiObject))
        local qualityName = qualityId == self.TAB_ALL and XAreaWarConfigs.GetQualityTabAll() or self._Control:GetConfig():GetItemQualityName(qualityId)
        uiObj:GetObject("TxtName").text = qualityName
        uiObj:GetObject("Select").gameObject:SetActiveEx(false)
        self.QualityObjDic[qualityId] = uiObj
        local tempQualityId = qualityId
        XUiHelper.RegisterClickEvent(self, uiObj:GetObject("Button"), function()
            self:OnQualityTabClick(tempQualityId)
        end, nil, true)
    end
end

function XUiPanelAreaWarAuctionBuy:OnQualityTabClick(qualityId)
    self.SelectedQuality = qualityId
    local qualityName = qualityId == self.TAB_ALL and XAreaWarConfigs.GetQualityTabAll() or self._Control:GetConfig():GetItemQualityName(qualityId)
    self.BtnCurQuality:SetName(qualityName)
    self:CloseDropdown()
    self:RefreshItemList()
end

-- 刷新品质下拉列表的选中状态
function XUiPanelAreaWarAuctionBuy:RefreshQualityTabSelected()
    for qualityId, uiObj in pairs(self.QualityObjDic) do
        local isSelected = qualityId == self.SelectedQuality
        uiObj:GetObject("Select").gameObject:SetActiveEx(isSelected)
    end
end

return XUiPanelAreaWarAuctionBuy
