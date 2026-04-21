local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XArenaAgency : XFubenSimulationChallengeAgency
---@field private _Model XArenaModel
local XArenaAgency = XClass(XFubenSimulationChallengeAgency, "XArenaAgency")

function XArenaAgency:OnInit()
    -- 初始化一些变量
    self:RegisterChapterAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.Arena)

    self.ExChapterType = self:ExGetChapterType()
end

function XArenaAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.ActivityResultNotify = Handler(self, self.OnActivityResultNotify)
    XRpc.NotifyArenaActivity = Handler(self, self.OnNotifyArenaActivity)
    XRpc.NotifyArenaStopResetTime = Handler(self, self.OnNotifyArenaStopResetTime)
end

function XArenaAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()

    -- 监听副本结算奖励事件（参考 XFubenBossSingleAgency）
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettle, self)
    
    self._OnBehaviorDoExitFightHandler = handler(self, self.OnBehaviorDoExitFight)
    
    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_BEHAVIOR_DO_EXIT_FIGHT, self._OnBehaviorDoExitFightHandler)
end

function XArenaAgency:ResetAll()
    self._FightSettleDataCache = nil
end

-- region Notify

function XArenaAgency:OnActivityResultNotify(data)
    self._Model:SetActivityResultData(data)
    self._Model:SetActivityDataContributeScore(data.ContributeScore)
    self._Model:SetActivityDataArenaLevel(data.NewArenaLevel)
end

function XArenaAgency:OnNotifyArenaActivity(data)
    self._Model:ClearAll()
    self._Model:SetActivityData(data)
    self._Model:SetIsRefreshMainPage(true)
    self:_JudgeToRunMain()
    self:_SaveActivityNo()

    -- 状态更改通知周历刷新
    XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
    XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
end

function XArenaAgency:OnNotifyArenaStopResetTime(data)
    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()

        activityData:SetStopResetTime(data.StopResetTime)
    end
end

-- endregion

function XArenaAgency:OnRelease()
    -- 移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettle, self)
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_BEHAVIOR_DO_EXIT_FIGHT, self._OnBehaviorDoExitFightHandler)
end

-- region 副本入口

function XArenaAgency:OpenMainUiFromCommonSkip(skipId)
    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local status = activityData:GetStatus()

        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenArena) then
            self._Model:JoinActivityRequest(function(success)
                self._Model:SetIsRefreshMainPage(false)

                if not success then
                    XFunctionManager.RecordSkip(skipId)
                    return
                end

                local callback = function(groupData, success)
                    if not success or not groupData then
                        XFunctionManager.RecordSkip(skipId, nil)
                        return
                    end

                    XLuaUiManager.Open("UiArenaNew", groupData)
                    -- 处理异步跳转结果（埋点相关）
                    XFunctionManager.RecordSkip(skipId, nil)
                end

                if status == XEnumConst.Arena.ActivityStatus.Fight then
                    self._Model:GroupMemberRequest(callback)
                else
                    self._Model:ScoreQueryRequest(callback)
                end
            end)

        end
    end

    return false
end

function XArenaAgency:ExOpenMainUi(skipId)
    local exCfg = self:ExGetConfig()

    if not exCfg or not XTool.IsNumberValid(exCfg.SkipId) then
        if XMain.IsEditorDebug then
            XLog.Error('战区入口配置SkipId为空，不通过通用跳转进入')
        end

        self:OpenMainUiFromCommonSkip()
    else
        XFubenSimulationChallengeAgency.ExOpenMainUi(self)
    end
end

function XArenaAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.ARENA
end

function XArenaAgency:ExGetProgressTip()
    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local status = activityData:GetStatus()

        if status == XEnumConst.Arena.ActivityStatus.Rest then
            return XUiHelper.GetText("ArenaTeamDescription")
        elseif status == XEnumConst.Arena.ActivityStatus.Fight then
            local isJoin = activityData:GetIsJoinActivity()

            if isJoin then
                return XUiHelper.GetText("ArenaFightJoinDescription")
            else
                return XUiHelper.GetText("ArenaFightNotJoinDescription")
            end
        elseif status == XEnumConst.Arena.ActivityStatus.Over then
            return XUiHelper.GetText("ArenaOverDescription")
        end
    end

    return ""
