local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiPanelTheatre6BottomBuffList : XUiNode 房间底部Buff列表
---@field _Control XTheatre6Control
local XUiPanelTheatre6BottomBuffList = XClass(XUiNode, "XUiPanelTheatre6BottomBuffList")

function XUiPanelTheatre6BottomBuffList:OnStart()
    ---@type XDynamicTableNormal
    self._DynamicTable = XDynamicTableNormal.New(self.ListBuff)
    self._DynamicTable:SetProxy(require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Buff"), self)
    self._DynamicTable:SetDelegate(self)
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6BottomBuffList:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_BUFF_CHANGE, self.UpdateView, self)
    --隐藏期间(如被升星弹窗盖住)收不到Buff变化事件,重新显示时主动刷新一次
    self:UpdateView()
end

function XUiPanelTheatre6BottomBuffList:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_BUFF_CHANGE, self.UpdateView, self)
end

function XUiPanelTheatre6BottomBuffList:UpdateView()
    local buffDatas = self._Control:GetSortCharacterShowBuffs()
    self._DynamicTable:SetDataSource(buffDatas)
    self._DynamicTable:ReloadDataSync()
    self.UiPanelNone.gameObject:SetActiveEx(#buffDatas == 0)
end

---@param grid XUiGridTheatre6Buff
function XUiPanelTheatre6BottomBuffList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable.DataSource[index]
        grid:UpdateByInfo(data)
        grid:CheckShowBuffDisable()
        grid:IsCanClick(true)
        grid:ShowRemainingTimes()
    end
end

return XUiPanelTheatre6BottomBuffList