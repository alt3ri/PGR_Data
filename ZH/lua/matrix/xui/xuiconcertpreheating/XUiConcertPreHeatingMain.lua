local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiConcertPreHeatingPanelSpine = require("XUi/XUiConcertPreHeating/Grid/XUiConcertPreHeatingPanelSpine")

---@field _Control XConcertPreHeatingControl
---@class XUiConcertPreHeatingMain : XLuaUi
local XUiConcertPreHeatingMain = XLuaUiManager.Register(XLuaUi, "UiConcertPreHeatingMain")

function XUiConcertPreHeatingMain:OnAwake()
    -- 页签状态
    self._StageIds = {}
    self._SelectStageId = 0

    self:InitDynamicTable()
    self:InitRewardBubble()
    self:InitCountdown()
    self:InitMiddleCd()
    self:InitButton()
    self:InitPanelSpine()
    self:AddEvent()
    self.PanelMiddleCd.gameObject:SetActiveEx(false)
    self.PanelFinalSpine.gameObject:SetActiveEx(false)
end

function XUiConcertPreHeatingMain:OnStart(selectStageId, playMainPerformance)
    self:PlayAnimation("AnimStart")
    self:InitTime()
    -- 外部打开 Main 时可指定一次初始选中关卡/主表现演出触发点。
    self._StartSelectStageId = selectStageId
    self._PlayMainPerformanceOnEnable = playMainPerformance
end

function XUiConcertPreHeatingMain:OnEnable()
    self:Refresh(self._StartSelectStageId)
    -- 外部指定关卡只消费一次，避免后续刷新锁定页签。
    self._StartSelectStageId = nil

    -- Stage 关闭前发来的主表现演出请求，等 Main 重新可见时再播放。
    local playMainPerformance = self._PlayMainPerformanceOnEnable
    self._PlayMainPerformanceOnEnable = nil
    if playMainPerformance then
        self:PlayMainPerformance()
    end

    self:StartTimer()
end

function XUiConcertPreHeatingMain:OnDisable()
    self.DynamicTable:RecycleAllTableGrid()
    self:StopTimer()
end

function XUiConcertPreHeatingMain:OnDestroy()
    self:RemoveEvent()
end

function XUiConcertPreHeatingMain:InitButton()
    XUiHelper.RegisterClickEvent(self, self._CountdownGotoLiveUi.BtnGotoLive, self.OnBtnGotoLiveClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSoundSet, self.OnBtnSoundSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReplayCG, self.OnBtnReplayCGClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFM, self.OnBtnFMClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFMAgain, self.OnBtnFMAgainClick)
    self:BindHelpBtn(self.BtnHelp, "ConcertPreHeatingHelp")
end

function XUiConcertPreHeatingMain:InitPanelSpine()
    self.PanelSpineNode = XUiConcertPreHeatingPanelSpine.New(self.PanelSpine, self, function() self:OnPanelSpineClose() end)
end

function XUiConcertPreHeatingMain:InitRewardBubble()
    local bubbleUi = XTool.InitUiObjectByUi({}, self.PanelCommonTaskRewardLeftBubble)
    self._RewardGrid = XUiGridCommon.New(bubbleUi.Grid256New)
end

function XUiConcertPreHeatingMain:InitDynamicTable()
    local XUiGridConcertPreHeatingStageTab = require("XUi/XUiConcertPreHeating/Grid/XUiGridConcertPreHeatingStageTab")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelBtnList, XUiGridConcertPreHeatingStageTab)
    self.GridBtnTab.gameObject:SetActiveEx(false)
end

function XUiConcertPreHeatingMain:InitCountdown()
    self._CountdownUi = XTool.InitUiObjectByUi({}, self.PanelCountdown)
    self._CountdownBeforeStartUi = XTool.InitUiObjectByUi({}, self._CountdownUi.PanelBeforeStart)
    self._CountdownTimeCdUi = XTool.InitUiObjectByUi({}, self._CountdownUi.PanelTimeCd)
    self._CountdownGotoLiveUi = XTool.InitUiObjectByUi({}, self._CountdownUi.PanelGotoLive)
    self._CountdownCdTextUi = {
        TxtHour = self._CountdownTimeCdUi.TxtHour,
        TxtMin = self._CountdownTimeCdUi.TxtMin,
        TxtSecond = self._CountdownTimeCdUi.TxtSecond,
    }
end

function XUiConcertPreHeatingMain:InitMiddleCd()
    local middleCdUi = XTool.InitUiObjectByUi({}, self.PanelMiddleCd)
    self._MiddleCdTextUi = {
        TxtHour = middleCdUi.TxtHour,
        TxtMin = middleCdUi.TxtMin,
        TxtSecond = middleCdUi.TxtSecond,
    }
