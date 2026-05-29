local XUiSignCard = XClass(nil, "XUiSignCard")
local XUiObtain = require("XUi/XUiObtain/XUiObtain")

function XUiSignCard:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitAddListen()
end

function XUiSignCard:OnDestroy()
    self:OnHide()
end

function XUiSignCard:OnHide()
end

function XUiSignCard:OnShow()
    if XOverseaManager.IsJPRegion() then
        if self.TxtCount1 then
            self.TxtCount1.text = CS.XTextManager.GetText("JPYKfirst")
        end
        if self.TxtCount2 then
            self.TxtCount2.text = CS.XTextManager.GetText("JPYKfirst")
        end
    end
       if XOverseaManager.IsKRRegion() then
        if self.TxtCount1 then
            self.TxtCount1.text = CS.XTextManager.GetText("KRYKfirst")
        end
        if self.TxtCount2 then
            self.TxtCount2.text = CS.XTextManager.GetText("KRYKfirst")
        end
    end
end

function XUiSignCard:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiSignCard:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiSignCard:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiSignCard:InitAddListen()
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnRetroactive, self.OnBtnRetroactiveClick)
    self:RegisterClickEvent(self.BtnHelpRetroactive, self.OnBtnHelpRetroactiveClick)
end

function XUiSignCard:OnBtnSkipClick()
    XDataCenter.AutoWindowManager.StopAutoWindow()
    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.YK, false)
end

function XUiSignCard:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", self.Config.Description or "")
end

function XUiSignCard:OnBtnContinueClick()
    XDataCenter.AutoWindowManager.StopAutoWindow()
    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.YK, false)
end

function XUiSignCard:OnBtnGetClick()
    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        local data = XDataCenter.PurchaseManager.GetYKInfoData()
        if not data or data.Id ~= self.Config.Param[2] then
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

function XUiSignCard:Refresh(configId, isShow, isAuto)
    self:RefreshButtons(configId, false)
    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        self.PanelBuy.gameObject:SetActive(false)
        self.PanelGet.gameObject:SetActive(false)

        self:RefreshButtons(configId, isAuto)
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
    end)
end

function XUiSignCard:RefreshButtons(configId, isAuto)
    if not configId then
        configId = self.ConfigId
    end
    self.ConfigId = configId
    self.Config = XSignInConfigs.GetSignCardConfig(configId)

    local ykConfig = XPurchaseConfigs.GetPurchasePackageYKUiConfig(self.Config.Param[2])
    self.TipText01.text = ykConfig.Tips[1]
    self.TipText02.text = ykConfig.Tips[2]

    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    local isBuy = data ~= nil and data.Id == self.Config.Param[2] and data.DailyRewardRemainDay > 0
    if isBuy then
        self:RefreshGet()
        self:AutoGetReward(isAuto)
    else
        self:RefreshBuy()
    end
end

function XUiSignCard:AutoGetReward(isAuto)
    if not isAuto then
        return
    end
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data or data.IsDailyRewardGet then
        return
    end

    XLuaUiManager.SetMask(true)
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        self:GetDailyRewardRequest(data.Id)
    end, 100)
end

function XUiSignCard:GetDailyRewardRequest(id)
    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(id, function(rewardItems)
        self:RefreshGet()
        if self.RootUi.RefreshWelfareCardRed then
            self.RootUi:RefreshWelfareCardRed()
        end

        XUiObtain.SetRewardsIsShowYKTag(rewardItems)
        XUiManager.OpenUiObtain(rewardItems)

        -- 设置月卡信息本地缓存
        XDataCenter.PurchaseManager.SetYKLocalCache()
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
    end)
end

function XUiSignCard:RefreshBuy()
    self.PanelBuy.gameObject:SetActive(true)
end


function XUiSignCard:RefreshGet()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data or data.Id ~= self.Config.Param[2] then
        return
    end

    local remainDay = not XOverseaManager.IsJP_KR_ENRegion() and data.DailyRewardRemainDay or data.DailyRewardRemainDay - 1
    if remainDay < 0 then
        remainDay = 0
    end

    self.TxtLeftDay.text = remainDay
    self.BtnContinue.gameObject:SetActive(data.BuyLimitRemainDay <= self.Config.CanBuyDay)
    self.TxtRetroactiveExpireTime.gameObject:SetActiveEx(false)

    local cardsMissed = 0
    local retroactiveItemId = data.DailyRewardSupplementGetConsumeItemId

    if data.DailyRewardSupplementGetData then
        cardsMissed = data.DailyRewardSupplementGetData.Count
    end

    if data.IsDailyRewardGet then
        -- 已领取
        self.BtnGet.gameObject:SetActive(false)
        self.BtnRetroactive.gameObject:SetActive(true)
        self.TxtMissedCards.text = tostring(cardsMissed)
        local itemManager = XDataCenter.ItemManager

        local retroactiveItemCount =
            itemManager.GetCount(retroactiveItemId)

        local retroactiveItemIcon =
            itemManager.GetItemIcon(retroactiveItemId)

        if self.ImgRetroactiveItemIcon1 then
            self.ImgRetroactiveItemIcon1:SetRawImage(retroactiveItemIcon)
        end

        if self.ImgRetroactiveItemIcon2 then
            self.ImgRetroactiveItemIcon2:SetRawImage(retroactiveItemIcon)
        end

        if self.ImgRetroactiveItemIcon3 then
            self.ImgRetroactiveItemIcon3:SetRawImage(retroactiveItemIcon)
        end

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

function XUiSignCard:OnBtnRetroactiveClick()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data or data.Id ~= self.Config.Param[2] then
        return
    end

    local cardsMissed = 0
    if data.DailyRewardSupplementGetData then
        cardsMissed = data.DailyRewardSupplementGetData.Count
    end

    if cardsMissed <= 0 then
        XUiManager.TipText("PurchaseYKRetroactiveNotNeeded")
        return
    end

    local itemCount = XDataCenter.ItemManager.GetCount(
        data.DailyRewardSupplementGetConsumeItemId)

    if itemCount > 0 then
        XDataCenter.PurchaseManager.PurchaseSupplementGetDailyReward(
            self.Config.Param[2],
            function(rewardList)
                self:RefreshGet()
                XUiObtain.SetRewardsIsShowYKTag(rewardList)
                XUiManager.OpenUiObtain(rewardList)
            end)
    else
        XUiManager.TipText("PurchaseYKRetroactiveNeedMoreItems")
    end
end

function XUiSignCard:OnBtnHelpRetroactiveClick()
    XUiManager.UiFubenDialogTip(
        CS.XTextManager.GetText("PurchaseYKRetroactiveHelpTitle"),
        CS.XTextManager.GetText("PurchaseYKRetroactiveHelpContent"),
        nil,
        nil)
end

return XUiSignCard
