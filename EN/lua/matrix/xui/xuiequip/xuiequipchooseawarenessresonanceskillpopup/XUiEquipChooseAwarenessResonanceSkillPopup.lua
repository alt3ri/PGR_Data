local CSInstantiate = CS.UnityEngine.Object.Instantiate
local CSVector2 = CS.UnityEngine.Vector2
local XUiGridChooseAwarenessResonance = require("XUi/XUiEquip/XUiEquipChooseAwarenessResonanceSkillPopup/XUiGridChooseAwarenessResonance")

-- 数据结构定义
---@class XUiChooseAwarenessTargetResonanceData
---@field ResonanceType number 目标共鸣类型
---@field SkillId number 目标共鸣技能 Id

---@class XUiChooseAwarenessResonanceSlotData
---@field Pos number 共鸣槽位
---@field ResonanceType number|nil 共鸣类型
---@field SkillId number|nil 共鸣技能 Id
---@field BindCharacterId number|nil 共鸣绑定角色 Id
---@field TargetState XEquipAwarenessResonanceTargetState|nil 目标共鸣达成状态
---@field Target XEquipAwarenessResonanceTarget|nil 当前槽位的共鸣目标

---@class XUiChooseAwarenessResonanceRowData
---@field Site number 意识穿戴位
---@field EquipId number 意识装备 Id
---@field IsCanResonance boolean 是否可共鸣
---@field SlotMap table<number, XUiChooseAwarenessResonanceSlotData> 共鸣槽位数据

---@alias XUiChooseAwarenessResonanceSelectedSkillMap table<number, table<number, boolean>>

-- 界面定义
---@class XUiEquipChooseAwarenessResonanceSkillPopup : XLuaUi
---@field _Control XEquipControl
---@field CurrentDataList XUiChooseAwarenessResonanceRowData[] 自身共鸣数据列表
---@field TargetDataList XUiChooseAwarenessResonanceRowData[] 目标共鸣数据列表
---@field Content UnityEngine.UI.GridLayoutGroup 意识行布局组件
---@field ContentCellSize UnityEngine.Vector2 意识行布局原始尺寸
---@field PanelOwnHeight number 自身共鸣区块高度
---@field CharacterId number 当前目标角色 Id
---@field ConfirmCb fun()|nil 确认回调
---@field GridList XUiGridChooseAwarenessResonance[] 意识行 Grid 列表
---@field SelectedSkillMap XUiChooseAwarenessResonanceSelectedSkillMap 当前可共鸣且未达成的已选目标槽位
---@field TargetMatchModeByPos table<number, XEquipAwarenessResonanceTargetMatchMode> 共鸣槽位到目标匹配模式的映射
---@field AwarenessEquipIdBySite table<number, number> 当前角色穿戴意识 Id 字典
---@field TotalCount number 当前可共鸣且未达成的目标槽位总数
---@field BtnClose XUiComponent.XUiButton 关闭按钮
---@field BtnSelectAll XUiComponent.XUiButton 全选按钮
---@field BtnComfirm XUiComponent.XUiButton 确认按钮
---@field ToggleDisplay XUiComponent.XUiButton|UnityEngine.UI.Toggle 当前共鸣显示开关
---@field GridResonance UnityEngine.RectTransform 意识行模板
---@field TxtChoosesNum UnityEngine.UI.Text 已选数量文本
local XUiEquipChooseAwarenessResonanceSkillPopup = XLuaUiManager.Register(XLuaUi, "UiEquipChooseAwarenessResonanceSkillPopup")

-- 初始化弹窗运行期缓存和组件引用
function XUiEquipChooseAwarenessResonanceSkillPopup:OnAwake()
    self.GridList = {}
    self.SelectedSkillMap = {}
    self:InitComponents()
end

-- 绑定按钮、开关、模板节点，并注册基础交互事件
function XUiEquipChooseAwarenessResonanceSkillPopup:InitComponents()
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnSelectAll:AddEventListener(function() self:OnBtnSelectAllClick() end)
    self.BtnComfirm:AddEventListener(function() self:OnBtnComfirmClick() end)
    self.ToggleDisplay.onValueChanged:AddListener(function() self:OnToggleDisplayChanged() end)

    self.GridResonance.gameObject:SetActiveEx(false)
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local go = CSInstantiate(self.GridResonance.gameObject, self.GridResonance.transform.parent)
        local grid = XUiGridChooseAwarenessResonance.New(go, self)
        grid:Open()
        self.GridList[index] = grid
    end
    self.ContentCellSize = self.Content.cellSize
    self.PanelOwnHeight = self.GridList[1]:GetPanelOwnHeight()
