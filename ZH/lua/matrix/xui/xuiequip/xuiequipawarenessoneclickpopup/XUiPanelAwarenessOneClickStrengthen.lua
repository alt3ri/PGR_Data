local CSInstantiate = CS.UnityEngine.Object.Instantiate
local EMPTY_CONTENT_TITLE_COLOR = XUiHelper.Hexcolor2Color("A1A1A1")

---@param countDic table<number, number> 道具数量字典
---@param itemId number|nil 道具 Id
---@param count number|nil 增量数量
local function AddItemCount(countDic, itemId, count)
    if not itemId or not count or count <= 0 then
        return
    end

    countDic[itemId] = (countDic[itemId] or 0) + count
end

---@class XAwarenessOneClickStrengthenConsumeData
---@field TemplateId number
---@field Count number
---@field IsExchange boolean
---@field IsEquip boolean
---@field Star number|nil 仅聚合后的选中强化材料存在

-- 意识一键养成强化面板
---@class XUiPanelAwarenessOneClickStrengthen : XUiNode
---@field Parent XUiEquipAwarenessOneClickPopup 所属一键养成弹窗
---@field _Control XEquipControl 装备控制器
---@field BtnChoose XUiComponent.XUiButton 是否勾选强化功能的按钮
---@field BtnDesc XUiComponent.XUiButton 强化说明按钮
---@field PanelCosume UiObject 强化消耗区域节点
---@field PanelNone UiObject 无消耗内容时的空状态节点
---@field GridConsume UiObject 消耗格子模板
---@field UiTxtPreview UnityEngine.UI.Text 目标强化等级预览文本
---@field ImgBreakIcon UnityEngine.UI.Image 目标突破图标
---@field TxtNone UnityEngine.UI.Text 无可用强化材料时的提示文本
---@field ConsumeGridPool table<number, UiObject> 消耗格子对象池
---@field StrengthenConsumes table 自动选择后的强化消耗材料列表
---@field StrengthenPreview table 强化可达成结果预览
---@field IsChoose boolean 强化功能是否参与一键养成
---@field IsEmptyState boolean 当前功能是否不可参与一键养成
---@field DefaultTitleColor UnityEngine.Color 标题默认颜色
---@field DefaultPreviewColor UnityEngine.Color 预览文本默认颜色
---@field DefaultArrowColor UnityEngine.Color 箭头默认颜色
local XUiPanelAwarenessOneClickStrengthen = XClass(XUiNode, "XUiPanelAwarenessOneClickStrengthen")

-- 初始化强化面板运行期缓存和默认选择状态
function XUiPanelAwarenessOneClickStrengthen:OnStart()
    self.ConsumeGridPool = {}
    self.IsEmptyState = true
    self.IsChoose = self._Control.OneClickAutoSettingControl:GetSetting(XMVCA.XEquip.Enum.OneClickAutoSettingType.AwarenessLevel)
    self.DefaultTitleColor = self.UiTxtTitle.color
    self.DefaultPreviewColor = self.UiTxtPreview.color
    self.DefaultArrowColor = self.ImgArrow.color
    self:InitComponents()
end

-- 初始化强化面板组件状态和交互事件
function XUiPanelAwarenessOneClickStrengthen:InitComponents()
    self.GridConsume.gameObject:SetActiveEx(false)

    self.Parent:RegisterClickEvent(self.BtnChoose, function() self:OnBtnChooseClick() end)
    self.Parent:RegisterClickEvent(self.BtnDesc, function() self:OnBtnDescClick() end)
end

-- 刷新强化预览；全部满级时只展示最高等级和突破，不再刷新消耗区域
function XUiPanelAwarenessOneClickStrengthen:Refresh()
    self.StrengthenPreview = nil

    local isAllMax = self:IsAllAwarenessMaxLevelAndBreakthrough()
    self.PanelCosume.gameObject:SetActiveEx(not isAllMax)

    if isAllMax then
        local maxBreakthrough, maxLevel = self._Control.StrengthenControl:GetEquipMaxBreakthrough(self.Parent.RefTemplateId)
        self:RefreshTargetPreview(maxLevel, maxBreakthrough, 0)
        self:RefreshMaterialState(false)
        return
    end

    self:RefreshStrengthenPreview()
    self:RefreshTargetPreview(
        self.StrengthenPreview.TargetLevel,
        self.StrengthenPreview.TargetBreakthrough,
        self.StrengthenPreview.OperationAwarenessCount
    )
    self:RefreshConsumeList()
