local XUiGridDlcRelinkPopupFilterTab = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkPopupFilterTab")
---@class XUiPanelDlcRelinkEquipFilter : XUiNode
---@field private _Control XDlcRelinkControl
---@field TypeReform XUiButtonGroup
local XUiPanelDlcRelinkEquipFilter = XClass(XUiNode, "XUiPanelDlcRelinkEquipFilter")

function XUiPanelDlcRelinkEquipFilter:OnStart(callback)
    self.GridCharacteristic.gameObject:SetActiveEx(false)
    self.Callback = callback

    self:InitBtnGroup(self.TypeReform, "ReformedType")
    self:InitBtnGroup(self.TypePosition, "EquipType")
    self:InitBtnGroup(self.TypeQuality, "EquipQuality")
    self:InitBtnGroup(self.TypeDiscard, "EquipDiscard")

    ---@type XUiGridDlcRelinkPopupFilterTab[]
    self.CharacteristicGridList = {}
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
    self.EquipFilterCache.EquipType = self.EquipFilterCache.EquipType or 0
    self.EquipFilterCache.EquipQuality = self.EquipFilterCache.EquipQuality or 0
    self.EquipFilterCache.EquipDiscard = self.EquipFilterCache.EquipDiscard or 0

    if self.TypeReform then
        if XTool.IsNumberValid(self.EquipFilterCache.ReformedType) then
            self.TypeReform:SelectIndex(self.EquipFilterCache.ReformedType)
        else
            self.TypeReform:CancelSelect()
        end
    end
    if self.TypePosition then
        if XTool.IsNumberValid(self.EquipFilterCache.EquipType) then
            self.TypePosition:SelectIndex(self.EquipFilterCache.EquipType)
        else
            self.TypePosition:CancelSelect()
        end
    end
    if self.TypeQuality then
        if XTool.IsNumberValid(self.EquipFilterCache.EquipQuality) then
            self.TypeQuality:SelectIndex(self.EquipFilterCache.EquipQuality)
        else
            self.TypeQuality:CancelSelect()
        end
    end
    if self.TypeDiscard then
        if XTool.IsNumberValid(self.EquipFilterCache.EquipDiscard) then
            self.TypeDiscard:SelectIndex(self.EquipFilterCache.EquipDiscard)
        else
            self.TypeDiscard:CancelSelect()
        end
    end
    self:RefreshCharacteristic()
end

function XUiPanelDlcRelinkEquipFilter:RefreshCharacteristic()
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
function XUiPanelDlcRelinkEquipFilter:OnBtnCharacteristicClick(grid)
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

    self:InvokeCallback()
end

return XUiPanelDlcRelinkEquipFilter
