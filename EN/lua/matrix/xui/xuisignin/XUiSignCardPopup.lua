---@class XUiSignCardPopup : XLuaUi
local XUiSignCardPopup = XLuaUiManager.Register(XLuaUi, "UiSignCardPopup")
local XUiObtain = require("XUi/XUiObtain/XUiObtain")
local XUiSignCard = require("XUi/XUiSignIn/XUiSignCard")

function XUiSignCardPopup:OnAwake()
    self:RegisterUiEvents()
end

function XUiSignCardPopup:OnStart()
    self.PanelBuy.gameObject:SetActive(false)
    self.PanelGet.gameObject:SetActive(false)
    self.BtnContinue.gameObject:SetActive(false)
    if XOverseaManager.IsKRRegion() then
        if self.TxtCount then
            self.TxtCount.text = CS.XTextManager.GetText("KRYKfirst")
        end
    end
    if XOverseaManager.IsJPRegion() then
        if self.TxtCount then
            self.TxtCount.text = CS.XTextManager.GetText("JPYKfirst")
        end
    end

    self:Refresh()
end

function XUiSignCardPopup:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.Refresh, self)
end

function XUiSignCardPopup:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.Refresh, self)
end

function XUiSignCardPopup:Refresh()
    if self:RefreshButtonsAndBg(false) then
        XDataCenter.PurchaseManager.YKInfoDataReq(function()
            self:RefreshButtonsAndBg(true)
        end)
    end
end

function XUiSignCardPopup:RefreshButtonsAndBg(autoGetReward)
    local isBuy = XDataCenter.PurchaseManager.IsYkBuyed()
    if isBuy then
        self:RefreshGet()
        if autoGetReward then self:AutoGetReward() end
    else
        self:Close()
        return false
    end

    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if data then
        if XOverseaManager.IsENRegion() then
            self.IsCardC = data and data.Id == XPurchaseConfigs.EnYKCID
            self.Bg.gameObject:SetActiveEx(not self.IsCardC)
            self.BgC.gameObject:SetActiveEx(self.IsCardC)
            self.ImgNormal.gameObject:SetActiveEx(not self.IsCardC)
            self.ImgNormal2.gameObject:SetActiveEx(not self.IsCardC)
            self.ImgNormalC.gameObject:SetActiveEx(self.IsCardC)
            self.ImgNormalC2.gameObject:SetActiveEx(self.IsCardC)
        end

        local ykConfig = XPurchaseConfigs.GetPurchasePackageYKUiConfig(data.Id)
        self.TipText01.text = ykConfig.Tips[1]
        self.TipText02.text = ykConfig.Tips[2]
    end

    return true
end

function XUiSignCardPopup:RefreshInfo(data)
    if not XOverseaManager.IsENRegion() then
        return
    end
    if not self.CardBg then
        self.CardBg = self.Transform:Find("SafeAreaContentPane/SignCard/Bg/Bg"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
    end
    if not self.CardABgPath then
        self.CardABgPath = CS.XGame.ClientConfig:GetString("MonthlyCardABg")
    end
    if not self.CardCBgPath then
        self.CardCBgPath = CS.XGame.ClientConfig:GetString("MonthlyCardCBg")
    end
    local isA = data.Id == 83028
    self.CardBg:SetImage(isA and self.CardABgPath or self.CardCBgPath)

    if self.TxtCount then
        self.TxtCount.text = data.RewardGoodsList[1].Count
    end

    if self.TxtCountDay then
        self.TxtCountDay.text = data.Desc
    end
end

function XUiSignCardPopup:AutoGetReward()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data or data.IsDailyRewardGet then
        return
    end

    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(data.Id, function(rewardItems)
        self:RefreshGet()

        XUiObtain.SetRewardsIsShowYKTag(rewardItems)
        XUiManager.OpenUiObtain(rewardItems)

        -- 设置月卡信息本地缓存
        XDataCenter.PurchaseManager.SetYKLocalCache()
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
    end)
end

function XUiSignCardPopup:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBigClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnRetroactive, self.OnBtnRetroactiveClick)

    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
    self:RegisterClickEvent(self.BtnHelpRetroactive, self.OnBtnHelpRetroactiveClick)
end

local ON_SIGNCARD_POPUP_INTERACTIVE_ARG_TARGET_TYPE_CONTINUE = "1"
local ON_SIGNCARD_POPUP_INTERACTIVE_ARG_TARGET_TYPE_DEFAULT = "2"

function XUiSignCardPopup:OnBtnContinueClick()
    self:Record(ON_SIGNCARD_POPUP_INTERACTIVE_ARG_TARGET_TYPE_CONTINUE)

    XUiSignCard.GotoPurchaseUi(
        self,
        function()
            self:Close()
            XLuaUiManager.SafeClose("UiPurchase")
        end)
end

function XUiSignCardPopup:OnBtnHelpRetroactiveClick()
    self:Record()
    XUiSignCard.OnBtnHelpRetroactiveClick(self)
end

function XUiSignCardPopup:Record(arg)
    arg = arg or ON_SIGNCARD_POPUP_INTERACTIVE_ARG_TARGET_TYPE_DEFAULT
    CS.XRecord.Record({ ["target"] = arg }, "20026", "OnSignCardPopupInteractive")
end

function XUiSignCardPopup:OnBtnTanchuangCloseBigClick()
    self:Record()
    self:Close()
