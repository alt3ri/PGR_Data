local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XConcertPreHeatingAgency : XFubenActivityAgency
---@field private _Model XConcertPreHeatingModel
local XConcertPreHeatingAgency = XClass(XFubenActivityAgency, "XConcertPreHeatingAgency", false)

local LiveState = XEnumConst.ConcertPreHeating.LiveState
local CHAT_TOAST_SHOW_SECONDS = 24 * 60 * 60

function XConcertPreHeatingAgency:OnInit()
    self:RegisterActivityAgency()
end

function XConcertPreHeatingAgency:InitRpc()
    self:AddRpc("NotifyConcertPreHeating", handler(self, self.OnNotifyConcertPreHeating))
    self:AddRpc("NotifyConcertVideoConfig", handler(self, self.OnNotifyConcertVideoConfig))
end

--region ----------public start----------

function XConcertPreHeatingAgency:OpenMainUi()
    if not self:IsActivityOpen() then
        XUiManager.TipText("ActivityBranchNotOpen")
        return
    end

    XLuaUiManager.Open("UiConcertPreHeatingMain")
end

-- UiActivityChapter入口使用：没有服务端活动数据时不展示入口。
function XConcertPreHeatingAgency:ExCheckInTime()
    return self:IsActivityOpen()
end

function XConcertPreHeatingAgency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

---@return XTableConcertPreHeatingActivity
function XConcertPreHeatingAgency:GetCurActivityCfg()
    return self._Model:GetActivityCfg(self:GetCurActivityId())
end

function XConcertPreHeatingAgency:IsActivityOpen()
    local activityCfg = self:GetCurActivityCfg()
    if not activityCfg then
        return false
    end

    return self:_CheckActivityTimeOpen(activityCfg)
end

function XConcertPreHeatingAgency:GetActivityEndTime()
    local activityCfg = self:GetCurActivityCfg()
    if not activityCfg or not XTool.IsNumberValid(activityCfg.TimeId) then
        return 0
    end

    return XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId) or 0
end

function XConcertPreHeatingAgency:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

-- 活动主界面 TxtTime 使用：活动起止日期文案。
function XConcertPreHeatingAgency:GetActivityTimeText()
    local activityCfg = self:GetCurActivityCfg()
    if not activityCfg or not XTool.IsNumberValid(activityCfg.TimeId) then
        return
    end

    local startTime = XFunctionManager.GetStartTimeByTimeId(activityCfg.TimeId) or 0
    local endTime = XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId) or 0
    if startTime <= 0 or endTime <= 0 then
        return
    end

    return XUiHelper.GetText("ActivityBriefFightTime", XTime.TimestampToGameDateTimeString(startTime, "MM/dd"), XTime.TimestampToGameDateTimeString(endTime, "MM/dd"))
end

-- 活动主界面页签列表使用：当前活动配置的关卡顺序。
function XConcertPreHeatingAgency:GetStageIds()
    local activityCfg = self._Model:GetActivityCfg(self._Model:GetCurActivityId())
    return activityCfg and activityCfg.StageIds or {}
end

