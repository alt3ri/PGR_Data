local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiGridBWShop : XUiNode
local XUiGridBWShop = XClass(XUiNode, "XUiGridBWShop")

function XUiGridBWShop:OnStart()
    self._ShopId = 0
    self._Data = false

    ---@type XUiGridBWItem
    self._GridItem = XUiGridBWItem.New(self.GridCommon, self)

    self._PanelPriceList = {
        self.PanelPrice1,
        self.PanelPrice2,
        self.PanelPrice3,
    }

    self._Sales = 100
    self._OnSales = false

    self._ItemTextColor = false

    self._ConditionText = ""

    self._CheckGoodsBuyPriorityHandler = false
    self._BuyGoodsHandler = false

    self._Timer = false
    self._OnSaleTimer = false

    self:_RegisterButtonClicks()
end

function XUiGridBWShop:OnDisable()
    self:_RemoveTimer()
    self:_RemoveOnSaleTimer()
end

function XUiGridBWShop:OnBtnBuyClick()
    local isCanBuy = self:_CheckCanBuy()
    local isCountEnough = self:_CheckItemCount()

    if isCanBuy and isCountEnough then
        self:_InvokeBuyGoods(function(count)
            self:RefreshHave()
            self:RefreshSellOut()
            self:RefreshCondition()
            self:RefreshOnSales()
            self:RefreshPrice()
            self:RefreshBuyCount()
        end)
    else
        if not isCanBuy then
            XMVCA.XBigWorldService:TipText("ShopBuyNotSales")
        end
        if not isCountEnough then
            XMVCA.XBigWorldService:TipText("ShopBuyNotEnough")
        end
    end
end

function XUiGridBWShop:SetCheckGoodsBuyPriorityProxy(handler)
    self._CheckGoodsBuyPriorityHandler = handler
end

function XUiGridBWShop:SetBuyGoodsProxy(handler)
    self._BuyGoodsHandler = handler
end

function XUiGridBWShop:SetItemTextColor(canBuyColor, notCanBuyColor)
    self._ItemTextColor = {
        CanBuy = canBuyColor,
        NotCanBuy = notCanBuyColor,
    }
end

function XUiGridBWShop:Refresh(data, shopId)
    self._ShopId = shopId
    self._Data = data

    self:RefreshHave()
    self:RefreshSellOut()
    self:RefreshCondition()
    self:RefreshCommon()
    self:RefreshOnSales()
    self:RefreshPrice()
    self:RefreshBuyCount()
    self:RefreshAlreadyTip()
    -- 全部隐藏，如果 < 开售时间显示开售时间，如果 >= 开售时间，显示结束时间
    self:SetAllTimeActive(false)

    self:_RemoveTimer()
    self:_RemoveOnSaleTimer()

    -- 未到开售时间
    if XTime.GetServerNowTimestamp() < self._Data.OnSaleTime then
        -- 刷新销售开启时间
        self:RefreshOnSaleTimer(self._Data.OnSaleTime)
    else
        -- 刷新销售结束时间
        self:RefreshTimer(self._Data.SelloutTime)
    end
end

function XUiGridBWShop:RefreshHave()
    if not self.ImgHave then
        return
    end

    local conditionIds = self._Data.ConditionIds
    local isHave = false

    if not conditionIds or #conditionIds <= 0 then
        isHave = false
    end

    for _, id in pairs(conditionIds) do
        local isSuccess, desc = XMVCA.XBigWorldService:CheckCondition(id)

        if isSuccess and self._Data.TotalBuyTimes < self._Data.BuyTimesLimit then
            isHave = true

            break
        end
    end

    self.ImgHave.gameObject:SetActiveEx(isHave)
end

function XUiGridBWShop:RefreshSellOut()
    if not self.ImgSellOut then
        return
    end

    if self._Data.BuyTimesLimit <= 0 then
        self.ImgSellOut.gameObject:SetActiveEx(false)
    else
        if self._Data.TotalBuyTimes >= self._Data.BuyTimesLimit then
            self.ImgSellOut.gameObject:SetActiveEx(true)
        else
            self.ImgSellOut.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridBWShop:RefreshCondition()
    if not self.BtnCondition then
        return
    end

    self._ConditionText = ""
    self.BtnCondition.gameObject:SetActiveEx(false)

    -- v4.0 判断购买优先级（商店里所有优先级低的商品买完后才能买优先级高的）
    if XTool.IsNumberValid(self._Data.BuyPriority) then
        if self._CheckGoodsBuyPriorityHandler then
            local isUnlock = self._CheckGoodsBuyPriorityHandler(self._Data)

            if not isUnlock then
                self._ConditionText = XUiHelper.ReplaceTextNewLine(
                    XMVCA.XBigWorldService:GetShopGoodsBuyPriorityDescript(self._Data.Id))
                self.BtnCondition.gameObject:SetActiveEx(true)
                self.ImgSellOut.gameObject:SetActiveEx(false)
                return
            end
        end
    end

    local conditionIds = self._Data.ConditionIds

    if not conditionIds or #conditionIds <= 0 then
        return
    end

    for _, id in pairs(conditionIds) do
        local isSuccess, desc = XMVCA.XBigWorldService:CheckCondition(id)

        if not isSuccess then
            self._ConditionText = desc
            self.BtnCondition.gameObject:SetActiveEx(true)
            self.ImgSellOut.gameObject:SetActiveEx(false)
            return
        end
    end
