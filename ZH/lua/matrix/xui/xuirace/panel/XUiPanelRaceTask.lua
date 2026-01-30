local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiPanelRaceTask : XUiNode
---@field Parent XUiRaceMissionShop
---@field _Control XRaceControl
local XUiPanelRaceTask = XClass(XUiNode, "XUiPanelRaceTask")

local MaskKey = "XUiRaceTaskPanel"

function XUiPanelRaceTask:OnStart()
    self._IsInit = true
    self._TaskGroupId = nil
    self:InitDynamicTable()
    self.GridTask.gameObject:SetActiveEx(false)
    self._OpenUiObtainCb = handler(self, self._OpenUiObtain)
end

function XUiPanelRaceTask:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
end

function XUiPanelRaceTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end
end

function XUiPanelRaceTask:OnDestroy()
    self._TaskGroupId = nil
end

function XUiPanelRaceTask:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self._DynamicTable:SetProxy(XDynamicGridTask, self.Parent)
    self._DynamicTable:SetDelegate(self)
end

function XUiPanelRaceTask:UpdateTaskShow(taskGroupId)
    if self._IsInit then
        XLuaUiManager.SetMask(true, "XUiPanelRaceTask")
        local timerId = XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false, "XUiPanelRaceTask")
            self:SetTableData(taskGroupId)
        end, 500) --动效
        self.Parent:_AddTimerId(timerId)
    else
        self:SetTableData(taskGroupId)
    end
    self._IsInit = false
end

function XUiPanelRaceTask:SetTableData(taskGroupId)
    self._TaskGroupId = taskGroupId
    local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(taskDatas))
    self._DynamicTable:SetDataSource(taskDatas)
    self._DynamicTable:ReloadDataSync(1)
end

--function XUiPanelRaceTask:FinishTask(id)
--    local taskIds = {}
--    local taskData = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self._TaskGroupId)
--    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
--        table.insert(taskIds, taskId)
--    end
--    if #taskIds <= 0 then
--        return
--    end
--    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds)
--end

function XUiPanelRaceTask:_OpenUiObtain(...)
    self._Control:OpenUiObtain(...)
end

---@param grid XDynamicGridTask
function XUiPanelRaceTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        grid:ResetData(data)
        grid:SetObtainUiCb(self._OpenUiObtainCb)
        --grid.BtnFinish.CallBack = function()
        --    self:FinishTask(data.Id)
        --end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self._DynamicTable:GetGrids()
        local gridCount = XTool.GetTableCount(grids)
        if XTool.IsTableEmpty(grids) or #grids <= 0 then
            return
        end
        for i, grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        local index = 0
        XLuaUiManager.SetMask(true, MaskKey)
        for i, grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/GridTaskEnable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                    index = index + 1
                    if index >= gridCount then
                        XLuaUiManager.SetMask(false, MaskKey)
                    end
                end
            end, 50 * i)
        end
    end
end

function XUiPanelRaceTask:OnTaskFinish()
    self:UpdateTaskShow(self._TaskGroupId)
end

return XUiPanelRaceTask