end

function XUiConcertPreHeatingMain:InitTime()
    local endTime = XMVCA.XConcertPreHeating:GetActivityEndTime()
    if not XTool.IsNumberValid(endTime) then
        return
    end

    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XMVCA.XConcertPreHeating:HandleActivityEnd()
        end
    end)
end

function XUiConcertPreHeatingMain:AddEvent()
    XEventManager.AddEventListener(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE, self.OnConcertPreHeatingEventRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_CONCERT_PRE_HEATING_PLAY_MAIN_PERFORMANCE, self.OnConcertPreHeatingPlayMainPerformance, self)
end

function XUiConcertPreHeatingMain:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE, self.OnConcertPreHeatingEventRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CONCERT_PRE_HEATING_PLAY_MAIN_PERFORMANCE, self.OnConcertPreHeatingPlayMainPerformance, self)
end

function XUiConcertPreHeatingMain:StartTimer()
    self._RefreshTimer = XScheduleManager.ScheduleForever(function()
        self:RefreshCountdown()
    end, XScheduleManager.SECOND)
end

function XUiConcertPreHeatingMain:StopTimer()
    XScheduleManager.UnSchedule(self._RefreshTimer)
    self._RefreshTimer = nil
    XScheduleManager.UnSchedule(self._MiddleCdTimer)
    self._MiddleCdTimer = nil
end

function XUiConcertPreHeatingMain:OnConcertPreHeatingEventRefresh()
    self:Refresh()
end

function XUiConcertPreHeatingMain:OnConcertPreHeatingPlayMainPerformance(stageId)
    -- Main 此时还被 Stage 压住，先记录请求，等 OnEnable 统一刷新后消费。
    self._StartSelectStageId = stageId
    self._PlayMainPerformanceOnEnable = true
end

-- 刷新整体界面
function XUiConcertPreHeatingMain:Refresh(selectStageId)
    self._StageIds = XMVCA.XConcertPreHeating:GetStageIds()
    local selectIndex = self:GetStageIndex(selectStageId)
    if not XTool.IsNumberValid(selectIndex) then
        selectIndex = self:GetStageIndex(self._SelectStageId)
    end
    if not XTool.IsNumberValid(selectIndex) then
        selectIndex = self:GetDefaultSelectStageIndex()
    end

    self._SelectStageId = self._StageIds[selectIndex] or 0
    self:RefreshDynamicTable(selectIndex)
    self:RefreshReward()
    self:RefreshCountdown()
end

function XUiConcertPreHeatingMain:GetStageIndex(stageId)
    for index, id in ipairs(self._StageIds or {}) do
        if id == stageId then
            return index
        end
    end

    return 0
end

function XUiConcertPreHeatingMain:GetDefaultSelectStageIndex()
    if XTool.IsTableEmpty(self._StageIds) then
        return 0
    end

    -- 最新可调频关优先
    local latestPlayableIndex = self:GetLatestPlayableStageIndex()
    local latestPlayableStageId = self._StageIds[latestPlayableIndex]
    if XTool.IsNumberValid(latestPlayableStageId) and not self._Control:IsStageFinished(latestPlayableStageId) then
        return latestPlayableIndex
    end

    -- 全部完成后回看玩家上次展示关卡
    local savedStageId = XMVCA.XConcertPreHeating:GetLocalSelectStageId()
    if XTool.IsNumberValid(savedStageId) and self._Control:IsStageOpen(savedStageId) then
        local savedIndex = self:GetStageIndex(savedStageId)
        if XTool.IsNumberValid(savedIndex) then
            return savedIndex
        end
    end

    return latestPlayableIndex
end

function XUiConcertPreHeatingMain:GetLatestPlayableStageIndex()
    local latestOpenIndex = 0

    for index, stageId in ipairs(self._StageIds or {}) do
        if self._Control:IsStageOpen(stageId) then
            latestOpenIndex = index

            if not self._Control:IsStageFinished(stageId) then
                return index
            end
        end
    end

    if XTool.IsNumberValid(latestOpenIndex) then
        return latestOpenIndex
    end

    return XTool.IsTableEmpty(self._StageIds) and 0 or 1
end

function XUiConcertPreHeatingMain:RefreshDynamicTable(index)
    if not self.PanelPlay.gameObject.activeInHierarchy then
        return
    end

    self.DynamicTable:SetDataSource(self._StageIds)
    self.DynamicTable:ReloadDataSync(XTool.IsNumberValid(index) and index or 1)

    if XTool.IsTableEmpty(self._StageIds) then
        self:RefreshCurrentStageInfo()
    end
