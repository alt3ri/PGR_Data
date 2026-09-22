local CSInstantiate = CS.UnityEngine.Object.Instantiate

-- 懒创建消耗格子，并按下标复用。
local function GetOrCreateUiCostGrid(gridList, index, template)
    local grid = gridList[index]
    if not grid then
        grid = { Ui = CSInstantiate(template, template.transform.parent) }
        gridList[index] = grid
    end

    return grid
end

---@class XUiPanelAwarenessEnhanceOverclocking : XUiNode
---@field _Control XEquipControl
local XUiPanelAwarenessEnhanceOverclocking = XClass(XUiNode, "XUiPanelAwarenessEnhanceOverclocking")

----------------------------------------
-- 初始化
----------------------------------------
-- 初始化消耗格子缓存，并注册入口按钮事件。
function XUiPanelAwarenessEnhanceOverclocking:OnStart()
    self.AwakeGridCostItems = {}
    self.GridCost.gameObject:SetActiveEx(false)
    self.GridCost:GetObject("TagRandom").gameObject:SetActiveEx(false)

    self.PanelSpecial.gameObject:SetActiveEx(false)
    self.Parent:RegisterClickEvent(self.BtnEnter, function() self:OnBtnEnterClick() end)
end

----------------------------------------
-- 刷新入口
----------------------------------------
-- 刷新超频完成态；未完成时刷新材料预览。
---@return boolean 是否已完成超频
function XUiPanelAwarenessEnhanceOverclocking:Refresh()
    self.AwarenessEquipIdBySite = self.Parent.AwarenessEquipIdBySite

    self.PanelSpecial.gameObject:SetActiveEx(false)
    local isComplete = not self:HasUnawakenedSkill()
    self.TagDone.gameObject:SetActiveEx(isComplete)
    self.BtnEnter.gameObject:SetActiveEx(not isComplete)
    self.PanelCost.gameObject:SetActiveEx(not isComplete)
    if isComplete then
        return true
    end

    self:RefreshCostItems()
    return false
end

----------------------------------------
-- 消耗格子刷新
----------------------------------------
-- 刷新固定的超频材料格子。
function XUiPanelAwarenessEnhanceOverclocking:RefreshCostItems()
    local isAutoExchangeOn = self.Parent.BtnAutoExchange:GetToggleState()
    local previewResult = self._Control.AwakeControl:CalcFullAwakePreviewCost(self.AwarenessEquipIdBySite, {
        IsAutoExchangeEnabled = isAutoExchangeOn,
    })
    local itemCountDic = previewResult and previewResult.CostItemDic or {}
    local autoExchangeInfo = previewResult and previewResult.AutoExchangeInfo or {}
    local itemIds = {
        XDataCenter.ItemManager.ItemId.EquipAwakeCoin1,
        XDataCenter.ItemManager.ItemId.EquipAwakeCoin2,
    }
    for index, itemId in ipairs(itemIds) do
        local grid = self:GetCostGrid(index, itemId)
        local ui = grid.Ui
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(grid.ItemId)
        local haveCount = XDataCenter.ItemManager.GetCount(grid.ItemId) or 0
        local needCount = itemCountDic[itemId] or 0
        local exchangeInfo = autoExchangeInfo[itemId]
        local availableRewardCount = exchangeInfo and exchangeInfo.AvailableRewardCount or 0
        local displayHaveCount = haveCount + availableRewardCount
        local txtHaveCount = ui:GetObject("TxtHaveCount")
        local txtNeedCount = ui:GetObject("TxtNeedCount")

        ui:GetObject("RImgIcon"):SetRawImage(goodsShowParams.Icon)
        XUiHelper.SetQualityIcon(self.Parent, ui:GetObject("ImgQuality"), goodsShowParams.Quality)
        -- 数量拆成可用和需求两个节点，只有可用数量需要按资源状态着色。
        txtHaveCount.text = tostring(displayHaveCount)
        txtHaveCount.color = self.Parent:GetMaterialCostColor(displayHaveCount, needCount).Text
        txtNeedCount.text = string.format("/%s", needCount)
        ui:GetObject("TagRandom").gameObject:SetActiveEx(false)
        ui.gameObject:SetActiveEx(true)
    end
end

----------------------------------------
-- 消耗格子工具
----------------------------------------
-- 获取或创建一个超频材料格子，并只绑定一次道具点击事件。
function XUiPanelAwarenessEnhanceOverclocking:GetCostGrid(index, itemId)
    local grid = GetOrCreateUiCostGrid(self.AwakeGridCostItems, index, self.GridCost)
    if not grid.IsClickEventRegistered then
        self.Parent:RegisterClickEvent(grid.Ui:GetObject("BtnClick"), function()
            self:OnCostClick(grid.ItemId)
        end)
        grid.IsClickEventRegistered = true
    end

    grid.ItemId = itemId
    return grid
end

----------------------------------------
-- 点击事件
----------------------------------------
-- 查找第一个可直接进入超频流程的槽位。
-- 需要和 UiEquipDetailV2P6 超频页签保持一致：满足 CheckEquipCanAwake 且未超频。
function XUiPanelAwarenessEnhanceOverclocking:GetFirstCanAwakeAwarenessEquipIdAndPos()
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.AwarenessEquipIdBySite[equipSite]
        if equipId then
            for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT do
                if XMVCA.XEquip:CheckEquipCanAwake(equipId, pos) and not XMVCA.XEquip:IsEquipPosAwaken(equipId, pos) then
                    return equipId, pos
                end
            end
        end
    end
end

-- 只判断是否存在未完成超频需求：6 星且未超频。
-- 这里刻意不判断共鸣、等级等解锁条件。
---@return boolean 是否存在未超频技能槽位
function XUiPanelAwarenessEnhanceOverclocking:HasUnawakenedSkill()
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.AwarenessEquipIdBySite[equipSite]
        if equipId and XMVCA.XEquip:CheckEquipStarCanAwake(equipId) then
            for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT do
                if not XMVCA.XEquip:IsEquipPosAwaken(equipId, pos) then
                    return true
                end
            end
        end
    end

    return false
end

-- 进入第一个可直接超频的槽位；有需求但无已解锁槽位时提示。
function XUiPanelAwarenessEnhanceOverclocking:OnBtnEnterClick()
    if not self:HasUnawakenedSkill() then
        return
    end

    local equipId, pos = self:GetFirstCanAwakeAwarenessEquipIdAndPos()
    if not equipId then
        XUiManager.TipText("SuperAwareness")
        return
    end

    XLuaUiManager.Open("UiEquipDetailV2P6", equipId, nil, self.Parent.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING, nil, pos)
end

-- 打开超频材料的通用道具详情。
function XUiPanelAwarenessEnhanceOverclocking:OnCostClick(itemId)
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(itemId))
end

return XUiPanelAwarenessEnhanceOverclocking
