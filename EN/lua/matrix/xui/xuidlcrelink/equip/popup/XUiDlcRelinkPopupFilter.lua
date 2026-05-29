local XUiGridDlcRelinkPopupFilterTab = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkPopupFilterTab")
---@class XUiDlcRelinkPopupFilter : XLuaUi
---@field private _Control XDlcRelinkControl
---@field TypeReform XUiButtonGroup
local XUiDlcRelinkPopupFilter = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupFilter")

function XUiDlcRelinkPopupFilter:OnAwake()
    self.GridCharacteristic.gameObject:SetActiveEx(false)
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
    self.EquipFilterCache.EquipType = self.EquipFilterCache.EquipType or 0
    self.EquipFilterCache.EquipQuality = self.EquipFilterCache.EquipQuality or 0
    self.EquipFilterCache.EquipDiscard = self.EquipFilterCache.EquipDiscard or 0

    self:InitBtnGroup(self.TypeReform, "ReformedType")
    self:InitBtnGroup(self.TypePosition, "EquipType")
    self:InitBtnGroup(self.TypeQuality, "EquipQuality")
    self:InitBtnGroup(self.TypeDiscard, "EquipDiscard")

    if self.TypePosition then
        self.TypePosition.gameObject:SetActiveEx(not self.IsHidePosition)
    end

    ---@type XUiGridDlcRelinkPopupFilterTab[]
    self.CharacteristicGridList = {}
    self.CurSelectGrid = nil
end

---@param equipMainFactorIds table<number> 装备主属性Id列表
---@param equipFilterCache XDlcRelinkEquipFilterCache 装备筛选缓存
function XUiDlcRelinkPopupFilter:RefreshFilter(equipMainFactorIds, equipFilterCache)
    self.EquipMainFactorIds = equipMainFactorIds
    self.EquipFilterCache = equipFilterCache or {}

    self.EquipFilterCache.FactorIds = self.EquipFilterCache.FactorIds or {}
    self.EquipFilterCache.ReformedType = self.EquipFilterCache.ReformedType or 0
    self.EquipFilterCache.EquipType = self.EquipFilterCache.EquipType or 0
    self.EquipFilterCache.EquipQuality = self.EquipFilterCache.EquipQuality or 0
    self.EquipFilterCache.EquipDiscard = self.EquipFilterCache.EquipDiscard or 0

    if self.TypeReform then
        self.TypeReform:CancelSelect()
    end
    if not self.IsHidePosition and self.TypePosition then
        self.TypePosition:CancelSelect()
    end
    if self.TypeQuality then
        self.TypeQuality:CancelSelect()
    end
    if self.TypeDiscard then
        self.TypeDiscard:CancelSelect()
    end
    self:RefreshCharacteristic()
end

function XUiDlcRelinkPopupFilter:OnEnable()
    if self.TypeReform and XTool.IsNumberValid(self.EquipFilterCache.ReformedType) then
        self.TypeReform:SelectIndex(self.EquipFilterCache.ReformedType, false)
    end
    if not self.IsHidePosition and self.TypePosition and XTool.IsNumberValid(self.EquipFilterCache.EquipType) then
        self.TypePosition:SelectIndex(self.EquipFilterCache.EquipType, false)
    end
    if self.TypeQuality and XTool.IsNumberValid(self.EquipFilterCache.EquipQuality) then
        self.TypeQuality:SelectIndex(self.EquipFilterCache.EquipQuality, false)
    end
    if self.TypeDiscard and XTool.IsNumberValid(self.EquipFilterCache.EquipDiscard) then
        self.TypeDiscard:SelectIndex(self.EquipFilterCache.EquipDiscard, false)
    end
    self:RefreshCharacteristic()
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

function XUiDlcRelinkPopupFilter:RefreshCharacteristic()
    local isEmpty = XTool.IsTableEmpty(self.EquipMainFactorIds)
    if isEmpty then
        for _, grid in pairs(self.CharacteristicGridList) do
            grid:Close()
        end
        self.TypeCharacteristic.gameObject:SetActiveEx(false)
        return
    end

    self.TypeCharacteristic.gameObject:SetActiveEx(true)
    for index, factorId in ipairs(self.EquipMainFactorIds) do
        local grid = self.CharacteristicGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCharacteristic, self.PanelCharacteristic)
            grid = XUiGridDlcRelinkPopupFilterTab.New(go, self, handler(self, self.OnBtnCharacteristicClick))
            self.CharacteristicGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(factorId)
        local isSelected = table.contains(self.EquipFilterCache.FactorIds, factorId)
        grid:SetSelect(isSelected)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
        end
    end

    for index = #self.EquipMainFactorIds + 1, #self.CharacteristicGridList do
        local grid = self.CharacteristicGridList[index]
        if grid then
            grid:Close()
        end
    end
end

---@param grid XUiGridDlcRelinkPopupFilterTab
function XUiDlcRelinkPopupFilter:OnBtnCharacteristicClick(grid)
    --单选
    local factorId = grid.FactorId
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
