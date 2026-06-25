---@class XUiPanelFashionSuitPurchase
local XUiPanelFashionSuitPurchase = XClass(nil, "XUiPanelFashionSuitPurchase")

function XUiPanelFashionSuitPurchase:Ctor(root)
    ---@type XUiPanelFashionSuitButtonGroup
    self._Parent = root
end

function XUiPanelFashionSuitPurchase:InitContext(context, helper)
    ---@type XUiHelperFashionSuit
    self._Helper = helper
    ---@type XFashionContext
    self._Context = context
end

function XUiPanelFashionSuitPurchase:ActionBuy(params, fashionGroup)
    self._Params = params
    ---@type XTableFashionGroup
    self._FashionGroup = fashionGroup
    self._ItemDataList = {}
    self._PackageId = self._Context:GetCurParams()[1]

    self:SetGroupItemData()
    self:ShowPurchase()
end

function XUiPanelFashionSuitPurchase:PurchaseConsumeCount()
    return XMVCA.XFashionSuit:PurchaseConsumeCount(self._ItemDataList)
end

function XUiPanelFashionSuitPurchase:PurchaseConvertSwitch()
    return XMVCA.XFashionSuit:PurchaseConvertSwitch(self._ItemDataList)
end

function XUiPanelFashionSuitPurchase:SetGroupItemData()
    for _, id in ipairs(self._Params) do
        local packageId = self._Context:GetParams(id)[1]
        local data = XDataCenter.PurchaseManager.GetPurchaseDataById(packageId)
        if data then
            table.insert(self._ItemDataList, data)
        end
    end
end

function XUiPanelFashionSuitPurchase:ShowPurchase()
    self._ItemData = XDataCenter.PurchaseManager.GetPurchaseDataById(self._PackageId)
    self._Parent:SetHideTime()
    --礼包未开启
    if not self._ItemData then
        self._Parent:SetBuyClose()
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
    self:CheckRemovalTime()
end

function XUiPanelFashionSuitPurchase:ShowDiscount()
    local tag = self._ItemData.Tag
    local isShowTag, tagSprice, tagText
    if tag > 0 then
        isShowTag = true
        tagSprice = XPurchaseConfigs.GetTagBgPath(tag)
        tagText = XPurchaseConfigs.GetTagDes(tag)

        if XPurchaseConfigs.GetTagType(tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self._ItemData)
            if disCountValue < 1 then
                if  XOverseaManager.IsJPRegion() then
                    tagText = XUiHelper.GetDiscountTextV2(disCountValue)
                elseif XOverseaManager.IsKRRegion() or XOverseaManager.IsENRegion() then
                    tagText = tostring(math.floor((1-disCountValue) * 100))..tagText
                else
                    local disCountStr = string.format("%.1f", disCountValue * 10)
                    if self._ItemData.DiscountShowStr and self._ItemData.DiscountShowStr ~= "" then
                        disCountStr = self._ItemData.DiscountShowStr
                    end
                    tagText = string.format("%s%s", disCountStr, tagText)
                end
            else
                isShowTag = false
            end
        end
        self._Parent.TxtDiscount.text = tagText
    else
        isShowTag = false
    end
    self._Parent:SetDiscount(isShowTag, tagText, tagSprice)
end

function XUiPanelFashionSuitPurchase:ShowPrice()
    local price, originalPrice = XMVCA.XFashionSuit:GetRealPurchasePriceWithDiscount(self._ItemDataList)
    if price == -1 then
        --无需购买
        self._Parent:SetBuyClose()
    elseif price == 0 then
        --免费
        self._Parent:SetPriceFree()
    else
        -- 需要判断是否足够
        local isEnough = self:_CheckBuyEnough(price)
        
        local priceStr = isEnough and tostring(price) or XUiHelper.GetText("PurchaseFashionSuitDetailCoinNotEnough", price)
        
        self._Parent:SetCurPrice(priceStr)
    end
    self._CurPrice = price
    self._Parent:SetConsumeIcon(true, self._ItemData.ConsumeId)
    self._Parent:SetOriginalPrice(originalPrice ~= nil, originalPrice)
end

---@return number, number 实际价格，原价, itemId
function XUiPanelFashionSuitPurchase:GetPrice()
    local price, originalPrice = XMVCA.XFashionSuit:GetRealPurchasePriceWithDiscount(self._ItemDataList)
    
    return price, originalPrice, self._ItemData.ConsumeId
end

function XUiPanelFashionSuitPurchase:CheckExpirationTime()
    if self._ItemData.TimeToInvalid and self._ItemData.TimeToInvalid > 0 then
        local remainTime = self._ItemData.TimeToInvalid - XTime.GetServerNowTimestamp()
        self._Parent:SetRemainTime(remainTime)
        if remainTime > 0 then
            --大于0，注册
            self._Parent:SettOff()
            --{0}后下架
            self._Parent:SetWillBeTakenDown(XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB)))
        else
            self._Parent:RemoveTimerFun()
            --下架了
            self._Parent:SetHasBeTakenDown()
        end
        return true
    end
    return false
end

function XUiPanelFashionSuitPurchase:CheckRemovalTime()
    local nowTime = XTime.GetServerNowTimestamp()
    if self._ItemData.TimeToUnShelve > 0 then
        if nowTime < self._ItemData.TimeToUnShelve then
            local remainTime = self._ItemData.TimeToUnShelve - nowTime
            self._Parent:SetRemainTime(remainTime)
            self._Parent:SettOff()
            --{0}后下架
            self._Parent:SetWillBeTakenDown(XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB)))
        else
            --下架了
            self._Parent:SetHasBeTakenDown()
        end
    end
end

--- 判断当前是否足够资源购买，参数依赖外部传参
function XUiPanelFashionSuitPurchase:_CheckBuyEnough(needCount)
    local consumeId = self._ItemData.ConsumeId

    if not XTool.IsNumberValidEx(needCount) or not XTool.IsNumberValidEx(consumeId) then
        -- 参数不充分默认足够
        return true
    end

    local haveCount = XDataCenter.ItemManager.GetCount(consumeId)

    return haveCount >= needCount
end

--region 购买

function XUiPanelFashionSuitPurchase:OnPurchaseBuy()
    if not self._ItemData then
        return
    end
    if XMVCA.XFashionSuit:CheckPurchaseGroupBuy(self._ItemDataList) then
        if self._Helper:IsEnableGroupSales() then
            local ids = {}
            for _, itemData in pairs(self._ItemDataList) do
                table.insert(ids, itemData.Id)
            end
            XDataCenter.PurchaseManager.MultiPurchaseRequest(ids, XPurchaseConfigs.GetLBUiTypesList(), function(rewardList)
                self:OnPurchaseBuyViewRefresh(rewardList)
            end)
        else
            XDataCenter.PurchaseManager.PurchaseRequest(self._ItemData.Id, function(rewardList)
                self:OnPurchaseBuyViewRefresh(rewardList)
            end, 1, nil, XPurchaseConfigs.GetLBUiTypesList())
        end
    end
end

function XUiPanelFashionSuitPurchase:OnPurchaseBuyViewRefresh(rewardList)
    self._Parent:UpdateView()
    self._Parent.Parent:ShowGift()
    self._Parent.Parent.Parent:CallPurchaseCb(rewardList)
    XEventManager.DispatchEvent(XEventId.EVENT_FASHION_SUIT_PURCHASE_BUY, rewardList)
end

--endregion

return XUiPanelFashionSuitPurchase