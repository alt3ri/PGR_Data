---@class XBigWorldQuestAgency : XAgency
---@field private _Model XBigWorldQuestModel
---@field QuestOpType table
local XBigWorldQuestAgency = XClass(XAgency, "XBigWorldQuestAgency")

local stringFormat = string.format

local DlcEventId = XMVCA.XBigWorldService.DlcEventId
local CsSyncFight = CS.StatusSyncFight

local Pattern = "{(.-)}"

function XBigWorldQuestAgency:OnInit()
    self.PatternKeyToValue = {
        Current = 0,
        Max = 0
    }
    self._TrackQuestIdCache = false
    self:InitEnum()
    self:InitConditionCheck()
    self:InitShieldController()
    XMVCA.XBigWorldUI:AddFightUiCb("UiBigWorldTaskMain", handler(self, self.OpenQuestMainByFight), handler(self, self.CloseQuestMain))
end

function XBigWorldQuestAgency:OnRelease()
    self:ReleaseConditionCheck()
    self:RemoveShieldController()
end

function XBigWorldQuestAgency:InitRpc()
end

function XBigWorldQuestAgency:InitEvent()
end

function XBigWorldQuestAgency:ResetData()
    self._Model:ResetData()
end

--region Condition

-- 条件判断初始化
function XBigWorldQuestAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10101001, handler(self, self.ConditionCheckQuestFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101005, handler(self, self.ConditionCheckQuestInProgressAndReady))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101002, handler(self, self.ConditionCheckStepFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101003, handler(self, self.ConditionCheckObjectiveFinish))
end

function XBigWorldQuestAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101001)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101005)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101002)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101003)
end

--- 检查任务是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckQuestFinish(template)
    local params = template.Params
    local questId = params[1]
    return self:CheckQuestFinish(questId), template.Desc
end

--- 检查任务是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckQuestInProgressAndReady(template)
    local params = template.Params
    local questId = params[1]
    local isSuccess = self:CheckQuestInProgress(questId) or self:CheckQuestReady(questId)

    return isSuccess, template.Desc
end

--- 检查任务步骤是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckStepFinish(template)
    local params = template.Params
    local stepId = params[1]
    return self:CheckStepFinish(stepId), template.Desc
end

--- 检查到任务目标是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckObjectiveFinish(template)
    local params = template.Params
    local objectiveId = params[1]
    local questId = self._Model:GetQuestIdByObjectiveId(objectiveId)
    if not questId or questId <= 0 then
        XLog.Warning(string.format("此任务目标配置了无效QuestId, ObjectiveId = %s", objectiveId))
        return false, template.Desc
    end
    return self:CheckObjectiveFinish(questId, objectiveId), template.Desc
end

function XBigWorldQuestAgency:CheckQuestFinish(questId)
    return self._Model:CheckQuestFinish(questId)
end

function XBigWorldQuestAgency:CheckQuestInProgress(questId)
    return self._Model:CheckQuestInProgress(questId)
end

function XBigWorldQuestAgency:CheckQuestReady(questId)
    return self._Model:CheckQuestReady(questId)
end

function XBigWorldQuestAgency:CheckStepFinish(stepId)
    local questId = self._Model:GetQuestIdByStepId(stepId)
    if questId <= 0 then
        return false
    end

    if self._Model:CheckQuestFinish(questId) then
        return true
    end

    local questData = self:GetQuestData(questId)
    if not questData then
        return false
    end
    --任务已经完成
    if questData:IsFinish() then
        return true
    end
    local state = questData:GetState()
    --任务刚激活，还未领取
    if state == self.QuestState.Ready then
        return false
    end
    local stepData = questData:GetStep(stepId)
    if not stepData then
        return false
    end
    return stepData:IsFinish()
end

function XBigWorldQuestAgency:CheckObjectiveFinish(questId, objectiveId)
    if self._Model:CheckQuestFinish(questId) then
        return true
    end
    return self:CheckObjectiveFinishOnlyObjective(questId, objectiveId)
end

function XBigWorldQuestAgency:CheckObjectiveFinishOnlyObjective(questId, objectiveId)
    local questData = self:GetQuestData(questId)
    if not questData then
        return false
    end
    if questData:CheckObjectiveFinish(objectiveId) then
        return true
    end
    local objective = questData:GetObjective(objectiveId)
    return objective and objective:IsFinish() or false
