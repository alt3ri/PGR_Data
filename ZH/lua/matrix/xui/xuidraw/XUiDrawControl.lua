local XUiDrawControl = XClass(nil, "XUiDrawControl")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")

---@class XUiDrawControl
function XUiDrawControl:Ctor(rootUi, drawInfo, drawCb, uiDraw)
    self.RootUi = rootUi
    self.DrawInfo = drawInfo
    self.DrawCb = drawCb
    self.UiDraw = uiDraw
    self.IsCanDraw = true
    self._DrawTime = 0
    self:InitRes()
    self:InitButtons()
    return self
end

function XUiDrawControl:InitRes()
    self.UseItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.DrawInfo.UseItemId)
    self.TxtDrawCount = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, "TxtTotalDrawCount", "Text")
    self.DrawBtnNameDict = {
        [1] = { "BtnDraw1", "BtnDraw3" }, --普通单抽按钮、免费单抽按钮
        [2] = { "BtnDraw2", "BtnDraw4" }, --普通十抽按钮、免费十抽按钮
    }
end

function XUiDrawControl:InitButtons()
    ---@type DrawButtonView[]
    self.DrawBtnDict = {}
    for i, btns in pairs(self.DrawBtnNameDict) do
        ---@type DrawButtonView
        local btnView = {}
        local drawCount = self.DrawInfo.BtnDrawCount[i]

        --普通按钮
        btnView.Btn = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, btns[1], "XUiButton")
        if btnView.Btn then
            self:InitButton(btnView.Btn, drawCount)
        else
            XLog.Error(string.format("【卡池】%s抽按钮不存在：%s", tostring(drawCount), btns[1]))
        end

        --免费按钮
        btnView.FreeBtn = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, btns[2], "XUiButton")
        if btnView.FreeBtn then
            btnView.FreeBtn:AddEventListener(function()
                self:OnDraw(drawCount)
            end)
            btnView.FreeBtnTip = btnView.FreeBtn.transform:Find("Time/ImgBg/Txt"):GetComponent(typeof(CS.UnityEngine.UI.Text))
        else
            XLog.Error(string.format("【卡池】免费%s抽按钮不存在：%s", tostring(drawCount), btns[2]))
        end

        btnView.IsTenDraw = i == 2
        self.DrawBtnDict[i] = btnView
    end
    self:RefreshTenDrawDiscount()
end

function XUiDrawControl:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self:RefreshFreeTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshFreeTime()
    end, XScheduleManager.SECOND)
end

function XUiDrawControl:RefreshFreeTime()
    if XTool.UObjIsNil(self.RootUi.PanelDrawButtons) then
        self:StopTimer()
        return
    end

    local singleRunning = self:RefreshTicketTimeTip(false)
    local tenRunning = self:RefreshTicketTimeTip(true)
    if not singleRunning and not tenRunning then
        self:StopTimer()
    end
end

---@param isTenDraw boolean false刷新单抽券提示（BtnDraw3），true刷新十连券提示（BtnDraw4）
---@return boolean 是否还有需要倒计时的券
function XUiDrawControl:RefreshTicketTimeTip(isTenDraw)
    local index = isTenDraw and 2 or 1
    local tipText =  self.DrawBtnDict[index].FreeBtnTip
    if XTool.UObjIsNil(tipText) then
        return false
    end

    local ticketData = self.FreeTicketDataDict[index]
    local ticketInfo, hasNewInfo, newTicketId, exprireTime, count = XDataCenter.DrawManager.GetTicketInfoForExpireTimeDisplay(ticketData.FreeTicketIdForExpireTimeDisplay, self.GroupId, isTenDraw)

    if ticketInfo and ticketInfo.ExpireTime then
        exprireTime = ticketInfo.ExpireTime
    elseif hasNewInfo then
        ticketData.FreeTicketIdForExpireTimeDisplay = newTicketId
        ticketData.FreeTicketCountForDisplay = count
    end

    if exprireTime then
        local now = XTime.GetServerNowTimestamp()
        local offset = exprireTime - now
        if offset <= 0 then
            offset = 0
        end
        tipText.text = CS.XTextManager.GetText("DrawFreeTicketCoolDown", ticketData.FreeTicketCountForDisplay, XUiHelper.GetTime(offset))
        return true
    else
        tipText.text = ""
        return false
    end
end

function XUiDrawControl:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

---@param btn XUiComponent.XUiButton
function XUiDrawControl:InitButton(btn, drawCount)
    self:UpdateButton(btn, drawCount)
    self.RootUi:RegisterClickEvent(btn:GetComponent(typeof(CS.UnityEngine.UI.Button)), function()
        self:OnDraw(drawCount)
    end)
end

---@param btn XUiComponent.XUiButton
function XUiDrawControl:UpdateButton(btn, drawCount)
    local itemCount = XDataCenter.DrawManager.GetDiscountDrawPrice(self.DrawInfo.GroupId, self.DrawInfo.UseItemCount, drawCount)
    btn:SetNameByGroup(0, CS.XTextManager.GetText("DrawCount", drawCount))
    btn:SetNameByGroup(1, itemCount)
    btn:SetRawImage(self.UseItemIcon)
