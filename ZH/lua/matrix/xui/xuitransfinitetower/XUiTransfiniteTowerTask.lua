local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTransfiniteTowerTask = require("XUi/XUiTransfiniteTower/Grid/XUiGridTransfiniteTowerTask")

---@class XUiTransfiniteTowerTask : XLuaUi
---@field _Control XTransfiniteTowerControl
local XUiTransfiniteTowerTask = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerTask")

--region 生命周期
function XUiTransfiniteTowerTask:OnAwake()
    self:Init()
end

function XUiTransfiniteTowerTask:OnStart()
    self:RefreshTasks()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local endTime = XMVCA.XTransfiniteTower:GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.UpdateLeftTime))
end

function XUiTransfiniteTowerTask:OnEnable()
    self:UpdateLeftTime(XMVCA.XTransfiniteTower:GetActivityRemainTime() <= 0)
end
--endregion

--region 初始化
function XUiTransfiniteTowerTask:Init()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiGridTransfiniteTowerTask, self)
    self.DynamicTable:SetDelegate(self)

    self.GridTask.gameObject:SetActiveEx(false)
end
--endregion

--region 数据更新
function XUiTransfiniteTowerTask:RefreshTasks()
    self.Tasks = XMVCA.XTransfiniteTower:GetTaskList()
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiTransfiniteTowerTask:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("TransfiniteTowerActivityEnd")
        XLuaUiManager.RunMain()
    end
end
--endregion

--region 事件处理
function XUiTransfiniteTowerTask:OnBtnBackClick()
    self:Close()
end

function XUiTransfiniteTowerTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTransfiniteTowerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.Tasks[index])
    end
end
--endregion

return XUiTransfiniteTowerTask
