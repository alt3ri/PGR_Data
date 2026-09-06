---@class XUiTeamRecommendResonanceSkillPopup : XLuaUi
---@field LeftTargetScrollRect UnityEngine.UI.ScrollRect 左侧意识目标滚动组件
---@field _Control XEquipControl
local XUiTeamRecommendResonanceSkillPopup = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendResonanceSkillPopup")
local RESONANCE_POS = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS

-- PanelResonance“任意攻击”按钮下标，不是目标匹配模式枚举。
local ATTACK_SKILL_OPTION_INDEX = 2

-- 按当前一键养成方案判断候选技能是否显示目标标签。
-- 只有“任意攻击”扩大目标集合，其余方案均按配置目标技能处理。
---@param resonanceControl XEquipResonanceControl
---@param skillInfo table
---@param configuredTargetSkillInfo table|nil
---@param isAttackTargetScheme boolean
---@return boolean
local function IsTargetSkill(resonanceControl, skillInfo, configuredTargetSkillInfo, isAttackTargetScheme)
    if isAttackTargetScheme then
        return resonanceControl:IsAttackResonanceSkill(skillInfo.EquipResonanceType, skillInfo.Id)
    end

    return configuredTargetSkillInfo ~= nil and skillInfo:IsSame(configuredTargetSkillInfo)
end

function XUiTeamRecommendResonanceSkillPopup:OnAwake()
    self.TargetGroupList = {}
    self.TargetSkillGridList = {}
    self.LeftTargetScrollRect = self.PanelResonanceSKill.transform:GetComponentInParent(typeof(CS.UnityEngine.UI.ScrollRect))

    self.PanelResonanceSKill.gameObject:SetActiveEx(false)
    self.GridResonanceSkillTarget.gameObject:SetActiveEx(false)

    self:InitButton()
end

function XUiTeamRecommendResonanceSkillPopup:OnStart(recommendCharData, selectSite, selectPos)
    self.RecommendCharData = recommendCharData
    self.SelectSite = selectSite
    self.SelectPos = selectPos

    self:Refresh()
end

function XUiTeamRecommendResonanceSkillPopup:InitButton()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnCloseMask.CallBack = function() self:Close() end
end

function XUiTeamRecommendResonanceSkillPopup:Refresh()
    if not self.RecommendCharData then
        self:Close()
        return
    end

    self:RefreshSelect()
    self:RefreshLeftTargetGroupList()
    self:RefreshTargetSkillList()
end

