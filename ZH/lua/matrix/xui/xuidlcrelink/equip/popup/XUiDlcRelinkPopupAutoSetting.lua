---@class XUiDlcRelinkPopupAutoSetting : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelTab XUiButtonGroup
local XUiDlcRelinkPopupAutoSetting = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupAutoSetting")

-- 特性网格视觉状态
local CharacteristicState = {
    Normal = 1, -- 未选中
    Select = 2, -- 已选中
}

-- 预计算全选掩码常量
local EQUIP_TYPE_ALL_MASK = (1 << XEnumConst.DlcRelink.EquipType.Main) | (1 << XEnumConst.DlcRelink.EquipType.Normal)
local QUALITY_ALL_MASK = (1 << XEnumConst.DlcRelink.EquipQualityType.Rare) | (1 << XEnumConst.DlcRelink.EquipQualityType.Epic) | (1 << XEnumConst.DlcRelink.EquipQualityType.Legendary) | (1 << XEnumConst.DlcRelink.EquipQualityType.Mythic)

function XUiDlcRelinkPopupAutoSetting:OnAwake()
    self:RegisterUiEvents()
    self.BtnTab.gameObject:SetActiveEx(false)
    self.GridContent1.gameObject:SetActiveEx(false)
    self.GridContent2.gameObject:SetActiveEx(false)
    self.GridCharacteristic.gameObject:SetActiveEx(false)

    ---@type XUiComponent.XUiButton[]
    self.EquipTypeToggles = {}
    ---@type XUiComponent.XUiButton[]
    self.QualityToggles = {}
    ---@type UiObject[]
    self.CharacteristicGridList = {}
    ---@type table[] 缓存特性网格子控件引用
    self.CharacteristicGridRefs = {}
    ---@type XUiComponent.XUiButton[]
    self.TabButtons = {}

    self:InitPanelTab()
    self:InitFilterGrids()
end

function XUiDlcRelinkPopupAutoSetting:OnStart()
    self.CurTabIndex = 0 -- 当前选中的Tab索引
    local markSettingDataList = self._Control:GetEquipsMarkSettingDataList()
    -- 初始化数据
    for ruleType = XEnumConst.DlcRelink.EquipRuleType.Lock, XEnumConst.DlcRelink.EquipRuleType.Discard do
        markSettingDataList[ruleType] = markSettingDataList[ruleType] or {}
        markSettingDataList[ruleType].EquipTypes = markSettingDataList[ruleType].EquipTypes or 0
        markSettingDataList[ruleType].QualityTypes = markSettingDataList[ruleType].QualityTypes or 0
        markSettingDataList[ruleType].FactorIds = markSettingDataList[ruleType].FactorIds or {}
    end
    ---@type table<number, XDlcRelinkEquipMarkSettingData>
    self.OriginalData = XTool.Clone(markSettingDataList)
    ---@type table<number, XDlcRelinkEquipMarkSettingData>
    self.EditCache = XTool.Clone(markSettingDataList) -- 编辑缓存
end

function XUiDlcRelinkPopupAutoSetting:OnEnable()
    self.PanelTab:SelectIndex(1)
end

function XUiDlcRelinkPopupAutoSetting:OnDestroy()
    self.OriginalData = nil
    self.EditCache = nil
end

--region Tab初始化

function XUiDlcRelinkPopupAutoSetting:InitPanelTab()
    for index = XEnumConst.DlcRelink.EquipRuleType.Lock, XEnumConst.DlcRelink.EquipRuleType.Discard do
        ---@type XUiComponent.XUiButton
        local btn = XUiHelper.Instantiate(self.BtnTab, self.PanelTab.transform)
        local name = self._Control:GetClientConfig("AutoSettingTabName", index)
        btn:SetNameByGroup(0, name)
        local image = self._Control:GetClientConfig("AutoSettingTabImage", index)
        btn:SetSprite(image)
        btn.gameObject:SetActiveEx(true)
        self.TabButtons[index] = btn
    end
    self.PanelTab:Init(self.TabButtons, function(index) self:OnTabClick(index) end)
end

function XUiDlcRelinkPopupAutoSetting:OnTabClick(index)
    if self.CurTabIndex == index then
        return
    end
    self.CurTabIndex = index
    self:RefreshAllFilters()
end

--endregion

--region 筛选项初始化与刷新

function XUiDlcRelinkPopupAutoSetting:InitFilterGrids()
    self:InitEquipTypeGrid()
    self:InitQualityGrid()
    self:InitCharacteristicGrid()
end

