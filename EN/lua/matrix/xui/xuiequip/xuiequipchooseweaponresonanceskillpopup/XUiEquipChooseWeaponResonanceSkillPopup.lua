-- 武器共鸣技能选择弹窗：玩家选择本次要共鸣的技能，确认后回传给一键养成弹窗
local XUiGridChooseWeaponResonanceSkill = require("XUi/XUiEquip/XUiEquipChooseWeaponResonanceSkillPopup/XUiGridChooseWeaponResonanceSkill")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

-- 行高：不勾选"显示当前"只展示目标技能 Item1；勾选后追加当前已共鸣 Item2，行高翻倍
local GRID_HEIGHT_TARGET_ONLY = 244
local GRID_HEIGHT_WITH_CURRENT = 508
local GRID_WIDTH = 580

---@class XUiEquipChooseWeaponResonanceSkillPopup : XLuaUi
---@field _Control XEquipControl
local XUiEquipChooseWeaponResonanceSkillPopup = XLuaUiManager.Register(XLuaUi, "UiEquipChooseWeaponResonanceSkillPopup")

function XUiEquipChooseWeaponResonanceSkillPopup:OnAwake()
    self:RegisterButtonEvent()
    self.GridSkill.gameObject:SetActiveEx(false)
    self.RowDataList = {}
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillScroll)
    self.DynamicTable:SetProxy(XUiGridChooseWeaponResonanceSkill, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiEquipChooseWeaponResonanceSkillPopup:RegisterButtonEvent()
    self.BtnCloseMask:AddEventListener(handler(self, self.Close))
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    self.BtnAll:AddEventListener(handler(self, self.OnBtnAllClick))
    self.ToggleDisplay.onValueChanged:AddListener(handler(self, self.OnToggleDisplayChanged))
end

--- @param equipId number 武器实例 Id
--- @param targetData table 养成目标数据（含 WeaponResonanceList）
--- @param selectedSkillMap table<number, boolean>|nil 已选槽位（by Pos）
--- @param confirmCb fun(selectedSkillMap:table<number, boolean>)|nil 确认回调
function XUiEquipChooseWeaponResonanceSkillPopup:OnStart(equipId, targetData, selectedSkillMap, confirmCb)
    self.EquipId = equipId
    self.TargetData = targetData
    self.SelectedSkillMap = XTool.Clone(selectedSkillMap) or {}
    self.ConfirmCb = confirmCb
    self.ToggleDisplay.isOn = false
    self:Refresh()
end

function XUiEquipChooseWeaponResonanceSkillPopup:IsDisplayCurrent()
    return self.ToggleDisplay.isOn
end

function XUiEquipChooseWeaponResonanceSkillPopup:Refresh()
    self:BuildRowDataList()
    self:PruneSelectedSkillMap()
    self:RefreshGridSize()
    self.DynamicTable:SetDataSource(self.RowDataList)
    self.DynamicTable:ReloadDataSync()
    self:RefreshChooseCount()
end

--- 按"显示当前"开关调整行高
function XUiEquipChooseWeaponResonanceSkillPopup:RefreshGridSize()
    local height = self:IsDisplayCurrent() and GRID_HEIGHT_WITH_CURRENT or GRID_HEIGHT_TARGET_ONLY
    self.DynamicTable:SetGridSize(CS.UnityEngine.Vector2(GRID_WIDTH, height))
end

--- 构建 3 个共鸣槽位数据：每槽含目标技能 + 武器当前已共鸣技能
function XUiEquipChooseWeaponResonanceSkillPopup:BuildRowDataList()
    local rowDataList = self.RowDataList
    for i = #rowDataList, 1, -1 do
        rowDataList[i] = nil
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local curCharacterId = equip and equip.CharacterId or 0
    local isDisplayCurrent = self:IsDisplayCurrent()
    -- 目标技能按已共鸣槽位重排（swap）：已共鸣的目标技能落到其真实槽，显"已达成"
    local targets = equip and self._Control.OneClickCultureControl:_BuildSwappedResonanceTargets(equip, self.TargetData) or {}

    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local target = targets[pos] or {}
        local currentInfo = equip and equip:GetResonanceInfo(pos)
        table.insert(rowDataList, {
            Pos = pos,
            Target = {
                Pos = pos,
                SkillId = target.SkillId or 0,
                ResonanceType = target.ResonanceType,
                IsComplete = target.IsComplete == true,
            },
            Current = {
                Pos = pos,
                SkillId = currentInfo and currentInfo.TemplateId or 0,
                ResonanceType = currentInfo and currentInfo.Type,
                BindCharacterId = currentInfo and currentInfo.CharacterId or 0,
                CurCharacterId = curCharacterId,
            },
            IsDisplayCurrent = isDisplayCurrent,
        })
    end
end

--- 该槽位是否可被选择：目标有技能，且尚未达成（已达成无需再选）
function XUiEquipChooseWeaponResonanceSkillPopup:IsPosSelectable(pos)
    local row = self.RowDataList[pos]
    return row ~= nil and XTool.IsNumberValid(row.Target.SkillId) and not row.Target.IsComplete
end

function XUiEquipChooseWeaponResonanceSkillPopup:IsSlotSelected(pos)
    return self.SelectedSkillMap[pos] == true
end

--- 目标可选总数 = 目标有技能且未达成的槽位数
function XUiEquipChooseWeaponResonanceSkillPopup:GetSelectableTotalCount()
    local count = 0
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        if self:IsPosSelectable(pos) then
            count = count + 1
        end
    end
    return count
end

function XUiEquipChooseWeaponResonanceSkillPopup:GetSelectedCount()
    local count = 0
    for pos in pairs(self.SelectedSkillMap) do
        if self:IsPosSelectable(pos) then
            count = count + 1
        end
    end
    return count
end

--- 裁剪已选表：移除不可选（无技能/已达成）的槽位
function XUiEquipChooseWeaponResonanceSkillPopup:PruneSelectedSkillMap()
    for pos in pairs(self.SelectedSkillMap) do
        if not self:IsPosSelectable(pos) then
            self.SelectedSkillMap[pos] = nil
        end
    end
end

--- 目标技能点击：切换选中
function XUiEquipChooseWeaponResonanceSkillPopup:OnTargetSkillClick(pos)
    if not self:IsPosSelectable(pos) then
        return
    end
    if self.SelectedSkillMap[pos] then
        self.SelectedSkillMap[pos] = nil
    else
        self.SelectedSkillMap[pos] = true
    end
    self.DynamicTable:ReloadDataSync()
    self:RefreshChooseCount()
end

function XUiEquipChooseWeaponResonanceSkillPopup:OnToggleDisplayChanged()
    self:Refresh()
end

--- 全选/取消：全选选中所有可选槽位，否则清空
function XUiEquipChooseWeaponResonanceSkillPopup:OnBtnAllClick()
    local isSelectAll = self:GetSelectedCount() < self:GetSelectableTotalCount()
    self.SelectedSkillMap = {}
    if isSelectAll then
        for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
            if self:IsPosSelectable(pos) then
                self.SelectedSkillMap[pos] = true
            end
        end
    end
    self.DynamicTable:ReloadDataSync()
    self:RefreshChooseCount()
end

--- 刷新 x/y 文本与全选按钮状态
function XUiEquipChooseWeaponResonanceSkillPopup:RefreshChooseCount()
    local selectedCount = self:GetSelectedCount()
    local totalCount = self:GetSelectableTotalCount()
    self.TxtChoosesNum.text = string.format("%d/%d", selectedCount, totalCount)

    local isAllSelected = totalCount > 0 and selectedCount >= totalCount
    self.BtnAll:SetButtonState(isAllSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiEquipChooseWeaponResonanceSkillPopup:OnBtnConfirmClick()
    if self.ConfirmCb then
        self.ConfirmCb(self.SelectedSkillMap)
    end
    self:Close()
end

--- DynamicTable 回调
function XUiEquipChooseWeaponResonanceSkillPopup:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.RowDataList[index], index)
    end
end

return XUiEquipChooseWeaponResonanceSkillPopup
