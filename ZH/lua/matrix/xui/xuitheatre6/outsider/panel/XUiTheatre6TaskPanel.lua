local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiTheatre6TaskPanel: XUiNode
local XUiTheatre6TaskPanel = XLuaUiManager.Register(XUiNode, "XUiTheatre6TaskPanel")
local MaskKey = "XUiTheatre6TaskPanel"

function XUiTheatre6TaskPanel:OnStart()
    self._TaskIds = nil
    self:InitDynamicTable()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiTheatre6TaskPanel:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
end

function XUiTheatre6TaskPanel:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end
end

function XUiTheatre6TaskPanel:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self._DynamicTable:SetProxy(XDynamicGridTask, self.Parent)
    self._DynamicTable:SetDelegate(self)
end

function XUiTheatre6TaskPanel:UpdateTaskShow(taskIds)
    self._TaskIds = taskIds
    local taskDatas = XDataCenter.TaskManager.GetTaskIdListData(taskIds, true)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(taskDatas))
    self._DynamicTable:SetDataSource(taskDatas)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiTheatre6TaskPanel:FinishTask(id)
    local taskIds = {}
    for _, taskId in ipairs(self._TaskIds) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, taskId)
        end
    end
    if #taskIds <= 0 then return end

    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
        XLuaUiManager.Open("UiTheatre6PopupGetReward", rewardGoodsList, nil)
    end)
end

function XUiTheatre6TaskPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.ClickFunc = function(reward)
            XLuaUiManager.Open("UiTheatre6PopupRewardDetail", reward)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        grid:ResetData(data)
        grid.BtnFinish.CallBack = function()
            self:FinishTask(data.Id)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self._DynamicTable:GetGrids()
        local gridCount = XTool.GetTableCount(grids)
        if XTool.IsTableEmpty(grids) or #grids <= 0 then
            return
        end
        for i, grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        local cnt = 0
        XLuaUiManager.SetMask(true, MaskKey)
        for i, grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/PanelEnable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                    cnt = cnt + 1
                    if cnt >= gridCount then
                        XLuaUiManager.SetMask(false, MaskKey)
                    end
                end
            end, 100 * i)
        end
    end
end

function XUiTheatre6TaskPanel:OnTaskFinish()
    self:UpdateTaskShow(self._TaskIds)
end

function XUiTheatre6TaskPanel:OnDestroy()
    self._TaskIds = nil
end

return XUiTheatre6TaskPanel