end

-- 刷新强化预览，并返回本阶段后的资源预算
---@return table<number, number> previewRemainItemCountDic 强化预览后的剩余资源数量
function XUiPanelAwarenessOneClickStrengthen:RefreshPreview()
    self:RefreshChooseState()
    self:Refresh()

    return self:BuildPreviewRemainItemCountDic()
end

-- 获取传给进度弹窗的强化执行结果；未勾选、无预览或无实际强化操作时不参与后续流程
---@return table|nil
function XUiPanelAwarenessOneClickStrengthen:GetResult()
    local preview = self.StrengthenPreview
    if not self.IsChoose or XTool.IsTableEmpty(preview) then
        return nil
    end

    if preview.OperationAwarenessCount <= 0 then
        return nil
    end

    return preview
end

-- 获取强化阶段预计消耗的道具数量
---@return table<number, number> costMap 道具 Id -> 预计消耗数量
function XUiPanelAwarenessOneClickStrengthen:GetPreviewCostMap()
    local preview = self:GetResult()
    if not preview then
        return table.empty
    end

    local costMap = {}
    AddItemCount(costMap, XDataCenter.ItemManager.ItemId.Coin, preview.CostMoney)
    for _, item in ipairs(preview.BreakList) do
        AddItemCount(costMap, item.Id, item.Count)
    end

    for _, siteResult in pairs(preview.SiteResults) do
        for _, operation in ipairs(siteResult.Operations) do
            if operation.UseItems then
                for itemId, count in pairs(operation.UseItems) do
                    AddItemCount(costMap, itemId, count)
                end
            end
        end
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

-- 判断当前穿戴的全部意识是否都已经满级满突破
function XUiPanelAwarenessOneClickStrengthen:IsAllAwarenessMaxLevelAndBreakthrough()
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.Parent.AwarenessEquipIdBySite[site]
        if not XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId) then
            return false
        end
    end

    return true
end

-- 计算当前穿戴意识在可用资源下能强化到的最高等级
function XUiPanelAwarenessOneClickStrengthen:RefreshStrengthenPreview()
    local refEquipId = self.Parent.RefEquipId
    -- 复用常规强化的自动选择逻辑，预览结果会反写各材料的 SelectCount
    self.StrengthenConsumes = self._Control.StrengthenControl:GetAllConsumeItems(refEquipId, {
        ForceAutoSelect = true,
    })
    self.StrengthenPreview = self._Control.StrengthenControl:SimulateAwarenessMaxAchievablePreview(
        self.Parent.AwarenessEquipIdBySite,
        self.StrengthenConsumes,
        {
            IsAutoExchangeEnabled = self.Parent:IsAutoExchangeOn(),
        }
    )
end

-- 判断指定意识在本轮预估强化后是否完成强化
---@param equipId number
---@return boolean
function XUiPanelAwarenessOneClickStrengthen:IsEstimatedFullyStrengthened(equipId)
    if XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId) then
        return true
    end

    if not self.IsChoose then
        return false
    end

    if XTool.IsTableEmpty(self.StrengthenPreview) then
        return false
    end

    local siteResult = self.StrengthenPreview.SiteResults[equipId]
    if not siteResult then
        return false
    end

    local equip = self._Control:GetEquip(equipId)
    local maxBreakthrough, maxLevel = self._Control.StrengthenControl:GetEquipMaxBreakthrough(equip.TemplateId)
    return siteResult.BT == maxBreakthrough and siteResult.Lv == maxLevel
end

