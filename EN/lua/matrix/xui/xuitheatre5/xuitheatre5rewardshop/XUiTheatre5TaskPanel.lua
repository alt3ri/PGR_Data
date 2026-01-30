local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiTheatre5TaskPanel: XUiNode
local XUiTheatre5TaskPanel = XLuaUiManager.Register(XUiNode, "XUiTheatre5TaskPanel")
local MaskKey = "XUiTheatre5TaskPanel"
function XUiTheatre5TaskPanel:OnStart()
    self._TaskIds = nil
    self:InitDynamicTable()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiTheatre5TaskPanel:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
end

function XUiTheatre5TaskPanel:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end    
end
function XUiTheatre5TaskPanel:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self._DynamicTable:SetProxy(XDynamicGridTask, self.Parent)
    self._DynamicTable:SetDelegate(self)
end

function XUiTheatre5TaskPanel:UpdateTaskShow(taskIds)
    self._TaskIds = taskIds
    local taskDatas = XDataCenter.TaskManager.GetTaskIdListData(taskIds, true)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(taskDatas))
    self._DynamicTable:SetDataSource(taskDatas)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiTheatre5TaskPanel:FinishTask(id)
    local taskIds = {}
    for _, taskId in ipairs(self._TaskIds) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then 
            table.insert(taskIds, taskId)
        end
    end
    if #taskIds <= 0 then return end
    
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
        XLuaUiManager.Open("UiTheatre5PopupGetReward", rewardGoodsList, nil)
    end)
end

function XUiTheatre5TaskPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.ClickFunc = function(reward)
              XLuaUiManager.Open("UiTheatre5PopupRewardDetail", reward.TemplateId, XMVCA.XTheatre5.EnumConst.ItemType.Common)
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
        for i,grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        local index = 0
        XLuaUiManager.SetMask(true, MaskKey)
        for i,grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/PanelEnable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                    index = index + 1
                    if index >= gridCount then
                        XLuaUiManager.SetMask(false, MaskKey)
                    end    
                end        
            end, 100 * i)
        end
    end    
        
end

function XUiTheatre5TaskPanel:OnTaskFinish()
    self:UpdateTaskShow(self._TaskIds)
end

function XUiTheatre5TaskPanel:OnDestroy()
    self._TaskIds = nil
end

return XUiTheatre5TaskPanel