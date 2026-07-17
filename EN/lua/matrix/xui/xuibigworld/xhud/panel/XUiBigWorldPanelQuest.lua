local XUiGridBWQuestItem = require("XUi/XUiBigWorld/XHud/Grid/XUiGridBWQuestItem")

---@class XUiBigWorldPanelQuest : XUiNode
---@field Parent XUiBigWorldHud
---@field _OperateBehavior XQuestOperation
---@field _ActionContainer XQuestActionContainer
---@field _GridObjectiveList table<number, XUiGridBWQuestItem>
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiBigWorldPanelQuest = XClass(XUiNode, "XUiBigWorldPanelQuest")

function XUiBigWorldPanelQuest:OnStart()
    self:InitUi()
    self:InitCb()
    self:AddEventListener()
end

function XUiBigWorldPanelQuest:OnEnable()
    self:AfterPauseRefresh()
end

function XUiBigWorldPanelQuest:OnDisable()
    self._PopupCount = 0
    self._ActionContainer:Pause()
end

function XUiBigWorldPanelQuest:OnDestroy()
    self:RemoveEventListener()
end

function XUiBigWorldPanelQuest:InitUi()
    self._GridObjectiveList = {}
    
    self._PopupCount = 0

    self.BtnTrack.gameObject:SetActiveEx(false)
    self.BtnGo.gameObject:SetActiveEx(false)
    self.BtnTrack:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("StartTrackText"))
    
    self.PanelQuest.gameObject:SetActiveEx(true)
    self.GridQuest.gameObject:SetActiveEx(false)
    
    self:HideAll()
    self._OperateBehavior = require("XUi/XUiBigWorld/XHud/Operation/XQuestOperation").New(self)

    self._OnActionFinishListener = function()
        if not self._OperateBehavior then
            return
        end
        self:Dequeue()
    end
    self.CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    self._StepChangeKey = nil
    self._StepChangeValue = {}
    self._ActionContainer = require("XUi/XUiBigWorld/XHud/Action/XQuestActionContainer").New(self._OnActionFinishListener)
end

function XUiBigWorldPanelQuest:InitCb()
    XUiHelper.RegisterClickEvent(self, self.PanelTitle, self.OnQuestClick)
    self._OnStepValueChangeListener = function(data)
        self:OnStepValueChange(data)
    end
    
    self._OnTrackFinishListener = function()
        self:SetBtnTrackActive(false)
    end
    
    self.BtnTrack:AddEventListener(handler(self, self.OnBtnTrackClick))
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
end

function XUiBigWorldPanelQuest:AddEventListener()
    local eventId = XMVCA.XBigWorldService.DlcEventId
    
    XEventManager.AddEventListener(eventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.Enqueue, self)
    XEventManager.AddEventListener(eventId.EVENT_MAP_PIN_ADD, self.AfterMapPinAdd, self)
    XEventManager.AddEventListener(eventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.AfterTempShowRefresh, self)
end

function XUiBigWorldPanelQuest:RemoveEventListener()
    local eventId = XMVCA.XBigWorldService.DlcEventId

    XEventManager.RemoveEventListener(eventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self.Enqueue, self)
    XEventManager.RemoveEventListener(eventId.EVENT_MAP_PIN_ADD, self.AfterMapPinAdd, self)
    XEventManager.RemoveEventListener(eventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.AfterTempShowRefresh, self)
end

function XUiBigWorldPanelQuest:Enqueue(operate, questId, stepId, objectiveId)
    if operate == XMVCA.XBigWorldQuest.QuestOpType.PopupBegin then
        self._PopupCount = self._PopupCount + 1
    elseif operate == XMVCA.XBigWorldQuest.QuestOpType.PopupEnd then
        self._PopupCount = self._PopupCount - 1
    else
        self._OperateBehavior:Enqueue(operate, questId, stepId, objectiveId)
    end
    self:Dequeue()
end

function XUiBigWorldPanelQuest:Dequeue()
    if not self:CheckDequeue() then 
        return
    end
    if self._ActionContainer:IsRunning() then
        return
    end

    if self._OperateBehavior:IsEmpty() then
        return
    end
    
    local res, _ = self._OperateBehavior:Dequeue()
    -- 出栈失败，重新出
    if not res then
        return self:Dequeue()
    end
end

function XUiBigWorldPanelQuest:CheckDequeue()
    if self._PopupCount > 0 then
        return false
    end
    if not self.GameObject.activeInHierarchy then
        return false
    end
    return true
end