-- 构建强化预览后剩余的资源数量，供其他一键养成模块作为资源预算
---@return table<number, number> previewRemainItemCountDic 道具 Id -> 强化预览后的剩余数量，包含 Coin
function XUiPanelAwarenessOneClickStrengthen:BuildPreviewRemainItemCountDic()
    local previewRemainItemCountDic = {}
    if not self.IsChoose or XTool.IsTableEmpty(self.StrengthenPreview) then
        return previewRemainItemCountDic
    end

    local strengthenPreview = self.StrengthenPreview
    local function ConsumePreviewItem(itemId, count)
        if count <= 0 then
            return
        end

        local remainCount = previewRemainItemCountDic[itemId]
        if remainCount == nil then
            remainCount = XDataCenter.ItemManager.GetCount(itemId)
        end

        previewRemainItemCountDic[itemId] = remainCount - count
    end

    -- 自动兑换获得的目标资源先写入剩余快照，后续消耗扣减会优先基于该快照计算
    for _, exchangeInfo in pairs(strengthenPreview.AutoExchangeInfo) do
        local itemId = exchangeInfo.ItemId
        previewRemainItemCountDic[itemId] = XDataCenter.ItemManager.GetCount(itemId) + exchangeInfo.RewardCount
    end

    -- 强化预览消耗按来源直接扣减，重复道具会在剩余快照上连续扣
    ConsumePreviewItem(XDataCenter.ItemManager.ItemId.Coin, strengthenPreview.CostMoney)
    for _, item in ipairs(strengthenPreview.BreakList) do
        ConsumePreviewItem(item.Id, item.Count)
    end

    for _, siteResult in pairs(strengthenPreview.SiteResults) do
        for _, operation in ipairs(siteResult.Operations) do
            if operation.UseItems then
                for itemId, count in pairs(operation.UseItems) do
                    ConsumePreviewItem(itemId, count)
                end
            end
        end
    end

    for _, exchangeInfo in pairs(strengthenPreview.AutoExchangeInfo) do
        for _, consume in ipairs(exchangeInfo.ConsumeList) do
            ConsumePreviewItem(consume.Id, consume.Count)
        end
    end

    return previewRemainItemCountDic
end

-- 刷新目标等级文案和目标突破图标
---@param level number 目标等级
---@param breakthrough number 目标突破次数
---@param operationAwarenessCount number 实际存在升级操作的意识数量
function XUiPanelAwarenessOneClickStrengthen:RefreshTargetPreview(level, breakthrough, operationAwarenessCount)
    self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickStrengthenTargetDesc", operationAwarenessCount, level)

    local breakThroughIcon = self._Control:GetEquipBreakThroughIcon(breakthrough)
    self.ImgBreakIcon:SetSprite(breakThroughIcon)
end

-- 切换强化功能是否参与一键养成
function XUiPanelAwarenessOneClickStrengthen:OnBtnChooseClick()
    self.IsChoose = self.BtnChoose:GetToggleState()
    self:RefreshTitleState()
    self.Parent:RefreshPreview()
end

-- 按当前弹窗状态刷新强化勾选表现
function XUiPanelAwarenessOneClickStrengthen:RefreshChooseState()
    local buttonState = self.IsChoose and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnChoose:SetButtonState(buttonState)
    self:RefreshTitleState()
end

-- 刷新强化标题背景；仅在已勾选且存在可执行内容时显示选中背景
function XUiPanelAwarenessOneClickStrengthen:RefreshTitleState()
    local isTitleChoose = self.IsChoose and not self.IsEmptyState
    self.BgTitleChoose.gameObject:SetActiveEx(isTitleChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not isTitleChoose)
end

-- 打开强化说明
function XUiPanelAwarenessOneClickStrengthen:OnBtnDescClick()
    self.Parent:ShowStrengthenTips(self.BtnDesc.transform.position)
end

-- 按材料不足状态刷新强化面板的空态、标题和说明控件
---@param isMaterialNotEnough boolean 是否因材料不足显示空态
function XUiPanelAwarenessOneClickStrengthen:RefreshMaterialState(isMaterialNotEnough)
    self.IsEmptyState = not self.IsChoose or isMaterialNotEnough
    self.PanelNone.gameObject:SetActiveEx(isMaterialNotEnough)
    self.ImgArrow.gameObject:SetActiveEx(self.IsChoose)
    self.UiTxtPreview.gameObject:SetActiveEx(self.IsChoose)
    local isBreakIconVisible = self.IsChoose and not isMaterialNotEnough
    self.ImgBreakIcon.gameObject:SetActiveEx(isBreakIconVisible)
    self.UiTxtTitle.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultTitleColor
    self.UiTxtPreview.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultPreviewColor
    self.ImgArrow.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultArrowColor
    if isMaterialNotEnough then
        self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickMaterialNotEnough")
        self:RefreshNoneText()
    end

    self:RefreshTitleState()
