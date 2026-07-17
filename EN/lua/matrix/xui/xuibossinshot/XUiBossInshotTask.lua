local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
-- Boss跃升任务界面
local XUiBossInshotTask = XLuaUiManager.Register(XLuaUi, "UiBossInshotTask")

function XUiBossInshotTask:OnAwake()
    self.ActivityId = self._Control:GetActivityId()
    self.TaskGroupIds = self._Control:GetActivityTaskGroupIds(self.ActivityId)

    self:SetAutoCloseTimer()
    self:RegisterEvent()
    self:InitDynamicTable()
    self:InitTabGroup()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiBossInshotTask:OnStart()
    self.BtnTabTask1:SetButtonState(CS.UiButtonState.Select)
    self:OnTabClick(1)
end

function XUiBossInshotTask:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateDynamicTable()
end

function XUiBossInshotTask:OnDisable()
    self.Super.OnDisable(self)
end

function XUiBossInshotTask:OnDestroy()
    self:ClearGridsTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinishMulti, self)
end

function XUiBossInshotTask:SetAutoCloseTimer()
    self.EndTime = self._Control:GetActivityEndTime(self.ActivityId)
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiBossInshotTask:InitDynamicTable()
    self.GridTask.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiBossInshotTask:UpdateDynamicTable()
    local taskGroupId = self.TaskGroupIds[self.TabIndex]
    local rawList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId, nil, true)

    local achievedIds = {}
    for _, task in ipairs(rawList) do
        if task.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(achievedIds, task.Id)
        end
    end

    if not XTool.IsTableEmpty(achievedIds) then
        self.TaskDataList = {}
        for _, task in ipairs(rawList) do
            local cloned = XTool.Clone(task)
            cloned.AllAchieveTaskDatas = achievedIds
            table.insert(self.TaskDataList, cloned)
        end
    else
        self.TaskDataList = rawList
    end

    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync(1)
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

local _GridParam = {
    GridNameplateScaleFactor = 0.8
}

---@param grid XDynamicGridTask
function XUiBossInshotTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData, _GridParam)
        grid:SetReceiveAll()
        if self.IsPlayDynamicAnim then
            grid.PanelAnimation.gameObject:SetActive(false)
        else
            grid.PanelAnimation.gameObject:SetActive(true)
            local anim = XUiHelper.TryGetComponent(grid.Transform, "Animation/GridTaskEnable", typeof(CS.UnityEngine.Playables.PlayableDirector))
            anim:Play()
            anim.time = anim.duration
            anim:Evaluate()
            anim:Stop()
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self.IsPlayDynamicAnim then
            -- 动画完成前禁用拖拽
            local scrollRect = self.SViewTask:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
            scrollRect.vertical = false
            
            local grids = self.DynamicTable:GetGrids()
            local gridCnt = #grids
            for _, g in pairs(grids) do
                g.PanelAnimation.gameObject:SetActive(false)
            end
            self:ClearGridsTimer()
            if gridCnt > 0 then
                self.GridIndex = 1
                self.GridsTimer = XScheduleManager.Schedule(function()
                    local item = grids[self.GridIndex]
                    if item then
                        item.PanelAnimation.gameObject:SetActive(true)
                        item.Transform:Find("Animation/GridTaskEnable"):PlayTimelineAnimation()
                    end
                    self.GridIndex = self.GridIndex + 1
                    
                    -- 恢复拖拽
                    if self.GridIndex == gridCnt then
                        scrollRect.vertical = true
                    end
                end, 100, gridCnt)
            end
            self.IsPlayDynamicAnim = false
        end
    end
end

function XUiBossInshotTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:UpdateDynamicTable()
        self:RefreshTabRedPoint()
    end
end

function XUiBossInshotTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

-- EVENT_FINISH_MULTI 是纯 Lua 侧事件，需用 XEventManager 手动监听
function XUiBossInshotTask:OnTaskFinishMulti()
    self:UpdateDynamicTable()
    self:RefreshTabRedPoint()
end

function XUiBossInshotTask:RegisterEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinishMulti, self)
end

function XUiBossInshotTask:InitTabGroup()
    self.TabBtns = {}
    for i, groupId in ipairs(self.TaskGroupIds) do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnTabClick(index) end)
    self:RefreshTabRedPoint()
end

function XUiBossInshotTask:OnTabClick(index)
    if self.TabIndex == index then
        return
    end
    self.TabIndex = index
    self.IsPlayDynamicAnim = true
    self:UpdateDynamicTable()
end

function XUiBossInshotTask:RefreshTabRedPoint()
    for i, groupId in ipairs(self.TaskGroupIds) do
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, nil, true)
        local isShowRed = false
        for _, task in pairs(taskDataList) do
            if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                isShowRed = true
                break
            end
        end
        self.TabBtns[i]:ShowReddot(isShowRed)
    end
end

function XUiBossInshotTask:ClearGridsTimer()
    if self.GridsTimer then
        XScheduleManager.UnSchedule(self.GridsTimer)
        self.GridsTimer = nil
    end
end

return XUiBossInshotTask