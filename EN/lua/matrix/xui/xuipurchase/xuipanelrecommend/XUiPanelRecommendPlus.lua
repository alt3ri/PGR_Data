---@class XUiPanelRecommendPlus 月卡Plus
local XUiPanelRecommendPlus = XClass(nil, "XUiPanelRecommendPlus")

function XUiPanelRecommendPlus:Ctor(ui, parent)
    ---@type UnityEngine.GameObject
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    self.RootUi = parent
    XTool.InitUiObject(self)

    if self.BtnBuy then
        self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
    end

    if self.BtnHelp then
        self.BtnHelp.CallBack = handler(self, self.OnBtnHelpClick)
    end
end

---@param data
function XUiPanelRecommendPlus:Refresh(signId, data)
    self.SignId = signId
    self.Data = data

    if self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes then
        self.IsSellOut = true
    end

    if self.RootUi and self.RootUi.RefreshBuyButtonStatus then
        self.RootUi:RefreshBuyButtonStatus(true)
    end
    
    if not XTool.IsTableEmpty(self.Data.RewardGoodsList) then
        for i, v in ipairs(self.Data.RewardGoodsList) do
            local btn = self['BtnGift' .. i]

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

    if self.TxtNum then
        self.TxtNum.text = CS.XGame.ClientConfig:GetInt('MonthCardTotalPrice')
    end
end

function XUiPanelRecommendPlus:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("PurchaseMonthPlusDesc"))
end

function XUiPanelRecommendPlus:OnBtnBuyClick()
    self.RootUi:OnBtnBuyClick() --self.RootUi is XUiPurchaseBuyTips
end

return XUiPanelRecommendPlus