end

function XUiConcertPreHeatingMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        local stageId = self.DynamicTable.DataSource[index]
        local isSelect = stageId == self._SelectStageId
        grid:Refresh(index, stageId)
        grid:RefreshButtonState(isSelect)

        if isSelect then
            self:RefreshCurrentStageInfo()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    end
end

-- 刷新活动时间和当前页签对应的操作按钮/角色展示
function XUiConcertPreHeatingMain:RefreshCurrentStageInfo()
    local stageId = self._SelectStageId
    if not XTool.IsNumberValid(stageId) then
        self.BtnFM.gameObject:SetActiveEx(false)
        self.BtnFMAgain.gameObject:SetActiveEx(false)
        self.BtnReplayCG.gameObject:SetActiveEx(false)
        return
    end

    local isOpen = self._Control:IsStageOpen(stageId)
    local isFinished = self._Control:IsStageFinished(stageId)
    local isMainPerformance = self._Control:IsMainPerformanceStage(stageId)

    -- 活动时间
    self.TxtTime.text = XMVCA.XConcertPreHeating:GetActivityTimeText()

    -- 操作按钮
    self.BtnFM.gameObject:SetActiveEx(not isFinished)
    self.BtnFMAgain.gameObject:SetActiveEx(isFinished)
    self.BtnReplayCG.gameObject:SetActiveEx(isFinished and not isMainPerformance)

    self.BtnFM:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnFMAgain:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    -- 角色展示：主表现关完成用 Spine Loop，其余关卡按剪影/展示图
    self.RImgRoleCG.gameObject:SetActiveEx(false)
    if isMainPerformance and isFinished then
        self.RImgRole.gameObject:SetActiveEx(false)
        self:ShowFinalSpineLoop()
    else
        self.PanelFinalSpine.gameObject:SetActiveEx(false)
        local roleImg = self._Control:GetStageMainUiImg(stageId)
        self.RImgRole:SetRawImage(roleImg)
        self.RImgRole.gameObject:SetActiveEx(not string.IsNilOrEmpty(roleImg))
    end
end

-- 刷新奖励入口
function XUiConcertPreHeatingMain:RefreshReward()
    local taskGroupId = XMVCA.XConcertPreHeating:GetTaskGroupId()
    local hasTaskGroup = XTool.IsNumberValid(taskGroupId)
    local rewardData, isReceived = nil, false

    -- 奖励红点
    XRedPointManager.CheckOnceByButton(self.BtnReward, { XRedPointConditions.Types.CONDITION_CONCERT_PRE_HEATING_TASK })

    if hasTaskGroup then
        rewardData, isReceived = XMVCA.XConcertPreHeating:GetTaskRewardPreview()
    end

    -- 奖励气泡
    local isShowBubble = hasTaskGroup and rewardData ~= nil
    self.PanelCommonTaskRewardLeftBubble.gameObject:SetActiveEx(isShowBubble)

    if isShowBubble then
        self._RewardGrid:Refresh(rewardData)
        self._RewardGrid:SetReceived(isReceived)
    end
end