function XUiBigWorldPanelQuest:RefreshQuest(questId, ignoreBtn)
    if questId and questId > 0 then
        self.PanelTitle.gameObject:SetActiveEx(true)
        self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
        local sprite = XMVCA.XBigWorldQuest:GetQuestIcon(questId)
        if not string.IsNilOrEmpty(sprite) then
            self.ImgTitle:SetSprite(sprite)
        end
    else
        self.PanelTitle.gameObject:SetActiveEx(false)
    end
    if not ignoreBtn then
        self:RefreshBtnGo(questId)
    end
    self._DisplayQuestId = questId
end

function XUiBigWorldPanelQuest:RefreshStep(stepId, stepTitle, isSpecialStepTitle)
    if string.IsNilOrEmpty(stepTitle) then
        self.TxtStep.gameObject:SetActiveEx(false)
        self.PanelPoint.gameObject:SetActiveEx(false)
    else
        self.TxtStep.gameObject:SetActiveEx(not isSpecialStepTitle)
        self.PanelPoint.gameObject:SetActiveEx(isSpecialStepTitle)
        if isSpecialStepTitle then
            self.TxtPoint.text = stepTitle
        else
            self.TxtStep.text = stepTitle
        end
    end
end

--- 刷新任务目标
---@param objective XBigWorldObjectiveData
function XUiBigWorldPanelQuest:RefreshObjective(objective, index)
    if not objective or not objective.Id or objective.Id <= 0 then
        return
    end
    if index <= 0 then
        return
    end
    local grid = self._GridObjectiveList[index]
    if not grid then
        local ui = index == 1 and self.GridQuest or XUiHelper.Instantiate(self.GridQuest, self.GridQuest.transform.parent)
        grid = XUiGridBWQuestItem.New(ui, self)
        self._GridObjectiveList[index] = grid
    end
    grid:Update(objective, index)
    grid:Open()
end

--- 刷新任务目标
---@param id number
function XUiBigWorldPanelQuest:GetGridObjectiveIndex(id)
    for index, grid in pairs(self._GridObjectiveList) do
        if grid:GetObjectiveId() == id and grid:IsNodeShow() then
            return index
        end
    end
    return -1
end

-- 隐藏所有任务目标
function XUiBigWorldPanelQuest:HideAllObjective()
    for _, grid in pairs(self._GridObjectiveList) do
        grid:Close()
    end
end

function XUiBigWorldPanelQuest:PlayObjectiveAnimation(id, isFade, isEnable, isFinish)
    for _, grid in pairs(self._GridObjectiveList) do
        if grid:GetObjectiveId() == id and grid:IsNodeShow() then
            if isEnable then
                grid:PlayYellowFlash()
            elseif isFinish then
                grid:PlayGreenFlash()
            elseif isFade then
                grid:PlayFade()
            end
            return
        end
    end
end

function XUiBigWorldPanelQuest:SetBtnTrackActive(value)
    if XTool.UObjIsNil(self.BtnTrack) then
        return
    end
    self.BtnTrack.gameObject:SetActiveEx(value)
end

function XUiBigWorldPanelQuest:SetBtnGoActive(value)
    if XTool.UObjIsNil(self.BtnGo) then
        return
    end
    self.BtnGo.gameObject:SetActiveEx(value)
end

function XUiBigWorldPanelQuest:RefreshBtnGo(questId)
    if not questId or questId <= 0 then
        self:SetBtnGoActive(false)
        return
    end
    --是否为副本任务
    local isInstQuest = XMVCA.XBigWorldQuest:IsInstQuest(questId)
    --是否为追踪任务
    local isTrackQuest = questId == XMVCA.XBigWorldQuest:GetTrackQuestId()
    --任务是否完成
    local isFinish = XMVCA.XBigWorldQuest:CheckQuestFinish(questId)
    if (not isFinish or XMVCA.XBigWorldQuest:IsInviteQuest(questId)) and not isInstQuest and isTrackQuest then
        local skipTxt = XMVCA.XBigWorldQuest:GetQuestSkipToText(XMVCA.XBigWorldQuest:GetQuestSkipInfo(questId))
        if not string.IsNilOrEmpty(skipTxt) then
            self.BtnGo:SetNameByGroup(0, skipTxt)
            self:SetBtnGoActive(true)
        else
            self:SetBtnGoActive(false)
        end
    else
        self:SetBtnGoActive(false)
    end
end

function XUiBigWorldPanelQuest:HideAll()
    self:RefreshQuest(0)
    self:RefreshStep(0, nil, false)
    self:HideAllObjective()
    self:SetBtnTrackActive(false)
    self:SetBtnGoActive(false)
end

