--- 任务结算奖励n选1界面
---@class XUiTheatre5PopupChooseTaskReward: XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupChooseTaskReward = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PopupChooseTaskReward')
local XUiGridTheatre5ChooseTaskReward = require('XUi/XUiTheatre5/XUiTheatre5PopupChooseTaskReward/XUiGridTheatre5ChooseTaskReward')

---@param mission Theatre5Mission
function XUiTheatre5PopupChooseTaskReward:OnStart(mission)
    self.Mission = mission
    
    self.GridDetail.gameObject:SetActiveEx(false)
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListGem, XUiGridTheatre5ChooseTaskReward)
end

function XUiTheatre5PopupChooseTaskReward:OnEnable()
    self:Refresh()
end

function XUiTheatre5PopupChooseTaskReward:Refresh()
    local itemCfgs = self._Control.MissionControl:GetItemIdsByMissionBountyId(self.Mission.MissionBounty.Bounty, self.Mission.MissionBounty.BountyLevel)

    if XTool.IsTableEmpty(itemCfgs) then
        self.DynamicTable:RecycleAllTableGrid()
    else
        self.DynamicTable:SetDataSource(itemCfgs)
        self.DynamicTable:ReloadDataSync()
    end
end

function XUiTheatre5PopupChooseTaskReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()    
        grid:Refresh(self.DynamicTable.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    end
end


return XUiTheatre5PopupChooseTaskReward