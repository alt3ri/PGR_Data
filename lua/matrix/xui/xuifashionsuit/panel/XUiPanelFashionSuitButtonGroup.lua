---@class XUiPanelFashionSuitButtonGroup : XUiNode 套装涂装三级界面购买、跳转和穿戴按钮
---@field Parent XUiFashionSuitDetail
---@field _Control XFashionSuitControl
local XUiPanelFashionSuitButtonGroup = XClass(XUiNode, "XUiPanelFashionSuitButtonGroup")

local FashionStatus = XDataCenter.FashionManager.FashionStatus
local GainType = XEnumConst.FashionSuit.GainType
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}

function XUiPanelFashionSuitButtonGroup:OnStart()
    self._RemainTime = 0
    self._IsDisCount = false
    self._TxtOriginalPrices = { self.TxtOriginalPrice1, self.TxtOriginalPrice2 }

    self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
    self.BtnGet.CallBack = handler(self, self.OnBtnGetClick)
    self.BtnWear.CallBack = handler(self, self.OnBtnWearClick)
end

function XUiPanelFashionSuitButtonGroup:OnBtnGetClick()
    XFunctionManager.SkipInterface(self._GainParams[1])
end

function XUiPanelFashionSuitButtonGroup:OnBtnWearClick()
    if self.BtnWear.ButtonState == CS.UiButtonState.Disable then
        return
    end
    XDataCenter.FashionManager.UseFashion(self._Id, function()
        XUiManager.TipText("UseSuccess")
        self:UpdateView()
    end)
end

function XUiPanelFashionSuitButtonGroup:OnBtnBuyClick()
    if self.BtnBuy.ButtonState == CS.UiButtonState.Disable then
        return
    end
    if self._GainType == GainType.Purchase then
        if not self._ItemData then
            return
        end
        XDataCenter.PurchaseManager.RemoveNotInTimeDiscountCoupon(self._ItemData) -- 移除未到时间的打折券
    elseif self._GainType == GainType.Shop then
        if not self._GoodsData then
            return
        end
    end
    self:OnBuyBefore()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1011)
end

function XUiPanelFashionSuitButtonGroup:UpdateBuyBtn(id)
    if self._Id then
        self.Parent:RemoveTimerFun(self._Id)
    end
    self._Id = id
    self._FashionConfig = XFashionConfigs.GetFashionTemplate(id)
    local isShowBuy, isShowGet, isShowWear
    local state = XDataCenter.FashionManager.GetFashionStatus(self._Id)

    if state == FashionStatus.UnOwned then
        self._GainType = self._FashionConfig.FashionGainType
        self._GainParams = self._FashionConfig.FashionGainParams
        if self._GainType == GainType.Purchase then
            isShowBuy = true
            local data = XDataCenter.PurchaseManager.GetPurchaseDataById(self._GainParams[1])
            self:ShowPurchase(data)
        elseif self._GainType == GainType.Shop then
            isShowBuy = true
            local data
            if XShopManager.IsShopOpen(self._GainParams[1]) then
                data = XShopManager.GetShopGoodsInfo(self._GainParams[1], self._GainParams[2])
            end
            self:ShowGoods(data)
        elseif self._GainType == GainType.Skip then
            isShowGet = true
        else
            self:SetBuyClose()
        end
    elseif state == FashionStatus.UnLock then
        isShowWear = true
        self.BtnWear:SetButtonState(XUiButtonState.Normal)
        self.Parent:RemoveTimerFun(self._Id)
    elseif state == FashionStatus.Dressed then
        isShowWear = true
        self.BtnWear:SetButtonState(XUiButtonState.Disable)
        self.Parent:RemoveTimerFun(self._Id)
    end

    self.BtnBuy.gameObject:SetActiveEx(isShowBuy)
    self.BtnGet.gameObject:SetActiveEx(isShowGet)
    self.BtnWear.gameObject:SetActiveEx(isShowWear)
end

