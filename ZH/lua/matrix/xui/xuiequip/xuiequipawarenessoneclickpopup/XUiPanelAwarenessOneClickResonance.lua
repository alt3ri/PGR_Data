local CSInstantiate = CS.UnityEngine.Object.Instantiate
local RESONANCE_COST_TYPE = XEnumConst.EQUIP.RESONANCE_COST_TYPE
local EMPTY_CONTENT_TITLE_COLOR = XUiHelper.Hexcolor2Color("A1A1A1")
local XUiGridAwarenessOneClickResonanceMaterial = require("XUi/XUiEquip/XUiEquipAwarenessOneClickPopup/XUiGridAwarenessOneClickResonanceMaterial")

-- 意识一键养成共鸣面板
---@class XUiPanelAwarenessOneClickResonance : XUiNode
---@field Parent XUiEquipAwarenessOneClickPopup 所属一键养成弹窗
---@field _Control XEquipControl 装备控制器
---@field BtnChoose XUiComponent.XUiButton 是否勾选共鸣功能的按钮
---@field BtnEditTarget XUiComponent.XUiButton 编辑目标共鸣技能按钮
---@field TxtChoosePreview UnityEngine.UI.Text 已选目标数量文本
---@field UiTxtPreview UnityEngine.UI.Text 共鸣预览文本
---@field PanelChooseMaterial UiObject 共鸣材料展示区域节点
---@field GridChooseMaterial UiObject 共鸣材料展示格子模板
---@field PanelSkillTypeUp XUiButtonGroup 上排共鸣技能类型按钮组
---@field PanelSkillTypeDown XUiButtonGroup 下排共鸣技能类型按钮组
---@field PanelChooseTimes XUiButtonGroup 共鸣次数按钮组
---@field SkillTypeUpButtons XUiComponent.XUiButton[] 上排共鸣技能类型按钮
---@field SkillTypeDownButtons XUiComponent.XUiButton[] 下排共鸣技能类型按钮
---@field BtnSkillTypeUp1 XUiComponent.XUiButton 上排共鸣技能类型按钮 1
---@field BtnSkillTypeUp2 XUiComponent.XUiButton 上排共鸣技能类型按钮 2
---@field BtnSkillTypeUp3 XUiComponent.XUiButton 上排共鸣技能类型按钮 3
---@field BtnSkillTypeDown1 XUiComponent.XUiButton 下排共鸣技能类型按钮 1
---@field BtnSkillTypeDown2 XUiComponent.XUiButton 下排共鸣技能类型按钮 2
---@field BtnSkillTypeDown3 XUiComponent.XUiButton 下排共鸣技能类型按钮 3
---@field BtnTimes1 XUiComponent.XUiButton 共鸣次数按钮 1
---@field BtnTimes2 XUiComponent.XUiButton 共鸣次数按钮 2
---@field BtnTimes3 XUiComponent.XUiButton 共鸣次数按钮 3
---@field BtnTimesTag UiObject 到达目标选中标签
---@field SkillTypeUpIndex number 当前选中的上排共鸣技能类型下标
---@field SkillTypeDownIndex number 当前选中的下排共鸣技能类型下标
---@field TimesIndex number 当前选中的共鸣次数下标
---@field IsChoose boolean 共鸣功能是否参与一键养成
---@field IsEmptyState boolean 当前功能是否不可参与一键养成
---@field DefaultTitleColor UnityEngine.Color 标题默认颜色
---@field DefaultPreviewColor UnityEngine.Color 预览文本默认颜色
---@field DefaultArrowColor UnityEngine.Color 箭头默认颜色
---@field CachedSelectedResonanceSkillMap table<number, table<number, boolean>> 用户缓存的目标槽位选择，包含当前方案下已达成槽位
---@field SelectedResonanceSkillMap table<number, table<number, boolean>> 当前可共鸣且未达成的已选目标槽位
---@field SelectableTargetSlotCount number 当前方案下可共鸣且未达成的目标槽位数量
---@field SelectedMaterialMap table<string, boolean|table<number, boolean>> 已选共鸣材料字典，普通材料为 true，意识材料为 {[equipId] = true}
---@field PreviewSkillExistsMap table<number, table<number, boolean>> 本轮预览后有共鸣技能的槽位映射
---@field PreviewContext XUiPanelAwarenessOneClickResonancePreviewContext|nil 本轮共鸣预览上下文
---@field ChooseMaterialGridPool table<number, XUiGridAwarenessOneClickResonanceMaterial> 共鸣材料展示格子对象池
---@field SelectedItemIdMap table<number, boolean> 已缓存的普通共鸣材料 ItemId 字典
local XUiPanelAwarenessOneClickResonance = XClass(XUiNode, "XUiPanelAwarenessOneClickResonance")

---@class XUiPanelAwarenessOneClickResonanceUnachievedSkillData
---@field CharacterId number 当前操作的角色 Id
---@field Site number 意识穿戴位置
---@field Pos number 共鸣槽位
---@field EquipId number 意识装备 Id
---@field SuitId number 意识套装 Id
---@field Target XEquipAwarenessResonanceTarget 共鸣目标
---@field IsResonanced boolean 当前共鸣槽位是否已共鸣

---@class XUiPanelAwarenessOneClickResonancePreviewMaterialData
---@field NeedCountMap table<string, number> 材料 Key 到预计消耗数量的映射
---@field SelectedCountMap table<string, number> 材料 Key 到当前选中数量的映射
---@field SelectedItemList table<number, table> 当前选中的道具材料列表

---@class XUiPanelAwarenessOneClickResonancePreviewContext
---@field UnachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
---@field MaterialList table<number, table> 当前可展示的材料列表
---@field TokenMinCostCountMap table<string, number> 普通共鸣道具 Key 到最低有效单次消耗的映射
---@field NeedCountMap table<string, number> 材料 Key 到预计消耗数量的映射
---@field PreviewSkillExistsMap table<number, table<number, boolean>> 预估后有共鸣技能的槽位映射
---@field PreviewMaterialData XUiPanelAwarenessOneClickResonancePreviewMaterialData|nil 预估材料消耗上下文
---@field FirstResonanceSucceedMap table<XUiPanelAwarenessOneClickResonanceUnachievedSkillData, boolean> 未共鸣槽位首次共鸣是否成功的映射
---@field FirstTargetReachedMap table<XUiPanelAwarenessOneClickResonanceUnachievedSkillData, boolean> 首次共鸣是否通过指定技能材料直接达成目标的映射
---@field FirstNeedCountMap table<string, number> 首次共鸣阶段已预占的材料数量
---@field TimesCount number 选择的共鸣次数
---@field IsUntilTarget boolean 是否选择到达成目标
---@field PreviewRemainItemCountDic table<number, number> 当前共鸣预览阶段后的剩余资源数量

---@class XUiPanelAwarenessOneClickResonanceResult
---@field CharacterId number 当前操作的角色 Id
---@field UnachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
---@field TargetCount number 本次需要处理的目标共鸣技能数量
---@field TimesCount number 选择的共鸣次数
---@field IsUntilTarget boolean 是否选择到达成目标
---@field TargetMatchModeByPos table<number, XEquipAwarenessResonanceTargetMatchMode> 共鸣槽位到目标匹配模式的映射
---@field TaskList XUiPanelAwarenessOneClickResonanceTask[] 执行流程任务列表
---@field MaterialBudget XUiPanelAwarenessOneClickResonanceMaterialBudget|nil 执行流程共享的材料预算

---@class XUiPanelAwarenessOneClickResonanceTask
---@field EquipId number 意识装备 Id
---@field Pos number 共鸣槽位
---@field Target XEquipAwarenessResonanceTarget 共鸣目标
---@field AwarenessMaterialKey string 意识材料 Key
---@field MaxTimes number 最大共鸣次数
---@field ExecutedTimes number 已执行次数
---@field IsFirstResonance boolean 是否首次共鸣任务

---@class XUiPanelAwarenessOneClickResonanceMaterialBudget
---@field SelectedCountMap table<string, number> 材料 Key 到执行阶段剩余可消耗数量的映射
---@field SelectedAwarenessIdListByKey table<string, number[]> 材料 Key 到已选意识 Id 列表的映射
---@field SelectedItemList table<number, table> 当前选中的道具材料列表
---@field DisplayMaterialList table<number, table> 按选择界面顺序排列的全部已选材料
local DEFAULT_SELECT_INDEX = 0

-- 判断当前意识的目标共鸣位是否已达成。
---@param resonanceControl XEquipResonanceControl
---@param equip XEquip
---@param target XEquipAwarenessResonanceTarget
---@param characterId number
---@return boolean
local function IsTargetSlotAchieved(resonanceControl, equip, target, characterId)
    return not resonanceControl:IsAwarenessResonanceTargetUnachieved(equip, target, characterId)
end

-- 恢复按钮组选中态，索引 0 表示无选中项
---@param buttonGroup XUiButtonGroup
---@param index number
local function RestoreButtonGroupSelect(buttonGroup, index)
    if index == DEFAULT_SELECT_INDEX then
        buttonGroup:CancelSelect()
        return
    end

    buttonGroup:SelectIndex(index, false)
end

-- 判断材料在当前目标集合下是否禁止选择。
---@param materialData table 材料展示数据
---@param tokenMinCostCountMap table<string, number> 普通共鸣道具最低有效单次消耗字典
---@return boolean 是否禁止选择
local function IsChooseMaterialDisabled(materialData, tokenMinCostCountMap)
    if materialData.Type ~= RESONANCE_COST_TYPE.TOKEN then
        return false
    end

    local minCostCount = tokenMinCostCountMap[materialData.MaterialKey]
    if not minCostCount then
        return true
    end

    return materialData.Count < minCostCount
end

-- 多次共鸣选项是否启用
local IS_MULTI_TIMES_OPTION_ENABLED = false

local FIRST_RESONANCE_TIMES = 1

