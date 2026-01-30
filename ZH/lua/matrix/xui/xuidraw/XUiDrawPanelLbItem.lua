---@class XUiDrawPanelLbItem
local XUiDrawPanelLbItem = XClass(XUiNode, "XUiDrawPanelLbItem")
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}

function XUiDrawPanelLbItem:OnStart()
    self.OpenBuyTipsList = {}
    self.TimeFuns = {}
    self.TimeSaveFuns = {}
    self.CheckBuyFun = function(count, disCountCouponIndex) return self:CheckBuy(count, disCountCouponIndex) end
    self.BeforeBuyReqFun = function(successCb) self:CheckIsOpenBuyTips(successCb) end
    self.UpdateCb = function(rewardList) self:OnBuyFinish(rewardList) end
    self.Btn.CallBack = function ()
        self:OnBtnClick()
    end
end

--region 购买相关逻辑
function XUiDrawPanelLbItem:OnBtnClick()
    XDataCenter.PurchaseManager.OpenPurchaseBuyUiByClientInfo(self.ItemData, self.CheckBuyFun, self.UpdateCb, self.BeforeBuyReqFun, XPurchaseConfigs.GetLBUiTypesList())
end

function XUiDrawPanelLbItem:CheckBuy(count, disCountCouponIndex)
    count = count or 1
    disCountCouponIndex = disCountCouponIndex or 0

    if self.ItemData.BuyLimitTimes > 0 and self.ItemData.BuyTimes == self.ItemData.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return 0
    end

    if self.ItemData.TimeToShelve > 0 and self.ItemData.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return 0
    end

    if self.ItemData.TimeToUnShelve > 0 and self.ItemData.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end

    if self.ItemData.TimeToInvalid > 0 and self.ItemData.TimeToInvalid < XTime.GetServerNowTimestamp() then --失效了
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end

    if self.ItemData.ConsumeCount > 0 and self.ItemData.ConvertSwitch <= 0 then -- 礼包内容全部拥有
        XUiManager.TipText("PurchaseRewardAllHaveErrorTips")
        return 0
    end

    local consumeCount = self.ItemData.ConsumeCount
    if disCountCouponIndex and disCountCouponIndex ~= 0 then
        local disCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.ItemData, disCountCouponIndex)
        consumeCount = math.floor(disCountValue * consumeCount)
    else
        if self.ItemData.ConvertSwitch and consumeCount > self.ItemData.ConvertSwitch then -- 已经被服务器计算了抵扣和折扣后的钱
            consumeCount = self.ItemData.ConvertSwitch
        end

        if XPurchaseConfigs.GetTagType(self.ItemData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 计算打折后的钱(普通打折或者选择了打折券)
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.ItemData)
            consumeCount = math.floor(disCountValue * consumeCount)
        end
    end
    
    consumeCount = count * consumeCount -- 全部数量的总价
    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(self.ItemData.ConsumeId) then --钱不够
        -- local name = XDataCenter.ItemManager.GetItemName(self.ItemData.ConsumeId) or ""
        -- local tips = CSXTextManagerGetText("PurchaseBuyKaCountTips", name)
        local tips = XUiHelper.GetCountNotEnoughTips(self.ItemData.ConsumeId)
        local payCount = consumeCount - XDataCenter.ItemManager.GetCount(self.ItemData.ConsumeId)
        XUiManager.TipMsg(tips,XUiManager.UiTipType.Wrong)
        if self.ItemData.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            self:PurchaseLBCb(XPurchaseConfigs.TabsConfig.HK)
        elseif self.ItemData.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            self:PurchaseLBCb(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
            return 3
        end
        return 0
    end

    return 1
end

function XUiDrawPanelLbItem:PurchaseLBCb(skipIndex, leftTabIndex, payCount)
    if skipIndex == XPurchaseConfigs.TabsConfig.Pay and XHeroSdkManager.IsPayEnable() then
        if payCount then
            XLuaUiManager.Open("UiPurchaseQuickBuy", payCount, function ()
                XLuaUiManager.PopThenOpen("UiPurchase", skipIndex)
            end)
        else
            XLuaUiManager.Open("UiPurchase", skipIndex)
        end
    else 
        XLuaUiManager.Open("UiPurchase", skipIndex)
    end
end

function XUiDrawPanelLbItem:CheckIsOpenBuyTips(successCb)
    if self.ItemData.ConvertSwitch and self.ItemData.ConsumeCount > self.ItemData.ConvertSwitch then -- 礼包被计算拥有物品折扣价后，拥有物品不会下发，所以无需二次提示转化碎片
        if successCb then successCb() end
        return
    end

    local rewardGoodsList = self.ItemData.RewardGoodsList
    if not rewardGoodsList then
        if successCb then successCb() end
        return
    end

    for _, v in pairs(rewardGoodsList) do
        if XRewardManager.IsRewardWeaponFashion(v.RewardType, v.TemplateId) then
            local isHave, ownRewardIsLimitTime, rewardIsLimitTime, leftTime = XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId)
            if isHave then
                if not ownRewardIsLimitTime or not rewardIsLimitTime then
                    local tipContent = {}
                    tipContent["title"] = CSXTextManagerGetText("WeaponFashionConverseTitle")
                    if ownRewardIsLimitTime and not rewardIsLimitTime then          --自己拥有的武器涂装是限时的去买永久的
                        local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                        tipContent["content"] = #rewardGoodsList > 1 and CSXTextManagerGetText("OwnLimitBuyForeverWeaponFashionGiftConverseText", timeText) or CSXTextManagerGetText("OwnLimitBuyForeverWeaponFashionConverseText", timeText)
                    elseif not ownRewardIsLimitTime and rewardIsLimitTime then      --自己拥有的武器涂装是永久的去买限时的
                        tipContent["content"] = CSXTextManagerGetText("OwnForeverBuyLimitWeaponFashionConverseText")
                    elseif not ownRewardIsLimitTime and not rewardIsLimitTime then  --自己拥有的武器涂装是永久的去买永久的
                        tipContent["content"] = CSXTextManagerGetText("OwnForeverBuyForeverWeaponFashionConverseText")
                    end
                    table.insert(self.OpenBuyTipsList, tipContent)
                else
                    --自己拥有的武器涂装是限时的去买限时的
                    self.IsCheckOpenAddTimeTips = true
                end
            end
        end
    end

    if #self.OpenBuyTipsList > 0 then
        self:OpenBuyTips(successCb)
        return
    end

    if successCb then successCb() end