end

function XUiDrawControl:OnDraw(drawCount)
    local info
    local list

    if self.DrawInfo.CapacityCheckType == XDrawConfigs.DrawCapacityCheckType.Partner then
        if not XDataCenter.PartnerManager.CheckPartnerCount() then
            return
        end
    end

    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return
    end

    -- CD冷却
    local nowTime = CS.XTimerManager.Ticks / 10000000
    if nowTime - self._DrawTime < tonumber(XDrawConfigs.GetDrawClientConfig("DrawCD")) then
        return
    end
    self._DrawTime = nowTime

    if XDataCenter.DrawManager.CheckDrawIsTimeOver(self.DrawInfo.Id) then
        XUiManager.TipText("DrawAimLeftTimeOver")
        return
    end
    -- 单抽只能用单抽券，十连只能用十连券
    local ticketIsTen
    if drawCount == 1 then
        ticketIsTen = false
    elseif drawCount == 10 then
        ticketIsTen = true
    end
    local hasMatchFreeTicket = ticketIsTen ~= nil and XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId, ticketIsTen)
    if not hasMatchFreeTicket then
        local drawGroupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
        if not drawGroupInfo then
            XLog.Error("XUiDrawControl:OnDraw 获取不到卡池信息 GroupId:" .. self.GroupId)
            return
        end
        local groupUseDrawId = (drawGroupInfo.UseDrawIdDict or {})[0] or 0
        -- ExtraOption 时从 UseDrawIdDict 获取当前 option 的选中状态
        local currentOptionKey = self.RootUi and self.RootUi.CurrentOptionKey or ""
        if not string.IsNilOrEmpty(currentOptionKey) then
            local _, groupSubtype = XDataCenter.DrawManager._ParseOptionKey(currentOptionKey)
            if groupSubtype and groupSubtype > 0 then
                local dict = drawGroupInfo.UseDrawIdDict or {}
                groupUseDrawId = dict[groupSubtype] or 0
            end
        end
        local drawGroupRule = XDrawConfigs.GetDrawGroupRuleById(self.GroupId)
        local needItemCount = XDataCenter.DrawManager.GetDiscountDrawPrice(self.DrawInfo.GroupId, self.DrawInfo.UseItemCount, drawCount)

        if drawGroupRule and drawGroupRule.IsNotSelectDefault and not XTool.IsNumberValid(groupUseDrawId) then
            -- 有选择次数的卡池没选Up池
            if not XDataCenter.ItemManager.DoNotEnoughBuyAssetByNeedCount(self.DrawInfo.UseItemId, needItemCount, nil, "DrawNotEnoughError", true) then
                XUiManager.TipText("DrawNeedChooseCharTip")
                -- 没选择Up池研发券不足时先让玩家选择
                if self.RootUi.OnBtnOptionDrawClick then
                    self.RootUi:OnBtnOptionDrawClick()
                end
                return
            end
        else
            if not XDataCenter.ItemManager.DoNotEnoughBuyAssetByNeedCount(self.DrawInfo.UseItemId, needItemCount, nil, "DrawNotEnoughError") then
                return
            end
        end
    end
    if XDataCenter.DrawManager:CheckIsNewDraw(self.GroupId) then
        local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
        -- 判断当前 option 是否已选目标
        local hasSelected = groupInfo.SwitchDrawIdCount > 0
        local curOptionKey = self.RootUi and self.RootUi.CurrentOptionKey or ""
        if not string.IsNilOrEmpty(curOptionKey) then
            local _, subtype = XDataCenter.DrawManager._ParseOptionKey(curOptionKey)
            if subtype and subtype > 0 then
                local dict = groupInfo.UseDrawIdDict or {}
                hasSelected = XTool.IsNumberValid(dict[subtype])
            end
        end
        if not hasSelected then
            XUiManager.TipText("DrawNeedChooseCharTip")
            if self.RootUi and self.RootUi.OnBtnOptionDrawClick then
                self.RootUi:OnBtnOptionDrawClick()
            end
            return
        end
    end

    if self.IsCanDraw then
        self.IsCanDraw = false
        local onAnimFinish = function()
            if list and #list > 0 then
                self.IsCanDraw = true
                --self.UiDraw:PushShow(info, list)
            end
        end

        characterRecord.Record()
        local freeId = hasMatchFreeTicket and XDataCenter.DrawManager.GetFreeTicketIdByGroupId(self.GroupId, ticketIsTen) or 0
        if freeId ~= 0 then
            XLog.Debug("使用了免费券 免费券Id:", freeId)
            XLog.Debug("使用了免费券 DrawId:", self.DrawInfo.Id)
        end
        XDataCenter.DrawManager.DrawCard(self.DrawInfo.Id, drawCount, freeId, function(drawInfo, rewardList, extraRewardList)
            XDataCenter.AntiAddictionManager.BeginDrawCardAction()
            if self.DrawCb then
                self.DrawCb()
            end

            self:Update(drawInfo)
            info = drawInfo
            list = rewardList
            XLuaUiManager.OpenWithCallback("UiDrawNew", function()
                onAnimFinish()
            end, info, list)
            --self.UiDraw:SetExtraRewardList(extraRewardList)
            --self.UiDraw:HideUiView(onAnimFinish)
            self:SetDrawEvent(drawInfo,drawCount)
        end)
    end