-- 初始化装备类型网格
function XUiDlcRelinkPopupAutoSetting:InitEquipTypeGrid()
    for index = 1, XEnumConst.DlcRelink.EquipType.Normal do
        ---@type UiObject
        local grid = XUiHelper.Instantiate(self.GridContent1, self.ImgBgContent1.transform)
        local btn = grid:GetObject("TogType")
        local name = self._Control:GetClientConfig("AutoSettingEquipTypeName", index)
        btn:SetNameByGroup(0, name)
        btn:AddEventListener(function()
            self:OnEquipTypeToggle(index)
        end)
        grid.gameObject:SetActiveEx(true)
        self.EquipTypeToggles[index] = btn
    end
end

-- 初始化装备品质网格
function XUiDlcRelinkPopupAutoSetting:InitQualityGrid()
    for index = 1, XEnumConst.DlcRelink.EquipQualityType.Mythic do
        ---@type UiObject
        local grid = XUiHelper.Instantiate(self.GridContent2, self.ImgBgContent2.transform)
        local btn = grid:GetObject("TogType")
        local name = self._Control:GetClientConfig("AutoSettingQualityTypeName", index)
        btn:SetNameByGroup(0, name)
        btn:AddEventListener(function()
            self:OnQualityToggle(index)
        end)
        grid.gameObject:SetActiveEx(true)
        self.QualityToggles[index] = btn
    end
end

-- 初始化装备特性网格
function XUiDlcRelinkPopupAutoSetting:InitCharacteristicGrid()
    self.CharacteristicList = self:BuildCharacteristicList()
    for index, data in ipairs(self.CharacteristicList) do
        ---@type UiObject
        local grid = XUiHelper.Instantiate(self.GridCharacteristic, self.ImgBgContent3.transform)
        grid:GetObject("TxtType1").text = data.Name
        grid:GetObject("TxtType2").text = data.Name
        grid:GetObject("TxtType3").text = data.Name
        local isHaveIcon = not string.IsNilOrEmpty(data.Icon)
        grid:GetObject("ImgAvatar1").gameObject:SetActiveEx(isHaveIcon)
        grid:GetObject("ImgAvatar2").gameObject:SetActiveEx(isHaveIcon)
        grid:GetObject("ImgAvatar3").gameObject:SetActiveEx(isHaveIcon)
        if isHaveIcon then
            grid:GetObject("ImgAvatar1"):SetSprite(data.Icon)
            grid:GetObject("ImgAvatar2"):SetSprite(data.Icon)
            grid:GetObject("ImgAvatar3"):SetSprite(data.Icon)
        end
        grid:GetObject("BtnClick"):AddEventListener(function()
            self:OnCharacteristicClick(index)
        end)
        grid.gameObject:SetActiveEx(true)
        self.CharacteristicGridList[index] = grid
        -- 缓存子控件引用
        self.CharacteristicGridRefs[index] = {
            HasIcon = isHaveIcon,
            Normal = grid:GetObject("Normal").gameObject,
            Select = grid:GetObject("Select").gameObject,
            Disable = grid:GetObject("Disable").gameObject,
            TxtTypes = {
                grid:GetObject("TxtType1").gameObject,
                grid:GetObject("TxtType2").gameObject,
                grid:GetObject("TxtType3").gameObject,
            },
            ImgAvatars = {
                grid:GetObject("ImgAvatar1").gameObject,
                grid:GetObject("ImgAvatar2").gameObject,
                grid:GetObject("ImgAvatar3").gameObject,
            },
        }
    end
end

-- 构建特性列表
function XUiDlcRelinkPopupAutoSetting:BuildCharacteristicList()
    local list = {}
    local configs = self._Control:GetFactorDescConfigs()
    if configs then
        for _, config in pairs(configs) do
            table.insert(list, {
                Id = config.Id,
                Name = config.Name or "",
                Icon = config.CharacterIcon or "",
                Order = config.Order or 0,
            })
        end
        table.sort(list, function(a, b)
            return a.Order < b.Order
        end)
    end
    return list
end

-- 刷新所有筛选项的显示状态
function XUiDlcRelinkPopupAutoSetting:RefreshAllFilters()
    self:RefreshEquipTypeToggles()
    self:RefreshQualityToggles()
    self:RefreshCharacteristicToggles()
    self:RefreshDesc()
    self:RefreshConflictTab()
end

--endregion

--region 数据处理

-- 装备类型是否全选
function XUiDlcRelinkPopupAutoSetting:IsEquipTypeAllSelected(ruleType)
    return self.EditCache[ruleType].EquipTypes == EQUIP_TYPE_ALL_MASK
end

-- 装备品质是否全选
function XUiDlcRelinkPopupAutoSetting:IsQualityAllSelected(ruleType)
    return self.EditCache[ruleType].QualityTypes == QUALITY_ALL_MASK
