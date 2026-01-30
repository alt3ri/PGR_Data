---@class XUiAreaWarPopupSellAll : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarPopupSellAll = XLuaUiManager.Register(XLuaUi, "UiAreaWarPopupSellAll")

function XUiAreaWarPopupSellAll:OnAwake()
    self.QualitySelectedDic = {} -- 选中品质
    self.ItemDataList = {} -- 道具列表
    self.ItemSelectedDic = {} -- 道具选中，key为ItemDataList的下标
    self.SELL_RATE = XAreaWarConfigs.GetAuctionSellRate() -- 出售手续费万分比，配置1000则为10%
    
    self.PanelTips.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitTokenIcon()
    self:InitTabList()
    self:InitDynamicTable()
end

function XUiAreaWarPopupSellAll:OnStart()
    
end

function XUiAreaWarPopupSellAll:OnEnable()
    self:Refresh()
end

function XUiAreaWarPopupSellAll:OnDisable()
    
end

function XUiAreaWarPopupSellAll:OnDestroy()
    
end

function XUiAreaWarPopupSellAll:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSell, self.OnBtnSellClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.PanelTips, self.OnPanelTipsClick)
end

function XUiAreaWarPopupSellAll:OnBtnCloseClick()
    self:Close()
end

function XUiAreaWarPopupSellAll:OnBtnSellClick()
    local sellItems = {}
    for index, isSelected in pairs(self.ItemSelectedDic) do
        if isSelected then
            local item = self.ItemDataList[index]
            local defaultPrice = self:GetSellPrice(item.ItemId)
            table.insert(sellItems, {
                ItemId = item.ItemId,
                Num = item.Num,
                Price = defaultPrice,
            })
        end
    end
    if #sellItems == 0 then return end

    XMVCA.XAreaWar:RequestAreaWar4AuctionPutOn(sellItems)
    self:Close()
end

function XUiAreaWarPopupSellAll:OnBtnHelpClick()
    self.PanelTips.gameObject:SetActiveEx(true)
end

function XUiAreaWarPopupSellAll:OnPanelTipsClick()
    self.PanelTips.gameObject:SetActiveEx(false)
end

function XUiAreaWarPopupSellAll:OnQualityTabClick(qualityId)
    local isSelected = self.QualitySelectedDic[qualityId] ~= true
    self.QualitySelectedDic[qualityId] = isSelected
    local uiObj = self.QualityObjDic[qualityId]
    uiObj:GetObject("ImgSelectNormal").gameObject:SetActiveEx(isSelected)
    uiObj:GetObject("ImgSelectPress").gameObject:SetActiveEx(isSelected)
    
    local selItemNum = {}
    -- 刷新Item
    for i, itemData in ipairs(self.ItemDataList) do
        local itemId = itemData.ItemId
        local num = itemData.Num
        local selNum = selItemNum[itemId] or 0
        local itemQualityId = self._Control:GetConfig():GetItemQuality(itemId)
        if qualityId == itemQualityId then
            local sellTipsType = self._Control:GetConfig():GetItemQualitySellTipsType(itemQualityId)
            if isSelected and sellTipsType == XMVCA.XAreaWar.EnumConst.SELL_TIPS_TYPE.KEEP_ONE then
                local allNum = self._Control:GetItemRoom():GetItemNum(itemId)
                if selNum + num >= allNum then
                    goto CONTINUE
                end
            elseif isSelected and sellTipsType == XMVCA.XAreaWar.EnumConst.SELL_TIPS_TYPE.UN_SUBMIT then
                local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
                local allNum = self._Control:GetItemRoom():GetItemNum(itemId)
                if not isSubmit and (selNum + num >= allNum) then
                    goto CONTINUE
                end
            end

            self.ItemSelectedDic[i] = isSelected
            selNum = selNum + num
            selItemNum[itemId] = selNum
            local grid = self.DynamicTable:GetGridByIndex(i)
            if grid then
                self:RefreshItemSelected(grid, isSelected)
            end
            :: CONTINUE ::
        end
    end
    self:RefreshIncome()
end

function XUiAreaWarPopupSellAll:Refresh()
    self:RefreshItemList()
    self:RefreshIncome()
end

-- 初始化代币图标
function XUiAreaWarPopupSellAll:InitTokenIcon()
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    self.RImgIncomeIcon:SetRawImage(icon)
    self.GridBag:GetObject("RImgIcon"):SetRawImage(icon)
    
    self.RImgIconTotalPrice:SetRawImage(icon)
    self.RImgIconHandlingFee:SetRawImage(icon)
    self.RImgIconIncomeNum:SetRawImage(icon)
end

function XUiAreaWarPopupSellAll:InitTabList()
    self.QualityObjDic = {}
    self.BtnTab.gameObject:SetActiveEx(false)
    local qualityIds = self._Control:GetConfig():GetItemQualityIdsWithOrder()
    for _, qualityId in pairs(qualityIds) do
        local go = XUiHelper.Instantiate(self.BtnTab.gameObject, self.PanelTabGroup.transform)
        go.gameObject:SetActiveEx(true)
        local uiObj = go:GetComponent(typeof(CS.UiObject))
        local qualityName = self._Control:GetConfig():GetItemQualityName(qualityId)
        uiObj:GetObject("TxtNormal").text = qualityName
        uiObj:GetObject("TxtPress").text = qualityName
        uiObj:GetObject("ImgSelectNormal").gameObject:SetActiveEx(false)
        uiObj:GetObject("ImgSelectPress").gameObject:SetActiveEx(false)
        self.QualityObjDic[qualityId] = uiObj
        local tempQualityId = qualityId
        self:RegisterClickEvent(uiObj:GetObject("Button"), function()
            self:OnQualityTabClick(tempQualityId)
        end)
    end