end

function XUiDrawControl:SetDrawEvent(drawInfo, drawCount)
    if drawCount < 10 then
        return
    end
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawInfo.Id)
    if combination then
        if combination.Type == XDrawConfigs.CombinationsTypes.Aim then
            local aimType = combination.GoodsId[1]
            if aimType ~= nil then
                aimType = XArrangeConfigs.GetType(aimType)
            end
            if not aimType or aimType == XArrangeConfigs.Types.Character then
                --CheckPoint: APPEVENT_DRAWS_ROLE_10_1
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_role_10)
            else
                --CheckPoint: APPEVENT_DRAWS_WEAPON_10_1
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_weapon_10)
            end
        elseif combination.Type == XDrawConfigs.CombinationsTypes.NewUp then
            --CheckPoint: APPEVENT_DRAWS_LIMIT_10
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_limit_10)
        end
    else
        if drawInfo.Id == 101 then
            --CheckPoint: APPEVENT_DRAWS_ROLE_10_2
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_role_10)
        elseif drawInfo.Id == 201 then
            --CheckPoint: APPEVENT_DRAWS_WEAPON_10_2
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_weapon_10)
        end
    end
end

function XUiDrawControl:Update(drawInfo, groupId)
    self.DrawInfo = drawInfo
    self.GroupId = groupId or self.GroupId
    self.UseItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.DrawInfo.UseItemId)
    ---@type FreeTicketData[]
    self.FreeTicketDataDict = {}

    local isFreeBtnShow = false
    for i, btnView in pairs(self.DrawBtnDict) do
        local drawCount = self.DrawInfo.BtnDrawCount[i]
        local isTenDraw = btnView.IsTenDraw
        local isShowFreeBtn = XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId, isTenDraw)

        --用于显示免费券多久失效的字段
        ---@type FreeTicketData
        local ticketData = {}
        local representTicketId, _, count = XDataCenter.DrawManager.GetLeastExpireTimeFreeTicketIdByGroupId(self.GroupId, isTenDraw)
        ticketData.FreeTicketIdForExpireTimeDisplay = representTicketId
        ticketData.FreeTicketCountForDisplay = count
        self.FreeTicketDataDict[i] = ticketData

        if btnView.Btn then
            self:UpdateButton(btnView.Btn, drawCount)
            btnView.Btn.gameObject:SetActiveEx(not isShowFreeBtn)
        end

        if btnView.FreeBtn then
            local freeCount = XDataCenter.DrawManager.GetFreeTicketCount(self.GroupId, isTenDraw)
            local content = XUiHelper.GetText('DrawFreeTimeFormat', freeCount)
            content = XUiHelper.ReplaceTextNewLine(content)
            btnView.FreeBtn:SetNameByGroup(1, content)
            btnView.FreeBtn.gameObject:SetActiveEx(isShowFreeBtn)
            if isShowFreeBtn then
                isFreeBtnShow = true
            end
        end
    end

    self:RefreshTenDrawDiscount()

    if self.TxtDrawCount then
        self.TxtDrawCount.text = CS.XTextManager.GetText("DrawTotalCount", drawInfo.TotalCount)
    end

    if isFreeBtnShow then
        self:StartTimer()
    else
        self:StopTimer()
    end
end

-- 刷新十连抽的折扣显示
function XUiDrawControl:RefreshTenDrawDiscount()
    -- 十连抽的折扣标签
    local isTenDiscount, discountText = XDataCenter.DrawManager.IsShowTagTenDiscount(self.DrawInfo.GroupId)
    if self.RootUi.Tag10Discount then
        self.RootUi.Tag10Discount.gameObject:SetActiveEx(isTenDiscount)
        if isTenDiscount then
            self.RootUi.Txt10Discount.text = discountText
        end
    end
    -- 十连抽的折扣描述
    local useCount, maxCount = XDataCenter.DrawManager.GetTenDrawDiscountCount(self.DrawInfo.GroupId)
    if self.RootUi.Panel10Discount then
        self.RootUi.Panel10Discount.gameObject:SetActiveEx(isTenDiscount)
        if isTenDiscount then
            useCount = math.min(useCount, maxCount)
            local discountTextKeyMap = {
                [23] = "DrawTenDiscountDescXuan",
                [24] = "DrawTenDiscountDescMingyunXuan",
            }
            local textKey = discountTextKeyMap[self.DrawInfo.GroupId] or "DrawTenDiscountDesc"
            self.RootUi.Txt10DiscountDesc.text = XUiHelper.GetText(textKey, useCount, maxCount)
        end
    end
end

return XUiDrawControl

---@class DrawButtonView
---@field IsTenDraw boolean
---@field Btn XUiComponent.XUiButton
---@field FreeBtn XUiComponent.XUiButton
---@field FreeBtnTip UnityEngine.UI.Text

---@class FreeTicketData
---@field FreeTicketIdForExpireTimeDisplay number
---@field FreeTicketCountForDisplay number
