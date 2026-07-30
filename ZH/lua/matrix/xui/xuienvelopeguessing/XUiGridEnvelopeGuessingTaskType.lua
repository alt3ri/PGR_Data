local XUiGridCommon =
    require("XUi/XUiObtain/XUiGridCommon")

local XUiGridEnvelopeGuessingTaskType =
    XClass(XUiNode, "XUiGridEnvelopeGuessingTaskType")

local XUiGridEnvelopeGuessingTask =
    XClass(XUiNode, "XUiGridEnvelopeGuessingTask")

function XUiGridEnvelopeGuessingTask:OnStart()
    function self.BtnSkip.CallBack()
        if self._TaskCfg.SkipId and self._TaskCfg.SkipId ~= 0 then
            XFunctionManager.SkipInterface(self._TaskCfg.SkipId)
        end
    end
end

function XUiGridEnvelopeGuessingTask:SpawnRewards()
    for i, reward in ipairs(self._Rewards) do
        local grid = self._RewardGrids[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCommon, self.GridCommon.parent)
            grid = XUiGridCommon.New(self, go)
            self._RewardGrids[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(reward)
    end
end

function XUiGridEnvelopeGuessingTask:SetData(data, args)
    local cfg = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    self._TaskCfg = cfg
    self.TxtTaskName.text = cfg.Title
    self.TxtTaskDescribe.text = cfg.Desc
    self.TxtSubTypeTip.text = cfg.Suffix or ""

    if not self._RewardGrids then
        self._RewardGrids = {}
    end

    self._Rewards = XRewardManager.GetRewardList(cfg.RewardId) or {}

    self.GridCommon.gameObject:SetActiveEx(false)

    for _, grid in pairs(self._RewardGrids) do
        grid.GameObject:SetActiveEx(false)
    end

    local showProgress = #cfg.Condition < 2
    self.ImgProgress.transform.parent.gameObject:SetActiveEx(showProgress)
    self.TxtTaskNumQian.gameObject:SetActiveEx(showProgress)
    if not showProgress then return end

    local result = cfg.Result > 0 and cfg.Result or 1
    XTool.LoopMap(data.Schedule, function(_, pair)
        local current = math.min(pair.Value, result)
        self.ImgProgress.fillAmount = current / result
        self.TxtTaskNumQian.text = current .. "/" .. result
    end)

    self.BtnSkip.gameObject:SetActiveEx(false)
    self.BtnReceive.gameObject:SetActiveEx(false)
    self.BtnReceive.CallBack = args.OnReceiveClick

    if data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnReceive.gameObject:SetActiveEx(true)
        self.BtnReceive:SetDisable(false, true)
        self.BtnReceive:SetName(CS.XTextManager.GetText(
            "EnvelopeGuessingTaskButtonFinish"))

    elseif data.State == XDataCenter.TaskManager.TaskState.Finish then
        self.BtnReceive.gameObject:SetActiveEx(true)
        self.BtnReceive:SetDisable(true, false)
        self.BtnReceive:SetName(CS.XTextManager.GetText(
            args.TaskType.TaskButtonArchivedText))
    else
        self.BtnSkip.gameObject:SetActiveEx(true)
        if cfg.SkipId and cfg.SkipId ~= 0 then
            self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
            self.BtnSkip:SetName(CS.XTextManager.GetText(
                "EnvelopeGuessingTaskButtonSkip"))
        else
            self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
            self.BtnSkip:SetName(CS.XTextManager.GetText(
                "EnvelopeGuessingTaskButtonNotFinished"))
        end
    end
end

function XUiGridEnvelopeGuessingTaskType:OnStart()
    self._TaskGrid = {}
    self.PanelTask.gameObject:SetActiveEx(false)
end

function XUiGridEnvelopeGuessingTaskType:Clear()
    for _, grid in pairs(self._TaskGrid) do
        grid:Close()
    end
end

function XUiGridEnvelopeGuessingTaskType:BuildTasks()
    self._TaskGrid = self._TaskGrid or {}

    local grids = {}
    for i, task in ipairs(self._Tasks) do
        local grid = self._TaskGrid[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.PanelTask, self.Transform)
            grid = XUiGridEnvelopeGuessingTask.New(go, self)
            self._TaskGrid[i] = grid
        end

        grid:Open()
        grid:SetData(task, self._GridArg)
        grid:SpawnRewards()
        grids[i] = grid
    end

    return grids
end

function XUiGridEnvelopeGuessingTaskType:SetData(taskType, onReceiveClick)
    self.TxtTitle.text = CS.XTextManager.GetText(taskType.TitleText)
    self.TxtTime.gameObject:SetActiveEx(not not taskType.SubTitleText)

    if taskType.SubTitleText then
        self.TxtTime.text = CS.XTextManager.GetText(taskType.SubTitleText)
    end

    local taskIds = XMVCA.XEnvelopeGuessing:GetTaskIds(taskType)
    local tasks = {}

    for _, taskId in ipairs(taskIds) do
        local task = XDataCenter.TaskManager.GetTaskDataById(taskId)

        if self._Control:IsValidTaskState(task.State) then
            table.insert(tasks, task)
        end
    end

    local taskPriority = {
        [XDataCenter.TaskManager.TaskState.Achieved] = 1,
        [XDataCenter.TaskManager.TaskState.Accepted] = 2,
        [XDataCenter.TaskManager.TaskState.Active] = 2,
        [XDataCenter.TaskManager.TaskState.Finish] = 3
    }

    table.sort(tasks, function(a, b)
        if a.State == b.State then return a.Id < b.Id end
        return taskPriority[a.State] < taskPriority[b.State]
    end)

    self._Tasks = tasks
    self._TaskType = taskType
    self._GridArg = {
        TaskType = taskType,
        OnReceiveClick = onReceiveClick
    }
end

return XUiGridEnvelopeGuessingTaskType