-- 刷新直播倒计时
function XUiConcertPreHeatingMain:RefreshCountdown()
    local liveState = XMVCA.XConcertPreHeating:GetLiveState()
    local countdownUi = self._CountdownUi
    local beforeStartUi = self._CountdownBeforeStartUi
    local timeCdUi = self._CountdownTimeCdUi
    local gotoLiveUi = self._CountdownGotoLiveUi

    if not liveState or liveState.State == XEnumConst.ConcertPreHeating.LiveState.None then
        self.PanelCountdown.gameObject:SetActiveEx(false)
        return
    end

    self.PanelCountdown.gameObject:SetActiveEx(true)
    -- 直播阶段
    local isBeforeLive = XMVCA.XConcertPreHeating:IsBeforeLive(liveState)
    local isLive = XMVCA.XConcertPreHeating:IsLive(liveState)
    local isReplay = XMVCA.XConcertPreHeating:IsReplay(liveState)
    local isReplayOpen = XMVCA.XConcertPreHeating:IsReplayOpen(liveState)
    local isLiveSoon = XMVCA.XConcertPreHeating:IsLiveSoon(liveState)
    local isMainPerformanceStageFinished = XMVCA.XConcertPreHeating:IsMainPerformanceStageFinished()
    local isShowTimeCd = isLive or isReplay or (isBeforeLive and (isMainPerformanceStageFinished or isLiveSoon))
    local isShowPanelTime = isBeforeLive and (isMainPerformanceStageFinished or isLiveSoon)
    local isShowGotoLive = isLive or isReplay or (isBeforeLive and (isMainPerformanceStageFinished or isLiveSoon))

    -- 倒计时面板
    countdownUi.PanelBeforeStart.gameObject:SetActiveEx(isBeforeLive)
    timeCdUi.PanelTime.gameObject:SetActiveEx(isShowPanelTime)
    timeCdUi.TxtPanelTimeCd.gameObject:SetActiveEx(isShowPanelTime)
    timeCdUi.PanelLive.gameObject:SetActiveEx(isLive)
    timeCdUi.PanelEnd.gameObject:SetActiveEx(isReplay)
    countdownUi.PanelTimeCd.gameObject:SetActiveEx(isShowTimeCd)
    countdownUi.PanelGotoLive.gameObject:SetActiveEx(isShowGotoLive)

    -- 直播入口状态
    gotoLiveUi.LiveBefore.gameObject:SetActiveEx(isBeforeLive and not isLiveSoon)
    gotoLiveUi.GotoLive.gameObject:SetActiveEx(isLive or (isBeforeLive and isLiveSoon))
    gotoLiveUi.GotoSeeLive.gameObject:SetActiveEx(isReplay and isReplayOpen)
    gotoLiveUi.LiveNotReplay.gameObject:SetActiveEx(isReplay and not isReplayOpen)
    gotoLiveUi.LiveReplayReady.gameObject:SetActiveEx(isReplay and isReplayOpen)

    -- 倒计时文本
    if isBeforeLive then
        beforeStartUi.TxtStartCountDown.text = XMVCA.XConcertPreHeating:GetLiveDayText(liveState)
        self:SetCdText(self._CountdownCdTextUi, isShowTimeCd and liveState.LeftTime or 0)
    elseif isLive then
        beforeStartUi.TxtStartCountDown.text = ""
        self:SetCdText(self._CountdownCdTextUi, liveState.LeftTime)
    else
        beforeStartUi.TxtStartCountDown.text = ""
        self:SetCdText(self._CountdownCdTextUi, 0)
    end
end

local function FormatCdNumber(value)
    local text = string.format("%02d", math.min(math.max(value or 0, 0), 99))
    return string.sub(text, 1, 1) .. " " .. string.sub(text, 2, 2)
end

function XUiConcertPreHeatingMain:SetCdText(cdTextUi, leftTime)
    leftTime = math.max(leftTime or 0, 0)
    local hour = math.floor(leftTime / 3600)
    local min = math.floor(leftTime % 3600 / 60)
    local second = math.floor(leftTime % 60)

    if cdTextUi.TxtHour then
        cdTextUi.TxtHour.text = FormatCdNumber(hour)
    end
    if cdTextUi.TxtMin then
        cdTextUi.TxtMin.text = FormatCdNumber(min)
    end
    if cdTextUi.TxtSecond then
        cdTextUi.TxtSecond.text = FormatCdNumber(second)
    end
end

function XUiConcertPreHeatingMain:RefreshStageTabButtonState(index, isSelect)
    if not XTool.IsNumberValid(index) then
        return
    end

    local grid = self.DynamicTable:GetGridByIndex(index)
    if grid then
        grid:RefreshButtonState(isSelect)
    end
end

function XUiConcertPreHeatingMain:OnGridClickStageTab(index)
    local stageId = self._StageIds[index]
    if not XTool.IsNumberValid(stageId) then
        return
    end

    if not self._Control:IsStageOpen(stageId) then
        XUiManager.TipMsg(self._Control:GetStageLockTip(stageId))
        return
    end

    local oldIndex = self:GetStageIndex(self._SelectStageId)
    self._SelectStageId = stageId
    XMVCA.XConcertPreHeating:SaveSelectStageId(stageId)
    XMVCA.XConcertPreHeating:MarkStageNewRead(stageId)
    if oldIndex ~= index then
        self:RefreshStageTabButtonState(oldIndex, false)
        self:PlayAnimation("RoleEnable")
    end

    self:RefreshStageTabButtonState(index, true)
    self:RefreshCurrentStageInfo()
end