end

--endregion Condition

function XBigWorldQuestAgency:InitShieldController()
    XMVCA.XBigWorldFunction:RegisterFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Task, self,
            self.OnChangeControlState)
end

function XBigWorldQuestAgency:RemoveShieldController()
    XMVCA.XBigWorldFunction:RemoveFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Task, self,
            self.OnChangeControlState)
end

--- 初始化枚举
--------------------------
function XBigWorldQuestAgency:InitEnum()
    self.QuestType = {
        All = 0,
        Main = 1,
        Side = 2,
        Normal = 3,
    }

    -- C# EQuestState
    self.QuestState = {
        --不活跃/未激活
        InActive = CS.EQuestState.InActive:GetHashCode(),
        --已激活未接取
        Ready = CS.EQuestState.Ready:GetHashCode(),
        --进行中
        InProgress = CS.EQuestState.InProgress:GetHashCode(),
        --已经完成
        Finished = CS.EQuestState.Finished:GetHashCode()
    }

    -- C# EQuestStepState
    self.StepState = {
        --不活跃/未激活
        Inactive = CS.EQuestStepState.InActive:GetHashCode(),
        --进行中
        InProgress = CS.EQuestStepState.InProgress:GetHashCode(),
        --完成
        Finished = CS.EQuestStepState.Finished:GetHashCode(),
    }

    -- C# EQuestObjectiveState
    self.ObjectiveState = {
        --不活跃/未激活
        InActive = 0,
        --内部Enter
        Enter = 1,
        --脚本正在执行进入环节
        ScriptEnter = 2,
        --进行中
        InProgress = 3,
        --内部Exit
        Exit = 4,
        --脚本正在退出进入环节
        ScriptExit = 5,
        --完成
        Finished = 6,
    }

    self.StepExecMode = {
        --线性执行下属objective
        Serial = 1,
        --并行执行下属objective
        Parallel = 2,
    }

    self.QuestOpType = {
        --弹窗展示
        PopupBegin = 1,
        --弹窗关闭
        PopupEnd = 2,
        --任务领取
        QuestReceive = 3,
        --任务追踪
        QuestTrack = 4,
        --任务取消追踪
        QuestUnTrack = 5,
        --任务完成
        QuestFinish = 6,
        --步骤激活
        StepActive = 7,
        --步骤完成
        StepFinish = 8,
        --流程激活
        ObjectiveActive = 9,
        --流程完成
        ObjectiveFinish = 10,
        --刷新流程
        ObjectiveRefresh = 11,
    }

    self.QuestCategory = {
        NormalQuest = 0,
        InstLevelStoryQuest = 1,
        InstLevelPlayQuest = 2,
        LevelPlayQuest = 3
    }

    local EQuestObjectiveProgressType = CS.StatusSyncFight.EQuestObjectiveProgressType

    self.QuestStepObjectiveType = {
        Bool = EQuestObjectiveProgressType.Bool:GetHashCode(),
        Int = EQuestObjectiveProgressType.Int:GetHashCode(),
        Float = EQuestObjectiveProgressType.Float:GetHashCode(),
        Percent = EQuestObjectiveProgressType.Percent:GetHashCode(),
    }

    self.QuestShieldState = {
        --进入正常状态
        BackToNormal = 0,
        --进入副本状态
        IntoFuben = 1,
    }

    self.QuestItemType = {
        NormalItem = 1,
        SpineItem = 2,
        PhotoItem = 3,
        TextItem = 4,
    }

    self.ActionType = {
        PlayAnimation = 1,
        Timer = 2,
        Func = 3,
    }

    self.EQuestObjectiveType = {
        ReadShortMessageComplete = 6,
        ReachTargetPosition = 7,
    }

    self.EQuestSkipToByFightState = {
        None = 0,
        NotExistMessage = 1,  -- 不存在目标短信
        ExistMessage = 2,  -- 存在目标短信
        SameAreaGroup = 3,  -- 当前位置与目标位置在相同区域
        DifferentAreaGroupSameLevel = 4, -- 当前位置同关卡不同区域
        DifferentLevel = 5, -- 与追踪目标不同关卡
        NotExistPin = 6,  -- 不存在图钉
        NotExistMap = 7, -- 不存在地图
    }

    self._ReplaceHandler = function(key)
        local v = self.PatternKeyToValue[key]
        return v and tostring(v) or key
    end