end

function XArenaAgency:ExGetRunningTimeStr()
    local timeText = ""
    local remainTimeText = self:GetActivityRemainTimeStr()

    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local state = activityData:GetStatus()

        if state == XEnumConst.Arena.ActivityStatus.Rest then
            timeText = XUiHelper.GetText("ArenaActivityBeginCountDown") .. remainTimeText
        elseif state == XEnumConst.Arena.ActivityStatus.Fight then
            timeText = XUiHelper.GetText("ArenaActivityEndCountDown", remainTimeText)
        elseif state == XEnumConst.Arena.ActivityStatus.Over then
            local resultCountDownStr = XUiHelper.GetText("ArenaActivityResultCountDown")

            timeText = resultCountDownStr .. remainTimeText
        end
    end

    return timeText
end

function XArenaAgency:ExCheckIsFinished(callback)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenArena, nil, true) then
        self.IsClear = true

        if callback then
            callback(true)
        end

        return
    end

    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local state = activityData:GetStatus()

        if state ~= XEnumConst.Arena.ActivityStatus.Fight then -- 特殊，只要不在战斗期就一定显示Clear
            self.IsClear = true

            if callback then
                callback(true)
            end

            return
        end

        self.IsClear = false
        -- 检测完成的数据必现先报名战区并请求下发数据，不然会弹提示。所以把提示关掉
        self._Model:AreaDataRequest(function(areaData)
            local isHasAreaUnlock = false -- 有战区未解锁
            local isHasArealock = false -- 有战区已解锁
            local isAreaUnLockButHasStageUnpassed = false -- 解锁的区有关卡没打
            local arenaShowDataList = areaData:GetArenaShowList()

            for k, areaInfo in pairs(arenaShowDataList) do
                if areaInfo:GetIsLock() and not isHasAreaUnlock then
                    isHasAreaUnlock = true
                end

                if not areaInfo:GetIsLock() then
                    if not isHasArealock then
                        isHasArealock = true
                    end

                    local stageInfo = areaInfo:GetStageInfo()

                    if not stageInfo or stageInfo:IsClear() then
                        isAreaUnLockButHasStageUnpassed = true
                    end
                end
            end

            local result = true
            local unlockCount = activityData:GetUnlockCount()

            -- 有次数且未解锁区
            -- 有战区已解锁 且 解锁的区有关卡没打
            -- 有奖励未领取
            if (isHasAreaUnlock and unlockCount > 0) or (isHasArealock and isAreaUnLockButHasStageUnpassed)
                or XRedPointManager.CheckConditions({
                    "CONDITION_ARENA_MAIN_TASK",
                }) or self:ExGetIsLocked() then
                result = false
            end

            self.IsClear = result
            if callback then
                callback(result)
            end
        end, callback)
    else
        self.IsClear = true

        if callback then
            callback(true)
        end
    end
end

-- 获取倒计时（周历专用）
function XArenaAgency:ExGetCalendarRemainingTime()
    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local nextTime = activityData:GetNextStatusTime()

        if XTool.IsNumberValid(nextTime) then
            local remainTime = nextTime - XTime.GetServerNowTimestamp()

            if remainTime < 0 then
                remainTime = 0
            end

            local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)

            return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
        end
    end

    return ""
end

-- 获取解锁时间（周历专用）
function XArenaAgency:ExGetCalendarEndTime()
    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local nextTime = activityData:GetNextStatusTime()

        if XTool.IsNumberValid(nextTime) then
            return nextTime
        end
    end

    return 0
end

-- 是否在周历里显示
function XArenaAgency:ExCheckShowInCalendar()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenArena, nil, true) then
        return false
    end
    
    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local nextTime = activityData:GetNextStatusTime()

        if XTool.IsNumberValid(nextTime) then
            if nextTime - XTime.GetServerNowTimestamp() <= 0 then
                return false
            end

            local state = activityData:GetStatus()

            if state == XEnumConst.Arena.ActivityStatus.Fight then
                return true
            end
        end
    end

    return false