end

function XUiGridBWShop:RefreshOnSales()
    local isOnSales = false

    self._OnSales = {}
    XTool.LoopMap(self._Data.OnSales, function(key, sales)
        self._OnSales[key] = sales
        isOnSales = true
    end)

    self._Sales = 100

    if isOnSales then
        local sortedKeys = {}

        for key, _ in pairs(self._OnSales) do
            table.insert(sortedKeys, key)
        end

        table.sort(sortedKeys)

        for i = 1, #sortedKeys do
            if self._Data.TotalBuyTimes >= sortedKeys[i] - 1 then
                self._Sales = self._OnSales[sortedKeys[i]]
            end
        end
    end

    self:RefreshPanelSale()
end

function XUiGridBWShop:RefreshPanelSale()
    if self.TxtSaleRate then
        if self._Data.Tags == XShopManager.ShopTags.DisCount then
            if self._Sales < 100 then
                -- 折扣显示 区分海外国服
                self.TxtSaleRate.text = XUiHelper.GetDiscountText(self._Sales)
            else
                self.TxtSaleRate.gameObject:SetActiveEx(false)
                self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(false)
            end
        elseif self._Data.Tags == XShopManager.ShopTags.TimeLimit then
            self.TxtSaleRate.text = XUiHelper.GetText("TimeLimit")
        elseif self._Data.Tags == XShopManager.ShopTags.Recommend then
            self.TxtSaleRate.text = XUiHelper.GetText("Recommend")
        elseif self._Data.Tags == XShopManager.ShopTags.HotSale then
            self.TxtSaleRate.text = XUiHelper.GetText("HotSell")
        elseif self._Data.Tags == XShopManager.ShopTags.Not then
            self.TxtSaleRate.gameObject:SetActiveEx(false)
            self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(false)
        else
            self.TxtSaleRate.gameObject:SetActiveEx(true)
            self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridBWShop:RefreshCommon()
    self._GridItem:Refresh(self._Data.RewardGoods)
    self._GridItem:RefreshCount()
end

function XUiGridBWShop:RefreshPrice()
    local panelCount = #self._PanelPriceList
    local index = 1

    for _, consume in pairs(self._Data.ConsumeList) do
        if index > panelCount then
            return
        end

        if self["TxtOldPrice" .. index] then
            if self._Sales == 100 then
                self["TxtOldPrice" .. index].gameObject:SetActiveEx(false)
            else
                self["TxtOldPrice" .. index].text = consume.Count
                self["TxtOldPrice" .. index].gameObject:SetActiveEx(true)
            end
        end

        if self["RImgPrice" .. index] and self["RImgPrice" .. index]:Exist() then
            local icon = XMVCA.XBigWorldService:GetItemIcon(consume.Id)

            if icon ~= nil then
                self["RImgPrice" .. index]:SetRawImage(icon)
            end
        end

        if self["TxtNewPrice" .. index] then
            local count = math.floor(consume.Count * self._Sales / 100)
            local itemCount = XMVCA.XBigWorldService:GetItemCount(consume.Id)

            self["TxtNewPrice" .. index].text = tostring(count)

            if itemCount < count then
                if not self._ItemTextColor or not self._ItemTextColor.NotCanBuy then
                    self["TxtNewPrice" .. index].color = CS.UnityEngine.Color(1, 0, 0)
                else
                    self["TxtNewPrice" .. index].color = XUiHelper.Hexcolor2Color(self._ItemTextColor.NotCanBuy)
                end
            else
                if not self._ItemTextColor or not self._ItemTextColor.CanBuy then
                    self["TxtNewPrice" .. index].color = CS.UnityEngine.Color(0, 0, 0)
                else
                    self["TxtNewPrice" .. index].color = XUiHelper.Hexcolor2Color(self._ItemTextColor.CanBuy)
                end
            end
        end

        self._PanelPriceList[index].gameObject:SetActiveEx(true)
        index = index + 1
    end

    for i = index, panelCount do
        self._PanelPriceList[i].gameObject:SetActiveEx(false)
    end
end

