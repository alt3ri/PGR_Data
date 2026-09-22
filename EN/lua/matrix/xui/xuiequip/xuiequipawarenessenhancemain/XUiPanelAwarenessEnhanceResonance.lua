local CSInstantiate = CS.UnityEngine.Object.Instantiate
local TARGET_MATCH_MODE = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE

-- 隐藏对象池中本次未使用的消耗格子。
local function HideUnusedCostGrids(gridList, usedCount)
    for i = usedCount + 1, #gridList do
        gridList[i].Ui.gameObject:SetActiveEx(false)
    end
end

-- 获取指定下标的消耗格子，不存在时按模板创建。
local function GetOrCreateUiCostGrid(gridList, index, template)
    local grid = gridList[index]
    if not grid then
        grid = { Ui = CSInstantiate(template, template.transform.parent) }
        gridList[index] = grid
    end

    return grid
end

---@class XUiPanelAwarenessEnhanceResonance : XUiNode
---@field _Control XEquipControl
local XUiPanelAwarenessEnhanceResonance = XClass(XUiNode, "XUiPanelAwarenessEnhanceResonance")

----------------------------------------
-- 初始化
----------------------------------------
-- 初始化格子对象池、模板状态和按钮事件。
function XUiPanelAwarenessEnhanceResonance:OnStart()
    self.ResonanceGridCostItems = {}
    self.ResonanceAwarenessCostItems = {}
    self.GridCost.gameObject:SetActiveEx(false)
    self.GridCost:GetObject("TagRandom").gameObject:SetActiveEx(false)
    self.GridCost:GetObject("TxtNeedCount").gameObject:SetActiveEx(false)

    self.GridCostSpecial:GetObject("TagTargeted").gameObject:SetActiveEx(true)
    self.GridCostSpecial:GetObject("TxtNeedCount").gameObject:SetActiveEx(false)
    self.GridCostSpecial:GetObject("TxtHaveCount").gameObject:SetActiveEx(true)

    self.Parent:RegisterClickEvent(self.BtnEnter, function() self:OnBtnEnterClick() end)
    self.Parent:RegisterClickEvent(self.GridCostSpecial:GetObject("BtnClick"), function()
        self:OnTargetedCostClick()
    end)
end

----------------------------------------
-- 刷新入口
----------------------------------------
-- 刷新共鸣完成态；未完成时刷新共鸣消耗展示。
---@return boolean 是否已完成目标共鸣
function XUiPanelAwarenessEnhanceResonance:Refresh()
    self.AwarenessEquipIdBySite = self.Parent.AwarenessEquipIdBySite

    local unachievedCount = self:GetUnachievedTargetResonanceSkillCount()
    local isComplete = unachievedCount == 0
    self.TagDone.gameObject:SetActiveEx(isComplete)
    self.BtnEnter.gameObject:SetActiveEx(not isComplete)
    self.PanelCost.gameObject:SetActiveEx(not isComplete)
    if isComplete then
        return true
    end

    local costInfos, targetedCostInfo =
        self._Control.ResonanceControl:BuildAwarenessResonanceCostInfoList(self.AwarenessEquipIdBySite)
    self:RefreshTargetedCostItem(targetedCostInfo ~= nil, unachievedCount)
    self:RefreshCostItems(costInfos)
    return false
end