end

function XUiDrawPanelLbItem:OnBuyFinish()
    self:Refresh(self.DrawInfo)
end

--endregion

--region 刷新
function XUiDrawPanelLbItem:Refresh(drawInfo)
    if not drawInfo then
        return
    end
    self.DrawInfo = drawInfo

    local exIds = drawInfo.ExPurchaseIds
    local isEmpty = XTool.IsTableEmpty(exIds)
    local targetShowExData = nil
    if isEmpty then
        self:Close()
    else
        for i, exId in ipairs(exIds) do
            local data = XDataCenter.PurchaseManager.GetPurchaseInfoDataById(exId)
            local nowTime = XTime.GetServerNowTimestamp()
            if data and not (data.TimeToUnShelve > 0 and data.TimeToUnShelve <= nowTime) then -- 没下架
                targetShowExData = data
                self.ItemData = targetShowExData
                break
            end
        end

        if targetShowExData then
            self:Open()
            self:RefreshUiShow()
        else
            self:Close()
        end
    end
end

function XUiDrawPanelLbItem:RefreshUiShow()
    if not self.ItemData then
        return
    end

   self:SetData()
   self:StartLBTimer()
end

function XUiDrawPanelLbItem:SetData()
    if self.ItemData.Icon then
        local iconPath = XPurchaseConfigs.GetIconPathByIconName(self.ItemData.Icon)
        if iconPath and iconPath.AssetPath then
            self.ImgIconLb:SetRawImage(iconPath.AssetPath, function() self.ImgIconLb:SetNativeSize() end)
        end
    end
    self.TxtName.text = self.ItemData.Name
    if self.ImgHave then
        self.ImgHave.gameObject:SetActive(false)
    end
    self:ActiveImgTimeBg(false)
    self:RemoveTimerFun(self.ItemData.Id)
    self.RemainTime = 0
    local nowTime = XTime.GetServerNowTimestamp()

    self.IsDisCount = false
    local tag = self.ItemData.Tag
    local isShowTag = false
    if tag > 0 then
        isShowTag = true
        local path = XPurchaseConfigs.GetTagBgPath(tag)
        if path then
           self.Parent:SetUiSprite(self.ImgTagBg, path)
        end
        local tagText = XPurchaseConfigs.GetTagDes(tag)
        
        if XPurchaseConfigs.GetTagType(tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.ItemData)
            if disCountValue < 1 then
                local disCountStr = string.format("%.1f", disCountValue * 10)
                if self.ItemData.DiscountShowStr and self.ItemData.DiscountShowStr ~= "" then
                    disCountStr = self.ItemData.DiscountShowStr
                end
                tagText = disCountStr..tagText
                self.IsDisCount = true
            else
                isShowTag = false
            end
        end
        self.TxtTagDes.text = tagText
    else
        isShowTag = false
    end
    self.PanelLabel.gameObject:SetActive(isShowTag)

    local consumeCount = self.ItemData.ConsumeCount or 0
    -- self.RedPoint.gameObject:SetActive(false)
    if consumeCount == 0 then -- 免费的
        self.TxtHk.gameObject:SetActive(false)
        -- self.TxtHk2.gameObject:SetActiveEx(false)
        local isShowRedPoint = (self.ItemData.BuyTimes == 0 or self.ItemData.BuyTimes < self.ItemData.BuyLimitTimes) and not XDataCenter.PurchaseManager.IsLBLock(self.ItemData)
        and (self.ItemData.TimeToShelve == 0 or self.ItemData.TimeToShelve < nowTime)
        and (self.ItemData.TimeToUnShelve == 0 or self.ItemData.TimeToUnShelve > nowTime) 
        and not XDataCenter.PurchaseManager.IsLBLock(self.ItemData)
        -- self.RedPoint.gameObject:SetActive(isShowRedPoint)
    elseif self.IsDisCount or self.ItemData.ConvertSwitch < consumeCount then -- 打折或者存在拥有物品折扣的
        self.TxtHk.gameObject:SetActive(false)
        local path = XDataCenter.ItemManager.GetItemIcon(self.ItemData.ConsumeId)
        if path then
            self.RawConsumeImage2:SetRawImage(path)
        end
        if self.ItemData.ConvertSwitch <= 0 then
            -- self.TxtHk2.gameObject:SetActiveEx(false)
        else
            -- self.TxtHk2.gameObject:SetActiveEx(true)
            local consumeNum = consumeCount
            if self.ItemData.ConvertSwitch > 0 and self.ItemData.ConvertSwitch < consumeCount then
                consumeNum = self.ItemData.ConvertSwitch
            end
            if self.IsDisCount then
                local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.ItemData)
                consumeNum = math.modf(disCountValue * consumeNum) or ""
            end
            -- self.TxtHk2.text = consumeNum
        end
        self.TxtPrice.text = self.ItemData.ConsumeCount or ""
    else
        -- self.TxtHk2.gameObject:SetActiveEx(false)
        self.TxtHk.gameObject:SetActive(true)
        local path = XDataCenter.ItemManager.GetItemIcon(self.ItemData.ConsumeId)
        if path then
            self.RawConsumeImage:SetRawImage(path)
        end
        self.TxtHk.text = self.ItemData.ConsumeCount or ""
    end

    -- 达到限购次数
    if self.ItemData.BuyLimitTimes and self.ItemData.BuyLimitTimes > 0 and self.ItemData.BuyTimes == self.ItemData.BuyLimitTimes then
        -- self.ImgSellout.gameObject:SetActive(true)
        self:Close()
        -- self.TxtSetOut.text = XUiHelper.GetText("PurchaseSettOut")
        self.TxtHk.gameObject:SetActive(false)
        self:SetBuyDes()
        return
    end

    --是否已拥有
    local isShowHave = false
    if self.ImgHave then
        isShowHave = XDataCenter.PurchaseManager.IsLBHave(self.ItemData)
        self.ImgHave.gameObject:SetActive(isShowHave)
    end
    
    --是否锁定(如果显示了已拥有，则不需要显示锁定）
    if self.ImgLock and (not self.ImgHave or not isShowHave)then
        local isLock, lockDesc = XDataCenter.PurchaseManager.IsLBLock(self.ItemData)
        self.ImgLock.gameObject:SetActiveEx(isLock)
        self.TxtLock.text = lockDesc or ''
    end

    -- 上架时间
    if self.ItemData.TimeToShelve > 0 and nowTime < self.ItemData.TimeToShelve then
        self.RemainTime = self.ItemData.TimeToShelve - XTime.GetServerNowTimestamp()
        if self.RemainTime > 0 then--大于0，注册。
            self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
            self:RegisterTimerFun(self.ItemData.Id, function() self:UpdateTimer() end)
        else
            self:RemoveTimerFun(self.ItemData.Id)
        end
        self.TxtHk.gameObject:SetActive(false)
        self:SetBuyDes()
        return
    end
    
    self:SetBuyDes()

    --有失效时间只显示失效时间。
    -- 失效时间
    if self.ItemData.TimeToInvalid and self.ItemData.TimeToInvalid > 0 then
        self.RemainTime = self.ItemData.TimeToInvalid - XTime.GetServerNowTimestamp()
        if self.RemainTime > 0 then--大于0，注册。
            self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
            self:RegisterTimerFun(self.ItemData.Id, self.TimerUpdateCb)
            self:ActiveImgTimeBg(true)
            if self.IsDisCount then
            else
            end
        else
            self:RemoveTimerFun(self.ItemData.Id)
            self:ActiveImgTimeBg(false)
            -- self.ImgSellout.gameObject:SetActive(true)
            self:Close()
            -- self.TxtSetOut.text = XUiHelper.GetText("PurchaseLBSettOff")
        end
        return
    end

    -- 下架时间
    if self.ItemData.TimeToUnShelve > 0 then
        if nowTime < self.ItemData.TimeToUnShelve then
            self.RemainTime = self.ItemData.TimeToUnShelve - XTime.GetServerNowTimestamp()
            if self.RemainTime > 0 then--大于0，注册。
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                self:RegisterTimerFun(self.ItemData.Id, self.TimerUpdateCb)
                self:ActiveImgTimeBg(true)
            else
                self:RemoveTimerFun(self.ItemData.Id)
                self:ActiveImgTimeBg(false)
            end
        else
            -- self.ImgSellout.gameObject:SetActive(true)
            self:Close()
            self:ActiveImgTimeBg(false)
            -- self.TxtSetOut.text = XUiHelper.GetText("PurchaseLBSettOff")
        end
    else
        self:ActiveImgTimeBg(false)
    end
end

function XUiDrawPanelLbItem:SetBuyDes()
    local clientResetInfo = self.ItemData.ClientResetInfo or {}
    if next(clientResetInfo) == nil then
        return
    end

    local textKey = ""
    if clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Interval then
        return
    elseif clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Day then
        textKey = "PurchaseRestTypeDay"
    elseif clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Week then
        textKey = "PurchaseRestTypeWeek"
    elseif clientResetInfo.ResetType == XPurchaseConfigs.RestTypeConfig.Month then
        textKey = "PurchaseRestTypeMonth"
    end
end

-- 更新倒计时
function XUiDrawPanelLbItem:UpdateTimer(isRecover, id)
    if self.ItemData.TimeToInvalid == 0 and self.ItemData.TimeToUnShelve == 0 and self.ItemData.TimeToShelve == 0 then
        return
    end

    if self.ItemData.Id ~= id then
        return
    end

    if isRecover then
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            if self.ItemData.TimeToInvalid > 0 then
                self.RemainTime = self.ItemData.TimeToInvalid - XTime.GetServerNowTimestamp()
            else
                self.RemainTime = self.ItemData.TimeToUnShelve - XTime.GetServerNowTimestamp()
            end
        else
            self.RemainTime = self.ItemData.TimeToShelve - XTime.GetServerNowTimestamp()
        end
    else
        self.RemainTime = self.RemainTime - 1
    end

    if self.RemainTime <= 0 then
        self:RemoveTimerFun(self.ItemData.Id)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            -- self.ImgSellout.gameObject:SetActive(true)
            self:Close()
            self:ActiveImgTimeBg(false)
            -- self.TxtSetOut.text = XUiHelper.GetText("PurchaseLBSettOff")
            return
        end

        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        self:ActiveImgTimeBg(true)
        return
    end
end

function XUiDrawPanelLbItem:ActiveImgTimeBg(value)
    if XTool.UObjIsNil(self.ImgTimeBg) then
        return
    end
    self.ImgTimeBg.gameObject:SetActiveEx(value)
end

local CurrentSchedule = nil
-- 计时器相关
function XUiDrawPanelLbItem:StartLBTimer()
    if self.IsStart then
        return
    end

    self.IsStart = true
    CurrentSchedule = XScheduleManager.ScheduleForever(function() self:UpdateLBTimer()end, 1000)
end

function XUiDrawPanelLbItem:UpdateLBTimer()
    if next(self.TimeFuns) then
        for _,timerFun in pairs(self.TimeFuns)do
            if timerFun then
                timerFun()
            end
        end
        return
    end
    self:DestroyTimer()
end

function XUiDrawPanelLbItem:RemoveTimerFun(id)
    if id and self.TimeFuns[id] then
        self.TimeFuns[id] = nil
    end
end

function XUiDrawPanelLbItem:RecoverTimerFun(id)
    if self.TimeFuns[id] then
        self.TimeFuns[id](true)
    end
end

function XUiDrawPanelLbItem:RegisterTimerFun(id, fun)
    self.TimeFuns[id] = fun
end

function XUiDrawPanelLbItem:DestroyTimer()
    if CurrentSchedule then
        self.IsStart = false
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end
end
--endregion

return XUiDrawPanelLbItem