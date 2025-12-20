---@class XUiGridAreaWarRareTab : XUiNode
---@field private _Control XAreaWarControl
---@field Parent XUiPanelAreaWarRareTab
local XUiGridAreaWarRareTab = XClass(XUiNode, "XUiGridAreaWarRareTab")

-- 设置道具Id
function XUiGridAreaWarRareTab:SetItemId(itemId)
    self.ItemId = itemId
    self:Refresh()
end

-- 刷新道具
function XUiGridAreaWarRareTab:Refresh()
    local icon = self._Control:GetConfig():GetItemIcon(self.ItemId)
    self.Button:SetRawImage(icon)

    -- 刷新上锁
    local isSubmit = self._Control:GetItemRoom():IsRaceItemSubmit(self.ItemId)
    self.PanelLockNormal.gameObject:SetActiveEx(not isSubmit)
    self.PanelLockPress.gameObject:SetActiveEx(not isSubmit)
    
    -- 刷新选中
    self:RefreshSelected()
    
    -- 蓝点
    local ownNum = self._Control:GetItemRoom():GetItemNum(self.ItemId)
    local isRed = not isSubmit and ownNum >= XMVCA.XAreaWar.EnumConst.SUBMIT_NUM
    self.Button:ShowReddot(isRed)
end

-- 刷新选中
function XUiGridAreaWarRareTab:RefreshSelected()
    local isSelected = self.ItemId == self.Parent.SelectItemId
    self.ImgSelectNormal.gameObject:SetActiveEx(isSelected)
    self.ImgSelectPress.gameObject:SetActiveEx(isSelected)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------

---@class XUiPanelAreaWarRareTab : XUiNode
---@field private _Control XAreaWarControl
---@field Parent XUiAreaWarRare
local XUiPanelAreaWarRareTab = XClass(XUiNode, "XUiPanelAreaWarRareTab")

function XUiPanelAreaWarRareTab:OnStart()
    self:InitDynamicTable()
    self:RefreshItemList()
end

-- 提交珍稀道具成功
function XUiPanelAreaWarRareTab:OnSubmitRaceItemSuccess()
    local grids = self.DynamicTable:GetGrids() or {}
    for _, grid in pairs(grids) do
        grid:Refresh()
    end
end

-- 刷新选中的道具Id
function XUiPanelAreaWarRareTab:RefreshSelectItemId(itemId)
    self.SelectItemId = itemId
    local grids = self.DynamicTable:GetGrids() or {}
    for _, grid in pairs(grids) do
        grid:RefreshSelected()
    end
end

function XUiPanelAreaWarRareTab:InitDynamicTable()
    self.GridTab.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTab)
    self.DynamicTable:SetProxy(XUiGridAreaWarRareTab, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新藏品列表
function XUiPanelAreaWarRareTab:RefreshItemList()
    self.DataList = self._Control:GetConfig():GetRareItems()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridAreaWarRareTab
function XUiPanelAreaWarRareTab:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DataList[index]
        grid:SetItemId(data.ItemId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnItemClick(index)
    end
end

function XUiPanelAreaWarRareTab:OnItemClick(index)
    self.Parent:OnItemClick(index)
end

return XUiPanelAreaWarRareTab
