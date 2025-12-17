---@class XUiTheatre5Main: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5Main = XLuaUiManager.Register(XLuaUi, 'UiTheatre5Main')
local XUiTheatre5MainTeaching = require("XUi/XUiTheatre5/XUiTheatre5Main/XUiTheatre5MainTeaching")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiTheatre5Main:OnAwake()
    self.BtnBack.CallBack = handler(self, self.OnClickClose)
    self.BtnMainUi.CallBack = handler(self, self.OnReturnMain)
    self:BindHelpBtn(self.BtnHelp, 'Theatre5')
    self:RegisterClickEvent(self.BtnBattle, self.OnBtnBattleClickEvent, true, true, 1)  --模式切换协议受连点影响，给个cd
    self.BtnRetreat.CallBack = handler(self, self.OnBtnRetreatClickEvent)
    self:RegisterClickEvent(self.BtnStartPVE, self.OnBtnPVEBattleClickEvent, true, true, 1)
    self.BtnRetreatPVE.CallBack = handler(self, self.OnBtnPVERetreatClickEvent)
    self._MainTeaching = XUiTheatre5MainTeaching.New(self.GameObject, self)
    self:RegisterClickEvent(self.BtnReward, self.OnOpenShop, true)
    self:RegisterClickEvent(self.BtnHandBook, self.OpenHangBook, true)
    if self.BtnStartPlay then
        self:RegisterClickEvent(self.BtnStartPlay, self.OnPlayVideo, true)
    end
    -- 消除初见蓝点
    self._Control:MarkHasNoEnterReddot()
    self.PanelPopup = self.PanelPopup or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelPopup", "RectTransform")
    self.PopupText = self.PopupText or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelPopup/Text", "Text")
end

function XUiTheatre5Main:OnStart()
    self:RefreshResourceBar()

    -- 注册蓝点
    self:InitReddots()
end

function XUiTheatre5Main:OnEnable()
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Theatre5)
    self:Refresh()
    self:StartPVPTimer()
    self:UpdateShopShowReward()
    self:UpdateAssetPanel()
    self:RefreshReddots()
    self:RemindNewStoryLine()
    
    -- 新赛季弹窗
    self._Control:CheckNewSeason()
end

function XUiTheatre5Main:OnDisable()
    self:StopPVPTimer()
    if self._TimerNewStoryLine then
        XScheduleManager.UnSchedule(self._TimerNewStoryLine)
        self._TimerNewStoryLine = nil
    end
end

function XUiTheatre5Main:Refresh()
    if self.BtnRetreat then
        --异步判空
        self.BtnRetreat.gameObject:SetActiveEx(self._Control:CheckIsInPVPAdventure())
    end
    if self.BtnRetreatPVE then
        self.BtnRetreatPVE.gameObject:SetActiveEx(self._Control.PVEControl:GetCurChapterBattleData() ~= nil)
    end
end

function XUiTheatre5Main:RefreshResourceBar()
    self._ResourceBarCoins = self._Control:GetTheatre5CoinIds()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(self._ResourceBarCoins, handler(self, self.UpdateAssetPanel), self.AssetActivityPanel)
    for i = 1, #self._ResourceBarCoins do
        self.AssetActivityPanel:SetButtonCb(i, function()
            self:CustomCurrencyClick(i)
        end)
    end
end

function XUiTheatre5Main:CustomCurrencyClick(index)
    local itemId = self._ResourceBarCoins[index]
    if XTool.IsNumberValid(itemId) then
        XLuaUiManager.Open("UiTheatre5PopupRewardDetail", itemId, XMVCA.XTheatre5.EnumConst.ItemType.Common)
    end
end

--- 进入游戏点击事件
function XUiTheatre5Main:OnBtnBattleClickEvent()
    if not self.PVPEnable then
        XUiManager.TipMsg(self._Control:GetClientConfigPVPNotOpenTips())
        return
    end

    if self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        XMVCA.XTheatre5:RequestPveOrPvpChange(function(success)
            if success then
                self:EnterPVPMode()
            end
        end)
    else
        self:EnterPVPMode()
    end
end

function XUiTheatre5Main:EnterPVPMode()
    self:PlayAnimationWithMask("Enter", function()
        self._Control.FlowControl:EnterModel()
        if self._Control:CheckIsInPVPAdventure() then
            self:_OnBattleContinue()
        else
            self:_OnNewBattleBegin()
        end

        self._Control:MarkNewPVPActivityReddot()
    end)
end

function XUiTheatre5Main:OnBtnPVEBattleClickEvent()
    if self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        XMVCA.XTheatre5:RequestPveOrPvpChange(function(success)
            if success then
                self:EnterPVEMode()
            end
        end)
    else
        self:EnterPVEMode()
    end
end

function XUiTheatre5Main:EnterPVEMode()
    self:PlayAnimationWithMask("Enter", function()
        self._Control.FlowControl:EnterModel()
        self._Control:MarkNewPVEActivityReddot()
    end)
end

--- 放弃游戏点击事件
function XUiTheatre5Main:OnBtnRetreatClickEvent()
    if self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        XMVCA.XTheatre5:RequestPveOrPvpChange(function(success)
            if success then
                self:SingleFightSettle()
            end
        end)
    else
        self:SingleFightSettle()
    end