end

function XBigWorldQuestAgency:IsQuestItem(id)
    if not XTool.IsNumberValid(id) then
        return false
    end

    return XArrangeConfigs.GetType(id) == XArrangeConfigs.Types.QuestItem
end

--region 战斗同步任务数据

--- 全量初始化任务数据
function XBigWorldQuestAgency:InitQuest(data)
    if not data then
        return
    end
    local quests = data.ActiveQuests
    for _, quest in pairs(quests) do
        local questData = self._Model:GetQuestData(quest.Id)
        questData:UpdateData(quest)
        --处于副本内，强制追踪副本任务
        if self:IsInstQuest(quest.Id) and XMVCA.XBigWorldGamePlay:IsInstLevel() then
            self:TrackQuest(quest.Id)
        end
    end
    self._Model:UpdateFinishQuest(data.FinishedQuestIds)
    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

--- 任务状态激活
function XBigWorldQuestAgency:OnQuestActivated(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.Id)
    questData:UpdateData(data)

    XEventManager.DispatchEvent(DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, data.Id)
end

--- 领取到任务
function XBigWorldQuestAgency:OnQuestUndertaken(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.Id)
    questData:UpdateData(data)
    if self:IsInstQuest(data.Id) then
        --强制追踪副本任务
        self:TrackQuest(data.Id)
    else
        self:PopupTaskObtain(data.Id, false)
        --领取到的任务是默认追踪的任务
        if self:IsDefaultTrackQuest(data.Id) and not self._SyncTracking then
            local trackId = self:GetTrackQuestId()
            --是默认追踪任务，且当前没有任务需要追踪
            if not trackId or trackId <= 0 then
                self:TrackQuest(data.Id)
            end
        end
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, data.Id)
    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
end

--- 任务完成
function XBigWorldQuestAgency:OnQuestFinished(data)
    if not data then
        return
    end
    local theLastOneQuestId = 0
    local untrackIds
    for _, id in pairs(data) do
        local quest = self:GetQuestData(id)
        quest:SetState(XMVCA.XBigWorldQuest.QuestState.Finished)
        --追踪的任务已经完成，需要取消追踪
        if self._Model:IsTrackQuest(id) then
            if not untrackIds then
                untrackIds = {}
            end
            untrackIds[#untrackIds + 1] = id
        end
        theLastOneQuestId = id
    end
    self._Model:UpdateFinishQuest(data)
    --只弹最后一个
    if theLastOneQuestId > 0 then
        --任务完成弹窗
        self:PopupTaskObtain(theLastOneQuestId, true)
        --刷新界面，推进演出
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestFinish, theLastOneQuestId, 0, 0)
    end
    --取消追踪任务
    if untrackIds then
        for _, id in pairs(untrackIds) do
            self:UnTrackQuest(id)
        end
    end
    local currentTrackId = self:GetTrackQuestId()
    if not currentTrackId or currentTrackId <= 0 then
        self:TryTrackDefault()
    end

    --更新红点
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH)
    --任务完成
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_FINISH)
end

--- 任务移除
function XBigWorldQuestAgency:OnQuestRemove(data)
    if not data then
        return
    end
    local id = data.Id
    if self:IsInstQuest(id) then
        self:UnTrackQuest(id)
    end
    self._Model:RemoveQuestRedPoint(id)
end

--- 任务重新接取
function XBigWorldQuestAgency:OnQuestRelaunch(data)
    if not data then
        return
    end
    for _, questData in pairs(data) do
        self:OnQuestUndertaken(questData)
    end
end

--- 任务单个步骤状态发生改变
function XBigWorldQuestAgency:OnStepChanged(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.QuestId)
    local stepData = questData:TryGetStep(data.StepId)

    local notifyEvent = false
    stepData:SetState(data.State)
    local op
    if stepData:IsFinish() then
        op = self.QuestOpType.StepFinish
        notifyEvent = true
    elseif stepData:IsActive() then
        op = self.QuestOpType.StepActive
    end
    if op then
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, op, data.QuestId, data.StepId, 0)
    end

    if notifyEvent then
        --通知界面刷新
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_FINISH)
    end
end

