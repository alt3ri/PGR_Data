---@class XUiPanelFashionSuitShop
local XUiPanelFashionSuitShop = XClass(nil, "XUiPanelFashionSuitShop")

function XUiPanelFashionSuitShop:Ctor(root)
    ---@type XUiPanelFashionSuitButtonGroup
    self._Parent = root
end

function XUiPanelFashionSuitShop:InitContext(context, helper)
    ---@type XUiHelperFashionSuit
    self._Helper = helper
    ---@type XFashionContext
    self._Context = context
end

function XUiPanelFashionSuitShop:ActionBuy(params, fashionGroup)
    self._Params = params
    ---@type XTableFashionGroup
    self._FashionGroup = fashionGroup
    self._GoodsDataDict = {}
    self.ActivityOpen = false

    local gainParams = self._Context:GetCurParams()
    self._ShopId = gainParams[1]
    self._GoodsId = gainParams[2]

    self:SetGroupGoodsData()
    self:ShowGoods()
end

function XUiPanelFashionSuitShop:SetGroupGoodsData()
    for _, id in ipairs(self._Params) do
        local params = self._Context:GetParams(id)
        local shopId = params[1]
        if XShopManager.IsShopOpen(shopId) then
            local data = XShopManager.GetShopGoodsInfo(shopId, params[2])
            if data then
                self._GoodsDataDict[data] = shopId
            end
        end
    end
end

function XUiPanelFashionSuitShop:ShowGoods()
    self._GoodsData = nil
    if XShopManager.IsShopOpen(self._ShopId) then
        self._GoodsData = XShopManager.GetShopGoodsInfo(self._ShopId, self._GoodsId)
        self:GetDiscountActivityIsOpen(self._ShopId, self._GoodsData)
    end
    self._Parent:SetHideTime()
    --商店未开启
    if not self._GoodsData then
        self._Parent:SetBuyClose()
        return
    end
    --折扣
    self:ShowGoodsDiscount()
    --价格
    self:ShowGoodsPrice()
    --下架时间
    if self:CheckGoodsRemovalTime() then
        return
    end
    --购买条件
    self:CheckGoodsCondition()
end

function XUiPanelFashionSuitShop:ShowGoodsDiscount()
    local hideSales, discount
    self.Sales = XMVCA.XFashionSuit:GetShopGoodsSale(self._ShopId, self._GoodsData)
    if self._GoodsData.Tags == XShopManager.ShopTags.DisCount then
        if self.Sales < 100 then
            discount = XUiHelper.GetDiscountText(self.Sales)
        else
            hideSales = true
        end
    end
    if self.ActivityOpen then
        discount = XUiHelper.GetDiscountText(math.floor(self._GoodsData.ActivityDiscount / 100))
        self._Parent:SetDiscount(true, discount)
    elseif self._GoodsData.Tags == XShopManager.ShopTags.Not or hideSales then
        self._Parent:SetDiscount(false)
    else
        self._Parent:SetDiscount(true, discount)
    end

    --显示商店折扣倒计时
    local activityEndTime = XShopManager.GetShopActivityEndTime(self._ShopId)
    local activityOpen = XShopManager.GetShopActivityIsOpen(self._ShopId)
    if activityOpen and activityEndTime and activityEndTime > 0 then
        local gameTime = activityEndTime - XTime.GetServerNowTimestamp()
        if gameTime > 0 then
            local leftTimeStr = XUiHelper.GetText("FashionSuitDiscountActivityTip",
                XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY))
            self._Parent:SetDiscountCountDown(leftTimeStr)
        end
    end
end

function XUiPanelFashionSuitShop:ShowGoodsPrice()
    local consumeId = self._GoodsData.ConsumeList[1].Id
    local consumeCount = XMVCA.XFashionSuit:GoodsConsumeCount(self._GoodsDataDict)
    self._Parent:SetConsumeIcon(true, consumeId)
    self._Parent:SetOriginalPrice(self.Sales ~= 100, consumeCount)
    self._CurPrice = XMVCA.XFashionSuit:GetRealGoodsPriceWithDiscount(self._GoodsDataDict)

    -- 需要判断是否足够
    local isEnough = self:_CheckBuyEnough(self._CurPrice, consumeId)

    local priceStr = isEnough and tostring(self._CurPrice) or XUiHelper.GetText("PurchaseFashionSuitDetailCoinNotEnough", self._CurPrice)
    
    self._Parent:SetCurPrice(priceStr)