end

function XUiTheatre5Main:OnBtnPVERetreatClickEvent()
    if self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        XMVCA.XTheatre5:RequestPveOrPvpChange(function(success)
            if success then
                self:SingleFightSettle()
            end
        end)
    else
        self:SingleFightSettle()
    end


end

function XUiTheatre5Main:OnOpenShop()
    self:PlayAnimationWithMask("Disable", function()
        XLuaUiManager.Open("UiTheatre5RewardShop")
        if self._ShowShopReddot then
            --消除商店红点
            self._Control:MarkLimitShopReddot()
        end
    end)
end

function XUiTheatre5Main:SingleFightSettle()
    XMVCA.XTheatre5:TryPopupDialog(XUiHelper.GetText("TipTitle"), self._Control:GetClientConfigGameGiveUpContent(), nil, function()
        if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
            if not XMVCA.XTheatre5:CheckInPVPActivityTime() then
                XUiManager.TipText('ActivityMainLineEnd')
                self:Refresh()
                return
            end
        end

        -- 特殊逻辑，结算后触发铭牌弹窗和结算弹窗重合，导致不能正常看到铭牌弹窗，需要在这锁定
        XDataCenter.MedalManager.SetNewNameplateAutoWinLock(true)

        XMVCA.XTheatre5.BattleCom:RequestTheatre5AdvanceSettle(function()
            self:Refresh()
        end)
    end)
end

function XUiTheatre5Main:_OnNewBattleBegin()
    self._Control:SetCurPlayingMode(XMVCA.XTheatre5.EnumConst.GameMode.PVP)
    XLuaUiManager.Open('UiTheatre5ChooseCharacter', XMVCA.XTheatre5.EnumConst.GameMode.PVP)
end

function XUiTheatre5Main:_OnBattleContinue()
    self._Control:SetCurPlayingMode(XMVCA.XTheatre5.EnumConst.GameMode.PVP)

    if not XMVCA.XTheatre5:CheckInPVPActivityTime() then
        XUiManager.TipText('ActivityMainLineEnd')
        self:Refresh()
        return
    end

    local curStatus = self._Control:GetCurPlayStatus()
    
    if curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.Matching then
        -- 重新进入匹配界面展示后请求进入战斗
        XMVCA.XTheatre5.BattleCom:OpenMatchLoadingUi(self._Control.PVPControl:GetCurMatchedEnemy())
    elseif curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.Battling then
        -- 结算后重新战斗
        XMVCA.XTheatre5.BattleCom:RequestTheatre5InterruptBattle(function(giveUpSuccess, isFinish)
            if giveUpSuccess then
                if not isFinish then
                    XMVCA.XTheatre5.BattleCom:OpenMatchLoadingUi(self._Control.PVPControl:GetCurMatchedEnemy())
                else
                    self:Refresh()
                end
            end
        end)
    elseif curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.BattleFinish then
        -- 请求进入商店    
        XMVCA.XTheatre5:RequestTheatre5EnterShop(function(success)
            if success then
                XLuaUiManager.Open('UiTheatre5BattleShop')
            end
        end)
    else
        XLuaUiManager.Open('UiTheatre5BattleShop')
    end
end

function XUiTheatre5Main:OnClickClose()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Theatre5)
    self:PlayAnimationWithMask("Disable", function()
        --win包很低概率偶现角色界面和主界面套娃，无法复现，故先容错处理
        XLuaUiManager.SafeClose("UiTheatre5ChooseCharacter")
        self:Close()
    end)
end

function XUiTheatre5Main:OnReturnMain()
    XLuaUiManager.RunMain()
end

--region PVP活动时间定时器

function XUiTheatre5Main:StopPVPTimer()
    if self._PVPTimerId then
        XScheduleManager.UnSchedule(self._PVPTimerId)
        self._PVPTimerId = nil
    end
end

function XUiTheatre5Main:StartPVPTimer()
    self:StopPVPTimer()

    self.PVPTimeId = XMVCA.XTheatre5:GetPVPActivityTimeId()

    if XTool.IsNumberValid(self.PVPTimeId) and XFunctionManager.CheckInTimeByTimeId(self.PVPTimeId) then
        self:_ShowWhenInTime()

        self:UpdatePVPTimer()
        self._PVPTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdatePVPTimer), XScheduleManager.SECOND)
    else
        self:_ShowWhenNotInTime()
    end
end

function XUiTheatre5Main:UpdatePVPTimer()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.PVPTimeId)

    if endTime <= 0 then
        XLog.Error('PVP结束时间异常，结束时间：' .. tostring(endTime) .. ' TimeId:' .. tostring(self.PVPTimeId))

        self:_ShowWhenNotInTime()
        self:StopPVPTimer()
    end

    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    local leftTimeStr = XUiHelper.FormatText(self._Control:GetClientConfigPVPTimeLabel(), XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))

    if self.BtnBattle then
        self.BtnBattle:SetNameByGroup(1, leftTimeStr)
    end

    if self.BtnStart then
        self.BtnStart:SetNameByGroup(1, leftTimeStr)
    end

    if leftTime <= 0 then
        self:_ShowWhenNotInTime()
        self:StopPVPTimer()
    end