function XUiBigWorldPanelQuest:RefreshAll()
    local trackId = XMVCA.XBigWorldQuest:GetTrackQuestId()
    if not trackId or trackId <= 0 then
        self:HideAll()
        return
    end
    self:AfterTempShowRefresh()
end

function XUiBigWorldPanelQuest:AfterMapPinAdd()
    --如果队列里还有内容，则以任务的数据为权威
    if not self._OperateBehavior:IsEmpty() then
        return
    end
    self:AfterTempShowRefresh()
end

function XUiBigWorldPanelQuest:AfterTempShowRefresh()
    local trackId = XMVCA.XBigWorldQuest:GetTrackQuestId()
    if trackId > 0 then
        --仅仅刷新界面即可
        if self.CanvasGroup.alpha > 0 and self._DisplayQuestId == trackId then
            self:RefreshQuest(trackId)
        else
            self:Enqueue(XMVCA.XBigWorldQuest.QuestOpType.QuestTrack, trackId, 0, 0)
        end
    else
        self:Enqueue(XMVCA.XBigWorldQuest.QuestOpType.QuestUnTrack, 0, 0, 0)
    end
end

function XUiBigWorldPanelQuest:AfterPauseRefresh()
    if not self:CheckDequeue() then
        return
    end
    self._ActionContainer:Resume()

    if not self._ActionContainer:IsRunning() then
        if self._OperateBehavior:IsEmpty() then
            self:RefreshAll()
        else
            self:Dequeue()
        end
    end
end

--- 任务步骤值变化回调
function XUiBigWorldPanelQuest:OnStepValueChange(data)
    if not data or string.IsNilOrEmpty(data.Key) then
        return
    end
    if self._StepChangeKey ~= data.Key then
        return
    end
    local value = data.Value or 0
    self._StepChangeValue[#self._StepChangeValue + 1] = value
    self:TryStartScoreTimer()
end

function XUiBigWorldPanelQuest:RefreshScore(oldValue, newValue)
    local changeValue = newValue - oldValue

    if changeValue > 0 then
        self.TxtPointNumberAdd.text = string.format("+%d", changeValue)
        self.TxtPointNumberAdd.gameObject:SetActiveEx(true)
        self.TxtPointNumberMinus.gameObject:SetActiveEx(false)
        self:PlayAnimation("TxtPointNumberAdd")
    elseif changeValue < 0 then
        self.TxtPointNumberMinus.text = changeValue
        self.TxtPointNumberMinus.gameObject:SetActiveEx(true)
        self.TxtPointNumberAdd.gameObject:SetActiveEx(false)
        self:PlayAnimation("TxtPointNumberMinus")
    else
        self.TxtPointNumberAdd.gameObject:SetActiveEx(false)
        self.TxtPointNumberMinus.gameObject:SetActiveEx(false)
    end

    self.TxtPointNumber.text = newValue
end

function XUiBigWorldPanelQuest:TryStartScoreTimer()
    if self._ScoreTimer then
        return
    end
    self._ScoreTimer = XScheduleManager.ScheduleForever(function()
        if #self._StepChangeValue <= 0 then
            self:StopScoreTimer()
            return
        end
        local value = table.remove(self._StepChangeValue, 1)
        self:RefreshScore(self._StepLastValue, value)
        self._StepLastValue = value
    end, 50)
end

function XUiBigWorldPanelQuest:StopScoreTimer()
    if not self._ScoreTimer then
        return
    end
    XScheduleManager.UnSchedule(self._ScoreTimer)
    self._ScoreTimer = nil
end

function XUiBigWorldPanelQuest:AddStepValueChangeListener(questId, key)
    if not questId or questId <= 0 or string.IsNilOrEmpty(key) then
        return
    end
    if self._StepChangeKey == key then
        return
    end

    self._StepChangeKey = key
    self._StepLastValue = 0
    self.TxtPointNumber.text = 0
    self.TxtPointNumberAdd.gameObject:SetActiveEx(false)
    self.TxtPointNumberMinus.gameObject:SetActiveEx(false)
    XMVCA.XBigWorldQuest:AddQuestValueChangeListener(questId, key, self._OnStepValueChangeListener)
end

function XUiBigWorldPanelQuest:RemoveStepValueChangeListener(questId)
    if not questId or questId <= 0 or string.IsNilOrEmpty(self._StepChangeKey) then
        return
    end
    XMVCA.XBigWorldQuest:RemoveQuestValueChangeListener(questId, self._StepChangeKey, self._OnStepValueChangeListener)
    self._StepChangeKey = nil
    for i = #self._StepChangeValue, 1, -1 do
        table.remove(self._StepChangeValue, i)
    end
    self._StepLastValue = 0
    self.TxtPointNumberAdd.gameObject:SetActiveEx(false)
    self.TxtPointNumberMinus.gameObject:SetActiveEx(false)
end

--region 按钮点击事件
function XUiBigWorldPanelQuest:OnBtnTrackClick()
    if not self._DisplayQuestId or self._DisplayQuestId <= 0 then
        return
    end
    if not self.BtnTrack.gameObject.activeInHierarchy then
        return
    end
    if XMVCA.XBigWorldQuest:CheckNormalQuestFinish(self._DisplayQuestId) then
        return
    end
    if XMVCA.XBigWorldQuest:CheckInviteQuestNotInProgress(self._DisplayQuestId) then
        return
    end
    self._OperateBehavior:Clear()
    self._ActionContainer:Clear()
    XMVCA.XBigWorldQuest:TrackQuest(self._DisplayQuestId, self._OnTrackFinishListener)
end

function XUiBigWorldPanelQuest:OnBtnGoClick()
    if not self._DisplayQuestId or self._DisplayQuestId <= 0 then
        return
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Task) then
        return
    end
    if not XMVCA.XBigWorldUI:IsQueueEmpty() then
        return
    end
    if XMVCA.XBigWorldCommon:HasAnySequentialJob() then
        return
    end
    XMVCA.XBigWorldQuest:TrySkipToByFightSkipInfo(XMVCA.XBigWorldQuest:GetQuestSkipInfo(self._DisplayQuestId))
