---@class XUiSignThreeDay : XUiNode 新手三日限定补给
local XUiSignThreeDay = XClass(XUiNode, "XUiSignThreeDay")

function XUiSignThreeDay:OnStart()
    if self.BtnBuy then
        self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
    end
    if self.BtnSkipToPlus then
        XUiHelper.RegisterClickEvent(self, self.BtnSkipToPlus, self.OnBtnSkipToPlusClick)
    end
    if self.BtnTanchuangCloseWhite then
        self.BtnTanchuangCloseWhite.CallBack = handler(self.Parent, self.Parent.Close)
    end

    if self.BtnHelp then
        self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    end

    if self.BtnHelpMonthPlus then
        self.BtnHelpMonthPlus.CallBack = handler(self, self.OnBtnHelpMonthPlusClick)
    end
    
    ---@type XUiGridPurchaseThreeDay[]
    self.Grids = {}
    self.SkipId = CS.XGame.ClientConfig:GetInt("MonthCardPlusSkipId")
    self.MonthCardPlusIsShowCondition = CS.XGame.ClientConfig:GetInt('MonthCardPlusIsShowCondition')
    self.MonthCardPlusPackId = CS.XGame.ClientConfig:GetInt('MonthCardPlusPackId')
end

function XUiSignThreeDay:OnGetLuaEvents()
    return {
        XEventId.EVENT_SING_IN_WEEK_CARD_GOT
    }
end

function XUiSignThreeDay:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SING_IN_WEEK_CARD_GOT then
        self:RefreshPanelComplete(true)
    end
end

---@param isShow boolean 只显示三日时为false，需要显示月卡plus时为true
function XUiSignThreeDay:Refresh(signId, isShow, data)
    self.IsShow = isShow

    if self.IsShow then
        if XTool.IsNumberValidEx(self.MonthCardPlusIsShowCondition) and not XConditionManager.CheckCondition(self.MonthCardPlusIsShowCondition) then
            self.IsShow = false
        end
    end
    
    self.SignId = signId
    self.IsPurchaseEnter = data ~= nil
    self.Purchase = XDataCenter.PurchaseManager.GetPurchasePackageBySignId(signId)
    self.PurchaseData = self.Purchase:GetRawData()
    self.BetterIndexDic = {}

    self.BetterIndexDic = {}
    if self.PurchaseData and self.PurchaseData.PurchaseSignInInfo then
        local batterIndexStr = self.PurchaseData.PurchaseSignInInfo.BetterIndexStr
        if not string.IsNilOrEmpty(batterIndexStr) then
            local betterIndexList = string.Split(batterIndexStr, "|")
            for _, index in ipairs(betterIndexList) do
                self.BetterIndexDic[tonumber(index)] = true
            end
        end
    end

    if self.IsPurchaseEnter then
        self:RefreshByPurchasePackageData()
    else
        self:RefreshBySignIn()
    end
    
    if self.PanelCard then
        self.PanelCard.gameObject:SetActiveEx(self.IsShow)
    end
    if self.PanelCardGain then
        self.PanelCardGain.gameObject:SetActiveEx(not self.IsShow)
    end

    if self.Bg3 then
        self.Bg3.gameObject:SetActiveEx(not self.IsShow)
    end

    if self.BtnSkipToPlus then
        self.BtnSkipToPlus.gameObject:SetActiveEx(self.IsShow)
    end

    if self.Parent.RefreshBuyButtonStatus then
        self.Parent:RefreshBuyButtonStatus(true)
    end
end

function XUiSignThreeDay:RefreshByPurchasePackageData()
    if self.BtnBuy then
        self.BtnBuy.gameObject:SetActiveEx(true)
        local icon = XDataCenter.ItemManager.GetItemIcon(self.PurchaseData.ConsumeId)
        if icon then
            self.BtnBuy:SetRawImage(icon)
        end
        self.BtnBuy:SetName(self.PurchaseData.ConsumeCount)
        if self.PurchaseData.BuyTimes < self.PurchaseData.BuyLimitTimes then
            self.BtnBuy:SetDisable(false)
        else
            self.BtnBuy:SetDisable(true)
        end
    end
    self.TxtTips.text = self.PurchaseData.Desc
    self.IsSellOut = self.PurchaseData.BuyLimitTimes > 0 and self.PurchaseData.BuyTimes == self.PurchaseData.BuyLimitTimes
    self:SetRewardInfos()