----------------------------------------
-- 消耗格子刷新
----------------------------------------
-- 刷新所有消耗格子的显示顺序、内容和可见状态。
function XUiPanelAwarenessEnhanceResonance:RefreshCostItems(costInfos)
    local baseSiblingIndex = self.GridCost.transform:GetSiblingIndex()
    local costType = XEnumConst.EQUIP.RESONANCE_COST_TYPE
    local usedCountByType = {
        [costType.TOKEN] = 0,
        [costType.AWARENESS] = 0,
    }
    for index, info in ipairs(costInfos) do
        local poolIndex = usedCountByType[info.Type] + 1
        usedCountByType[info.Type] = poolIndex
        local grid = self:GetCostGrid(info, poolIndex)
        self:RefreshCostGrid(grid.Ui, info, poolIndex)
        grid.Ui.transform:SetSiblingIndex(baseSiblingIndex + index)
        grid.Ui.gameObject:SetActiveEx(true)
    end

    HideUnusedCostGrids(self.ResonanceGridCostItems, usedCountByType[costType.TOKEN])
    HideUnusedCostGrids(self.ResonanceAwarenessCostItems, usedCountByType[costType.AWARENESS])
end

-- 根据消耗类型获取对应对象池中的格子。
function XUiPanelAwarenessEnhanceResonance:GetCostGrid(costInfo, poolIndex)
    if costInfo.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.TOKEN then
        local grid = GetOrCreateUiCostGrid(self.ResonanceGridCostItems, poolIndex, self.GridCost)
        if not grid.IsClickEventRegistered then
            self.Parent:RegisterClickEvent(grid.Ui:GetObject("BtnClick"), function()
                self:OnTokenCostClick(grid.ItemId)
            end)
            grid.IsClickEventRegistered = true
        end

        grid.ItemId = costInfo.ItemId
        return grid
    end

    return GetOrCreateUiCostGrid(self.ResonanceAwarenessCostItems, poolIndex, self.GridCost)
end

-- 按消耗类型刷新单个消耗格子。
function XUiPanelAwarenessEnhanceResonance:RefreshCostGrid(uiObj, costInfo, poolIndex)
    if costInfo.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.TOKEN then
        self:RefreshCostItemOwnedCount(uiObj, costInfo.ItemId)
        uiObj:GetObject("TagRandom").gameObject:SetActiveEx(poolIndex == 1)
        return
    end

    self:RefreshAwarenessCostItem(uiObj, costInfo.Star, costInfo.Count, costInfo.IconTemplateId)
end

-- 刷新定向共鸣消耗入口，仅存在6星意识时显示。
---@param hasTargetedCost boolean 是否存在定向共鸣消耗入口
---@param unachievedCount number 未达成的目标共鸣槽数量
function XUiPanelAwarenessEnhanceResonance:RefreshTargetedCostItem(hasTargetedCost, unachievedCount)
    self.PanelSpecial.gameObject:SetActiveEx(hasTargetedCost)
    if not hasTargetedCost then
        return
    end

    local itemId = XDataCenter.ItemManager.ItemId.QuickReasonanceCoin
    self:RefreshCostItemOwnedCount(self.GridCostSpecial, itemId)
    local txtNeedCount = self.GridCostSpecial:GetObject("TxtNeedCount")
    txtNeedCount.gameObject:SetActiveEx(true)
    txtNeedCount.text = "/" .. tostring(unachievedCount)
end

-- 统计当前已穿戴且可共鸣的意识中，尚未达到目标技能的共鸣槽数量。
function XUiPanelAwarenessEnhanceResonance:GetUnachievedTargetResonanceSkillCount()
    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)
    if XTool.IsTableEmpty(awarenessSlotList) then
        return 0
    end

    local count = 0
    local resonanceControl = self._Control.ResonanceControl
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.AwarenessEquipIdBySite[equipSite]
        local equip = equipId and self._Control:GetEquip(equipId)
        local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
        if isCanResonance then
            local targetSlotData = awarenessSlotList[equipSite]
            if targetSlotData and targetSlotData.ResonanceList then
                for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                    local targetResonanceData = targetSlotData.ResonanceList[pos]
                    local target = targetResonanceData and {
                        Pos = pos,
                        MatchMode = TARGET_MATCH_MODE.TARGET,
                        TargetType = targetResonanceData.ResonanceType,
                        TargetSkillId = targetResonanceData.SkillId,
                    }
                    local isUnachieved = target and resonanceControl:IsAwarenessResonanceTargetUnachieved(equip, target, characterId)
                    if isUnachieved then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

