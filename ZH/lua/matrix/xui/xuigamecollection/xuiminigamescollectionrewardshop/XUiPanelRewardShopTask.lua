---@class XUiPanelRewardShopTask : XUiNode
---@field _Control XGameCollectionControl


local XUiPanelRewardShopTask = XLuaUiManager.Register(XUiNode, "XUiPanelRewardShopTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTask = require("XUi/XUiFubenTaskReward/XUiGridTask")
function XUiPanelRewardShopTask:OnAwake()

end

function XUiPanelRewardShopTask:OnGetLuaEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiPanelRewardShopTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:RefreshTaskList()
        self.Parent:UpdateReddot()
    end
end


function XUiPanelRewardShopTask:InitComponents()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XUiGridTask)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end
function XUiPanelRewardShopTask:OnStart(...)
    self:InitComponents()
end

function XUiPanelRewardShopTask:OnEnable()
end


function XUiPanelRewardShopTask:Refresh()
    self:RefreshTaskList()
end

function XUiPanelRewardShopTask:RefreshTaskList()
    self._TaskDatas = self._Control:GetShowTaskDataList()
    if XTool.IsTableEmpty(self._TaskDatas) then
        return
    end
    self.DynamicTable:SetDataSource(self._TaskDatas)
    self.DynamicTable:ReloadDataASync(1)

    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self._TaskDatas))
end
function XUiPanelRewardShopTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._TaskDatas[index]
        grid:ResetData(data)
    end
end

return XUiPanelRewardShopTask