--- 任务单个操作状态发生改变
function XBigWorldQuestAgency:OnObjectiveChanged(data)
    if not data then
        return
    end
    local questData = self._Model:GetQuestData(data.QuestId)
    local stepData = questData:TryGetStep(data.StepId)
    local objectiveData = stepData:TryGetObjective(data.ObjectiveId)
    objectiveData:SetProgress(data.Progress)
    objectiveData:SetState(data.State)
    objectiveData:SetIsAnimation(data.SkipUiRefreshEffect)

    local op
    local notifyEvent = false
    local ObjectiveState = self.ObjectiveState
    if data.State == ObjectiveState.Finished then
        op = self.QuestOpType.ObjectiveFinish
        notifyEvent = true
    elseif data.State == ObjectiveState.Enter then
        op = self.QuestOpType.ObjectiveActive
    elseif data.State == ObjectiveState.InProgress 
            or data.State == ObjectiveState.Exit 
            or data.State == ObjectiveState.ScriptExit then
        op = self.QuestOpType.ObjectiveRefresh
    end
    if op then
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, op, data.QuestId, data.StepId, data.ObjectiveId)
    end

    if notifyEvent then
        --通知界面刷新
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_FINISH)
    end
end

---@return XBigWorldQuest
function XBigWorldQuestAgency:GetQuestData(questId)
    return self._Model:GetQuestData(questId)
end

--endregion 战斗同步任务数据

--region 战斗交互

--- 添加任务值修改的回调
---@param questId number 任务Id
---@param key string 任务值key
---@param func function 回调函数
function XBigWorldQuestAgency:AddQuestValueChangeListener(questId, key, func)
    if not questId or questId <= 0 then
        return
    end
    if not key or not func then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_ADD_VAR_MODIFY_LISTENER, {
        QuestId = questId,
        Key = key,
        Listener = func
    })
end

--- 移除任务值修改的回调
---@param questId number 任务Id
---@param key string 任务值key
---@param func function 回调函数
function XBigWorldQuestAgency:RemoveQuestValueChangeListener(questId, key, func)
    if not questId or questId <= 0 then
        return
    end
    if not key or not func then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_REMOVE_VAR_MODIFY_LISTENER, {
        QuestId = questId,
        Key = key,
        Listener = func
    })
end

--- 追踪任务
---@param questId number 任务Id  
--------------------------
function XBigWorldQuestAgency:TrackQuest(questId, cb)
    local category = self._Model:GetQuestCategory(questId)
    local serverTrackId = self._Model:GetTrackQuestId(category)

    --当前追踪的Id与服务器Id一致，仅通知战斗
    if serverTrackId == questId then
        self:NotifyFightTrackQuest(questId, true, cb)
        XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestTrack, questId, 0, 0)
    else
        self._SyncTracking = true
        local req = {
            ChangeTraceQuestId = questId,
            IsCancel = false,
        }
        XNetwork.Call("DlcQuestTraceIdChangeRequest", req, function(res)
            self._SyncTracking = false
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            self._Model:SetTrackQuestId(category, questId)
            self:NotifyFightTrackQuest(questId, true, cb)
            XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestTrack, questId, 0, 0)
        end)
    end
end

--- 取消追踪
---@param questId number 任务Id    
--------------------------
function XBigWorldQuestAgency:UnTrackQuest(questId, cb)
    local category = self._Model:GetQuestCategory(questId)
    local serverTrackId = self._Model:GetTrackQuestId(category)
    if serverTrackId ~= questId then
        return
    end
    self._SyncTracking = true
    local req = {
        ChangeTraceQuestId = questId,
        IsCancel = true,
    }
    XNetwork.Call("DlcQuestTraceIdChangeRequest", req, function(res)
        self._SyncTracking = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetTrackQuestId(category, 0)
        self:NotifyFightTrackQuest(questId, false, cb)
    end)
    XEventManager.DispatchEvent(DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.QuestOpType.QuestUnTrack, questId, 0, 0)
end