end

-- endregion

-- region 战斗接口

function XArenaAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local preFight = {
        CardIds = {},
        StageId = stage.StageId,
        IsHasAssist = isAssist and true or false,
        ChallengeCount = challengeCount or 1,
        ArenaSelectIndex = self._Model:GetCurrentSelectFightBuffIndex() - 1,
        SelectAreaId = self:GetCurrentAreaId(),
    }

    -- 如果有试玩角色且没有隐藏模式，则不读取玩家队伍信息
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)

        for _, v in pairs(teamData) do
            table.insert(preFight.CardIds, v)
        end

        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
    end

    local team = XDataCenter.TeamManager.GetXTeam(teamId) or XDataCenter.TeamManager.GetTempTeam(teamId)

    if team then
        preFight.GeneralSkill = team:GetCurGeneralSkill()
    end

    return preFight
end

--- 战斗结束处理（参考 XFubenBossSingleAgency:FinishFight）
---@param settle table 结算数据
function XArenaAgency:FinishFight(settle)
    if settle.IsWin then
        self:ChallengeWin(settle)
    else
        self:ChallengeLose(settle)
    end
end

--- 战斗胜利处理（参考 XFubenBossSingleAgency:ChallengeWin）
---@param settleData table 结算数据
function XArenaAgency:ChallengeWin(settleData)
    local beginData = XMVCA.XFuben:GetFightBeginData()
    local winData = XMVCA.XFuben:GetChallengeWinData(beginData, settleData)
    local stage = XMVCA.XFuben:GetStageCfg(settleData.StageId)
    local endStoryId = XMVCA.XFuben:GetEndStoryId(settleData.StageId)
    local isKeepPlayingStory = stage and XMVCA.XFuben:IsKeepPlayingStory(stage.StageId)
    local isNotPass = stage and beginData and not beginData.LastPassed

    if endStoryId and (isKeepPlayingStory or isNotPass) then
        -- 播放剧情
        CsXUiManager.Instance:SetRevertAndReleaseLock(true)
        XDataCenter.MovieManager.PlayMovie(endStoryId, function()
            -- 弹出结算
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
            XLuaAudioManager.StopCurrentBGM()
            -- self:ShowReward(winData, true)
        end, nil, nil, nil, nil, nil, settleData.StageId)
    else
        -- 弹出结算
        -- self:ShowReward(winData, false)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
end

--- 战斗失败处理（参考 XFubenBossSingleAgency:ChallengeLose）
---@param settleData table 结算数据
function XArenaAgency:ChallengeLose(settleData)
    XMVCA.XFuben:ChallengeLose(settleData)
end

--- 显示结算界面（私有函数，参考 XTransfiniteManager._ShowReward）
---@param winData table 胜利数据
function XArenaAgency:_ShowReward(winData)
    -- 检查强制退出（参考 XFubenBossSingleAgency）
    if self:CheckRunMainWhenFightOver() then
        return
    end

    -- Debug 模式下保存界面数据（参考 XFubenBossSingleAgency）
    if XMain.IsEditorDebug then
        self._DebugWinData = winData
    end

    -- 保存结算数据（Point 和 OldPoint，用于新纪录检查）
    local arenaResult = winData and winData.SettleData and winData.SettleData.ArenaResult
    if arenaResult and arenaResult.Point and arenaResult.OldArenaMaxPoint then
        local areaId = self._Model:GetCurrentEnterAreaId()
        if areaId and areaId > 0 then
            -- 通过 ConfigModel 获取 DistributeType 数组
            local distributeTypeList = self._Model:GetAreaStageDistributeTypeById(areaId)
            if distributeTypeList and not XTool.IsTableEmpty(distributeTypeList) then
                local selectIndex = self._Model:GetCurrentSelectFightBuffIndex()
                if selectIndex and selectIndex > 0 and selectIndex <= #distributeTypeList then
                    local distributeType = distributeTypeList[selectIndex]
                    if distributeType then
                        self._Model:SaveSettlePointByDistributeType(
                            distributeType,
                            arenaResult.Point,
                            arenaResult.OldArenaMaxPoint
                        )
                    end
                end
            end
        end
    end
    
    self._FightSettleDataCache = winData
