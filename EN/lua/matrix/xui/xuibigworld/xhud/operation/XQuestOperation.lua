local XBigWorldObjectiveData = require("XUi/XUiBigWorld/XHud/ViewData/XBigWorldObjectiveData")
local XBigWorldQuestData = require("XUi/XUiBigWorld/XHud/ViewData/XBigWorldQuestData")

local tableRemove = table.remove

local Pattern = "{(.-)}"
local SplitPattern = "^(.-){.-}(.-)$"

---@class XQuestOperation
---@field _View XUiBigWorldPanelQuest
---@field _QuestQueue XBigWorldQuestData[]
---@field _QuestPool XBigWorldQuestData[]
---@field _ObjectivePool XBigWorldObjectiveData[]
---@field _RunningData XBigWorldQuestData
local XQuestOperation = XClass(nil, "XQuestOperation")

function XQuestOperation:Ctor(view)
    self._View = view
    self._QuestQueue = {}
    self._QuestPool = {}
    self._ObjectivePool = {}
    self._OperateBehavior = {}
    self._OperateDataFunc = {}

    self:InitDataFunc()
    self:InitBehavior()
end

--region 队列操作

function XQuestOperation:Enqueue(operate, questId, stepId, objectiveId)
    local func = self._OperateDataFunc[operate]
    if not func then
        XLog.Error("XQuestOperation:Enqueue - No data function for operate: " .. tostring(operate))
        return
    end
    local data = func(operate, questId, stepId, objectiveId)
    if not data or not self:CheckData(data) then
        self:RecycleQuest(data)
        return
    end
    self._QuestQueue[#self._QuestQueue + 1] = data
end

function XQuestOperation:Dequeue()
    self:RecycleRunning()
    --没有数据
    if self:IsEmpty() then
        return true
    end
    ---@type XBigWorldQuestData
    local data = tableRemove(self._QuestQueue, 1)
    if not data then
        XLog.Error("XQuestOperation:Dequeue - No data to dequeue")
        return false
    end
    if not data:IsAlive() then
        XLog.Error("XQuestOperation:Dequeue - Data is recycled, cannot dequeue")
        return false
    end
    local isInstLevel = XMVCA.XBigWorldGamePlay:IsInstLevel()
    local isInstQuest = XMVCA.XBigWorldQuest:IsInstQuest(data:GetQuestId())
    if isInstQuest ~= isInstLevel then
        --这两种状态需要先把事件给移除掉
        if data.Operate == XMVCA.XBigWorldQuest.QuestOpType.QuestUnTrack 
                or data.Operate == XMVCA.XBigWorldQuest.QuestOpType.QuestFinish then
            self._View:RemoveStepValueChangeListener(data.QuestId)
        end
        self:RecycleQuest(data)
        return false
    end
    local behavior = self._OperateBehavior[data:GetOperate()]
    if not behavior then
        XLog.Error("XQuestOperation:Dequeue - No behavior for operate: " .. tostring(data:GetOperate()))
        self:RecycleQuest(data)
        return false
    end
    self._RunningData = data
    return true, behavior(data)
end

---@param data XBigWorldQuestData
function XQuestOperation:CheckData(data)
    if not data or not data:IsAlive() then
        return false
    end
    local addCode = data:GetHashCode()
    --取消追踪
    local isUnTrack = data:GetOperate() == XMVCA.XBigWorldQuest.QuestOpType.QuestUnTrack
    for i = #self._QuestQueue, 1, -1 do
        local questData = self._QuestQueue[i]
        --数据已经存在
        if questData:GetHashCode() == addCode then
            return false
        end

        --如果是取消追踪操作，且队列中存在追踪操作，则移除追踪操作
        if isUnTrack and questData:GetQuestId() == data:GetQuestId()
                and questData:GetOperate() == XMVCA.XBigWorldQuest.QuestOpType.QuestTrack then
            tableRemove(self._QuestQueue, i)
            --回收数据
            self:RecycleQuest(questData)
            return false
        end
    end
    return true
end

function XQuestOperation:IsEmpty()
    return #self._QuestQueue <= 0
end

function XQuestOperation:InitDataFunc()
    local operate = XMVCA.XBigWorldQuest.QuestOpType

    self:AddDataFunc(operate.QuestTrack, self.GetQuestTrack)
    self:AddDataFunc(operate.QuestUnTrack, self.GetQuestUnTrack)
    self:AddDataFunc(operate.QuestFinish, self.GetQuestFinish)
    self:AddDataFunc(operate.StepActive, self.GetStepActive)
    self:AddDataFunc(operate.StepFinish, self.GetStepFinish)
    self:AddDataFunc(operate.ObjectiveActive, self.GetObjectiveActive)
    self:AddDataFunc(operate.ObjectiveFinish, self.GetObjectiveFinish)
    self:AddDataFunc(operate.ObjectiveRefresh, self.GetObjectiveRefresh)
end

function XQuestOperation:AddDataFunc(operate, func)
    if not operate or not func then
        return
    end
    self._OperateDataFunc[operate] = handler(self, func)
end

function XQuestOperation:GetTrackQuestId()
    return XMVCA.XBigWorldQuest:GetTrackQuestId()
end

function XQuestOperation:GetInProgressQuest(questId)
    if not questId or questId <= 0 then
        return nil
    end
    local quest = XMVCA.XBigWorldQuest:GetQuestData(questId)
    if not (quest:IsInProgress() or quest:IsReady()) then
        return nil
    end
    return quest
end

---@param step XBigWorldQuestStep
---@return boolean, XBigWorldObjectiveData|XBigWorldObjectiveData[]
function XQuestOperation:GetObjective(step)
    local dict = step:GetObjectiveDict()
    local isSerial = XMVCA.XBigWorldQuest:IsSerialStep(step:GetId())
    local isParallel = XMVCA.XBigWorldQuest:IsParallelStep(step:GetId())
    local data
    if isParallel then
        data = {}
    end
    local State = XMVCA.XBigWorldQuest.ObjectiveState
    for _, objective in pairs(dict) do
        if isSerial then
            local state = objective:GetObjectiveState()
            if state ~= State.Finished and state ~= State.InActive then
                data = self:CreateObjective(objective)
                break
            end
        elseif isParallel then
            local temp = self:CreateObjective(objective)
            if temp then
                data[#data + 1] = temp
            end
        end
    end
    return isSerial, data
end

function XQuestOperation:GetStepTitle(stepId)
    if not stepId or stepId <= 0 then
        return nil
    end
    local title = XMVCA.XBigWorldQuest:GetQuestStepTextByStepId(stepId)
    local key
    if not string.IsNilOrEmpty(title) then
        key = string.match(title, Pattern)
        if not string.IsNilOrEmpty(key) then
            local before, after = string.match(title, SplitPattern)
            if not string.IsNilOrEmpty(before) then
                title = before
            elseif not string.IsNilOrEmpty(after) then
                title = after
            end
        end
    end
    return title, key
end

--- 获取任务追踪数据
---@return XBigWorldQuestData
function XQuestOperation:GetQuestTrack(operate, questId, stepId, objectiveId)
    local trackId = self:GetTrackQuestId()
    ---如果没有追踪任务，则不处理
    if trackId ~= questId then
        return
    end
    local quest = self:GetInProgressQuest(questId)
    if not quest then
        return
    end
    local step = quest:GetActiveStepData()
    if not step then
        return
    end
    local isSerial, objectiveData = self:GetObjective(step)
    if isSerial and not objectiveData then
        return
    end
    if not isSerial and XTool.IsTableEmpty(objectiveData) then
        return
    end
    stepId = step:GetId()
    local data = self:RetainQuest()

    data:SetParams(operate, questId, stepId, isSerial, objectiveData, false)

    return data
end

--- 获取任务取消追踪数据
---@return XBigWorldQuestData
function XQuestOperation:GetQuestUnTrack(operate, questId, stepId, objectiveId)
    local data = self:RetainQuest()
    data:SetParams(operate, questId, 0, false, nil, false)

    return data
end

--- 获取任务完成数据
---@return XBigWorldQuestData
function XQuestOperation:GetQuestFinish(operate, questId, stepId, objectiveId)
    local trackId = self:GetTrackQuestId()
    ---如果没有追踪任务，则不处理
    if trackId ~= questId then
        return
    end
    local data = self:RetainQuest()
    data:SetParams(operate, questId, 0, false, nil, false)

    return data
end

--- 获取步骤激活数据
---@return XBigWorldQuestData
function XQuestOperation:GetStepActive(operate, questId, stepId, objectiveId)
    local trackId = self:GetTrackQuestId()
    local isTempShow = false
    ---如果没有追踪任务，则不处理
    if trackId ~= questId and questId > 0 then
        -- 任务状态更新时，需要在界面上临时展示
        if XMVCA.XBigWorldQuest:IsFirstStatusBarPlay(questId)
                and not XMVCA.XBigWorldQuest:IsInstQuest(questId)
        then
            isTempShow = true
        else
            return
        end
    end
    local quest = self:GetInProgressQuest(questId)
    if not quest then
        return
    end
    local step = quest:GetActiveStepData()
    if not step or step:GetId() ~= stepId then
        return
    end
    local isSerial, objectiveData = self:GetObjective(step)
    if isSerial and not objectiveData then
        return
    end
    if not isSerial and XTool.IsTableEmpty(objectiveData) then
        return
    end
    local data = self:RetainQuest()
    data:SetParams(operate, questId, stepId, isSerial, objectiveData, isTempShow)

    return data
end

--- 获取步骤完成数据
---@return XBigWorldQuestData
function XQuestOperation:GetStepFinish(operate, questId, stepId, objectiveId)
    local trackId = self:GetTrackQuestId()
    ---如果没有追踪任务，则不处理
    if trackId ~= questId then
        return
    end
    local data = self:RetainQuest()
    data:SetParams(operate, questId, stepId, false, nil, false)

    return data
end

--- 获取目标激活数据
---@return XBigWorldQuestData
function XQuestOperation:GetObjectiveActive(operate, questId, stepId, objectiveId)
    if not objectiveId or objectiveId <= 0 or not questId or questId <= 0 then
        return nil
    end
    local title = XMVCA.XBigWorldQuest:GetObjectiveTitle(objectiveId)
    if string.IsNilOrEmpty(title) then
        return nil
    end
    local isTempShow = false
    local trackId = self:GetTrackQuestId()
    if trackId ~= questId and questId > 0 then
        -- 任务状态更新时，需要在界面上临时展示
        if XMVCA.XBigWorldQuest:IsFirstStatusBarPlay(questId)
                and not XMVCA.XBigWorldQuest:IsInstQuest(questId)
        then
            isTempShow = true
        else
            return
        end
    end
    local quest = self:GetInProgressQuest(questId)
    if not quest then
        return nil
    end
    local objective = quest:GetObjective(objectiveId)
    if not objective then
        return nil
    end
    local data = self:RetainQuest()
    data:SetParams(operate, questId, stepId, true, self:CreateObjective(objective), isTempShow, objective:IsSkipAnimation())

    return data
end

--- 获取目标完成数据
---@return XBigWorldQuestData
function XQuestOperation:GetObjectiveFinish(operate, questId, stepId, objectiveId)
    if not objectiveId or objectiveId <= 0 or not questId or questId <= 0 then
        return nil
    end
    local trackId = self:GetTrackQuestId()
    if trackId ~= questId then
        return nil
    end
    local title = XMVCA.XBigWorldQuest:GetObjectiveTitle(objectiveId)
    if string.IsNilOrEmpty(title) then
        return nil
    end

    local quest = self:GetInProgressQuest(questId)
    if not quest then
        return nil
    end
    local objective = quest:GetObjective(objectiveId)
    if not objective then
        return nil
    end
    if objective:IsSkipAnimation() then
        return nil
    end
    local data = self:RetainQuest()
    data:SetParams(operate, questId, stepId, true, self:CreateObjective(objective), false, objective:IsSkipAnimation())

    return data
end

--- 获取目标刷新数据
---@return XBigWorldQuestData
function XQuestOperation:GetObjectiveRefresh(operate, questId, stepId, objectiveId)
    if not objectiveId or objectiveId <= 0 or not questId or questId <= 0 then
        return nil
    end
    local trackId = self:GetTrackQuestId()
    if trackId ~= questId then
        return nil
    end
    local title = XMVCA.XBigWorldQuest:GetObjectiveTitle(objectiveId)
    if string.IsNilOrEmpty(title) then
        return nil
    end
    local quest = self:GetInProgressQuest(questId)
    if not quest then
        return nil
    end
    local objective = quest:GetObjective(objectiveId)
    if not objective then
        return nil
    end
    local data = self:RetainQuest()
    if objective:IsRunning() then
        data:SetParams(operate, questId, stepId, true, self:CreateObjective(objective), false, objective:IsSkipAnimation())
    else
        data:SetParams(operate, 0, 0, true, self:CreateObjective(objective), false, objective:IsSkipAnimation())
    end
    
    return data
end


--endregion

--region 行为操作

function XQuestOperation:InitBehavior()
    local operate = XMVCA.XBigWorldQuest.QuestOpType

    self:AddBehavior(operate.QuestTrack, self.DoQuestTrack)
    self:AddBehavior(operate.QuestUnTrack, self.DoQuestUnTrack)
    self:AddBehavior(operate.QuestFinish, self.DoQuestFinish)
    self:AddBehavior(operate.StepActive, self.DoStepActive)
    self:AddBehavior(operate.StepFinish, self.DoStepFinish)
    self:AddBehavior(operate.ObjectiveActive, self.DoObjectiveActive)
    self:AddBehavior(operate.ObjectiveFinish, self.DoObjectiveFinish)
    self:AddBehavior(operate.ObjectiveRefresh, self.DoObjectiveRefresh)
end

function XQuestOperation:AddBehavior(operate, behavior)
    if not operate or not behavior then
        return
    end
    self._OperateBehavior[operate] = handler(self, behavior)
end

--- 任务追踪 
---@param data XBigWorldQuestData
function XQuestOperation:DoQuestTrack(data)
    self._View:RefreshQuest(data:GetQuestId())
    local stepId = data:GetStepId()
    local title, key = self:GetStepTitle(stepId)
    local isSpecialTitle = not string.IsNilOrEmpty(key)
    if isSpecialTitle then
        self._View:AddStepValueChangeListener(data:GetQuestId(), key)
    end
    self._View:RefreshStep(stepId, title, isSpecialTitle)
    self._View:HideAllObjective()
    if data:CheckIsSingle() then
        local objective = data:GetObjective()
        self._View:RefreshObjective(objective, 1)
    else
        local objectiveList = data:GetObjectiveList()
        if not XTool.IsTableEmpty(objectiveList) then
            for i, objective in pairs(objectiveList) do
                self._View:RefreshObjective(objective, i)
            end
        end
    end
    self._View:InsertAnimationAction("TaskEnable")

    self._View:StartAction()
end

--- 任务取消追踪
---@param data XBigWorldQuestData
function XQuestOperation:DoQuestUnTrack(data)
    self._View:RemoveStepValueChangeListener(data.QuestId)
    self._View:InsertAnimationAction("TaskDisable")
    self._View:InsertFuncAction(self._View.HideAll, self._View)
    self._View:StartAction()
end

--- 任务完成
---@param data XBigWorldQuestData
function XQuestOperation:DoQuestFinish(data)
    self._View:RemoveStepValueChangeListener(data.QuestId)
    self._View:InsertAnimationAction("TaskDisable")
    self._View:InsertFuncAction(self._View.HideAll, self._View)
    self._View:StartAction()
end

--- 步骤激活
---@param data XBigWorldQuestData
function XQuestOperation:DoStepActive(data)
    local stepId = data:GetStepId()
    local title, _ = self:DoRefreshStep(data:GetQuestId(), stepId)
    self._View:HideAllObjective()
    

    --并行的情况下，在步骤激活时就播放动画，不然表现很拖沓
    if XMVCA.XBigWorldQuest:IsParallelStep(stepId) then
        if data:CheckIsSingle() then
            local objective = data:GetObjective()
            self._View:RefreshObjective(objective, 1)
            self._View:PlayObjectiveAnimation(objective:GetId(), true, false, false)
        else
            local objectiveList = data:GetObjectiveList()
            if not XTool.IsTableEmpty(objectiveList) then
                for i, objective in pairs(objectiveList) do
                    self._View:InsertDelayAction((i - 1) * 50)
                    self._View:InsertFuncAction(self._View.RefreshObjective, self._View, objective, i)
                    self._View:InsertFuncAction(self._View.PlayObjectiveAnimation, self._View, objective:GetId(), true, false, false)
                end
            end
        end
    else
        --有文本才播放动画
        if not string.IsNilOrEmpty(title) then
            self._View:InsertAnimationAction("StepStart")
        end
    end

    self._View:StartAction()
end

--- 步骤完成
---@param data XBigWorldQuestData
function XQuestOperation:DoStepFinish(data)
    --self._View:RemoveStepValueChangeListener(data:GetQuestId())
    --有文本才播放动画
    if not string.IsNilOrEmpty(XMVCA.XBigWorldQuest:GetQuestStepTextByStepId(data:GetStepId())) then
        self._View:InsertAnimationAction("StepFinish")
    end
    self._View:HideAllObjective()

    self._View:StartAction()
end

--- 目标激活
---@param data XBigWorldQuestData
function XQuestOperation:DoObjectiveActive(data)
    local isSkipAnimation = data:CheckIsSkipAnimation()
    self._View:RefreshQuest(data:GetQuestId())
    if data:CheckIsTempShow() then
        if not isSkipAnimation then
            self._View:InsertAnimationAction("TaskEnable")
        end
        local title, key = self:DoRefreshStep(data:GetQuestId(), data:GetStepId())
        --有文本才播放动画
        if not string.IsNilOrEmpty(title) and not isSkipAnimation then
            self._View:InsertAnimationAction("StepStart")
        end
    --else
    --    self._View:RefreshBtnGo(data:GetQuestId())
    end
    --由于数据更新时机，可能会出现先刷新目标激活再追踪任务
    if not self._View:IsDisplay() then
        self._View:InsertAnimationAction("TaskEnable")
    end
    --并行的情况下，在步骤激活时就播放动画，这里则不处理
    if XMVCA.XBigWorldQuest:IsSerialStep(data:GetStepId()) then
        if data:CheckIsSingle() then
            local objective = data:GetObjective()
            self._View:RefreshObjective(objective, 1)
            if not isSkipAnimation then
                self._View:InsertObjectiveAnimation(objective:GetId(), false, true, false)
            end
        else
            local objectiveList = data:GetObjectiveList()
            if not XTool.IsTableEmpty(objectiveList) then
                for i, objective in pairs(objectiveList) do
                    self._View:RefreshObjective(objective, i)
                    if not isSkipAnimation then
                        self._View:InsertObjectiveAnimation(objective:GetId(), false, true, false)
                    end
                end
            end
        end
    end
    if data:CheckIsTempShow() then
        self._View:InsertTempShow(3000)
    end
    self._View:StartAction()
end

--- 目标完成
---@param data XBigWorldQuestData
function XQuestOperation:DoObjectiveFinish(data)
    self._View:RefreshQuest(data:GetQuestId(), true)
    --串行任务，目标完成则隐藏跳转按钮
    if XMVCA.XBigWorldQuest:IsSerialStep(data:GetStepId()) then
        self._View:RefreshBtnGo(0)
    else --并行时
        self._View:RefreshBtnGo(data:GetQuestId())
    end
    if data:CheckIsSingle() then
        local objective = data:GetObjective()
        self._View:RefreshObjective(objective, self._View:GetGridObjectiveIndex(objective:GetId()))
        if not data:CheckIsSkipAnimation() then
            self._View:InsertObjectiveAnimation(objective:GetId(), false, false, true)
        end
    else
        local objectiveList = data:GetObjectiveList()
        if not XTool.IsTableEmpty(objectiveList) then
            for i, objective in pairs(objectiveList) do
                self._View:RefreshObjective(objective, self._View:GetGridObjectiveIndex(objective:GetId()))
                if not data:CheckIsSkipAnimation() then
                    self._View:InsertObjectiveAnimation(objective:GetId(), false, false, true)
                end
            end
        end
    end

    self._View:StartAction()
end

--- 刷新目标
---@param data XBigWorldQuestData
function XQuestOperation:DoObjectiveRefresh(data)
    self._View:RefreshQuest(data:GetQuestId())
    if data:CheckIsSingle() then
        local objective = data:GetObjective()
        self._View:RefreshObjective(objective, self._View:GetGridObjectiveIndex(objective:GetId()))
    else
        local objectiveList = data:GetObjectiveList()
        if not XTool.IsTableEmpty(objectiveList) then
            for _, objective in pairs(objectiveList) do
                self._View:RefreshObjective(objective, self._View:GetGridObjectiveIndex(objective:GetId()))
            end
        end
    end

    self._View:StartAction()
end

function XQuestOperation:DoRefreshStep(questId, stepId)
    local title, key = self:GetStepTitle(stepId)
    local isSpecialTitle = not string.IsNilOrEmpty(key)
    if isSpecialTitle then
        self._View:AddStepValueChangeListener(questId, key)
    end
    self._View:RefreshStep(stepId, title, isSpecialTitle)
    
    return title, key
end

--endregion

--region 数据操作

---@param questData XBigWorldQuestData
function XQuestOperation:RecycleQuest(questData)
    if not questData then
        return
    end
    if not questData:IsAlive() then
        XLog.Error("XQuestOperation:RecycleQuest - questData is already recycled")
        return
    end
    if questData:CheckIsSingle() then
        local objective = questData:GetObjective()
        if objective then
            self:RecycleObjective(objective)
        end
    else
        local list = questData:GetObjectiveList()
        if not XTool.IsTableEmpty(list) then
            for _, objective in pairs(list) do
                self:RecycleObjective(objective)
            end
        end
    end

    questData:Recycle()
    self._QuestPool[#self._QuestPool + 1] = questData
end

---@return XBigWorldQuestData
function XQuestOperation:RetainQuest()
    ---@type XBigWorldQuestData
    local data
    if #self._QuestPool > 0 then
        data = tableRemove(self._QuestPool, 1)
        data:Retain()
    else
        data = XBigWorldQuestData.New()
    end

    return data
end

---@param objectiveData XBigWorldObjectiveData
function XQuestOperation:RecycleObjective(objectiveData)
    if not objectiveData then
        return
    end
    if not objectiveData:IsAlive() then
        XLog.Error("XQuestOperation:RecycleObjective - objectiveData is already recycled")
        return
    end

    objectiveData:Recycle()
    self._ObjectivePool[#self._ObjectivePool + 1] = objectiveData
end

---@return XBigWorldObjectiveData
function XQuestOperation:RetainObjective()
    ---@type XBigWorldObjectiveData
    local data
    if #self._ObjectivePool > 0 then
        data = tableRemove(self._ObjectivePool, 1)
        data:Retain()
    else
        data = XBigWorldObjectiveData.New()
    end

    return data
end

---@param objectiveData XBigWorldQuestObjective
function XQuestOperation:CreateObjective(objectiveData)
    local id = objectiveData:GetId()
    local title = XMVCA.XBigWorldQuest:GetObjectiveTitle(id)
    ---如果标题为空，则不处理
    if string.IsNilOrEmpty(title) then
        return nil
    end
    local data = self:RetainObjective()
    local description = XMVCA.XBigWorldQuest:GetObjectiveProgressDesc(objectiveData:GetId(), objectiveData:GetProgress(), objectiveData:GetMaxProgress())
    local isComplete = objectiveData:IsFinish()
    data:SetParams(objectiveData:GetId(), description, isComplete)

    return data
end

function XQuestOperation:RecycleRunning()
    if self._RunningData and self._RunningData:IsAlive() then
        self:RecycleQuest(self._RunningData)
    end
    self._RunningData = nil
end

function XQuestOperation:Clear()
    for i = #self._QuestQueue, 1, -1 do
        local data = tableRemove(self._QuestQueue, i)
        self:RecycleQuest(data)
    end
    self:RecycleRunning()
end

--endregion

return XQuestOperation