end

function XUiSignThreeDay:RefreshBySignIn()
    self.WeekCardData = XDataCenter.PurchaseManager.GetWeekCardDataBySignInId(self.SignId)
    if not self.WeekCardData then
        return
    end
    if self.BtnBuy then
        self.BtnBuy.gameObject:SetActiveEx(false)
    end
    self.TxtTips.text = self.WeekCardData:GetDesc()
    self:SetRewardInfos()
    self:RefreshPanelComplete()

    if self.IsShow then
        self:SetMonthPlusRewardInfos()

        if self.TxtNum then
            self.TxtNum.text = CS.XGame.ClientConfig:GetString('MonthCardTotalPrice2')
        end
    end
end

function XUiSignThreeDay:SetRewardInfos()
    local rewardInfos = self.IsPurchaseEnter and self.PurchaseData.PurchaseSignInInfo.PurchaseSignInRewardInfos or self.WeekCardData:GetRewardInfos()
    for index, rewardInfo in ipairs(rewardInfos) do
        local rewardList = XRewardManager.GetRewardList(rewardInfo)
        local reward = rewardList[1]
        local grid = self.Grids[index]
        if not grid then
            local go = self[string.format("PanelGift%s", index)]
            grid = require("XUi/XUiPurchase/Grid/XUiGridPurchaseThreeDay").New(go, self)
            self.Grids[index] = grid
        end
        grid:UpdateData(self.Purchase:GetId(), reward, self.IsPurchaseEnter, self.IsShow, index, self.IsSellOut)
    end
end

function XUiSignThreeDay:SetMonthPlusRewardInfos()
    if XTool.IsNumberValidEx(self.MonthCardPlusPackId) then
        local packData = XDataCenter.PurchaseManager.GetPurchasePackageById(self.MonthCardPlusPackId)
        
        if packData then
            packData = packData:GetRawData()
            
            if not XTool.IsTableEmpty(packData.RewardGoodsList) then
                for i, v in ipairs(packData.RewardGoodsList) do
                    local btn = self['BtnGift0' .. i]

                    if btn then
                        btn:SetNameByGroup(0, XUiHelper.GetText('PayQuickBuyNumber', v.Count))
                        btn:SetRawImage(XGoodsCommonManager.GetGoodsIcon(v.TemplateId))
                        btn:AddEventListener(function()
                            XLuaUiManager.Open("UiTip", v, true, self.Parent and self.Parent.Name)
                        end, true)
                    end
                end
            end
        end
    end
end

function XUiSignThreeDay:OnBtnHelpClick()
    local sigInCfg = XSignInConfigs.GetSignInConfig(self.SignId)
    local subRoundCfg = XSignInConfigs.GetSubRoundConfig(sigInCfg.SubRoundId[1])
    XUiManager.UiFubenDialogTip("", subRoundCfg.SubRoundDesc or "")
end

function XUiSignThreeDay:OnBtnHelpMonthPlusClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("PurchaseMonthPlusDesc"))
end

function XUiSignThreeDay:OnBtnBuyClick()
    if self.Parent.OnBtnBuyClick then
        self.Parent:OnBtnBuyClick()
    end
end

function XUiSignThreeDay:OnBtnSkipToPlusClick()
    if XTool.IsNumberValid(self.SkipId) then
        XLuaUiManager.Close('UiSignBanner')
        if XLuaUiManager.IsUiLoad('UiPurchase') then
            XLuaUiManager.Remove('UiPurchase')
        end
        XFunctionManager.SkipInterface(self.SkipId)
    end
end

function XUiSignThreeDay:RefreshPanelComplete(isGotReward)
    if not self.PanelComplete then
        return
    end
    if self.WeekCardData then
        local isGotToday = self.WeekCardData:GetIsGotToday()
        if isGotToday then
            self.PanelComplete.gameObject:SetActiveEx(true)
            if isGotReward then
                self.PanelCompleteEnable:PlayTimelineAnimation()
            end
        else
            self.PanelComplete.gameObject:SetActiveEx(false)
        end
    else
        self.PanelComplete.gameObject:SetActiveEx(false)
    end
end

return XUiSignThreeDay