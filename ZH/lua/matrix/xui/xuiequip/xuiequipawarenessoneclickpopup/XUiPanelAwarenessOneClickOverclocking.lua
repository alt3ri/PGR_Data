local CSInstantiate = CS.UnityEngine.Object.Instantiate
local EMPTY_CONTENT_TITLE_COLOR = XUiHelper.Hexcolor2Color("A1A1A1")

---@param countMap table<number, number> 道具数量字典
---@param itemId number|nil 道具 Id
---@param count number|nil 增量数量
local function AddItemCount(countMap, itemId, count)
    if not itemId or not count or count <= 0 then
        return
    end

    countMap[itemId] = (countMap[itemId] or 0) + count
end

---@class XAwarenessOneClickOverclockingConsumeData
---@field ItemId number 道具 Id
---@field Count number 消耗数量
---@field IsExchange boolean 是否通过自动兑换补足

---@class XAwarenessOneClickAwakePreviewResult : XEquipAwakePreviewResult
---@field UnawakenedSkillCount number 当前穿戴且支持超频的意识中，尚未超频的技能槽位总数
---@field HasAvailableAwakeSkill boolean 是否存在满足满级和共鸣条件的可超频技能

-- 意识一键养成超频面板
---@class XUiPanelAwarenessOneClickOverclocking : XUiNode
---@field Parent XUiEquipAwarenessOneClickPopup 所属一键养成弹窗
---@field _Control XEquipControl 装备控制器
---@field BtnChoose XUiComponent.XUiButton 是否勾选超频功能的按钮
---@field GridConsume UiObject 消耗格子模板
---@field UiTxtPreview UnityEngine.UI.Text 超频预览数量文本
---@field PanelNone UiObject 无可超频内容时的空状态节点
---@field TxtNone UnityEngine.UI.Text 无可超频内容时的提示文本
---@field IsChoose boolean 超频功能是否参与一键养成
---@field ConsumeGridPool table<number, table> 消耗格子对象池
---@field PreviewResult XAwarenessOneClickAwakePreviewResult 超频消耗预览结果
---@field IsEmptyState boolean 当前功能是否不可参与一键养成
---@field DefaultTitleColor UnityEngine.Color 标题默认颜色
---@field DefaultPreviewColor UnityEngine.Color 预览文本默认颜色
---@field DefaultArrowColor UnityEngine.Color 箭头默认颜色
local XUiPanelAwarenessOneClickOverclocking = XClass(XUiNode, "XUiPanelAwarenessOneClickOverclocking")

-- 初始化超频面板默认选择状态
function XUiPanelAwarenessOneClickOverclocking:OnStart()
    self.ConsumeGridPool = {}
    self.IsEmptyState = true
    self.IsChoose = self._Control.OneClickAutoSettingControl:GetSetting(XMVCA.XEquip.Enum.OneClickAutoSettingType.AwarenessOverclocking)
    self.DefaultTitleColor = self.UiTxtTitle.color
    self.DefaultPreviewColor = self.UiTxtPreview.color
    self.DefaultArrowColor = self.ImgArrow.color
    self:InitComponents()
end

-- 初始化超频面板组件状态和交互事件
function XUiPanelAwarenessOneClickOverclocking:InitComponents()
    self.GridConsume.gameObject:SetActiveEx(false)

    self.Parent:RegisterClickEvent(self.BtnChoose, function() self:OnBtnChooseClick() end)
end

-- 切换超频功能是否参与一键养成
function XUiPanelAwarenessOneClickOverclocking:OnBtnChooseClick()
    self.IsChoose = self.BtnChoose:GetToggleState()
    self:RefreshTitleState()
    self.Parent:RefreshPreview()
end

-- 按当前弹窗状态刷新超频勾选表现
function XUiPanelAwarenessOneClickOverclocking:RefreshChooseState()
    local buttonState = self.IsChoose and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnChoose:SetButtonState(buttonState)
    self:RefreshTitleState()
end

-- 刷新超频标题背景；仅在已勾选且存在可执行内容时显示选中背景
function XUiPanelAwarenessOneClickOverclocking:RefreshTitleState()
    local isTitleChoose = self.IsChoose and not self.IsEmptyState
    self.BgTitleChoose.gameObject:SetActiveEx(isTitleChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not isTitleChoose)
end

-- 刷新超频预览，并返回本阶段后的资源预算
---@param previewRemainItemCountDic table<number, number> 预览链路当前剩余资源数量
---@return table<number, number> result 超频预览后的剩余资源数量
function XUiPanelAwarenessOneClickOverclocking:RefreshPreview(previewRemainItemCountDic)
    self:RefreshChooseState()
    self.PreviewResult = self:BuildPreview(previewRemainItemCountDic)
    self:RefreshConsumeList()
    self:RefreshNoneState(previewRemainItemCountDic)

    return self:BuildPreviewRemainItemCountDic(previewRemainItemCountDic)
