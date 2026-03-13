local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@class XUiPanelDynamic : XUiNode
---@field _Control XSubPackageControl
local XUiPanelDynamic = XClass(XUiNode, "XUiPanelDynamic")

local XUiGridDownload = require("XUi/XUiSubPackage/XUiGrid/XUiGridDownload")


function XUiPanelDynamic:OnStart(isPreview)
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridDownload, self, isPreview)
end

-- 简略版是在非主下载界面显示，要在格子里的文本加上可选/必选的前缀
function XUiPanelDynamic:SetShort()
    self.IsShortVersion = true
end

function XUiPanelDynamic:OnGetLuaEvents()
    return {
        XEventId.EVENT_SUBPACKAGE_START,
        XEventId.EVENT_SUBPACKAGE_PAUSE,
        XEventId.EVENT_SUBPACKAGE_UPDATE,
        XEventId.EVENT_SUBPACKAGE_COMPLETE,
        XEventId.EVENT_SUBPACKAGE_PREPARE,
        XEventId.EVENT_CLIENT_TASK_FINISH,
    }
end

function XUiPanelDynamic:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SUBPACKAGE_START
            or evt == XEventId.EVENT_SUBPACKAGE_PAUSE
            or evt == XEventId.EVENT_SUBPACKAGE_PREPARE then
        self:RefreshSingleGrid(...)
    elseif evt == XEventId.EVENT_SUBPACKAGE_COMPLETE or evt == XEventId.EVENT_CLIENT_TASK_FINISH then
        self:SetupDynamicTable(self.DataList)
    elseif evt == XEventId.EVENT_SUBPACKAGE_UPDATE then
        self:RefreshSingleProgress(...)
    end
end

function XUiPanelDynamic:SetupDynamicTable(dataList)
    if not XTool.IsTableEmpty(dataList) then
        dataList = self:SortSubpackage(dataList)
        self.DataList = dataList
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelDynamic:OnlyRefreshGridData()
    local grids = self.DynamicTable:GetGrids()
    for index, grid in pairs(grids) do
        grid:Refresh(self.DataList[index])
    end
end


---
---@param evt string
---@param index number
---@param grid XUiGridDownload
--------------------------
function XUiPanelDynamic:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiPanelDynamic:SortSubpackage(subpackageIds)
    if XTool.IsTableEmpty(subpackageIds) then
        return {}
    end

    table.sort(subpackageIds, function(idA, idB)
        local itemA = self._Control:GetSubpackageItem(idA)
        local itemB = self._Control:GetSubpackageItem(idB)
        
        local isAComplete = itemA:IsComplete()
        local isBComplete = itemB:IsComplete()

        --已完成的沉底
        if isAComplete ~= isBComplete then
            return isBComplete
        end

        local subConfigA = XMVCA.XSubPackage:GetSubpackageTemplate(idA)
        local subConfigB = XMVCA.XSubPackage:GetSubpackageTemplate(idB)
        if subConfigA.Type ~= subConfigB.Type then
            return subConfigA.Type < subConfigB.Type
        end

        return idA < idB
    end)

    return subpackageIds
end

---@return XUiGridDownload
function XUiPanelDynamic:GetGrid(subpackageId)
    local grids = self.DynamicTable:GetGrids()
    local temp
    for _, grid in pairs(grids) do
        if grid:GetSubpackageId() == subpackageId then
            temp = grid
            break
        end
    end

    return temp
end

function XUiPanelDynamic:RefreshSingleGrid(subpackageId)
    local temp = self:GetGrid(subpackageId)
    if not temp then
        return
    end
    
    temp:Refresh(subpackageId)
end

function XUiPanelDynamic:RefreshSingleProgress(subpackageId, progress)
    local temp = self:GetGrid(subpackageId)
    if not temp then
        return
    end
    
    temp:RefreshProgressOnly(progress)
end

return XUiPanelDynamic