end

-- 装备特性是否全选
function XUiDlcRelinkPopupAutoSetting:IsCharacteristicAllSelected(ruleType)
    local factorIds = self.EditCache[ruleType].FactorIds
    if #factorIds < #self.CharacteristicList then
        return false
    end
    local idSet = {}
    for _, id in ipairs(factorIds) do
        idSet[id] = true
    end
    for _, data in ipairs(self.CharacteristicList) do
        if not idSet[data.Id] then
            return false
        end
    end
    return true
end

-- 检查是否有未保存的修改
function XUiDlcRelinkPopupAutoSetting:CheckDirty()
    if not self.OriginalData then
        return false
    end
    for ruleType, data in pairs(self.EditCache) do
        local snap = self.OriginalData[ruleType]
        if not snap then
            return true
        end
        if data.EquipTypes ~= snap.EquipTypes then
            return true
        end
        if data.QualityTypes ~= snap.QualityTypes then
            return true
        end
        -- 比较FactorIds
        if #data.FactorIds ~= #snap.FactorIds then
            return true
        end
        local factorSet = {}
        for _, id in ipairs(snap.FactorIds) do
            factorSet[id] = true
        end
        for _, id in ipairs(data.FactorIds) do
            if not factorSet[id] then
                return true
            end
        end
    end
    return false
end

--endregion

--region 装备类型操作

-- 单个装备类型开关点击
function XUiDlcRelinkPopupAutoSetting:OnEquipTypeToggle(index)
    local data = self.EditCache[self.CurTabIndex]
    local bit = 1 << index
    -- 切换选中状态（异或）
    data.EquipTypes = data.EquipTypes ~ bit
    self:RefreshEquipTypeToggles()
    self:RefreshConflictTab()
end

