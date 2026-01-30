---@class XUiPanelTheatre5Main: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5Main
local XUiPanelTheatre5Main = XClass(XUiNode, 'XUiPanelTheatre5Main')
local XUiTheatre5MainTeaching = require("XUi/XUiTheatre5/XUiTheatre5Main/XUiTheatre5MainTeaching")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local Day = 3600 * 24

function XUiPanelTheatre5Main:OnStart()
    self:Init()
    
    -- 注册蓝点
    self:InitReddots()
end

function XUiPanelTheatre5Main:OnEnable()
    self:RefreshResourceBar()

    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Theatre5)
    self._IsPlayingEnableAnim = true
    self:TryPlayAnimationWithMask('AnimEnable', function()
        -- 因为样式替换的原因，该实例可能会被销毁，需要先检查
        if self:IsValid() then
            -- 新赛季弹窗
            self._Control:CheckNewSeason()
        end
        self._IsPlayingEnableAnim = false
    end)
    self:Refresh()
    self:StartPVPTimer()
    self:UpdateShopShowReward()
    self:RefreshReddots()
    self:RemindNewStoryLine()

    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PVP_END_IN_MATCH, self.OnPVPEndInMacthEvent, self)
end

function XUiPanelTheatre5Main:OnDisable()
    self:StopPVPTimer()
    if self._TimerNewStoryLine then
        XScheduleManager.UnSchedule(self._TimerNewStoryLine)
        self._TimerNewStoryLine = nil
    end

    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PVP_END_IN_MATCH, self.OnPVPEndInMacthEvent, self)
end

function XUiPanelTheatre5Main:OnRelease()
    self:StopPVPTimer()
    if self._TimerNewStoryLine then
        XScheduleManager.UnSchedule(self._TimerNewStoryLine)
        self._TimerNewStoryLine = nil
    end
end

function XUiPanelTheatre5Main:TryPlayAnimationWithMask(animName, cb, wrapMode)
    local isBegin = false

    self:PlayAnimationWithMask(animName, cb, function() 
        isBegin = true
    end, wrapMode)

    if not isBegin then
        if cb then
            cb()
        end
    end
end

function XUiPanelTheatre5Main:Init()
    self.BtnBack.CallBack = handler(self, self.OnClickClose)
    self.BtnMainUi.CallBack = handler(self, self.OnReturnMain)
    self:BindHelpBtn(self.BtnHelp, 'Theatre5')
    self.BtnBattle:AddEventListener(handler(self, self.OnBtnBattleClickEvent), true, true, 1)--模式切换协议受连点影响，给个cd
    self.BtnRetreat:AddEventListener(handler(self, self.OnBtnRetreatClickEvent))
    self.BtnStartPVE:AddEventListener(handler(self, self.OnBtnPVEBattleClickEvent), true, true, 1)
    self.BtnRetreatPVE:AddEventListener(handler(self, self.OnBtnPVERetreatClickEvent))
    self.BtnReward:AddEventListener(handler(self, self.OnOpenShop))
    self.BtnHandBook:AddEventListener(handler(self, self.OpenHangBook))

    self._MainTeaching = XUiTheatre5MainTeaching.New(self.GameObject, self)

    if self.BtnStartPlay then
        self.BtnStartPlay:AddEventListener(handler(self, self.OnPlayVideo), true)
    end
    -- 消除初见蓝点
    self._Control:MarkHasNoEnterReddot()
    self.PanelPopup = self.PanelPopup or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelPopup", "RectTransform")
    self.PopupText = self.PopupText or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelPopup/Text", "Text")
end

function XUiPanelTheatre5Main:Refresh()
    if self.BtnRetreat then
        --异步判空
        self.BtnRetreat.gameObject:SetActiveEx(self._Control:CheckIsInPVPAdventure())
    end
    if self.BtnRetreatPVE then
        self.BtnRetreatPVE.gameObject:SetActiveEx(self._Control.PVEControl:GetCurChapterBattleData() ~= nil)
    end
end

