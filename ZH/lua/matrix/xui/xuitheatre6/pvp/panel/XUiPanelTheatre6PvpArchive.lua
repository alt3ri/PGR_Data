---@class XUiPanelTheatre6PvpArchive : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6PVPAttackDefend
local XUiPanelTheatre6PvpArchive = XClass(XUiNode, "XUiPanelTheatre6PvpArchive")

local XUiGridTheatre6PvpArchive = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpArchive")

function XUiPanelTheatre6PvpArchive:OnStart()
    self.BtnFilter:AddEventListener(handler(self, self.OnBtnFilterClick))
    self.BtnUp:AddEventListener(handler(self, self.OnBtnUpClick))
    self.BtnRemove:AddEventListener(handler(self, self.OnBtnRemoveClick))
    self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))

    self.TxtTipsDefend.gameObject:SetActiveEx(false)
    self.TxtTipsAttack.gameObject:SetActiveEx(false)
    self.GridArchive.gameObject:SetActiveEx(false)
    self.BtnFilter:SetButtonState(XUiButtonState.Normal)

    -- 数据列表
    ---@type Theatre6FileData[]
    self._ArchiveDataList = {}
    -- 筛选条件
    ---@type Theatre6FileData[]
    self._FilterSet = self._Control:GetAllFileData()
    -- 筛选设置
    self._FilterSetting = {}

    ---@type XUiGridTheatre6PvpArchive[]
    self._ArchiveGrids = {}

    -- 当前选中格子的角色Id和存档槽位ID
    self._CurSelectedCharacterId = -1
    self._CurSelectedSlotId = -1
    -- 当前选中的格子
    ---@type XUiGridTheatre6PvpArchive
    self._CurSelectedGrid = nil
end

function XUiPanelTheatre6PvpArchive:Refresh()
    self:RefreshArchiveList()
    self:SelectDefaultArchive()
    self:RefreshTips()
end

function XUiPanelTheatre6PvpArchive:RefreshArchiveList()
    local fileDataList = self:GetFileDataList()
    self._ArchiveDataList = XTool.CloneEx(fileDataList)
    if XTool.IsTableEmpty(self._ArchiveDataList) then
        self.ScrollList.gameObject:SetActiveEx(false)
        return
    end
    self.ScrollList.gameObject:SetActiveEx(true)
    self:SortArchive(self._ArchiveDataList)
    XTool.UpdateDynamicItem(self._ArchiveGrids, self._ArchiveDataList, self.GridArchive, XUiGridTheatre6PvpArchive, self)
end

function XUiPanelTheatre6PvpArchive:GetFileDataList()
    return self._FilterSet
end

---@param list Theatre6FileData[]
function XUiPanelTheatre6PvpArchive:SortArchive(list)
    table.sort(list, function(a, b)
        local aIsUp = self._Control:IsPvpArchiveCurrentLineup(self.Parent:GetLineupMode(), a.CharacterId, a.SlotId)
        local bIsUp = self._Control:IsPvpArchiveCurrentLineup(self.Parent:GetLineupMode(), b.CharacterId, b.SlotId)
        if aIsUp ~= bIsUp then
            return aIsUp
        end
        if a.Score ~= b.Score then
            return a.Score > b.Score
        end
        return a.CharacterId > b.CharacterId
    end)
end

---@param grid XUiGridTheatre6PvpArchive
function XUiPanelTheatre6PvpArchive:OnSelectArchive(grid)
    if not grid or not grid.FileData then
        return
    end
    if self._CurSelectedCharacterId == grid.FileData.CharacterId and self._CurSelectedSlotId == grid.FileData.SlotId then
        return
    end
    if self._CurSelectedGrid then
        self._CurSelectedGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self._CurSelectedCharacterId = grid.FileData.CharacterId
    self._CurSelectedSlotId = grid.FileData.SlotId
    self._CurSelectedGrid = grid
    self:RefreshBtn()
end

---根据角色Id和存档槽位Id选中存档；找到并选中返回 true，否则返回 false
---@param characterId number
---@param slotId number
---@return boolean
function XUiPanelTheatre6PvpArchive:SelectArchive(characterId, slotId)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(slotId) then
        return false
    end
    if characterId <= 0 or slotId <= 0 then
        return false
    end
    for index, data in ipairs(self._ArchiveDataList) do
        if data.CharacterId == characterId and data.SlotId == slotId then
            local grid = self._ArchiveGrids[index]
            if not grid then
                return false
            end
            if self._CurSelectedGrid then
                self._CurSelectedGrid:SetSelect(false)
            end
            grid:SetSelect(true)
            self._CurSelectedGrid = grid
            self._CurSelectedCharacterId = characterId
            self._CurSelectedSlotId = slotId
            self:RefreshBtn()
            return true
        end
    end
    return false
end

---默认选中第一个存档，如果当前选中的存档仍在列表中，则选中当前存档
function XUiPanelTheatre6PvpArchive:SelectDefaultArchive()
    if XTool.IsTableEmpty(self._ArchiveDataList) then
        if self._CurSelectedGrid then
            self._CurSelectedGrid:SetSelect(false)
            self._CurSelectedGrid = nil
        end
        self._CurSelectedCharacterId = -1
        self._CurSelectedSlotId = -1
        self:RefreshBtn()
        return
    end

    -- 若当前选中的存档仍在列表中，保持选中态
    if self:SelectArchive(self._CurSelectedCharacterId, self._CurSelectedSlotId) then
        return
    end

    -- 否则默认选中第一个
    local firstGrid = self._ArchiveGrids[1]
    if firstGrid then
        self:OnSelectArchive(firstGrid)
    end
end

