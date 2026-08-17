local XUiGridEnvelopeGuessingTaskType = require("XUi/XUiEnvelopeGuessing/XUiGridEnvelopeGuessingTaskType")
---@class XUiEnvelopeGuessingTask : XLuaUi
---@field private _Control XEnvelopeGuessingControl
local XUiEnvelopeGuessingTask = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingTask")

function XUiEnvelopeGuessingTask:OnStart()
    self:_RegisterButtons()

    self._TaskTypeOrdered = XTool.ToArray(XMVCA.XEnvelopeGuessing.TaskType)
    table.sort(self._TaskTypeOrdered, function(a, b)
        return a.Priority < b.Priority
    end)

    self._OnReceiveClickedHandler = handler(self, self._OnReceiveClicked)

    -- 设置自动关闭
    self:SetAutoCloseInfo(XMVCA.XEnvelopeGuessing:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiEnvelopeGuessingTask:OnEnable()
    self._IsPlayAnim = true
    self:_Refresh()
end

function XUiEnvelopeGuessingTask:OnGetLuaEvents()
    return {
        XEventId.EVENT_DAILY_RESET,
        XEventId.EVENT_ENVELOPE_UPDATE_DATA,
    }
end

function XUiEnvelopeGuessingTask:OnNotify(event, ...)
    if event == XEventId.EVENT_DAILY_RESET or event == XEventId.EVENT_ENVELOPE_UPDATE_DATA then
        self:_Refresh()
    end
end

function XUiEnvelopeGuessingTask:OnDisable()
    self:_StopPlayStepsStagger()
end

function XUiEnvelopeGuessingTask:_Refresh()
    self:_StopPlayStepsStagger()

    if self._GridTaskTypes then
        for _, v in pairs(self._GridTaskTypes) do
            v:Clear()
        end
    else
        self._GridTaskTypes = {}
    end

    self.GridTask.gameObject:SetActiveEx(false)
    local playSteps = self:_BuildAll()
    if self._IsPlayAnim then
        self._IsPlayAnim = false
        self:_PlayStepsStagger(playSteps)
    end
end

function XUiEnvelopeGuessingTask:_BuildAll()
    local steps = {}

    for typeIndex, taskType in ipairs(self._TaskTypeOrdered) do
        local uiTaskType = self._GridTaskTypes[typeIndex]
        if not uiTaskType then
            local go = XUiHelper.Instantiate(self.GridTask, self.ContentTasks)
            uiTaskType = XUiGridEnvelopeGuessingTaskType.New(go, self)
            self._GridTaskTypes[typeIndex] = uiTaskType
        end
        uiTaskType:Open()
        uiTaskType:SetData(taskType, self._OnReceiveClickedHandler)

        steps[#steps + 1] = { Node = uiTaskType, Anim = "PanelTaskTitleEnable" }
        for _, taskGrid in ipairs(uiTaskType:BuildTasks()) do
            steps[#steps + 1] = { Node = taskGrid, Anim = "PanelTaskEnable" }
        end
    end

    return steps
end

function XUiEnvelopeGuessingTask:_PlayStepsStagger(steps)
    local count = #steps
    if count == 0 then
        return
    end

    XLuaUiManager.SetMask(true, self.Name)

    for _, step in ipairs(steps) do
        step.Node:Close()
    end

    local interval = 20 -- 间隔20毫秒
    local index = 0
    self._ScheduleLoading = XScheduleManager.Schedule(function()
        index = index + 1
        local step = steps[index]
        if step then
            step.Node:Open()
            step.Node:PlayAnimation(step.Anim)
        end
        if index >= count then
            self:_StopPlayStepsStagger()
        end
    end, interval, count, 0)
end

function XUiEnvelopeGuessingTask:_StopPlayStepsStagger()
    if self._ScheduleLoading then
        XScheduleManager.UnSchedule(self._ScheduleLoading)
        self._ScheduleLoading = nil
    end
    if XLuaUiManager.IsMaskShow(self.Name) then
        XLuaUiManager.SetMask(false, self.Name)
    end
end

function XUiEnvelopeGuessingTask:_RegisterButtons()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
end

function XUiEnvelopeGuessingTask:_OnReceiveClicked()
    local allArchivedTaskIds = {}

    for _, taskType in pairs(self._TaskTypeOrdered) do
        local taskIds = XMVCA.XEnvelopeGuessing:GetActivityTaskIds(taskType)
        for _, taskId in pairs(taskIds) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(allArchivedTaskIds, taskId)
            end
        end
    end

    if XTool.IsTableEmpty(allArchivedTaskIds) then
        return
    end

    XDataCenter.TaskManager.FinishMultiTaskRequest(allArchivedTaskIds, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList, nil, handler(self, self._Refresh))
    end)
end

return XUiEnvelopeGuessingTask