end

function XArenaAgency:OnBehaviorDoExitFight(event, args)
    if not args or args.Length <= 0 then
        return
    end
    
    -- C#数组，从0开始
    local stageId = args[0]
    
    -- 检查是否是 Arena 的关卡
    if not self:CheckIsArenaStage(stageId) then
        return
    end
    
    self:_OpenRewardUi(self._FightSettleDataCache)
    self._FightSettleDataCache = nil
end

function XArenaAgency:_OpenRewardUi(winData)
    XMVCA.XFuben:SetMouseVisible()

    if XMVCA.XFuben:CheckHasFlopReward(winData) then
        XLuaUiManager.Open("UiFubenFlopReward", function()
            XLuaUiManager.PopThenOpen("UiArenaSettlement", winData)
        end, winData)
    else
        XLuaUiManager.Open("UiArenaSettlement", winData)
    end
end

--- 为独立判断关卡解锁增加的Handler（参考 XFubenBossSingleAgency，对应 ProcessFunc.CheckUnlockByStageId）
function XArenaAgency:CheckUnlockByStageId(stageId)
    -- 普通模式返回 nil，使用默认逻辑
    return nil
end

--- 检查是否自动退出战斗（参考 XFubenBossSingleAgency.CheckAutoExitFight，对应 ProcessFunc.CheckAutoExitFight）
---@param stageId number 关卡ID
---@return boolean 是否自动退出
function XArenaAgency:CheckAutoExitFight(stageId)
    -- 战区不需要自动退出战斗
    return false
end

--- 退出战斗（参考 XFubenBossSingleAgency.ExitFight）
function XArenaAgency:ExitFight()
    CS.XFight.ExitForClient(true)
    XEventManager.DispatchEvent(XEventId.EVENT_ARENA_HIDE_SETTLE)
end

--- 处理战斗结算奖励事件（参考 XFubenBossSingleAgency 的 EVENT_FUBEN_SETTLE_REWARD 处理）
---@param settleData table 结算数据
---@param res table 结算响应
function XArenaAgency:OnFightSettle(settleData, res)
    -- 其他副本的战斗也会进这里, 所以需要检查是否是 Arena 的关卡
    if not res then
        return
    end

    if not settleData then
        return
    end

    local stageId = settleData.StageId
    if not stageId then
        return
    end

    -- 检查是否是 Arena 的关卡
    if not self:CheckIsArenaStage(stageId) then
        return
    end
    
    if res.Code ~= XCode.Success then
        XLog.Error("[XArenaAgency] 结算结果失败: ", res.Code)
        CS.XFight.ExitForClient(true)
        return
    end

    if settleData.IsWin then
        -- 胜利：显示结算界面（参考 XTransfiniteManager 的实现）
        local beginData = XMVCA.XFuben:GetFightBeginData()
        local winData = XMVCA.XFuben:GetChallengeWinData(beginData, settleData)
        self:_ShowReward(winData)
    else
        -- 失败：退出战斗（使用默认的失败处理）
        -- 注意：这里不直接调用 ChallengeLose，因为 FinishFight 已经处理了失败逻辑
    end
end

-- endregion

-- region Other

-- 获取当前挑战任务
function XArenaAgency:GetCurrentChallengeTasks()
    local tasks = {}

    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local challengeId = activityData:GetChallengeId()
        local dailyTasks = XDataCenter.TaskManager.GetArenaChallengeTaskList()
        local taskIds = self:GetChallengeTaskIds(activityData, challengeId)
        if not XTool.IsTableEmpty(taskIds) then
            for _, taskId in pairs(taskIds) do
                for _, dailyTask in pairs(dailyTasks) do
                    if taskId == dailyTask.Id then
                        table.insert(tasks, dailyTask)
                    end
                end
            end
        end
    end

    return tasks
