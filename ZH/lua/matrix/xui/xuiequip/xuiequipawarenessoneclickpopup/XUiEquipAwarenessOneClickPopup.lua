local XUiPanelAwarenessOneClickStrengthen = require("XUi/XUiEquip/XUiEquipAwarenessOneClickPopup/XUiPanelAwarenessOneClickStrengthen")
local XUiPanelAwarenessOneClickResonance = require("XUi/XUiEquip/XUiEquipAwarenessOneClickPopup/XUiPanelAwarenessOneClickResonance")
local XUiPanelAwarenessOneClickOverclocking = require("XUi/XUiEquip/XUiEquipAwarenessOneClickPopup/XUiPanelAwarenessOneClickOverclocking")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

local COST_ITEM_ID_LIST = {
    XDataCenter.ItemManager.ItemId.Coin,
    XDataCenter.ItemManager.ItemId.RepeatChallengeCoin,
    XGuildConfig.GuildCoin,
}

local KILO = 1000

---将代币数量缩写为 K，向下保留最多一位小数
---@param cost number
---@return string
local function FormatCost(cost)
    if cost < KILO then
        return tostring(cost)
    end

    local costInK = math.floor(cost / KILO * 10) / 10
    local costText = string.format("%.1f", costInK):gsub("%.0$", "")
    return costText .. "K"
end

---@param targetMap table<number, number>
---@param sourceMap table<number, number>
local function MergeCostMap(targetMap, sourceMap)
    for itemId, count in pairs(sourceMap) do
        targetMap[itemId] = (targetMap[itemId] or 0) + count
    end
end

-- 将单个养成阶段的自动兑换信息合并到确认弹窗数据中
---@param exchangeInfoMap table<number, table>
---@param result table|nil
local function MergeAutoExchangeInfo(exchangeInfoMap, result)
    for _, exchangeInfo in pairs(result and result.AutoExchangeInfo or table.empty) do
        if exchangeInfo.ExchangeTimes and exchangeInfo.ExchangeTimes > 0 then
            local itemId = exchangeInfo.ItemId
            local mergedInfo = exchangeInfoMap[itemId]
            if not mergedInfo then
                mergedInfo = {
                    ItemId = itemId,
                    RewardCount = 0,
                    ConsumeCountMap = {},
                }
                exchangeInfoMap[itemId] = mergedInfo
            end

            mergedInfo.RewardCount = mergedInfo.RewardCount + exchangeInfo.RewardCount
            for _, consume in ipairs(exchangeInfo.ConsumeList) do
                mergedInfo.ConsumeCountMap[consume.Id] = (mergedInfo.ConsumeCountMap[consume.Id] or 0) + consume.Count
            end
        end
    end
end

-- 汇总强化和超频阶段实际需要执行的自动兑换明细
---@param strengthenResult table|nil
---@param overclockingResult XAwarenessOneClickAwakePreviewResult|nil
---@return table[] exchangeList
local function BuildAutoExchangeList(strengthenResult, overclockingResult)
    local exchangeInfoMap = {}
    MergeAutoExchangeInfo(exchangeInfoMap, strengthenResult)
    MergeAutoExchangeInfo(exchangeInfoMap, overclockingResult)

    local exchangeList = {}
    for _, exchangeInfo in pairs(exchangeInfoMap) do
        local consumeList = {}
        for consumeId, consumeCount in pairs(exchangeInfo.ConsumeCountMap) do
            table.insert(consumeList, { Id = consumeId, Count = consumeCount })
        end
        table.sort(consumeList, function(a, b) return a.Id < b.Id end)
        table.insert(exchangeList, {
            ItemId = exchangeInfo.ItemId,
            RewardCount = exchangeInfo.RewardCount,
            ConsumeList = consumeList,
        })
    end
    table.sort(exchangeList, function(a, b) return a.ItemId < b.ItemId end)
    return exchangeList
end

---@param targetList XAwarenessOneClickResonanceRecordTargetData[]
---@return number[]
local function BuildSelectedResonanceSlots(targetList)
    local selectedSlots = {}
    local resonanceSlotCount = XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT
    local totalSlotCount = XEnumConst.EQUIP.WEAR_AWARENESS_COUNT * resonanceSlotCount
    for index = 1, totalSlotCount do
        selectedSlots[index] = 0
    end

    for _, targetData in ipairs(targetList) do
        local index = (targetData.Site - 1) * resonanceSlotCount + targetData.Pos
        selectedSlots[index] = 1
    end

    return selectedSlots
end

