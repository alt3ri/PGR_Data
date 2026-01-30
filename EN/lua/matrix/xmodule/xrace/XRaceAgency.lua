local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

---@class XRaceAgency : XFubenActivityAgency
---@field private _Model XRaceModel
local XRaceAgency = XClass(XFubenActivityAgency, "XRaceAgency")

function XRaceAgency:OnInit()
    self._IsEnterScene = false
    self._WaitTimers = {}
    self:RegisterActivityAgency()
end

function XRaceAgency:InitRpc()
    XRpc.NotifyRacePlayerDataDb = handler(self, self.NotifyRacePlayerDataDb)
    XRpc.NotifyRaceRoundConfig = handler(self, self.NotifyRaceRoundConfig) --RaceRound表被放到etcd里面（热更） 客户端读不到 由服务端下发
    XRpc.NotifyRaceRoundStart = handler(self, self.NotifyRaceRoundStart)
    XRpc.NotifyRaceRoundEnd = handler(self, self.NotifyRaceRoundEnd)
end

function XRaceAgency:InitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self.CheckOpenMainTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_ENABLE, self.CheckOpenChatTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.CloseChatTip, self)
end

function XRaceAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self.CheckOpenMainTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UICHAT_ENABLE, self.CheckOpenChatTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.CloseChatTip, self)
end

function XRaceAgency:ResetAll()
    for _, timerId in pairs(self._WaitTimers) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._WaitTimers = {}
    self._IsEnterScene = false
end

----------public start----------

function XRaceAgency:GetCurrentConfig()
    if not self._Model.ActivityId then
        return nil
    end
    return self._Model:GetActivityById(self._Model.ActivityId)
end

function XRaceAgency:IsInActivity()
    local activity = self:GetCurrentConfig()
    if activity then
        return XFunctionManager.CheckInTimeByTimeId(activity.TimeId) and self._Model:IsExistEtcdConfig()
    end
    return false
end

function XRaceAgency:OpenMain()
    local emptyReq = {}
    XNetwork.CallWithAutoHandleErrorCode("RaceGetMainPlainRequest", emptyReq, function(res)
        self._Model:UpdateBasePlayerData(res.RaceDataDb, res.RoundId)
        XNetwork.CallWithAutoHandleErrorCode("RaceGetAllRoundResultRequest", emptyReq, function(res)
            self._Model:UpdateAllRoundResult(res)
            XLuaUiManager.Open("UiRaceMain")
        end)
    end)
end

function XRaceAgency:IsGamePlaying()
    local roundId = self._Model:GetCurRound()
    if roundId ~= -1 then
        local etcd = self._Model:GetEtcdRoundConfig(roundId)
        if etcd then
            return etcd.StartTimeLong < XTime.GetServerNowTimestamp()
        end
    end
    return false
end

--region 场景相关--------------------------------------------------
function XRaceAgency:OpenLoading(maxPercentage, time)
    if self._IsShowLoading then return end
    self._IsShowLoading = true
    XLuaUiManager.Open("UiRaceFightLoading")
end

function XRaceAgency:CloseLoading()
    if not self._IsShowLoading then return end
    XLuaUiManager.Close("UiRaceFightLoading")
    self._IsShowLoading = false
end

function XRaceAgency:IsEnterScene()
    return self._IsEnterScene
end

-- 进入场景
function XRaceAgency:EnterMatchScene(...)
    if self._IsEnterScene then return end
    self._IsEnterScene = true
    self:OpenLoading()
    XMVCA.XScene:LoadScene(SceneIds.XRaceScene, true, nil, nil, ...)
end

-- 离开场景
function XRaceAgency:LeaveMatchScene()
    XMVCA.XScene:ExitScene(SceneIds.XRaceScene)
    self._IsEnterScene = false
end

function XRaceAgency:GetRaceStartTime()
    local roundId = self._Model:GetCurRound()
    if roundId == -1 then
        return -1
    end
    local etcd = self._Model:GetEtcdRoundConfig(roundId)
    if not etcd then
        return -1
    end
    return etcd.StartTimeLong
end

--endregion

----------public end----------

----------副本扩展----------

function XRaceAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return false
    end
    -- 打开主界面
    self:OpenMain()
    return true
end

function XRaceAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XRaceAgency:ExGetProgressTip()
    return ""
end

function XRaceAgency:ExGetRunningTimeStr()
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local timeId = self:GetActivityTimeId()
        local gameEndTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("RaceResetTime", timeStr)
    else
        return XUiHelper.GetText("RaceActivityEnd")
    end
end

