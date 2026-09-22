local XUiGridTRAwarenessResonanceSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRAwarenessResonanceSkill")
local TARGET_MATCH_MODE = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE

local TARGET_DESCRIPTION_TEXT_KEY_BY_MATCH_MODE = {
    [TARGET_MATCH_MODE.ANY] = "AwarenessOneClickResonanceSkillTypeAny",
    [TARGET_MATCH_MODE.ATTACK] = {
        [XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP] = "AwarenessOneClickResonanceSkillTypeAttackAttribute",
        [XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.DOWN] = "AwarenessOneClickResonanceSkillTypeAttack",
    },
}

---@class XUiGridChooseAwarenessResonanceSlot : XUiNode
---@field Parent XUiGridChooseAwarenessResonance 所属意识行 Grid
---@field UiRoot XUiEquipChooseAwarenessResonanceSkillPopup 根弹窗
---@field Data XUiChooseAwarenessResonanceSlotData 当前槽位数据
---@field RowData XUiChooseAwarenessResonanceRowData 当前意识行数据
---@field IsSelectable boolean 是否参与目标选择
---@field TargetSkillGrid XUiGridTRAwarenessResonanceSkill|nil 目标共鸣技能 Grid
---@field OwnSkillGrid XUiGridTRAwarenessResonanceSkill|nil 自身共鸣技能 Grid
---@field Button XUiComponent.XUiButton 槽位点击按钮
---@field BtnResonance XUiComponent.XUiButton 选中态按钮
---@field ImgSelect UnityEngine.UI.Image 选中标记
---@field PanelComplete UnityEngine.RectTransform 已达成标记
---@field PanelResonanceSkillTarget UnityEngine.RectTransform 目标共鸣技能面板
---@field GridResonanceSkillTarget UnityEngine.RectTransform 目标共鸣技能节点
---@field TxtSkillDesTarget UnityEngine.UI.Text 目标共鸣技能描述
---@field PanelResonanceSkillOwn UnityEngine.RectTransform 自身共鸣技能面板
---@field GridResonanceSkillOwn UnityEngine.RectTransform 自身共鸣技能节点
---@field TxtSkillDesOwn UnityEngine.UI.Text 自身共鸣技能描述
---@field PanelUnResonance UnityEngine.RectTransform 不可共鸣节点
---@field PanelNoResonanceSkill UnityEngine.RectTransform 空共鸣槽位节点
local XUiGridChooseAwarenessResonanceSlot = XClass(XUiNode, "XUiGridChooseAwarenessResonanceSlot")

-- 初始化单个共鸣槽位，并按是否参与选择绑定点击。
---@param uiRoot XUiEquipChooseAwarenessResonanceSkillPopup
---@param isSelectable boolean
function XUiGridChooseAwarenessResonanceSlot:OnStart(uiRoot, isSelectable)
    self.UiRoot = uiRoot
    self.IsSelectable = isSelectable

    if self.IsSelectable then
        self.UiRoot:RegisterClickEvent(self.Button, function() self:OnGridClick() end)
    end
end

-- 按槽位数据刷新技能、空槽或不可共鸣状态。
---@param slotData XUiChooseAwarenessResonanceSlotData
---@param rowData XUiChooseAwarenessResonanceRowData
function XUiGridChooseAwarenessResonanceSlot:Refresh(slotData, rowData)
    self.Data = slotData
    self.RowData = rowData
    self.PanelResonanceSkillTarget.gameObject:SetActiveEx(false)
    self.PanelResonanceSkillOwn.gameObject:SetActiveEx(false)
    self.PanelUnResonance.gameObject:SetActiveEx(false)
    self.PanelNoResonanceSkill.gameObject:SetActiveEx(false)

    if not rowData.IsCanResonance then
        self.PanelUnResonance.gameObject:SetActiveEx(true)
    elseif not XTool.IsNumberValid(slotData.SkillId) or not XTool.IsNumberValid(slotData.ResonanceType) then
        self.PanelNoResonanceSkill.gameObject:SetActiveEx(true)
    else
        local skillInfo = XMVCA.XEquip:CreateResonanceSkillInfo(slotData.ResonanceType, slotData.SkillId)
        if not skillInfo then
            self.PanelNoResonanceSkill.gameObject:SetActiveEx(true)
        elseif self.IsSelectable then
            self:RefreshTargetResonanceSkill(skillInfo, slotData)
        else
            self:RefreshOwnResonanceSkill(skillInfo, slotData)
        end
    end
    self:RefreshSelected()