function XUiConcertPreHeatingMain:PlayMainPerformance()
    -- 主表现关完成后回 Main 的最终演出入口。
    self.PanelMiddleCd.gameObject:SetActiveEx(true)
    local liveState = XMVCA.XConcertPreHeating:GetLiveState()

    -- MiddleCd 面板文案为"距音乐会正式开始"，只对直播前有语义：
    -- 直播中/结束后注入 0，避免把"距直播结束"的时间误当"距开始"展示。
    local isBeforeLive = XMVCA.XConcertPreHeating:IsBeforeLive(liveState)
    local leftTime = isBeforeLive and liveState.LeftTime or 0
    self:SetCdText(self._MiddleCdTextUi, leftTime)

    -- 仅直播前倒计时在动画期间会走动，此时每秒刷新避免快照漂移。
    if isBeforeLive then
        self._MiddleCdTimer = XScheduleManager.ScheduleForever(function()
            local state = XMVCA.XConcertPreHeating:GetLiveState()
            local before = XMVCA.XConcertPreHeating:IsBeforeLive(state)
            self:SetCdText(self._MiddleCdTextUi, before and state.LeftTime or 0)
        end, XScheduleManager.SECOND)
    end

    self:ShowFinalSpineLoop()
    self:PlayAnimationWithMask("FinalStageFinish", function()
        self.PanelMiddleCd.gameObject:SetActiveEx(false)
        self:RefreshCountdown()
    end)
end

-- 主表现关完成态展示：激活 PanelFinalSpine 并常驻播放 Loop（切页签与结算演出共用）。
function XUiConcertPreHeatingMain:ShowFinalSpineLoop()
    self.PanelFinalSpine.gameObject:SetActiveEx(true)
    local finalSpineRole = self.PanelFinalSpine.transform:FindTransform("Role")
    local finalSpineSkeletonAnimation = finalSpineRole:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
    finalSpineSkeletonAnimation.AnimationState:SetAnimation(0, "Loop", true)
end

function XUiConcertPreHeatingMain:OpenSelectedStage()
    local tuningStageId = self._SelectStageId
    if not XTool.IsNumberValid(tuningStageId) then
        return
    end

    if not self._Control:IsStageOpen(tuningStageId) then
        XUiManager.TipMsg(self._Control:GetStageLockTip(tuningStageId))
        return
    end

    XMVCA.XConcertPreHeating:ConcertPreHeatingStartRequest(tuningStageId, function()
        XLuaUiManager.Open("UiConcertPreHeatingTuningStage", tuningStageId)
    end)
end

function XUiConcertPreHeatingMain:OnBtnGotoLiveClick()
    XMVCA.XConcertPreHeating:OpenLiveUrlWithTips(nil, true)
end

function XUiConcertPreHeatingMain:OnBtnRewardClick()
    XLuaUiManager.Open("UiConcertPreHeatingTask")
end

function XUiConcertPreHeatingMain:OnBtnBackClick()
    self:Close()
end

function XUiConcertPreHeatingMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiConcertPreHeatingMain:OnBtnSoundSetClick()
    XLuaUiManager.Open("UiSet")
end

function XUiConcertPreHeatingMain:OnBtnReplayCGClick()
    local stageId = self._SelectStageId
    if not self._Control:IsStageFinished(stageId) then
        return
    end

    if self._Control:IsMainPerformanceStage(stageId) then
        return
    end

    local spinePrefabUrl = self._Control:GetStageCompleteSpinePrefabUrl(stageId)
    if string.IsNilOrEmpty(spinePrefabUrl) then
        return
    end

    self:PlayStageCompleteSpineReplay(spinePrefabUrl)
end

function XUiConcertPreHeatingMain:PlayStageCompleteSpineReplay(spinePrefabUrl)
    self.PanelSpineNode:LoadSpinePrefab(spinePrefabUrl)
    self:PlayAnimationWithMask("StageFinish")
    local stageFinish = self.Transform:Find("Animation/StageFinish")
    local playableDirector = stageFinish:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    local delayTime = (playableDirector.duration or 0) / 2
    if delayTime <= 0 then
        self:ShowStageSpine()
        return
    end

    self:DelayCall(function()
        self:ShowStageSpine()
    end, delayTime)
end

function XUiConcertPreHeatingMain:ShowStageSpine()
    self.PanelSpineNode:Open()
    self.PanelSpineNode:PlaySpinePerformance(true, function()
        self.DynamicTable:RecycleAllTableGrid()
        self.PanelPlay.gameObject:SetActiveEx(false)
    end)
end

function XUiConcertPreHeatingMain:OnPanelSpineClose()
    self.PanelSpineNode:Close()
    self.PanelPlay.gameObject:SetActiveEx(true)
    self:RefreshDynamicTable(self:GetStageIndex(self._SelectStageId))
end

function XUiConcertPreHeatingMain:OnBtnFMClick()
    self:OpenSelectedStage()
end

function XUiConcertPreHeatingMain:OnBtnFMAgainClick()
    self:OpenSelectedStage()
end

return XUiConcertPreHeatingMain