--- 同步战斗追踪状态
---@param questId number 任务Id
---@param enable boolean 是否追踪
---@param enable function 回调函数
function XBigWorldQuestAgency:NotifyFightTrackQuest(questId, enable, cancelCb)
    if not questId or questId <= 0 then
        return
    end

    local isInstQuest = self:IsInstQuest(questId)
    local isInstLevel = XMVCA.XBigWorldGamePlay:IsInstLevel()
    --追踪了一个已完成的非副本任务， 副本任务可以重复接取
    if enable and (not isInstQuest and self:CheckQuestFinish(questId)) then
        return
    end
    
    if isInstQuest ~= isInstLevel then
        return
    end
    
    local data = {
        QuestId = questId,
        Enable = enable,
    }
    local result = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_SET_NAVIGTION_ENABLE, data)
    local cancelId = 0
    if result and result.CanceledQuestId and result.CanceledQuestId > 0 then
        cancelId = result.CanceledQuestId
    elseif not enable then
        cancelId = questId
    end

    if cancelCb then
        cancelCb(cancelId)
    end
end

--- 追踪默认的任务
function XBigWorldQuestAgency:TryTrackDefault()
    local list = self._Model:GetReceiveAndDefaultTrackQuestIds()
    if XTool.IsTableEmpty(list) then
        return false
    end
    local questId = list[1]
    self:TrackQuest(questId)

    return true
end

--- 获取任务跳转数据
---@param questId number 任务Id
---@return table 跳转数据
function XBigWorldQuestAgency:GetQuestSkipInfo(questId)
    local objectiveId
    local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)
    local activeStep = questData:GetActiveStepData()
    if not activeStep then
        return
    end
    local objective = activeStep:GetInRunningObjective()
    if not objective then
        return
    end
    objectiveId = objective:GetId()

    local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_SKIP_INFO, {
        QuestId = questId,
        ObjectiveId = objectiveId
    })
    if not data then
        return
    end
    return data
end

--- 尝试根据战斗跳转数据进行条状
---@param data table 跳转数据
function XBigWorldQuestAgency:TrySkipToByFightSkipInfo(data)
    if not data then
        XLog.Error("跳转失败, 数据为空！")
        return false
    end
    if data.ShortMessageId and data.ShortMessageId > 0 then
        local id = data.ShortMessageId
        XMVCA.XBigWorldUI:SafeClose("UiBigWorldTaskMain")
        return XMVCA.XBigWorldMessage:TryOpenMessageSingle(id)
    elseif data.NavMapPinId and data.NavMapPinId > 0 then
        local id = data.NavMapPinId
        if id and id > 0 then
            return XMVCA.XBigWorldMap:TryOpenBigWorldMapUiAnchorPin(XMVCA.XBigWorldGamePlay:GetCurrentWorldId(), data.NavLevelId, id)
        else
            XMVCA.XBigWorldUI:TipMsg(XMVCA.XBigWorldService:GetText("MapAnchorQuestTip"))
            return false
        end
    else
        XMVCA.XBigWorldUI:TipMsg(XMVCA.XBigWorldService:GetText("QuestCanNotGoToText"))
        return false
    end
end

--- 根据战斗跳转数据获取跳转的状态
---@return number
function XBigWorldQuestAgency:CheckSkipToByFightSkipInfo(data)
    if not data then
        XLog.Error("跳转失败, 数据为空！")

        return self.EQuestSkipToByFightState.None
    end

    if data.ShortMessageId and data.ShortMessageId > 0 then
        local id = data.ShortMessageId
        
        if XMVCA.XBigWorldMessage:CheckHasMessage(id) then
            return self.EQuestSkipToByFightState.ExistMessage
        end

        return self.EQuestSkipToByFightState.NotExistMessage
    elseif data.NavMapPinId and data.NavMapPinId > 0 then
        local id = data.NavMapPinId
        local levelId = data.NavLevelId
        local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

        if not XMVCA.XBigWorldMap:CheckLevelHasMap(levelId) and not XMVCA.XBigWorldMap:CheckLevelLinkOther(levelId) then
            return self.EQuestSkipToByFightState.NotExistMap
        end

        if XMVCA.XBigWorldMap:CheckHasPin(levelId, id) then
            if currentLevelId ~= levelId then
                return self.EQuestSkipToByFightState.DifferentLevel
            end

            if XMVCA.XBigWorldMap:CheckPinCurrentSameAreaGroup(levelId, id) then
                return self.EQuestSkipToByFightState.SameAreaGroup
            end

            return self.EQuestSkipToByFightState.DifferentAreaGroupSameLevel
        end

        return self.EQuestSkipToByFightState.NotExistPin
    else
        return self.EQuestSkipToByFightState.None
    end
end

