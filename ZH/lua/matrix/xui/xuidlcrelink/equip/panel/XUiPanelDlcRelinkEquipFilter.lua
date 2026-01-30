local XUiGridDlcRelinkPopupFilterTab = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkPopupFilterTab")
---@class XUiPanelDlcRelinkEquipFilter : XUiNode
---@field private _Control XDlcRelinkControl
---@field TypeReform XUiButtonGroup
local XUiPanelDlcRelinkEquipFilter = XClass(XUiNode, "XUiPanelDlcRelinkEquipFilter")

function XUiPanelDlcRelinkEquipFilter:OnStart(callback)
    self.GridCharacteristic.gameObject:SetActiveEx(false)
    self.Callback = callback

    self:InitBtnGroup(self.TypeReform, "ReformedType")
    --self:InitBtnGroup(self.TypeNumber, "FactorRemovedType")
    self:InitBtnGroup(self.TypePosition, "EquipType")

    -- 隐藏删除次数筛选
    if self.TypeNumber then
        self.TypeNumber.gameObject:SetActiveEx(false)
    end

    self:InitDynamicTable()
    self.CurSelectGrid = nil
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
    --if self.TypeNumber then
    --    if XTool.IsNumberValid(self.EquipFilterCache.FactorRemovedType) then
    --        self.TypeNumber:SelectIndex(self.EquipFilterCache.FactorRemovedType)
    --    else
    --        self.TypeNumber:CancelSelect()
    --    end
    --end
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
    if isEmpty then
        self.DynamicTable:Clear()
        self.TypeCharacteristic.gameObject:SetActiveEx(false)
        return
    end

    self.TypeCharacteristic.gameObject:SetActiveEx(true)
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
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --单选
        local curFactorId = self.EquipFilterCache.FactorIds[1] or 0
        local isSelected = curFactorId == factorId
        if isSelected then
            self.EquipFilterCache.FactorIds[1] = nil
            grid:SetSelect(false)
            self.CurSelectGrid = nil
        else
            self.EquipFilterCache.FactorIds[1] = factorId
            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelect(false)
            end
            grid:SetSelect(true)
            self.CurSelectGrid = grid
        end

        self:InvokeCallback()
    end
end

return XUiPanelDlcRelinkEquipFilter