local RESONANCE_TIMES_INDEX = {
    NONE = 0,
    ONCE = 1,
    FIVE = 2,
    UNTIL_TARGET = 3,
}

-- 共鸣次数按钮下标到实际共鸣次数的映射；“到达成目标”需要运行时动态判定，材料预估按 0 次处理。
local RESONANCE_TIMES_COUNT_BY_INDEX = {
    [RESONANCE_TIMES_INDEX.NONE] = 0,
    [RESONANCE_TIMES_INDEX.ONCE] = 1,
    [RESONANCE_TIMES_INDEX.FIVE] = 5,
    [RESONANCE_TIMES_INDEX.UNTIL_TARGET] = 0,
}

-- 共鸣技能筛选按钮组选项下标，不是 XEnumConst.EQUIP.RESONANCE_TYPE
local SKILL_OPTION_INDEX = {
    ANY = 1,        -- 任意技能
    ATTACK = 2,     -- 任意攻击技能
    TARGET = 3,     -- 与目标共鸣技能一致
}

-- 判断技能方案是否允许选择多次共鸣。
---@param index number 共鸣技能方案下标
---@return boolean 是否允许选择多次共鸣
local function IsMultiTimesSkillOption(index)
    return index == SKILL_OPTION_INDEX.ATTACK or index == SKILL_OPTION_INDEX.TARGET
end

local TARGET_MATCH_MODE = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE
local TARGET_MATCH_MODE_BY_SKILL_OPTION_INDEX = {
    [SKILL_OPTION_INDEX.ANY] = TARGET_MATCH_MODE.ANY,
    [SKILL_OPTION_INDEX.ATTACK] = TARGET_MATCH_MODE.ATTACK,
    [SKILL_OPTION_INDEX.TARGET] = TARGET_MATCH_MODE.TARGET,
}

-- 将 UI 技能选项转换为 Control 使用的目标匹配模式；未选择时按指定目标计算。
---@param skillOptionIndex number 共鸣技能筛选按钮组选项下标
---@return XEquipAwarenessResonanceTargetMatchMode
local function ResolveTargetMatchMode(skillOptionIndex)
    if skillOptionIndex == DEFAULT_SELECT_INDEX then
        return TARGET_MATCH_MODE.TARGET
    end

    local targetMatchMode = TARGET_MATCH_MODE_BY_SKILL_OPTION_INDEX[skillOptionIndex]
    assert(targetMatchMode, string.format("Invalid resonance skill option index: %s", tostring(skillOptionIndex)))
    return targetMatchMode
end

-- 初始化共鸣面板运行时字段和组件
function XUiPanelAwarenessOneClickResonance:OnStart()
    self.ChooseMaterialGridPool = {}
    self.IsChoose = self._Control.OneClickAutoSettingControl:GetSetting(XMVCA.XEquip.Enum.OneClickAutoSettingType.AwarenessResonance)
    self.CachedSelectedResonanceSkillMap = {}
    self.SelectedResonanceSkillMap = {}
    self.SelectableTargetSlotCount = 0
    self.SelectedMaterialMap = {}
    self.SelectedItemIdMap = {}
    self.PreviewSkillExistsMap = {}
    self.PreviewContext = nil
    self.IsEmptyState = true
    self.DefaultTitleColor = self.UiTxtTitle.color
    self.DefaultPreviewColor = self.UiTxtPreview.color
    self.DefaultArrowColor = self.ImgArrow.color

    self:InitComponents()
end

-- 初始化共鸣面板组件状态和交互事件
function XUiPanelAwarenessOneClickResonance:InitComponents()
    self.GridChooseMaterial.gameObject:SetActiveEx(false)

    self:InitButtonGroups()
    self.Parent:RegisterClickEvent(self.BtnChoose, function()
        self:OnBtnChooseClick()
    end)
    self.Parent:RegisterClickEvent(self.BtnEditTarget, function()
        self:OnBtnEditTargetClick()
    end)
    self.Parent:RegisterClickEvent(self.BtnNumDesc, function()
        self:OnBtnNumDescClick()
    end)
end

-- 刷新超频前共鸣预览：只预占首次共鸣，用于给超频提供可超频槽位和资源预算
---@param previewRemainItemCountDic table<number, number> 强化预览后的剩余资源数量
---@return table<number, number> previewRemainItemCountDic 首次共鸣预占后的剩余资源数量
function XUiPanelAwarenessOneClickResonance:RefreshPreviewBeforeOverclocking(previewRemainItemCountDic)
    self:RefreshSetting()
    local unachievedList = self:BuildUnachievedSelectedResonanceSkillList()
    self.PreviewContext = self:BuildSelectedMaterialPreviewContext(unachievedList, previewRemainItemCountDic)
    self.PreviewSkillExistsMap = self.PreviewContext.PreviewSkillExistsMap
    self:RefreshPreviewText(unachievedList)

    return self.PreviewContext.PreviewRemainItemCountDic
end

-- 判断当前穿戴且可共鸣的意识中，是否存在未达成当前方案的推荐目标共鸣技能。
---@return boolean 是否存在未达成的推荐目标共鸣技能
function XUiPanelAwarenessOneClickResonance:HasUnachievedTargetResonanceSkill()
    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)
    if XTool.IsTableEmpty(awarenessSlotList) then
        return false
    end

    local resonanceControl = self._Control.ResonanceControl
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.Parent.AwarenessEquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
        if isCanResonance then
            local targetSlotData = awarenessSlotList[site]
            if targetSlotData and targetSlotData.ResonanceList then
                for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                    local targetResonanceData = targetSlotData.ResonanceList[pos]
                    if targetResonanceData then
                        local skillOptionIndex = pos == XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP
                            and self.SkillTypeUpIndex or self.SkillTypeDownIndex
                        local target = self:BuildResonanceTarget(pos, skillOptionIndex, targetResonanceData)
                        if not IsTargetSlotAchieved(resonanceControl, equip, target, characterId) then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

-- 刷新超频后共鸣预览：扣除超频占用后，再预估剩余共鸣次数并刷新材料格
---@param previewRemainItemCountDic table<number, number> 超频预览后的剩余资源数量
---@return table<number, number> previewRemainItemCountDic 剩余共鸣预览后的剩余资源数量
function XUiPanelAwarenessOneClickResonance:RefreshPreviewAfterOverclocking(previewRemainItemCountDic)
    local previewContext = self.PreviewContext
    self:ConsumeRemainResonancePreviewAfterOverclocking(previewContext, previewRemainItemCountDic)
    previewContext.PreviewRemainItemCountDic = self:BuildPreviewRemainItemCountDicAfterOverclocking(previewContext, previewRemainItemCountDic)
    self:RefreshChooseMaterialGridList(previewContext)

    return previewContext.PreviewRemainItemCountDic
end

-- 获取已勾选共鸣时缺失的设置提示文本 Key；设置完整或当前无可共鸣目标时返回 nil。
---@return string|nil
function XUiPanelAwarenessOneClickResonance:GetMissingSettingTipKey()
    if not self.IsChoose then
        return nil
    end

    if not self:HasUnachievedTargetResonanceSkill() then
        return nil
    end

    local isUpTargetSelected = false
    local isDownTargetSelected = false
    local upResonancePos = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP
    local downResonancePos = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.DOWN
    for _, posMap in pairs(self.SelectedResonanceSkillMap) do
        isUpTargetSelected = isUpTargetSelected or posMap[upResonancePos] == true
        isDownTargetSelected = isDownTargetSelected or posMap[downResonancePos] == true
    end

    if not isUpTargetSelected and not isDownTargetSelected then
        return "AwarenessOneClickResonanceTargetNotSelected"
    end

    if isUpTargetSelected and self.SkillTypeUpIndex == DEFAULT_SELECT_INDEX then
        return "AwarenessOneClickResonanceTargetUpSchemeNotSelected"
    end

    if isDownTargetSelected and self.SkillTypeDownIndex == DEFAULT_SELECT_INDEX then
        return "AwarenessOneClickResonanceTargetDownSchemeNotSelected"
    end

    if XTool.IsTableEmpty(self.SelectedMaterialMap) then
        return "AwarenessOneClickResonanceMaterialNotSelected"
    end

    if self.TimesIndex == DEFAULT_SELECT_INDEX then
        return "AwarenessOneClickResonanceTimesNotSelected"
    end

    return nil
end

-- 获取传给进度弹窗的共鸣执行结果；未勾选时不参与后续流程
---@return XUiPanelAwarenessOneClickResonanceResult|nil
function XUiPanelAwarenessOneClickResonance:GetResult()
    if not self.IsChoose or not self.PreviewContext then
        return nil
    end

    local result = self:BuildResonanceResult(self.PreviewContext)
    local hasTarget = result.TargetCount > 0
    local hasTimes = result.IsUntilTarget or result.TimesCount > 0
    local hasTask = not XTool.IsTableEmpty(result.TaskList)
    local hasMaterialBudget = result.MaterialBudget ~= nil
    if not hasTarget or not hasTimes or not hasTask or not hasMaterialBudget then
        return nil
    end

    return result
end

-- 获取共鸣阶段的代币展示数量；到达目标返回已选数量，固定次数返回预计消耗数量
---@return table<number, number> costMap 道具 Id -> 展示数量
function XUiPanelAwarenessOneClickResonance:GetPreviewCostMap()
    local previewContext = self.PreviewContext
    if not self.IsChoose or not previewContext then
        return table.empty
    end

    local costMap = {}
    for _, materialData in ipairs(previewContext.MaterialList) do
        if materialData.Type ~= RESONANCE_COST_TYPE.AWARENESS then
            local count
            if previewContext.IsUntilTarget then
                count = self:GetChooseMaterialSelectedCount(materialData)
            else
                count = previewContext.NeedCountMap[materialData.MaterialKey] or 0
            end

            if count > 0 then
                local itemId = materialData.ItemId
                costMap[itemId] = (costMap[itemId] or 0) + count
            end
        end
    end

    return costMap