---@class XAwarenessOneClickUpgradeRecordTarget
---@field IsSelected boolean 是否实际进入升级与突破执行流程
---@field TargetLevel number|nil 目标等级
---@field TargetBreakthrough number|nil 目标突破等级

---@class XAwarenessOneClickResonanceRecordTargetData
---@field Site number 意识穿戴位置
---@field Pos number 共鸣槽位
---@field Target XEquipAwarenessResonanceTarget 共鸣目标

---@class XAwarenessOneClickResonanceRecordTarget
---@field IsSelected boolean 是否实际进入共鸣执行流程
---@field UpperTargetIndex number|nil 上位共鸣目标选项下标
---@field LowerTargetIndex number|nil 下位共鸣目标选项下标
---@field TimesIndex number|nil 单个技能共鸣次数选项下标
---@field SelectedSlots number[] 按意识位置及上、下位顺序排列的十二个共鸣槽选中状态
---@field TargetList XAwarenessOneClickResonanceRecordTargetData[] 已选且尚未达成的共鸣目标快照

---@class XAwarenessOneClickOverclockRecordTarget
---@field IsSelected boolean 是否实际进入超频执行流程

---@class XAwarenessOneClickRecordTarget
---@field Upgrade XAwarenessOneClickUpgradeRecordTarget
---@field Resonance XAwarenessOneClickResonanceRecordTarget
---@field Overclock XAwarenessOneClickOverclockRecordTarget

---@class XAwarenessOneClickProgressArgs
---@field CharacterId number 当前操作的角色 Id
---@field EquipIdBySite table<number, number> 确认执行时六个穿戴位对应的意识 Id
---@field StrengthenResult table|nil 强化执行结果
---@field ResonanceResult XUiPanelAwarenessOneClickResonanceResult|nil 共鸣执行结果
---@field OverclockingResult XAwarenessOneClickAwakePreviewResult|nil 超频执行结果
---@field RecordTarget XAwarenessOneClickRecordTarget 埋点目标快照

-- 意识一键养成弹窗
---@class XUiEquipAwarenessOneClickPopup : XLuaUi
---@field _Control XEquipControl 装备控制器
---@field BtnClose XUiComponent.XUiButton 关闭按钮
---@field BtnBgClose XUiComponent.XUiButton 背景关闭按钮
---@field BtnAutoSetting XUiComponent.XUiButton 自动设置按钮
---@field BtnAutoExchange XUiComponent.XUiButton 自动兑换开关按钮
---@field BtnChooseCostDesc XUiComponent.XUiButton 消耗说明按钮
---@field BtnTipsClose XUiComponent.XUiButton 说明弹窗关闭按钮
---@field BtnConfirm XUiComponent.XUiButton 确认执行按钮
---@field PanelAsset UnityEngine.RectTransform 资源栏挂点
---@field PanelStrengthen UiObject 强化面板节点
---@field PanelResonance UiObject 共鸣面板节点
---@field PanelOverclocking UiObject 超频面板节点
---@field PanelChooseCostTips UiObject 消耗说明弹窗节点
---@field PanelChooseTimeTips UiObject 共鸣次数说明弹窗节点
---@field PanelStrengthenTips UiObject 强化说明弹窗节点
---@field UiTxtStrengthenTips UnityEngine.UI.Text 强化说明文本
---@field UiPanelStrengthen XUiPanelAwarenessOneClickStrengthen 强化功能面板实例
---@field UiPanelResonance XUiPanelAwarenessOneClickResonance 共鸣功能面板实例
---@field UiPanelOverclocking XUiPanelAwarenessOneClickOverclocking 超频功能面板实例
---@field CharacterId number 当前操作的角色 Id
---@field AwarenessEquipIdBySite table<number, number> 当前角色穿戴的意识 Id 字典，key 为穿戴位
---@field RefEquipId number 用于计算强化预览的参考意识 Id
---@field RefTemplateId number 参考意识模板 Id
---@field GridCost UiObject 消耗格子模板
---@field CostGridPool table<number, table> 消耗格子对象池
local XUiEquipAwarenessOneClickPopup = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessOneClickPopup")

-- 初始化弹窗组件
function XUiEquipAwarenessOneClickPopup:OnAwake()
    self.GridCost.gameObject:SetActiveEx(false)
    self.CostGridPool = {}
    self:InitComponents()
end