end

function XArenaAgency:GetChallengeTaskIds(activityData, challengeId)
    local taskIds = self._Model:GetChallengeAreaTaskIdByChallengeId(challengeId)
    return taskIds
end

function XArenaAgency:GetActivityCurrentLevel()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetArenaLevel()
    end

    return 0
end

function XArenaAgency:GetActivityCurrentChallengeId()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetChallengeId()
    end

    return 0
end

function XArenaAgency:GetActivityNo()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetActivityNo()
    end

    return 0
end

function XArenaAgency:GetActivityStatus()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetStatus()
    end

    return 0
end

function XArenaAgency:GetActivityIsJoin()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetIsJoinActivity()
    end

    return 0
end

function XArenaAgency:GetEnterAreaStageNameInfo()
    local areaId = self:GetCurrentAreaId()
    local stageName = ""
    local chapterName = ""

    if XTool.IsNumberValid(areaId) then
        local selectIndex = self._Model:GetCurrentSelectFightBuffIndex()
        local buffNameList = self._Model:GetAreaStageBuffNameById(areaId)

        if selectIndex and buffNameList then
            stageName = buffNameList[selectIndex] or ""
        end
    end

    return chapterName, stageName
end

function XArenaAgency:IsArenaCanEnterFight()
    if self._Model:CheckHasActivityData() then
        local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenArena)
        local activityData = self._Model:GetActivityData()

        return isOpen and activityData:GetStatus() == XEnumConst.Arena.ActivityStatus.Fight
    end

    return false
end

function XArenaAgency:GetContributeScoreItemId()
    return self._Model:GetContributeScoreItemId()
end

function XArenaAgency:GetContributeScore()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetContributeScore()
    end
end

function XArenaAgency:GetArenaLevelNameByLevel(level)
    return self._Model:GetArenaLevelNameById(level)
end

function XArenaAgency:GetArenaLevelIconByLevel(level)
    return self._Model:GetArenaLevelIconById(level)
end

function XArenaAgency:GetActivityCountDownTimerKey()
    return "FubenArenaActivityTimer"
end

function XArenaAgency:GetActivityRemainTimeStr()
    local timeText = ""

    if self._Model:CheckHasActivityData() then
        local activityData = self._Model:GetActivityData()
        local nextStatusTime = activityData:GetNextStatusTime()
        local remainTime = nextStatusTime - XTime.GetServerNowTimestamp()
        local state = activityData:GetStatus()

        if state == XEnumConst.Arena.ActivityStatus.Rest then
            timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        elseif state == XEnumConst.Arena.ActivityStatus.Fight then
            timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        elseif state == XEnumConst.Arena.ActivityStatus.Over then
            local stopResetTime = activityData:GetStopResetTime()

            if stopResetTime and XTool.IsNumberValid(stopResetTime.EndTime)
                and XTool.IsNumberValid(stopResetTime.StartTime) then
                local endTime = stopResetTime.EndTime
                local beginTime = stopResetTime.StartTime
                local nowTime = XTime.GetServerNowTimestamp()

                if nowTime >= beginTime and nowTime <= endTime then
                    remainTime = endTime - nowTime
                end
            end

            timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        end
    end

    return timeText
end

function XArenaAgency:SetIsRefreshMainPage(isRefresh)
    self._Model:SetIsRefreshMainPage(isRefresh)
end

function XArenaAgency:GetCurrentAreaCount()
    return self._Model:GetCurrentAreaCount()
end

function XArenaAgency:GetCurrentAreaId()
    return self._Model:GetCurrentEnterAreaId() or 0
end

function XArenaAgency:GetCurrentFightBuffId()
    local areaId = self:GetCurrentAreaId()
    local buffIndex = self._Model:GetCurrentSelectFightBuffIndex()
    local buffIds = self._Model:GetAreaStageBuffIdById(areaId)

    if not XTool.IsTableEmpty(buffIds) then
        return buffIds[buffIndex] or 0
    end

    return 0