end

--- 根据是否存在可超频技能区分无技能和材料不足两种空状态
---@param previewRemainItemCountDic table<number, number> 预览链路当前剩余资源数量
function XUiPanelAwarenessOneClickOverclocking:RefreshNoneState(previewRemainItemCountDic)
    local isContentEmpty = self.PreviewResult.PreviewAwakeCount <= 0
    local isMaterialNotEnough = isContentEmpty and self.PreviewResult.HasAvailableAwakeSkill
    local isNoAwakeSkill = isContentEmpty and not self.PreviewResult.HasAvailableAwakeSkill
    self.IsEmptyState = not self.IsChoose or isContentEmpty
    self.PanelNone.gameObject:SetActiveEx(isContentEmpty)
    self.UiTxtTitle.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultTitleColor
    self.UiTxtPreview.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultPreviewColor
    self.ImgArrow.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultArrowColor
    self.ImgArrow.gameObject:SetActiveEx(self.IsChoose)
    self.UiTxtPreview.gameObject:SetActiveEx(self.IsChoose)
    if isMaterialNotEnough then
        self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickMaterialNotEnough")
    elseif isNoAwakeSkill then
        self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickAwakeNoSkillTitle")
    else
        self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickAwakeTimesDesc", self.PreviewResult.PreviewAwakeCount)
    end
    self:RefreshTitleState()
    if not isContentEmpty then
        return
    end

    if self.PreviewResult.HasAvailableAwakeSkill then
        local lackItemId = self:GetLackAwakeItemId(previewRemainItemCountDic)
        local lackItemName = XDataCenter.ItemManager.GetItemName(lackItemId)
        self.TxtNone.text = XUiHelper.GetText("AwarenessOneClickAwakeNoMaterialDesc", lackItemName)
    else
        self.TxtNone.text = XUiHelper.GetText("AwarenessOneClickAwakeNoSkillDesc")
    end
end

--- 获取首个可超频槽位缺少的直接消耗道具；超频材料优先于螺母
---@param previewRemainItemCountDic table<number, number> 预览链路当前剩余资源数量
---@return number itemId 缺少的道具 Id
function XUiPanelAwarenessOneClickOverclocking:GetLackAwakeItemId(previewRemainItemCountDic)
    local targetAwakeInfo = self:BuildTargetAwakeInfoList()[1]
    local equipId = targetAwakeInfo.EquipId
    local itemCostList = self._Control:GetAwakeConsumeItemCrystalList(equipId, 1)
    for _, itemCost in ipairs(itemCostList) do
        local remainCount = self:GetPreviewRemainItemCount(previewRemainItemCountDic, itemCost.ItemId)
        if remainCount < itemCost.Count then
            return itemCost.ItemId
        end
    end

    return XDataCenter.ItemManager.ItemId.Coin
end

-- 判断当前穿戴且支持超频的意识中，是否仍存在未超频技能槽位。
---@return boolean 是否存在未超频技能槽位
function XUiPanelAwarenessOneClickOverclocking:HasUnawakenedSkill()
    return self.PreviewResult.UnawakenedSkillCount > 0
end

-- 获取传给进度弹窗的超频执行结果；未勾选或无可执行槽位时不参与后续流程
---@return XAwarenessOneClickAwakePreviewResult|nil
function XUiPanelAwarenessOneClickOverclocking:GetResult()
    if not self.IsChoose or not self.PreviewResult then
        return nil
    end

    if self.PreviewResult.PreviewAwakeCount <= 0 then
        return nil
    end

    return self.PreviewResult
end

-- 获取超频阶段预计消耗的道具数量
---@return table<number, number> costMap 道具 Id -> 预计消耗数量
function XUiPanelAwarenessOneClickOverclocking:GetPreviewCostMap()
    local preview = self:GetResult()
    if not preview then
        return table.empty
    end

    local costMap = {}
    AddItemCount(costMap, XDataCenter.ItemManager.ItemId.Coin, preview.CostMoney)
    for _, costItem in ipairs(preview.CostItemList) do
        AddItemCount(costMap, costItem.Id, costItem.Count)
    end

    for _, exchangeInfo in pairs(preview.AutoExchangeInfo) do
        if exchangeInfo.ExchangeTimes and exchangeInfo.ExchangeTimes > 0 then
            for _, consume in ipairs(exchangeInfo.ConsumeList) do
                AddItemCount(costMap, consume.Id, consume.Count)
            end
        end
    end

    return costMap
