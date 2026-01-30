---@class XUiGridPurchaseThreeDay
---@field Parent XUiPanelRecommendThreeDay
local XUiGridPurchaseThreeDay = XClass(nil, "XUiGridPurchaseThreeDay")

function XUiGridPurchaseThreeDay:Ctor(ui, parent)
    ---@type UnityEngine.GameObject
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)

    self.BtnGift.CallBack = handler(self, self.OnBtnGiftClick)
end

function XUiGridPurchaseThreeDay:Update()
    self:UpdateData(self.Id, self.Reward, self.IsPurchaseEnter, self.IsShow, self.Index)
end

---@param purchase XPurchasePackage
function XUiGridPurchaseThreeDay:UpdateData(id, reward, isPurchaseEnter, isShow, index, isBuyPurchase)
    self.Id = id
    self.Reward = reward
    self.IsPurchaseEnter = isPurchaseEnter
    self.IsShow = isShow
    self.Index = index
    self.WeekData = XDataCenter.PurchaseManager.GetWeekCardData(id)

    local isBatter = self.Parent.BetterIndexDic[index]
    local isToday, isGain, isExpired
    if self.WeekData then
        isToday = index == self.WeekData:GetCurRoundDay()
        isGain = self.WeekData:CheckIsGotByRoundAndDay(1, index)
        isExpired = self.WeekData:CheckIsPreviousDay(1, index)
    else
        -- 三日礼包不会过期，没有数据显示已结束
        if isPurchaseEnter then
            if self.ImgEnd then
                self.ImgEnd.gameObject:SetActiveEx(isBuyPurchase)
            end
        end
    end

    --大奖
    self.RImgBgHighlight.gameObject:SetActiveEx(isBatter)
    -- 已领取和已过期不能同时有，优先已领取
    --已领取
    self.ImgGot.gameObject:SetActiveEx(isGain)
    --已过期：从礼包中打开
    if self.ImgMask then
        -- 通用逻辑是前天或当天的奖励都属于之前的奖励
        if isExpired then
            -- 如果是当天的奖励，且没有领取，则不属于过期范畴
            if isToday and not isGain then
                isExpired = false
            end
        end
        self.ImgMask.gameObject:SetActiveEx(isExpired and not isGain)
    end

    if reward then
        self.TemplateId = reward.TemplateId
        self.BtnGift:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.TemplateId))
        self.BtnGift:SetNameByGroup(0, XUiHelper.GetText('PayQuickBuyNumber', reward.Count))
    end

    if not isPurchaseEnter and not reward then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    -- 如果是礼包打开详情，或不属于当天的奖励，则不进行后续领取的逻辑
    if self.IsPurchaseEnter or not isToday then
        return
    end

    if isToday and isGain then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    --登录时领取奖励
    self:GetThreeDayCardReward()
end

function XUiGridPurchaseThreeDay:OnBtnGiftClick()
    if self.TemplateId then
        XLuaUiManager.Open("UiTip", self.TemplateId)
    end
end

function XUiGridPurchaseThreeDay:GetThreeDayCardReward()
    XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(self.WeekData:GetId(), function(rewards)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        RunAsyn(function()
            asynWaitSecond(0.7)
            self:HandlerReward(rewards)
            self.WeekData:SetWeekCardGotToday()
            self:Update()
            XEventManager.DispatchEvent(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN)
        end)
    end)
end

function XUiGridPurchaseThreeDay:HandlerReward(rewardItems)
    if rewardItems and #rewardItems > 0 then
        self:SetReward(rewardItems)
    else
        self:SetNoReward()
    end
end

function XUiGridPurchaseThreeDay:SetReward(rewardItems)
    --self.GameObject:PlayTimelineAnimation(function() 暂无动画
    --    XUiManager.OpenUiObtain(rewardItems)
    --    self:SetEffectActive(false)
    --    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
    --end, function()
    --    self:SetEffectActive(true)
    --end)
    XUiManager.OpenUiObtain(rewardItems)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiGridPurchaseThreeDay:SetNoReward()
    self:SetEffectActive(false)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiGridPurchaseThreeDay:SetEffectActive(active)

end

return XUiGridPurchaseThreeDay