end

function XUiBigWorldPanelQuest:OnQuestClick()
    if not self._DisplayQuestId or self._DisplayQuestId <= 0 then
        return
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Task) then
        return
    end
    if not XMVCA.XBigWorldUI:IsQueueEmpty() then
        return
    end
    if XMVCA.XBigWorldCommon:HasAnySequentialJob() then
        return
    end
    self.Parent:RecordQuestClick()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest(1, self._DisplayQuestId)
end
--endregion

function XUiBigWorldPanelQuest:StartAction()
    self._ActionContainer:Begin()
end

function XUiBigWorldPanelQuest:InsertAnimationAction(animName)
    local transform = self[animName]
    if not transform then
        transform = self.Transform:FindTransform(animName)
        self[animName] = transform
    end
    if not transform then
        XLog.Error("XUiBigWorldPanelQuest:InsertAnimationAction - Animation not found: " .. animName)
        return
    end
    local action = self._ActionContainer:RetainAction(XMVCA.XBigWorldQuest.ActionType.PlayAnimation, transform)
    self._ActionContainer:InsertAction(action)
end

function XUiBigWorldPanelQuest:InsertDelayAction(delay)
    if not delay or delay <= 0 then
        return
    end
    local action = self._ActionContainer:RetainAction(XMVCA.XBigWorldQuest.ActionType.Timer, delay)
    self._ActionContainer:InsertAction(action)
end

function XUiBigWorldPanelQuest:InsertFuncAction(func, caller, ...)
    local action = self._ActionContainer:RetainAction(XMVCA.XBigWorldQuest.ActionType.Func, func, caller, ...)
    self._ActionContainer:InsertAction(action)
end

function XUiBigWorldPanelQuest:InsertObjectiveAnimation(id, isFade, isEnable, isFinish)
    local action
    for _, grid in pairs(self._GridObjectiveList) do
        if grid:GetObjectiveId() == id and grid:IsNodeShow() then
            if isEnable then
                action = grid:CreateYellowFlash()
            elseif isFinish then
                action = grid:CreateGreenFlash()
            elseif isFade then
                action = grid:CreateFade()
            end
            break
        end
    end
    if action then
        self._ActionContainer:InsertAction(action)
    end
end

function XUiBigWorldPanelQuest:CreateObjectiveAnimation(transform)
    if not transform then
        XLog.Error("XUiBigWorldPanelQuest:CreateObjectiveAnimation - Transform is nil.")
        return nil
    end
    return self._ActionContainer:RetainAction(XMVCA.XBigWorldQuest.ActionType.PlayAnimation, transform)
end

function XUiBigWorldPanelQuest:InsertTempShow(delay)
    self:SetBtnTrackActive(true)
    self:InsertDelayAction(delay)
    self:InsertFuncAction(self.SetBtnTrackActive, self, false)
    self:InsertFuncAction(self.AfterTempShowRefresh, self)
end

function XUiBigWorldPanelQuest:IsDisplay()
    return self.CanvasGroup.alpha > 0
end


return XUiBigWorldPanelQuest