end

-- 计算当前一键养成预估能执行的超频槽位和实际消耗
---@param previewRemainItemCountDic table<number, number> 预览链路当前剩余资源数量
---@return XAwarenessOneClickAwakePreviewResult result 超频消耗预览结果
function XUiPanelAwarenessOneClickOverclocking:BuildPreview(previewRemainItemCountDic)
    local targetAwakeInfoList = self:BuildTargetAwakeInfoList()
    local result = self._Control.AwakeControl:CalcAvailableAwakePreviewCost({
        IsAutoExchangeEnabled = self.Parent:IsAutoExchangeOn(),
        TargetAwakeInfoList = targetAwakeInfoList,
        PreviewRemainItemCountDic = previewRemainItemCountDic,
    })
    result.UnawakenedSkillCount = self:BuildUnawakenedSkillCount()
    result.HasAvailableAwakeSkill = not XTool.IsTableEmpty(targetAwakeInfoList)
    return result
end

-- 统计支持超频的穿戴意识中尚未超频的技能槽位，不受等级和共鸣状态影响
---@return number unawakenedSkillCount 未超频技能槽位总数
function XUiPanelAwarenessOneClickOverclocking:BuildUnawakenedSkillCount()
    local unawakenedSkillCount = 0
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.Parent.AwarenessEquipIdBySite[site]
        if equipId and XMVCA.XEquip:CheckEquipStarCanAwake(equipId) then
            for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT do
                if not XMVCA.XEquip:IsEquipPosAwaken(equipId, pos) then
                    unawakenedSkillCount = unawakenedSkillCount + 1
                end
            end
        end
    end
    return unawakenedSkillCount
end

-- 构建超频预览后剩余的资源数量，供后续共鸣预览作为资源预算
---@param previewRemainItemCountDic table<number, number> 超频前的剩余资源数量
---@return table<number, number> result 超频预览后的剩余资源数量
function XUiPanelAwarenessOneClickOverclocking:BuildPreviewRemainItemCountDic(previewRemainItemCountDic)
    local result = XTool.Clone(previewRemainItemCountDic)
    if not self.IsChoose or not self.PreviewResult then
        return result
    end

    for _, exchangeInfo in pairs(self.PreviewResult.AutoExchangeInfo) do
        self:ChangePreviewRemainItemCount(result, exchangeInfo.ItemId, exchangeInfo.RewardCount)
        for _, consume in ipairs(exchangeInfo.ConsumeList) do
            self:ChangePreviewRemainItemCount(result, consume.Id, -consume.Count)
        end
    end

    self:ChangePreviewRemainItemCount(result, XDataCenter.ItemManager.ItemId.Coin, -self.PreviewResult.CostMoney)
    for _, costItem in ipairs(self.PreviewResult.CostItemList) do
        self:ChangePreviewRemainItemCount(result, costItem.Id, -costItem.Count)
    end

    return result
end

-- 调整预览资源预算，正数表示增加，负数表示消耗
---@param previewRemainItemCountDic table<number, number>
---@param itemId number
---@param changeCount number
function XUiPanelAwarenessOneClickOverclocking:ChangePreviewRemainItemCount(previewRemainItemCountDic, itemId, changeCount)
    if not itemId or not changeCount or changeCount == 0 then
        return
    end

    local remainCount = self:GetPreviewRemainItemCount(previewRemainItemCountDic, itemId)
    previewRemainItemCountDic[itemId] = remainCount + changeCount
end

---@param previewRemainItemCountDic table<number, number>
---@param itemId number
---@return number
function XUiPanelAwarenessOneClickOverclocking:GetPreviewRemainItemCount(previewRemainItemCountDic, itemId)
    if previewRemainItemCountDic[itemId] ~= nil then
        return previewRemainItemCountDic[itemId]
    end

    return XDataCenter.ItemManager.GetCount(itemId)
end

-- 构建满足一键强化、共鸣预估条件的超频目标槽位
---@return XEquipAwakePreviewSlotInfo[] targetAwakeInfoList 超频目标槽位列表
function XUiPanelAwarenessOneClickOverclocking:BuildTargetAwakeInfoList()
    local targetAwakeInfoList = {}

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.Parent.AwarenessEquipIdBySite[site]
        if self:IsAwarenessPreviewAwakeEnabled(equipId) then
            local slots = {}
            for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT do
                if self:IsAwakePosPreviewAvailable(equipId, pos) then
                    table.insert(slots, pos)
                end
            end

            if #slots > 0 then
                table.insert(targetAwakeInfoList, { EquipId = equipId, Slots = slots })
            end
        end
    end

    return targetAwakeInfoList