function XUiPanelTheatre5Main:RefreshResourceBar()
    local latestCoinIds = self._Control:GetTheatre5CoinIds()

    if not self.AssetActivityPanel then
        self._ResourceBarCoins = latestCoinIds
        
        ---@type XUiPanelActivityAsset
        self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
        for i = 1, #self._ResourceBarCoins do
            self.AssetActivityPanel:SetButtonCb(i, function()
                self:CustomCurrencyClick(i)
            end)
        end
    else
        -- 如果货币数量发生了变化，需要重新设置点击回调
        if #self._ResourceBarCoins ~= #latestCoinIds then
            for i = 1, #latestCoinIds do
                self.AssetActivityPanel:SetButtonCb(i, function()
                    self:CustomCurrencyClick(i)
                end)
            end
        end

        self._ResourceBarCoins = latestCoinIds
    end

    XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
    XDataCenter.ItemManager.AddCountUpdateListener(self._ResourceBarCoins, handler(self, self.UpdateAssetPanel), self.AssetActivityPanel)
end

function XUiPanelTheatre5Main:CustomCurrencyClick(index)
    local itemId = self._ResourceBarCoins[index]
    if XTool.IsNumberValid(itemId) then
        XLuaUiManager.Open("UiTheatre5PopupRewardDetail", itemId, XMVCA.XTheatre5.EnumConst.ItemType.Common)
    end
end

--- 进入游戏点击事件
function XUiPanelTheatre5Main:OnBtnBattleClickEvent()
    if not self.PVPEnable then
        local format = self._Control:GetClientConfigPVPNotOpenTips(self.PVPNotStart)

        if string.find(format, '{0}') then
            format = XUiHelper.FormatText(format, self._LeftTimeStr)
        end
        
        XUiManager.TipMsg(format)
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

function XUiPanelTheatre5Main:EnterPVPMode()
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

function XUiPanelTheatre5Main:OnBtnPVEBattleClickEvent()
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

function XUiPanelTheatre5Main:EnterPVEMode()
    self:PlayAnimationWithMask("Enter", function()
        self._Control.FlowControl:EnterModel()
        self._Control:MarkNewPVEActivityReddot()
    end)
end

--- 放弃游戏点击事件
function XUiPanelTheatre5Main:OnBtnRetreatClickEvent()
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

function XUiPanelTheatre5Main:OnBtnPVERetreatClickEvent()
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

function XUiPanelTheatre5Main:OnOpenShop()
    self:PlayAnimationWithMask("Disable", function()
        XLuaUiManager.Open("UiTheatre5RewardShop")
        if self._ShowShopReddot then
            --消除商店红点
            self._Control:MarkLimitShopReddot()
        end
    end)
end

function XUiPanelTheatre5Main:SingleFightSettle()
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

function XUiPanelTheatre5Main:_OnNewBattleBegin()
    self._Control:SetCurPlayingMode(XMVCA.XTheatre5.EnumConst.GameMode.PVP)
    XLuaUiManager.Open('UiTheatre5ChooseCharacter', XMVCA.XTheatre5.EnumConst.GameMode.PVP)
end

function XUiPanelTheatre5Main:_OnBattleContinue()
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

function XUiPanelTheatre5Main:OnClickClose()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Theatre5)

    self:PlayAnimationWithMask("Disable", function()
        --win包很低概率偶现角色界面和主界面套娃，无法复现，故先容错处理
        XLuaUiManager.SafeClose("UiTheatre5ChooseCharacter")
        self:CloseRoot()
    end)
end

function XUiPanelTheatre5Main:OnReturnMain()
    XLuaUiManager.RunMain()
end

--region PVP活动时间定时器

function XUiPanelTheatre5Main:StopPVPTimer()
    if self._PVPTimerId then
        XScheduleManager.UnSchedule(self._PVPTimerId)
        self._PVPTimerId = nil
        
        -- pvp结束后需要刷新相关的商店红点、资源
        self:RefreshResourceBar()
        self:RefreshReddots()
    end
end

function XUiPanelTheatre5Main:StartPVPTimer()
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

function XUiPanelTheatre5Main:UpdatePVPTimer()
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

function XUiPanelTheatre5Main:_ShowWhenNotInTime()
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
    
    local timeId = self._Control.PVPControl:GetFuturePVPActivityTimeId()

    if not XTool.IsNumberValidEx(timeId) then
        return
    end
    
    -- 判断时间，如果是未来会开启，则显示静态文本：x日后开启
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()

    if now < startTime then
        local startLeftTime = startTime - now
        local leftTimeStr = XUiHelper.GetTime(startLeftTime, XUiHelper.TimeFormatType.ACTIVITY)
        -- 将时间定格下来，只在重新进入界面时刷新
        self._LeftTimeStr = leftTimeStr
        
        leftTimeStr = XUiHelper.FormatText(self._Control:GetClientConfigPVPNotStartTips(false), leftTimeStr)
        
        if self.BtnBattle then
            self.BtnBattle:SetNameByGroup(2, leftTimeStr)
        end
        
        self.PVPNotStart = true
    else
        if self.BtnBattle then
            self.BtnBattle:SetNameByGroup(2, self._Control:GetClientConfigPVPNotStartTips(true))
        end

        self.PVPNotStart = false
    end

    self.PVPEnable = false
