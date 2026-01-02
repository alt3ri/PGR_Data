---@class XBigWorldQuestAgency : XAgency
---@field private _Model XBigWorldQuestModel
---@field QuestOpType table
local XBigWorldQuestAgency = XClass(XAgency, "XBigWorldQuestAgency", true)

--require 部分类
require("XModule/XBigWorldQuest/SubModule/XBigWorldSpecialQuestAgency")
require("XModule/XBigWorldQuest/SubModule/XBigWorldQuestConstAgency")
require("XModule/XBigWorldQuest/SubModule/XBigWorldTrackQuestAgency")

local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local Pattern = "{(.-)}"

function XBigWorldQuestAgency:OnInit()
    self.PatternKeyToValue = {
        Current = 0,
        Max = 0
    }
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
    self:AddRpc("NotifyDlcInviteQuestResultReward", handler(self, self.NotifyDlcInviteQuestResultReward))
    self:AddRpc("NotifyDlcInviteQuestResultNumReward", handler(self, self.NotifyDlcInviteQuestResultNumReward))
end

function XBigWorldQuestAgency:InitEvent()
end

function XBigWorldQuestAgency:ResetData()
    self._Model:ResetData()
end

function XBigWorldQuestAgency:NotifyDlcInviteQuestResultReward(data)
    if not data then
        return
    end
    local questId, resultId, rewardItems = data.QuestId, data.ResultId, data.RewardItems
    self:OpenInvitationDetail(questId, resultId)
    self._Model:AddFinishInviteResult(resultId)
    if rewardItems and not XTool.IsTableEmpty(rewardItems) then
        XMVCA.XBigWorldUI:OpenBigWorldRewardGoods(rewardItems)
    end

    self._Model:InitInviteInfo(data.InviteQuestInfo)
end

function XBigWorldQuestAgency:NotifyDlcInviteQuestResultNumReward(data)
    if not data then
        return
    end
    local rewardItems = data.RewardItems
    
    if rewardItems and not XTool.IsTableEmpty(rewardItems) then
        XMVCA.XBigWorldUI:OpenBigWorldRewardGoods(rewardItems)
    end
    
    self._Model:InitInviteInfo(data.InviteQuestInfo)
end

function XBigWorldQuestAgency:InitShieldController()
    XMVCA.XBigWorldFunction:RegisterFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Task, self,
            self.OnChangeControlState)
end

function XBigWorldQuestAgency:RemoveShieldController()
    XMVCA.XBigWorldFunction:RemoveFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Task, self,
            self.OnChangeControlState)
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
        --强制追踪副本任务，主要是更新数据
        self:TrackQuest(data.Id)
    else
        self:PopupTaskObtain(data.Id, false)
        --领取到的任务是默认追踪的任务
        self:TryTrackDefault()
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
    local currentTrackId = self:GetTrackQuestId()
    local isFinishCurTrack = false
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
        if not isFinishCurTrack and currentTrackId == id then
            isFinishCurTrack = true
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
    local function TrackDefault()
        if not isFinishCurTrack then
            return
        end
        if not self:TryTrackDefault() then
            return
        end
        isFinishCurTrack = false
    end
    --取消追踪任务
    if untrackIds then
        for _, id in pairs(untrackIds) do
            self:UnTrackQuest(id, nil, TrackDefault)
        end
    end

    TrackDefault()

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
    elseif data.CanJumpToEnter and data.InstLevelId > 0 then
        local commonData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
        local title = XMVCA.XBigWorldService:GetText("CommmonTipsTitle")
        local tip = XUiHelper.ReplaceTextNewLine(XMVCA.XBigWorldService:GetText("QuestGoToNewLevelText"))
        local sureCb = function()
            local x, y, z, eulerY = data.PosX, data.PosY, data.PosZ, data.RotY
            local worldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId()
            local team = XMVCA.XBigWorldCharacter:GetCurrentTeam():ToServerTeam()
            local pos = { X = x, Y = y, Z = z }
            local rot = { X = 0, Y = eulerY, Z = 0 }
            XMVCA.XBigWorldGamePlay:RequestEnterInstLevel(worldId, data.InstLevelId, team, pos, rot, function() 
                XMVCA.XBigWorldUI:RunMain()
            end)
        end
        commonData:InitInfo(title, tip):InitSureClick(nil, sureCb):InitToggleActive(false)

        XMVCA.XBigWorldUI:OpenConfirmPopup(commonData)
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
    elseif data.CanJumpToEnter then
        if data.InstLevelId <= 0 then
            return self.EQuestSkipToByFightState.LevelInValid
        end
    else
        return self.EQuestSkipToByFightState.None
    end