--- 根据战斗跳转数据获取跳转的文本
---@return string
function XBigWorldQuestAgency:GetQuestSkipToText(data)
    local text
    if data then
        if data.ShortMessageId and data.ShortMessageId > 0 then
            text = XMVCA.XBigWorldService:GetText("QuestReadMessageText")
        elseif data.NavLevelId and data.NavLevelId > 0 then
            local currentLevel = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
            if currentLevel == data.NavLevelId then
                text = XMVCA.XBigWorldService:GetText("QuestGoToCurrentLevelText")
            else
                local levelName = XMVCA.XBigWorldMap:GetLevelName(data.NavLevelId)
                text = XMVCA.XBigWorldService:GetText("BigWorldTrackText", levelName)
            end
        end
    end

    return text
end

--endregion 战斗交互

--- 当前场景支持接取的任务类型
---@param levelId number 场景Id
---@return number 任务类型
function XBigWorldQuestAgency:GetLevelSupportCategory(levelId)
    ---@type StatusSyncFight.XTableLevel
    local template = CsSyncFight.XLevelConfig.GetTemplate(levelId)
    local levelType = template and template.LevelType or 0
    local levelSubType = template and template.LevelSubType or 0

    if levelType == XMVCA.XBigWorldInstance.LevelType.BigWorld then
        return self.QuestCategory.NormalQuest
    elseif levelType == XMVCA.XBigWorldInstance.LevelType.Instance then
        if levelSubType == XMVCA.XBigWorldInstance.LevelSubType.StoryInst then
            return self.QuestCategory.InstLevelStoryQuest
        elseif levelSubType == XMVCA.XBigWorldInstance.LevelSubType.LevelPlayInst then
            return self.QuestCategory.InstLevelPlayQuest
        end
    end
    XLog.Error("未找到当前Level支持的任务类型，请检查！！！ LevelId = " .. levelId)
    return self.QuestCategory.NormalQuest
end

--- 当前追踪的任务
---@param category number 任务类型，不填时为当前场景支持的任务类型
---@return number
function XBigWorldQuestAgency:GetTrackQuestId(category)
    category = category or self:GetLevelSupportCategory(XMVCA.XBigWorldGamePlay:GetCurrentLevelId())
    return self._Model:GetTrackQuestId(category)
end

--- 场景切换完成
function XBigWorldQuestAgency:DoLevelChangeComplete()
    --场景切换完成，如果是副本任务，会接取到任务，在接取时追踪即可
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        return
    end
    --切换到非副本场景时，如果存在追踪的任务，则进行还原
    local questId = self:GetTrackQuestId()
    self:TrackQuest(questId)
end

function XBigWorldQuestAgency:UpdateData(traceQuestIds)
    self._Model:UpdateTrackIds(traceQuestIds)
end

