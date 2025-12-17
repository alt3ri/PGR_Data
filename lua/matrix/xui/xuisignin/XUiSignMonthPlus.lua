---@class XUiSignMonthPlus : XUiNode 月卡Plus
local XUiSignMonthPlus = XClass(XUiNode, "XUiSignMonthPlus")

function XUiSignMonthPlus:OnStart()
    if self.BtnBuy then
        self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
    end
    if self.BtnTanchuangCloseWhite then
        self.BtnTanchuangCloseWhite.CallBack = handler(self.Parent, self.Parent.Close)
    end
    if self.BtnHelp then
        self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    end
end

function XUiSignMonthPlus:Refresh(purchaseData, buyCallBack)
    self._Cb = buyCallBack
    
    if self.Parent.RefreshBuyButtonStatus then
        self.Parent:RefreshBuyButtonStatus(true)
    end
    
    if purchaseData.BuyLimitTimes > 0 and purchaseData.BuyTimes == purchaseData.BuyLimitTimes then
        self.BtnBuy:SetButtonState(CS.UiButtonState.Disable)
        self.IsSellOut = true
    end
    
    self.BtnBuy:SetNameByGroup(0, purchaseData.ConsumeCount)
    
    self._PurchaseData = purchaseData
    self:RefreshRewardData()

    if self.TxtNum then
        self.TxtNum.text = CS.XGame.ClientConfig:GetInt('MonthCardTotalPrice')
    end
end

function XUiSignMonthPlus:RefreshRewardData()
    if not XTool.IsTableEmpty(self._PurchaseData.RewardGoodsList) then
        for i, v in pairs(self._PurchaseData.RewardGoodsList) do
            local btn = self['BtnGift0' .. i]

            if btn then
                btn:SetNameByGroup(0, XUiHelper.GetText('PayQuickBuyNumber', v.Count))
                btn:SetRawImage(XGoodsCommonManager.GetGoodsIcon(v.TemplateId))
                btn:AddEventListener(function()
                    XLuaUiManager.Open("UiTip", v, true, self.Parent and self.Parent.Name)
                end, true)
                
                btn:ShowTag(self.IsSellOut)
            end
        end
    end
end

function XUiSignMonthPlus:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("PurchaseMonthPlusDesc"))
end

function XUiSignMonthPlus:OnBtnBuyClick()
    if self.IsSellOut then
        return
    end
    
    if self._Cb then
        self._Cb()
    end
end

return XUiSignMonthPlus