end

-- 刷新共鸣目标选择数量和执行预览
---@param unachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
function XUiPanelAwarenessOneClickResonance:RefreshPreviewText(unachievedList)
    local selectedTargetSlotCount = self:GetSelectedTargetSlotCount()
    local unachievedCount = #unachievedList
    local missingSettingTipKey = self:GetMissingSettingTipKey()
    local hasMissingSetting = missingSettingTipKey ~= nil
    self.TxtChoosePreview.text = string.format("%d/%d", selectedTargetSlotCount, self.SelectableTargetSlotCount)
    self.IsEmptyState = not self.IsChoose or hasMissingSetting
    self.UiTxtTitle.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultTitleColor
    self.UiTxtPreview.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultPreviewColor
    self.ImgArrow.color = self.IsEmptyState and EMPTY_CONTENT_TITLE_COLOR or self.DefaultArrowColor
    self.ImgArrow.gameObject:SetActiveEx(self.IsChoose)
    self.UiTxtPreview.gameObject:SetActiveEx(self.IsChoose)
    self:RefreshTitleState()

    if missingSettingTipKey then
        self.UiTxtPreview.text = XUiHelper.GetText(missingSettingTipKey)
    elseif unachievedCount <= 0 or self.TimesIndex == RESONANCE_TIMES_INDEX.NONE then
        self.UiTxtPreview.text = ""
    elseif self.TimesIndex == RESONANCE_TIMES_INDEX.UNTIL_TARGET then
        self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickResonanceTargetTimesDesc", unachievedCount)
    else
        local timesCount = unachievedCount * RESONANCE_TIMES_COUNT_BY_INDEX[self.TimesIndex]
        self.UiTxtPreview.text = XUiHelper.GetText("AwarenessOneClickResonanceTimesDesc", unachievedCount, timesCount)
    end
end

-- 初始化共鸣技能类型和共鸣次数的按钮组
function XUiPanelAwarenessOneClickResonance:InitButtonGroups()
    self.SkillTypeUpIndex = DEFAULT_SELECT_INDEX
    self.SkillTypeDownIndex = DEFAULT_SELECT_INDEX
    self.TimesIndex = DEFAULT_SELECT_INDEX

    self.SkillTypeUpButtons = { self.BtnSkillTypeUp1, self.BtnSkillTypeUp2, self.BtnSkillTypeUp3 }
    self.PanelSkillTypeUp:Init(self.SkillTypeUpButtons, function(index)
        self:OnSkillTypeUpSelect(index)
    end)
    self.PanelSkillTypeUp:CancelSelect()

    self.SkillTypeDownButtons = { self.BtnSkillTypeDown1, self.BtnSkillTypeDown2, self.BtnSkillTypeDown3 }
    self.PanelSkillTypeDown:Init(self.SkillTypeDownButtons, function(index)
        self:OnSkillTypeDownSelect(index)
    end)
    self.PanelSkillTypeDown:CancelSelect()

    local timesButtons = { self.BtnTimes1, self.BtnTimes2, self.BtnTimes3 }
    self.PanelChooseTimes:Init(timesButtons, function(index)
        self:OnTimesSelect(index)
    end)
    self.PanelChooseTimes:CancelSelect()

    self:RefreshTimesButtonState()
end

-- 按角色缓存和默认值刷新共鸣方案，并同步当前弹窗的勾选表现
function XUiPanelAwarenessOneClickResonance:RefreshSetting()
    local settingControl = self._Control.OneClickAutoSettingControl
    local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
    local characterId = self.Parent.CharacterId
    self.SkillTypeUpIndex = settingControl:GetCharacterSetting(characterId, settingType.AwarenessResonanceSkillTypeUpIndex)
    self.SkillTypeDownIndex = settingControl:GetCharacterSetting(characterId, settingType.AwarenessResonanceSkillTypeDownIndex)
    local cachedTimesIndex = settingControl:GetCharacterSetting(characterId, settingType.AwarenessResonanceTimesIndex)
    self.TimesIndex = cachedTimesIndex
    local cachedSkillMap = settingControl:GetCharacterSetting(characterId, settingType.AwarenessResonanceSelectedSkillMap)
    self.CachedSelectedResonanceSkillMap = cachedSkillMap
    self.SelectedItemIdMap = settingControl:GetCharacterSetting(characterId, settingType.AwarenessResonanceSelectedItemIdMap)
    self:RefreshSelectedResonanceSkillMap(cachedSkillMap)

    -- 恢复按钮组选中态；索引 0 表示未选择
    RestoreButtonGroupSelect(self.PanelChooseTimes, self.TimesIndex)

    -- 技能类型按钮先恢复可选状态，再按缓存恢复选中并设置禁用态，避免选择禁用按钮触发回调。
    self:RefreshSkillTypeButtonState()

    local buttonState = self.IsChoose and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnChoose:SetButtonState(buttonState)
    self:RefreshTitleState()
    self:RefreshTimesButtonState()
    if self.TimesIndex ~= cachedTimesIndex then
        settingControl:SetCharacterSetting(characterId, settingType.AwarenessResonanceTimesIndex, self.TimesIndex)
    end
end

-- 从设置缓存中恢复当前可共鸣且未达成的已选目标槽位。
---@param cachedSkillMap table<number, table<number, boolean>>
function XUiPanelAwarenessOneClickResonance:RefreshSelectedResonanceSkillMap(cachedSkillMap)
    self.SelectedResonanceSkillMap = {}
    self.SelectableTargetSlotCount = 0

    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)
    local resonanceControl = self._Control.ResonanceControl

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.Parent.AwarenessEquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
        if isCanResonance then
            local cachedPosMap = cachedSkillMap[site]
            local selectedPosMap = {}
            local targetSlotData = awarenessSlotList and awarenessSlotList[site]
            for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                local resonanceList = targetSlotData and targetSlotData.ResonanceList
                local targetResonanceData = resonanceList and resonanceList[pos]
                local skillOptionIndex = pos == XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP
                    and self.SkillTypeUpIndex or self.SkillTypeDownIndex
                local target = targetResonanceData
                    and self:BuildResonanceTarget(pos, skillOptionIndex, targetResonanceData)
                if target and not IsTargetSlotAchieved(resonanceControl, equip, target, characterId) then
                    self.SelectableTargetSlotCount = self.SelectableTargetSlotCount + 1
                    if cachedPosMap and cachedPosMap[pos] == true then
                        selectedPosMap[pos] = true
                    end
                end
            end
            if next(selectedPosMap) then
                self.SelectedResonanceSkillMap[site] = selectedPosMap
            end
        end
    end
end

-- 判断指定共鸣位是否存在缓存选中且当前已达成的目标。
---@param resonancePos number 共鸣位
---@param skillOptionIndex number 共鸣技能筛选按钮组选项下标
---@return boolean 是否存在已达成目标
function XUiPanelAwarenessOneClickResonance:HasAchievedCachedResonanceTarget(resonancePos, skillOptionIndex)
    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)
    local resonanceControl = self._Control.ResonanceControl

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local cachedPosMap = self.CachedSelectedResonanceSkillMap[site]
        if cachedPosMap and cachedPosMap[resonancePos] == true then
            local equipId = self.Parent.AwarenessEquipIdBySite[site]
            local equip = equipId and self._Control:GetEquip(equipId)
            local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
            if isCanResonance then
                local targetSlotData = awarenessSlotList and awarenessSlotList[site]
                local resonanceList = targetSlotData and targetSlotData.ResonanceList
                local targetResonanceData = resonanceList and resonanceList[resonancePos]
                local target = targetResonanceData
                    and self:BuildResonanceTarget(resonancePos, skillOptionIndex, targetResonanceData)
                if target and IsTargetSlotAchieved(resonanceControl, equip, target, characterId) then
                    return true
                end
            end
        end
    end

    return false
end

-- 判断用户缓存的目标槽位中，是否存在尚未达成指定方案的意识。
---@param resonancePos number 共鸣位
---@param skillOptionIndex number 共鸣技能类型选项下标
---@return boolean 是否存在未达成指定技能类型的已选意识
function XUiPanelAwarenessOneClickResonance:HasUnachievedCachedResonanceTarget(resonancePos, skillOptionIndex)
    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)
    local resonanceControl = self._Control.ResonanceControl

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local posMap = self.CachedSelectedResonanceSkillMap[site]
        if posMap and posMap[resonancePos] == true then
            local equipId = self.Parent.AwarenessEquipIdBySite[site]
            local equip = equipId and self._Control:GetEquip(equipId)
            local targetSlotData = awarenessSlotList and awarenessSlotList[site]
            local resonanceList = targetSlotData and targetSlotData.ResonanceList
            local targetResonanceData = resonanceList and resonanceList[resonancePos]
            local isCanResonance = equip and XMVCA.XEquip:CanResonance(equipId)
            if isCanResonance and targetResonanceData then
                local target = self:BuildResonanceTarget(resonancePos, skillOptionIndex, targetResonanceData)
                local isUnachieved = resonanceControl:IsAwarenessResonanceTargetUnachieved(equip, target, characterId)
                if isUnachieved then
                    return true
                end
            end
        end
    end

    return false
end

