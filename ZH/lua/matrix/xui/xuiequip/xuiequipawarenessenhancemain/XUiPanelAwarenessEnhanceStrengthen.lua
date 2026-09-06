local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

---@class XUiPanelAwarenessEnhanceStrengthen : XUiNode
---@field _Control XEquipControl
local XUiPanelAwarenessEnhanceStrengthen = XClass(XUiNode, "XUiPanelAwarenessEnhanceStrengthen")

----------------------------------------
-- 初始化
----------------------------------------
-- 初始化强化入口的消耗格子、模板状态和按钮事件。
function XUiPanelAwarenessEnhanceStrengthen:OnStart()
    self.GridCostItems = {}
    self.GridCost.gameObject:SetActiveEx(false)
    self.GridCost:GetObject("TagRandom").gameObject:SetActiveEx(false)

    self.TxtExpCostNeedCount = self.GridCostSpecial:GetObject("TxtNeedCount")
    self.GridCostSpecial:GetObject("TagTargeted").gameObject:SetActiveEx(false)
    self.GridCostSpecial:GetObject("TxtHaveCount").gameObject:SetActiveEx(false)

    self.Parent:RegisterClickEvent(self.BtnEnter, function() self:OnBtnEnterClick() end)
    self.Parent:RegisterClickEvent(self.GridCostSpecial:GetObject("BtnClick"), function()
        self:OnGridCostSpecialBtnClick()
    end)
end

----------------------------------------
-- 刷新入口
----------------------------------------
-- 刷新强化完成态；未完成时刷新满级消耗预览。
---@return boolean 是否已完成强化
function XUiPanelAwarenessEnhanceStrengthen:Refresh()
    local isComplete = self:GetFirstNotMaxLevelAwarenessEquipId() == nil
    self.TagDone.gameObject:SetActiveEx(isComplete)
    self.BtnEnter.gameObject:SetActiveEx(not isComplete)
    self.PanelCost.gameObject:SetActiveEx(not isComplete)
    if isComplete then
        return true
    end

    local awarenessEquipIdBySite = self.Parent.AwarenessEquipIdBySite
    local isAutoExchangeOn = self.Parent.BtnAutoExchange:GetToggleState()
    local totalExp, previewResult = self._Control.StrengthenControl:CalcFullAwarenessStrengthenPreviewCost(awarenessEquipIdBySite, {
        IsAutoExchangeEnabled = isAutoExchangeOn,
    })
    local breakthroughCostList = previewResult and previewResult.BreakList or {}
    local usedExp = previewResult and previewResult.UsedExp or 0
    local autoExchangeInfo = previewResult and previewResult.AutoExchangeInfo or {}

    self:RefreshGridCostSpecial(totalExp, usedExp)
    self:RefreshCostGrids(breakthroughCostList, autoExchangeInfo)
    return false
end

----------------------------------------
-- 消耗格子刷新
----------------------------------------
-- 获取或创建一个突破材料格子。
function XUiPanelAwarenessEnhanceStrengthen:GetCostGrid(index)
    local grid = self.GridCostItems[index]
    if not grid then
        local ui = CSInstantiate(self.GridCost, self.GridCost.transform.parent)
        grid = XUiGridCostItem.New(self.Parent, ui)
        self.GridCostItems[index] = grid
    end

    return grid
end

-- 刷新突破材料格子，并根据自动兑换预览补足展示数量。
---@param breakthroughCostList table<number, table>
---@param autoExchangeInfo table<number, XEquipStrengthenAutoExchangeInfo>
function XUiPanelAwarenessEnhanceStrengthen:RefreshCostGrids(breakthroughCostList, autoExchangeInfo)
    for index, item in ipairs(breakthroughCostList) do
        local grid = self:GetCostGrid(index)
        local haveCount = XDataCenter.ItemManager.GetCount(item.Id) or 0
        local exchangeInfo = autoExchangeInfo[item.Id]
        local availableRewardCount = exchangeInfo and exchangeInfo.AvailableRewardCount or 0
        local displayHaveCount = haveCount + availableRewardCount

        grid.GameObject:SetActiveEx(true)
        grid:Refresh(item.Id, item.Count)
        grid.TxtHaveCount.text = tostring(displayHaveCount)
        grid.TxtHaveCount.color = self.Parent:GetMaterialCostColor(displayHaveCount, item.Count).Text
    end

    for i = #breakthroughCostList + 1, #self.GridCostItems do
        self.GridCostItems[i].GameObject:SetActiveEx(false)
    end
end

----------------------------------------
-- 经验消耗刷新
----------------------------------------
-- 刷新经验材料汇总文案；经验不足时仅高亮数量部分。
---@param totalExp number
---@param usedExp number
function XUiPanelAwarenessEnhanceStrengthen:RefreshGridCostSpecial(totalExp, usedExp)
    --local colorHex = self.Parent:GetMaterialCostColor(usedExp, totalExp).Hex
    local title = CS.XTextManager.GetText("CharacterUpgradeSkillConsumeTitle")
    local expStr = tostring(totalExp or 0)
    --expStr = string.format("<color=#%s>%s</color>", colorHex, expStr)

    self.TxtExpCostNeedCount.text = title .. expStr
end

----------------------------------------
-- 点击事件
----------------------------------------
-- 查找第一个尚未满级满突破的穿戴意识，用于进入强化页签。
function XUiPanelAwarenessEnhanceStrengthen:GetFirstNotMaxLevelAwarenessEquipId()
    local awarenessEquipIdBySite = self.Parent.AwarenessEquipIdBySite
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = awarenessEquipIdBySite[equipSite]
        if equipId and not XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId) then
            return equipId
        end
    end
end

-- 进入第一个仍需强化的意识详情强化页签。
function XUiPanelAwarenessEnhanceStrengthen:OnBtnEnterClick()
    local equipId = self:GetFirstNotMaxLevelAwarenessEquipId()
    if not equipId then
        return
    end

    XLuaUiManager.Open("UiEquipDetailV2P6", equipId, nil, self.Parent.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN)
end

-- 打开经验材料的获取跳转。
function XUiPanelAwarenessEnhanceStrengthen:OnGridCostSpecialBtnClick()
    local itemId = XDataCenter.ItemManager.ItemId.AwarenessStrengthenMaterial4
    XLuaUiManager.Open("UiSkip", itemId)
end

return XUiPanelAwarenessEnhanceStrengthen
