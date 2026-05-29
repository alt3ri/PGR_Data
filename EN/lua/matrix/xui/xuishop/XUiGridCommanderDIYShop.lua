local XUiGridFashionShop = require("XUi/XUiShop/XUiGridFashionShop")
local BuyCount = 1
local XUiGridCommanderDIYShop = XClass(XUiGridFashionShop, "XUiGridCommanderDIYShop")

function XUiGridCommanderDIYShop:UpdateData(data)
    self.Super.UpdateData(self, data)
    self:RefrshSuitState()
end

function XUiGridCommanderDIYShop:OnBtnBuyClick()
    if self.IsShopOnSaleLock then
        XUiManager.TipError(self.ShopOnSaleLockDecs)
        return
    end
    local buyData = {}
    buyData.CurRewardGoods = self.Data.RewardGoods
    buyData.IsHave = false
    buyData.ItemIcon = self.ItemIcon
    buyData.ItemCount = self.NeedCount
    -- 不是很清楚为什么基类不需要ConsumeList Index 1的Id，想改基类又感觉有点不妥，先强读吧
    buyData.ItemId = self.Data.ConsumeList[1].Id
    buyData.GiftRewardId = self.GiftRewardId
    if self.NeedCount ~= self.Data.ConsumeList[1].Count then
        buyData.OriginCount = self.Data.ConsumeList[1].Count
    end
    buyData.BuyCallBack = function()
        for _, consume in pairs(self.Data.ConsumeList) do
            if consume.Id == XDataCenter.ItemManager.ItemId.HongKa then
                local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, self.NeedCount)
                if not result then
                    XUiManager.TipText("ShopItemHongKaNotEnough")
                    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
                    return
                end
            elseif consume.Id == XDataCenter.ItemManager.ItemId.PaidGem then
                local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, self.NeedCount)
                if not result then
                    XUiManager.TipText("ShopItemPaidGemNotEnough")
                    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
                    return
                end
            end
        end

        XShopManager.BuyShop(self.Parent:GetCurShopId(), self.Data.Id, BuyCount, function(res)
            self:OnBuyShopSuccessCb(res.GoodList, res.IsShowBuyResult)
        end, function(errorCode)
            if errorCode == XCode.ShopActivityStatusInconsistent then -- 写死活动过期错误码
                XLuaUiManager.RunMain()
            end
        end, self.ActivityIsOpen)
    end
    buyData.GroupBuyCallBack = function(partId)
    end
    XMVCA.XShop:OpenCommanderDIYDetailUi(self.Data.RewardGoods.TemplateId, buyData, self.Data)
end

function XUiGridCommanderDIYShop:OnBuyShopSuccessCb(goodList, isShowBuyResult)
    local text = CS.XTextManager.GetText("BuySuccess")
    XUiManager.TipMsg(text, nil, function()
        if isShowBuyResult and not XTool.IsTableEmpty(goodList) then
            self:ShowFashionObtainPopup(goodList)
            return
        end
    end)
    if XTool.UObjIsNil(self.ImgSellOut) then
        return
    end
    self:RefreshSellOut()
    self:RefreshCondition()
    self:RefreshOnSales()
    self:RefreshPrice()
    self:RefreshBuyCount()
    self.Parent:RefreshBuy()
end

function XUiGridCommanderDIYShop:ShowFashionObtainPopup(goodList)
    if not CS.XFightInterface.IsOutFight then
        return -- 战斗不弹
    end

    -- 等待父级ui中列表异步刷新完成，以保证弹窗的截图效果正常
    if XUiManager.IsTableAsyncLoading() then
        XUiManager.WaitTableLoadComplete(function()
            XLuaUiManager.Open("UiShopFashionObtain", goodList)
        end)
    else
        XLuaUiManager.Open("UiShopFashionObtain", goodList)
    end
end

function XUiGridCommanderDIYShop:RefrshSuitState()
    local isSuit = XMVCA.XBigWorldCommanderDIY:GetPartIsSuit(self.Data.RewardGoods.TemplateId)
    self.PanelSuit.gameObject:SetActiveEx(isSuit)
end

return XUiGridCommanderDIYShop