---@param stepData XBigWorldQuestStep
---@return XBigWorldQuestObjective[]
function XBigWorldQuestAgency:GetObjectiveListWithStep(stepData)
    if not stepData then
        return
    end
    local dict = stepData:GetObjectiveDict()
    if XTool.IsTableEmpty(dict) then
        return
    end
    local mode = self._Model:GetQuestStepExecMode(stepData:GetId())
    local isSerial = mode == self.StepExecMode.Serial
    local isParallel = mode == self.StepExecMode.Parallel
    local ObjectiveState = self.ObjectiveState

    local list = {}
    for _, objective in pairs(dict) do
        local title = self._Model:GetObjectiveTitle(objective:GetId())
        if string.IsNilOrEmpty(title) then
            goto continue
        end
        if isSerial then
            --线性模式
            local state = objective:GetObjectiveState()
            if state ~= ObjectiveState.Finished and state ~= ObjectiveState.InActive then
                list[#list + 1] = objective
            end
        elseif isParallel then
            --并行模式
            list[#list + 1] = objective
        end
        :: continue ::
    end
    return list
end

function XBigWorldQuestAgency:GetObjectiveListWithQuestId(questId)
    local questData = self._Model:GetQuestData(questId)
    local step = questData:GetActiveStepData()
    if not step then
        return
    end
    return self:GetObjectiveListWithStep(step)
end

function XBigWorldQuestAgency:GetQuestDisplayProgress(questId)
    local objectiveList = self:GetObjectiveListWithQuestId(questId)
    if XTool.IsTableEmpty(objectiveList) then
        return
    end
    local list = {}
    for _, objective in pairs(objectiveList) do
        local id = objective:GetId()
        local progress = self:GetObjectiveProgressDesc(id, objective:GetProgress(), objective:GetMaxProgress())
        list[#list + 1] = progress
    end
    return list
end

--region Quest Item Config

function XBigWorldQuestAgency:GetQuestItemIcon(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Icon or ""
end

function XBigWorldQuestAgency:GetQuestItemName(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Name or ""
end

function XBigWorldQuestAgency:GetQuestItemPriority(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Priority or ""
end

function XBigWorldQuestAgency:GetQuestItemQuality(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Quality or ""
end

function XBigWorldQuestAgency:GetQuestItemDescription(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Description or ""
end

function XBigWorldQuestAgency:GetQuestItemWorldDescription(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.WorldDescription or ""
end

function XBigWorldQuestAgency:GetQuestItemType(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Type or ""
end

function XBigWorldQuestAgency:GetQuestItemParams(templateId)
    local template = self._Model:GetQuestItemTemplate(templateId)
    return template and template.Params or nil
end

function XBigWorldQuestAgency:GetGroupIdByQuestId(questId)
    return self._Model:GetGroupIdByQuestId(questId, true)
end

--endregion Quest Item Config

--region Quest Config

function XBigWorldQuestAgency:GetObjectiveProgressDescByObjectiveId(questId, objectiveId)
    local questData = self:GetQuestData(questId)

    if not questData then
        return
    end

    local objective = questData:GetObjective(objectiveId)

    if not objective then
        return
    end

    return self:GetObjectiveProgressDesc(objectiveId, objective:GetProgress(), objective:GetMaxProgress())
end

function XBigWorldQuestAgency:GetObjectiveProgressDesc(objectiveId, current, max)
    --local type = self._Model:GetObjectiveType(objectiveId)
    --local max = self._Model:GetObjectiveMaxProgress(objectiveId)
    --if type == self.QuestStepObjectiveType.Int then
    --    return stringFormat("%d/%d", progress, max)
    --elseif type == self.QuestStepObjectiveType.Float then
    --    return stringFormat("%0.1f/%0.1f", progress / 10000, max / 10000)
    --elseif type == self.QuestStepObjectiveType.Percent then
    --    return stringFormat("%0.1f%%", 100 * progress / max)
    --elseif type == self.QuestStepObjectiveType.Bool then
    --    return stringFormat("%d/%d", progress > 0 and 0 or 1, 1)
    --end
    local txt = self._Model:GetObjectiveTitle(objectiveId)
    self.PatternKeyToValue.Current = current
    self.PatternKeyToValue.Max = max
    return txt:gsub(Pattern, self._ReplaceHandler)
end

function XBigWorldQuestAgency:GetReceiveQuestIds()
    return self._Model:GetReceiveQuestIds()
end

function XBigWorldQuestAgency:GetQuestStepText(questId)
    local questData = self._Model:GetQuestData(questId)
    local step = questData:GetActiveStepData()
    if not step then
        return
    end
    return self._Model:GetQuestStepText(step:GetId())
end

function XBigWorldQuestAgency:GetQuestTypeColorWithQuestId(questId)
    local t = self._Model:GetQuestTemplate(questId)
    if not t then
        return ""
    end

    local template = self._Model:GetQuestTypeTemplate(t.Type)
    return template and template.Color or ""
end

function XBigWorldQuestAgency:GetQuestTypeMessageColorWithQuestId(questId)
    local t = self._Model:GetQuestTemplate(questId)
    if not t then
        return ""
    end

    local template = self._Model:GetQuestTypeTemplate(t.Type)
    return template and template.MessageColor or ""
end

function XBigWorldQuestAgency:GetQuestIdByObjectiveId(objectiveId)
    if not XTool.IsNumberValid(objectiveId) then
        return 0
    end

    return self._Model:GetQuestIdByObjectiveId(objectiveId)
end

function XBigWorldQuestAgency:GetQuestIcon(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestIcon or ""
end

function XBigWorldQuestAgency:GetQuestBanner(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.QuestBanner or ""
end

function XBigWorldQuestAgency:GetQuestText(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.Name or ""
end

function XBigWorldQuestAgency:GetQuestDesc(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.Desc or ""
end

function XBigWorldQuestAgency:GetQuestRewardId(questId)
    local t = self._Model:GetQuestTemplate(questId)

    return t and t.RewardId or 0
end

function XBigWorldQuestAgency:IsFavorableQuestType(questId)
    return self._Model:IsFavorableQuestType(questId)
end

function XBigWorldQuestAgency:IsFirstStatusBarPlay(questId)
    return self._Model:IsFirstStatusBarPlay(questId)
end

function XBigWorldQuestAgency:IsDefaultTrackQuest(questId)
    return self._Model:IsDefaultTrackQuest(questId)
end

function XBigWorldQuestAgency:IsTrackQuest(questId)
    return self._Model:IsTrackQuest(questId)
end

function XBigWorldQuestAgency:GetQuestStepExecMode(stepId)
    return self._Model:GetQuestStepExecMode(stepId)
end

function XBigWorldQuestAgency:IsSerialStep(stepId)
    local mode = self:GetQuestStepExecMode(stepId)
    return mode == self.StepExecMode.Serial
end

function XBigWorldQuestAgency:IsParallelStep(stepId)
    local mode = self:GetQuestStepExecMode(stepId)
    return mode == self.StepExecMode.Parallel
end

function XBigWorldQuestAgency:IsInstQuest(questId)
    if not questId or questId <= 0 then
        return false
    end
    local category = self._Model:GetQuestCategory(questId)
    return category == self.QuestCategory.InstLevelPlayQuest or category == self.QuestCategory.InstLevelStoryQuest
end

function XBigWorldQuestAgency:GetObjectiveTitle(objectiveId)
    return self._Model:GetObjectiveTitle(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveDesc(objectiveId)
    return self._Model:GetObjectiveDesc(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveMaxProgress(objectiveId)
    return self._Model:GetObjectiveMaxProgress(objectiveId)
end

function XBigWorldQuestAgency:IsBoolObjective(objectiveId)
    return self._Model:GetObjectiveType(objectiveId) == self.QuestStepObjectiveType.Bool
end

function XBigWorldQuestAgency:GetQuestStepTextByStepId(stepId)
    return self._Model:GetQuestStepText(stepId)
end

--endregion Quest Config

--region Ui Open

function XBigWorldQuestAgency:PopupTaskObtain(questId, isFinish)
    self._Model:PopupTaskObtain(questId, isFinish)
end

function XBigWorldQuestAgency:OpenPopupDelivery(luaTable)
    if not luaTable then
        XLog.Error("打开交付界面异常, 参数为空")
        return
    end
    XLuaUiManager.Open("UiBigWorldPopupDelivery", luaTable.ObjectiveId)
end

function XBigWorldQuestAgency:OpenQuestMain(index, questId)
    if self:IsSkipToMainShield() then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskMain", index, questId)
end

function XBigWorldQuestAgency:CloseQuestMain()
    XMVCA.XBigWorldUI:Close("UiBigWorldTaskMain")
end

function XBigWorldQuestAgency:OpenQuestMainByFight(data)
    self:OpenQuestMain(nil, nil)
end

function XBigWorldQuestAgency:IsSkipToMainShield()
    return self._IsSkipToMainShield
end

---@param controlData XBWFunctionControlData
function XBigWorldQuestAgency:OnChangeControlState(controlData)
    local shieldState = controlData:GetArgByIndex(1)
    if not shieldState then
        XLog.Error("屏蔽任务失败，参数异常!")
        return
    end

    if shieldState == self.QuestShieldState.BackToNormal then
        --返回正常状态
        self._IsSkipToMainShield = false
    elseif shieldState == self.QuestShieldState.IntoFuben then
        --进入副本，任务的表现
        self._IsSkipToMainShield = true
    end
end

--endregion Ui Open

--region 红点
function XBigWorldQuestAgency:CheckQuestRed()
    return self._Model:CheckQuestRed()
end

function XBigWorldQuestAgency:CheckQuestRedWithQuestType(type)
    return self._Model:CheckQuestRedWithQuestType(type)
end

function XBigWorldQuestAgency:CheckQuestRedWithQuestId(questId)
    return self._Model:CheckQuestRedWithQuestId(questId)
end

function XBigWorldQuestAgency:MarkQuestRedPoint(questId)
    self._Model:MarkQuestRedPoint(questId)
end

function XBigWorldQuestAgency:SaveQuestRed()
    self._Model:SaveQuestRed()
end
--endregion



return XBigWorldQuestAgency