function XRaceAgency:ExGetRightMidCustomText()
    if not self:GetIsOpen(true) then
        return nil
    end
    local roundId = self._Model:GetCurRound()
    if roundId == -1 then
        return nil
    end
    local etcd = self._Model:GetEtcdRoundConfig(roundId)
    local leftTime = etcd.StartTimeLong - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        return XUiHelper.GetText("RaceRightMidRunning")
    end
    local leftMinute = math.ceil(leftTime / 60)
    if leftMinute > self._Model:GetMainRightMidShowTime() then
        return nil
    end
    return XUiHelper.GetText("RaceRightMidStartTime", leftMinute)
end

---活动是否开启
function XRaceAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Race, false, noTips) then
        return false
    end
    if not self:IsInActivity() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XRaceAgency:GetActivityTimeId()
    if not self._Model.ActivityId then
        return 0
    end
    return self._Model:GetActivityById(self._Model.ActivityId).TimeId
end

---检查是否处于活动的游戏时间
function XRaceAgency:CheckActivityIsInGameTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XRaceAgency:FinishFight(settleData)

end

----------副本扩展 end----------

----------private start----------

function XRaceAgency:NotifyRacePlayerDataDb(data)
    self._Model:NotifyRacePlayerDataDb(data)
    if self._Model._EtcdRoundConfigs then
        self:CheckOpenMainTip()
    end
end

function XRaceAgency:NotifyRaceRoundConfig(data)
    self._Model:NotifyRaceRoundConfig(data)
    if self._Model._CurRoundId then
        self:CheckOpenMainTip()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RACE_TIME_UPDATE)
end

function XRaceAgency:IsRunninghMatch()
    if self._IsRunningMatch == nil then
        return XTime.GetServerNowTimestamp() >= self:GetRaceStartTime()
    end
    return self._IsRunningMatch
end

function XRaceAgency:NotifyRaceRoundStart(data)
    if not self:GetIsOpen(true) then
        return
    end
    self._IsRunningMatch = true
    self._Model:NotifyRaceRoundStart(data)
    XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_START)
end

function XRaceAgency:NotifyRaceRoundEnd(data)
    if not self:GetIsOpen(true) then
        return
    end
    self._IsRunningMatch = false
    self._Model:SetRoleRandomSite(nil)
    if self:IsEnterScene() then
        XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_END_IN_SCENE, data.RoundId)
        return --走局内的结算逻辑
    end
    XNetwork.CallWithAutoHandleErrorCode("RaceGetAllRoundResultRequest", {}, function(res)
        self._Model:UpdateAllRoundResult(res)
        XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_END, data.RoundId)
    end)
end

--region 飘字

-- UiMain的OnEnable时机可能比协议下发快
function XRaceAgency:CheckOpenMainTip()
    local inMainUi = XLuaUiManager.IsUiShow("UiMain") and XLuaUiManager.GetTopUiName() == "UiMain"
    if not inMainUi then
        return
    end
    if XLuaUiManager.IsUiLoad("UiChatServeMain") then
        -- 避免从聊天横幅跳转活动主界面，然后点返回按钮时，同时出现2个横幅导致层级出问题
        return
    end
    self:CheckTip(XEnumConst.Race.Tip.Main)
end

function XRaceAgency:CheckOpenChatTip()
    local inMainUi = XLuaUiManager.IsUiShow("UiChatServeMain") and XLuaUiManager.GetTopUiName() == "UiChatServeMain"
    if not inMainUi then
        return
    end
    self:CheckTip(XEnumConst.Race.Tip.Chat)
end

