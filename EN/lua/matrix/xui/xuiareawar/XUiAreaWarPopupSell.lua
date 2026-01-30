---@class XUiAreaWarPopupSell : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarPopupSell = XLuaUiManager.Register(XLuaUi, "UiAreaWarPopupSell")

function XUiAreaWarPopupSell:OnAwake()
    self.PanelTips.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = XUiGridAreaWarItem.New(self.GridItem, self)
end

function XUiAreaWarPopupSell:OnStart(itemId)
    self.ItemId = itemId
    
    self.OwnNum = self._Control:GetItemRoom():GetItemNum(self.ItemId)
    self.MinPrice = self._Control:GetConfig():GetAuctionSellPriceMin(self.ItemId)
    self.MaxPrice = self._Control:GetConfig():GetAuctionSellPriceMax(self.ItemId)
    self.PriceInternal = self._Control:GetConfig():GetAuctionSellPriceInterval(self.ItemId)
    self.AuctionSellRate = XAreaWarConfigs.GetAuctionSellRate() -- 出售手续费万分比，配置1000则为10%
    self.InitPrice = self:GetInitPrice() -- 获取初始价格
    self.SellPrice = self.InitPrice -- 出售价格
    self.SellNum = 1 -- 出售数量
end

function XUiAreaWarPopupSell:OnEnable()
    self:Refresh()
end

function XUiAreaWarPopupSell:OnDisable()
    
end

function XUiAreaWarPopupSell:OnDestroy()
    
end

function XUiAreaWarPopupSell:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSell, self.OnBtnSellClick)
    self:RegisterClickEvent(self.BtnPriceSub, self.OnBtnPriceSubClick)
    self:RegisterClickEvent(self.BtnPriceAdd, self.OnBtnPriceAddClick)
    self:RegisterClickEvent(self.BtnPriceMax, self.OnBtnPriceMaxClick)
    self:RegisterClickEvent(self.BtnNumSub, self.OnBtnNumSubClick)
    self:RegisterClickEvent(self.BtnNumAdd, self.OnBtnNumAddClick)
    self:RegisterClickEvent(self.BtnNumMax, self.OnBtnNumMaxClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.PanelTips, self.OnPanelTipsClick)
    self.SliderPrice.onValueChanged:AddListener(handler(self, self.OnSliderPriceValueChanged))
    self.SliderNum.onValueChanged:AddListener(handler(self, self.OnSliderNumValueChanged))
end

function XUiAreaWarPopupSell:OnBtnCloseClick()
    self:Close()
end

function XUiAreaWarPopupSell:OnBtnSellClick()
    local item = { ItemId = self.ItemId, Price = self.SellPrice, Num = self.SellNum}
    local items = {item}
    XMVCA.XAreaWar:RequestAreaWar4AuctionPutOn(items)
    self:Close()
end

function XUiAreaWarPopupSell:OnBtnPriceSubClick()
    if self.SellPrice > self.MinPrice then
        self.SellPrice = self.SellPrice - self.PriceInternal
    end
    if self.SellPrice < self.MinPrice then
        self.SellPrice = self.MinPrice
    end
    self:RefreshPrice()
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnBtnPriceAddClick()
    if self.SellPrice < self.MaxPrice then
        self.SellPrice = self.SellPrice + self.PriceInternal
    end
    if self.SellPrice > self.MaxPrice then
        self.SellPrice = self.MaxPrice
    end
    self:RefreshPrice()
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnBtnPriceMaxClick()
    self.SellPrice = self.MaxPrice
    self:RefreshPrice()
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnBtnNumSubClick()
    if self.SellNum > 1 then
        self.SellNum = self.SellNum - 1
    end
    self:RefreshNum()
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnBtnNumAddClick()
    if self.SellNum < self.OwnNum then
        self.SellNum = self.SellNum + 1
    end
    self:RefreshNum()
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnBtnNumMaxClick()
    self.SellNum = self.OwnNum
    self:RefreshNum()
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnBtnHelpClick()
    self.PanelTips.gameObject:SetActiveEx(true)
    local allPrice = self.SellNum * self.SellPrice -- 总价
    local sellCharge = math.floor(self.AuctionSellRate / 10000 * allPrice) -- 出售手续费
    local income = allPrice - sellCharge -- 净收入
    self.TxtTotalPriceNum.text = tostring(allPrice)
    self.TxtHandlingFeeNum.text = tostring(sellCharge)
    self.TxtIncomeNum.text = tostring(income)
end

function XUiAreaWarPopupSell:OnPanelTipsClick()
    self.PanelTips.gameObject:SetActiveEx(false)
end

function XUiAreaWarPopupSell:OnSliderPriceValueChanged(v)
    local price = (self.MaxPrice - self.MinPrice) * v + self.MinPrice
    self.SellPrice = math.floor(price + 0.5) -- 四舍五入
    if self.SellPrice < 1 then
        self.SellPrice = 1
    end
    self:RefreshPrice(true)
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:OnSliderNumValueChanged(v)
    local num = self.OwnNum * v
    self.SellNum = math.floor(num + 0.5) -- 四舍五入
    if self.SellNum < 1 then
        self.SellNum = 1
    end
    self:RefreshNum(true)
    self:RefreshIncome()
end

function XUiAreaWarPopupSell:Refresh()
    self.GridAreaWarItem:RefreshItem(self.ItemId, nil, true)
    self.TxtDescription.text = self._Control:GetConfig():GetItemDesc(self.ItemId)
    
    -- 刷新代币图标
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    self.RImgPriceIcon:SetRawImage(icon)
    self.RImgIncomeIcon:SetRawImage(icon)
    self.RImgIconTotalPrice:SetRawImage(icon)
    self.RImgIconHandlingFee:SetRawImage(icon)
    self.RImgIconIncome:SetRawImage(icon)

    self:RefreshPrice()
    self:RefreshNum()
    self:RefreshIncome()
end

-- 刷新价格
function XUiAreaWarPopupSell:RefreshPrice(isIgnoreSlider)
    self.TxtPrice.text = tostring(self.SellPrice)
    if not isIgnoreSlider then
        self.SliderPrice.value = (self.SellPrice - self.MinPrice) / (self.MaxPrice - self.MinPrice)
    end
end

-- 刷新数量
function XUiAreaWarPopupSell:RefreshNum(isIgnoreSlider)
    self.TxtNum.text = tostring(self.SellNum) .. "/" .. tostring(self.OwnNum)
    if not isIgnoreSlider then
        self.SliderNum.value = self.SellNum / self.OwnNum
    end
end

-- 刷新收入
function XUiAreaWarPopupSell:RefreshIncome()
    local allPrice = self.SellNum * self.SellPrice -- 总价
    local sellCharge = math.floor(self.AuctionSellRate / 10000 * allPrice) -- 出售手续费
    local income = allPrice - sellCharge
    self.TxtIncome.text = tostring(income)
end

-- 获取初始价格
function XUiAreaWarPopupSell:GetInitPrice()
    -- 当前交易行订单平均价格
    local averagePrice = self._Control:GetAuction():GetItemAveragePrice(self.ItemId)
    if averagePrice ~= 0 then
        if averagePrice > self.MaxPrice then
            averagePrice = self.MaxPrice 
        end
        if averagePrice < self.MinPrice then
            averagePrice = self.MinPrice
        end
        return averagePrice
    end
    -- 默认配置价格
    return self._Control:GetConfig():GetAuctionSellPriceDefault(self.ItemId)
end

return XUiAreaWarPopupSell