end

-- 判断意识在本轮一键养成预估中是否满足超频的装备级条件
---@param equipId number 意识装备 Id
---@return boolean
function XUiPanelAwarenessOneClickOverclocking:IsAwarenessPreviewAwakeEnabled(equipId)
    if not XMVCA.XEquip:CheckEquipStarCanAwake(equipId) then
        return false
    end

    return self.Parent.UiPanelStrengthen:IsEstimatedFullyStrengthened(equipId)
end

-- 判断意识槽位在本轮一键养成预估中是否可以超频
---@param equipId number 意识装备 Id
---@param pos number 超频槽位
---@return boolean
function XUiPanelAwarenessOneClickOverclocking:IsAwakePosPreviewAvailable(equipId, pos)
    if XMVCA.XEquip:IsEquipPosAwaken(equipId, pos) then
        return false
    end

    return self.Parent.UiPanelResonance:IsPreviewSkillExists(equipId, pos)
end

-- 刷新本轮预估实际消耗的超频材料
function XUiPanelAwarenessOneClickOverclocking:RefreshConsumeList()
    local displayConsumeList = self:BuildDisplayConsumeList()
    for index, consumeData in ipairs(displayConsumeList) do
        local grid = self:GetOrCreateConsumeGrid(index)
        self:RefreshConsumeGrid(grid, consumeData)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #displayConsumeList + 1, #self.ConsumeGridPool do
        self.ConsumeGridPool[index].GameObject:SetActiveEx(false)
    end
end

-- 构建界面展示的消耗列表，先展示超频自身消耗，再展示自动兑换补足材料
---@return XAwarenessOneClickOverclockingConsumeData[] displayConsumeList 消耗展示数据
function XUiPanelAwarenessOneClickOverclocking:BuildDisplayConsumeList()
    local result = {}
    local autoExchangeInfo = self.PreviewResult.AutoExchangeInfo

    -- 超频材料按实际来源拆分：已有材料和自动兑换补足材料分别占用一个格子
    for _, costItem in ipairs(self.PreviewResult.CostItemList) do
        local itemId = costItem.Id
        local exchangeInfo = autoExchangeInfo[itemId]
        local exchangeCount = exchangeInfo and exchangeInfo.LackCount or 0
        local ownCount = costItem.Count - exchangeCount
        if ownCount > 0 then
            table.insert(result, { ItemId = itemId, Count = ownCount, IsExchange = false })
        end
        if exchangeCount > 0 then
            table.insert(result, { ItemId = itemId, Count = exchangeCount, IsExchange = true })
        end
    end

    -- 已有材料优先于自动兑换材料展示，同一来源内按道具 Id 排序
    table.sort(result, function(a, b)
        if a.IsExchange ~= b.IsExchange then
            return not a.IsExchange
        end
        return a.ItemId < b.ItemId
    end)

    --[[ 不显示兑换螺母信息
    -- 列表末尾只追加自动兑换补足的螺母，不展示超频自身消耗的 CostMoney
    local coinItemId = XDataCenter.ItemManager.ItemId.Coin
    local coinExchangeInfo = autoExchangeInfo[coinItemId]
    local coinExchangeCount = coinExchangeInfo and coinExchangeInfo.LackCount or 0
    if coinExchangeCount > 0 then
        table.insert(result, { ItemId = coinItemId, Count = coinExchangeCount, IsExchange = true })
    end
    ]]

    return result
end

-- 从对象池获取消耗格子，不足时根据模板创建
---@param index number 格子下标
---@return table grid 消耗格子
function XUiPanelAwarenessOneClickOverclocking:GetOrCreateConsumeGrid(index)
    local grid = self.ConsumeGridPool[index]
    if not grid then
        local ui = CSInstantiate(self.GridConsume, self.GridConsume.transform.parent)
        grid = XTool.InitUiObjectByUi({}, ui)
        self.ConsumeGridPool[index] = grid
    end

    return grid
end

-- 刷新单个超频材料格子的图标、品质、数量和兑换状态
---@param grid table 消耗格子
---@param consumeData XAwarenessOneClickOverclockingConsumeData 消耗展示数据
function XUiPanelAwarenessOneClickOverclocking:RefreshConsumeGrid(grid, consumeData)
    local itemId = consumeData.ItemId
    grid.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))

    grid.ImgEquipQuality:SetSprite(XArrangeConfigs.GeQualityPath(XDataCenter.ItemManager.GetItemQuality(itemId)))
    grid.TxtCount.text = "x" .. consumeData.Count
    grid.ImgExchange.gameObject:SetActiveEx(consumeData.IsExchange)
end

return XUiPanelAwarenessOneClickOverclocking