end

-- 刷新目标共鸣技能的图标、描述和目标达成状态
---@param skillInfo XEquipResonanceSkillInfo
---@param slotData XUiChooseAwarenessResonanceSlotData
function XUiGridChooseAwarenessResonanceSlot:RefreshTargetResonanceSkill(skillInfo, slotData)
    self.PanelResonanceSkillTarget.gameObject:SetActiveEx(true)
    local matchMode = slotData.Target.MatchMode
    local textKey = TARGET_DESCRIPTION_TEXT_KEY_BY_MATCH_MODE[matchMode]
    if type(textKey) == "table" then
        textKey = textKey[slotData.Pos]
    end
    self.TxtSkillDesTarget.text = textKey and XUiHelper.GetText(textKey) or skillInfo.Description

    if not self.TargetSkillGrid then
        self.TargetSkillGrid = XUiGridTRAwarenessResonanceSkill.New(self.GridResonanceSkillTarget, self)
        self.TargetSkillGrid:SetEnableClick(false)
    end

    self:RefreshSkillGrid(self.TargetSkillGrid, slotData.TargetState, false, matchMode)
end

-- 刷新自身共鸣技能的图标和描述
---@param skillInfo XEquipResonanceSkillInfo
---@param slotData XUiChooseAwarenessResonanceSlotData
function XUiGridChooseAwarenessResonanceSlot:RefreshOwnResonanceSkill(skillInfo, slotData)
    self.PanelResonanceSkillOwn.gameObject:SetActiveEx(true)
    self.TxtSkillDesOwn.text = skillInfo.Description

    if not self.OwnSkillGrid then
        self.OwnSkillGrid = XUiGridTRAwarenessResonanceSkill.New(self.GridResonanceSkillOwn, self)
        self.OwnSkillGrid:SetEnableClick(false)
    end

    local bindCharacterId = slotData.BindCharacterId or 0
    local isBindOtherCharacter = bindCharacterId ~= 0 and bindCharacterId ~= self.UiRoot.CharacterId
    self:RefreshSkillGrid(self.OwnSkillGrid, nil, isBindOtherCharacter)
    self.OwnSkillGrid.PanelAwakenRoot.gameObject:SetActiveEx(false)
end

-- 刷新共鸣技能 Grid 的通用展示状态
---@param skillGrid XUiGridTRAwarenessResonanceSkill
---@param targetState XEquipAwarenessResonanceTargetState|nil
---@param showBindCharacterMismatch boolean|nil
---@param targetMatchMode XEquipAwarenessResonanceTargetMatchMode|nil
function XUiGridChooseAwarenessResonanceSlot:RefreshSkillGrid(
    skillGrid, targetState, showBindCharacterMismatch, targetMatchMode)
    local slotData = self.Data
    local rowData = self.RowData
    skillGrid:Refresh({
        ResonanceData = slotData,
        Site = rowData.Site,
        Pos = slotData.Pos,
        WearingEquipId = rowData.EquipId,
        TargetState = targetState,
        ShowBindCharacterMismatch = showBindCharacterMismatch,
        TargetMatchMode = targetMatchMode,
    })
    skillGrid:SetActiveImgPos(false)
    skillGrid:SetSelected(false)
end

-- 刷新当前槽位的选中表现。
function XUiGridChooseAwarenessResonanceSlot:RefreshSelected()
    local site = self.RowData.Site
    local pos = self.Data.Pos
    local isTargetSlot = self.IsSelectable
    local isAchieved = isTargetSlot and self.UiRoot:IsTargetSlotAchieved(site, pos)
    local showSelected = isTargetSlot and not isAchieved and self.UiRoot:IsSlotSelected(site, pos)
    self.PanelComplete.gameObject:SetActiveEx(isAchieved)
    self.ImgSelect.gameObject:SetActiveEx(showSelected)
end

-- 处理目标共鸣槽位点击。
function XUiGridChooseAwarenessResonanceSlot:OnGridClick()
    self.UiRoot:OnGridResonanceSkillClick(self.RowData.Site, self.Data.Pos)
end

return XUiGridChooseAwarenessResonanceSlot