function XUiPanelFashionSuitButtonGroup:UpdateView()
    self:UpdateBuyBtn(self._Id)
end

---设置货币Icon
function XUiPanelFashionSuitButtonGroup:SetConsumeIcon(isVisible, itemId)
    if isVisible then
        self.RawImageConsume.gameObject:SetActiveEx(true)
        local path = XDataCenter.ItemManager.GetItemIcon(itemId)
        if path then
            self.RawImageConsume:SetRawImage(path)
        end
    else
        self.RawImageConsume.gameObject:SetActiveEx(false)
    end
end

---设置旧价格
function XUiPanelFashionSuitButtonGroup:SetOriginalPrice(isVisible, price)
    for _, txt in pairs(self._TxtOriginalPrices) do
        if isVisible then
            txt.gameObject:SetActiveEx(true)
            if price then
                txt.text = price
            end
        else
            txt.gameObject:SetActiveEx(false)
        end
    end
end

---设置当前价格
function XUiPanelFashionSuitButtonGroup:SetCurPrice(price)
    self.BtnBuy:SetNameByGroup(0, price)
    self.BtnBuy:SetButtonState(XUiButtonState.Normal)
end

---设置折扣
function XUiPanelFashionSuitButtonGroup:SetDiscount(isVisible, discount, tagSprice)
    if isVisible then
        self.ImgTagDiscount.gameObject:SetActive(true)
        if not string.IsNilOrEmpty(tagSprice) then
            self.ImgTagDiscount:SetSprite(tagSprice)
        end
        if discount then
            self.TxtDiscount.text = discount
        end
    else
        self.ImgTagDiscount.gameObject:SetActive(false)
    end
end

---设置为免费获取
function XUiPanelFashionSuitButtonGroup:SetPriceFree()
    self.BtnBuy:SetButtonState(XUiButtonState.Normal)
    self:SetOriginalPrice(false)
    self:SetCurPrice(XUiHelper.GetText("PurchaseFreeText"))
end

---设置上架时间
function XUiPanelFashionSuitButtonGroup:SetWaitListed(timeStr)
    self:SetBuyClose()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = timeStr
end

---设置商品下架时间
function XUiPanelFashionSuitButtonGroup:SetWillBeTakenDown(timeStr)
    self.BtnBuy:SetButtonState(XUiButtonState.Normal)
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = timeStr
end

---设置商品已下架
function XUiPanelFashionSuitButtonGroup:SetHasBeTakenDown()
    self:SetBuyClose()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = XUiHelper.GetText("PurchaseLBSettOff")
end

---设置时间隐藏
function XUiPanelFashionSuitButtonGroup:SetHideTime()
    self.TxtTime.gameObject:SetActiveEx(false)
end

---设置购买条件
function XUiPanelFashionSuitButtonGroup:SetBuyCondition(condTxt)
    self:SetBuyClose()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = condTxt
end

---设置商店/礼包未开启
function XUiPanelFashionSuitButtonGroup:SetBuyClose()
    self.BtnBuy:SetButtonState(XUiButtonState.Disable)
    self:SetHideTime()
    self:SetConsumeIcon(false)
    self:SetDiscount(false)
end

--region 购买前置判断

--- 执行正常购买流程前的处理，用于特殊逻辑
function XUiPanelFashionSuitButtonGroup:OnBuyBefore()
    --3.1莉莉丝可肝卡池特殊涂装
    local lilithFashionId = XGachaConfigs.GetClientConfigNumber('SpeicalFashionFromPurchaseToGachaShop', 1)

    if XTool.IsNumberValid(lilithFashionId) and lilithFashionId == self._Id then
        local skipCondition = XGachaConfigs.GetClientConfigNumber('SpecialConditionFromPurchaseToGachaShop', 1)
        -- 判断条件满足，因为具有特殊性，未配置视为不可跳转
        if XTool.IsNumberValid(skipCondition) and XConditionManager.CheckCondition(skipCondition) then
            local skipId = XGachaConfigs.GetClientConfigNumber('SpecialSkipToGachaShop', 1)
            if XTool.IsNumberValid(skipId) then
                XLuaUiManager.Open('UiGachaCanLiverDialog', handler(self, self.OnBuy), skipId)
                return
            end
        end
    end

    -- 未执行特殊逻辑，则直接执行回调
    self:OnBuy()