end

function XUiPanelAwarenessOneClickStrengthen:RefreshNoneText()
    local nextStrengthenPreview = self._Control.StrengthenControl:GetAwarenessNextStrengthenPreview(
        self.Parent.AwarenessEquipIdBySite, self.Parent:IsAutoExchangeOn())
    assert(nextStrengthenPreview, "XUiPanelAwarenessOneClickStrengthen.RefreshNoneText error: 当前存在未满级意识时必须有下一档预览")

    local textKey = "AwarenessOneClickMaterialNotEnough"
    if nextStrengthenPreview.CanBreakThroughCondition and not nextStrengthenPreview.CanBreakThrough then
        -- 下一档可突破但材料不足时，优先提示突破材料。
        textKey = "AwarenessOneClickStrengthenLackBreakthroughMaterial"
    elseif not nextStrengthenPreview.CanLevelUp then
        -- 突破材料充足后，继续提示升级材料不足。
        textKey = "AwarenessOneClickStrengthenLackLevelUpMaterial"
    elseif not nextStrengthenPreview.IsMoneyEnough then
        -- 升级材料充足后，提示剩余的螺母不足。
        textKey = "AwarenessOneClickStrengthenLackCoin"
    end
    self.TxtNone.text = XUiHelper.GetText(textKey)
end

-- 按预览结果刷新消耗格子，并在无材料时显示空状态
function XUiPanelAwarenessOneClickStrengthen:RefreshConsumeList()
    local displayConsumes = self:BuildDisplayConsumeList()
    local isMaterialNotEnough = #displayConsumes <= 0
    self:RefreshMaterialState(isMaterialNotEnough)

    for index, consumeData in ipairs(displayConsumes) do
        local grid = self:GetOrCreateConsumeGrid(index)
        self:RefreshConsumeGrid(grid, consumeData)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #displayConsumes + 1, #self.ConsumeGridPool do
        self.ConsumeGridPool[index].GameObject:SetActiveEx(false)
    end
end

-- 构建最终用于界面展示的消耗材料列表
function XUiPanelAwarenessOneClickStrengthen:BuildDisplayConsumeList()
    local result = {}
    local preview = self.StrengthenPreview

    -- 展示顺序固定为：突破材料 -> 已选强化材料 -> 自动兑换材料
    self:AppendBreakthroughConsumes(result, preview.BreakList, preview.AutoExchangeInfo)
    self:AppendSelectedStrengthenConsumes(result)
    self:AppendAutoExchangeConsumes(result, preview.AutoExchangeInfo)

    return result
end

-- 追加突破材料，突破材料需要优先展示
function XUiPanelAwarenessOneClickStrengthen:AppendBreakthroughConsumes(result, breakList, autoExchangeInfo)
    for _, item in ipairs(breakList or {}) do
        local count = item.Count or 0
        local exchangeInfo = autoExchangeInfo and autoExchangeInfo[item.Id]
        local exchangeCount = exchangeInfo and exchangeInfo.LackCount or 0
        self:AppendConsumeData(result, item.Id, count - exchangeCount, false, false)
    end
end

-- 追加选中的强化道具和意识狗粮，并按类型、星级排序
---@param result XAwarenessOneClickStrengthenConsumeData[]
function XUiPanelAwarenessOneClickStrengthen:AppendSelectedStrengthenConsumes(result)
    local groupList = {}
    local groupByIsEquip = { [false] = {}, [true] = {} }

    for _, consume in ipairs(self.StrengthenConsumes) do
        local selectedCount = consume.SelectCount
        if selectedCount > 0 then
            local isEquip = consume:IsEquip()
            local star = isEquip and consume:GetStar() or consume:GetQuality()
            local groupByStar = groupByIsEquip[isEquip]
            local group = groupByStar[star]

            if group then
                group.Count = group.Count + selectedCount
            else
                group = {
                    TemplateId = consume.TemplateId,
                    Count = selectedCount,
                    IsExchange = false,
                    IsEquip = isEquip,
                    Star = star,
                }
                groupByStar[star] = group
                table.insert(groupList, group)
            end
        end
    end

    table.sort(groupList, function(a, b)
        if a.IsEquip ~= b.IsEquip then return not a.IsEquip end
        return a.Star > b.Star
    end)

    for _, group in ipairs(groupList) do
        table.insert(result, group)
    end