end

-- 接收角色、已选共鸣槽和确认回调后刷新界面
---@param characterId number 当前目标角色 Id
---@param selectedSkillMap XUiChooseAwarenessResonanceSelectedSkillMap|nil 外部传入的已选目标槽位
---@param targetMatchModeByPos table<number, XEquipAwarenessResonanceTargetMatchMode> 共鸣槽位到目标匹配模式的映射
---@param confirmCb fun()|nil 确认回调
function XUiEquipChooseAwarenessResonanceSkillPopup:OnStart(
    characterId, selectedSkillMap, targetMatchModeByPos, confirmCb)
    self.CharacterId = characterId
    self.SelectedSkillMap = XTool.Clone(selectedSkillMap) or {}
    local resonancePos = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS
    local targetMatchMode = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE
    self.TargetMatchModeByPos = {
        [resonancePos.UP] = targetMatchModeByPos[resonancePos.UP] or targetMatchMode.TARGET,
        [resonancePos.DOWN] = targetMatchModeByPos[resonancePos.DOWN] or targetMatchMode.TARGET,
    }
    self.ConfirmCb = confirmCb
    self.ToggleDisplay.isOn = false
    self:Refresh()
end

-- 判断当前是否展示角色身上已穿戴意识的实际共鸣技能
---@return boolean 是否展示当前已穿戴意识的实际共鸣技能
function XUiEquipChooseAwarenessResonanceSkillPopup:IsDisplayCurrent()
    return self.ToggleDisplay.isOn
end

-- 按 ToggleDisplay 状态重建数据并刷新列表和计数。
function XUiEquipChooseAwarenessResonanceSkillPopup:Refresh()
    self.AwarenessEquipIdBySite = self._Control:GetCharacterAwarenessIdDic(self.CharacterId)
    self.CurrentDataList = self:BuildCurrentResonanceDataList()
    self.TargetDataList = self:BuildTargetResonanceDataList()
    self.TotalCount = self:GetSelectableTargetSlotCount()
    self:RefreshContentCellSize()
    self:RefreshGridList()
    self:RefreshChooseCount()
end