-- 刷新装备类型开关显示
function XUiDlcRelinkPopupAutoSetting:RefreshEquipTypeToggles()
    local data = self.EditCache[self.CurTabIndex]
    for index = 1, XEnumConst.DlcRelink.EquipType.Normal do
        local bit = 1 << index
        local btn = self.EquipTypeToggles[index]
        local isSelected = (data.EquipTypes & bit) ~= 0
        btn:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    -- 更新全选按钮状态
    local isAllSelected = self:IsEquipTypeAllSelected(self.CurTabIndex)
    self.TogType1:SetButtonState(isAllSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 全选按钮
function XUiDlcRelinkPopupAutoSetting:OnTogType1Click()
    local data = self.EditCache[self.CurTabIndex]
    if data.EquipTypes == EQUIP_TYPE_ALL_MASK then
        data.EquipTypes = 0
    else
        data.EquipTypes = EQUIP_TYPE_ALL_MASK
    end
    self:RefreshEquipTypeToggles()
    self:RefreshConflictTab()
end

--endregion

--region 装备品质操作

-- 单个装备品质开关点击
function XUiDlcRelinkPopupAutoSetting:OnQualityToggle(index)
    local data = self.EditCache[self.CurTabIndex]
    local bit = 1 << index
    -- 切换选中状态（异或）
    data.QualityTypes = data.QualityTypes ~ bit
    self:RefreshQualityToggles()
    self:RefreshConflictTab()
end

-- 刷新装备品质开关显示
function XUiDlcRelinkPopupAutoSetting:RefreshQualityToggles()
    local data = self.EditCache[self.CurTabIndex]
    for index = 1, XEnumConst.DlcRelink.EquipQualityType.Mythic do
        local bit = 1 << index
        local btn = self.QualityToggles[index]
        local isSelected = (data.QualityTypes & bit) ~= 0
        btn:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    -- 更新全选按钮状态
    local isAllSelected = self:IsQualityAllSelected(self.CurTabIndex)
    self.TogType2:SetButtonState(isAllSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 全选按钮
function XUiDlcRelinkPopupAutoSetting:OnTogType2Click()
    local data = self.EditCache[self.CurTabIndex]
    if data.QualityTypes == QUALITY_ALL_MASK then
        data.QualityTypes = 0
    else
        data.QualityTypes = QUALITY_ALL_MASK
    end
    self:RefreshQualityToggles()
    self:RefreshConflictTab()
end

--endregion

--region 装备特性操作

-- 单个装备特性点击
function XUiDlcRelinkPopupAutoSetting:OnCharacteristicClick(index)
    local data = self.EditCache[self.CurTabIndex]
    local factorId = self.CharacteristicList[index].Id
    -- 切换选中状态
    local contain, pos = table.contains(data.FactorIds, factorId)
    if contain then
        table.remove(data.FactorIds, pos)
    else
        table.insert(data.FactorIds, factorId)
    end
    self:RefreshCharacteristicToggles()
    self:RefreshConflictTab()
end

-- 刷新装备特性开关显示
function XUiDlcRelinkPopupAutoSetting:RefreshCharacteristicToggles()
    local data = self.EditCache[self.CurTabIndex]
    local selectedSet = {}
    for _, id in ipairs(data.FactorIds) do
        selectedSet[id] = true
    end
    local allSelected = #self.CharacteristicList > 0 -- 空列表视为非全选
    for index, charData in ipairs(self.CharacteristicList) do
        local factorId = charData.Id
        local isSelected = selectedSet[factorId] == true
        if not isSelected then
            allSelected = false
        end
        self:SetCharacteristicGridState(index, isSelected and CharacteristicState.Select or CharacteristicState.Normal)
    end
    -- 直接使用循环中已计算的全选结果
    self.TogType3:SetButtonState(allSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 设置特性网格的视觉状态
function XUiDlcRelinkPopupAutoSetting:SetCharacteristicGridState(index, state)
    local refs = self.CharacteristicGridRefs[index]
    for i = 1, 3 do
        local isActive = (i == state)
        refs.TxtTypes[i]:SetActiveEx(isActive)
        refs.ImgAvatars[i]:SetActiveEx(isActive and refs.HasIcon)
    end
    refs.Normal:SetActiveEx(state == CharacteristicState.Normal)
    refs.Select:SetActiveEx(state == CharacteristicState.Select)
    refs.Disable:SetActiveEx(false)
end

-- 全选按钮
function XUiDlcRelinkPopupAutoSetting:OnTogType3Click()
    local data = self.EditCache[self.CurTabIndex]
    local isAllSelected = self:IsCharacteristicAllSelected(self.CurTabIndex)
    if isAllSelected then
        -- 全选状态 → 清空所有
        data.FactorIds = {}
    else
        -- 非全选 → 全部选中
        data.FactorIds = {}
        for _, charData in ipairs(self.CharacteristicList) do
            table.insert(data.FactorIds, charData.Id)
        end
    end
    self:RefreshCharacteristicToggles()
    self:RefreshConflictTab()
end

--endregion

--region 界面刷新

-- 刷新规则说明文本
function XUiDlcRelinkPopupAutoSetting:RefreshDesc()
    local desc = self._Control:GetClientConfig("AutoSettingDesc", self.CurTabIndex)
    self.TxtDesc.text = desc
end

-- 刷新弃置Tab的冲突标记
function XUiDlcRelinkPopupAutoSetting:RefreshConflictTab()
    local discardTab = self.TabButtons[XEnumConst.DlcRelink.EquipRuleType.Discard]
    if discardTab then
        local hasConflict = self._Control:HasEquipsMarkSettingDataConflict(self.EditCache)
        discardTab:ShowTag(hasConflict)
        self.PanelPopupNotice.gameObject:SetActiveEx(hasConflict and self.CurTabIndex == XEnumConst.DlcRelink.EquipRuleType.Discard)
    end
    -- 刷新保存按钮状态
    local isDirty = self:CheckDirty()
    self.BtnConfirm:SetDisable(not isDirty, isDirty)
end

--endregion

--region 事件注册

function XUiDlcRelinkPopupAutoSetting:RegisterUiEvents()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    self.TogType1:AddEventListener(handler(self, self.OnTogType1Click))
    self.TogType2:AddEventListener(handler(self, self.OnTogType2Click))
    self.TogType3:AddEventListener(handler(self, self.OnTogType3Click))
end

--endregion

--region 按钮回调

-- 关闭按钮
function XUiDlcRelinkPopupAutoSetting:OnBtnCloseClick()
    if self:CheckDirty() then
        -- 有未保存的修改，弹二次确认
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("AutoSettingUnsavedTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "AutoSettingUnsavedTip" }
        self._Control:OpenCommonTipDialog(title, content, nil, function()
            self:Close()
        end, extraData)
    else
        self:Close()
    end
end

-- 保存按钮
function XUiDlcRelinkPopupAutoSetting:OnBtnConfirmClick()
    if not self:CheckDirty() then
        self:Close()
        return
    end

    local settings = {}
    for ruleType, data in pairs(self.EditCache) do
        table.insert(settings, {
            RuleType = ruleType,
            EquipType = data.EquipTypes,
            EquipQuality = data.QualityTypes,
            EquipFactorIds = data.FactorIds,
        })
    end

    self._Control:RequestSetEquipModRule(settings, function()
        self._Control:OpenCommonTipSuccess(self._Control:GetClientConfig("AutoSettingSavedTip"))
        self:Close()
    end)
end

--endregion

return XUiDlcRelinkPopupAutoSetting