function XConcertPreHeatingAgency:IsStageOpen(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return false
    end

    return not XTool.IsNumberValid(stageCfg.TimeId) or XFunctionManager.CheckInTimeByTimeId(stageCfg.TimeId)
end

-- 活动主界面倒计时使用：主表现关是否已完成。
function XConcertPreHeatingAgency:IsMainPerformanceStageFinished()
    for _, stageId in ipairs(self:GetStageIds()) do
        if self._Model:GetStageCfg(stageId).IsMainPerformance == true then
            return self._Model:GetFinishedStageIdMap()[stageId] == true
        end
    end

    return false
end

-- UiActivityChapter入口 TxtConsumeCount 使用：自定义进度文本。
function XConcertPreHeatingAgency:ExGetProgressTip()
    local stageIds = self:GetStageIds()
    local finishedCount = 0
    local finishedStageIdMap = self._Model:GetFinishedStageIdMap()
    for _, stageId in ipairs(stageIds) do
        if finishedStageIdMap[stageId] == true then
            finishedCount = finishedCount + 1
        end
    end

    return finishedCount .. "/" .. #stageIds
end

-- 活动主界面页签点击使用：保存玩家当前展示关卡。
function XConcertPreHeatingAgency:SaveSelectStageId(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end

    XSaveTool.SaveData(self:_GetSelectStageSaveKey(), stageId)
end

-- 活动主界面进入使用：读取玩家上次展示关卡。
function XConcertPreHeatingAgency:GetLocalSelectStageId()
    return XSaveTool.GetData(self:_GetSelectStageSaveKey()) or 0
end

-- 入口/页签蓝点使用：关卡开放后，玩家未查看前提示一次。
function XConcertPreHeatingAgency:CheckStageIsNew(stageId)
    if not XTool.IsNumberValid(stageId) or not self:IsActivityOpen() then
        return false
    end

    if not self:IsStageOpen(stageId) then
        return false
    end

    if self._Model:GetFinishedStageIdMap()[stageId] == true then
        return false
    end

    return XSaveTool.GetData(self:_GetStageNewSaveKey(stageId)) ~= true
end

function XConcertPreHeatingAgency:CheckAnyStageIsNew()
    for _, stageId in ipairs(self:GetStageIds()) do
        if self:CheckStageIsNew(stageId) then
            return true
        end
    end

    return false
end

function XConcertPreHeatingAgency:MarkStageNewRead(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end

    local saveKey = self:_GetStageNewSaveKey(stageId)
    if XSaveTool.GetData(saveKey) == true then
        return
    end

    XSaveTool.SaveData(saveKey, true)
    XEventManager.DispatchEvent(XEventId.EVENT_CONCERT_PRE_HEATING_RED_POINT_UPDATE)
end

function XConcertPreHeatingAgency:ExCheckIsShowRedPoint()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_CONCERT_PRE_HEATING_MAIN)
end

-- UiMain入口/活动主界面任务按钮使用：活动任务组。
function XConcertPreHeatingAgency:GetTaskGroupId()
    local activityCfg = self:GetCurActivityCfg()
    return activityCfg and activityCfg.TaskGroupId or 0
end

-- UiMain入口/活动主界面任务按钮使用：是否有任务奖励可领。
function XConcertPreHeatingAgency:CheckHasTaskReward()
    local taskGroupId = self:GetTaskGroupId()
    if not XTool.IsNumberValid(taskGroupId) then
        return false
    end

    return XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
end

-- 活动主界面奖励气泡使用：取一个可展示的任务奖励。
function XConcertPreHeatingAgency:GetTaskRewardPreview()
    local taskGroupId = self:GetTaskGroupId()
    if not XTool.IsNumberValid(taskGroupId) then
        return nil, false
    end

    local firstReward
    local isFirstRewardReceived = false
    local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId, true)

    for _, taskData in ipairs(taskDataList or {}) do
        local reward = self:_GetTaskPreviewRewardItem(taskData)
        if reward then
            local isReceived = taskData.State == XDataCenter.TaskManager.TaskState.Finish
            if not firstReward then
                firstReward = reward
                isFirstRewardReceived = isReceived
            end

            if not isReceived then
                return reward, false
            end
        end
    end

    return firstReward, isFirstRewardReceived
end

-- UiMain入口标签/活动主界面倒计时使用：归一化直播状态。
function XConcertPreHeatingAgency:GetLiveState()
    local config = self:_GetLiveStateVideoConfig()
    if not config then
        return { State = LiveState.None }
    end

    local now = XTime.GetServerNowTimestamp()
    local liveStartTime = XTool.IsNumberValid(config.LiveTimeId)
        and (XFunctionManager.GetStartTimeByTimeId(config.LiveTimeId) or 0)
        or 0
    local liveEndTime = XTool.IsNumberValid(config.LiveTimeId)
        and (XFunctionManager.GetEndTimeByTimeId(config.LiveTimeId) or 0)
        or 0
    local recordStartTime = XTool.IsNumberValid(config.RecordTimeId)
        and (XFunctionManager.GetStartTimeByTimeId(config.RecordTimeId) or 0)
        or 0
    local isLive = XTool.IsNumberValid(config.LiveTimeId) and XFunctionManager.CheckInTimeByTimeId(config.LiveTimeId)
    local isRecordOpen = XTool.IsNumberValid(config.RecordTimeId)
        and XFunctionManager.CheckInTimeByTimeId(config.RecordTimeId)

    if isLive then
        return {
            State = LiveState.Live,
            Url = config.LiveUrl,
            LeftTime = math.max(liveEndTime - now, 0),
            StartTime = liveStartTime,
            EndTime = liveEndTime,
            Config = config,
        }
    end

    if liveStartTime > 0 and now < liveStartTime then
        return {
            State = LiveState.BeforeLive,
            Url = config.LiveUrl,
            LeftTime = liveStartTime - now,
            StartTime = liveStartTime,
            Config = config,
        }
    end

    if liveEndTime > 0 and now >= liveEndTime then
        return {
            State = LiveState.Replay,
            Url = config.RecordUrl,
            RecordStartTime = recordStartTime,
            IsRecordOpen = isRecordOpen,
            Config = config,
        }
    end

    return { State = LiveState.None, Config = config }
end

-- 活动主界面 PanelBeforeStart 使用：直播开始前。
function XConcertPreHeatingAgency:IsBeforeLive(liveState)
    return liveState and liveState.State == LiveState.BeforeLive
end

-- 活动主界面 PanelLive 使用：直播进行中。
function XConcertPreHeatingAgency:IsLive(liveState)
    return liveState and liveState.State == LiveState.Live
end

-- 活动主界面 PanelCountdown 使用：直播结束后进入回放态。
function XConcertPreHeatingAgency:IsReplay(liveState)
    return liveState and liveState.State == LiveState.Replay
end

-- 活动主界面录播按钮使用：录播链接是否已开放。
function XConcertPreHeatingAgency:IsReplayOpen(liveState)
    return self:IsReplay(liveState) and liveState.IsRecordOpen == true
end

-- 活动主界面 GotoLive 使用：直播前 10 分钟内点亮入口。
function XConcertPreHeatingAgency:IsLiveSoon(liveState)
    return self:IsBeforeLive(liveState) and (liveState.LeftTime or 0) <= 10 * 60
end

-- 活动主界面倒计时文本使用：时分秒。
function XConcertPreHeatingAgency:GetLiveCountDownText(liveState)
    return XUiHelper.GetTime(math.max(liveState and liveState.LeftTime or 0, 0), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
end

-- 活动主界面倒计时文本使用：距音乐会还有 N 天。
function XConcertPreHeatingAgency:GetLiveDayText(liveState)
    return XUiHelper.GetText("ConcertPreHeatingLiveDayText", math.max(math.ceil((liveState and liveState.LeftTime or 0) / 86400), 1))
end

-- 活动主界面未开放 toast 使用：直播开始时间。
function XConcertPreHeatingAgency:GetLiveStartTimeText(liveState)
    local startTime = liveState and liveState.StartTime or 0
    if not XTool.IsNumberValid(startTime) then
        return ""
    end

    return XTime.TimestampToGameDateTimeString(startTime, "yyyy/MM/dd HH:mm:ss")
end

-- UiMain入口标签使用：音乐会是否直播中。
function XConcertPreHeatingAgency:CheckActivityEntryLive()
    return self:GetLiveState().State == LiveState.Live
end

-- 聊天界面音乐会提示使用：是否显示直播入口。
function XConcertPreHeatingAgency:GetChatToastLiveState()
    if not self:IsActivityOpen() then
        return false
    end

    local liveState = self:GetLiveState()
    if self:IsBeforeLive(liveState) then
        return (liveState.LeftTime or 0) <= CHAT_TOAST_SHOW_SECONDS, liveState
    end

    if self:IsLive(liveState) then
        return true, liveState
    end

    if liveState and liveState.State == LiveState.None then
        XLog.Error("【音乐会预热】聊天提示缺少直播配置，无法显示")
    end

    return false, liveState
end

-- 聊天界面音乐会提示使用：距离进入显示窗口的秒数。
function XConcertPreHeatingAgency:GetChatToastShowWaitSeconds(liveState)
    if not self:IsBeforeLive(liveState) then
        return 0
    end

    return math.max((liveState.LeftTime or 0) - CHAT_TOAST_SHOW_SECONDS, 0)
end

-- 聊天界面音乐会提示使用：成功跳转直播后打点。
function XConcertPreHeatingAgency:BuryingChatLiveJump()
    CS.XRecord.Record("1000047", "ConcertPreHeatingChatLiveJump")
end

-- 调音关卡完成结算埋点。
function XConcertPreHeatingAgency:BuryingStageSettle(stageId, fightTime)
    local dict = {}
    dict["i_stage_id"] = stageId
    dict["i_fight_time"] = fightTime
    CS.XRecord.Record(dict, "1000045", "ConcertPreHeatingStageSettle")
end

-- UiMain入口/活动主界面直播按钮使用：打开外部链接。
function XConcertPreHeatingAgency:OpenLiveUrl(liveState)
    local url = liveState and liveState.Url
    if url and url ~= "" then
        CS.UnityEngine.Application.OpenURL(liveState.Url)
        return true
    end

    return false
end

-- 直播入口使用：按直播状态打开链接或给出提示。
function XConcertPreHeatingAgency:OpenLiveUrlWithTips(liveState, allowReplay)
    if not self:IsActivityOpen() then
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end

    liveState = liveState or self:GetLiveState()
    if self:IsBeforeLive(liveState) and not self:IsLiveSoon(liveState) then
        local startTimeText = self:GetLiveStartTimeText(liveState)
        XUiManager.TipText("ConcertPreHeatingLiveNotOpen", nil, nil, startTimeText)
        return false
    end

    if self:IsReplay(liveState) and not allowReplay then
        return false
    end

    if self:IsReplay(liveState) and not self:IsReplayOpen(liveState) then
        XUiManager.TipText("ConcertPreHeatingReplayNotOpen")
        return false
    end

    if not self:IsLive(liveState) and not self:IsLiveSoon(liveState) and not self:IsReplay(liveState) then
        return false
    end

    if not self:OpenLiveUrl(liveState) then
        XUiManager.TipText("ConcertPreHeatingLiveUrlEmpty")
        return false
    end

    return true
end

function XConcertPreHeatingAgency:ConcertPreHeatingStartRequest(stageId, cb)
    XNetwork.Call("ConcertPreHeatingStartRequest", { StageId = stageId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res)
        end
    end)
end

function XConcertPreHeatingAgency:ConcertPreHeatingSettleRequest(stageId, fightTime, cb)
    XNetwork.Call("ConcertPreHeatingSettleRequest", { StageId = stageId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:RefreshActivityData(res)
        self:BuryingStageSettle(stageId, fightTime)
        XEventManager.DispatchEvent(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE)

        if cb then
            cb(res)
        end
    end)
end

--endregion ----------public end----------

--region ----------private start----------

function XConcertPreHeatingAgency:OnNotifyConcertPreHeating(data)
    if XTool.IsTableEmpty(data) then
        return
    end

    self._Model:RefreshActivityData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE)
end

function XConcertPreHeatingAgency:OnNotifyConcertVideoConfig(data)
    if XTool.IsTableEmpty(data) then
        return
    end

    self._Model:RefreshServerVideoConfigs(data)
    XEventManager.DispatchEvent(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE)
end

function XConcertPreHeatingAgency:_CheckActivityTimeOpen(activityCfg)
    if not activityCfg then
        return false
    end

    return not XTool.IsNumberValid(activityCfg.TimeId) or XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId)
end

-- 服务端 NotifyConcertVideoConfig 直接推完整视频配置；没有推送时才读本地表兜底。
function XConcertPreHeatingAgency:_GetLiveStateVideoConfig()
    local serverConfig = self:_GetLowestIdVideoConfig(self._Model:GetServerVideoConfigMap())
    if serverConfig then
        return serverConfig
    end

    return self:_GetLowestIdVideoConfig(self._Model:GetAllVideoConfigCfgs())
end

function XConcertPreHeatingAgency:_GetLowestIdVideoConfig(videoConfigs)
    local lowestId = 0
    local result

    for id, config in pairs(videoConfigs or {}) do
        local configId = config.Id or id
        if XTool.IsNumberValid(configId)
            and (not XTool.IsNumberValid(lowestId) or configId < lowestId)
        then
            lowestId = configId
            result = config
        end
    end

    return result
end

function XConcertPreHeatingAgency:_GetTaskPreviewRewardItem(taskData)
    if not taskData or not XTool.IsNumberValid(taskData.Id) then
        return nil
    end

    local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
    local rewardList = taskCfg and XRewardManager.GetRewardList(taskCfg.RewardId)
    return not XTool.IsTableEmpty(rewardList) and rewardList[1] or nil
end

function XConcertPreHeatingAgency:_GetSelectStageSaveKey()
    return "XConcertPreHeatingSelectStageId_" .. XPlayer.Id .. "_" .. self:GetCurActivityId()
end

function XConcertPreHeatingAgency:_GetStageNewSaveKey(stageId)
    return "XConcertPreHeatingStageNew_" .. XPlayer.Id .. "_" .. self:GetCurActivityId() .. "_" .. stageId
end

--endregion ----------private end----------

return XConcertPreHeatingAgency