-- 绑定按钮事件，并创建强化、共鸣、超频三个功能面板
function XUiEquipAwarenessOneClickPopup:InitComponents()
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnBgClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnAutoSetting:AddEventListener(function() self:OnBtnAutoSettingClick() end)
    self.BtnAutoExchange:AddEventListener(function() self:OnBtnAutoExchangeClick() end)
    self.BtnChooseCostDesc:AddEventListener(function() self:OnBtnChooseCostDescClick() end)
    self.BtnTipsClose:AddEventListener(function() self:OnBtnTipsCloseClick() end)
    self.BtnConfirm:AddEventListener(function() self:OnBtnConfirmClick() end)
    self:CloseTips()

    self.PanelAsset = XUiHelper.XUiPanelAsset(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.Coin, XDataCenter.ItemManager.ItemId.RepeatChallengeCoin, XGuildConfig.GuildCoin)

    self.UiPanelStrengthen = XUiPanelAwarenessOneClickStrengthen.New(self.PanelStrengthen, self)
    self.UiPanelResonance = XUiPanelAwarenessOneClickResonance.New(self.PanelResonance, self)
    self.UiPanelOverclocking = XUiPanelAwarenessOneClickOverclocking.New(self.PanelOverclocking, self)
    self.UiPanelStrengthen:Open()
    self.UiPanelResonance:Open()
    self.UiPanelOverclocking:Open()
end

-- 记录当前角色 Id，并刷新弹窗内容
function XUiEquipAwarenessOneClickPopup:OnStart(characterId)
    self.CharacterId = characterId
    self:Refresh()
end

-- 界面启用生命周期预留
function XUiEquipAwarenessOneClickPopup:OnEnable()
end

-- 界面禁用生命周期预留
function XUiEquipAwarenessOneClickPopup:OnDisable()
end

-- 界面销毁生命周期预留
function XUiEquipAwarenessOneClickPopup:OnDestroy()
end

-- 刷新意识上下文、自动兑换按钮状态和各功能面板预览
function XUiEquipAwarenessOneClickPopup:Refresh()
    self:RefreshAwarenessContext()
    self:RefreshAutoExchangeFromCache()
    self:RefreshPreview()
end

-- 刷新一键养成预览链路：强化 -> 首次共鸣 -> 超频 -> 剩余共鸣
function XUiEquipAwarenessOneClickPopup:RefreshPreview()
    local remainAfterStrengthen = self.UiPanelStrengthen:RefreshPreview()
    local remainAfterFirstResonance = self.UiPanelResonance:RefreshPreviewBeforeOverclocking(remainAfterStrengthen)
    local remainAfterOverclocking = self.UiPanelOverclocking:RefreshPreview(remainAfterFirstResonance)
    self.UiPanelResonance:RefreshPreviewAfterOverclocking(remainAfterOverclocking)

    self:RefreshCost()
    self:RefreshConfirmButton()
    self:RefreshPanelVisibility()
end

-- 在完整预览、消耗和确认按钮刷新后，按当前养成状态统一更新功能面板显隐。
function XUiEquipAwarenessOneClickPopup:RefreshPanelVisibility()
    local isStrengthenVisible = not self.UiPanelStrengthen:IsAllAwarenessMaxLevelAndBreakthrough()
    local isResonanceVisible = self.UiPanelResonance:HasUnachievedTargetResonanceSkill()
    local isOverclockingVisible = self.UiPanelOverclocking:HasUnawakenedSkill()
    self.UiPanelStrengthen:SetVisible(isStrengthenVisible)
    self.UiPanelResonance:SetVisible(isResonanceVisible)
    self.UiPanelOverclocking:SetVisible(isOverclockingVisible)
end

-- 根据当前有效执行结果刷新确认按钮状态
function XUiEquipAwarenessOneClickPopup:RefreshConfirmButton()
    local strengthenResult = self.UiPanelStrengthen:GetResult()
    local resonanceResult = self.UiPanelResonance:GetResult()
    local overclockingResult = self.UiPanelOverclocking:GetResult()
    local hasResult = strengthenResult or resonanceResult or overclockingResult
    local hasMissingResonanceSetting = self.UiPanelResonance:GetMissingSettingTipKey() ~= nil
    self.BtnConfirm:SetDisable(not hasResult or hasMissingResonanceSetting)
end

-- 获取或创建代币消耗格子
---@param index number
---@return table grid
function XUiEquipAwarenessOneClickPopup:GetOrCreateCostGrid(index)
    local grid = self.CostGridPool[index]
    if grid then
        return grid
    end

    local ui = CSInstantiate(self.GridCost, self.GridCost.transform.parent)
    grid = XTool.InitUiObjectByUi({}, ui)
    self.CostGridPool[index] = grid
    return grid
end

