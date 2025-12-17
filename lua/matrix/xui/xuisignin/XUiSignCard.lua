local XUiSignCard = XClass(nil, "XUiSignCard")

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
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.Refresh, self)
end

function XUiSignCard:OnShow()
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.Refresh, self)
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
                XUiManager.OpenUiObtain(rewardItems)

                -- 设置月卡信息本地缓存
                XDataCenter.PurchaseManager.SetYKLocalCache()
                XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
            end)
        end
    end)
end

function XUiSignCard:Refresh(configId, isShow, isAuto)
    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        if not configId then
            configId = self.ConfigId
        end
        self.ConfigId = configId

        self.PanelBuy.gameObject:SetActive(false)
        self.PanelGet.gameObject:SetActive(false)

        self.Config = XSignInConfigs.GetSignCardConfig(configId)
        local data = XDataCenter.PurchaseManager.GetYKInfoData()
        local isBuy = data ~= nil and data.Id == self.Config.Param[2] and data.DailyRewardRemainDay > 0
        if isBuy then
            self:RefreshGet()
            self:AutoGetReward(isAuto)
        else
            self:RefreshBuy()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
    end)
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
    self.BtnContinue.gameObject:SetActive(data.DailyRewardRemainDay < self.Config.CanBuyDay)
    if data.IsDailyRewardGet then
        self.BtnGet:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnGet:SetButtonState(CS.UiButtonState.Normal)
    end

    self.PanelGet.gameObject:SetActive(true)
end

return XUiSignCard