end

function XUiPanelTheatre5Main:_ShowWhenInTime()
    if self.BtnBattle then
        self.BtnBattle:SetButtonState(CS.UiButtonState.Normal)
        self.BtnBattle:ShowTag(true)
    end

    if self.BtnStart then
        self.BtnStart:ShowTag(true)
    end

    self.PVPEnable = true
end

function XUiPanelTheatre5Main:OnPlayVideo()
    local videoId = self._Control:GetMainVideoId()
    if not XTool.IsNumberValid(videoId) then
        return
    end
    XLuaVideoManager.PlayUiVideo(videoId)
end

function XUiPanelTheatre5Main:UpdateShopShowReward()
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

function XUiPanelTheatre5Main:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
end

--endregion

--region 蓝点

function XUiPanelTheatre5Main:InitReddots()
    self._PVPReddotId = self:AddRedPointEvent(self.BtnBattle, self.OnBtnPVPReddotEvent, self, { XRedPointConditions.Types.CONDITION_THEATRE5_PVP_NEW_ACTIVITY }, nil, false)
    self._PVEReddotId = self:AddRedPointEvent(self.BtnStartPVE, self.OnBtnPVEReddotEvent, self, { XRedPointConditions.Types.CONDITION_THEATRE5_PVE_NEW_ACTIVITY }, nil, false)
    self._ShopReddotId = self:AddRedPointEvent(self.BtnReward, self.OnBtnShopReddotEvent, self, { XRedPointConditions.Types.CONDITION_THEATRE5_LIMIT_SHOP, XRedPointConditions.Types.CONDITION_THEATRE5_TASK }, nil, false)
end

function XUiPanelTheatre5Main:RefreshReddots()
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

function XUiPanelTheatre5Main:OnBtnPVPReddotEvent(count)
    self.BtnBattle:ShowReddot(count >= 0)
end

function XUiPanelTheatre5Main:OnBtnPVEReddotEvent(count)
    self.BtnStartPVE:ShowReddot(count >= 0)
end

function XUiPanelTheatre5Main:OnBtnShopReddotEvent(count)
    self._ShowShopReddot = count >= 0
    self.BtnReward:ShowReddot(count >= 0)
end

--endregion

function XUiPanelTheatre5Main:OpenHangBook()
    XLuaUiManager.Open("UiTheatre5SkillHandbook")
end

-- v3.8新增，提示新剧情
function XUiPanelTheatre5Main:RemindNewStoryLine()
    local tipsNewStoryLine = self._Control:GetTipsNewStoryLine()
    if tipsNewStoryLine and tipsNewStoryLine ~= "" and self.PanelPopup then
        self.PanelPopup.gameObject:SetActiveEx(true)
        self.PopupText.text = XUiHelper.ReplaceTextNewLine(tipsNewStoryLine)
        --XLog.Debug("新增共通线提示:" .. tipsNewStoryLine)
        if not self._TimerNewStoryLine then
            self._TimerNewStoryLine = XScheduleManager.ScheduleOnce(function()
                self.PanelPopup.gameObject:SetActiveEx(false)
                self._TimerNewStoryLine = nil
            end, 5 * XScheduleManager.SECOND)
        end
    end
end

function XUiPanelTheatre5Main:CloseRoot()
    self.Parent:Close()
end

--- 这里主要是动画表现处理，因为直接在主界面进入匹配界面时，匹配界面是pop，主界面不会隐藏，也就不会重置enable和enter动画
--- 需要踢出返回后表现重进主界面，需要在这处理下动画播放
function XUiPanelTheatre5Main:OnPVPEndInMacthEvent()
    self:StopAnimation('Enter')
    if not self._IsPlayingEnableAnim then
        self:PlayAnimation('AnimEnable')
    end
end


--region 调用父节点方法的封装

function XUiPanelTheatre5Main:SetUiSprite(...)
    self.Parent:SetUiSprite(...)
end

function XUiPanelTheatre5Main:BindHelpBtn(...)
    self.Parent:BindHelpBtn(...)
end
--endregion

return XUiPanelTheatre5Main