-- 刷新已勾选模块的三种代币展示数量
function XUiEquipAwarenessOneClickPopup:RefreshCost()
    local totalCostMap = {}
    MergeCostMap(totalCostMap, self.UiPanelStrengthen:GetPreviewCostMap())
    MergeCostMap(totalCostMap, self.UiPanelResonance:GetPreviewCostMap())
    MergeCostMap(totalCostMap, self.UiPanelOverclocking:GetPreviewCostMap())

    local usedGridCount = 0
    for _, itemId in ipairs(COST_ITEM_ID_LIST) do
        local count = totalCostMap[itemId] or 0
        if count > 0 then
            usedGridCount = usedGridCount + 1
            local grid = self:GetOrCreateCostGrid(usedGridCount)
            grid.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
            grid.TxtCost.text = FormatCost(count)
            grid.GameObject:SetActiveEx(true)
        end
    end

    for index = usedGridCount + 1, #self.CostGridPool do
        self.CostGridPool[index].GameObject:SetActiveEx(false)
    end
end

-- 缓存当前角色穿戴意识、参考意识和参考模板 Id
function XUiEquipAwarenessOneClickPopup:RefreshAwarenessContext()
    self.AwarenessEquipIdBySite = self.CharacterId and self._Control:GetCharacterAwarenessIdDic(self.CharacterId) or {}
    self.RefEquipId = self._Control:GetFirstWearAwarenessEquipId(self.AwarenessEquipIdBySite)
    self.RefTemplateId = self.RefEquipId and XMVCA.XEquip:GetEquipTemplateId(self.RefEquipId) or nil
end

-- 获取自动兑换开关的缓存状态
function XUiEquipAwarenessOneClickPopup:IsAutoExchangeOn()
    return self._Control:GetAwarenessEnhanceMainAutoExchangeOn()
end

