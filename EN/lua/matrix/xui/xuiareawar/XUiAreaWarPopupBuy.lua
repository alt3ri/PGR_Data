---@class XUiAreaWarPopupBuy : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarPopupBuy = XLuaUiManager.Register(XLuaUi, "UiAreaWarPopupBuy")

function XUiAreaWarPopupBuy:OnAwake()
    self.PanelTips.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = XUiGridAreaWarItem.New(self.GridItem, self)
end

function XUiAreaWarPopupBuy:OnStart(itemId)
    self.ItemId = itemId -- 道具Id
    self.AuctionNum = self._Control:GetAuction():GetItemAllNum(itemId) -- 交易行已上架该商品的数量
    self.MaxNum = self._Control:GetAuction():GetMaxBuyNum(itemId) -- 已拥有货币可购买数量
    if self.MaxNum == 0 and self.AuctionNum > 0 then
        self.MaxNum = 1
    end
    self.BuyNum = self.MaxNum > 0 and 1 or 0 -- 购买数量
    self.TotalPrice = 0 -- 总价格
end

function XUiAreaWarPopupBuy:OnEnable()
    self:Refresh()
end

function XUiAreaWarPopupBuy:OnDisable()
    
end

function XUiAreaWarPopupBuy:OnDestroy()
    
end

function XUiAreaWarPopupBuy:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuyClick)
    self:RegisterClickEvent(self.BtnSub, self.OnBtnSubClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self.SliderNum.onValueChanged:AddListener(handler(self, self.OnSliderNumValueChanged))
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.PanelTips, self.OnPanelTipsClick)
end

function XUiAreaWarPopupBuy:OnBtnCloseClick()
    self:Close()
end

function XUiAreaWarPopupBuy:OnBtnBuyClick()
    -- 数量不足
    if self.MaxNum < 1 then
        local tips = XAreaWarConfigs.GetAuctionBuyNoEnoughShopTips()
        XUiManager.TipError(tips)
        return
    end
    
    -- 代币不足
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    if ownCnt < self.TotalPrice then
        local tips = XAreaWarConfigs.GetAuctionBuyNoEnoughCoinTips()
        XUiManager.TipError(tips)
        return
    end
    
    XMVCA.XAreaWar:RequestAreaWar4AuctionBuy(self.ItemId, self.BuyNum, function()
        local tips = XAreaWarConfigs.GetAuctionBuySuccessTips()
        XUiManager.TipError(tips)
        self:Close()
    end, function()
        self.MaxNum = self._Control:GetAuction():GetItemAllNum(self.ItemId) -- 交易行已上架该商品的数量
        if self.BuyNum > self.MaxNum then
            self.BuyNum = self.MaxNum
        end
        self:Refresh()
        
        local tips = XAreaWarConfigs.GetAuctionRefreshReBuyTips()
        XUiManager.TipError(tips)
    end)
end

function XUiAreaWarPopupBuy:OnBtnSubClick()
    if self.BuyNum > 1 then
        self.BuyNum = self.BuyNum - 1
    end
    self:RefreshNum()
    self:RefreshIncome()
end

function XUiAreaWarPopupBuy:OnBtnAddClick()
    if self.BuyNum < self.MaxNum then
        self.BuyNum = self.BuyNum + 1
    end
    self:RefreshNum()
    self:RefreshIncome()
end

function XUiAreaWarPopupBuy:OnBtnMaxClick()
    self.BuyNum = self._Control:GetAuction():GetMaxBuyNum(self.ItemId)
    if self.BuyNum < 1 and self.MaxNum > 0 then
        self.BuyNum = 1
    end
    
    self:RefreshNum()
    self:RefreshIncome()
end

function XUiAreaWarPopupBuy:OnSliderNumValueChanged(v)
    if self.MaxNum <= 0 then
        return
    end
    
    local num = self.MaxNum * v
    self.BuyNum = math.floor(num + 0.5) -- 四舍五入
    if self.BuyNum < 1 and self.MaxNum > 0 then
        self.BuyNum = 1
    end
    self:RefreshNum(true)
    self:RefreshIncome()
end

function XUiAreaWarPopupBuy:OnBtnHelpClick()
    self.PanelTips.gameObject:SetActiveEx(true)
end

function XUiAreaWarPopupBuy:OnPanelTipsClick()
    self.PanelTips.gameObject:SetActiveEx(false)
end

function XUiAreaWarPopupBuy:Refresh()
    self.GridAreaWarItem:RefreshItem(self.ItemId)
    self.TxtDescription.text = self._Control:GetConfig():GetItemDesc(self.ItemId)
    
    -- 刷新代币图标
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    self.RImgIconAvg:SetRawImage(icon)
    self.RImgIconTotal:SetRawImage(icon)
    
    -- 剩余数量提示
    local tips = XAreaWarConfigs.GetAuctionItemRemainTips()
    self.TxtLeftTips.text = string.format(tips, self.MaxNum)
    
    -- 刷新数量和价格
    self:RefreshNum()
    self:RefreshIncome()
end

-- 刷新数量
function XUiAreaWarPopupBuy:RefreshNum(isIgnoreSlider)
    self.TxtNum.text = tostring(self.BuyNum) .. "/" .. tostring(self.MaxNum)
    if not isIgnoreSlider then
        self.SliderNum.value = self.BuyNum / self.MaxNum
    end
end

-- 刷新收入
function XUiAreaWarPopupBuy:RefreshIncome()
    self.TotalPrice = self._Control:GetAuction():GetItemBuyPrice(self.ItemId, self.BuyNum)

    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    if ownCnt < self.TotalPrice then
        local colorFormat = XAreaWarConfigs.GetAuctionBuyNoEnoughCoinColor()
        self.TxtTotalPrice.text = string.format(colorFormat, self.TotalPrice)
    else
        self.TxtTotalPrice.text = self.TotalPrice
    end
    self.TxtAvgPrice.text = self._Control:GetAuction():GetItemAveragePrice(self.ItemId)

    -- 仅剩**件提示
    self.TxtLeftTips.gameObject:SetActiveEx(false)
    if self.BuyNum == self.AuctionNum then
        local maxPrice = self._Control:GetAuction():GetItemMaxPrice(self.ItemId)
        if (ownCnt - self.TotalPrice) >= maxPrice then
            self.TxtLeftTips.gameObject:SetActiveEx(true)
        end
    end
end

return XUiAreaWarPopupBuy
