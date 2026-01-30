

---@class XUiPanelBWDeliveryBag : XUiNode
---@field Parent XUiBigWorldPopupDelivery
local XUiPanelBWDeliveryBag = XClass(XUiNode, "XUiPanelBWDeliveryBag")

function XUiPanelBWDeliveryBag:OnStart()
    self.DynamicTable = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal").New(self.PanelItem)
    self.DynamicTable:SetProxy(require("XUi/XUiBigWorld/XQuest/Grid/XUiGridBWDelivery"), self, true)
    self.DynamicTable:SetDelegate(self)
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiPanelBWDeliveryBag:OnEnable()
    self.Parent:PlayAnimation("PanelLeftEnable")
end

function XUiPanelBWDeliveryBag:Refresh(objectiveId, itemList)
    self._ObjectiveId = objectiveId
    local isEmpty = XTool.IsTableEmpty(itemList)
    self.PanelNone.gameObject:SetActive(isEmpty)
    if not isEmpty then
        self:SetupDynamicTable(itemList)
    end
end

function XUiPanelBWDeliveryBag:SetupDynamicTable(itemList)
    self.ItemList = itemList
    self.DynamicTable:SetDataSource(self.ItemList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridBWDelivery
function XUiPanelBWDeliveryBag:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshBag(self.ItemList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickItem(grid, index)
    end
end

function XUiPanelBWDeliveryBag:OnClickItem(grid, index)
end

function XUiPanelBWDeliveryBag:DoDeliverToBag(data, isBag)
    self.Parent:DoDeliverToBag(data, isBag)
end

function XUiPanelBWDeliveryBag:DoBagToDeliver(data)
    self.Parent:DoBagToDeliver(data)
end

function XUiPanelBWDeliveryBag:IsManualDeliver()
    return self.Parent:IsManualDeliver()
end

return XUiPanelBWDeliveryBag