function XRaceAgency:CheckTip(tipType)
    local timer = self._WaitTimers[tipType]
    if timer then
        XScheduleManager.UnSchedule(timer)
        self._WaitTimers[tipType] = nil
    end
    if not self:GetIsOpen(true) then
        return
    end
    local configs = self._Model:GetSortBroadcasts(tipType)
    if XTool.IsTableEmpty(configs) then
        return
    end
    local roundId = self._Model:GetCurRound()
    if not roundId or roundId == -1 then
        return
    end
    local etcd = self._Model:GetEtcdRoundConfig(roundId)
    if not etcd then
        XLog.Error(string.format("【赛马】检查播报时找不到RoundId=%s的etcd配置", roundId))
        return
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = etcd.StartTimeLong
    local leftMinute = math.max(startTime - nowTime, 0) / 60
    local maxBeforeTime = configs[#configs].BeforeTime
    if leftMinute > maxBeforeTime then
        --还未到飘横幅的时候
        self:DoCountDown(tipType, startTime, maxBeforeTime)
    else
        for i, v in ipairs(configs) do
            if leftMinute <= v.BeforeTime then
                if v.IsStill or not self._Model:IsTipHasShow(tipType, v.Id) then
                    if self:IsTipShowing(tipType) then
                        XEventManager.DispatchEvent(XEventId.EVENT_RACE_TOAST_HALL_UPDATE, v, tipType)
                    else
                        --不能打开2个同名的Ui界面
                        if tipType == XEnumConst.Race.Tip.Main then
                            local isChatShow = XLuaUiManager.IsUiShow("UiChatServeMain")
                            if not isChatShow then
                                self:SetTipShowing(tipType, true)
                                XLuaUiManager.Open("UiRaceToastHall", v, tipType)
                            end
                        else
                            self:SetTipShowing(tipType, true)
                            XLuaUiManager.Open("UiRaceToastHallChat", v, tipType)
                        end
                    end
                end
                -- 倒计时显示下一条播报
                if i > 1 then
                    self:DoCountDown(tipType, startTime, configs[i - 1].BeforeTime)
                end
                return
            end
        end
    end
end

function XRaceAgency:DoCountDown(tipType, startTime, beforeTime)
    local nextTime = startTime - beforeTime * 60
    local waitTime = (nextTime - XTime.GetServerNowTimestamp()) * 1000
    self._WaitTimers[tipType] = XScheduleManager.ScheduleOnce(function()
        self:CheckTip(tipType)
    end, waitTime)
end

--todo 停服公告出现时隐藏
function XRaceAgency:CloseMainTip()
    self:CloseTip(XEnumConst.Race.Tip.Main)
end

function XRaceAgency:CloseChatTip()
    self:CloseTip(XEnumConst.Race.Tip.Chat)
    self:CheckTip(XEnumConst.Race.Tip.Main)
end

function XRaceAgency:CloseTip(tipType)
    local timer = self._WaitTimers[tipType]
    if timer then
        XScheduleManager.UnSchedule(timer)
        self._WaitTimers[tipType] = nil
    end
end

---横幅是否正在显示
function XRaceAgency:SetTipShowing(tipType, isShowing)
    if not self._TipShowDict then
        self._TipShowDict = {}
    end
    self._TipShowDict[tipType] = isShowing
end

function XRaceAgency:IsTipShowing(tipType)
    return self._TipShowDict and self._TipShowDict[tipType]
end

function XRaceAgency:SetTipShow(tipType, id)
    self._Model:SetTipShow(tipType, id)
end

--endregion

--region 红点
function XRaceAgency:CheckTaskRedPoint()
    if self:GetIsOpen(true) then
        local taskId = self:GetCurrentConfig().TaskTimeLimitId
        local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId)
        for _, value in pairs(taskDatas) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(value.Id)
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end
    return false
end

function XRaceAgency:GetTimeToMatchCountDown()
    local config = self._Model:GetClintConfigById("TimeToMatchCountDown")
    return tonumber(config.Values[1]) * 24 * 60 * 60
end

function XRaceAgency:CheckMatchGuessRedpoint()
    if self:GetIsOpen(true) then
        local activity = self:GetCurrentConfig()
        local nowTime = XTime.GetServerNowTimestamp()
        local matchGuessEndTime = XFunctionManager.GetEndTimeByTimeId(activity.MatchGuessTime)
        local timeToMatchCountDown = self:GetTimeToMatchCountDown()
        local leftTime = matchGuessEndTime - nowTime
        if leftTime > 0 and leftTime < timeToMatchCountDown then
            --预测时间是否结束
            local matchGuess = activity.MatchGuess
            local playerData = self._Model:GetBasePlayerData()
            if playerData and playerData.GlobalGuessDict then
                for _, id in ipairs(matchGuess) do
                    local info = playerData.GlobalGuessDict[id]
                    if not (info and (XTool.IsNumberValid(info.CharacterId) or XTool.IsNumberValid(info.OptionId))) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function XRaceAgency:CheckRoundGuessRedPoint()
    if self:GetIsOpen(true) then
        local hasPredicted = {}
        local curRoundId = self._Model:GetCurRound()
        local playerData = self._Model:GetBasePlayerData()
        
        if playerData and playerData.RoundGuessDict then
            for roundId, v in pairs(playerData.RoundGuessDict) do
                local infoDict = v.RaceRoundGuessInfoDict
                if infoDict then
                    for guessId, info in pairs(infoDict) do
                        if info.GuessState == XEnumConst.Race.GuessState.GuessSuccess and not info.IsGain then
                            return true --有奖励未领取
                        end
                        if curRoundId == roundId then
                            if XTool.IsNumberValid(info.CharacterId) or XTool.IsNumberValid(info.OptionId) then
                                --已预测选项
                                hasPredicted[guessId] = true
                            end
                        end
                    end
                end
            end
        end
        
        if curRoundId ~= -1 then
            --当前比赛所有预测选项
            local etcd = self._Model:GetEtcdRoundConfig(curRoundId)
            if etcd then
                for _, guessId in pairs(etcd.Guess) do
                    if not hasPredicted[guessId] then
                        return true
                    end
                end
            end
        end
    end
    return false
end
--endregion

----------private end----------

return XRaceAgency