-- 刷新一排共鸣技能类型按钮，并返回当前有效的选中下标。
---@param resonancePos number 共鸣位
---@param selectedIndex number 当前选中下标
---@param buttonGroup XUiButtonGroup 共鸣技能类型按钮组
---@param buttons XUiComponent.XUiButton[] 共鸣技能类型按钮
---@return number 当前有效的选中下标
function XUiPanelAwarenessOneClickResonance:RefreshSkillTypeRowButtonState(resonancePos, selectedIndex, buttonGroup, buttons)
    local isButtonDisabledBySkillOption = {}

    for skillOptionIndex in ipairs(buttons) do
        local hasUnachievedTarget = self:HasUnachievedCachedResonanceTarget(resonancePos, skillOptionIndex)
        isButtonDisabledBySkillOption[skillOptionIndex] = not hasUnachievedTarget
    end

    local isSelectedButtonDisabled = isButtonDisabledBySkillOption[selectedIndex]
    local canRestoreSelect = selectedIndex ~= DEFAULT_SELECT_INDEX and isSelectedButtonDisabled == false

    -- SelectIndex 会调用禁用按钮的回调，先重置按钮状态再恢复有效选中。
    for _, button in ipairs(buttons) do
        button:SetDisable(false)
    end

    if not canRestoreSelect then
        buttonGroup:CancelSelect()
    end

    for skillOptionIndex, button in ipairs(buttons) do
        button:SetDisable(isButtonDisabledBySkillOption[skillOptionIndex])
    end

    if not canRestoreSelect then
        return DEFAULT_SELECT_INDEX
    end

    buttonGroup:SelectIndex(selectedIndex, false)
    return selectedIndex
end

-- 刷新共鸣技能类型按钮的禁用状态。
-- 当前技能类型没有已选目标或目标均已达成时，仅取消本轮 UI 选择，不覆盖角色缓存。
function XUiPanelAwarenessOneClickResonance:RefreshSkillTypeButtonState()
    self.SkillTypeUpIndex = self:RefreshSkillTypeRowButtonState(
        XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP,
        self.SkillTypeUpIndex,
        self.PanelSkillTypeUp,
        self.SkillTypeUpButtons
    )
    self.SkillTypeDownIndex = self:RefreshSkillTypeRowButtonState(
        XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.DOWN,
        self.SkillTypeDownIndex,
        self.PanelSkillTypeDown,
        self.SkillTypeDownButtons
    )
end

-- 选择上排共鸣技能类型，并刷新预览
function XUiPanelAwarenessOneClickResonance:OnSkillTypeUpSelect(index)
    local selectedIndex = XTool.IsNumberValid(index) and index or DEFAULT_SELECT_INDEX
    local button = self.SkillTypeUpButtons[selectedIndex]
    if selectedIndex ~= DEFAULT_SELECT_INDEX and button.ButtonState == CS.UiButtonState.Disable then
        local hasAchievedTarget = self:HasAchievedCachedResonanceTarget(
            XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.UP,
            selectedIndex
        )
        local tipKey = hasAchievedTarget and "AwarenessOneClickResonanceTargetAchieved" or "AwarenessOneClickResonanceTargetUpNotSelected"
        XUiManager.TipText(tipKey)
        return
    end

    local previousTimesIndex = self.TimesIndex
    local characterId = self.Parent.CharacterId
    self.SkillTypeUpIndex = selectedIndex
    self:RefreshTimesButtonState()
    local settingControl = self._Control.OneClickAutoSettingControl
    local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
    settingControl:SetCharacterSetting(characterId, settingType.AwarenessResonanceSkillTypeUpIndex, self.SkillTypeUpIndex)
    if self.TimesIndex ~= previousTimesIndex then
        settingControl:SetCharacterSetting(characterId, settingType.AwarenessResonanceTimesIndex, self.TimesIndex)
    end
    self.Parent:RefreshPreview()
end

-- 选择下排共鸣技能类型，并刷新预览
function XUiPanelAwarenessOneClickResonance:OnSkillTypeDownSelect(index)
    local selectedIndex = XTool.IsNumberValid(index) and index or DEFAULT_SELECT_INDEX
    local button = self.SkillTypeDownButtons[selectedIndex]
    if selectedIndex ~= DEFAULT_SELECT_INDEX and button.ButtonState == CS.UiButtonState.Disable then
        local hasAchievedTarget = self:HasAchievedCachedResonanceTarget(
            XEnumConst.EQUIP.AWARENESS_RESONANCE_POS.DOWN,
            selectedIndex
        )
        local tipKey = hasAchievedTarget and "AwarenessOneClickResonanceTargetAchieved" or "AwarenessOneClickResonanceTargetDownNotSelected"
        XUiManager.TipText(tipKey)
        return
    end

    local previousTimesIndex = self.TimesIndex
    local characterId = self.Parent.CharacterId
    self.SkillTypeDownIndex = selectedIndex
    self:RefreshTimesButtonState()
    local settingControl = self._Control.OneClickAutoSettingControl
    local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
    settingControl:SetCharacterSetting(characterId, settingType.AwarenessResonanceSkillTypeDownIndex, self.SkillTypeDownIndex)
    if self.TimesIndex ~= previousTimesIndex then
        settingControl:SetCharacterSetting(characterId, settingType.AwarenessResonanceTimesIndex, self.TimesIndex)
    end
    self.Parent:RefreshPreview()
end

-- 选择共鸣次数类型，并刷新预览
function XUiPanelAwarenessOneClickResonance:OnTimesSelect(index)
    self.TimesIndex = XTool.IsNumberValid(index) and index or DEFAULT_SELECT_INDEX
    local characterId = self.Parent.CharacterId
    local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
    self._Control.OneClickAutoSettingControl:SetCharacterSetting(characterId, settingType.AwarenessResonanceTimesIndex, self.TimesIndex)
    self.Parent:RefreshPreview()
end

-- 按技能方案和解锁条件刷新共鸣次数按钮；当前选择失效时取消选择。
function XUiPanelAwarenessOneClickResonance:RefreshTimesButtonState()
    local isMultiTimesVisible = IS_MULTI_TIMES_OPTION_ENABLED and (IsMultiTimesSkillOption(self.SkillTypeUpIndex) or IsMultiTimesSkillOption(self.SkillTypeDownIndex))
    local untilTargetConditionValues = XMVCA.XEquip:GetEquipConfigValuesByKey("AwarenessOneClickResonanceUntilTargetCondition")
    local untilTargetConditionId = untilTargetConditionValues[1]
    local isUntilTargetVisible = isMultiTimesVisible
        and (not XTool.IsNumberValid(untilTargetConditionId)
            or XConditionManager.CheckCondition(untilTargetConditionId))

    self.BtnTimes1.gameObject:SetActiveEx(true)
    self.BtnTimes2.gameObject:SetActiveEx(isMultiTimesVisible)
    self.BtnTimes3.gameObject:SetActiveEx(isUntilTargetVisible)

    local isCurrentTimesVisible = self.TimesIndex == RESONANCE_TIMES_INDEX.ONCE
        or self.TimesIndex == RESONANCE_TIMES_INDEX.FIVE and isMultiTimesVisible
        or self.TimesIndex == RESONANCE_TIMES_INDEX.UNTIL_TARGET and isUntilTargetVisible
    if self.TimesIndex ~= RESONANCE_TIMES_INDEX.NONE and not isCurrentTimesVisible then
        self.PanelChooseTimes:CancelSelect()
        self.TimesIndex = RESONANCE_TIMES_INDEX.NONE
    end

    local isUntilTargetSelected = self.TimesIndex == RESONANCE_TIMES_INDEX.UNTIL_TARGET
    self.BtnTimesTag.gameObject:SetActiveEx(isUntilTargetSelected)
end

-- 切换共鸣功能是否参与一键养成
function XUiPanelAwarenessOneClickResonance:OnBtnChooseClick()
    self.IsChoose = self.BtnChoose:GetToggleState()
    self:RefreshTitleState()
    self.Parent:RefreshPreview()
end

-- 刷新共鸣标题背景；仅在已勾选且存在可执行内容时显示选中背景
function XUiPanelAwarenessOneClickResonance:RefreshTitleState()
    local isTitleChoose = self.IsChoose and not self.IsEmptyState
    self.BgTitleChoose.gameObject:SetActiveEx(isTitleChoose)
    self.BgTitleNotChoose.gameObject:SetActiveEx(not isTitleChoose)
end

-- 点击共鸣次数说明按钮
function XUiPanelAwarenessOneClickResonance:OnBtnNumDescClick()
    self.Parent:ShowChooseTimeTips(self.BtnNumDesc.transform.position)
end

-- 打开目标共鸣技能选择界面，并在确认后刷新预览。
function XUiPanelAwarenessOneClickResonance:OnBtnEditTargetClick()
    XLuaUiManager.Open(
        "UiEquipChooseAwarenessResonanceSkillPopup",
        self.Parent.CharacterId,
        self.SelectedResonanceSkillMap,
        self:GetTargetMatchModeByPos(),
        function()
            self.Parent:RefreshPreview()
        end
    )
end

-- 获取当前上下排共鸣方案快照。
---@return table<number, XEquipAwarenessResonanceTargetMatchMode>
function XUiPanelAwarenessOneClickResonance:GetTargetMatchModeByPos()
    local resonancePos = XEnumConst.EQUIP.AWARENESS_RESONANCE_POS
    local targetMatchModeByPos = {}
    if self.SkillTypeUpIndex ~= DEFAULT_SELECT_INDEX then
        targetMatchModeByPos[resonancePos.UP] = ResolveTargetMatchMode(self.SkillTypeUpIndex)
    end
    if self.SkillTypeDownIndex ~= DEFAULT_SELECT_INDEX then
        targetMatchModeByPos[resonancePos.DOWN] = ResolveTargetMatchMode(self.SkillTypeDownIndex)
    end
    return targetMatchModeByPos
end

-- 统计当前方案下已选择且尚未达成的目标槽位数量。
---@return number 已选择的目标槽位数量
function XUiPanelAwarenessOneClickResonance:GetSelectedTargetSlotCount()
    local count = 0
    for _, posMap in pairs(self.SelectedResonanceSkillMap) do
        for _, isSelected in pairs(posMap) do
            if isSelected then
                count = count + 1
            end
        end
    end
    return count
end