end

-- 追加自动兑换材料，兑换项需要单独成格并展示兑换标记
function XUiPanelAwarenessOneClickStrengthen:AppendAutoExchangeConsumes(result, autoExchangeInfo)
    local exchangeList = {}
    local awarenessExpItemId = XDataCenter.ItemManager.ItemId.AwarenessStrengthenMaterial4
    local coinItemId = XDataCenter.ItemManager.ItemId.Coin
    local expExchangeInfo
    local coinExchangeInfo

    -- 狗粮和螺母固定放在兑换材料列表末尾，普通兑换材料仍按道具 Id 排序
    for _, exchangeInfo in pairs(autoExchangeInfo or {}) do
        if exchangeInfo.ItemId == awarenessExpItemId then
            expExchangeInfo = exchangeInfo
        elseif exchangeInfo.ItemId == coinItemId then
            coinExchangeInfo = exchangeInfo
        else
            table.insert(exchangeList, exchangeInfo)
        end
    end
    table.sort(exchangeList, function(a, b)
        return (a.ItemId or 0) < (b.ItemId or 0)
    end)

    if expExchangeInfo then
        table.insert(exchangeList, expExchangeInfo)
    end
    --[[ 不显示兑换螺母信息
    if coinExchangeInfo then
        table.insert(exchangeList, coinExchangeInfo)
    end
    ]]

    for _, exchangeInfo in ipairs(exchangeList) do
        local count = exchangeInfo.LackCount or 0
        self:AppendConsumeData(result, exchangeInfo.ItemId, count, true, false)
    end
end

-- 追加单条消耗显示数据，过滤掉数量为 0 的材料
---@param result XAwarenessOneClickStrengthenConsumeData[]
---@param templateId number
---@param count number
---@param isExchange boolean
---@param isEquip boolean
function XUiPanelAwarenessOneClickStrengthen:AppendConsumeData(result, templateId, count, isExchange, isEquip)
    if count <= 0 then
        return
    end

    table.insert(result, {
        TemplateId = templateId,
        Count = count,
        IsExchange = isExchange == true,
        IsEquip = isEquip == true,
    })
end

-- 从对象池获取消耗格子，不足时根据模板创建
function XUiPanelAwarenessOneClickStrengthen:GetOrCreateConsumeGrid(index)
    local grid = self.ConsumeGridPool[index]
    if not grid then
        local ui = CSInstantiate(self.GridConsume, self.GridConsume.transform.parent)
        grid = XTool.InitUiObjectByUi({}, ui)
        self.ConsumeGridPool[index] = grid
    end

    return grid
end

-- 刷新单个消耗格子的图标、数量和兑换状态
---@param grid UiObject
---@param data XAwarenessOneClickStrengthenConsumeData
function XUiPanelAwarenessOneClickStrengthen:RefreshConsumeGrid(grid, data)
    local icon
    local quality
    if data.IsEquip then
        icon = XMVCA.XEquip:GetEquipIconPath(data.TemplateId)
        quality = XMVCA.XEquip:GetEquipQuality(data.TemplateId)
    else
        icon = XDataCenter.ItemManager.GetItemIcon(data.TemplateId)
        quality = XDataCenter.ItemManager.GetItemQuality(data.TemplateId)
    end

    grid.RImgIcon:SetRawImage(icon)
    grid.ImgEquipQuality:SetSprite(XArrangeConfigs.GeQualityPath(quality))
    grid.TxtCount.text = "x" .. data.Count

    -- 兑换材料和直接消耗材料分格展示，兑换格显示兑换角标
    grid.ImgExchange.gameObject:SetActiveEx(data.IsExchange == true)

    local showStarTag = data.IsEquip and data.Star ~= nil
    grid.TagStar.gameObject:SetActiveEx(showStarTag)
    if showStarTag then
        grid.TxtTagStar.text = XUiHelper.GetText("AwarenessOneClickStrengthenAwarenessStarTag", data.Star)
    end
end

return XUiPanelAwarenessOneClickStrengthen
