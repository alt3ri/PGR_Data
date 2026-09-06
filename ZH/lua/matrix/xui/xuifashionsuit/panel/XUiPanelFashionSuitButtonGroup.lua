---@class XUiPanelFashionSuitButtonGroup : XUiNode 套装涂装三级界面购买、跳转和穿戴按钮
---@field Parent XUiPanelFashionDetail
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
    self.BtnRandomWear:AddEventListener(handler(self, self.OnBtnRandomWearClick))
    self.BtnBuySuit:AddEventListener(handler(self, self.OnBtnBuySuitClick))
    ---@type XUiPanelFashionSuitPurchase
    self._Purchase = require("XUi/XUiFashionSuit/Panel/XUiPanelFashionSuitPurchase").New(self)
    ---@type XUiPanelFashionSuitShop
    self._Shop = require("XUi/XUiFashionSuit/Panel/XUiPanelFashionSuitShop").New(self)
end

function XUiPanelFashionSuitButtonGroup:InitContext(context, helper)
    ---@type XUiHelperFashionSuit
    self._Helper = helper
    ---@type XFashionContext
    self._Context = context
    self._Context:RegistActionHandlers(XEnumConst.FashionSuit.Action.Wear, handler(self, self.ActionWear))
    self._Context:RegistActionHandlers(XEnumConst.FashionSuit.Action.Buy, handler(self, self.ActionBuy))
    self._Context:RegistActionHandlers(XEnumConst.FashionSuit.Action.JoinRandom, handler(self, self.ActionJoinRandom))

    self._Purchase:InitContext(context, helper)
    self._Shop:InitContext(context, helper)
end

function XUiPanelFashionSuitButtonGroup:OnBtnGetClick()
    local skipId = self._Context:GetCurParams()[1]
    if not XTool.IsNumberValid(skipId) then
        return
    end

    XLuaUiManager.Open("UiSkip", self._Context.SourceId, nil, nil, { skipId })
end

function XUiPanelFashionSuitButtonGroup:OnBtnWearClick()
    XMVCA.XFashionSuit:RecursionUseFashion(self._CharacterId, self._Params, function()
        XUiManager.TipText("UseSuccess")
        self:UpdateView()
    end)
end

function XUiPanelFashionSuitButtonGroup:OnBtnBuyClick()
    self:OnBuyBefore()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1011)
end

function XUiPanelFashionSuitButtonGroup:OnBtnRandomWearClick()
    local characterId = self._Context.CharacterId
    XMVCA.XFashionSuit:JoinFashionToRandom(characterId, self._Params[1], self._Params[2], function()
        XUiManager.TipText("FashionAddToRandomTip")
        self:UpdateView()
    end)
end

function XUiPanelFashionSuitButtonGroup:UpdateBuyBtn()
    if self._Id then
        self:RemoveTimerFun()
    end
    self._Id = self._Context.SourceId
    self._FashionGroup = XMVCA.XFashionSuit:GetFashionGroupByFashionId(self._Id)
    self._Context:AppyActionHandler()
end

function XUiPanelFashionSuitButtonGroup:ActionBuy(characterId, params)
    self._CharacterId = characterId
    self._Params = params
    
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnGet.gameObject:SetActiveEx(false)
    self.BtnWear.gameObject:SetActiveEx(false)
    self.BtnRandomWear.gameObject:SetActiveEx(false)
    
    self._GainType = self._FashionGroup.GainType

    for _, id in ipairs(params) do
        local gainParams = self._Context:GetParams(id)
        if not XMVCA.XFashionSuit:CheckGainParamsValid(self._GainType, gainParams) then
            self:SetBuyClose()
            return
        end
    end
    if self._GainType == GainType.Purchase then
        self.BtnBuy.gameObject:SetActiveEx(true)
        self._Purchase:ActionBuy(params, self._FashionGroup)
    elseif self._GainType == GainType.Shop then
        self.BtnBuy.gameObject:SetActiveEx(true)
        self._Shop:ActionBuy(params, self._FashionGroup)
    elseif self._GainType == GainType.Skip then
        self.BtnGet.gameObject:SetActiveEx(true)
    else
        self:SetBuyClose()
    end
end

function XUiPanelFashionSuitButtonGroup:ActionWear(characterId, params)
    local isEmpty = #params == 0
    self._CharacterId = characterId
    self._Params = params
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnGet.gameObject:SetActiveEx(false)
    self.BtnRandomWear.gameObject:SetActiveEx(false)
    self.BtnWear.gameObject:SetActiveEx(true)
    self.BtnWear:SetDisable(isEmpty, not isEmpty)
    self:RemoveTimerFun()
end

function XUiPanelFashionSuitButtonGroup:ActionJoinRandom(characterId, params)
    local isEmpty = #params == 0
    self._CharacterId = characterId
    self._Params = params
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnGet.gameObject:SetActiveEx(false)
    self.BtnWear.gameObject:SetActiveEx(false)
    self.BtnRandomWear.gameObject:SetActiveEx(true)
    self.BtnRandomWear:SetDisable(isEmpty, not isEmpty)
    self:RemoveTimerFun()
end

function XUiPanelFashionSuitButtonGroup:UpdateView()
    self:UpdateBuyBtn()
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
    self.BtnBuy:SetDisable(false, true)
end

---设置折扣
function XUiPanelFashionSuitButtonGroup:SetDiscount(isVisible, discount, tagSprice)
    if isVisible then
        self.ImgTagDiscount.gameObject:SetActive(true)
        if not string.IsNilOrEmpty(tagSprice) then
            self.ImgTagDiscount:SetSprite(tagSprice)
        end
        if discount then
            if XOverseaManager.IsJPRegion() then
                self.TxtDiscount.text = XUiHelper.GetDiscountTextV2(discount)
            else
                self.TxtDiscount.text = discount
            end
        end
    else
        self.ImgTagDiscount.gameObject:SetActive(false)
    end