function XUiGridBWShop:RefreshShowLock()
    local isLock = string.IsNilOrEmpty(self._ConditionText)

    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end

    if self.TxtLock then
        if isLock then
            self.TxtLock.text = XUiHelper.ReplaceTextNewLine(self._ConditionText)
            self.TxtLock.gameObject:SetActiveEx(true)
        else
            self.TxtLock.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridBWShop:RefreshBuyCount()
    if not self.ImgLimitLable then
        return
    end

    if not self.TxtLimitLable then
        return
    end

    if self._Data.BuyTimesLimit <= 0 then
        if not self:_CheckDiscountCanBuyAmount() then
            self.TxtLimitLable.gameObject:SetActiveEx(false)
            self.ImgLimitLable.gameObject:SetActiveEx(false)
        else
            self.TxtLimitLable.gameObject:SetActiveEx(true)
            self.ImgLimitLable.gameObject:SetActiveEx(true)
        end
    else
        local buynumber = self._Data.BuyTimesLimit - self._Data.TotalBuyTimes
        local limitLabel = XMVCA.XBigWorldService:GetShopBuyLimitLabel(self._Data.AutoResetClockId)
        local text = string.format(limitLabel, buynumber)

        self.TxtLimitLable.text = text
        self.TxtLimitLable.gameObject:SetActiveEx(true)
        self.ImgLimitLable.gameObject:SetActiveEx(true)
    end
end

function XUiGridBWShop:RefreshAlreadyTip()
    if self._ShopId ~= XShopManager.RechargeShopType.CharacterShop and self._ShopId ~=
        XShopManager.RechargeShopType.EquipShop and self._ShopId ~= XShopManager.RechargeShopType.PartnerShop then
        if self.PanelAlreadyownedRole then
            self.PanelAlreadyownedRole.gameObject:SetActiveEx(false)
        end

        return
    end
    if not self.PanelAlreadyownedRole or not self.TxtAlready then
        return
    end

    if not self._Data then
        self.PanelAlreadyownedRole.gameObject:SetActiveEx(false)
        return
    end

    local rewardGoods = self._Data.RewardGoods
    local rewardType = rewardGoods.RewardType
    local templateId = rewardGoods.TemplateId

    if XMVCA.XBigWorldService:CheckRewardCharacter(rewardType, templateId) then
        self.PanelAlreadyownedRole.gameObject:SetActiveEx(true)
        self.TxtAlready.text = XUiHelper.GetText("ShopAlreadyHasCharacterTip")
    elseif XMVCA.XBigWorldService:CheckRewardEquip(rewardType, templateId) then
        self.PanelAlreadyownedRole.gameObject:SetActiveEx(true)
        self.TxtAlready.text = XUiHelper.GetText("ShopAlreadyHasEquipTip")
    elseif rewardType == XRewardManager.XRewardType.Partner then
        if XMVCA.XBigWorldService:GetPartnerCountByTemplateId(templateId) > 0 then
            self.PanelAlreadyownedRole.gameObject:SetActiveEx(true)
            self.TxtAlready.text = XUiHelper.GetText("ShopAlreadyHasPartnerTip")
        else
            self.PanelAlreadyownedRole.gameObject:SetActiveEx(false)
        end
    else
        self.PanelAlreadyownedRole.gameObject:SetActiveEx(false)
    end
end

function XUiGridBWShop:RefreshTimer(time)
    if XTool.UObjIsNil(self.ImgLeftTime) then
        return
    end

    if XTool.UObjIsNil(self.TxtLeftTime) then
        self.ImgLeftTime.gameObject:SetActiveEx(false)
        return
    end

    if time <= 0 then
        self.TxtLeftTime.gameObject:SetActiveEx(false)
        self.ImgLeftTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtLeftTime.gameObject:SetActiveEx(true)
    self.ImgLeftTime.gameObject:SetActiveEx(true)

    local leftTime = XMVCA.XBigWorldService:GetShopLeftTime(time)

    self:_RemoveTimer()

    self._Timer = XScheduleManager.ScheduleForeverEx(function()
        leftTime = leftTime > 0 and leftTime or 0

        local dataTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.SHOP)

        if self.TxtLeftTime then
            self.TxtLeftTime.text = CS.XTextManager.GetText("TimeSoldOut", dataTime)
        end

        if leftTime <= 0 then
            self:_RemoveTimer()

            if self.ImgSellOut then
                self.ImgSellOut.gameObject:SetActiveEx(true)
            end
        end

        leftTime = leftTime - 1
    end, XScheduleManager.SECOND)
end

