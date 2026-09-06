---@class XUiPanelConsume : XUiNode
---@field Parent XLuaUi
---@field TxtTitle UnityEngine.UI.Text
---@field PanelLevelUp UnityEngine.RectTransform
---@field GridLevelUp UnityEngine.RectTransform
local XUiPanelConsume = XClass(XUiNode, "XUiPanelConsume")

local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local CONSUME_TYPE_ITEM = 0

local function NewItemCostData(itemId, count, isExchange)
    return {
        Type = CONSUME_TYPE_ITEM,
        Id = itemId,
        TemplateId = itemId,
        Count = count,
        IsExchange = isExchange == true,
    }
end

local function CostDataSort(costA, costB)
    if costA.IsExchange ~= costB.IsExchange then
        return not costA.IsExchange
    end
    if costA.TemplateId ~= costB.TemplateId then
        return costA.TemplateId < costB.TemplateId
    end
    return costA.Id < costB.Id
end

function XUiPanelConsume:OnStart()
    self.GridLevelUp.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelLevelUp)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
    self.CostList = {}
end

--- @param data {Title=string, CostList={ {Id,Count,IsExchange}, ... }}
function XUiPanelConsume:Refresh(data)
    self.Title = data.Title
    self.CostList = data.CostList or {}
    table.sort(self.CostList, CostDataSort)

    if self.TxtTitle then
        self.TxtTitle.text = data.Title or ""
    end

    self.DynamicTable:SetDataSource(self.CostList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelConsume:Update(data, index)
    self:Refresh(data)
end

local function SetExchangeMark(grid, data)
    if not grid or not grid.Transform then
        return
    end
    grid.ImgExchange = grid.ImgExchange or grid.Transform:Find("ImgExchange")
    if grid.ImgExchange then
        grid.ImgExchange.gameObject:SetActiveEx(data and data.IsExchange == true)
    end
end

function XUiPanelConsume:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.CostList[index]
        if not data then
            return
        end
        grid:Refresh(NewItemCostData(data.Id, data.Count, data.IsExchange))
        SetExchangeMark(grid, data)
    end
end

return XUiPanelConsume