-- 构建角色当前穿戴 6 件意识的实际共鸣技能数据
---@return XUiChooseAwarenessResonanceRowData[] 当前穿戴意识共鸣数据列表
function XUiEquipChooseAwarenessResonanceSkillPopup:BuildCurrentResonanceDataList()
    local result = {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.AwarenessEquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
        local rowData = self:CreateRowData(site, equipId, isCanResonance)
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local slotData = { Pos = pos }
            rowData.SlotMap[pos] = slotData

            if isCanResonance then
                local resonanceInfo = equip:GetResonanceInfo(pos)
                if resonanceInfo then
                    slotData.ResonanceType = resonanceInfo.Type
                    slotData.SkillId = resonanceInfo.TemplateId
                    slotData.BindCharacterId = resonanceInfo.CharacterId or 0
                end
            end
        end
        table.insert(result, rowData)
    end
    return result
end

-- 构建推荐目标共鸣技能数据
---@return XUiChooseAwarenessResonanceRowData[] 目标共鸣数据列表
function XUiEquipChooseAwarenessResonanceSkillPopup:BuildTargetResonanceDataList()
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(self.CharacterId)
    local resonanceControl = self._Control.ResonanceControl

    local result = {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.AwarenessEquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
        local rowData = self:CreateRowData(site, equipId, isCanResonance)
        local targetSlotData = awarenessSlotList and awarenessSlotList[site]
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local slotData = { Pos = pos }
            rowData.SlotMap[pos] = slotData

            local resonanceList = targetSlotData and targetSlotData.ResonanceList
            local targetResonanceData = resonanceList and resonanceList[pos]
            if targetResonanceData then
                slotData.ResonanceType = targetResonanceData.ResonanceType
                slotData.SkillId = targetResonanceData.SkillId
                slotData.BindCharacterId = self.CharacterId
                slotData.Target = {
                    Pos = pos,
                    MatchMode = self.TargetMatchModeByPos[pos],
                    TargetType = targetResonanceData.ResonanceType,
                    TargetSkillId = targetResonanceData.SkillId,
                }
                if rowData.IsCanResonance then
                    slotData.TargetState = resonanceControl:GetAwarenessResonanceTargetMatchState(
                        equip, slotData.Target, self.CharacterId)
                end
            end
        end
        table.insert(result, rowData)
    end
    return result
end

-- 创建一件意识对应的一行数据
---@param site number 意识穿戴位
---@param equipId number 意识装备 Id
---@param isCanResonance boolean|nil 是否可共鸣
---@return XUiChooseAwarenessResonanceRowData 意识行数据
function XUiEquipChooseAwarenessResonanceSkillPopup:CreateRowData(site, equipId, isCanResonance)
    return {
        Site = site,
        EquipId = equipId,
        IsCanResonance = isCanResonance == true,
        SlotMap = {},
    }
end

-- 统计当前可共鸣且未达成的目标槽位总数。
---@return number 可选择的目标共鸣技能槽位总数
function XUiEquipChooseAwarenessResonanceSkillPopup:GetSelectableTargetSlotCount()
    local count = 0
    for _, rowData in ipairs(self.TargetDataList) do
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            if self:CanSelectTargetSlot(rowData.Site, pos) then
                count = count + 1
            end
        end
    end
    return count
end

-- 刷新一行一件意识的共鸣技能列表
function XUiEquipChooseAwarenessResonanceSkillPopup:RefreshGridList()
    local isDisplayCurrent = self:IsDisplayCurrent()
    for index, grid in ipairs(self.GridList) do
        grid:Refresh(self.TargetDataList[index], self.CurrentDataList[index], isDisplayCurrent)
    end
end

-- 按自身共鸣区块显隐刷新外层 GridLayoutGroup 的行高
function XUiEquipChooseAwarenessResonanceSkillPopup:RefreshContentCellSize()
    local isDisplayCurrent = self:IsDisplayCurrent()
    local height = isDisplayCurrent and self.ContentCellSize.y or self.ContentCellSize.y - self.PanelOwnHeight
    self.Content.cellSize = CSVector2(self.ContentCellSize.x, height)
end

-- 判断指定共鸣槽位是否被选中
---@param site number 意识穿戴位
---@param pos number 共鸣槽位
---@return boolean 是否已选中
function XUiEquipChooseAwarenessResonanceSkillPopup:IsSlotSelected(site, pos)
    local posMap = self.SelectedSkillMap[site]
    return posMap ~= nil and posMap[pos] == true
end

-- 判断指定目标共鸣槽位是否已达成
---@param site number 意识穿戴位
---@param pos number 共鸣槽位
---@return boolean 是否已达成
function XUiEquipChooseAwarenessResonanceSkillPopup:IsTargetSlotAchieved(site, pos)
    local slotData = self.TargetDataList[site].SlotMap[pos]
    local targetState = slotData.TargetState
    return targetState ~= nil and targetState.IsAchieved == true
end

-- 判断指定目标槽位是否可被用户选择；已达成槽位仅展示完成态，不参与运行时选择。
---@param site number 意识穿戴位
---@param pos number 共鸣槽位
---@return boolean 是否可选择目标共鸣槽位
function XUiEquipChooseAwarenessResonanceSkillPopup:CanSelectTargetSlot(site, pos)
    local rowData = self.TargetDataList[site]
    local slotData = rowData.SlotMap[pos]
    local hasTarget = slotData.Target ~= nil
    local isAchieved = self:IsTargetSlotAchieved(site, pos)
    return rowData.IsCanResonance and hasTarget and not isAchieved
end

-- 点击单个共鸣技能槽时切换选中状态
---@param site number 意识穿戴位
---@param pos number 共鸣槽位
function XUiEquipChooseAwarenessResonanceSkillPopup:OnGridResonanceSkillClick(site, pos)
    if not self:CanSelectTargetSlot(site, pos) then
        return
    end

    local posMap = self.SelectedSkillMap[site]
    if posMap and posMap[pos] then
        posMap[pos] = nil
        if next(posMap) == nil then
            self.SelectedSkillMap[site] = nil
        end
    else
        self.SelectedSkillMap[site] = self.SelectedSkillMap[site] or {}
        self.SelectedSkillMap[site][pos] = true
    end
    self:RefreshGridSelectedState()
    self:RefreshChooseCount()
end

-- 切换展示来源后重新构建列表
function XUiEquipChooseAwarenessResonanceSkillPopup:OnToggleDisplayChanged()
    self:Refresh()
end

-- 点击关闭按钮
function XUiEquipChooseAwarenessResonanceSkillPopup:OnBtnCloseClick()
    self:Close()
end

-- 根据当前选择数量执行全选或全部取消
function XUiEquipChooseAwarenessResonanceSkillPopup:OnBtnSelectAllClick()
    local selectedCount = self:GetSelectedSkillCount()
    local isSelectAll = selectedCount < self.TotalCount
    self.SelectedSkillMap = {}
    if isSelectAll then
        for _, rowData in ipairs(self.TargetDataList) do
            local selectedPosMap = {}
            for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                if self:CanSelectTargetSlot(rowData.Site, pos) then
                    selectedPosMap[pos] = true
                end
            end
            if next(selectedPosMap) then
                self.SelectedSkillMap[rowData.Site] = selectedPosMap
            end
        end
    end

    self:RefreshGridSelectedState()
    self:RefreshChooseCount()
end

-- 保存选择缓存并通知外部刷新。
function XUiEquipChooseAwarenessResonanceSkillPopup:OnBtnComfirmClick()
    self:SaveSelectedSkillMap()

    if self.ConfirmCb then
        self.ConfirmCb()
    end
    self:Close()
end

-- 刷新所有 Grid 上的槽位选中显示
function XUiEquipChooseAwarenessResonanceSkillPopup:RefreshGridSelectedState()
    for _, grid in ipairs(self.GridList) do
        grid:RefreshSelected()
    end
end

-- 刷新已选数量文本和全选按钮状态
function XUiEquipChooseAwarenessResonanceSkillPopup:RefreshChooseCount()
    local selectedCount = self:GetSelectedSkillCount()
    self.TxtChoosesNum.text = string.format("%d/%d", selectedCount, self.TotalCount)

    local isAllSelected = self.TotalCount > 0 and selectedCount >= self.TotalCount
    self.BtnSelectAll:SetButtonState(isAllSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 统计当前可选择且已选中的目标共鸣槽位数量。
---@return number 已选中的目标共鸣槽位数量
function XUiEquipChooseAwarenessResonanceSkillPopup:GetSelectedSkillCount()
    local count = 0
    for _, rowData in ipairs(self.TargetDataList) do
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            if self:CanSelectTargetSlot(rowData.Site, pos) and self:IsSlotSelected(rowData.Site, pos) then
                count = count + 1
            end
        end
    end
    return count
end

-- 保存本次有效选择；当前已达成槽位保留原缓存，避免切换方案后改变用户勾选范围。
function XUiEquipChooseAwarenessResonanceSkillPopup:SaveSelectedSkillMap()
    local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
    local settingControl = self._Control.OneClickAutoSettingControl
    local cachedSkillMap = XTool.Clone(settingControl:GetCharacterSetting(self.CharacterId, settingType.AwarenessResonanceSelectedSkillMap))

    for _, rowData in ipairs(self.TargetDataList) do
        if rowData.IsCanResonance then
            cachedSkillMap[rowData.Site] = cachedSkillMap[rowData.Site] or {}
            local cachedPosMap = cachedSkillMap[rowData.Site]
            local selectedPosMap = self.SelectedSkillMap[rowData.Site]
            for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                local isAchieved = self:IsTargetSlotAchieved(rowData.Site, pos)
                if not isAchieved then
                    local isSelected = selectedPosMap ~= nil and selectedPosMap[pos] == true
                    cachedPosMap[pos] = isSelected
                end
            end
        end
    end

    settingControl:SetCharacterSetting(self.CharacterId, settingType.AwarenessResonanceSelectedSkillMap, cachedSkillMap)
end

return XUiEquipChooseAwarenessResonanceSkillPopup