-- 收集已选但未达成当前筛选目标的共鸣技能
---@return XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能数据
function XUiPanelAwarenessOneClickResonance:BuildUnachievedSelectedResonanceSkillList()
    local result = {}
    local characterId = self.Parent.CharacterId
    local awarenessSlotList = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessSlotList(characterId)

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local posMap = self.SelectedResonanceSkillMap[site]
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local isSelected = posMap and posMap[pos] == true
            local skillOptionIndex = pos == 1 and self.SkillTypeUpIndex or self.SkillTypeDownIndex
            local hasSkillOption = skillOptionIndex ~= DEFAULT_SELECT_INDEX
            if isSelected and hasSkillOption then
                local equipId = self.Parent.AwarenessEquipIdBySite[site]
                local equip = self._Control:GetEquip(equipId)
                local targetSlotData = awarenessSlotList[site]
                local targetResonanceData = targetSlotData and targetSlotData.ResonanceList and targetSlotData.ResonanceList[pos]
                local target = self:BuildResonanceTarget(pos, skillOptionIndex, targetResonanceData)
                local isUnachieved = self._Control.ResonanceControl:IsAwarenessResonanceTargetUnachieved(equip, target, characterId)
                if isUnachieved then
                    local resonanceInfo = equip:GetResonanceInfo(pos)
                    table.insert(result, {
                        CharacterId = characterId,
                        Site = site,
                        Pos = pos,
                        EquipId = equipId,
                        SuitId = equip:GetSuitId(),
                        Target = target,
                        IsResonanced = resonanceInfo ~= nil,
                    })
                end
            end
        end
    end

    return result
end

-- 将 UI 技能选项转换为 Control 使用的标准共鸣目标
---@param pos number 共鸣槽位
---@param skillOptionIndex number 共鸣技能筛选按钮组选项下标
---@param targetResonanceData table|nil 推荐目标共鸣数据
---@return XEquipAwarenessResonanceTarget
function XUiPanelAwarenessOneClickResonance:BuildResonanceTarget(pos, skillOptionIndex, targetResonanceData)
    return {
        Pos = pos,
        MatchMode = ResolveTargetMatchMode(skillOptionIndex),
        TargetType = targetResonanceData and targetResonanceData.ResonanceType or nil,
        TargetSkillId = targetResonanceData and targetResonanceData.SkillId or nil,
    }
end

