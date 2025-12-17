local XUiPanelCourse = require("XUi/XUiTask/XUiPanelCourse")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiPanelCourseReward = require("XUi/XUiTask/XUiPanelCourseReward")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelTaskStory
local XUiPanelTaskStory = XClass(nil, "XUiPanelTaskStory")
local GridTimeAnimation = 50

function XUiPanelTaskStory:Ctor(ui, parent, chapterId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.ChapterId = chapterId

    XTool.InitUiObject(self)
    self.GridTask.gameObject:SetActiveEx(false)
    
    ---@type XUiPanelCourse
    self.Course = XUiPanelCourse.New(self.Parent, self.PanelCourse, self.ChapterId, self)
    ---@type XUiPanelCourseReward
    self.CourseReward = XUiPanelCourseReward.New(self.Parent, self.PanelCourseReward)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    if XUiManager.IsHideFunc then
        self.Course.GameObject:SetActiveEx(false)
    end
end

--动态列表事件
function XUiPanelTaskStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.StoryTasks[index]
        grid.RootUi = self.Parent
        grid:SetReceiveAll()
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.IsPlayAnimation then
            return
        end

        local grids = self.DynamicTable:GetGrids()
        self.GridIndex = 1
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActive(true)
                item:PlayAnimation()
            end
            self.GridIndex = self.GridIndex + 1
        end, GridTimeAnimation, self.GridCount, 0)
    end
end

function XUiPanelTaskStory:ShowPanel(isPlayAnimation)
    self.GridCount = 0
    self.IsPlayAnimation = isPlayAnimation
    self.GameObject:SetActive(true)
    self.PanelTaskStoryList.gameObject:SetActive(true)

    self.StoryTasks = self:GetTasks()

    self.PanelNoneStoryTask.gameObject:SetActive(#self.StoryTasks <= 0)
    self.DynamicTable:SetDataSource(self.StoryTasks)
    self.DynamicTable:ReloadDataASync()

    if not XUiManager.IsHideFunc then
        self.Course:SetSViewIndex()
        self.Course:PlayImgFill()
    end
end

function XUiPanelTaskStory:HidePanel()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
    self.IsPlayAnimation = false
    self.GameObject:SetActive(false)
end

function XUiPanelTaskStory:ShowCourseReward(rewardId, name)
    self.CourseReward:ShowPanel(rewardId, name)
end

function XUiPanelTaskStory:Refresh()
    self.StoryTasks = self:GetTasks()

    self.PanelNoneStoryTask.gameObject:SetActive(#self.StoryTasks <= 0)
    self.DynamicTable:SetDataSource(self.StoryTasks)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelTaskStory:RefreshCourse()
    if not XUiManager.IsHideFunc then
        self.Course:RefreshCourse()
    end
end

function XUiPanelTaskStory:GetTasks()
    local allAchieveTasks = {}
    local taskGroupId = XFubenMainLineConfigs.GetConfigChapterTaskGroupId(self.ChapterId)
    local tasks = XDataCenter.TaskManager.GetStoryTaskListByGroupId(taskGroupId)
    for _, v in pairs(tasks) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks , v.Id) 
        end
    end

    local finalResultTaskDataList = {}
    if allAchieveTasks and next(allAchieveTasks) then
        --self.ReceiveAll = true        -- 一键领取激活
        --finalResultTaskDataList[1] = {ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks}

        for i = 1, #tasks do
            local taskData = XTool.Clone(tasks[i])
            taskData.AllAchieveTaskDatas = allAchieveTasks
            table.insert(finalResultTaskDataList, taskData)
        end
    else
        --self.ReceiveAll = false
        finalResultTaskDataList = tasks 
    end

    return finalResultTaskDataList
end

return XUiPanelTaskStory