end

function XUiPanelFashionSuitButtonGroup:OnBuy()
    local title = XUiHelper.GetText("PurchaseFashionRepeatTipsTitle")
    local content = XUiHelper.GetText("PurchaseFashionRepeatTipsContent")
    local isHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnWithAll({ XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self._Id) })
    local sureCb = function()
        if self._GainType == GainType.Purchase then
            self:OnPurchaseBuy()
        elseif self._GainType == GainType.Shop then
            self:OnShopBuy()
        end
    end
    -- 已有涂装则二次确认，V1.31折价礼包不弹二次确认提示
    if isHaveFashion and self._ItemData.ConvertSwitch >= self._ItemData.consumeCount then
        XUiManager.DialogTip(title, content, nil, nil, sureCb)
    else
        sureCb()
    end
end

--endregion

--region 礼包价格信息

function XUiPanelFashionSuitButtonGroup:ShowPurchase(itemData)
    self._ItemData = itemData
    self:SetHideTime()
    --礼包未开启
    if not self._ItemData then
        self:SetBuyClose()
        return
    end
    --折扣
    self:ShowDiscount()
    --价格
    self:ShowPrice()
    --生效时间
    if self:CheckExpirationTime() then
        return
    end
    --下架时间
    if self:CheckRemovalTime() then
        return
    end
end

function XUiPanelFashionSuitButtonGroup:ShowDiscount()
    local tag = self._ItemData.Tag
    local isShowTag, tagSprice, tagText
    if tag > 0 then
        isShowTag = true
        tagSprice = XPurchaseConfigs.GetTagBgPath(tag)

        tagText = XPurchaseConfigs.GetTagDes(tag)
        if XPurchaseConfigs.GetTagType(tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self._ItemData)
            if disCountValue < 1 then
                if XOverseaManager.IsOverSeaRegion() and not XOverseaManager.IsTWRegion() then
                    local disCountStr = tostring(math.floor((1 - disCountValue) * 100))
                    tagText = string.format("%s%s", disCountStr, tagText)
                else
                    local disCountStr = string.format("%.1f", disCountValue * 10)
                    if self._ItemData.DiscountShowStr and self._ItemData.DiscountShowStr ~= "" then
                        disCountStr = self._ItemData.DiscountShowStr
                    end
                    tagText = string.format("%s%s", disCountStr, tagText)
                end
                if XOverseaManager.IsJPRegion() then
                    tagText = "お得"
                end
                self._IsDisCount = true
            else
                isShowTag = false
            end
        end
        self.TxtDiscount.text = tagText
    else
        isShowTag = false
    end

    self:SetDiscount(isShowTag, tagText, tagSprice)
end

function XUiPanelFashionSuitButtonGroup:ShowPrice()
    local isShowDiscount, consumeCountStr
    local consumeCount = self._ItemData.ConsumeCount or 0

    if consumeCount == 0 then
        --免费
        self:SetPriceFree()
    elseif self._IsDisCount or self._ItemData.ConvertSwitch < consumeCount then
        if self._ItemData.ConvertSwitch <= 0 then
            --无需购买
            self:SetBuyClose()
        else
            --打折或者存在拥有物品折扣的
            local consumeNum = consumeCount
            if self._ItemData.ConvertSwitch > 0 and self._ItemData.ConvertSwitch < consumeCount then
                consumeNum = self._ItemData.ConvertSwitch
            end
            if self._IsDisCount then
                local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self._ItemData)
                consumeNum = math.modf(disCountValue * consumeNum) or ""
            end
            isShowDiscount = true
            consumeCountStr = self._ItemData.ConsumeCount or ""
            self:SetCurPrice(consumeNum)
        end
    else
        self:SetCurPrice(self._ItemData.ConsumeCount or "")
    end

    self:SetConsumeIcon(true, self._ItemData.ConsumeId)
    self:SetOriginalPrice(isShowDiscount, consumeCountStr)
