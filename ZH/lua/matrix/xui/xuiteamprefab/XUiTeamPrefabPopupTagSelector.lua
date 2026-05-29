---@class XUiTeamPrefabPopupTagSelector : XLuaUi
--- 编队预设标签选择弹窗，支持 "set"（设置标签）和 "filter"（筛选标签）两种模式
local XUiTeamPrefabPopupTagSelector = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabPopupTagSelector")

local MODE_SET = "set"
local MODE_FILTER = "filter"

function XUiTeamPrefabPopupTagSelector:OnAwake()
    self.AttributeGrids = {}  -- 属性标签 Grid clone 列表
    self.ModeGrids = {}       -- 玩法标签 Grid clone 列表
    self.SelectedAttributeTagId = nil
    self.SelectedModeTagId = nil

    self:InitTagGrids()
    self:InitButton()
end

---@param mode string "set" 或 "filter"
---@param initSelectedTags table<int, true> 初始选中的标签集合
---@param confirmCallback function(selectedTags) 确认回调
function XUiTeamPrefabPopupTagSelector:OnStart(mode, initSelectedTags, confirmCallback)
    self.Mode = mode or MODE_SET
    self.ConfirmCallback = confirmCallback

    -- 模式差异：标题互斥显示
    local isSetMode = (self.Mode == MODE_SET)
    self.TxtTitleSet.gameObject:SetActiveEx(isSetMode)
    self.TxtTitleFilter.gameObject:SetActiveEx(not isSetMode)

    -- 筛选模式才显示清空按钮
    local isFilterMode = (self.Mode == MODE_FILTER)
    self.BtnCancelFilter.gameObject:SetActiveEx(isFilterMode)

    -- 还原初始选中状态
    self.SelectedAttributeTagId = nil
    self.SelectedModeTagId = nil
    if initSelectedTags then
        for tagId in pairs(initSelectedTags) do
            local cfg = XTeamConfig.GetTeamPrefabTagCfgById(tagId)
            if cfg then
                if cfg.TagType == XEnumConst.TeamPrefab.TagTypeAttribute then
                    self.SelectedAttributeTagId = tagId
                elseif cfg.TagType == XEnumConst.TeamPrefab.TagTypeGameplay then
                    self.SelectedModeTagId = tagId
                end
            end
        end
    end

    -- 记录初始选中状态，用于关闭时变更检测
    self._InitAttributeTagId = self.SelectedAttributeTagId
    self._InitModeTagId = self.SelectedModeTagId

    self:RefreshAllGridSelectState()
end

function XUiTeamPrefabPopupTagSelector:InitButton()
    self.BtnTanchuangClose.CallBack = handler(self, self.OnBtnCloseClick)
    self.BtnSure.CallBack = handler(self, self.OnBtnSureClick)
    self.BtnCancelFilter.CallBack = handler(self, self.OnBtnCancelFilterClick)
end

--- 从全量配置按 TagType 分组并按 Order 排序，结果缓存到 self
function XUiTeamPrefabPopupTagSelector:GetTagsByType(tagType)
    self._TagsByTypeCache = self._TagsByTypeCache or {}
    if self._TagsByTypeCache[tagType] then
        return self._TagsByTypeCache[tagType]
    end

    local result = {}
    local allCfg = XTeamConfig.GetAllTeamPrefabTagCfg()
    if allCfg then
        for _, cfg in pairs(allCfg) do
            if cfg.TagType == tagType then
                table.insert(result, cfg)
            end
        end
        table.sort(result, function(a, b) return a.Order < b.Order end)
    end
    self._TagsByTypeCache[tagType] = result
    return result
end

function XUiTeamPrefabPopupTagSelector:InitTagGridStateNode(grid)
    grid.NormalNode = grid.Transform:Find("Normal")
    grid.PressNode = grid.Transform:Find("Press")
    grid.SelectNode = grid.Transform:Find("Select")
end