-- 按最终共鸣预览上下文刷新材料格
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
function XUiPanelAwarenessOneClickResonance:RefreshChooseMaterialGridList(previewContext)
    local materialList = previewContext.MaterialList
    local tokenMinCostCountMap = previewContext.TokenMinCostCountMap
    local displayNeedCountMap = self:BuildMaterialDisplayNeedCountMap(previewContext)
    self.PanelChooseMaterial.gameObject:SetActiveEx(#materialList > 0)

    for index, data in ipairs(materialList) do
        local grid = self:GetOrCreateChooseMaterialGrid(index)
        local materialKey = data.MaterialKey
        local isSelected = self:IsChooseMaterialSelected(data)
        local isDisabled = IsChooseMaterialDisabled(data, tokenMinCostCountMap)
        local selectedCount = self:GetPreviewMaterialDisplaySelectedCount(previewContext, data)
        local displayNeedCount = displayNeedCountMap[materialKey] or 0
        grid:Open()
        grid:Refresh(data, isSelected, isDisabled, selectedCount, displayNeedCount)
    end

    for index = #materialList + 1, #self.ChooseMaterialGridPool do
        self.ChooseMaterialGridPool[index]:Close()
    end
end

-- 筛出不能由定向共鸣材料处理、仍需其他材料处理的目标。
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@param targetedMaterialData table 定向共鸣材料数据
---@return XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] remainingSkillList 剩余目标列表
function XUiPanelAwarenessOneClickResonance:BuildRemainingSkillList(previewContext, targetedMaterialData)
    local remainingSkillList = {}
    local resonanceControl = self._Control.ResonanceControl

    for _, skillData in ipairs(previewContext.UnachievedList) do
        local canUseTargetedMaterial = false
        if skillData.Target.MatchMode == TARGET_MATCH_MODE.TARGET then
            local equip = self._Control:GetEquip(skillData.EquipId)
            local isAvailable = resonanceControl:IsAwarenessResonanceCostAvailable(
                skillData.Target,
                targetedMaterialData
            )
            local costCount = resonanceControl:GetAwarenessResonanceCostCount(targetedMaterialData, equip)
            canUseTargetedMaterial = isAvailable and costCount and costCount > 0
        end

        if not canUseTargetedMaterial then
            remainingSkillList[#remainingSkillList + 1] = skillData
        end
    end

    return remainingSkillList
end

-- 排除定向共鸣材料后，复用现有两阶段规则预估剩余目标的材料消耗。
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@param remainingSkillList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 剩余目标列表
---@return table<string, number> 材料 Key 到预计消耗数量的映射
function XUiPanelAwarenessOneClickResonance:BuildRemainingSkillNeedCountMap(previewContext, remainingSkillList)
    local sourceMaterialData = previewContext.PreviewMaterialData
    local previewMaterialData = {
        NeedCountMap = {},
        SelectedCountMap = XTool.Clone(sourceMaterialData.SelectedCountMap),
        SelectedItemList = {},
    }

    for _, materialData in ipairs(sourceMaterialData.SelectedItemList) do
        if materialData.Type ~= RESONANCE_COST_TYPE.TARGETED then
            previewMaterialData.SelectedItemList[#previewMaterialData.SelectedItemList + 1] = materialData
        end
    end

    local previewSkillExistsMap = XTool.Clone(previewContext.PreviewSkillExistsMap)
    local firstSucceedMap, firstTargetReachedMap = self:PreviewFirstResonance(
        remainingSkillList,
        previewSkillExistsMap,
        previewMaterialData
    )
    self:PreviewRemainResonance(
        remainingSkillList,
        previewContext.TimesCount,
        firstSucceedMap,
        firstTargetReachedMap,
        previewMaterialData
    )

    return previewMaterialData.NeedCountMap
end

-- 构建材料格展示用的消耗数量，不修改实际预览或执行预算。
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@return table<string, number> 材料 Key 到展示消耗数量的映射
function XUiPanelAwarenessOneClickResonance:BuildMaterialDisplayNeedCountMap(previewContext)
    local previewMaterialData = previewContext.PreviewMaterialData
    if not previewMaterialData then
        return table.empty
    end

    local selectedCountMap = previewMaterialData.SelectedCountMap
    local targetedMaterialData
    for _, materialData in ipairs(previewContext.MaterialList) do
        local materialKey = materialData.MaterialKey
        local isSelectedTargetedMaterial = materialData.Type == RESONANCE_COST_TYPE.TARGETED
            and selectedCountMap[materialKey] ~= nil
        if isSelectedTargetedMaterial then
            targetedMaterialData = materialData
            break
        end
    end

    if targetedMaterialData then
        local remainingSkillList = self:BuildRemainingSkillList(previewContext, targetedMaterialData)
        local targetedSkillCount = #previewContext.UnachievedList - #remainingSkillList
        local targetedOwnedCount = targetedMaterialData.Count
        local isTargetedMaterialEnough = targetedSkillCount > 0
            and targetedOwnedCount >= targetedSkillCount
        local displayNeedCountMap
        if not isTargetedMaterialEnough then
            displayNeedCountMap = XTool.Clone(selectedCountMap)
        elseif #remainingSkillList == 0 then
            displayNeedCountMap = {}
        elseif previewContext.IsUntilTarget then
            displayNeedCountMap = XTool.Clone(selectedCountMap)
        else
            displayNeedCountMap = self:BuildRemainingSkillNeedCountMap(previewContext, remainingSkillList)
        end

        displayNeedCountMap[targetedMaterialData.MaterialKey] = math.min(targetedOwnedCount, targetedSkillCount)
        return displayNeedCountMap
    end

    if previewContext.IsUntilTarget then
        return XTool.Clone(selectedCountMap)
    end

    return XTool.Clone(previewContext.NeedCountMap)
end

-- 构建共鸣材料展示列表：
-- 1. 只使用未达成目标技能对应的意识，避免展示无效材料入口。
-- 2. 展示顺序保持与常规共鸣一致：定向材料 -> 随机材料 -> 意识材料。
-- 3. 每个入口在这里统一生成 MaterialKey，后续刷新和点击只读取该字段。
---@param unachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
---@param previewRemainItemCountDic table<number, number> 当前预览链路的剩余资源数量
---@return table<number, table> 共鸣材料展示数据列表
function XUiPanelAwarenessOneClickResonance:BuildChooseMaterialList(unachievedList, previewRemainItemCountDic)
    local result = {}
    local awarenessEquipIdBySite = {}
    local hasTargetSkillOption = false
    -- 道具材料按 ItemId 统一 Key，重复入口保留展示顺序最靠前的一项。
    local itemMaterialKeySet = {}
    for _, skillData in ipairs(unachievedList) do
        awarenessEquipIdBySite[skillData.Site] = skillData.EquipId
        if skillData.Target.MatchMode == TARGET_MATCH_MODE.TARGET then
            hasTargetSkillOption = true
        end
    end

    local function appendOwnedItemMaterial(costInfo)
        local materialInfo = XTool.Clone(costInfo)
        local materialKey = self:GetMaterialKey(materialInfo)
        if itemMaterialKeySet[materialKey] then
            return
        end

        local count = self:GetPreviewRemainItemCount(previewRemainItemCountDic, materialInfo.ItemId)
        if count <= 0 then return end

        materialInfo.Count = count
        materialInfo.MaterialKey = materialKey
        itemMaterialKeySet[materialKey] = true
        table.insert(result, materialInfo)
    end

    local costInfos, targetedCostInfo = self._Control.ResonanceControl:BuildAwarenessResonanceCostInfoList(awarenessEquipIdBySite)
    if targetedCostInfo and hasTargetSkillOption then
        appendOwnedItemMaterial(targetedCostInfo)
    end

    for _, costInfo in ipairs(costInfos) do
        if costInfo.Type == RESONANCE_COST_TYPE.TOKEN then
            appendOwnedItemMaterial(costInfo)
        elseif costInfo.Type == RESONANCE_COST_TYPE.AWARENESS and costInfo.Count > 0 then
            costInfo.MaterialKey = self:GetMaterialKey(costInfo)
            table.insert(result, costInfo)
        end
    end
    return result
end

-- 构建普通共鸣道具面对当前目标集合时的最低有效单次消耗。
---@param materialList table<number, table> 当前材料列表
---@param unachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标列表
---@return table<string, number> 普通共鸣道具 Key 到最低有效单次消耗的映射
function XUiPanelAwarenessOneClickResonance:BuildTokenMinCostCountMap(materialList, unachievedList)
    local result = {}
    local tokenMaterialList = {}
    for _, materialData in ipairs(materialList) do
        if materialData.Type == RESONANCE_COST_TYPE.TOKEN then
            table.insert(tokenMaterialList, materialData)
        end
    end

    if #tokenMaterialList <= 0 then
        return result
    end

    local resonanceControl = self._Control.ResonanceControl
    for _, skillData in ipairs(unachievedList) do
        local equip = self._Control:GetEquip(skillData.EquipId)
        for _, materialData in ipairs(tokenMaterialList) do
            local isAvailable = resonanceControl:IsAwarenessResonanceCostAvailable(skillData.Target, materialData)
            if isAvailable then
                local costCount = resonanceControl:GetAwarenessResonanceCostCount(materialData, equip)
                if costCount and costCount > 0 then
                    local materialKey = materialData.MaterialKey
                    local oldMinCostCount = result[materialKey]
                    if not oldMinCostCount or costCount < oldMinCostCount then
                        result[materialKey] = costCount
                    end
                end
            end
        end
    end

    return result
end

-- 从对象池获取材料格子，不足时按模板创建
---@param index number 格子序号
---@return XUiGridAwarenessOneClickResonanceMaterial
function XUiPanelAwarenessOneClickResonance:GetOrCreateChooseMaterialGrid(index)
    local grid = self.ChooseMaterialGridPool[index]
    if not grid then
        local ui = CSInstantiate(self.GridChooseMaterial, self.GridChooseMaterial.transform.parent)
        grid = XUiGridAwarenessOneClickResonanceMaterial.New(ui, self, self.Parent, function(data)
            self:OnChooseMaterialClick(data)
        end)
        self.ChooseMaterialGridPool[index] = grid
    end

    return grid
end

-- 根据消耗类型和关键配置生成稳定 Key，用于在刷新后恢复材料选中态
---@param data table 材料显示数据
---@return string 材料选择状态 Key
function XUiPanelAwarenessOneClickResonance:GetMaterialKey(data)
    -- 道具类材料统一按 ItemId 生成 Key，避免同一资源被拆成多个预算入口。
    if data.Type == RESONANCE_COST_TYPE.AWARENESS then
        return string.format("Awareness_%s", data.SuitId)
    end

    return string.format("Item_%s", data.ItemId)
end

-- 判断材料入口是否已选中；意识材料只要存在任一已选意识即视为选中
---@param data table 材料显示数据
---@return boolean 是否选中
function XUiPanelAwarenessOneClickResonance:IsChooseMaterialSelected(data)
    local materialKey = data.MaterialKey
    local selectedValue = self.SelectedMaterialMap[materialKey]
    if data.Type == RESONANCE_COST_TYPE.AWARENESS then
        return not XTool.IsTableEmpty(selectedValue)
    end

    return selectedValue == true
end

-- 统计当前材料入口已选中的消耗数量，用于刷新已选择数量显示。
---@param data table 材料显示数据
---@return number 已选中材料数量
function XUiPanelAwarenessOneClickResonance:GetChooseMaterialSelectedCount(data)
    local materialKey = data.MaterialKey
    local selectedValue = self.SelectedMaterialMap[materialKey]
    if not selectedValue then return 0 end

    if data.Type ~= RESONANCE_COST_TYPE.AWARENESS then
        return data.Count
    end

    local selectedCount = 0
    for _ in pairs(selectedValue) do
        selectedCount = selectedCount + 1
    end
    return selectedCount
end

---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext
---@param data table
---@return number
function XUiPanelAwarenessOneClickResonance:GetPreviewMaterialDisplaySelectedCount(previewContext, data)
    local previewMaterialData = previewContext.PreviewMaterialData
    if previewMaterialData then
        local selectedCount = previewMaterialData.SelectedCountMap[data.MaterialKey]
        if selectedCount ~= nil then
            return selectedCount
        end
    end

    return self:GetChooseMaterialSelectedCount(data)
end

-- 构建共鸣预览上下文，并先执行首次共鸣阶段
---@param unachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
---@param previewRemainItemCountDic table<number, number> 强化预览后的剩余资源数量
---@param materialList table<number, table>|nil 当前可展示的材料列表
---@return XUiPanelAwarenessOneClickResonancePreviewContext
function XUiPanelAwarenessOneClickResonance:BuildSelectedMaterialPreviewContext(unachievedList, previewRemainItemCountDic, materialList)
    local needCountMap = {}
    local previewSkillExistsMap = self:BuildCurrentSkillExistsMap()
    local timesCount = RESONANCE_TIMES_COUNT_BY_INDEX[self.TimesIndex] or 0
    local isUntilTarget = self.TimesIndex == RESONANCE_TIMES_INDEX.UNTIL_TARGET
    local currentMaterialList = materialList or self:BuildChooseMaterialList(unachievedList, previewRemainItemCountDic)
    local tokenMinCostCountMap = self:BuildTokenMinCostCountMap(currentMaterialList, unachievedList)
    self:RebuildSelectedMaterialMap(currentMaterialList, tokenMinCostCountMap)

    local previewContext = {
        UnachievedList = unachievedList,
        MaterialList = currentMaterialList,
        TokenMinCostCountMap = tokenMinCostCountMap,
        NeedCountMap = needCountMap,
        PreviewSkillExistsMap = previewSkillExistsMap,
        PreviewMaterialData = nil,
        FirstResonanceSucceedMap = {},
        FirstTargetReachedMap = {},
        FirstNeedCountMap = {},
        TimesCount = timesCount,
        IsUntilTarget = isUntilTarget,
        PreviewRemainItemCountDic = XTool.Clone(previewRemainItemCountDic),
    }

    if #unachievedList <= 0 or (timesCount <= 0 and not isUntilTarget) then
        return previewContext
    end

    local previewMaterialData = self:BuildPreviewMaterialData(currentMaterialList, needCountMap)
    previewContext.PreviewMaterialData = previewMaterialData
    previewContext.FirstResonanceSucceedMap, previewContext.FirstTargetReachedMap = self:PreviewFirstResonance(
        unachievedList,
        previewSkillExistsMap,
        previewMaterialData
    )
    previewContext.FirstNeedCountMap = XTool.Clone(needCountMap)
    previewContext.PreviewRemainItemCountDic = self:BuildPreviewRemainItemCountDic(previewContext, previewRemainItemCountDic)

    return previewContext
end

-- 构建进度弹窗和 Control 使用的共鸣执行结果，隔离 UI 预览上下文
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext
---@return XUiPanelAwarenessOneClickResonanceResult
function XUiPanelAwarenessOneClickResonance:BuildResonanceResult(previewContext)
    local taskList, materialBudget = self:BuildExecutionTaskList(previewContext)
    return {
        CharacterId = self.Parent.CharacterId,
        UnachievedList = previewContext.UnachievedList,
        TargetCount = #previewContext.UnachievedList,
        TimesCount = previewContext.TimesCount,
        IsUntilTarget = previewContext.IsUntilTarget,
        TargetMatchModeByPos = self:GetTargetMatchModeByPos(),
        TaskList = taskList,
        MaterialBudget = materialBudget,
    }
end

-- 构建本轮预估材料消耗上下文。
---@param materialList table<number, table> 当前可展示的材料列表
---@param needCountMap table<string, number> 材料 Key 到预计消耗数量的映射
---@return XUiPanelAwarenessOneClickResonancePreviewMaterialData 预估材料消耗上下文
function XUiPanelAwarenessOneClickResonance:BuildPreviewMaterialData(materialList, needCountMap)
    local previewMaterialData = {
        NeedCountMap = needCountMap,
        SelectedCountMap = {},
        SelectedItemList = {},
    }

    for _, data in ipairs(materialList) do
        if self:IsChooseMaterialSelected(data) then
            previewMaterialData.SelectedCountMap[data.MaterialKey] = self:GetChooseMaterialSelectedCount(data)
            if data.Type ~= RESONANCE_COST_TYPE.AWARENESS then
                table.insert(previewMaterialData.SelectedItemList, data)
            end
        end
    end

    return previewMaterialData
end

-- 按材料 Key 和单次消耗数量预估材料可支持的共鸣次数。
---@param materialKey string 材料 Key
---@param resonanceTimes number 预计共鸣次数
---@param costCount number 单次共鸣消耗数量
---@param previewMaterialData XUiPanelAwarenessOneClickResonancePreviewMaterialData 预估材料消耗上下文
---@return number 剩余未覆盖的共鸣次数
function XUiPanelAwarenessOneClickResonance:ConsumePreviewMaterialByTimes(materialKey, resonanceTimes, costCount, previewMaterialData)
    local needCountMap = previewMaterialData.NeedCountMap
    local selectedCountMap = previewMaterialData.SelectedCountMap
    local usedCount = needCountMap[materialKey] or 0
    local unusedCount = (selectedCountMap[materialKey] or 0) - usedCount
    if resonanceTimes <= 0 or unusedCount < costCount then
        return resonanceTimes
    end

    local useTimes = math.min(resonanceTimes, math.floor(unusedCount / costCount))
    needCountMap[materialKey] = usedCount + useTimes * costCount

    return resonanceTimes - useTimes
end

-- 按指定技能和共鸣次数预估材料消耗。
---@param skillData XUiPanelAwarenessOneClickResonanceUnachievedSkillData 未达成目标的已选共鸣技能数据
---@param resonanceTimes number 预计共鸣次数
---@param previewMaterialData XUiPanelAwarenessOneClickResonancePreviewMaterialData 预估材料消耗上下文
---@return number 剩余未覆盖的共鸣次数
---@return boolean 是否通过指定技能材料直接达成目标
function XUiPanelAwarenessOneClickResonance:ConsumePreviewMaterialBySkillData(skillData, resonanceTimes, previewMaterialData)
    if resonanceTimes <= 0 then
        return resonanceTimes, false
    end

    local awarenessMaterialKey = self:GetMaterialKey({
        Type = RESONANCE_COST_TYPE.AWARENESS,
        SuitId = skillData.SuitId,
    })

    local remainingTimes = self:ConsumePreviewMaterialByTimes(awarenessMaterialKey, resonanceTimes, 1, previewMaterialData)
    local selectedItemList = previewMaterialData.SelectedItemList
    if remainingTimes > 0 and #selectedItemList > 0 then
        local equip = self._Control:GetEquip(skillData.EquipId)
        local resonanceControl = self._Control.ResonanceControl
        for _, itemData in ipairs(selectedItemList) do
            if remainingTimes <= 0 then
                break
            end

            local isAvailable = resonanceControl:IsAwarenessResonanceCostAvailable(skillData.Target, itemData)
            local costCount = resonanceControl:GetAwarenessResonanceCostCount(itemData, equip)
            if isAvailable and costCount and costCount > 0 then
                local isSelectSkillCost = resonanceControl:IsAwarenessResonanceCostNeedSelectSkill(itemData)
                local consumeTimes = isSelectSkillCost and FIRST_RESONANCE_TIMES or remainingTimes
                local unresolvedTimes = self:ConsumePreviewMaterialByTimes(
                    itemData.MaterialKey,
                    consumeTimes,
                    costCount,
                    previewMaterialData
                )
                if isSelectSkillCost then
                    if unresolvedTimes <= 0 then
                        return 0, true
                    end
                else
                    remainingTimes = unresolvedTimes
                end
            end
        end
    end

    return remainingTimes, false
end

-- 预估未共鸣槽位优先获得一次共鸣技能的材料消耗。
---@param unachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
---@param previewSkillExistsMap table<number, table<number, boolean>> 预估后有共鸣技能的槽位映射
---@param previewMaterialData XUiPanelAwarenessOneClickResonancePreviewMaterialData 预估材料消耗上下文
---@return table<XUiPanelAwarenessOneClickResonanceUnachievedSkillData, boolean> 未共鸣槽位首次共鸣是否成功的映射
---@return table<XUiPanelAwarenessOneClickResonanceUnachievedSkillData, boolean> 首次共鸣是否通过指定技能材料直接达成目标的映射
function XUiPanelAwarenessOneClickResonance:PreviewFirstResonance(unachievedList, previewSkillExistsMap, previewMaterialData)
    local firstResonanceSucceedMap = {}
    local firstTargetReachedMap = {}

    for _, skillData in ipairs(unachievedList) do
        if not skillData.IsResonanced then
            local remainingTimes, isTargetReached = self:ConsumePreviewMaterialBySkillData(
                skillData,
                FIRST_RESONANCE_TIMES,
                previewMaterialData
            )
            local isFirstResonanceSucceed = remainingTimes <= 0
            firstResonanceSucceedMap[skillData] = isFirstResonanceSucceed
            firstTargetReachedMap[skillData] = isTargetReached
            if self.IsChoose and isFirstResonanceSucceed then
                previewSkillExistsMap[skillData.EquipId][skillData.Pos] = true
            end
        end
    end

    return firstResonanceSucceedMap, firstTargetReachedMap
end

-- 预估首次共鸣阶段后的剩余共鸣材料消耗。
---@param unachievedList XUiPanelAwarenessOneClickResonanceUnachievedSkillData[] 未达成目标的已选共鸣技能列表
---@param timesCount number 选择的共鸣次数
---@param firstResonanceSucceedMap table<XUiPanelAwarenessOneClickResonanceUnachievedSkillData, boolean> 未共鸣槽位首次共鸣是否成功的映射
---@param firstTargetReachedMap table<XUiPanelAwarenessOneClickResonanceUnachievedSkillData, boolean> 首次共鸣是否通过指定技能材料直接达成目标的映射
---@param previewMaterialData XUiPanelAwarenessOneClickResonancePreviewMaterialData 预估材料消耗上下文
function XUiPanelAwarenessOneClickResonance:PreviewRemainResonance(
        unachievedList, timesCount, firstResonanceSucceedMap, firstTargetReachedMap, previewMaterialData)
    for _, skillData in ipairs(unachievedList) do
        local resonanceTimes = timesCount
        if firstTargetReachedMap[skillData] then
            resonanceTimes = 0
        elseif not skillData.IsResonanced then
            resonanceTimes = firstResonanceSucceedMap[skillData] and timesCount - FIRST_RESONANCE_TIMES or 0
        end

        self:ConsumePreviewMaterialBySkillData(skillData, resonanceTimes, previewMaterialData)
    end
end

-- 构建进度弹窗可直接执行的共鸣任务列表。
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext
---@return XUiPanelAwarenessOneClickResonanceTask[]
---@return XUiPanelAwarenessOneClickResonanceMaterialBudget|nil
function XUiPanelAwarenessOneClickResonance:BuildExecutionTaskList(previewContext)
    if not previewContext.PreviewMaterialData then
        return {}, nil
    end

    local taskList = {}
    local materialBudget = self:BuildExecutionMaterialBudget(previewContext)

    -- 先补齐未共鸣槽位，再进入目标共鸣阶段，避免单个技能提前占完材料。
    for _, skillData in ipairs(previewContext.UnachievedList) do
        if not skillData.IsResonanced and self:CanTakeExecutionMaterial(skillData, materialBudget) then
            table.insert(taskList, self:BuildExecutionTask(skillData, FIRST_RESONANCE_TIMES, true))
        end
    end

    for _, skillData in ipairs(previewContext.UnachievedList) do
        local maxTimes = self:GetSkillDataExecutionMaxTimes(skillData, previewContext)
        if maxTimes > 0 and self:CanTakeExecutionMaterial(skillData, materialBudget) then
            table.insert(taskList, self:BuildExecutionTask(skillData, maxTimes, false))
        end
    end

    return taskList, materialBudget
end

---@param skillData XUiPanelAwarenessOneClickResonanceUnachievedSkillData
---@param maxTimes number
---@param isFirstResonance boolean
---@return XUiPanelAwarenessOneClickResonanceTask
function XUiPanelAwarenessOneClickResonance:BuildExecutionTask(skillData, maxTimes, isFirstResonance)
    return {
        EquipId = skillData.EquipId,
        Pos = skillData.Pos,
        Target = skillData.Target,
        AwarenessMaterialKey = self:GetMaterialKey({
            Type = RESONANCE_COST_TYPE.AWARENESS,
            SuitId = skillData.SuitId,
        }),
        MaxTimes = maxTimes,
        ExecutedTimes = 0,
        IsFirstResonance = isFirstResonance,
    }
end

---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext
---@return XUiPanelAwarenessOneClickResonanceMaterialBudget
function XUiPanelAwarenessOneClickResonance:BuildExecutionMaterialBudget(previewContext)
    -- 执行流程中共鸣早于超频，但 SelectedCountMap 已在超频预览后扣除了超频预留资源。
    -- 后续执行只能使用该预算，不能改为实时读取背包数量，否则会抢占超频材料。
    local selectedAwarenessIdListByKey = {}
    for _, data in ipairs(previewContext.MaterialList) do
        if data.Type == RESONANCE_COST_TYPE.AWARENESS then
            local selectedAwarenessIdMap = self.SelectedMaterialMap[data.MaterialKey]
            if not XTool.IsTableEmpty(selectedAwarenessIdMap) then
                local selectedAwarenessIdList = {}
                for _, equipId in ipairs(data.AwarenessIdList) do
                    if selectedAwarenessIdMap[equipId] then
                        table.insert(selectedAwarenessIdList, equipId)
                    end
                end

                if #selectedAwarenessIdList > 0 then
                    selectedAwarenessIdListByKey[data.MaterialKey] = selectedAwarenessIdList
                end
            end
        end
    end

    local displayMaterialList = {}
    for _, data in ipairs(previewContext.MaterialList) do
        if previewContext.PreviewMaterialData.SelectedCountMap[data.MaterialKey] ~= nil then
            table.insert(displayMaterialList, data)
        end
    end

    return {
        SelectedCountMap = XTool.Clone(previewContext.PreviewMaterialData.SelectedCountMap),
        SelectedAwarenessIdListByKey = selectedAwarenessIdListByKey,
        SelectedItemList = previewContext.PreviewMaterialData.SelectedItemList,
        DisplayMaterialList = displayMaterialList,
    }
end

---@param skillData XUiPanelAwarenessOneClickResonanceUnachievedSkillData
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext
---@return number
function XUiPanelAwarenessOneClickResonance:GetSkillDataExecutionMaxTimes(skillData, previewContext)
    if skillData.Target.MatchMode == TARGET_MATCH_MODE.ANY then
        return 0
    end

    if previewContext.IsUntilTarget then
        return math.huge
    end

    if not skillData.IsResonanced then
        return math.max(0, previewContext.TimesCount - FIRST_RESONANCE_TIMES)
    end

    return previewContext.TimesCount
end

---@param skillData XUiPanelAwarenessOneClickResonanceUnachievedSkillData
---@param materialBudget XUiPanelAwarenessOneClickResonanceMaterialBudget
---@return boolean
function XUiPanelAwarenessOneClickResonance:CanTakeExecutionMaterial(skillData, materialBudget)
    local awarenessMaterialKey = self:GetMaterialKey({
        Type = RESONANCE_COST_TYPE.AWARENESS,
        SuitId = skillData.SuitId,
    })
    local selectedAwarenessIdList = materialBudget.SelectedAwarenessIdListByKey[awarenessMaterialKey]
    if not XTool.IsTableEmpty(selectedAwarenessIdList) and (materialBudget.SelectedCountMap[awarenessMaterialKey] or 0) > 0 then
        return true
    end

    local equip = self._Control:GetEquip(skillData.EquipId)
    local resonanceControl = self._Control.ResonanceControl
    for _, itemData in ipairs(materialBudget.SelectedItemList) do
        if resonanceControl:IsAwarenessResonanceCostAvailable(skillData.Target, itemData) then
            local costCount = resonanceControl:GetAwarenessResonanceCostCount(itemData, equip)
            local remainCount = materialBudget.SelectedCountMap[itemData.MaterialKey] or 0
            if costCount and costCount > 0 and remainCount >= costCount then
                return true
            end
        end
    end

    return false
end

-- 在超频预览后继续消费共鸣预览上下文，同一个 previewContext 只应在单次父面板 RefreshPreview 链路中调用一次。
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@param previewRemainItemCountDic table<number, number> 超频预览后的剩余资源数量
function XUiPanelAwarenessOneClickResonance:ConsumeRemainResonancePreviewAfterOverclocking(previewContext, previewRemainItemCountDic)
    if not previewContext.PreviewMaterialData then
        return
    end

    self:ApplyPreviewRemainItemCountDicToMaterialData(previewContext, previewRemainItemCountDic)
    if previewContext.IsUntilTarget then
        return
    end

    self:PreviewRemainResonance(
        previewContext.UnachievedList,
        previewContext.TimesCount,
        previewContext.FirstResonanceSucceedMap,
        previewContext.FirstTargetReachedMap,
        previewContext.PreviewMaterialData
    )
end

-- 构建共鸣预览后剩余的资源数量，供超频或后续共鸣阶段作为资源预算
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@param previewRemainItemCountDic table<number, number> 共鸣前的剩余资源数量
---@return table<number, number> result 共鸣预览后的剩余资源数量
function XUiPanelAwarenessOneClickResonance:BuildPreviewRemainItemCountDic(previewContext, previewRemainItemCountDic)
    local result = XTool.Clone(previewRemainItemCountDic)
    if not self.IsChoose then
        return result
    end

    for _, data in ipairs(previewContext.MaterialList) do
        if data.Type ~= RESONANCE_COST_TYPE.AWARENESS then
            local needCount = previewContext.NeedCountMap[data.MaterialKey] or 0
            self:ConsumePreviewRemainItemCount(result, data.ItemId, needCount)
        end
    end

    return result
end

-- 构建超频后剩余共鸣预览后的资源数量，只扣除超频后追加预占的共鸣材料
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@param previewRemainItemCountDic table<number, number> 超频预览后的剩余资源数量
---@return table<number, number> result 剩余共鸣预览后的剩余资源数量
function XUiPanelAwarenessOneClickResonance:BuildPreviewRemainItemCountDicAfterOverclocking(previewContext, previewRemainItemCountDic)
    local result = XTool.Clone(previewRemainItemCountDic)
    if not self.IsChoose then
        return result
    end

    for _, data in ipairs(previewContext.MaterialList) do
        if data.Type ~= RESONANCE_COST_TYPE.AWARENESS then
            local materialKey = data.MaterialKey
            local totalNeedCount = previewContext.NeedCountMap[materialKey] or 0
            local firstNeedCount = previewContext.FirstNeedCountMap[materialKey] or 0
            local remainNeedCount = totalNeedCount - firstNeedCount
            self:ConsumePreviewRemainItemCount(result, data.ItemId, remainNeedCount)
        end
    end

    return result
end

-- 将超频后的剩余道具数量回写到共鸣材料预算，限制剩余共鸣阶段可继续占用的道具材料
---@param previewContext XUiPanelAwarenessOneClickResonancePreviewContext 共鸣预览上下文
---@param previewRemainItemCountDic table<number, number> 超频预览后的剩余资源数量
function XUiPanelAwarenessOneClickResonance:ApplyPreviewRemainItemCountDicToMaterialData(previewContext, previewRemainItemCountDic)
    if not self.IsChoose then
        return
    end

    local previewMaterialData = previewContext.PreviewMaterialData
    local selectedCountMap = previewMaterialData.SelectedCountMap
    for _, data in ipairs(previewContext.MaterialList) do
        if data.Type ~= RESONANCE_COST_TYPE.AWARENESS and selectedCountMap[data.MaterialKey] then
            local usedCount = previewContext.NeedCountMap[data.MaterialKey] or 0
            local remainCount = self:GetPreviewRemainItemCount(previewRemainItemCountDic, data.ItemId)
            selectedCountMap[data.MaterialKey] = usedCount + math.max(0, remainCount)
        end
    end
end

---@param previewRemainItemCountDic table<number, number>
---@param itemId number
---@return number
function XUiPanelAwarenessOneClickResonance:GetPreviewRemainItemCount(previewRemainItemCountDic, itemId)
    if previewRemainItemCountDic[itemId] ~= nil then
        return previewRemainItemCountDic[itemId]
    end

    return XDataCenter.ItemManager.GetCount(itemId)
end

---@param previewRemainItemCountDic table<number, number>
---@param itemId number
---@param count number
function XUiPanelAwarenessOneClickResonance:ConsumePreviewRemainItemCount(previewRemainItemCountDic, itemId, count)
    if not itemId or not count or count <= 0 then
        return
    end

    previewRemainItemCountDic[itemId] = self:GetPreviewRemainItemCount(previewRemainItemCountDic, itemId) - count
end

-- 构建当前已拥有共鸣技能的槽位状态。
---@return table<number, table<number, boolean>> 当前有共鸣技能的槽位映射
function XUiPanelAwarenessOneClickResonance:BuildCurrentSkillExistsMap()
    local result = {}

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = self.Parent.AwarenessEquipIdBySite[site]
        local equip = equipId and self._Control:GetEquip(equipId)
        if equip then
            local equipMap = {}
            result[equipId] = equipMap
            for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                equipMap[pos] = equip:GetResonanceInfo(pos) ~= nil
            end
        end
    end

    return result
end

-- 判断指定意识槽位在本轮预估共鸣后是否拥有共鸣技能。
---@param equipId number 意识装备 Id
---@param pos number 共鸣槽位
---@return boolean 是否预计拥有共鸣技能
function XUiPanelAwarenessOneClickResonance:IsPreviewSkillExists(equipId, pos)
    return self.PreviewSkillExistsMap[equipId][pos]
end

-- 按当前材料列表重建选中态；普通材料从角色缓存恢复，意识装备只保留本次界面内的选择。
---@param materialList table<number, table> 当前可展示材料列表
---@param tokenMinCostCountMap table<string, number> 普通共鸣道具最低有效单次消耗字典
function XUiPanelAwarenessOneClickResonance:RebuildSelectedMaterialMap(materialList, tokenMinCostCountMap)
    local oldSelectedMaterialMap = self.SelectedMaterialMap
    self.SelectedMaterialMap = {}

    for _, data in ipairs(materialList) do
        local materialKey = data.MaterialKey
        local isDisabled = IsChooseMaterialDisabled(data, tokenMinCostCountMap)
        if not isDisabled then
            if data.Type == RESONANCE_COST_TYPE.AWARENESS then
                local selectedValue = oldSelectedMaterialMap[materialKey]
                local selectedAwarenessIdMap = {}
                for _, equipId in ipairs(data.AwarenessIdList) do
                    if selectedValue and selectedValue[equipId] then
                        selectedAwarenessIdMap[equipId] = true
                    end
                end

                if next(selectedAwarenessIdMap) then
                    self.SelectedMaterialMap[materialKey] = selectedAwarenessIdMap
                end
            elseif self.SelectedItemIdMap[data.ItemId] then
                self.SelectedMaterialMap[materialKey] = true
            end
        end
    end
end

-- 点击材料格：普通材料直接切换，意识材料进入弹窗选择具体消耗意识
---@param data table 材料显示数据
function XUiPanelAwarenessOneClickResonance:OnChooseMaterialClick(data)
    local isDisabled = IsChooseMaterialDisabled(data, self.PreviewContext.TokenMinCostCountMap)
    if isDisabled then
        return
    end

    local materialKey = data.MaterialKey
    if data.Type == RESONANCE_COST_TYPE.AWARENESS then
        local selectedAwarenessIdMap = self.SelectedMaterialMap[materialKey]
        XLuaUiManager.Open("UiEquipChooseCostAwarenessPopup", data.AwarenessIdList, selectedAwarenessIdMap, function(selectedAwarenessIdMap)
            if XTool.IsTableEmpty(selectedAwarenessIdMap) then
                self.SelectedMaterialMap[materialKey] = nil
            else
                self.SelectedMaterialMap[materialKey] = selectedAwarenessIdMap
            end
            self.Parent:RefreshPreview()
        end)
    else
        if self.SelectedItemIdMap[data.ItemId] then
            self.SelectedItemIdMap[data.ItemId] = nil
        else
            self.SelectedItemIdMap[data.ItemId] = true
        end
        local settingControl = self._Control.OneClickAutoSettingControl
        local settingType = XMVCA.XEquip.Enum.OneClickAutoSettingType
        settingControl:SetCharacterSetting(self.Parent.CharacterId, settingType.AwarenessResonanceSelectedItemIdMap, self.SelectedItemIdMap)
        self.Parent:RefreshPreview()
    end
end

return XUiPanelAwarenessOneClickResonance