end

function XUiPanelFashionSuitButtonGroup:CheckReleaseDate()
    local nowTime = XTime.GetServerNowTimestamp()
    if self._ItemData.TimeToShelve > 0 and nowTime < self._ItemData.TimeToShelve then
        self._RemainTime = self._ItemData.TimeToShelve - XTime.GetServerNowTimestamp()
        if self._RemainTime > 0 then
            --大于0，注册。
            self._UpdateTimerType = UpdateTimerTypeEnum.SettOn
            self.Parent:RegisterTimerFun(self._Id, handler(self, self.UpdateTimer))
        else
            self.Parent:RemoveTimerFun(self._Id)
        end
        --{0}后上架
        self:SetWaitListed(XUiHelper.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self._RemainTime, XUiHelper.TimeFormatType.PURCHASELB)))
        return true
    end
    return false
end

function XUiPanelFashionSuitButtonGroup:CheckExpirationTime()
    if self._ItemData.TimeToInvalid and self._ItemData.TimeToInvalid > 0 then
        self._RemainTime = self._ItemData.TimeToInvalid - XTime.GetServerNowTimestamp()
        if self._RemainTime > 0 then
            --大于0，注册
            self._UpdateTimerType = UpdateTimerTypeEnum.SettOff
            self.Parent:RegisterTimerFun(self._Id, handler(self, self.UpdateTimer))
            --{0}后下架
            self:SetWillBeTakenDown(XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self._RemainTime, XUiHelper.TimeFormatType.PURCHASELB)))
        else
            self.Parent:RemoveTimerFun(self._Id)
            --下架了
            self:SetHasBeTakenDown()
        end
        return true
    end
    return false
end

function XUiPanelFashionSuitButtonGroup:CheckRemovalTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self._ItemData.TimeToUnShelve > 0 then
        if nowTime < self._ItemData.TimeToUnShelve then
            self._RemainTime = self._ItemData.TimeToUnShelve - nowTime
            self._UpdateTimerType = UpdateTimerTypeEnum.SettOff
            self.Parent:RegisterTimerFun(self._Id, handler(self, self.UpdateTimer))
            --{0}后下架
            self:SetWillBeTakenDown(XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self._RemainTime, XUiHelper.TimeFormatType.PURCHASELB)))
        else
            --下架了
            self:SetHasBeTakenDown()
        end
        return true
    end
    return false
end

---更新倒计时
function XUiPanelFashionSuitButtonGroup:UpdateTimer()
    self._RemainTime = self._RemainTime - 1

    if self._RemainTime <= 0 then
        self.Parent:RemoveTimerFun(self._Id)
        if self._UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            --下架了
            self:SetHasBeTakenDown()
            return
        end

        self:SetHideTime()
        return
    end

    if self._UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        --{0}后下架
        self:SetWillBeTakenDown(XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self._RemainTime, XUiHelper.TimeFormatType.PURCHASELB)))
        return
    end

    --{0}后上架
    self:SetWaitListed(XUiHelper.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self._RemainTime, XUiHelper.TimeFormatType.PURCHASELB)))
end

--endregion

--region 礼包购买

function XUiPanelFashionSuitButtonGroup:OnPurchaseBuy()
    if self:CheckPurchaseBuy() then
        if self._ItemData and self._ItemData.Id then
            XDataCenter.PurchaseManager.PurchaseRequest(self._ItemData.Id, function()
                self:UpdateView()
                self.Parent:ShowGift()
            end, 1, nil, XPurchaseConfigs.GetLBUiTypesList(), nil, nil, nil, function()
                self:ShowWearPopup()
            end)
        end
    end
end