function XUiTeamRecommendResonanceSkillPopup:BuildValidAwarenessSiteList()
    local result = {}
    local awarenessTargetSlotList = self.RecommendCharData.AwarenessSlotList or {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local targetSlotData = awarenessTargetSlotList[site]
        if targetSlotData and XTool.IsNumberValid(targetSlotData.EquipTemplateId) then
            table.insert(result, site)
        end
    end
    return result
end

function XUiTeamRecommendResonanceSkillPopup:RefreshSelect()
    local targetSlotData = self:GetAwarenessTargetSlotData(self.SelectSite)
    if targetSlotData then
        if not XTool.IsNumberValid(self.SelectPos) or self.SelectPos > XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT then
            self.SelectPos = 1
        end
        return
    end

    local validAwarenessSiteList = self:BuildValidAwarenessSiteList()
    local firstSite = validAwarenessSiteList[1]
    if firstSite then
        self.SelectSite = firstSite
        self.SelectPos = 1
    end
end

function XUiTeamRecommendResonanceSkillPopup:RefreshLeftTargetGroupList()
    local validAwarenessSiteList = self:BuildValidAwarenessSiteList()
    local selectedGroup
    for index, site in ipairs(validAwarenessSiteList) do
        local targetSlotData = self:GetAwarenessTargetSlotData(site)
        local wearingEquipId = self:GetWearingAwarenessEquipId(targetSlotData)
        local group = self:GetLeftTargetGroup(index)
        group:RefreshLeftGroup(targetSlotData, wearingEquipId, self.RecommendCharData.CharacterId, self.SelectSite, self.SelectPos)
        if site == self.SelectSite then
            selectedGroup = group
        end
    end

    for index = #validAwarenessSiteList + 1, #self.TargetGroupList do
        self.TargetGroupList[index]:Close()
    end

    self:ScrollToSelectedGroup(selectedGroup)
end

-- 将 RectTransform 的本地 Y 坐标转换为 Content 坐标系。
local function GetYInContent(content, rectTransform, localY)
    local worldPosition = rectTransform:TransformPoint(CS.UnityEngine.Vector3(0, localY, 0))
    return content:InverseTransformPoint(worldPosition).y
end

-- 选中意识组不在左侧纵向可视范围时，将其滚动至视口中间。
function XUiTeamRecommendResonanceSkillPopup:ScrollToSelectedGroup(group)
    local scrollRect = self.LeftTargetScrollRect
    if not group or not scrollRect then
        return
    end

    local content = scrollRect.content
    local viewport = scrollRect.viewport
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(content)

    local viewportRect = viewport.rect
    local viewportMinY = GetYInContent(content, viewport, viewportRect.yMin)
    local viewportMaxY = GetYInContent(content, viewport, viewportRect.yMax)

    local groupRect = group.Transform.rect
    local groupCenterY = GetYInContent(content, group.Transform, groupRect.center.y)
    if groupCenterY >= viewportMinY and groupCenterY <= viewportMaxY then
        return
    end

    local viewportHeight = viewportMaxY - viewportMinY
    local scrollableHeight = content.rect.height - viewportHeight
    if scrollableHeight <= 0 then
        return
    end

    local targetViewportMinY = groupCenterY - viewportHeight * 0.5
    local targetPosition = (targetViewportMinY - content.rect.yMin) / scrollableHeight
    scrollRect.velocity = CS.UnityEngine.Vector2.zero
    scrollRect.verticalNormalizedPosition = CS.UnityEngine.Mathf.Clamp01(targetPosition)
end

function XUiTeamRecommendResonanceSkillPopup:GetLeftTargetGroup(index)
    local grid = self.TargetGroupList[index]
    if grid then
        return grid
    end

    local go = XUiHelper.Instantiate(self.PanelResonanceSKill.gameObject, self.PanelResonanceSKill.transform.parent)
    local XUiGridTRResonancePopupTargetGroup = require("XUi/XUiTeamRecommend/Grid/XUiGridTRResonancePopupTargetGroup")
    grid = XUiGridTRResonancePopupTargetGroup.New(go, self)
    self.TargetGroupList[index] = grid

    return grid
end

function XUiTeamRecommendResonanceSkillPopup:RefreshTargetSkillList()
    local targetSlotData = self:GetAwarenessTargetSlotData(self.SelectSite)
    if not targetSlotData then
        self.TxtAwareness.text = ""
        for _, grid in ipairs(self.TargetSkillGridList) do
            grid:Close()
        end
        return
    end

    local titleKey = self.SelectPos == RESONANCE_POS.UP
        and "TeamRecommendAwarenessResonanceTitleUp"
        or "TeamRecommendAwarenessResonanceTitleDown"
    self.TxtAwareness.text = XUiHelper.GetText(titleKey, string.format("%02d", self.SelectSite or 0))

    local characterId = self.RecommendCharData.CharacterId
    local skillInfoList = XMVCA.XEquip:GetResonancePreviewSkillInfoListByTemplateId(targetSlotData.EquipTemplateId, characterId, self.SelectPos) or {}
    local actualSkillInfo = self:GetActualSkillInfo(targetSlotData)
    local isAttackTargetScheme = self:IsAttackTargetSchemeSelected()
    local configuredTargetSkillInfo = self:GetConfiguredTargetSkillInfo(targetSlotData)
    local resonanceControl = self._Control.ResonanceControl

    local originalOrderMap = {}
    local isTargetMap = {}
    for index, skillInfo in ipairs(skillInfoList) do
        originalOrderMap[skillInfo] = index
        isTargetMap[skillInfo] = IsTargetSkill(
            resonanceControl,
            skillInfo,
            configuredTargetSkillInfo,
            isAttackTargetScheme
        )
    end

    -- 目标技能优先，同为目标或非目标时保持候选技能原始顺序。
    table.sort(skillInfoList, function(a, b)
        if isTargetMap[a] ~= isTargetMap[b] then
            return isTargetMap[a]
        end
        return originalOrderMap[a] < originalOrderMap[b]
    end)

    for index, skillInfo in ipairs(skillInfoList) do
        self:GetTargetSkillGrid(index):Refresh({
            SkillInfo = skillInfo,
            IsTarget = isTargetMap[skillInfo],
            ActualSkillInfo = actualSkillInfo,
            Pos = self.SelectPos,
        })
    end

    for index = #skillInfoList + 1, #self.TargetSkillGridList do
        self.TargetSkillGridList[index]:Close()
    end
end

function XUiTeamRecommendResonanceSkillPopup:GetTargetSkillGrid(index)
    local grid = self.TargetSkillGridList[index]
    if grid then
        return grid
    end

    local go = XUiHelper.Instantiate(self.GridResonanceSkillTarget.gameObject, self.GridResonanceSkillTarget.transform.parent)
    local XUiGridTRResonancePopupTargetSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRResonancePopupTargetSkill")
    grid = XUiGridTRResonancePopupTargetSkill.New(go, self)
    self.TargetSkillGridList[index] = grid

    return grid
end

--- 目标意识槽的目标配置（模板/目标共鸣）；无目标返回nil
function XUiTeamRecommendResonanceSkillPopup:GetAwarenessTargetSlotData(site)
    if not XTool.IsNumberValid(site) then
        return nil
    end

    local awarenessTargetSlotList = self.RecommendCharData.AwarenessSlotList or {}
    local targetSlotData = awarenessTargetSlotList[site]
    if targetSlotData and XTool.IsNumberValid(targetSlotData.EquipTemplateId) then
        return targetSlotData
    end
    return nil
end

--- 当前角色在该意识位穿的就是目标模板时返回穿戴装备id（与完成度公式同源）；否则nil
function XUiTeamRecommendResonanceSkillPopup:GetWearingAwarenessEquipId(targetSlotData)
    local wearingEquipId = XMVCA.XEquip:GetCharacterEquipId(self.RecommendCharData.CharacterId, targetSlotData.Site)
    if not XTool.IsNumberValid(wearingEquipId) then
        return nil
    end

    local wearingEquip = XMVCA.XEquip:GetEquip(wearingEquipId)
    if wearingEquip and wearingEquip.TemplateId == targetSlotData.EquipTemplateId then
        return wearingEquipId
    end
end

-- 判断当前上下位是否选择了 PanelResonance 的“任意攻击”方案。
---@return boolean
function XUiTeamRecommendResonanceSkillPopup:IsAttackTargetSchemeSelected()
    local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
    local skillOptionSettingType = self.SelectPos == RESONANCE_POS.UP
        and settingType.AwarenessResonanceSkillTypeUpIndex
        or settingType.AwarenessResonanceSkillTypeDownIndex
    local skillOptionIndex = self._Control.OneClickAutoSettingControl:GetCharacterSetting(
        self.RecommendCharData.CharacterId,
        skillOptionSettingType
    )
    return skillOptionIndex == ATTACK_SKILL_OPTION_INDEX
end

-- 获取推荐方案配置的指定目标技能；无有效目标时返回 nil。
---@param targetSlotData table
---@return table|nil
function XUiTeamRecommendResonanceSkillPopup:GetConfiguredTargetSkillInfo(targetSlotData)
    local resonanceData = targetSlotData.ResonanceList and targetSlotData.ResonanceList[self.SelectPos]
    if not resonanceData then
        return nil
    end

    return XMVCA.XEquip:CreateResonanceSkillInfo(resonanceData.ResonanceType, resonanceData.SkillId)
end

function XUiTeamRecommendResonanceSkillPopup:GetActualSkillInfo(targetSlotData)
    local wearingEquipId = self:GetWearingAwarenessEquipId(targetSlotData)
    if not wearingEquipId then
        return nil
    end

    return XMVCA.XEquip:GetResonanceSkillInfo(wearingEquipId, self.SelectPos)
end

function XUiTeamRecommendResonanceSkillPopup:OnSelectTargetResonance(site, pos)
    self.SelectSite = site
    self.SelectPos = pos

    self:RefreshLeftTargetGroupList()
    self:RefreshTargetSkillList()
end