-- 根据缓存状态刷新自动兑换按钮表现
function XUiEquipAwarenessOneClickPopup:RefreshAutoExchangeFromCache()
    local isOn = self:IsAutoExchangeOn()
    self.BtnAutoExchange:SetButtonState(isOn and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 点击自动设置按钮
function XUiEquipAwarenessOneClickPopup:OnBtnAutoSettingClick()
    XLuaUiManager.Open("UiEquipOneClickAutoCommonSetting")
end

-- 点击说明弹窗关闭按钮
function XUiEquipAwarenessOneClickPopup:OnBtnTipsCloseClick()
    self:CloseTips()
end

-- 点击消耗说明按钮
function XUiEquipAwarenessOneClickPopup:OnBtnChooseCostDescClick()
    self:CloseTips()
    self.PanelChooseCostTips.gameObject:SetActiveEx(true)
    self.PanelChooseCostTips.transform.position = self.BtnChooseCostDesc.transform.position
    self.BtnTipsClose.gameObject:SetActiveEx(true)
    self.UiTxtChooseCostTips.text = XUiHelper.ReadTextWithNewLine("AwarenessOneClickChooseCostTips")
end

-- 显示强化说明弹窗
---@param buttonWorldPosition UnityEngine.Vector3 触发按钮的世界坐标
function XUiEquipAwarenessOneClickPopup:ShowStrengthenTips(buttonWorldPosition)
    self:CloseTips()
    self.PanelStrengthenTips.gameObject:SetActiveEx(true)
    self.PanelStrengthenTips.transform.position = buttonWorldPosition
    self.BtnTipsClose.gameObject:SetActiveEx(true)
    self.UiTxtStrengthenTips.text = XUiHelper.ReadTextWithNewLine("AwarenessOneClickStrengthenTips")
end

-- 显示共鸣次数说明弹窗
---@param buttonWorldPosition UnityEngine.Vector3 触发按钮的世界坐标
function XUiEquipAwarenessOneClickPopup:ShowChooseTimeTips(buttonWorldPosition)
    self:CloseTips()
    self.PanelChooseTimeTips.gameObject:SetActiveEx(true)
    self.PanelChooseTimeTips.transform.position = buttonWorldPosition
    self.BtnTipsClose.gameObject:SetActiveEx(true)
    self.UiTxtChooseTimeTips.text = XUiHelper.ReadTextWithNewLine("AwarenessOneClickResonanceTimesTips")
end

-- 关闭全部说明弹窗和说明弹窗关闭按钮
function XUiEquipAwarenessOneClickPopup:CloseTips()
    self.PanelChooseCostTips.gameObject:SetActiveEx(false)
    self.PanelChooseTimeTips.gameObject:SetActiveEx(false)
    self.PanelStrengthenTips.gameObject:SetActiveEx(false)
    self.BtnTipsClose.gameObject:SetActiveEx(false)
end

-- 切换自动兑换状态，并同步刷新主界面和当前弹窗预览
function XUiEquipAwarenessOneClickPopup:OnBtnAutoExchangeClick()
    local isOn = self.BtnAutoExchange:GetToggleState()
    self._Control:SetAwarenessEnhanceMainAutoExchangeOn(isOn)
    self:Refresh()
end

--- 捕获实际进入执行流程的升级目标。
---@param strengthenResult table|nil 强化执行结果
---@return XAwarenessOneClickUpgradeRecordTarget
function XUiEquipAwarenessOneClickPopup:CaptureUpgradeRecordTarget(strengthenResult)
    if not strengthenResult then
        return { IsSelected = false }
    end

    return {
        IsSelected = true,
        TargetLevel = strengthenResult.TargetLevel,
        TargetBreakthrough = strengthenResult.TargetBreakthrough,
    }
end

--- 捕获实际进入执行流程的共鸣目标。
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult|nil 共鸣执行结果
---@return XAwarenessOneClickResonanceRecordTarget
function XUiEquipAwarenessOneClickPopup:CaptureResonanceRecordTarget(resonanceResult)
    if not resonanceResult then
        return { IsSelected = false }
    end

    local resonancePanel = self.UiPanelResonance
    local targetList = {}
    for _, skillData in ipairs(resonanceResult.UnachievedList) do
        targetList[#targetList + 1] = {
            Site = skillData.Site,
            Pos = skillData.Pos,
            Target = XTool.Clone(skillData.Target),
        }
    end

    return {
        IsSelected = true,
        UpperTargetIndex = resonancePanel.SkillTypeUpIndex,
        LowerTargetIndex = resonancePanel.SkillTypeDownIndex,
        TimesIndex = resonancePanel.TimesIndex,
        SelectedSlots = BuildSelectedResonanceSlots(targetList),
        TargetList = targetList,
    }
end

--- 捕获实际进入执行流程的埋点目标；执行结束后只补充最终状态。
---@param strengthenResult table|nil 强化执行结果
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult|nil 共鸣执行结果
---@param overclockingResult table|nil 超频执行结果
---@return XAwarenessOneClickRecordTarget
function XUiEquipAwarenessOneClickPopup:CaptureRecordTarget(strengthenResult, resonanceResult, overclockingResult)
    return {
        Upgrade = self:CaptureUpgradeRecordTarget(strengthenResult),
        Resonance = self:CaptureResonanceRecordTarget(resonanceResult),
        Overclock = {
            IsSelected = overclockingResult ~= nil,
        },
    }
end

-- 点击确认按钮
function XUiEquipAwarenessOneClickPopup:OnBtnConfirmClick()
    local resonanceTipKey = self.UiPanelResonance:GetMissingSettingTipKey()
    if resonanceTipKey then
        XUiManager.TipText(resonanceTipKey)
        return
    end

    local strengthenResult = self.UiPanelStrengthen:GetResult()
    local resonanceResult = self.UiPanelResonance:GetResult()
    local overclockingResult = self.UiPanelOverclocking:GetResult()
    if not strengthenResult and not resonanceResult and not overclockingResult then
        return
    end

    local progressArgs = {
        CharacterId = self.CharacterId,
        EquipIdBySite = XTool.Clone(self.AwarenessEquipIdBySite),
        StrengthenResult = strengthenResult,
        ResonanceResult = resonanceResult,
        OverclockingResult = overclockingResult,
        RecordTarget = self:CaptureRecordTarget(strengthenResult, resonanceResult, overclockingResult),
    }
    local onConfirm = function()
        self:Close()
        XLuaUiManager.Open("UiEquipAwarenessEnhanceProgressPopup", progressArgs)
    end

    local isConfirmSettingEnabled = self._Control.OneClickAutoSettingControl:GetSetting(XMVCA.XEquip.Enum.OneClickAutoSettingType.ConfirmSetting)
    if not isConfirmSettingEnabled then
        onConfirm()
        return
    end

    local exchangeList = BuildAutoExchangeList(strengthenResult, overclockingResult)
    if not XTool.IsTableEmpty(exchangeList) then
        XLuaUiManager.Open("UiRoleExchangeTipPopup", exchangeList, onConfirm)
        return
    end

    local content = XUiHelper.GetText("AwarenessOneClickConfirmContent")
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, onConfirm)
end

-- 点击关闭关闭弹窗
function XUiEquipAwarenessOneClickPopup:OnBtnCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWARENESS_ENHANCE_REFRESH)
end

return XUiEquipAwarenessOneClickPopup