end

function XUiTheatre5Main:_ShowWhenNotInTime()
    -- 隐藏首入口的时间文本、PVP入口

    if self.BtnBattle then
        self.BtnBattle:SetButtonState(CS.UiButtonState.Disable)
        self.BtnBattle:ShowTag(false)
    end

    if self.BtnStart then
        self.BtnStart:ShowTag(false)
    end

    if self.BtnRetreat then
        self.BtnRetreat.gameObject:SetActiveEx(false)
    end

    self.PVPEnable = false
end

function XUiTheatre5Main:_ShowWhenInTime()
    if self.BtnBattle then
        self.BtnBattle:SetButtonState(CS.UiButtonState.Normal)
        self.BtnBattle:ShowTag(true)
    end

    if self.BtnStart then
        self.BtnStart:ShowTag(true)
    end

    self.PVPEnable = true
end

function XUiTheatre5Main:OnPlayVideo()
    local videoId = self._Control:GetMainVideoId()
    if not XTool.IsNumberValid(videoId) then
        return
    end
    XLuaVideoManager.PlayUiVideo(videoId)
end

function XUiTheatre5Main:UpdateShopShowReward()
    local shopRewards = self._Control:GetShopShowRewards()
    self._RewardCellList = XUiHelper.RefreshUiObjectList(self._RewardCellList, self.Grid256New.transform.parent, self.Grid256New, #shopRewards, function(index, grid)
        ---@type XUiGridCommon
        local cell = XUiGridCommon.New(self, grid.GameObject)
        cell:Refresh(shopRewards[index])
        cell:SetName("")
        cell:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiTheatre5PopupRewardDetail", shopRewards[index].TemplateId, XMVCA.XTheatre5.EnumConst.ItemType.Common)
        end)
    end)
end

function XUiTheatre5Main:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
end

--endregion

--region 蓝点

function XUiTheatre5Main:InitReddots()
    self._PVPReddotId = self:AddRedPointEvent(self.BtnBattle, self.OnBtnPVPReddotEvent, self, { XRedPointConditions.Types.CONDITION_THEATRE5_PVP_NEW_ACTIVITY }, nil, false)
    self._PVEReddotId = self:AddRedPointEvent(self.BtnStartPVE, self.OnBtnPVEReddotEvent, self, { XRedPointConditions.Types.CONDITION_THEATRE5_PVE_NEW_ACTIVITY }, nil, false)
    self._ShopReddotId = self:AddRedPointEvent(self.BtnReward, self.OnBtnShopReddotEvent, self, { XRedPointConditions.Types.CONDITION_THEATRE5_LIMIT_SHOP, XRedPointConditions.Types.CONDITION_THEATRE5_TASK }, nil, false)
end

function XUiTheatre5Main:RefreshReddots()
    self._ShowShopReddot = nil
    XRedPointManager.Check(self._PVPReddotId)
    XRedPointManager.Check(self._PVEReddotId)
    local shopIdList = self._Control:GetValidShopIdlist()
    --基础商店是否解锁
    local baseShopUnlock = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true)
    if XTool.IsTableEmpty(shopIdList) or not baseShopUnlock then
        XRedPointManager.Check(self._ShopReddotId)
    else
        -- 任务也要刷新红点
        XRedPointManager.Check(self._ShopReddotId)
        XShopManager.GetShopInfoList(shopIdList, function()
            XRedPointManager.Check(self._ShopReddotId)
        end, XShopManager.ActivityShopType.Theatre5Shop, true)
    end
end

function XUiTheatre5Main:OnBtnPVPReddotEvent(count)
    self.BtnBattle:ShowReddot(count >= 0)
end

function XUiTheatre5Main:OnBtnPVEReddotEvent(count)
    self.BtnStartPVE:ShowReddot(count >= 0)
end

function XUiTheatre5Main:OnBtnShopReddotEvent(count)
    self._ShowShopReddot = count >= 0
    self.BtnReward:ShowReddot(count >= 0)
end

--endregion

function XUiTheatre5Main:OpenHangBook()
    XLuaUiManager.Open("UiTheatre5SkillHandbook")
end

-- v3.8新增，提示新剧情
function XUiTheatre5Main:RemindNewStoryLine()
    local tipsNewStoryLine = self._Control:GetTipsNewStoryLine()
    if tipsNewStoryLine and tipsNewStoryLine ~= "" and self.PanelPopup then
        self.PanelPopup.gameObject:SetActiveEx(true)
        self.PopupText.text = tipsNewStoryLine
        --XLog.Debug("新增共通线提示:" .. tipsNewStoryLine)
        if not self._TimerNewStoryLine then
            self._TimerNewStoryLine = XScheduleManager.ScheduleOnce(function()
                self.PanelPopup.gameObject:SetActiveEx(false)
                self._TimerNewStoryLine = nil
            end, 5 * XScheduleManager.SECOND)
        end
    end
end

return XUiTheatre5Main