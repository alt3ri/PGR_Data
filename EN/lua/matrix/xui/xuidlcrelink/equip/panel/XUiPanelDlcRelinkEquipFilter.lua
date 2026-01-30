local XUiGridDlcRelinkPopupFilterTab = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkPopupFilterTab")
---@class XUiPanelDlcRelinkEquipFilter : XUiNode
---@field private _Control XDlcRelinkControl
---@field TypeReform XUiButtonGroup
local XUiPanelDlcRelinkEquipFilter = XClass(XUiNode, "XUiPanelDlcRelinkEquipFilter")

function XUiPanelDlcRelinkEquipFilter:OnStart(callback)
    self.GridCharacteristic.gameObject:SetActiveEx(false)
    self.Callback = callback

    self:InitBtnGroup(self.TypeReform, "ReformedType")
    self:InitBtnGroup(self.TypeNumber, "FactorRemovedType")
    self:InitBtnGroup(self.TypePosition, "EquipType")

    self:InitDynamicTable()
end

---@field btnGroup XUiButtonGroup
function XUiPanelDlcRelinkEquipFilter:InitBtnGroup(btnGroup, cacheKey)
    if btnGroup and btnGroup.TabBtnList then
        btnGroup:InitBtns(btnGroup.TabBtnList:ToArray(), function(index)
            if self.EquipFilterCache[cacheKey] == index then
                self.EquipFilterCache[cacheKey] = 0
            else
                self.EquipFilterCache[cacheKey] = index
            end
            self:InvokeCallback()
        end)
    end
end

function XUiPanelDlcRelinkEquipFilter:InvokeCallback()
    if self.Callback then
        self.Callback()
    end
end

---@param equipMainFactorIds table<number> 装备主属性Id列表
---@param equipFilterCache XDlcRelinkEquipFilterCache 装备筛选缓存
function XUiPanelDlcRelinkEquipFilter:Refresh(equipMainFactorIds, equipFilterCache)
    self.EquipMainFactorIds = equipMainFactorIds
    self.EquipFilterCache = equipFilterCache or {}

    self.EquipFilterCache.FactorIds = self.EquipFilterCache.FactorIds or {}
    self.EquipFilterCache.ReformedType = self.EquipFilterCache.ReformedType or 0
    self.EquipFilterCache.FactorRemovedType = self.EquipFilterCache.FactorRemovedType or 0
    self.EquipFilterCache.EquipType = self.EquipFilterCache.EquipType or 0

    if self.TypeReform then
        if XTool.IsNumberValid(self.EquipFilterCache.ReformedType) then
            self.TypeReform:SelectIndex(self.EquipFilterCache.ReformedType)
        else
            self.TypeReform:CancelSelect()
        end
    end
    if self.TypeNumber then
        if XTool.IsNumberValid(self.EquipFilterCache.FactorRemovedType) then
            self.TypeNumber:SelectIndex(self.EquipFilterCache.FactorRemovedType)
        else
            self.TypeNumber:CancelSelect()
        end
    end
    if self.TypePosition then
        if XTool.IsNumberValid(self.EquipFilterCache.EquipType) then
            self.TypePosition:SelectIndex(self.EquipFilterCache.EquipType)
        else
            self.TypePosition:CancelSelect()
        end
    end
    self:SetupDynamicTable()
end

function XUiPanelDlcRelinkEquipFilter:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTypeCharacteristic)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkPopupFilterTab, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelDlcRelinkEquipFilter:SetupDynamicTable()
    local isEmpty = XTool.IsTableEmpty(self.EquipMainFactorIds)
    if self.TypeCharacteristic then
        self.TypeCharacteristic.gameObject:SetActiveEx(not isEmpty)
    end
    if isEmpty then
        return
    end

    self.DynamicTable:SetDataSource(self.EquipMainFactorIds)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkPopupFilterTab
function XUiPanelDlcRelinkEquipFilter:OnDynamicTableEvent(event, index, grid)
    local factorId = self.EquipMainFactorIds and self.EquipMainFactorIds[index]
    if not factorId then
        return
    end

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(factorId)
        local isSelected = table.contains(self.EquipFilterCache.FactorIds, factorId)
        grid:SetSelect(isSelected)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local isSelected, i = table.contains(self.EquipFilterCache.FactorIds, factorId)
        if isSelected then
            table.remove(self.EquipFilterCache.FactorIds, i)
            grid:SetSelect(false)
        else
            table.insert(self.EquipFilterCache.FactorIds, factorId)
            grid:SetSelect(true)
        end
        self:InvokeCallback()
    end
end

return XUiPanelDlcRelinkEquipFilter
