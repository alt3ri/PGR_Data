local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
---@class XUiGridDlcRelinkTaskPanel : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkTaskPanel = XClass(XUiNode, "XUiGridDlcRelinkTaskPanel")

function XUiGridDlcRelinkTaskPanel:OnStart()
    self.GridTask.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiGridDlcRelinkTaskPanel:Refresh(configId)
    self.ConfigId = configId
    self:SetupDynamicTable()
end

function XUiGridDlcRelinkTaskPanel:OnGetLuaEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_FINISH_MULTI,
    }
end

function XUiGridDlcRelinkTaskPanel:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_FINISH_MULTI then
        self:SetupDynamicTable()
    end
end

function XUiGridDlcRelinkTaskPanel:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self.Parent)
    self.DynamicTable:SetDelegate(self)
end

function XUiGridDlcRelinkTaskPanel:SetupDynamicTable()
    local taskTimelimitIds = self._Control:GetShopTaskParamId(self.ConfigId)
    local taskTimelimitId = taskTimelimitIds and taskTimelimitIds[1] or 0
    self.TaskDataList = XTool.IsNumberValidEx(taskTimelimitId) and XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimelimitId) or {}
    local isEmpty = XTool.IsTableEmpty(self.TaskDataList)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end

    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XDynamicGridTask
function XUiGridDlcRelinkTaskPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.ClickFunc = function(reward)
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", reward.TemplateId)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskDataList[index]
        if data then
            grid:ResetData(data)
            grid.BtnFinish.CallBack = function()
                self:FinishTask()
            end
        end
    end
end

function XUiGridDlcRelinkTaskPanel:FinishTask()
    local taskIds = {}
    for _, taskData in ipairs(self.TaskDataList) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, taskData.Id)
        end
    end

    if #taskIds > 0 then
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
            XLuaUiManager.Open("UiDlcRelinkPopupGetReward", rewardGoodsList)
        end)
    end
end

return XUiGridDlcRelinkTaskPanel