function XUiPanelFashionSuitButtonGroup:CheckPurchaseBuy(count, disCountCouponIndex)
    count = count or 1
    disCountCouponIndex = disCountCouponIndex or 0

    if self._ItemData.BuyLimitTimes > 0 and self._ItemData.BuyTimes == self._ItemData.BuyLimitTimes then
        --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return false
    end

    if self._ItemData.TimeToShelve > 0 and self._ItemData.TimeToShelve > XTime.GetServerNowTimestamp() then
        --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return false
    end

    if self._ItemData.TimeToUnShelve > 0 and self._ItemData.TimeToUnShelve < XTime.GetServerNowTimestamp() then
        --下架了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if self._ItemData.TimeToInvalid > 0 and self._ItemData.TimeToInvalid < XTime.GetServerNowTimestamp() then
        --失效了
        XUiManager.TipText("PurchaseSettOff")
        return false
    end

    if self._ItemData.ConsumeCount > 0 and self._ItemData.ConvertSwitch <= 0 then
        -- 礼包内容全部拥有
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return false
    end

    local consumeCount = self._ItemData.ConsumeCount
    if disCountCouponIndex and disCountCouponIndex ~= 0 then
        local disCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self._ItemData, disCountCouponIndex)
        consumeCount = math.floor(disCountValue * consumeCount)
    else
        if self._ItemData.ConvertSwitch and consumeCount > self._ItemData.ConvertSwitch then
            -- 已经被服务器计算了抵扣和折扣后的钱
            consumeCount = self._ItemData.ConvertSwitch
        end

        if XPurchaseConfigs.GetTagType(self._ItemData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            -- 计算打折后的钱(普通打折或者选择了打折券)
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self._ItemData)
            consumeCount = math.floor(disCountValue * consumeCount)
        end
    end

    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(self._ItemData.ConsumeId) then
        --钱不够
        local tips = XUiHelper.GetCountNotEnoughTips(self._ItemData.ConsumeId)
        XUiManager.TipMsg(tips, XUiManager.UiTipType.Wrong)
        if self._ItemData.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            self:OnPurchaseMoneyNotEnough(XPurchaseConfigs.TabsConfig.HK)
        elseif self._ItemData.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            local payCount = consumeCount - XDataCenter.ItemManager.GetCount(self._ItemData.ConsumeId)
            self:OnPurchaseMoneyNotEnough(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end
        return false
    end

    return true
end

function XUiPanelFashionSuitButtonGroup:OnPurchaseMoneyNotEnough(skipIndex, leftTabIndex, payCount)
    if leftTabIndex == nil then
        leftTabIndex = 1
    end
    if skipIndex == XPurchaseConfigs.TabsConfig.Pay and XHeroSdkManager.IsPayEnable() then
        if payCount then
            XLuaUiManager.Open("UiPurchaseQuickBuy", payCount)
        end
    end
end

--endregion

--region 商店商品价格信息

function XUiPanelFashionSuitButtonGroup:ShowGoods(data)
    self._GoodsData = data
    self:SetHideTime()
    --商店未开启
    if not self._GoodsData then
        self:SetBuyClose()
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

function XUiPanelFashionSuitButtonGroup:ShowGoodsDiscount()
    self.OnSales = {}
    self.Sales = 100

    XTool.LoopMap(self._GoodsData.OnSales, function(k, sales)
        self.OnSales[k] = sales
    end)

    if not XTool.IsTableEmpty(self.OnSales) then
        local sortedKeys = {}
        for k, _ in pairs(self.OnSales) do
            table.insert(sortedKeys, k)
        end
        table.sort(sortedKeys)

        for i = 1, #sortedKeys do
            if self._GoodsData.TotalBuyTimes >= sortedKeys[i] - 1 then
                self.Sales = self.OnSales[sortedKeys[i]]
            end
        end
    end

    local hideSales, discount
    if self._GoodsData.Tags == XShopManager.ShopTags.DisCount then
        if self.Sales < 100 then
            discount = string.format("%s%S", self.Sales / 10, XUiHelper.GetText("Snap"))
        else
            hideSales = true
        end
    end

    if self._GoodsData.Tags == XShopManager.ShopTags.Not or hideSales then
        self:SetDiscount(false)
    else
        self:SetDiscount(true, discount)
    end
end

function XUiPanelFashionSuitButtonGroup:ShowGoodsPrice()
    local count = self._GoodsData.ConsumeList[1]
    self:SetConsumeIcon(true, count.Id)
    self:SetOriginalPrice(self.Sales ~= 100, count.Count)
    self:SetCurPrice(math.floor(count.Count * self.Sales / 100))
end

function XUiPanelFashionSuitButtonGroup:CheckGoodsRemovalTime()
    local time = self._GoodsData.SelloutTime
    if time and time > 0 then
        self._RemainTime = math.max(0, XShopManager.GetLeftTime(time))
        if self._RemainTime <= 0 then
            self:SetHasBeTakenDown()
        else
            local dataTime = XUiHelper.GetTime(self._RemainTime, XUiHelper.TimeFormatType.SHOP)
            self:SetWillBeTakenDown(XUiHelper.GetText("TimeSoldOut", dataTime))
            self._UpdateTimerType = UpdateTimerTypeEnum.SettOff
            self.Parent:RegisterTimerFun(self._Id, handler(self, self.UpdateTimer))
        end
    else
        self:SetHideTime()
    end
end

function XUiPanelFashionSuitButtonGroup:CheckGoodsCondition()
    local conditionIds = self._GoodsData.ConditionIds
    if not conditionIds or #conditionIds <= 0 then
        return
    end

    for _, id in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id)
        if not ret then
            self:SetBuyCondition(desc)
            return
        end
    end
