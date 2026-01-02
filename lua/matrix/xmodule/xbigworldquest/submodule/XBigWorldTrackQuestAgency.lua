local CsSyncFight = CS.StatusSyncFight

---@type XBigWorldQuestAgency
local XBigWorldQuestAgency = XClassPartial("XBigWorldQuestAgency")

--- 追踪任务
---@param questId number 任务id
---@param onFightTrackCb function 任务追踪完回调
--------------------------
function XBigWorldQuestAgency:TrackQuest(questId, onFightTrackCb, questCb)
    if not questId or questId <= 0 then
        return
    end
    local serverTrackId = self._Model:GetTrackQuestId()

    --当前追踪的Id与服务器Id一致，仅通知战斗
    if serverTrackId == questId then
        self:NotifyFightTrackQuest(questId, true, onFightTrackCb)
        self:DispatchObjectiveChanged(questId, 0, 0)
    else
        --如果需要追踪的任务是副本任务，则不需要同步到服务器
        --1. 因为重连后如果是进入副本，则会重新追踪
        --2. 如果是退出副本，则不会重新追踪副本任务，只需要追踪正常任务的数据即可
        if self:IsInstQuest(questId) then
            --如果当前追踪的任务不是副本任务，则需要更新Last， 标记为需要还原
            if not self:IsInstQuest(serverTrackId) then
                self._Model:MarkRevertTrackQuest()
            end
            self._Model:SetTrackQuestIdLocal(questId)
            self:NotifyFightTrackQuest(questId, true, onFightTrackCb)
            self:DispatchObjectiveChanged(questId, 0, 0)

            if questCb then
                questCb()
            end
        else
            self._SyncTracking = true
            local req = {
                ChangeTraceQuestId = questId
            }
            XNetwork.Call("DlcQuestTraceIdChangeRequest", req, function(res)
                self._SyncTracking = false
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                self._Model:SetTrackQuestId(questId)
                self:NotifyFightTrackQuest(questId, true, onFightTrackCb)
                self:DispatchObjectiveChanged(questId, 0, 0)
            end)

            if questCb then
                questCb()
            end
        end
    end
end

--- 取消追踪任务
---@param questId number 任务id
---@param onFightTrackCb function 任务追踪取消完回调
--------------------------
function XBigWorldQuestAgency:UnTrackQuest(questId, onFightTrackCb, questCb)
    local serverTrackId = self._Model:GetTrackQuestId()
    --取消的不是当前追踪的
    if serverTrackId ~= questId then
        return
    end
    if self:IsInstQuest(questId) then
        self._Model:TryRevertTrackQuest()
        self:NotifyFightTrackQuest(questId, false, onFightTrackCb)
        if questCb then
            questCb()
        end
    else
        self._SyncTracking = true
        local req = { ChangeTraceQuestId = 0 }
        XNetwork.Call("DlcQuestTraceIdChangeRequest", req, function(res)
            self._SyncTracking = false
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            self._Model:SetTrackQuestId(0)
            self:NotifyFightTrackQuest(questId, false, onFightTrackCb)
            if questCb then
                questCb()
            end
        end)
    end
    
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED,
            self.QuestOpType.QuestUnTrack, questId, 0, 0)
end

--- 同步战斗追踪状态
---@param questId number 任务Id
---@param enable boolean 是否追踪
---@param onFightTrackCb function 回调函数
--------------------------
function XBigWorldQuestAgency:NotifyFightTrackQuest(questId, enable, onFightTrackCb)
    if not questId or questId <= 0 then
        return
    end
    local isInstQuest = self:IsInstQuest(questId)
    local isInstLevel = XMVCA.XBigWorldGamePlay:IsInstLevel()

    if isInstQuest ~= isInstLevel then
        return
    end
    local category = self:GetQuestCategory(questId)
    if category == self.QuestCategory.NormalQuest and self:CheckQuestFinish(questId) then
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

    if onFightTrackCb then
        onFightTrackCb(cancelId)
    end
end

--- 尝试追踪默认任务
---@return boolean 
--------------------------
function XBigWorldQuestAgency:TryTrackDefault()
    if self._SyncTracking then
        return false
    end
    local trackId = self:GetTrackQuestId()
    -- 当前类型已经有追踪的任务了
    if trackId and trackId > 0 then
        return false
    end
    local list = self._Model:GetReceiveAndDefaultTrackQuestIds()
    if XTool.IsTableEmpty(list) then
        return false
    end
    list = self:SortDefaultTrackList(list)
    self:TrackQuest(list[1])
    
    return true
end

--- 默认追踪任务排序
---@param list number[] 任务Id数组
---@return number[]
--------------------------
function XBigWorldQuestAgency:SortDefaultTrackList(list)
    if XTool.IsTableEmpty(list) then
        return list
    end
    if #list == 1 then
        return list
    end
    
    table.sort(list, function(questIdA, questIdB)
        local priorityA = self:GetQuestTypePriorityByQuestId(questIdA)
        local priorityB = self:GetQuestTypePriorityByQuestId(questIdB)

        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
        priorityA = self._Model:GetQuestTrackPriority(questIdA)
        priorityB = self._Model:GetQuestTrackPriority(questIdB)
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end
        return questIdA < questIdB
    end)
    
    return list
end

--- 当前追踪的任务
---@return number
--------------------------
function XBigWorldQuestAgency:GetTrackQuestId()
    return self._Model:GetTrackQuestId()
end

function XBigWorldQuestAgency:GetQuestTypePriorityByQuestId(questId)
    local questType = self._Model:GetQuestType(questId)
    return self._Model:GetQuestTypePriority(questType)
end

function XBigWorldQuestAgency:DispatchObjectiveChanged(questId, stepId, objectiveId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED,
            self.QuestOpType.QuestTrack, questId, stepId, objectiveId)
end

function XBigWorldQuestAgency:IsDefaultTrackQuest(questId)
    return self._Model:IsDefaultTrackQuest(questId)
end

function XBigWorldQuestAgency:IsTrackQuest(questId)
    return self._Model:IsTrackQuest(questId)
end

--- 通过服务器数据初始化追踪数据
---@param traceQuestIds table<number, number> 追踪数据(category, questId)
---@param traceQuestData table 追踪数据
--------------------------
function XBigWorldQuestAgency:InitTrackDataByServer(traceQuestIds, traceQuestData)
    -- 新版追踪的数据
    if traceQuestData and traceQuestData.IsEnabled then
        self._Model:InitTrackData(traceQuestData.CurrentTraceQuestId, traceQuestData.LastTraceQuestId)
    elseif traceQuestIds then --兼容旧版
        local questId = traceQuestIds[self.QuestCategory.NormalQuest] or 0
        self._Model:InitTrackData(questId, 0)
    end
end