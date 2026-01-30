local XUiGridDlcRelinkPopupFilterTab = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkPopupFilterTab")
---@class XUiDlcRelinkPopupFilter : XLuaUi
---@field private _Control XDlcRelinkControl
---@field TypeReform XUiButtonGroup
local XUiDlcRelinkPopupFilter = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupFilter")

function XUiDlcRelinkPopupFilter:OnAwake()
    self.GridCharacteristic.gameObject:SetActiveEx(false)
    self.CurSelectGrid = nil
    self:RegisterUiEvents()
end

---@param equipMainFactorIds table<number> 装备主属性Id列表
---@param equipFilterCache XDlcRelinkEquipFilterCache 装备筛选缓存
---@param isHidePosition boolean 是否隐藏装备位置筛选
---@param updateCallback function 更新回调
---@param callback function 关闭回调
function XUiDlcRelinkPopupFilter:OnStart(equipMainFactorIds, equipFilterCache, isHidePosition, updateCallback, callback)
    self.EquipMainFactorIds = equipMainFactorIds
    self.EquipFilterCache = equipFilterCache or {}
    self.IsHidePosition = isHidePosition or false
    self.UpdateCallback = updateCallback
    self.Callback = callback

    self.EquipFilterCache.FactorIds = self.EquipFilterCache.FactorIds or {}
    self.EquipFilterCache.ReformedType = self.EquipFilterCache.ReformedType or 0
    self.EquipFilterCache.FactorRemovedType = self.EquipFilterCache.FactorRemovedType or 0
    self.EquipFilterCache.EquipType = self.EquipFilterCache.EquipType or 0

    self:InitBtnGroup(self.TypeReform, "ReformedType")
    --self:InitBtnGroup(self.TypeNumber, "FactorRemovedType")
    self:InitBtnGroup(self.TypePosition, "EquipType")

    if self.TypePosition then
        self.TypePosition.gameObject:SetActiveEx(not self.IsHidePosition)
    end
    -- 隐藏删除次数筛选
    if self.TypeNumber then
        self.TypeNumber.gameObject:SetActiveEx(false)
    end

    self:InitDynamicTable()
end

---@param equipMainFactorIds table<number> 装备主属性Id列表
---@param equipFilterCache XDlcRelinkEquipFilterCache 装备筛选缓存
function XUiDlcRelinkPopupFilter:RefreshFilter(equipMainFactorIds, equipFilterCache)
    self.EquipMainFactorIds = equipMainFactorIds
    self.EquipFilterCache = equipFilterCache or {}

    self.EquipFilterCache.FactorIds = self.EquipFilterCache.FactorIds or {}
    self.EquipFilterCache.ReformedType = self.EquipFilterCache.ReformedType or 0
    self.EquipFilterCache.FactorRemovedType = self.EquipFilterCache.FactorRemovedType or 0
    self.EquipFilterCache.EquipType = self.EquipFilterCache.EquipType or 0

    if self.TypeReform then
        self.TypeReform:CancelSelect()
    end
    if not self.IsHidePosition and self.TypePosition then
        self.TypePosition:CancelSelect()
    end
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupFilter:OnEnable()
    if self.TypeReform and XTool.IsNumberValid(self.EquipFilterCache.ReformedType) then
        self.TypeReform:SelectIndex(self.EquipFilterCache.ReformedType, false)
    end
    --if self.TypeNumber and XTool.IsNumberValid(self.EquipFilterCache.FactorRemovedType) then
    --    self.TypeNumber:SelectIndex(self.EquipFilterCache.FactorRemovedType, false)
    --end
    if not self.IsHidePosition and self.TypePosition and XTool.IsNumberValid(self.EquipFilterCache.EquipType) then
        self.TypePosition:SelectIndex(self.EquipFilterCache.EquipType, false)
    end
    self:SetupDynamicTable()
end

---@field btnGroup XUiButtonGroup
function XUiDlcRelinkPopupFilter:InitBtnGroup(btnGroup, cacheKey)
    if btnGroup and btnGroup.TabBtnList then
        btnGroup:InitBtns(btnGroup.TabBtnList:ToArray(), function(index)
            if self.EquipFilterCache[cacheKey] == index then
                self.EquipFilterCache[cacheKey] = 0
            else
                self.EquipFilterCache[cacheKey] = index
            end
            self:InvokeUpdateCallback()
        end)
    end
end

function XUiDlcRelinkPopupFilter:InvokeUpdateCallback()
    if self.UpdateCallback then
        self.UpdateCallback()
    end
end

function XUiDlcRelinkPopupFilter:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTypeCharacteristic)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkPopupFilterTab, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupFilter:SetupDynamicTable()
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
function XUiDlcRelinkPopupFilter:OnDynamicTableEvent(event, index, grid)
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

        self:InvokeUpdateCallback()
    end
end

function XUiDlcRelinkPopupFilter:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiDlcRelinkPopupFilter:OnBtnCloseClick()
    self:Close()
    if self.Callback then
        self.Callback()
    end
end

return XUiDlcRelinkPopupFilter
