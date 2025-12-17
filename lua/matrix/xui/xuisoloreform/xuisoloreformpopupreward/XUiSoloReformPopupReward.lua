---@class XUiSoloReformPopupReward: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformPopupReward = XLuaUiManager.Register(XLuaUi, 'UiSoloReformPopupReward')
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSoloReformPopupRewardItem = require("XUi/XUiSoloReform/XUiSoloReformPopupReward/XUiSoloReformPopupRewardItem")

function XUiSoloReformPopupReward:OnAwake()
    self._TaskDatas = nil
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
end

function XUiSoloReformPopupReward:OnStart()
    self:InitDynamicTable()
end

function XUiSoloReformPopupReward:OnEnable()
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD, self.OnGainTaskReward, self)
    self:Refresh()
end

function XUiSoloReformPopupReward:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD, self.OnGainTaskReward, self)
end

function XUiSoloReformPopupReward:Refresh()
    self._TaskDatas = self._Control:GetTaskDatas()
    self.DynamicTable:SetDataSource(self._TaskDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiSoloReformPopupReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGrade)
    self.DynamicTable:SetProxy(XUiSoloReformPopupRewardItem, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
end

function XUiSoloReformPopupReward:OnGainTaskReward()
    self:Refresh()
end

function XUiSoloReformPopupReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:Update(data)
    end
end

function XUiSoloReformPopupReward:OnDestroy()
    self._TaskDatas = nil
end

return XUiSoloReformPopupReward