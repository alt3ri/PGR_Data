local XUiPanelRecommendBase = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendBase")

---@class XUiPanelRecommendCompanyPackage : XUiPanelRecommendBase 新手三日限定补给+月卡Plus
local XUiPanelRecommendCompanyPackage = XClass(XUiPanelRecommendBase, "XUiPanelRecommendCompanyPackage")

function XUiPanelRecommendCompanyPackage:OnInit()

end

function XUiPanelRecommendCompanyPackage:SetUi(ui)
    XUiHelper.InitUiClass(self, ui)
    ---@type XUiPanelRecommendThreeDay
    self._ThreeDay = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendThreeDay").New(self.PanelDetailLB, self)
    ---@type XUiPanelRecommendPlus
    self._Plus = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendPlus").New(self.PanelDetailYK, self)
end

function XUiPanelRecommendCompanyPackage:SetData(data, skipFunc, buyFinished)
    ---@type XPurchaseRecommend
    self.Recommend = data
    self.SkipFunc = skipFunc
    self.BuyFinished = buyFinished

    local isHavePackageId = XTool.IsNumberValid(#self.Recommend:GetPurchasePackageIdList())
    local allSellOut = true

    if isHavePackageId then
        for index, _ in ipairs(self.Recommend:GetPurchasePackageIdList()) do
            local package = self.Recommend:GetPurchasePackage()[index]
            local rawData = package:GetRawData()
            ---@type XUiComponent.XUiButton
            local btnBuy
            if index == 1 then
                self._ThreeDay:Refresh(rawData.PurchaseSignInInfo.PurchaseSignInShowId, rawData)
                btnBuy = self._ThreeDay.BtnBuyLB
            elseif index == 2 then
                local data = XDataCenter.PurchaseManager.GetPurchasePackageById(rawData.CompanyPackage)
                self._Plus:Refresh(data:GetId(), rawData)
                btnBuy = self._Plus.BtnBuyYK
            end

            if not btnBuy then
                break
            end

            if package == nil then
                -- 页签显示时间内但找不到礼包数据则不显示
                btnBuy.gameObject:SetActiveEx(false)
            else
                -- 设置礼包状态
                if package:GetIsHave() then
                    btnBuy:SetDisable(true)
                    self:ShowBuyBtnSoldOutOrOwned(btnBuy.transform, false)
                end
                if package:GetIsSellOut() then
                    btnBuy:SetDisable(true)
                    self:ShowBuyBtnSoldOutOrOwned(btnBuy.transform, true)
                else
                    allSellOut = false
                end
                -- 注册礼包购买
                btnBuy.CallBack = function()
                    if package:GetIsSellOut() then
                        XUiManager.TipErrorWithKey("PurchaseSettOut")
                        return
                    end
                    local buyData = self.Recommend:GetPurchasePackage()
                    if buyData then
                        self.PurchaseManager.OpenPurchaseBuyUiByPurchasePackage(package, function(_, payCount)
                            self.SkipFunc(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
                        end, nil, self.BuyFinished)
                    end
                end
            end
        end
    end

    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
end

return XUiPanelRecommendCompanyPackage