---根据当前选中的角色Id和存档槽位Id，返回 _ArchiveDataList 中对应的 FileData
---@return Theatre6FileData|nil
function XUiPanelTheatre6PvpArchive:GetSelectedFileData()
    if self._CurSelectedCharacterId <= 0 or self._CurSelectedSlotId <= 0 then
        return nil
    end
    for _, data in ipairs(self._ArchiveDataList) do
        if data.CharacterId == self._CurSelectedCharacterId and data.SlotId == self._CurSelectedSlotId then
            return data
        end
    end
    return nil
end

function XUiPanelTheatre6PvpArchive:RefreshTips()
    local isDefend = self.Parent:IsDefend()
    self.TxtTipsDefend.gameObject:SetActiveEx(isDefend)
    self.TxtTipsAttack.gameObject:SetActiveEx(not isDefend)
    local count = self._Control:GetPvpCurrentLineupCharacterSlotCount(self.Parent:GetLineupMode())
    local limit = self._Control:GetPvpCurrentLineupCharacterSlotLimit(self.Parent:GetLineupMode())
    local index = count >= limit and 2 or 1
    local tips = self._Control:GetPvpClientConfigValue("ArchiveTips", index)
    if isDefend then
        self.TxtNumDefend.text = string.format(tips, count, limit)
    else
        self.TxtNumAttack.text = string.format(tips, count, limit)
    end
end

function XUiPanelTheatre6PvpArchive:RefreshArchiveRoleMask()
    local lineupMode = self.Parent:GetLineupMode()
    local targetIndex = self.Parent:GetCurSelectedIndex()
    for _, grid in pairs(self._ArchiveGrids) do
        local isMask = false
        local fileData = grid.FileData
        if fileData and XTool.IsNumberValid(targetIndex) and targetIndex > 0 then
            local isValid = self._Control:CheckPvpArchiveBeforeLineup(lineupMode, fileData.CharacterId, fileData.SlotId, targetIndex)
            isMask = not isValid
        end
        grid:SetRoleMask(isMask)
    end
end

function XUiPanelTheatre6PvpArchive:RefreshBtn()
    self:RefreshArchiveRoleMask()
    if self._CurSelectedCharacterId <= 0 or self._CurSelectedSlotId <= 0 then
        return
    end
    local isLineupSlot = self._Control:IsPvpArchiveInCurrentLineupSlot(self.Parent:GetLineupMode(), self._CurSelectedCharacterId, self._CurSelectedSlotId, self.Parent:GetCurSelectedIndex())
    self.BtnUp.gameObject:SetActiveEx(not isLineupSlot)
    self.BtnRemove.gameObject:SetActiveEx(isLineupSlot)
    if not isLineupSlot then
        local isFill = self._Control:CheckPvpArchiveBeforeLineup(self.Parent:GetLineupMode(), self._CurSelectedCharacterId, self._CurSelectedSlotId, self.Parent:GetCurSelectedIndex())
        self.BtnUp:SetDisable(not isFill)
    end
end

function XUiPanelTheatre6PvpArchive:OnBtnFilterClick()
    local filterData = {}
    XLuaUiManager.OpenWithCloseCallback("UiTheatre6PopupPVPFilterCharacter", function()
        local isNoFilter = XTool.IsTableEmpty(self._FilterSetting.CharacterId) and XTool.IsTableEmpty(self._FilterSetting.BuildTag)
        self.BtnFilter:SetButtonState(isNoFilter and XUiButtonState.Normal or XUiButtonState.Select)
        self._FilterSet = filterData.result or {}
        self:RefreshArchiveList()
        self:SelectDefaultArchive()
    end, filterData, self._FilterSetting)
end

function XUiPanelTheatre6PvpArchive:OnBtnUpClick()
    if self._CurSelectedCharacterId <= 0 or self._CurSelectedSlotId <= 0 then
        return
    end

    local isFill, desc = self._Control:CheckPvpArchiveBeforeLineup(self.Parent:GetLineupMode(), self._CurSelectedCharacterId, self._CurSelectedSlotId, self.Parent:GetCurSelectedIndex())
    if not isFill then
        self._Control:ShowTip(desc)
        return
    end

    local fileData = self:GetSelectedFileData()
    if not fileData then
        return
    end
    local isSuccess = self._Control:TryPvpUpCurrentLineupInfo(self.Parent:GetLineupMode(), fileData, self.Parent:GetCurSelectedIndex())
    if isSuccess then
        self._Control:ShowTip(self._Control:GetPvpClientConfigValue("ArchiveUpLineupSuccessTips"))
        self:Refresh()
    else
        XLog.Error("XUiPanelTheatre6PvpArchive:OnBtnUpClick failed to up lineup")
    end
end

function XUiPanelTheatre6PvpArchive:OnBtnRemoveClick()
    local isSuccess = self._Control:RemovePvpCurrentLineupInfo(self.Parent:GetLineupMode(), self.Parent:GetCurSelectedIndex())
    if isSuccess then
        self._Control:ShowTip(self._Control:GetPvpClientConfigValue("ArchiveRemoveLineupSuccessTips"))
        self:Refresh()
    else
        XLog.Error("XUiPanelTheatre6PvpArchive:OnBtnRemoveClick failed to remove lineup")
    end
end

function XUiPanelTheatre6PvpArchive:OnBtnDetailClick()
    if self._CurSelectedCharacterId <= 0 or self._CurSelectedSlotId <= 0 then
        return
    end
    local fileData = self:GetSelectedFileData()
    if not fileData then
        return
    end
    XLuaUiManager.Open("UiTheatre6PopupRoleDetail", nil, fileData)
end

return XUiPanelTheatre6PvpArchive