function XUiGridBWShop:RefreshOnSaleTimer(time)
    if not self.TxtOnSaleTime then
        return
    end

    if time <= 0 then
        self.TxtOnSaleTime.gameObject:SetActiveEx(false)
        if not XTool.UObjIsNil(self.ImgLeftTime) then
            self.ImgLeftTime.gameObject:SetActiveEx(false)
        end
        return
    end

    if not XTool.UObjIsNil(self.ImgLeftTime) then
        self.ImgLeftTime.gameObject:SetActiveEx(true)
    end

    self.TxtOnSaleTime.gameObject:SetActiveEx(true)

    local saleTime = XMVCA.XBigWorldService:GetShopLeftTime(time)

    self:_RemoveOnSaleTimer()
    self.OnSaleTimer = XScheduleManager.ScheduleForeverEx(function()
        saleTime = saleTime > 0 and saleTime or 0

        local dataTime = XUiHelper.GetTime(saleTime, XUiHelper.TimeFormatType.ACTIVITY)

        if self.TxtOnSaleTime then
            self.TxtOnSaleTime.text = XUiHelper.GetText("TimeOnSale", dataTime)
        end

        if saleTime <= 0 then
            self:_RemoveOnSaleTimer()

            if self.TxtOnSaleTime then
                self.TxtOnSaleTime.gameObject:SetActiveEx(false)
            end
            if not XTool.UObjIsNil(self.ImgLeftTime) then
                self.ImgLeftTime.gameObject:SetActiveEx(false)
            end
        end

        saleTime = saleTime - 1
    end, XScheduleManager.SECOND)
end

function XUiGridBWShop:SetAllTimeActive(isActive)
    if self.TxtLeftTime then
        self.TxtLeftTime.gameObject:SetActiveEx(isActive)
    end
    if self.TxtOnSaleTime then
        self.TxtOnSaleTime.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridBWShop:_CheckCanBuy()
    local currentTime = XTime.GetServerNowTimestamp()
    if currentTime >= self._Data.OnSaleTime then
        if self._Data.SelloutTime <= 0 then
            return true
        end
        return currentTime <= self._Data.SelloutTime
    end
    return false
end

function XUiGridBWShop:_CheckItemCount()
    for _, consume in pairs(self._Data.ConsumeList) do
        local count = math.floor(consume.Count * self._Sales / 100)
        local itemCount = XMVCA.XBigWorldService:GetItemCount(consume.Id)

        if itemCount >= count then
            return true
        end
    end
end

-- 这一段复制自  XUiShopItem:GetMaxCount()
function XUiGridBWShop:_CheckDiscountCanBuyAmount()
    if not self._ShopId then
        return false
    end

    local sortedKeys = {}

    for k, _ in pairs(self._OnSales) do
        table.insert(sortedKeys, k)
    end

    table.sort(sortedKeys)

    local leftSalesGoods = XMVCA.XBigWorldService.ShopBuyGoodsCountLimit

    for i = 1, #sortedKeys do
        if self._Data.TotalBuyTimes >= sortedKeys[i] - 1 then
        else
            leftSalesGoods = sortedKeys[i] - self._Data.TotalBuyTimes - 1
            break
        end
    end

    local leftShopTimes = XMVCA.XBigWorldService:GetShopLeftBuyTimes(self._ShopId)

    if not leftShopTimes then
        leftShopTimes = XMVCA.XBigWorldService.ShopBuyGoodsCountLimit
    end

    local leftGoodsTimes = XMVCA.XBigWorldService.ShopBuyGoodsCountLimit

    if self._Data.BuyTimesLimit and self._Data.BuyTimesLimit > 0 then
        local buyCount = self._Data.TotalBuyTimes and self._Data.TotalBuyTimes or 0

        leftGoodsTimes = self._Data.BuyTimesLimit - buyCount
    end

    local maxCount = math.min(leftGoodsTimes, math.min(leftShopTimes, leftSalesGoods))

    if maxCount < XMVCA.XBigWorldService.ShopBuyGoodsCountLimit then
        local clockId = 0
        local limitLabel = XMVCA.XBigWorldService:GetShopBuyLimitLabel(clockId)
        local text = string.format(limitLabel, maxCount)

        self.TxtLimitLable.text = text

        return true
    end

    return false
end

function XUiGridBWShop:_RegisterButtonClicks()
    self.BtnBuy:AddEventListener(Handler(self, self.OnBtnBuyClick))
end

function XUiGridBWShop:_RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiGridBWShop:_RemoveOnSaleTimer()
    if self._OnSaleTimer then
        XScheduleManager.UnSchedule(self._OnSaleTimer)
        self._OnSaleTimer = false
    end
end

function XUiGridBWShop:_InvokeBuyGoods(callback)
    if self._BuyGoodsHandler then
        self._BuyGoodsHandler(self._Data, callback)
        return
    end

    XMVCA.XBigWorldUI:Open("UiBigWorldPurchaseItem", self._ShopId, self._Data, callback)
end

return XUiGridBWShop