end

--endregion

--region 商店购买

function XUiPanelFashionSuitButtonGroup:OnShopBuy()
    for _, consume in pairs(self._GoodsData.ConsumeList) do
        if consume.Id == XDataCenter.ItemManager.ItemId.HongKa then
            local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, consume.Count)
            if not result then
                local tips = XUiHelper.GetCountNotEnoughTips(consume.Id)
                XUiManager.TipMsg(tips, XUiManager.UiTipType.Wrong)
                return
            end
        elseif consume.Id == XDataCenter.ItemManager.ItemId.PaidGem then
            local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, consume.Count)
            if not result then
                XUiManager.TipText("ShopItemPaidGemNotEnough")
                XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
                return
            end
        end
    end

    XShopManager.BuyShop(self._GainParams[1], self._GoodsData.Id, 1, function(res)
        self:UpdateView()
        self.Parent:ShowGift()
        local text = XUiHelper.GetText("BuySuccess")
        XUiManager.TipMsg(text, nil, function()
            if res.IsShowBuyResult and not XTool.IsTableEmpty(res.GoodList) then
                XUiManager.OpenUiObtain(res.GoodList, nil, function()
                    self:ShowWearPopup()
                end)
            else
                self:ShowWearPopup()
            end
        end)
    end)
end

--endregion

function XUiPanelFashionSuitButtonGroup:ShowWearPopup()
    local characterId = XDataCenter.FashionManager.GetCharacterId(self._Id)
    local isOwnCharacter = XMVCA.XCharacter:IsOwnCharacter(characterId)
    if not isOwnCharacter then
        return
    end
    
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("FashionSuitWearTip"), nil, nil, function()
        XDataCenter.FashionManager.UseFashion(self._Id, function()
            XUiManager.TipText("UseSuccess")
            self:UpdateView()
        end)
    end)
end

function XUiPanelFashionSuitButtonGroup:SetButtonBg(buyBg, getBg, wearBg)
    self.BtnBuy:SetRawImage(buyBg)
    self.BtnGet:SetRawImage(getBg)
    self.BtnWear:SetRawImage(wearBg)
end

return XUiPanelFashionSuitButtonGroup
