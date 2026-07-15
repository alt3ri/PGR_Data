local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@field _Control XPassportControl
---@class XUiPassportPanelTask:XUiNode
local XUiPassportPanelTask = XClass(XUiNode, "XUiPassportPanelTask")

local TaskTabConfig = {
    { Type = XEnumConst.PASSPORT.TASK_TYPE.DAILY, RedCondition = XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED },
    { Type = XEnumConst.PASSPORT.TASK_TYPE.WEEKLY, RedCondition = XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED },
    { Type = XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY, RedCondition = XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED },
}

function XUiPassportPanelTask:OnStart(model3d)
    self.CurrTabIndex = 0
    self.Model3D = model3d

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTask)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActive(false)

    self:InitTab()
    self:InitRedPoint()
end

function XUiPassportPanelTask:InitTab()
    local btnGroup = {}
    for i = 1, #TaskTabConfig do
        local btn = self["Btn0" .. i]
        if btn then
            table.insert(btnGroup, btn)
        end
    end

    self.PanelNoticeTitleBtnGroup:Init(btnGroup, function(index)
        self:OnSelectTab(index)
    end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(1)
end

function XUiPassportPanelTask:InitRedPoint()
    for i, config in ipairs(TaskTabConfig) do
        local btn = self["Btn0" .. i]
        if btn then
            self:AddRedPointEvent(btn, function(_, count)
                btn:ShowReddot(count >= 0)
            end, self, { config.RedCondition })
        end
    end
end

function XUiPassportPanelTask:OnSelectTab(index)
    if self.CurrTabIndex == index then
        return
    end
    self.CurrTabIndex = index
    self:Refresh()
end

function XUiPassportPanelTask:GetCurrTaskType()
    local config = TaskTabConfig[self.CurrTabIndex]
    return config and config.Type
end

function XUiPassportPanelTask:Refresh()
    if not self:IsShow() then
        return
    end

    local taskType = self:GetCurrTaskType()
    if not taskType then
        return
    end

    self.Tasks = self._Control:GetPassportTask(taskType)
    for _, taskData in ipairs(self.Tasks) do
        taskData.ExRewardId = self._Control:GetPassportTaskExRewardId(taskData.Id)
    end
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataSync()
    self:UpdateTabExRewardMark()

    self.TxtDaily.gameObject:SetActiveEx(false)
    self.TxtTurnChallenge.gameObject:SetActiveEx(false)
    self.TxtTurnRemainTime.gameObject:SetActiveEx(false)

    if taskType == XEnumConst.PASSPORT.TASK_TYPE.DAILY then
        self.TxtDaily.gameObject:SetActiveEx(true)
    elseif taskType == XEnumConst.PASSPORT.TASK_TYPE.WEEKLY then    -- 轮次任务
        self.TxtTurnChallenge.gameObject:SetActiveEx(true)

        local curPoints, allPoints = self:CalcTaskPoints(self.Tasks)

        self.TxtTurnChallenge.text = CS.XTextManager.GetText(
            "PassportTaskWeeklyChallengePoints",
            curPoints,
            allPoints)

        local remainTime = self:GetWeeklyTaskRemainTime()
        if remainTime then
            self.TxtTurnRemainTime.gameObject:SetActiveEx(true)
            self.TxtTurnRemainTime.text = CS.XTextManager.GetText(
                "PassportTaskWeeklyRemainTime",
                remainTime)
        end
    elseif taskType == XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY then  -- 手册任务
        self.TxtTurnChallenge.gameObject:SetActiveEx(true)
        local curTasks, allTasks = self:CalcTaskProgress(self.Tasks)
        self.TxtTurnChallenge.text = CS.XTextManager.GetText(
            "PassportTaskActivityProgress",
            curTasks,
            allTasks)

    else
        XLog.Error("XUiPassportPanelTask:Refresh, unknown task type: " .. taskType)
    end
end

-- 计算手册任务完成进度
function XUiPassportPanelTask:CalcTaskProgress(tasks)
    local allTasks = 0
    local finishTasks = 0

    for _, taskData in pairs(tasks) do
        allTasks = allTasks + 1
        if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
            finishTasks = finishTasks + 1
        end
    end

    return finishTasks, allTasks
end

-- 计算挑战点数
function XUiPassportPanelTask:CalcTaskPoints(tasks)
    local allPoints = 0
    local gotPoints = 0
    local pointItemId = CS.XGame.ClientConfig:GetInt("PassportPointItemId")

    for _, taskData in pairs(tasks) do
        local taskConf = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
        local rewardConf = XRewardManager.GetRewardList(taskConf.RewardId)

        local points = 0
        for _, reward in pairs(rewardConf) do
            if reward.TemplateId == pointItemId then
                points = points + reward.Count
            end
        end

        local exRewardId = self._Control:GetPassportTaskExRewardId(taskData.Id)
        local exRewardConf = nil

        if exRewardId then
            exRewardConf = XRewardManager.GetRewardList(exRewardId)
        end

        if exRewardConf then
            for _, exReward in pairs(exRewardConf) do
                if exReward.TemplateId == pointItemId then
                    points = points + exReward.Count
                end
            end
        end

        allPoints = allPoints + points

        if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
            gotPoints = gotPoints + points
        end
    end

    return gotPoints, allPoints
end

function XUiPassportPanelTask:GetWeeklyTaskRemainTime()
    local passportTaskGroupId = self._Control:GetPassportTaskGroupIdByType(
        XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)

    if not XTool.IsNumberValid(passportTaskGroupId) then
        return
    end

    local timeId = self._Control:GetPassportTaskGroupTimeId(passportTaskGroupId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(endTime - nowServerTime, XUiHelper.TimeFormatType.PASSPORT)
end

function XUiPassportPanelTask:UpdateTabExRewardMark()
    for i, config in ipairs(TaskTabConfig) do
        local rImgUp = self["RImgUp0" .. i]
        if rImgUp then
            rImgUp.gameObject:SetActiveEx(self._Control:HasPassportTaskExReward(config.Type))
        end
    end
end

function XUiPassportPanelTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
        grid:AppendExtraReward(data.ExRewardId)
    end
end

function XUiPassportPanelTask:UpdateTime()
    if self:GetCurrTaskType() ~= XEnumConst.PASSPORT.TASK_TYPE.WEEKLY then
        return
    end
    if not self:IsShow() then
        return
    end

    local passportTaskGroupId = self._Control:GetPassportTaskGroupIdByType(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)
    if not XTool.IsNumberValid(passportTaskGroupId) then
        return
    end

    local timeId = self._Control:GetPassportTaskGroupTimeId(passportTaskGroupId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    if not XTool.UObjIsNil(self.TxtTime) then
        self.TxtTime.text = XUiHelper.GetTime(endTime - nowServerTime, XUiHelper.TimeFormatType.PASSPORT)
    end
end

--一键领取当前页签任务
function XUiPassportPanelTask:FinishMultiTask()
    local taskType = self:GetCurrTaskType()
    if taskType then
        self._Control:FinishMultiTaskRequest(taskType)
    end
end

function XUiPassportPanelTask:Show()
    self:Open()
    self:Refresh()
end

function XUiPassportPanelTask:Hide()
    self:Close()
end

function XUiPassportPanelTask:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeSelf
end

return XUiPassportPanelTask