end

---设置为免费获取
function XUiPanelFashionSuitButtonGroup:SetPriceFree()
    self.BtnBuy:SetDisable(false, true)
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
    self.BtnBuy:SetDisable(false, true)
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = timeStr
end

---设置折扣倒计时
function XUiPanelFashionSuitButtonGroup:SetDiscountCountDown(timeStr)
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
    self.BtnBuy.gameObject:SetActiveEx(true)
    self.BtnBuy:SetDisable(true, false)
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

    -- 构建viewmodel
    local realCost, originCost, itemId = self:_GetPrice()

    -- 倒计时：复用按钮区已算的剩余时间，重建绝对结束时间戳（仅下架场景），传入二级弹窗显示倒计时
    local endTime = nil
    if self._UpdateTimerType == UpdateTimerTypeEnum.SettOff and self._RemainTime > 0 then
        endTime = XTime.GetServerNowTimestamp() + self._RemainTime
    end

    local giftId = XFashionConfigs.GetFashionTemplate(self._Id).GiftId
    local isHideWorldDesc = self._Helper:IsEnableGroupSales() and not XTool.IsNumberValid(giftId)

    ---@type CoatingBuyTipsViewModel
    local viewModel = {
        Title = self._Helper:GetName(),
        SubTitle = "", --todo
        DetailDesc = self._Helper:GetDesc(),
        RewardDataList = self._Helper:GetRewards(),
        RealCost = realCost,
        OriginCost = originCost,
        ItemId = itemId,
        AssetsItemIds = { XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa },
        EndTime = endTime,
        IsTimeLimit = XTool.IsNumberValid(endTime),
        IsHideWorldDesc = isHideWorldDesc,
    }

    -- 打开详情界面
    XLuaUiManager.Open("UiPurchaseBuyCoatingTips", viewModel, handler(self, self.OnBuy))
end

function XUiPanelFashionSuitButtonGroup:OnBuy()
    if not self.Parent then
        return
    end
    if self._GainType == GainType.Purchase then
        self._Purchase:OnPurchaseBuy()
    elseif self._GainType == GainType.Shop then
        self._Shop:OnShopBuy()
    end
end

--endregion

---设置剩余时间
function XUiPanelFashionSuitButtonGroup:SetRemainTime(time)
    self._RemainTime = time
end

---注册倒计时
function XUiPanelFashionSuitButtonGroup:SettOff()
    self._UpdateTimerType = UpdateTimerTypeEnum.SettOff
    self.Parent:RegisterTimerFun(self._Id, handler(self, self.UpdateTimer))
    self:UpdateTimer()
end

---移除倒计时
function XUiPanelFashionSuitButtonGroup:RemoveTimerFun()
    self.Parent:RemoveTimerFun(self._Id)
end

---更新倒计时
function XUiPanelFashionSuitButtonGroup:UpdateTimer()
    self._RemainTime = self._RemainTime - 1

    if self._RemainTime <= 0 then
        self:RemoveTimerFun()
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

--function XUiPanelFashionSuitButtonGroup:ShowWearPopup()
--    local characterId = XDataCenter.FashionManager.GetCharacterId(self._Id)
--    local isOwnCharacter = XMVCA.XCharacter:IsOwnCharacter(characterId)
--    if not isOwnCharacter then
--        return
--    end
--    
--    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("FashionSuitWearTip"), nil, nil, function()
--        XDataCenter.FashionManager.UseFashion(self._Id, function()
--            XUiManager.TipText("UseSuccess")
--            self:UpdateView()
--        end)
--    end)
--end

function XUiPanelFashionSuitButtonGroup:SetButtonBg(buyBg, getBg, wearBg, randomWearBg)
    self.BtnBuy:SetRawImage(buyBg)
    self.BtnGet:SetRawImage(getBg)
    self.BtnWear:SetRawImage(wearBg)
    self.BtnRandomWear:SetRawImage(randomWearBg)
end

--region 成套购买

--只有从涂装套装主界面跳转过来时 才开启成套购买功能
function XUiPanelFashionSuitButtonGroup:SetBtnBuySuitVisible(bo, skipUpdateView)
    self._IsGroupSalesVisible = bo
    if self._Context.FashionGroup.GainType == GainType.Skip then
        self.BtnBuySuit.gameObject:SetActiveEx(false)
    else
        self.BtnBuySuit.gameObject:SetActiveEx(bo)
    end
    if skipUpdateView then
        self.Parent:ApplyGroupSalesState(self._IsGroupSalesVisible, self._IsGroupSalesEnable)
    else
        self.Parent:SetGroupSales(self._IsGroupSalesVisible, self._IsGroupSalesEnable)
    end
end

function XUiPanelFashionSuitButtonGroup:OnBtnBuySuitClick()
    self._IsGroupSalesEnable = self.BtnBuySuit.ButtonState == CS.UiButtonState.Select
    self.Parent:SetGroupSales(self._IsGroupSalesVisible, self._IsGroupSalesEnable)
end

--endregion

--region 参数获取

---@return number, number 实际价格，原价, itemId
function XUiPanelFashionSuitButtonGroup:_GetPrice()
    if self._GainType == GainType.Purchase then
        return self._Purchase:GetPrice()
    elseif self._GainType == GainType.Shop then
        return self._Shop:GetPrice()
    end
end

--endregion

return XUiPanelFashionSuitButtonGroup