end

---@return number, number 实际价格，原价, itemId
function XUiPanelFashionSuitShop:GetPrice()
    local consumeId = self._GoodsData.ConsumeList[1].Id
    local consumeCount = XMVCA.XFashionSuit:GoodsConsumeCount(self._GoodsDataDict)
    local realPrice = XMVCA.XFashionSuit:GetRealGoodsPriceWithDiscount(self._GoodsDataDict)
    
    return realPrice, consumeCount, consumeId
end

function XUiPanelFashionSuitShop:CheckGoodsRemovalTime()
    local time = self._GoodsData.SelloutTime
    if time and time > 0 then
        local remainTime = math.max(0, XShopManager.GetLeftTime(time))
        self._Parent:SetRemainTime(remainTime)
        if remainTime <= 0 then
            self._Parent:SetHasBeTakenDown()
        else
            local dataTime = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.SHOP)
            self._Parent:SetWillBeTakenDown(XUiHelper.GetText("TimeSoldOut", dataTime))
            self._Parent:SettOff()
        end
    end
end

function XUiPanelFashionSuitShop:CheckGoodsCondition()
    local conditionIds = self:GoodsConditionIds()
    for id, _ in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id)
        if not ret then
            self._Parent:SetBuyCondition(desc)
            return
        end
    end
end

function XUiPanelFashionSuitShop:GoodsConditionIds()
    local conditionIds = {}
    for data in pairs(self._GoodsDataDict) do
        for _, id in pairs(data.ConditionIds) do
            conditionIds[id] = true
        end
    end
    return conditionIds
end

--- 判断当前是否足够资源购买，参数依赖外部传参
function XUiPanelFashionSuitShop:_CheckBuyEnough(needCount, consumeId)

    if not XTool.IsNumberValidEx(needCount) or not XTool.IsNumberValidEx(consumeId) then
        -- 参数不充分默认足够
        return true
    end

    local haveCount = XDataCenter.ItemManager.GetCount(consumeId)

    return haveCount >= needCount
end

--region V4.2商店打折

function XUiPanelFashionSuitShop:GetDiscountActivityIsOpen(shopId, goodsData)
    if not goodsData then
        return
    end
    self.ActivityOpen, self.NeedCount = XMVCA.XFashionSuit:GetDiscountActivityIsOpen(shopId, goodsData)
    if self.ActivityOpen and goodsData.ActivityConsumeCount == 0 then
        XShopManager.GetShopInfo(shopId, function()
            self:ShowGoods()
        end)
    end
    if not self.ActivityOpen and goodsData.ActivityConsumeCount ~= 0 then
        XShopManager.GetShopInfo(shopId, function()
            self:ShowGoods()
        end)
    end
end

--endregion

--region 购买

function XUiPanelFashionSuitShop:OnShopBuy()
    if not self._GoodsData then
        return
    end

    local consumeId = self._GoodsData.ConsumeList[1].Id
    if not XMVCA.XFashionSuit:CheckShopGoodsBuy(consumeId, self._CurPrice) then
        return
    end

    if self._Helper:IsEnableGroupSales() then
        local shopIds, goodsIds = {}, {}
        for data, shopId in pairs(self._GoodsDataDict) do
            table.insert(shopIds, shopId)
            table.insert(goodsIds, data.Id)
        end
        XShopManager.MultiBuyShop(shopIds, goodsIds, function(goodList)
            self:OnShopBuyViewRefresh(goodList)
        end, nil, self.ActivityOpen)
    else
        XShopManager.BuyShop(self._ShopId, self._GoodsData.Id, 1, function(res)
            self:OnShopBuyViewRefresh(res.GoodList)
        end, nil, self.ActivityOpen)
    end
end

function XUiPanelFashionSuitShop:OnShopBuyViewRefresh(goodList)
    self._Parent:UpdateView()
    self._Parent.Parent:ShowGift()
    self._Parent.Parent.Parent:CallPurchaseCb(goodList)
    XUiManager.TipMsg(XUiHelper.GetText("BuySuccess"), nil, function()
        if not XTool.IsTableEmpty(goodList) then
            XUiManager.OpenUiObtain(goodList, nil, nil, nil, nil, {
                IsIgnoreOpenFashionTipCheck = true
            })
        end
    end)
end

--endregion

return XUiPanelFashionSuitShop