end

--- 根据战斗跳转数据获取跳转的文本
---@return string
function XBigWorldQuestAgency:GetQuestSkipToText(data)
    local text
    if data then
        local levelId = (data.NavLevelId and data.NavLevelId > 0) and data.NavLevelId or ((data.InstLevelId and data.InstLevelId > 0) and data.InstLevelId or 0)
        if data.ShortMessageId and data.ShortMessageId > 0 then
            text = XMVCA.XBigWorldService:GetText("QuestReadMessageText")
        elseif levelId > 0 then
            local currentLevel = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
            if currentLevel == levelId then
                text = XMVCA.XBigWorldService:GetText("QuestGoToCurrentLevelText")
            else
                local levelName = XMVCA.XBigWorldMap:GetLevelName(levelId)
                text = XMVCA.XBigWorldService:GetText("BigWorldTrackText", levelName)
            end
        end
    end

    return text
end

--endregion 战斗交互

--- 场景切换完成
function XBigWorldQuestAgency:DoLevelChangeComplete()
    --场景切换完成时再追踪一次
    if not XMVCA.XBigWorldGamePlay:IsInstLevel() then
        self._Model:TryRevertTrackQuest()
    end
    local questId = self:GetTrackQuestId()
    self:TrackQuest(questId)
end

function XBigWorldQuestAgency:UpdateData(traceQuestIds, traceQuestData, inviteQuestInfo)
    self:InitTrackDataByServer(traceQuestIds, traceQuestData)
    self._Model:InitInviteInfo(inviteQuestInfo)
end

---@param stepData XBigWorldQuestStep
---@return XBigWorldQuestObjective[]
function XBigWorldQuestAgency:GetObjectiveListWithStep(stepData, ignoreEmptyTitle)
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
        if ignoreEmptyTitle and string.IsNilOrEmpty(title) then
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

function XBigWorldQuestAgency:GetObjectiveListWithQuestId(questId, ignoreEmptyTitle)
    local questData = self._Model:GetQuestData(questId)
    local step = questData:GetActiveStepData()
    if not step then
        return
    end
    return self:GetObjectiveListWithStep(step, ignoreEmptyTitle)
end

function XBigWorldQuestAgency:GetQuestDisplayProgress(questId, ignoreEmptyTitle)
    local objectiveList = self:GetObjectiveListWithQuestId(questId, ignoreEmptyTitle)
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

function XBigWorldQuestAgency:GetQuestExtraDetail(questId)
    local t = self._Model:GetQuestTemplate(questId)
    return t and t.ExtraDetail or nil
end

function XBigWorldQuestAgency:IsFavorableQuestType(questId)
    return self._Model:IsFavorableQuestType(questId)
end

function XBigWorldQuestAgency:IsFirstStatusBarPlay(questId)
    return self._Model:IsFirstStatusBarPlay(questId)
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

function XBigWorldQuestAgency:GetQuestSystemUiStyleId(questId)
    return self._Model:GetQuestSystemUiStyleId(questId)
end

function XBigWorldQuestAgency:GetQuestCategory(questId)
    return self._Model:GetQuestCategory(questId)
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