function XUiTeamPrefabPopupTagSelector:InitTagGrids()
    -- 属性标签
    local attributeTags = self:GetTagsByType(XEnumConst.TeamPrefab.TagTypeAttribute)
    self.GridTagAttribute.gameObject:SetActiveEx(false)
    for i, cfg in ipairs(attributeTags) do
        local go = XUiHelper.Instantiate(self.GridTagAttribute.gameObject)
        go.transform:SetParent(self.GridTagAttribute.transform.parent, false)
        go:SetActiveEx(true)
        local btn = go:GetComponent("XUiButton")
        btn:SetNameByGroup(0, cfg.Text)
        if not string.IsNilOrEmpty(cfg.Icon) then
            btn:SetRawImage(cfg.Icon)
        end
        local tagId = cfg.Id
        btn.CallBack = function()
            self:OnTagGridClick(tagId, XEnumConst.TeamPrefab.TagTypeAttribute)
        end
        local grid = { GameObject = go, Transform = go.transform, Btn = btn, TagId = cfg.Id }
        self:InitTagGridStateNode(grid)
        self:SetTagGridSelectState(grid, false)
        self.AttributeGrids[i] = grid
    end

    -- 玩法标签
    local modeTags = self:GetTagsByType(XEnumConst.TeamPrefab.TagTypeGameplay)
    self.GridTagMode.gameObject:SetActiveEx(false)
    for i, cfg in ipairs(modeTags) do
        local go = XUiHelper.Instantiate(self.GridTagMode.gameObject)
        go.transform:SetParent(self.GridTagMode.transform.parent, false)
        go:SetActiveEx(true)
        local btn = go:GetComponent("XUiButton")
        btn:SetNameByGroup(0, cfg.Text)
        local tagId = cfg.Id
        btn.CallBack = function()
            self:OnTagGridClick(tagId, XEnumConst.TeamPrefab.TagTypeGameplay)
        end
        local grid = { GameObject = go, Transform = go.transform, Btn = btn, TagId = cfg.Id }
        self:InitTagGridStateNode(grid)
        self:SetTagGridSelectState(grid, false)
        self.ModeGrids[i] = grid
    end
end

--- 标签点击：同类型内单选，再次点击取消
function XUiTeamPrefabPopupTagSelector:OnTagGridClick(tagId, tagType)
    if tagType == XEnumConst.TeamPrefab.TagTypeAttribute then
        self.SelectedAttributeTagId = (self.SelectedAttributeTagId ~= tagId) and tagId or nil
    elseif tagType == XEnumConst.TeamPrefab.TagTypeGameplay then
        self.SelectedModeTagId = (self.SelectedModeTagId ~= tagId) and tagId or nil
    end

    self:RefreshAllGridSelectState()
end

function XUiTeamPrefabPopupTagSelector:SetTagGridSelectState(grid, isSelected)
    if grid.NormalNode then
        grid.NormalNode.gameObject:SetActiveEx(not isSelected)
    end
    if grid.PressNode then
        grid.PressNode.gameObject:SetActiveEx(false)
    end
    if grid.SelectNode then
        grid.SelectNode.gameObject:SetActiveEx(isSelected)
    end
end

function XUiTeamPrefabPopupTagSelector:RefreshAllGridSelectState()
    for _, grid in ipairs(self.AttributeGrids) do
        local isSelected = (grid.TagId == self.SelectedAttributeTagId)
        self:SetTagGridSelectState(grid, isSelected)
    end
    for _, grid in ipairs(self.ModeGrids) do
        local isSelected = (grid.TagId == self.SelectedModeTagId)
        self:SetTagGridSelectState(grid, isSelected)
    end
end

--- 收集选中标签，返回 set 和 array 两种形式
function XUiTeamPrefabPopupTagSelector:CollectSelectedTags()
    local tags = {}
    if self.SelectedAttributeTagId then
        table.insert(tags, self.SelectedAttributeTagId)
    end
    if self.SelectedModeTagId then
        table.insert(tags, self.SelectedModeTagId)
    end
    local tagsSet = {}
    for _, id in ipairs(tags) do
        tagsSet[id] = true
    end
    return tagsSet, tags
end

function XUiTeamPrefabPopupTagSelector:OnBtnSureClick()
    if self.ConfirmCallback then
        self.ConfirmCallback(self:CollectSelectedTags())
    end
    self:Close()
end

function XUiTeamPrefabPopupTagSelector:OnBtnCancelFilterClick()
    if self.ConfirmCallback then
        self.ConfirmCallback({}, {})
    end
    self:Close()
end

function XUiTeamPrefabPopupTagSelector:OnBtnCloseClick()
    if self.Mode == MODE_SET and (self.SelectedAttributeTagId ~= self._InitAttributeTagId or self.SelectedModeTagId ~= self._InitModeTagId) then
        XLuaUiManager.Open("UiDialog", XUiHelper.GetText("TipTitle"),
            XUiHelper.GetText("SetTeamTag"),
            XUiManager.DialogType.Normal, nil, function()
                if self.ConfirmCallback then
                    self.ConfirmCallback(self:CollectSelectedTags())
                end
                self:Close()
            end, nil, function()
                self:Close()
            end)
        return
    end
    self:Close()
end