end

function XUiSignCardPopup:OnBtnGetClick()
    self:Record()
    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        local data = XDataCenter.PurchaseManager.GetYKInfoData()
        if not data then
            return
        end

        if data.IsDailyRewardGet then
            XUiManager.TipText("ChallengeRewardIsGetted")
        else
            XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(data.Id, function(rewardItems)
                self:RefreshGet()

                XUiObtain.SetRewardsIsShowYKTag(rewardItems)
                XUiManager.OpenUiObtain(rewardItems)

                -- 设置月卡信息本地缓存
                XDataCenter.PurchaseManager.SetYKLocalCache()
                XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
            end)
        end
    end)
end

function XUiSignCardPopup:RefreshGet()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data then
        return
    end
    local ykConfig = XSignInConfigs.GetSignCardConfigByPurchasePackageId(data.Id)

    local remainDay = not XOverseaManager.IsJP_KR_ENRegion() and data.DailyRewardRemainDay or data.DailyRewardRemainDay - 1
    if remainDay < 0 then
        remainDay = 0
    end

    self.TxtLeftDay.text = remainDay
    self.BtnContinue.gameObject:SetActive(data.BuyLimitRemainDay <= ykConfig.CanBuyDay)
    self.TxtRetroactiveExpireTime.gameObject:SetActiveEx(false)

    local cardsMissed = 0
    local retroactiveItemId = data.DailyRewardSupplementGetConsumeItemId

    if data.DailyRewardSupplementGetData then
        cardsMissed = data.DailyRewardSupplementGetData.Count
    end

    if data.IsDailyRewardGet then
        self.BtnGet.gameObject:SetActive(false)
        self.BtnRetroactive.gameObject:SetActive(true)
        self.TxtMissedCards.text = tostring(cardsMissed)
        local itemManager = XDataCenter.ItemManager

        local retroactiveItemCount =
            itemManager.GetCount(retroactiveItemId)

        local retroactiveItemIcon =
            itemManager.GetItemIcon(retroactiveItemId)

        self.ImgRetroactiveItemIcon1:SetRawImage(retroactiveItemIcon)
        self.ImgRetroactiveItemIcon2:SetRawImage(retroactiveItemIcon)
        self.ImgRetroactiveItemIcon3:SetRawImage(retroactiveItemIcon)

        local retroactiveChance =
            tostring(retroactiveItemCount) .. "/" .. tostring(math.min(retroactiveItemCount, cardsMissed))

        self.TxtRetroactiveChance1.text = retroactiveChance
        self.TxtRetroactiveChance2.text = retroactiveChance
        self.TxtRetroactiveChance3.text = retroactiveChance

        if retroactiveItemCount > 0 then
            if cardsMissed > 0 then
                self.BtnRetroactive:SetButtonState(CS.UiButtonState.Normal)
                self.BtnRetroactive:ShowReddot(true)
            else
                self.BtnRetroactive:SetButtonState(CS.UiButtonState.Disable)
                self.BtnRetroactive:ShowReddot(false)
            end


            -- 每自然月一号05:00 AM过期
            local hour5 = 5 * 60 * 60
            local now = XTime.GetServerNowTimestamp()
            local leftTime = XTime.GetCurrentMonthFirstDay() + hour5
            if now >= leftTime then
                leftTime = XTime.GetNextMonthFirstDay() + hour5
            end
            leftTime = leftTime - now

            local deadlineStr = XUiHelper.GetTimeDesc(leftTime, 2)

            self.TxtRetroactiveExpireTime.text = leftTime <= 0 and deadlineStr or CS.XTextManager.GetText("ItemDeadLine", deadlineStr)
            self.TxtRetroactiveExpireTime.gameObject:SetActiveEx(true)
        else
            self.BtnRetroactive:ShowReddot(false)
            self.TxtRetroactiveChance3.text = retroactiveChance
            self.BtnRetroactive:SetButtonState(CS.UiButtonState.Disable)
        end
    else
        -- 未领取，需要领取
        self.BtnGet.gameObject:SetActive(true)
        self.BtnRetroactive.gameObject:SetActive(false)
        self.BtnGet:SetButtonState(CS.UiButtonState.Normal)
    end

    self.PanelGet.gameObject:SetActive(true)
end

function XUiSignCardPopup:OnBtnRetroactiveClick()
    self:Record()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()

    local cardsMissed = 0
    if data.DailyRewardSupplementGetData then
        cardsMissed = data.DailyRewardSupplementGetData.Count
    end

    if cardsMissed <= 0 then
        XUiManager.TipText("PurchaseYKRetroactiveNotNeeded")
        return
    end

    local ykConfig = XSignInConfigs.GetSignCardConfigByPurchasePackageId(data.Id)

    local itemCount = XDataCenter.ItemManager.GetCount(
        data.DailyRewardSupplementGetConsumeItemId)

    if itemCount > 0 then
        XDataCenter.PurchaseManager.PurchaseSupplementGetDailyReward(
            ykConfig.Param[2],
            function(rewardList)
                self:RefreshGet()
                XUiObtain.SetRewardsIsShowYKTag(rewardList)
                XUiManager.OpenUiObtain(rewardList)
            end)
    else
        XUiManager.TipText("PurchaseYKRetroactiveNeedMoreItems")
    end
end

return XUiSignCardPopup