-- 查找第一个未达到目标的意识及共鸣槽位。
function XUiPanelAwarenessEnhanceResonance:GetFirstUnachievedTargetAwarenessEquipIdAndPos()
    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)
    if XTool.IsTableEmpty(awarenessSlotList) then
        return
    end

    local awarenessEquipIdBySite = self.AwarenessEquipIdBySite
    local resonanceControl = self._Control.ResonanceControl
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = awarenessEquipIdBySite[equipSite]
        local equip = equipId and self._Control:GetEquip(equipId)
        local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
        if isCanResonance then
            local targetSlotData = awarenessSlotList[equipSite]
            if targetSlotData and targetSlotData.ResonanceList then
                for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                    local targetResonanceData = targetSlotData.ResonanceList[pos]
                    local target = targetResonanceData and {
                        Pos = pos,
                        MatchMode = TARGET_MATCH_MODE.TARGET,
                        TargetType = targetResonanceData.ResonanceType,
                        TargetSkillId = targetResonanceData.SkillId,
                    }
                    local isUnachieved = target and resonanceControl:IsAwarenessResonanceTargetUnachieved(equip, target, characterId)
                    if isUnachieved then
                        return equipId, pos
                    end
                end
            end
        end
    end
end

-- 刷新意识材料消耗格子的图标、品质和数量。
function XUiPanelAwarenessEnhanceResonance:RefreshAwarenessCostItem(uiObj, star, count, iconTemplateId)
    uiObj:GetObject("RImgIcon"):SetRawImage(XMVCA.XEquip:GetEquipIconPath(iconTemplateId))
    XUiHelper.SetQualityIcon(self.Parent, uiObj:GetObject("ImgQuality"), star)
    uiObj:GetObject("TxtNeedCount").gameObject:SetActiveEx(false)
    uiObj:GetObject("TagRandom").gameObject:SetActiveEx(false)
    local txtHaveCount = uiObj:GetObject("TxtHaveCount")
    txtHaveCount.gameObject:SetActiveEx(true)
    txtHaveCount.text = count
    txtHaveCount.color = self.Parent:GetMaterialCostColor(count).Text
end

-- 刷新道具消耗格子的图标、品质和当前拥有数量。
function XUiPanelAwarenessEnhanceResonance:RefreshCostItemOwnedCount(uiObj, itemId)
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
    uiObj:GetObject("RImgIcon"):SetRawImage(goodsShowParams.Icon)
    XUiHelper.SetQualityIcon(self.Parent, uiObj:GetObject("ImgQuality"), goodsShowParams.Quality)
    uiObj:GetObject("TxtNeedCount").gameObject:SetActiveEx(false)
    local txtHaveCount = uiObj:GetObject("TxtHaveCount")
    txtHaveCount.gameObject:SetActiveEx(true)
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    txtHaveCount.text = itemCount
    txtHaveCount.color = self.Parent:GetMaterialCostColor(itemCount).Text
end

----------------------------------------
-- 点击事件
----------------------------------------
function XUiPanelAwarenessEnhanceResonance:OnBtnEnterClick()
    local equipId, pos = self:GetFirstUnachievedTargetAwarenessEquipIdAndPos()
    if not equipId then
        return
    end

    XLuaUiManager.Open("UiEquipDetailV2P6", equipId, nil, self.Parent.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
end

-- 打开随机共鸣代币道具详情。
function XUiPanelAwarenessEnhanceResonance:OnTokenCostClick(itemId)
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(itemId))
end

-- 打开定向共鸣代币道具详情。
function XUiPanelAwarenessEnhanceResonance:OnTargetedCostClick()
    local item = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.QuickReasonanceCoin)
    XLuaUiManager.Open("UiTip", item)
end

return XUiPanelAwarenessEnhanceResonance