end

function XUiAreaWarPopupSellAll:InitDynamicTable()
    self.GridBag.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBagList)
    self.DynamicTable:SetProxy(XUiGridAreaWarItem, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新藏品列表
function XUiAreaWarPopupSellAll:RefreshItemList()
    ---@type XAreaWarItem[]
    self.ItemDataList = self._Control:GetOwnItemDataList()
    self.ItemSelectedDic = {}
    self.DynamicTable:SetDataSource(self.ItemDataList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridAreaWarItem
function XUiAreaWarPopupSellAll:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local item = self.ItemDataList[index]
        grid:RefreshItem(item.ItemId, item.Num)
        local isSelected = self.ItemSelectedDic[index] == true
        self:RefreshItemSelected(grid, isSelected)
        local defaultPrice = self:GetSellPrice(item.ItemId)
        grid.TxtPrice.text = tostring(defaultPrice)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local isSelected = self.ItemSelectedDic[index] ~= true
        local item = self.ItemDataList[index]
        local itemId = item.ItemId
        local num = item.Num
        local qualityId = self._Control:GetConfig():GetItemQuality(itemId)
        local sellTipsType = self._Control:GetConfig():GetItemQualitySellTipsType(qualityId)
        local selNum = self:GetSelectedItemNum(itemId)
        if isSelected and sellTipsType == XMVCA.XAreaWar.EnumConst.SELL_TIPS_TYPE.KEEP_ONE then
            local allNum = self._Control:GetItemRoom():GetItemNum(itemId)
            if selNum + num >= allNum then
                local title = CS.XTextManager.GetText("TipTitle")
                local sellTips = self._Control:GetConfig():GetItemQualitySellTips(qualityId)
                XUiManager.DialogTip(title, sellTips, XUiManager.DialogType.Normal, nil, function()
                    self:OnItemSelected(grid, index, isSelected)
                end)
                return
            end
        elseif isSelected and sellTipsType == XMVCA.XAreaWar.EnumConst.SELL_TIPS_TYPE.UN_SUBMIT then
            local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(itemId)
            local allNum = self._Control:GetItemRoom():GetItemNum(itemId)
            if not isSubmit and (selNum + num >= allNum) then
                local title = CS.XTextManager.GetText("TipTitle")
                local sellTips = self._Control:GetConfig():GetItemQualitySellTips(qualityId)
                XUiManager.DialogTip(title, sellTips, XUiManager.DialogType.Normal, nil, function()
                    self:OnItemSelected(grid, index, isSelected)
                end)
                return
            end
        end
        
        self:OnItemSelected(grid, index, isSelected)
    end
end

function XUiAreaWarPopupSellAll:OnItemSelected(grid, index, isSelected)
    self.ItemSelectedDic[index] = isSelected
    self:RefreshItemSelected(grid, isSelected)
    self:RefreshIncome()
end

-- 获取选中的道具数量
function XUiAreaWarPopupSellAll:GetSelectedItemNum(itemId)
    local selNum = 0
    for i, itemData in ipairs(self.ItemDataList) do
        if self.ItemSelectedDic[i] and itemData.ItemId == itemId then
            selNum = selNum + itemData.Num
        end
    end
    return selNum
end

-- 刷新道具的选中状态
function XUiAreaWarPopupSellAll:RefreshItemSelected(grid, isSelected)
    grid.Normal:GetObject("ImgSelect").gameObject:SetActiveEx(isSelected)
    grid.Press:GetObject("ImgSelect").gameObject:SetActiveEx(isSelected)
end

-- 刷新收入
function XUiAreaWarPopupSellAll:RefreshIncome()
    local totalPrice = 0
    local totalSellCharge = 0
    local totalIncome = 0
    for index, isSelected in pairs(self.ItemSelectedDic) do
        if isSelected then
            local item = self.ItemDataList[index]
            local defaultPrice = self:GetSellPrice(item.ItemId)
            local allPrice = item.Num * defaultPrice -- 总价
            local sellCharge = math.floor(self.SELL_RATE / 10000 * allPrice) -- 出售手续费
            local income = allPrice - sellCharge
            totalPrice = totalPrice + allPrice
            totalSellCharge = totalSellCharge + sellCharge
            totalIncome = totalIncome + income
        end
    end
    
    self.TxtIncome.text = totalIncome
    
    self.TxtTotalPriceNum.text = totalPrice
    self.TxtHandlingFeeNum.text = totalSellCharge
    self.TxtIncomeNum.text = totalIncome
end

-- 获取初始价格
function XUiAreaWarPopupSellAll:GetSellPrice(itemId)
    -- 当前交易行订单平均价格
    local averagePrice = self._Control:GetAuction():GetItemAveragePrice(itemId)
    if averagePrice ~= 0 then
        return averagePrice
    end
    -- 默认配置价格
    return self._Control:GetConfig():GetAuctionSellPriceDefault(itemId)
end

return XUiAreaWarPopupSellAll