end

function XArenaAgency:GetCurrentFightEventGroupId()
    return self._Model:GetCurrentFightEventGroupId() or 0
end

-- endregion

-- region Check

function XArenaAgency:CheckRunMainWhenFightOver()
    if not XLuaUiManager.IsUiLoad("UiArenaNew") then
        return false
    end

    if not self._Model:GetIsInFightChangeActivityStatus() then
        return false
    end

    self._Model:SetIsInFightChangeActivityStatus(false)
    XUiManager.TipText("ArenaActivityStatusChange")
    XLuaUiManager.RunMain()

    return true
end

function XArenaAgency:CheckOpenActivityResultUi(isInActivityOpen)
    if self._Model:CheckHasActivityResultData() then
        if isInActivityOpen then
            XLuaUiManager.Open("UiArenaActivityResult", self._Model:GetActivityResultData())
        else
            XLuaUiManager.Open("UiArenaActivityResult", self._Model:GetActivityResultData(), function()
                XEventManager.DispatchEvent(XEventId.EVENT_ARENA_RESULT_CLOSE)
            end)
        end

        return true
    end

    return false
end

function XArenaAgency:CheckIsArenaStage(stageId)
    local stageConfig = XMVCA.XFuben:GetStageCfg(stageId)
    if not stageConfig then
        return false
    end
    
    return stageConfig.Type == XEnumConst.FuBen.StageType.Arena
end

function XArenaAgency:CheckIsSpecialAreaNumber(number)
    return number == self:GetCurrentAreaCount()
end

-- endregion

-- region Private/Protected

function XArenaAgency:_JudgeToRunMain()
    if not XLuaUiManager.IsUiLoad("UiArenaNew") then
        return
    end

    local activityData = self._Model:GetActivityData()

    if not activityData or activityData:IsClear() then
        return
    end

    local status = activityData:GetStatus()

    if status == XEnumConst.Arena.ActivityStatus.Loading or status == XEnumConst.Arena.ActivityStatus.Default then
        return
    end

    -- 如果玩家在竞技战斗中 先做缓存
    if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
        self._Model:SetIsInFightChangeActivityStatus(true)
        return
    end

    -- 如果玩家在好友宿舍中 退出宿舍
    if XLuaUiManager.IsUiLoad("UiDormSecond") then
        XHomeSceneManager.LeaveScene()
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_CLOSE_COMPONET)
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        XDataCenter.GuideManager.ResetGuide()
    end

    XUiManager.TipText("ArenaActivityStatusChange")
    XLuaUiManager.RunMain()
end

function XArenaAgency:_SaveActivityNo()
    local activityData = self._Model:GetActivityData()

    if not activityData or activityData:IsClear() then
        return
    end

    local activityNo = activityData:GetActivityNo()
    local oldNo = XSaveTool.GetData(self:_GetArenaActivityNoSaveKey())

    if activityNo ~= oldNo then
        self._Model:ClearSettlePointCacheByActivityNo(oldNo)  -- 跨期清除旧期结算缓存
        XSaveTool.SaveData(self:_GetArenaActivityNoSaveKey(), activityNo)
        XSaveTool.SaveData(self:_GetArenaClearSelectBuffSaveKey(), true)
    end
end

function XArenaAgency:_GetArenaActivityNoSaveKey()
    return "ARENA_ACTIVITY_NO_" .. XPlayer.Id
end

function XArenaAgency:_GetArenaClearSelectBuffSaveKey()
    return "ARENA_CLEAR_STAGE_SELECT_BUFF_" .. XPlayer.Id
end

-- endregion

function XArenaAgency:CheckInStatus(status)
    local currentStatus = self._Model:GetStatus()
    return currentStatus == status
end

--- 获取 Debug 模式下的胜利数据（参考 XFubenBossSingleAgency:GetDebugWinData）
---@return table|nil
function XArenaAgency:GetDebugWinData()
    return self._DebugWinData
end

return XArenaAgency