function XBigWorldQuestAgency:GetQuestStepTextByStepId(stepId)
    return self._Model:GetQuestStepText(stepId)
end

function XBigWorldQuestAgency:GetObjectiveType(objectiveId)
    return self._Model:GetObjectiveType(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveDeliveryItemDict(objectiveId)
    return self._Model:GetObjectiveDeliveryItemDict(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveDeliveryTitle(objectiveId)
    return self._Model:GetObjectiveDeliveryTitle(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveDeliveryDesc(objectiveId)
    return self._Model:GetObjectiveDeliveryDesc(objectiveId)
end

function XBigWorldQuestAgency:GetObjectiveItemsDeliverType(objectiveId)
    return self._Model:GetObjectiveItemsDeliverType(objectiveId)
end

function XBigWorldQuestAgency:GetStepLocation(stepId)
    local template = self._Model:GetQuestStepTemplate(stepId)
    return template and template.LocationText or ""
end

function XBigWorldQuestAgency:GetQuestFinishTip(questId)
    return self._Model:GetQuestFinishTip(questId)
end

--endregion Quest Config


--region Ui Open

function XBigWorldQuestAgency:PopupTaskObtain(questId, isFinish)
    local template = self._Model:GetQuestTemplate(questId)
    --手动的情况，不弹弹窗，通过战斗3C通知再弹
    if template and template.IsManualPop then
        return
    end
    self._Model:PopupTaskObtain(questId, isFinish)
end

function XBigWorldQuestAgency:PopupTaskObtainByFight(data)
    if not data then
        return
    end
    self._Model:PopupTaskObtain(data.QuestId, data.IsFinish)
end

function XBigWorldQuestAgency:OpenPopupDelivery(luaTable)
    if not luaTable then
        XLog.Error("打开交付界面异常, 参数为空")
        return
    end
    local objectiveId = luaTable.ObjectiveId
    if not objectiveId or objectiveId <= 0 then
        XLog.Error("打开交付界面异常, ObjectiveId = " .. objectiveId) 
        return
    end
    local questId = self:GetQuestIdByObjectiveId(objectiveId)
    if not questId or questId <= 0 then
        XLog.Error("打开交付界面异常, questId = " .. questId)
        return  
    end
    local questData = self:GetQuestData(questId)
    if not questData:IsInProgress() then
        XLog.Error("打开交付界面异常, questId = " .. questId .. "，状态不是进行中")
        return
    end
    local objectiveData = questData:GetObjective(objectiveId)
    if not objectiveData or not objectiveData:IsInProgress() then
        XLog.Error("打开交付界面异常, objectiveId = " .. objectiveId .. "，状态不是进行中")
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupDelivery", objectiveId)
end

function XBigWorldQuestAgency:OpenQuestMain(index, questId)
    if self:IsSkipToMainShield() then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldTaskMain", index, questId)
end

function XBigWorldQuestAgency:OpenQuestMainByType(questType)
    local index = 1
    if questType then
        for idx, typeId in pairs(self._Model:GetQuestTypeIds()) do
            if typeId == questType then
                --因为主界面会有全部，所以需要 + 1
                index = idx + 1
            end
        end
    end
    self:OpenQuestMain(index)
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
    if self._Model:CheckQuestRed() then
        return true
    end
    if self:CheckAllInviteRedPoint() then
        return true
    end
    return false
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

function XBigWorldQuestAgency:CheckAllInviteRedPoint()
    local questIds = self:GetInviteIds()
    for _, questId in pairs(questIds) do
        if self:CheckInviteRedPoint(questId) then
            return true
        end
    end
    return false
end

function XBigWorldQuestAgency:CheckInviteRedPoint(questId)
    if XMVCA.XBigWorldQuest:CheckInviteFinish(questId) and not XMVCA.XBigWorldQuest:CheckInviteRewardReceived(questId) then
        return true
    end
    
    return false
end
--endregion



return XBigWorldQuestAgency