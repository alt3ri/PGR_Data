---@class XUiTheatre6PopupPVPFilterCharacter : XLuaUi pvp筛选存档界面
---@field _Control XTheatre6Control
local XUiTheatre6PopupPVPFilterCharacter = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupPVPFilterCharacter")

function XUiTheatre6PopupPVPFilterCharacter:OnAwake()
    self.BtnClear:AddEventListener(handler(self, self.OnBtnClearClick))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.OnBtnCloseClick))
end

---@param filterData table 外部传入的空表，确认时通过 filterData.result 赋值返回筛选结果
function XUiTheatre6PopupPVPFilterCharacter:OnStart(filterData, filterSetting)
    self._FilterData = filterData
    self._CharacterConfigs = self:GetSortedCharacters()
    self._BuildTagConfigs = self:GetSortedTags()

    if filterSetting then
        self._FilterSetting = filterSetting
        self._SelectedCharacterIds = filterSetting.CharacterId and XTool.Clone(filterSetting.CharacterId) or {}
        self._SelectedBuildTagIds = filterSetting.BuildTag and XTool.Clone(filterSetting.BuildTag) or {}
    else
        self._SelectedCharacterIds = {}
        self._SelectedBuildTagIds = {}
    end
    
    self._CharacterGrids = {}
    self._TagGrids = {}
    self._HistoryFilterData = self:FilterFileDatas()

    self:RefreshCharacterGrids()
    self:RefreshTagGrids()
end

---@return XTableTheatre6Character[]
function XUiTheatre6PopupPVPFilterCharacter:GetSortedCharacters()
    local result = {}
    for _, cfg in pairs(self._Control:GetCharacterConfigs()) do
        if XTool.IsNumberValid(cfg.FilterSort) then
            table.insert(result, cfg)
        end
    end
    table.sort(result, function(a, b)
        return a.FilterSort < b.FilterSort
    end)
    return result
end

---@return XTableTheatre6BuildTag[]
function XUiTheatre6PopupPVPFilterCharacter:GetSortedTags()
    local result = {}
    for _, cfg in pairs(self._Control:GetBuildTagConfigs()) do
        if XTool.IsNumberValid(cfg.FilterSort) then
            table.insert(result, cfg)
        end
    end
    table.sort(result, function(a, b)
        return a.FilterSort < b.FilterSort
    end)
    return result
end

function XUiTheatre6PopupPVPFilterCharacter:RefreshCharacterGrids()
    local count = #self._CharacterConfigs
    XUiHelper.RefreshCustomizedList(self.GridCharacter.parent, self.GridCharacter, count, function(i, go)
        local cfg = self._CharacterConfigs[i]
        local headIcon = self._Control:GetFashionConfig(cfg.FashionIds[1]).Portrait
        local id = cfg.CharacterId
        local uiObj = {}
        XUiHelper.InitUiClass(uiObj, go)
        local btn = uiObj.GridCharacter
        self:UpdateGridSelectState(btn, self._SelectedCharacterIds[id])
        btn.ExitCheck = false
        btn:SetName(cfg.Name)
        btn:SetRawImage(headIcon)
        btn:AddEventListener(function()
            if self._SelectedCharacterIds[id] then
                self._SelectedCharacterIds[id] = nil
            else
                self._SelectedCharacterIds[id] = true
            end
            self:UpdateGridSelectState(btn, self._SelectedCharacterIds[id])
        end)
        table.insert(self._CharacterGrids, btn)
    end)
end

function XUiTheatre6PopupPVPFilterCharacter:RefreshTagGrids()
    local count = #self._BuildTagConfigs
    XUiHelper.RefreshCustomizedList(self.GridTag.parent, self.GridTag, count, function(i, go)
        local cfg = self._BuildTagConfigs[i]
        local id = cfg.Id
        local uiObj = {}
        XUiHelper.InitUiClass(uiObj, go)
        local btn = uiObj.GridTag
        self:UpdateGridSelectState(btn, self._SelectedBuildTagIds[id])
        btn.ExitCheck = false
        btn:SetName(cfg.Name)
        btn:SetRawImage(cfg.Icon)
        btn:AddEventListener(function()
            if self._SelectedBuildTagIds[id] then
                self._SelectedBuildTagIds[id] = nil
            else
                self._SelectedBuildTagIds[id] = true
            end
            self:UpdateGridSelectState(btn, self._SelectedBuildTagIds[id])
        end)
        table.insert(self._TagGrids, btn)
    end)
end

function XUiTheatre6PopupPVPFilterCharacter:UpdateGridSelectState(grid, isSelected)
    grid:SetButtonState(isSelected and XUiButtonState.Select or XUiButtonState.Normal)
end

---根据当前选中条件筛选存档
function XUiTheatre6PopupPVPFilterCharacter:FilterFileDatas()
    local fileDatas = self._Control:GetAllFileData()
    if XTool.IsTableEmpty(fileDatas) then
        return table.empty
    end

    local hasCharacterFilter = not XTool.IsTableEmpty(self._SelectedCharacterIds)
    local hasTagFilter = not XTool.IsTableEmpty(self._SelectedBuildTagIds)
    if not hasCharacterFilter and not hasTagFilter then
        return fileDatas
    end

    local result = {}
    for _, fileData in ipairs(fileDatas) do
        local characterId = self._Control:GetCharacterConfig(fileData.CharacterId).CharacterId
        local characterMatch = not hasCharacterFilter or self._SelectedCharacterIds[characterId]
        local tagMatch = not hasTagFilter
        if hasTagFilter then
            local buildTags = self._Control:GetSortFileDataBuildTags(fileData)
            for _, tagId in ipairs(buildTags) do
                if self._SelectedBuildTagIds[tagId] then
                    tagMatch = true
                    break
                end
            end
        end
        if characterMatch and tagMatch then
            table.insert(result, fileData)
        end
    end
    return result
end

function XUiTheatre6PopupPVPFilterCharacter:OnBtnClearClick()
    self._SelectedCharacterIds = {}
    self._SelectedBuildTagIds = {}
    for _, grid in ipairs(self._CharacterGrids) do
        self:UpdateGridSelectState(grid, false)
    end
    for _, grid in ipairs(self._TagGrids) do
        self:UpdateGridSelectState(grid, false)
    end
end

function XUiTheatre6PopupPVPFilterCharacter:OnBtnYesClick()
    self._FilterData.result = self:FilterFileDatas()
    if self._FilterSetting then
        self._FilterSetting.CharacterId = self._SelectedCharacterIds
        self._FilterSetting.BuildTag = self._SelectedBuildTagIds
    end
    self:Close()
end

function XUiTheatre6PopupPVPFilterCharacter:OnBtnCloseClick()
    self._FilterData.result = self._HistoryFilterData
    self:Close()
end

return XUiTheatre6PopupPVPFilterCharacter
