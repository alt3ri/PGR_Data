---@class XUiConcertPreHeatingTask : XLuaUi
local XUiConcertPreHeatingTask = XLuaUiManager.Register(XLuaUi, "UiConcertPreHeatingTask")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")

function XUiConcertPreHeatingTask:OnAwake()
    self:InitDynamicTable()
    self:InitButton()
    self.AssetPanel = XUiHelper.XUiPanelAsset(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

function XUiConcertPreHeatingTask:OnStart()
    self:InitTime()
    self:RefreshTime()
end

function XUiConcertPreHeatingTask:OnEnable()
    self:RefreshDynamicTable()
end

function XUiConcertPreHeatingTask:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiConcertPreHeatingTask:InitDynamicTable()
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.SViewTask, XDynamicGridTask)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiConcertPreHeatingTask:InitTime()
    local endTime = XMVCA.XConcertPreHeating:GetActivityEndTime()
    if not XTool.IsNumberValid(endTime) then
        return
    end

    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XMVCA.XConcertPreHeating:HandleActivityEnd()
        end
    end)
end

function XUiConcertPreHeatingTask:RefreshTime()
    self.TxtTime.text = XMVCA.XConcertPreHeating:GetActivityTimeText()
end

function XUiConcertPreHeatingTask:RefreshDynamicTable()
    local taskGroupId = XMVCA.XConcertPreHeating:GetTaskGroupId()
    if not XTool.IsNumberValid(taskGroupId) then
        self.TaskDataList = {}
    else
        self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId, true)
    end

    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

---@param grid XDynamicGridTask
function XUiConcertPreHeatingTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiConcertPreHeatingTask:OnBtnBackClick()
    self:Close()
end

function XUiConcertPreHeatingTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiConcertPreHeatingTask
