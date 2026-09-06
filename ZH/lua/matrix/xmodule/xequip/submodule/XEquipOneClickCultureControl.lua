-- 武器一键养成子 Control：候选武器筛选、界面视图数据组装、预览计算、执行链
--
-- 两个界面的数据口径不同：
-- 【主页 UiEquipOneClickCultureDetailMain】—— 展示"养到最高等级需要的总消耗"（固定目标 = 满级）
--   入口：GetOneClickCultureViewData → _BuildModuleDataList → 三模块的 GetOneClickCultureXxxCostList（总消耗）
-- 【弹窗 UiEquipWeaponOneClickPopup】—— 展示"玩家当前材料能拉到多少"（动态 = 最高可达）
--   入口：CalcWeaponOneClickCulturePreview（升级用 SimulateWeaponMaxAchievablePreview 可达，
--        产出 result.LevelCostList 升级材料 + ResonanceCostList + OverrunCostList + 执行用 LevelPreview）
--        + StartWeaponOneClickCulture（执行链）

----------------------------------------
-- 数据结构
----------------------------------------

---@class XEquipOneClickCultureCostItem 一键养成消耗材料项（各模块 CostList 统一项结构）
---@field IsSpecial boolean 是否特殊材料区（经验/共鸣代币等）
---@field IsExp boolean|nil 是否经验项（特殊材料区，主界面用）
---@field IsWeaponMaterial boolean|nil 是否武器材料（吃武器获得的，非道具）
---@field ItemId number 道具/武器模板 Id
---@field NeedCount number 需求数量
---@field HaveCount number 持有数量（含兑换补足后的展示量）
---@field ExchangeCount number|nil 兑换补足到手量
---@field IsExchange boolean|nil 是否需通过兑换补足（持有不足且可兑换）
---@field Icon string|nil 图标路径（特殊材料区可占位）
---@field HaveText string|nil 持有文本（经验项等自定义展示）
---@field NeedText any|nil 需求文本

---@class XEquipOneClickCultureFeedItem 升级喂养材料项（吃掉的道具/装备，按模板归类）
---@field ItemId number 模板 Id
---@field Count number 选中消耗数
---@field IsEquip boolean 是否装备（否则道具）

---@class XEquipOneClickCultureResonanceSlot 共鸣槽位视图（主页 + 弹窗共用）
---@field Pos number 槽位（1..WEAPON_RESONANCE_COUNT）
---@field SkillId number 目标共鸣技能 Id
---@field IsComplete boolean 该槽目标技能是否已在武器当前共鸣中

---@class XEquipOneClickCultureModuleData 主页三模块视图项（等级/共鸣/谐振）
---@field Type number 模块类型（ONE_CLICK_CULTURE_MODULE_TYPE）
---@field Title string 标题
---@field IsComplete boolean 该模块是否已达成
---@field TabIndex number 对应 Tab 索引
---@field CostList XEquipOneClickCultureCostItem[] 该模块消耗列表

---@class XEquipOneClickCultureViewData 主界面视图数据
---@field EquipId number 武器实例 Id
---@field TemplateId number 武器模板 Id
---@field CharacterId number 装备角色 Id
---@field Level number 当前等级
---@field LevelLimit number 当前突破等级上限
---@field Breakthrough number 当前突破次数
---@field ResonanceList XEquipOneClickCultureResonanceSlot[] 共鸣槽位视图
---@field TargetResonanceCount number 目标共鸣技能数
---@field ResonanceCompleteCount number 已达成的目标共鸣数
---@field IsLevelComplete boolean 升级是否已满级
---@field IsResonanceComplete boolean 共鸣是否已全达成
---@field TargetSuitId number 谐振目标绑定意识套装 Id
---@field OverrunLevel number 当前谐振等级
---@field MaxOverrunLevel number 谐振总节点数
---@field IsOverrunLevelComplete boolean 谐振等级是否已满
---@field IsOverrunSuitComplete boolean 谐振绑定套装是否已达成
---@field IsOverrunComplete boolean 谐振是否已全部达成
---@field ModuleDataList XEquipOneClickCultureModuleData[] 三模块视图（总消耗）
---@field IsAllComplete boolean 三模块是否全部达成

---@class XEquipOneClickCultureOverrunLevelPreview 谐振等级节点预览（气泡展示用）
---@field Level number 谐振等级
---@field IsPreviewActive boolean 是否在本次目标等级内
---@field Title string 节点标题
---@field Desc string 节点描述
---@field AwarenessIcon string|nil 绑定意识图标

---@class XWeaponOneClickCultureArgs 一键养成预览入参（UI 收集勾选/交互态填入）
---@field EquipId number 武器实例 Id（实际由 TargetData 反查已穿戴，此处冗余保留兼容）
---@field TargetData table 养成方案数据
---@field IncludeLevel boolean 是否养成"升级与突破"
---@field IncludeResonance boolean 是否养成"共鸣"
---@field IncludeOverrun boolean 是否养成"谐振"
---@field AutoExchange boolean 是否自动兑换补足
---@field TargetOverrunLevel number|nil 谐振目标激活等级（nil=最高）
---@field ResonanceSkillMap table<number, boolean>|nil 选中的共鸣槽位（key=Pos，swap 后）
---@field ResonanceSelectedEquipMap table<number, boolean>|nil 全局手选的武器实例（equipId→bool，不分模板）
---@field ResonanceSelectedTokenCount number|nil 手选的共鸣代币数量（与武器共享首绑槽数上限）

---@class XWeaponOneClickCultureResult 一键养成预览结果（供 UI 展示 + 执行链使用）
---@field EquipId number 武器实例 Id
---@field LevelPreview table|nil 升级预览（SimulateWeaponMaxAchievablePreview 结果，含 FeedList/BreakList/AutoExchangeInfo/CostMoney）
---@field LevelCostList XEquipOneClickCultureCostItem[] 升级材料展示列表（喂养 + 突破，含兑换）
---@field ResonanceCostList XEquipOneClickCultureCostItem[] 共鸣材料
---@field OverrunCostList XEquipOneClickCultureCostItem[] 谐振材料
---@field ResonanceTaskList table[] 共鸣执行计划 { {Pos, SkillId, ResonanceType, UseEquipId|UseItemId}, ... }
---@field TotalCostMoney number 总螺母消耗
---@field IsEnough boolean 资源是否足够（含自动兑换补足后）
---@field IsLevelMaxed boolean 升级是否拉满（拉满后剩余代币才给谐振绑套装兑换）
---@field UsedTokenMap table<number, number> 升级兑换已消耗的代币（tokenId→消耗量，谐振用剩余）
---@field OverrunTokenCostMap table<number, number> 谐振兑换消耗的代币（tokenId→消耗量，与升级分开记）
---@field TargetOverrunLevel number|nil 谐振目标激活等级（执行链用）
---@field TargetData table 养成方案（执行链绑套装用）
---@field IncludeLevel boolean 是否勾选升级模块
---@field IncludeResonance boolean 是否勾选共鸣模块
---@field IncludeOverrun boolean 是否勾选谐振模块
---@field HasExecutableTask boolean 执行链是否非空（过滤前置兑换后，有实际养成动作）
---@field ResonanceChosen boolean 是否勾选共鸣模块且选了共鸣目标槽
---@field ResonanceMaterialEnough boolean 共鸣材料是否选够（手选武器 + 代币持有 >= 首绑槽数）
---@field ResonanceFirstBindCount number 首绑槽数（选武器上限）

---@class XWeaponOneClickCultureTask 执行链任务项
---@field Type number 任务类型（WeaponCultureTaskType）
---@field Id number|nil 兑换目标道具 Id（仅 Exchange 任务）

---@class XWeaponOneClickCultureTaskInfo 执行链任务信息
---@field Result XWeaponOneClickCultureResult 预览结果
---@field TaskList XWeaponOneClickCultureTask[] 任务列表
---@field Index number 当前执行索引

---@class XEquipOneClickCultureControl: XControl
---@field private _Model XEquipModel
---@field private _MainControl XEquipControl
---@field private _WeaponCultureTaskInfo XWeaponOneClickCultureTaskInfo|nil
---@field private _WeaponCultureCallbacks table|nil 阶段回调集合（onLevelStart/onResonanceStart/onOverrunStart/onAllDone/onAbort）
---@field private _WeaponCultureRunning boolean|nil 链路是否运行中（配对 TaskManager 同步事件开关）
local XEquipOneClickCultureControl = XClass(XControl, "XEquipOneClickCultureControl")

local ModuleType = XEnumConst.EQUIP.ONE_CLICK_CULTURE_MODULE_TYPE

-- 执行链任务类型，数值即执行顺序：先自动兑换补足，再升级/共鸣/谐振
local WeaponCultureTaskType = {
    Exchange = 1,
    Level = 2,
    Resonance = 3,
    Overrun = 4,
}

-- 会触发进度弹窗阶段动画的任务类型 → 弹窗单元 Key / 阶段回调名（Exchange 为静默前置，不触发）
local WeaponCultureTaskPhase = {
    [WeaponCultureTaskType.Level] = "Level",
    [WeaponCultureTaskType.Resonance] = "Resonance",
    [WeaponCultureTaskType.Overrun] = "Overrun",
}

----------------------------------------
-- 纯函数工具
----------------------------------------

---@param data table
---@param key string
---@return number
local function GetNumber(data, key)
    return data[key] or 0
end

--- 道具数量字典累加（countDic[itemId] += count，忽略无效增量）
---@param countDic table<number, number>
---@param itemId number|nil
---@param count number|nil
local function AddCost(countDic, itemId, count)
    if not XTool.IsNumberValid(itemId) or not count or count <= 0 then
        return
    end
    countDic[itemId] = (countDic[itemId] or 0) + count
end

--- 数量字典 → 按 Id 升序的 CostItem 数组（消除散落的 local {}+table.insert 三件套）
---@param countDic table<number, number>
---@param extraFieldGetter fun(itemId:number):table|nil 按 itemId 附加额外字段（IsExchange/HaveCount 等）
---@return XEquipOneClickCultureCostItem[]
local function BuildCostList(countDic, extraFieldGetter)
    local costList = {}
    for itemId, count in pairs(countDic or table.empty) do
        local item = { ItemId = itemId, NeedCount = count }
        if extraFieldGetter then
            local extra = extraFieldGetter(itemId, count)
            if extra then
                for k, v in pairs(extra) do
                    item[k] = v
                end
            end
        end
        table.insert(costList, item)
    end
    table.sort(costList, function(a, b) return (a.ItemId or 0) < (b.ItemId or 0) end)
    return costList
end

--- 材料是否足够：持有不足时，若开启自动兑换且该材料可兑换补足，则视为可满足
---@param costList XEquipOneClickCultureCostItem[]
---@param autoExchange boolean
---@return boolean
local function CheckCostEnough(costList, autoExchange)
    for _, cost in ipairs(costList or table.empty) do
        if (cost.HaveCount or 0) < (cost.NeedCount or 0) then
            local canExchange = autoExchange
                and XDataCenter.ItemManager.GetItemAutoExchangeInfo(cost.ItemId) ~= nil
            if not canExchange then
                return false
            end
        end
    end
    return true
end

--- 汇总升级自动兑换消耗的代币（tokenId → 消耗量），供谐振兑换判断剩余代币
---@param autoExchangeInfo table<number, table> SimulateWeaponMaxAchievablePreview 的 AutoExchangeInfo
---@return table<number, number> usedTokenMap tokenId -> 消耗量
local function SumExchangeConsumedTokens(autoExchangeInfo)
    local usedTokenMap = {}
    for _, info in pairs(autoExchangeInfo or table.empty) do
        for _, consume in ipairs(info.ConsumeList or table.empty) do
            local tokenId = consume.Id
            local count = consume.Count or 0
            if XTool.IsNumberValid(tokenId) and count > 0 then
                usedTokenMap[tokenId] = (usedTokenMap[tokenId] or 0) + count
            end
        end
    end
    return usedTokenMap
end

--- 五星及以下走属性共鸣，不绑角色、不支持定向选技能
---@param equip table 武器实例
---@return boolean
local function IsFiveStarWeapon(equip)
    local quality = XMVCA.XEquip:GetEquipQuality(equip.TemplateId)
    return quality ~= nil and quality <= XEnumConst.EQUIP.MIN_RESONANCE_EQUIP_STAR_COUNT
end

----------------------------------------
-- 候选武器与共鸣视图（主页+弹窗共用）
----------------------------------------

--- 养成模块排序：未完成在前、完成在后，同状态按类型升序（静态方法，无状态，便于单测）
---@param moduleDataList XEquipOneClickCultureModuleData[]
function XEquipOneClickCultureControl.SortModuleData(moduleDataList)
    table.sort(moduleDataList, function(moduleA, moduleB)
        if moduleA.IsComplete ~= moduleB.IsComplete then
            return not moduleA.IsComplete
        end
        return GetNumber(moduleA, "Type") < GetNumber(moduleB, "Type")
    end)
end

--- 取养成方案对应的武器实例 Id：选已穿戴的那把（需求保证目标武器一定有一把已穿戴）
---@param targetData table
---@return number|nil
function XEquipOneClickCultureControl:GetOneClickCultureEquipId(targetData)
    local weaponTemplateId = targetData and targetData.WeaponId
    if not XTool.IsNumberValid(weaponTemplateId) then
        XLog.Error("XEquipOneClickCultureControl.GetOneClickCultureEquipId: targetData.WeaponId 无效")
        return nil
    end

    -- 取该角色手上那把
    local characterId = targetData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        XLog.Error("XEquipOneClickCultureControl.GetOneClickCultureEquipId: targetData.CharacterId 无效")
        return nil
    end
    local equip = XMVCA.XEquip:GetCharacterWeapon(characterId)
    if not equip then
        XLog.Error("XEquipOneClickCultureControl.GetOneClickCultureEquipId: 角色未装备武器 characterId=" .. characterId)
        return nil
    end
    return equip.Id
end

----------------------------------------
-- 【主页】视图数据（总消耗，取养到满级的数据）
----------------------------------------

--- 组装一键养成主界面视图数据
---@param targetData table 养成方案数据
---@param isAutoExchange boolean 是否自动兑换补足
---@return XEquipOneClickCultureViewData|nil
function XEquipOneClickCultureControl:GetOneClickCultureViewData(targetData, isAutoExchange)
    local equipId = self:GetOneClickCultureEquipId(targetData)
    local equip = equipId and self._MainControl:GetEquip(equipId) or nil
    if not equip then
        return nil
    end

    local templateId = equip.TemplateId
    local strengthenControl = self._MainControl.StrengthenControl
    local targetSkillList = self:_BuildTargetSkillList(targetData)
    local targetSuitId = targetData.WeaponOverrunChoseSuit or 0

    -- 最高谐振等级 = 谐振配置总条数（含绑定档），当前等级用 equip 实际谐振等级
    local overrunCfgs = self._MainControl:GetWeaponOverrunCfgsByTemplateId(templateId, equip.CharacterId)
    local maxOverrunLevel = self:_CountOverrunLevel(overrunCfgs)
    local currentOverrunLevel = equip:GetOverrunLevel()
    local targetResonanceCount = self:_CountValidSkills(targetSkillList)
    local resonanceList, resonanceCompleteCount
    if IsFiveStarWeapon(equip) then
        resonanceList, resonanceCompleteCount = self:_BuildFiveStarResonanceStateList(equip, targetSkillList)
    else
        resonanceList, resonanceCompleteCount = XMVCA.XTeamRecommend:BuildWeaponResonanceTargetStateList(equipId, equip.CharacterId, targetSkillList)
    end

    local isLevelComplete = strengthenControl:GetEquipLevelUnit(equipId)
        >= strengthenControl:GetEquipMaxLevelUnit(templateId)
    local isResonanceComplete = resonanceCompleteCount >= targetResonanceCount
    local isOverrunConfigured = XTool.IsNumberValid(targetSuitId) and maxOverrunLevel > 0
    local isOverrunLevelComplete = not isOverrunConfigured or currentOverrunLevel >= maxOverrunLevel
    local isOverrunSuitComplete = not isOverrunConfigured or equip:GetOverrunChoseSuit() == targetSuitId
    local isOverrunComplete = isOverrunLevelComplete and isOverrunSuitComplete

    local moduleDataList = self:_BuildModuleDataList(equipId, templateId, targetData, isAutoExchange, {
        IsLevelComplete = isLevelComplete,
        IsResonanceComplete = isResonanceComplete,
        IsOverrunComplete = isOverrunComplete,
        MaxOverrunLevel = maxOverrunLevel,
        TargetResonanceCount = targetResonanceCount,
    })

    return {
        EquipId = equipId,
        TemplateId = templateId,
        CharacterId = equip.CharacterId,
        Level = equip.Level,
        LevelLimit = strengthenControl:GetBreakthroughLevelLimit(templateId, equip.Breakthrough),
        Breakthrough = equip.Breakthrough,
        ResonanceList = resonanceList,
        TargetResonanceCount = targetResonanceCount,
        ResonanceCompleteCount = resonanceCompleteCount,
        IsLevelComplete = isLevelComplete,
        IsResonanceComplete = isResonanceComplete,
        TargetSuitId = targetSuitId,
        OverrunLevel = equip:GetOverrunLevel(),
        MaxOverrunLevel = maxOverrunLevel,
        IsOverrunLevelComplete = isOverrunLevelComplete,
        IsOverrunSuitComplete = isOverrunSuitComplete,
        IsOverrunComplete = isOverrunComplete,
        ModuleDataList = moduleDataList,
        IsAllComplete = isLevelComplete and isResonanceComplete and isOverrunComplete,
    }
end

--- 从 targetData 抽取有效目标共鸣技能 Id 列表
---@param targetData table
---@return number[]
function XEquipOneClickCultureControl:_BuildTargetSkillList(targetData)
    local list = {}
    for _, resonance in ipairs(targetData and targetData.WeaponResonanceList or table.empty) do
        if XTool.IsNumberValid(resonance.SkillId) then
            table.insert(list, resonance.SkillId)
        end
    end
    return list
end

--- 统计有效目标共鸣技能数量
---@param skillList number[]
---@return number
function XEquipOneClickCultureControl:_CountValidSkills(skillList)
    local count = 0
    for _, skillId in ipairs(skillList or table.empty) do
        if XTool.IsNumberValid(skillId) then
            count = count + 1
        end
    end
    return count
end

--- 五星武器共鸣目标状态
---@param equip table 武器实例
---@param targetSkillList number[] 目标共鸣技能 Id 列表（按下标=槽位）
---@return table[] resonanceList
---@return number completeCount
function XEquipOneClickCultureControl:_BuildFiveStarResonanceStateList(equip, targetSkillList)
    local resonanceList = {}
    local completeCount = 0
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local targetSkillId = targetSkillList and targetSkillList[pos] or 0
        local isComplete = XTool.IsNumberValid(targetSkillId) and equip:GetResonanceInfo(pos) ~= nil
        if isComplete then
            completeCount = completeCount + 1
        end
        resonanceList[pos] = {
            Pos = pos,
            SkillId = targetSkillId,
            IsComplete = isComplete == true,
        }
    end
    return resonanceList, completeCount
end

--- 谐振总节点数 = 配置表条数
---@param overrunCfgs table
---@return number
function XEquipOneClickCultureControl:_CountOverrunLevel(overrunCfgs)
    local count = 0
    for _ in pairs(overrunCfgs or table.empty) do
        count = count + 1
    end
    return count
end

--- 组装 3 个养成模块（等级/共鸣/谐振）的视图数据并按状态排序
---@param equipId number
---@param templateId number
---@param targetData table
---@param isAutoExchange boolean
---@param completeState table 各模块完成态 + MaxOverrunLevel
---@return XEquipOneClickCultureModuleData[]
function XEquipOneClickCultureControl:_BuildModuleDataList(equipId, templateId, targetData, isAutoExchange, completeState)
    local strengthenControl = self._MainControl.StrengthenControl
    local maxLevel = select(2, strengthenControl:ConvertToBreakThroughAndLevel(
        templateId, strengthenControl:GetEquipMaxLevelUnit(templateId)))
    local targetSuitId = targetData.WeaponOverrunChoseSuit or 0
    local targetSuitName = XTool.IsNumberValid(targetSuitId) and self._MainControl:GetSuitName(targetSuitId) or ""
    local BtnIndex = XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX

    -- 先算升级 CostList，顺带拿到升级兑换代币 + 升级能否拉满（供谐振绑套装判断剩余代币）
    local levelCostList, usedTokenMap, isLevelMaxed = self:GetOneClickCultureLevelCostList(equipId, isAutoExchange)

    local moduleDataList = {}
    table.insert(moduleDataList, {
        Type = ModuleType.LEVEL,
        Title = CS.XTextManager.GetText("EquipOneClickCultureLevelTitle", maxLevel),
        IsComplete = completeState.IsLevelComplete,
        TabIndex = BtnIndex.STRENGTHEN,
        CostList = levelCostList,
    })
    -- 共鸣模块仅在养成计划配了共鸣技能时展示（没配则整栏不显示，而非显示完成态）
    if XTool.IsNumberValid(completeState.TargetResonanceCount) then
        table.insert(moduleDataList, {
            Type = ModuleType.RESONANCE,
            Title = CS.XTextManager.GetText("EquipOneClickCultureResonanceTitle"),
            IsComplete = completeState.IsResonanceComplete,
            TabIndex = BtnIndex.RESONANCE,
            CostList = self:GetOneClickCultureResonanceCostList(equipId, targetData, isAutoExchange, nil, true),
        })
    end
    -- 谐振模块仅在目标谐振等级 > 0 且配了目标套装时展示（无谐振配置的武器不显示该 PanelUnit）
    if XTool.IsNumberValid(targetSuitId) and XTool.IsNumberValid(completeState.MaxOverrunLevel) then
        table.insert(moduleDataList, {
            Type = ModuleType.OVERRUN,
            Title = CS.XTextManager.GetText("EquipOneClickCultureOverrunTitle", CS.XTextManager.GetText("WeaponOverrun" .. completeState.MaxOverrunLevel), targetSuitName),
            IsComplete = completeState.IsOverrunComplete,
            TabIndex = BtnIndex.OVERRUN,
            CostList = self:GetOneClickCultureOverrunCostList(equipId, targetData, isAutoExchange, nil, usedTokenMap, isLevelMaxed),
        })
    end
    self.SortModuleData(moduleDataList)
    return moduleDataList
end

----------------------------------------
-- 各模块消耗列表
----------------------------------------

--- 【主页】等级与突破模块消耗列表（CalcFullWeaponStrengthenPreviewCost = 养到满级的总消耗）
---@param equipId number
---@param isAutoExchange boolean
---@return XEquipOneClickCultureCostItem[] costList, table<number,number> usedTokenMap, boolean isLevelMaxed
function XEquipOneClickCultureControl:GetOneClickCultureLevelCostList(equipId, isAutoExchange)
    local strengthenControl = self._MainControl.StrengthenControl
    local totalExp, previewResult = strengthenControl:CalcFullWeaponStrengthenPreviewCost(
        equipId, { IsAutoExchangeEnabled = isAutoExchange == true })
    previewResult = previewResult or table.empty

    local costList = {}
    -- 经验项（特殊材料区）：图标由 prefab GridSpecial 自带，不加载；文本拼接，颜色按缺口经验判断
    local isExpEnough = (previewResult.LackExp or 0) <= 0
    table.insert(costList, {
        IsSpecial = true,
        IsExp = true,
        ItemId = XDataCenter.ItemManager.ItemId.WeaponStrengthenMaterial4,
        NeedCount = totalExp,
        HaveCount = isExpEnough and totalExp or 0,
        HaveText = CS.XTextManager.GetText("CharacterUpgradeSkillConsumeTitle"),
        NeedText = totalExp,
    })

    -- 突破材料项：HaveCount=真实持有，ExchangeCount=自动兑换补足到手量
    -- 兑换量以「最高可达」预览为准，可达预览按等级逐级推进分配，才是实际执行时的兑换顺序。需求量仍用满级口径。
    local autoExchangeInfo = previewResult.AutoExchangeInfo or table.empty
    if isAutoExchange then
        local reachablePreview = strengthenControl:SimulateWeaponMaxAchievablePreview(
            equipId,
            strengthenControl:GetAllConsumeItems(equipId, { ForceAutoSelect = true }),
            { IsAutoExchangeEnabled = true })
        autoExchangeInfo = reachablePreview and reachablePreview.AutoExchangeInfo or table.empty
    end
    for _, breakItem in ipairs(previewResult.BreakList or table.empty) do
        local itemId = breakItem.Id
        local need = breakItem.Count
        local have = XDataCenter.ItemManager.GetCount(itemId)
        local canExchange = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId) ~= nil
        local exchangeCount = 0
        if isAutoExchange and autoExchangeInfo[itemId] then
            exchangeCount = autoExchangeInfo[itemId].AvailableRewardCount or 0
        end
        table.insert(costList, {
            IsSpecial = false,
            ItemId = itemId,
            NeedCount = need,
            HaveCount = have,
            ExchangeCount = exchangeCount,
            IsExchange = have < need and canExchange,
        })
    end
    -- 升级能否拉满（材料/螺母/兑换消耗够升到满级）；口径同 IsStrengthenPreviewAchievable
    local isLevelMaxed
    if isAutoExchange then
        isLevelMaxed = previewResult.CanLevelUp ~= false
            and previewResult.CanBreakThroughCondition ~= false
            and previewResult.IsAutoExchangeConsumeEnough ~= false
    else
        isLevelMaxed = previewResult.CanLevelUp ~= false
            and previewResult.CanBreakThrough ~= false
            and previewResult.IsMoneyEnough ~= false
    end
    -- 返回：消耗列表 + 升级兑换代币 + 升级是否拉满（供主页谐振绑套装判断剩余代币）
    return costList, SumExchangeConsumedTokens(autoExchangeInfo), isLevelMaxed
end

--- 【弹窗】升级模块"最高可达"材料列表：喂养材料（吃掉的道具/装备）+ BreakList 突破材料
--- 私有：由 CalcWeaponOneClickCulturePreview 调用，结果存入 result.LevelCostList
---@param levelPreview table SimulateWeaponMaxAchievablePreview 结果（含 FeedList / BreakList / AutoExchangeInfo）
---@param isAutoExchange boolean
---@return XEquipOneClickCultureCostItem[]
function XEquipOneClickCultureControl:_BuildLevelReachableCostList(levelPreview, isAutoExchange)
    local costList = {}
    if not levelPreview then
        return costList
    end
    local autoExchangeInfo = levelPreview.AutoExchangeInfo or table.empty
    local expItemId = XDataCenter.ItemManager.ItemId.WeaponStrengthenMaterial4
    -- 喂养材料（实际选中吃掉的道具/装备）：NeedCount = 消耗数，持有即选中数（从持有里选的，恒够）
    -- 2/3/4 星武器按星级合并展示（只显该星级第一把，数量=该星级武器总数）；1 星隐藏，5 星+ 每模板原样
    local starGroup = {} -- star -> { ItemId, Count }
    for _, feed in ipairs(levelPreview.FeedList or table.empty) do
        local isWeaponFeed = feed.IsEquip == true
        local star = isWeaponFeed and self._MainControl:GetEquipStar(feed.ItemId) or 0
        if isWeaponFeed and star >= 2 and star <= 4 then
            local group = starGroup[star]
            if not group then
                group = { ItemId = feed.ItemId, Count = 0 }
                starGroup[star] = group
            end
            group.Count = group.Count + (feed.Count or 0)
        elseif not (isWeaponFeed and star < 2) then
            -- 经验道具自动兑换
            local exchangeCount = 0
            if not isWeaponFeed and feed.ItemId == expItemId
                and isAutoExchange and autoExchangeInfo[expItemId] then
                exchangeCount = autoExchangeInfo[expItemId].AvailableRewardCount or 0
            end
            table.insert(costList, {
                IsSpecial = false,
                IsWeaponMaterial = isWeaponFeed,
                ItemId = feed.ItemId,
                NeedCount = feed.Count,
                HaveCount = feed.Count,
                ExchangeCount = exchangeCount,
                SortKey = isWeaponFeed and 2 or 3, -- 武器材料=2，武器强化素材(道具)=3
                Star = isWeaponFeed and star or 0,
            })
        end
    end
    for star = 2, 4 do
        local group = starGroup[star]
        if group then
            table.insert(costList, {
                IsSpecial = false,
                IsWeaponMaterial = true,
                ItemId = group.ItemId,
                NeedCount = group.Count,
                HaveCount = group.Count,
                ExchangeCount = 0,
                SortKey = 2, -- 武器材料
                Star = star,
                IsStarMerged = true,
            })
        end
    end
    local autoExchangeInfo = levelPreview.AutoExchangeInfo or table.empty
    for _, breakItem in ipairs(levelPreview.BreakList or table.empty) do
        local itemId = breakItem.Id
        local exchangeCount = 0
        if isAutoExchange and autoExchangeInfo[itemId] then
            -- 按代币实际够的兑换量，不用不限量的 RewardCount
            exchangeCount = autoExchangeInfo[itemId].AvailableRewardCount or 0
        end
        table.insert(costList, {
            IsSpecial = false,
            ItemId = itemId,
            NeedCount = breakItem.Count,
            HaveCount = XDataCenter.ItemManager.GetCount(itemId),
            ExchangeCount = exchangeCount,
            SortKey = 1, -- 突破材料
        })
    end
    -- 排序：突破材料 > 武器材料 > 武器强化素材；星级小在前、大在后
    table.sort(costList, function(a, b)
        local ka, kb = a.SortKey or 99, b.SortKey or 99
        if ka ~= kb then
            return ka < kb
        end
        return (a.Star or 0) < (b.Star or 0)
    end)
    return costList
end

--- 汇总实际选中的喂养材料，按 模板+类型 归类
---@param consumes table[] SimulateWeaponMaxAchievablePreview 处理后的消耗池（SelectCount 已设）
---@return XEquipOneClickCultureFeedItem[]
function XEquipOneClickCultureControl:_BuildLevelFeedList(consumes)
    local groupDic = {}
    local feedList = {}
    for _, consume in ipairs(consumes or table.empty) do
        if consume:IsSelect() then
            local isEquip = consume:IsEquip()
            local key = (isEquip and "E_" or "I_") .. consume.TemplateId
            local group = groupDic[key]
            if not group then
                group = { ItemId = consume.TemplateId, Count = 0, IsEquip = isEquip }
                groupDic[key] = group
                table.insert(feedList, group)
            end
            group.Count = group.Count + consume.SelectCount
        end
    end
    return feedList
end

--- 共鸣目标技能按已共鸣槽位重排（swap）：若某槽真实共鸣的技能绑当前角色且是目标技能之一，
--- 把该目标技能移到它真实所在的槽，使玩家只需选剩余槽（已共鸣的显"已达成"、不消耗材料）
---@param equip table 武器实例
---@param targetData table 养成方案
---@return table[] swap 后 { [pos] = {SkillId, ResonanceType, IsComplete} }
function XEquipOneClickCultureControl:_BuildSwappedResonanceTargets(equip, targetData)
    local count = XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT
    local curCharacterId = equip.CharacterId
    local resonanceList = targetData.WeaponResonanceList or table.empty

    local targets = {}
    for pos = 1, count do
        local t = resonanceList[pos]
        targets[pos] = {
            SkillId = t and t.SkillId or 0,
            ResonanceType = t and t.ResonanceType,
        }
    end

    if not IsFiveStarWeapon(equip) then
        for pos = 1, count do
            local info = equip:GetResonanceInfo(pos)
            if info and info.CharacterId == curCharacterId and XTool.IsNumberValid(info.TemplateId) then
                for j = 1, count do
                    if j ~= pos and targets[j].SkillId == info.TemplateId then
                        targets[pos], targets[j] = targets[j], targets[pos]
                        break
                    end
                end
            end
        end
    end

    -- 标记已达成 + 补 ResonanceType
    local isFiveStar = IsFiveStarWeapon(equip)
    for pos = 1, count do
        local target = targets[pos]
        local info = equip:GetResonanceInfo(pos)
        if isFiveStar then
            target.IsComplete = XTool.IsNumberValid(target.SkillId) and info ~= nil
        else
            target.IsComplete = info ~= nil and info.CharacterId == curCharacterId
                and XTool.IsNumberValid(target.SkillId) and info.TemplateId == target.SkillId
        end
        if not target.ResonanceType and XTool.IsNumberValid(target.SkillId) then
            target.ResonanceType = XMVCA.XEquip:GuessResonanceType(target.SkillId, targetData.WeaponId)
        end
    end
    return targets
end

--- 构建共鸣执行计划：按选中槽（args.ResonanceSkillMap）逐槽产出请求项
--- 首绑槽（未绑当前角色）消耗武器/代币；换技能槽（已绑当前角色）不消耗
---@param equip table 武器实例
---@param args XWeaponOneClickCultureArgs
---@return table[] { {Pos, SkillId, ResonanceType, UseEquipId|UseItemId}, ... }
function XEquipOneClickCultureControl:_BuildResonanceExecPlan(equip, args)
    local count = XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT
    local curCharacterId = equip.CharacterId
    local targets = self:_BuildSwappedResonanceTargets(equip, args.TargetData)
    local skillMap = args.ResonanceSkillMap or table.empty

    -- 展开玩家全局手选的武器实例，作为首绑槽的消耗来源
    local weaponQueue = {}
    for eatEquipId, isSelected in pairs(args.ResonanceSelectedEquipMap or table.empty) do
        if isSelected then
            table.insert(weaponQueue, eatEquipId)
        end
    end
    local weaponIndex = 1
    -- 星级共鸣材料（武器不足时用代币，可用数=玩家手选代币数）
    local tokenItemId = self:_GetResonanceTokenItemId(equip.TemplateId)
    local tokenAvailable = args.ResonanceSelectedTokenCount or 0
    local tokenUsed = 0

    local taskList = {}
    for pos = 1, count do
        local target = targets[pos]
        -- 选中且未达成（已达成的不用再共鸣）
        if skillMap[pos] and not target.IsComplete and XTool.IsNumberValid(target.SkillId) then
            local task = {
                Pos = pos,
                SkillId = target.SkillId,
                ResonanceType = target.ResonanceType,
            }
            -- 首绑槽（该槽未绑当前角色）才消耗材料：优先用选中武器，武器不足且代币还有额度用代币
            local info = equip:GetResonanceInfo(pos)
            local isFirstBind = not (info and info.CharacterId == curCharacterId)
            if isFirstBind then
                local eatEquipId = weaponQueue[weaponIndex]
                if eatEquipId then
                    task.UseEquipId = eatEquipId
                    weaponIndex = weaponIndex + 1
                elseif XTool.IsNumberValid(tokenItemId) and tokenUsed < tokenAvailable then
                    task.UseItemId = tokenItemId
                    tokenUsed = tokenUsed + 1
                end
            end
            table.insert(taskList, task)
        end
    end
    return taskList
end

--- 统计首绑槽数：选中未达成、且该槽当前未绑当前角色的槽数（首绑才消耗材料）
---@param equip table 武器实例
---@param args XWeaponOneClickCultureArgs
---@return number
function XEquipOneClickCultureControl:_CountResonanceFirstBind(equip, args)
    local targets = self:_BuildSwappedResonanceTargets(equip, args.TargetData)
    local skillMap = args.ResonanceSkillMap or table.empty
    local firstBindCount = 0
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local target = targets[pos]
        if skillMap[pos] and not target.IsComplete and XTool.IsNumberValid(target.SkillId) then
            local info = equip:GetResonanceInfo(pos)
            if not (info and info.CharacterId == equip.CharacterId) then
                firstBindCount = firstBindCount + 1
            end
        end
    end
    return firstBindCount
end

--- 全局选中的武器数（一份 equipId→bool，不分模板）
---@param args XWeaponOneClickCultureArgs
---@return number
local function CountSelectedWeapon(args)
    local count = 0
    for _, isSelected in pairs(args.ResonanceSelectedEquipMap or table.empty) do
        if isSelected then
            count = count + 1
        end
    end
    return count
end

--- 共鸣材料是否选够：全局手选武器数 + 星级共鸣代币持有 >= 首绑槽数（换技能/已达成不消耗，无首绑则恒足）
---@param equip table 武器实例
---@param args XWeaponOneClickCultureArgs
---@return boolean
--- 取共鸣代币 itemId（EquipResonanceUseItem.ItemId[1]，不经 IsResonanceItemShowInTokenTab 过滤）
---@param templateId number 武器模板 Id
---@return number
function XEquipOneClickCultureControl:_GetResonanceTokenItemId(templateId)
    local config = self._MainControl:GetEquipResonanceUseItem(templateId)
    local itemIds = config and config.ItemId
    return (itemIds and itemIds[1]) or 0
end

function XEquipOneClickCultureControl:_IsResonanceMaterialEnough(equip, args)
    local firstBindCount = self:_CountResonanceFirstBind(equip, args)
    if firstBindCount <= 0 then
        return true
    end
    -- 选够 = 手选武器数 + 手选代币数 >= 首绑槽数
    return CountSelectedWeapon(args) + (args.ResonanceSelectedTokenCount or 0) >= firstBindCount
end


---@param isAutoExchange boolean
---@param selectedSkillMap table<number, boolean>|nil 选中的共鸣槽（弹窗按勾选算首绑数；主页 nil = 全部目标首绑）
---@return XEquipOneClickCultureCostItem[]
function XEquipOneClickCultureControl:GetOneClickCultureResonanceCostList(equipId, targetData, isAutoExchange, selectedSkillMap, mergeWeaponMaterial)
    local mainControl = self._MainControl
    local equip = mainControl:GetEquip(equipId)
    if not equip then
        return {}
    end
    local templateId = equip.TemplateId

    -- 共鸣材料需求 = 要新共鸣的目标槽里"首绑当前角色"的槽数（换技能/已达成不消耗材料）
    -- 弹窗只算勾选的槽（selectedSkillMap），主页 nil 时算全部目标槽（满配总需求）
    local targets = self:_BuildSwappedResonanceTargets(equip, targetData)
    local targetResonanceCount = 0
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local target = targets[pos]
        local isSelected = selectedSkillMap == nil or selectedSkillMap[pos] == true
        if isSelected and XTool.IsNumberValid(target.SkillId) and not target.IsComplete then
            local info = equip:GetResonanceInfo(pos)
            local isFirstBind = not (info and info.CharacterId == equip.CharacterId)
            if isFirstBind then
                targetResonanceCount = targetResonanceCount + 1
            end
        end
    end

    local costList = {}
    -- 道具材料（GridCostSpecial）：直接取 EquipResonanceUseItem 表的共鸣代币 ItemId（不经 IsResonanceItemShowInTokenTab 过滤，否则会被拦）
    local resonanceUseItem = mainControl:GetEquipResonanceUseItem(templateId)
    for _, itemId in ipairs(resonanceUseItem and resonanceUseItem.ItemId or table.empty) do
        table.insert(costList, {
            IsSpecial = true,
            ItemId = itemId,
            NeedCount = targetResonanceCount,
            HaveCount = XDataCenter.ItemManager.GetCount(itemId),
        })
    end

    -- 武器材料（GridCost）：可吃武器候选列表
    local candidateIds = mainControl:GetWeaponResonanceCanEatEquipIds(equipId)
    if mergeWeaponMaterial then
        -- 主页合并展示：只显第一把武器，数量=所有可吃武器合并总数
        if #candidateIds > 0 then
            local firstEquip = mainControl:GetEquip(candidateIds[1])
            if firstEquip then
                table.insert(costList, {
                    IsSpecial = false,
                    IsWeaponMaterial = true,
                    ItemId = firstEquip.TemplateId,
                    NeedCount = targetResonanceCount,
                    HaveCount = #candidateIds,
                })
            end
        end
    else
        -- 弹窗按武器模板归类，每模板一格
        local weaponCountByTemplate = {}
        for _, candidateEquipId in ipairs(candidateIds) do
            local candidateEquip = mainControl:GetEquip(candidateEquipId)
            if candidateEquip then
                AddCost(weaponCountByTemplate, candidateEquip.TemplateId, 1)
            end
        end
        for _, item in ipairs(BuildCostList(weaponCountByTemplate, function(itemId)
            return {
                IsSpecial = false,
                IsWeaponMaterial = true,
                NeedCount = targetResonanceCount,
                HaveCount = weaponCountByTemplate[itemId],
            }
        end)) do
            table.insert(costList, item)
        end
    end
    return costList
end

--- 【主页+弹窗】谐振模块消耗列表：累加"当前谐振等级 → 目标激活等级"之间各档的激活材料 + 绑定意识材料
--- 激活材料（非 SUIT）看持有、不可兑换；绑套装材料（SUIT）勾选自动兑换且升级拉满时用剩余代币算 ExchangeCount
---@param equipId number
---@param targetData table
---@param isAutoExchange boolean
---@param targetOverrunLevel number|nil 目标激活到的等级；nil 表示到最高（全部剩余）
---@param usedTokenMap table<number, number>|nil 升级兑换已占用的代币
---@param isLevelMaxed boolean|nil 升级是否拉满（拉满才允许绑套装用剩余代币兑换）
---@return XEquipOneClickCultureCostItem[]
function XEquipOneClickCultureControl:GetOneClickCultureOverrunCostList(equipId, targetData, isAutoExchange, targetOverrunLevel, usedTokenMap, isLevelMaxed)
    local mainControl = self._MainControl
    local equip = mainControl:GetEquip(equipId)
    if not equip then
        return {}
    end
    local overrunCfgs = mainControl:GetWeaponOverrunCfgsByTemplateId(equip.TemplateId, equip.CharacterId)
    local currentLevel = equip:GetOverrunLevel()
    local targetLevel = targetOverrunLevel or math.maxinteger

    -- 累加"要新激活"的档：激活材料（所有档 ConsumeItemIds）看持有；绑套装材料（SUIT 的 ActiveSuitItemId）走剩余代币兑换
    local SUIT = XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT
    -- 目标套装是否已激活
    local targetSuitId = targetData and targetData.WeaponOverrunChoseSuit or 0
    local needActivateSuit = XTool.IsNumberValid(targetSuitId)
        and not self:IsOverrunSuitActivated(equipId, targetSuitId)
    local activeCostDic = {}
    local suitCostDic = {}
    local cfgCount = 0
    for _, cfg in pairs(overrunCfgs or table.empty) do
        cfgCount = cfgCount + 1
        local cfgLevel = cfg.Level or 0
        local isNewLevel = cfgLevel > currentLevel and cfgLevel <= targetLevel
        -- SUIT 档：等级已升过但目标套装未激活时，补激活材料
        local isSuitToActivate = cfg.OverrunType == SUIT and needActivateSuit and cfgLevel <= targetLevel
        if isNewLevel then
            -- 升级材料（不可兑换）：所有档都有 ConsumeItemIds
            local consumeIds = cfg.ConsumeItemIds
            local consumeCounts = cfg.ConsumeItemCounts
            if consumeIds and consumeCounts then
                for i = 1, #consumeIds do
                    AddCost(activeCostDic, consumeIds[i], consumeCounts[i])
                end
            end
        end
        -- 激活套装材料（可兑换）
        if cfg.OverrunType == SUIT and (isNewLevel or isSuitToActivate) then
            AddCost(suitCostDic, cfg.ActiveSuitItemId, cfg.ActiveSuitItemCount)
        end
    end
    if cfgCount <= 0 then
        return {}
    end

    -- 激活材料：看持有，不可兑换（ExchangeCount=0）
    local costList = BuildCostList(activeCostDic, function(itemId, count)
        return {
            IsSpecial = false,
            HaveCount = XDataCenter.ItemManager.GetCount(itemId),
            ExchangeCount = 0,
            IsExchange = false,
        }
    end)
    -- 绑套装材料：勾选自动兑换且升级拉满时，用剩余代币算 ExchangeCount（展示兑换补足量）；标记 IsSuitBind
    for _, item in ipairs(BuildCostList(suitCostDic, function(itemId, count)
        local canExchange = isAutoExchange == true and isLevelMaxed == true
        local exchangeCount = canExchange and self:_CalcSuitExchangeGain(itemId, count, usedTokenMap) or 0
        return {
            IsSpecial = false,
            HaveCount = XDataCenter.ItemManager.GetCount(itemId),
            ExchangeCount = exchangeCount,
            IsExchange = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId) ~= nil,
            IsSuitBind = true,
        }
    end)) do
        table.insert(costList, item)
    end
    return costList
end

----------------------------------------
-- 【弹窗】最高可达预览（算玩家材料能拉到多少）
----------------------------------------

--- 一键养成聚合预览：按勾选的模块汇总消耗（升级用 SimulateWeaponMaxAchievablePreview）
---@param args XWeaponOneClickCultureArgs
---@return XWeaponOneClickCultureResult
function XEquipOneClickCultureControl:CalcWeaponOneClickCulturePreview(args)
    local mainControl = self._MainControl
    local strengthenControl = mainControl.StrengthenControl
    local equipId = self:GetOneClickCultureEquipId(args.TargetData)

    local result = {
        EquipId = equipId,
        LevelPreview = nil,
        LevelCostList = {},
        ResonanceCostList = {},
        OverrunCostList = {},
        ResonanceTaskList = {},
        TotalCostMoney = 0,
        IsEnough = true,
        IsLevelMaxed = args.IncludeLevel ~= true,
        UsedTokenMap = {},
        OverrunTokenCostMap = {},
        -- 执行链用：谐振目标等级 + 养成方案
        TargetOverrunLevel = args.TargetOverrunLevel,
        TargetData = args.TargetData,
        -- 各模块是否勾选（BtnChoose），入链前提
        IncludeLevel = args.IncludeLevel == true,
        IncludeResonance = args.IncludeResonance == true,
        IncludeOverrun = args.IncludeOverrun == true,
    }
    if not XTool.IsNumberValid(equipId) then
        result.IsEnough = false
        return result
    end

    -- 升级与突破：用武器最高可达预览（含突破材料/经验/螺母/自动兑换信息）
    local levelPreview = nil
    local consumes = strengthenControl:GetAllConsumeItems(equipId, { ForceAutoSelect = true })
    levelPreview = strengthenControl:SimulateWeaponMaxAchievablePreview(
        equipId, consumes, { IsAutoExchangeEnabled = args.AutoExchange == true })
    result.LevelPreview = levelPreview
    if levelPreview then
        -- 汇总实际选中的喂养材料 + 构建升级材料展示列表（喂养 + 突破，含兑换）
        levelPreview.FeedList = self:_BuildLevelFeedList(consumes)
        result.LevelCostList = self:_BuildLevelReachableCostList(levelPreview, args.AutoExchange)
    end

    -- 升级参与养成时：螺母/是否足够/升级拉满/兑换代币 才计入（执行与校验口径）
    if args.IncludeLevel and levelPreview then
        result.TotalCostMoney = result.TotalCostMoney + (levelPreview.CostMoney or 0)
        -- 升级是否拉满（拉满后剩余代币才给谐振绑套装兑换）+ 升级兑换消耗的代币（谐振用剩余）
        local equip = mainControl:GetEquip(equipId)
        local templateId = equip and equip.TemplateId or 0
        result.IsLevelMaxed = XTool.IsNumberValid(templateId)
            and levelPreview.TargetLevelUnit >= strengthenControl:GetEquipMaxLevelUnit(templateId)
        result.UsedTokenMap = SumExchangeConsumedTokens(levelPreview.AutoExchangeInfo)
    end

    -- 共鸣：材料列表 + 逐槽执行计划（首绑槽消耗武器/代币）
    if args.IncludeResonance then
        -- 按勾选的槽算材料需求（与执行计划口径一致，避免 IsEnough 误判）
        result.ResonanceCostList = self:GetOneClickCultureResonanceCostList(equipId, args.TargetData, args.AutoExchange, args.ResonanceSkillMap, true)
        local equip = mainControl:GetEquip(equipId)
        if equip then
            result.ResonanceTaskList = self:_BuildResonanceExecPlan(equip, args)
        end
    end

    -- 谐振：材料列表（绑套装兑换用升级后剩余代币）
    if args.IncludeOverrun then
        result.OverrunCostList = self:GetOneClickCultureOverrunCostList(equipId, args.TargetData, args.AutoExchange,
            args.TargetOverrunLevel, result.UsedTokenMap, result.IsLevelMaxed)
        -- 谐振兑换实际消耗的代币
        result.OverrunTokenCostMap = self:_SumOverrunExchangeTokenCost(result.OverrunCostList)
    end

    -- 确认按钮检测：执行链是否非空（过滤前置兑换）、是否选了共鸣目标、共鸣材料是否选够
    local execTaskList = self:_BuildWeaponCultureTaskList(result)
    result.HasExecutableTask = false
    for _, task in ipairs(execTaskList) do
        if task.Type ~= WeaponCultureTaskType.Exchange then
            result.HasExecutableTask = true
            break
        end
    end
    local equip = mainControl:GetEquip(equipId)
    result.ResonanceChosen = args.IncludeResonance == true and next(args.ResonanceSkillMap or table.empty) ~= nil
    result.ResonanceMaterialEnough = equip == nil or self:_IsResonanceMaterialEnough(equip, args)
    -- 选武器上限 = 首绑槽数（要新绑角色的槽数，全局武器+代币按此判够）
    result.ResonanceFirstBindCount = equip and self:_CountResonanceFirstBind(equip, args) or 0

    return result
end

--- 把一条兑换明细并入汇总表
---@param exchangeInfoMap table<number, table>
---@param itemId number
---@param rewardCount number 本次兑换获得的数量
---@param consumeList table[] { Id, Count }
local function MergeExchangeEntry(exchangeInfoMap, itemId, rewardCount, consumeList)
    if not XTool.IsNumberValid(itemId) or (rewardCount or 0) <= 0 then
        return
    end
    local mergedInfo = exchangeInfoMap[itemId]
    if not mergedInfo then
        mergedInfo = { ItemId = itemId, RewardCount = 0, ConsumeCountMap = {} }
        exchangeInfoMap[itemId] = mergedInfo
    end
    mergedInfo.RewardCount = mergedInfo.RewardCount + rewardCount
    for _, consume in ipairs(consumeList or table.empty) do
        mergedInfo.ConsumeCountMap[consume.Id] = (mergedInfo.ConsumeCountMap[consume.Id] or 0) + consume.Count
    end
end

--- 升级阶段：兑换明细由 AutoExchangeInfo 直接给出
local function MergeLevelAutoExchange(exchangeInfoMap, levelPreview)
    for _, exchangeInfo in pairs(levelPreview and levelPreview.AutoExchangeInfo or table.empty) do
        if (exchangeInfo.ExchangeTimes or 0) > 0 then
            MergeExchangeEntry(exchangeInfoMap, exchangeInfo.ItemId, exchangeInfo.RewardCount, exchangeInfo.ConsumeList)
        end
    end
end

--- 谐振阶段：兑换需求记在 CostList 的 ExchangeCount 上，按商店配置折算消耗
local function MergeCostListExchange(exchangeInfoMap, costList)
    for _, cost in ipairs(costList or table.empty) do
        local exchangeCount = cost.ExchangeCount or 0
        if exchangeCount > 0 then
            local info = XDataCenter.ItemManager.GetItemAutoExchangeInfo(cost.ItemId)
            local rewardPerTime = info and info.RewardCountList and info.RewardCountList[1] or 0
            if rewardPerTime > 0 then
                local times = math.ceil(exchangeCount / rewardPerTime)
                local consumeList = {}
                for _, consume in ipairs(info.ConsumeList[1] or table.empty) do
                    table.insert(consumeList, {
                        Id = consume.ConsumeId,
                        Count = (consume.ConsumeCount or 0) * times,
                    })
                end
                MergeExchangeEntry(exchangeInfoMap, cost.ItemId, rewardPerTime * times, consumeList)
            end
        end
    end
end

--- 汇总本次养成会触发的全部自动兑换明细（仅升级与谐振会兑换，共鸣不涉及）
---@param result table CalcWeaponOneClickCulturePreview 的结果
---@return table[] exchangeList { ItemId, RewardCount, ConsumeList }
function XEquipOneClickCultureControl:BuildWeaponCultureAutoExchangeList(result)
    if not result then
        return table.empty
    end
    local exchangeInfoMap = {}
    MergeLevelAutoExchange(exchangeInfoMap, result.LevelPreview)
    MergeCostListExchange(exchangeInfoMap, result.OverrunCostList)

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

--- 判断谐振能否叠加到指定等级（该等级所需材料是否足够，含自动兑换补足）
---@param equipId number
---@param targetData table
---@param targetLevel number
--- 判断谐振能否叠加到指定等级
--- 激活材料（非 SUIT）：看持有，不可兑换
--- 绑套装材料（SUIT）：需绑且升级拉满时，用剩余代币兑换判断（代币 = 持有 - usedTokenMap）
---@param equipId number
---@param targetData table
---@param targetLevel number
---@param autoExchange boolean
---@param usedTokenMap table<number, number>|nil 升级兑换已占用的代币
---@param isLevelMaxed boolean|nil 升级是否拉满（拉满才允许谐振动用代币）
---@return boolean
function XEquipOneClickCultureControl:IsOverrunLevelReachable(equipId, targetData, targetLevel, autoExchange, usedTokenMap, isLevelMaxed)
    local costList = self:GetOneClickCultureOverrunCostList(equipId, targetData, autoExchange, targetLevel, usedTokenMap, isLevelMaxed)
    -- 激活材料（非 IsSuitBind）：只看持有，不可兑换（强制 autoExchange=false 避免 CheckCostEnough 误判有兑换路线）
    local activeCostList = {}
    local suitCostList = {}
    for _, cost in ipairs(costList) do
        if cost.IsSuitBind then
            table.insert(suitCostList, cost)
        else
            table.insert(activeCostList, cost)
        end
    end
    if not CheckCostEnough(activeCostList, false) then
        return false
    end

    -- 绑套装材料：不需要绑则跳过；需要绑则用剩余代币兑换判断（代币 = 持有 - usedTokenMap）
    local equip = self._MainControl:GetEquip(equipId)
    local targetSuitId = targetData and targetData.WeaponOverrunChoseSuit or 0
    local currentSuitId = equip and equip:GetOverrunChoseSuit() or 0
    local needBindSuit = XTool.IsNumberValid(targetSuitId) and currentSuitId ~= targetSuitId
    if not needBindSuit then
        return true
    end
    for _, cost in ipairs(suitCostList) do
        if not self:_IsSuitMaterialExchangeEnough(cost.ItemId, cost.NeedCount, usedTokenMap) then
            return false
        end
    end
    return true
end

--- 取 SUIT 档绑套装材料消耗（ActiveSuitItemId/Count，目标套装绑定所需）
---@param equipId number
---@param targetData table
---@return {ItemId:number, NeedCount:number}|nil
function XEquipOneClickCultureControl:_GetOverrunSuitBindCost(equipId, targetData)
    local equip = self._MainControl:GetEquip(equipId)
    if not equip then
        return nil
    end
    local cfgs = self._MainControl:GetWeaponOverrunCfgsByTemplateId(equip.TemplateId, equip.CharacterId)
    local SUIT = XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT
    for _, cfg in pairs(cfgs or table.empty) do
        if cfg.OverrunType == SUIT and XTool.IsNumberValid(cfg.ActiveSuitItemId) then
            return { ItemId = cfg.ActiveSuitItemId, NeedCount = cfg.ActiveSuitItemCount or 0 }
        end
    end
    return nil
end

--- 目标意识套装是否已激活（在武器的 ActiveSuits 里）
---@param equipId number
---@param targetSuitId number 目标套装 Id
---@return boolean
function XEquipOneClickCultureControl:IsOverrunSuitActivated(equipId, targetSuitId)
    if not XTool.IsNumberValid(targetSuitId) then
        return false
    end
    local equip = self._MainControl:GetEquip(equipId)
    if not equip then
        return false
    end
    for _, suitId in pairs(equip:GetOverrunActiveSuits() or table.empty) do
        if suitId == targetSuitId then
            return true
        end
    end
    return false
end

--- 谐振等级是否已满（当前等级 >= 谐振总节点数）
---@param equipId number
---@param targetData table 养成方案
---@return boolean
function XEquipOneClickCultureControl:IsOverrunLevelFull(equipId, targetData)
    local equip = self._MainControl:GetEquip(equipId)
    if not equip then
        return false
    end
    local cfgs = self._MainControl:GetWeaponOverrunCfgsByTemplateId(equip.TemplateId, equip.CharacterId)
    local maxLevel = self:_CountOverrunLevel(cfgs)
    return (equip:GetOverrunLevel() or 0) >= maxLevel
end

--- 目标套装能否绑定：已绑则无需操作；已激活则只 Chose（不消耗代币）；未激活则需 Active 激活（消耗代币，用剩余代币兑换激活材料判断）
---@param equipId number
---@param targetData table
---@param usedTokenMap table<number, number>|nil
---@param isLevelMaxed boolean|nil
---@return boolean
function XEquipOneClickCultureControl:_IsOverrunSuitBindable(equipId, targetData, usedTokenMap, isLevelMaxed)
    local equip = self._MainControl:GetEquip(equipId)
    local targetSuitId = targetData and targetData.WeaponOverrunChoseSuit or 0
    local currentSuitId = equip and equip:GetOverrunChoseSuit() or 0
    local needBindSuit = XTool.IsNumberValid(targetSuitId) and currentSuitId ~= targetSuitId
    if not needBindSuit then
        return true
    end
    if self:IsOverrunSuitActivated(equipId, targetSuitId) then
        return true
    end
    local suitCost = self:_GetOverrunSuitBindCost(equipId, targetData)
    if not suitCost then
        return true
    end
    return self:_IsSuitMaterialExchangeEnough(suitCost.ItemId, suitCost.NeedCount, usedTokenMap)
end

--- 谐振步进器状态 flags（供 UI 算加号 Disable / 预览文本 / BgTitle）
---@param equipId number
---@param targetData table
---@param nextLevel number 下一级等级（步进器等级 + 1）
---@param autoExchange boolean
---@param usedTokenMap table<number, number>|nil
---@param isLevelMaxed boolean|nil
---@return table { CanUpdate, CanActivate, IsActivate, CanBind, NeedBindSuit }
function XEquipOneClickCultureControl:_GetOverrunStepFlags(equipId, targetData, nextLevel, autoExchange, usedTokenMap, isLevelMaxed)
    local equip = self._MainControl:GetEquip(equipId)
    local targetSuitId = targetData and targetData.WeaponOverrunChoseSuit or 0
    local currentSuitId = equip and equip:GetOverrunChoseSuit() or 0
    local needBindSuit = XTool.IsNumberValid(targetSuitId) and currentSuitId ~= targetSuitId

    -- IsActivate: 目标套装已激活（在 ActiveSuits 里）
    local isActivate = self:IsOverrunSuitActivated(equipId, targetSuitId)

    -- CanUpdate: 下一级升级材料（激活材料，非 IsSuitBind）持有够
    local canUpdate = true
    local costList = self:GetOneClickCultureOverrunCostList(equipId, targetData, autoExchange, nextLevel, usedTokenMap, isLevelMaxed)
    for _, cost in ipairs(costList) do
        if not cost.IsSuitBind then
            if (cost.HaveCount or 0) < (cost.NeedCount or 0) then
                canUpdate = false
                break
            end
        end
    end

    -- CanActivate: 激活目标套装材料（绑套装材料）代币兑换够（目标未激活时才需判）
    local canActivate = true
    if needBindSuit and not isActivate then
        local suitCost = self:_GetOverrunSuitBindCost(equipId, targetData)
        if suitCost then
            if autoExchange then
                -- 勾选自动兑换：持有 + 剩余代币可兑换补足
                canActivate = self:_IsSuitMaterialExchangeEnough(suitCost.ItemId, suitCost.NeedCount, usedTokenMap)
            else
                -- 未勾选：只看仓库持有
                canActivate = XDataCenter.ItemManager.GetCount(suitCost.ItemId) >= (suitCost.NeedCount or 0)
            end
        end
    end

    -- CanBind: CanActivate && IsActivate && needBindSuit
    local canBind = (canActivate or isActivate) and needBindSuit

    return {
        CanUpdate = canUpdate,
        CanActivate = canActivate,
        IsActivate = isActivate,
        CanBind = canBind,
        NeedBindSuit = needBindSuit,
    }
end


---@param itemId number 绑套装材料 Id
---@param needCount number 需求数量
---@param usedTokenMap table<number, number>|nil 升级已占用的代币
---@return boolean
--- 绑套装材料用剩余代币能兑换到手量（封顶缺口，供展示 ExchangeCount + 判断复用）
---@param itemId number 绑套装材料 Id
---@param needCount number 需求数量
---@param usedTokenMap table<number, number>|nil 升级已占用的代币
---@return number 可兑到手量（0=无需兑换或兑不出）
function XEquipOneClickCultureControl:_CalcSuitExchangeGain(itemId, needCount, usedTokenMap)
    local have = XDataCenter.ItemManager.GetCount(itemId)
    local lack = needCount - have
    if lack <= 0 then
        return 0
    end
    local info = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId)
    if not info then
        return 0
    end
    local rewardPerTime = info.RewardCountList and info.RewardCountList[1] or 0
    local singleConsumeList = info.ConsumeList and info.ConsumeList[1] or {}
    if rewardPerTime <= 0 then
        return 0
    end
    -- 每种代币的剩余预算算可兑次数，取最小
    local maxTimes = math.maxinteger
    for _, consume in ipairs(singleConsumeList) do
        local tokenId = consume.ConsumeId
        local singleCost = consume.ConsumeCount or 0
        if singleCost > 0 then
            local own = XDataCenter.ItemManager.GetCount(tokenId)
            local used = (usedTokenMap and usedTokenMap[tokenId]) or 0
            local remaining = math.max(0, own - used)
            maxTimes = math.min(maxTimes, math.floor(remaining / singleCost))
        end
    end
    -- 可兑到手量，封顶缺口（展示"消耗多少显多少"）
    return math.min(lack, maxTimes * rewardPerTime)
end

--- 汇总谐振材料自动兑换实际消耗的代币（tokenId → 消耗量）
---@param overrunCostList XEquipOneClickCultureCostItem[]
---@return table<number, number>
function XEquipOneClickCultureControl:_SumOverrunExchangeTokenCost(overrunCostList)
    local tokenCostMap = {}
    for _, cost in ipairs(overrunCostList or table.empty) do
        local exchangeCount = cost.ExchangeCount or 0
        if exchangeCount > 0 then
            local info = XDataCenter.ItemManager.GetItemAutoExchangeInfo(cost.ItemId)
            local rewardPerTime = info and info.RewardCountList and info.RewardCountList[1] or 0
            if rewardPerTime > 0 then
                local times = math.ceil(exchangeCount / rewardPerTime)
                for _, consume in ipairs(info.ConsumeList and info.ConsumeList[1] or table.empty) do
                    AddCost(tokenCostMap, consume.ConsumeId, (consume.ConsumeCount or 0) * times)
                end
            end
        end
    end
    return tokenCostMap
end

--- 绑套装材料用剩余代币兑换是否足够
---@param itemId number
---@param needCount number
---@param usedTokenMap table<number, number>|nil
---@return boolean
function XEquipOneClickCultureControl:_IsSuitMaterialExchangeEnough(itemId, needCount, usedTokenMap)
    local have = XDataCenter.ItemManager.GetCount(itemId)
    local gain = self:_CalcSuitExchangeGain(itemId, needCount, usedTokenMap)
    return have + gain >= needCount
end

--- 谐振各等级节点预览列表（气泡展示用）
---@param equipId number
---@param targetData table
---@param targetLevel number 本次将激活到的等级
---@return XEquipOneClickCultureOverrunLevelPreview[] levelList, number totalStage
function XEquipOneClickCultureControl:GetOverrunLevelPreviewList(equipId, targetData, targetLevel)
    local equip = self._MainControl:GetEquip(equipId)
    if not equip then
        return {}, 0
    end
    local cfgs = self._MainControl:GetWeaponOverrunCfgsByTemplateId(equip.TemplateId, equip.CharacterId)
    local targetSuitId = targetData.WeaponOverrunChoseSuit or 0
    local SUIT = XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT

    local levelList = {}
    local UP_SKILL = XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.UP_SKILL
    for _, cfg in pairs(cfgs or table.empty) do
        local awarenessIcon
        if cfg.OverrunType == SUIT then
            -- 1 级：绑套装，显目标套装图标
            awarenessIcon = XMVCA.XEquip:GetEquipSuitIconPath(targetSuitId)
        elseif cfg.OverrunType == UP_SKILL then
            -- 3-7 级：给技能升级，显被升级技能图标
            local skillGroupId = cfg.UpSkillGroupId
            local character = XTool.IsNumberValid(cfg.CharacterId) and XMVCA.XCharacter:GetCharacter(cfg.CharacterId) or nil
            local skillId = character and character:GetGroupCurSkillId(skillGroupId) or XMVCA.XCharacter:GetGroupDefaultSkillId(skillGroupId)
            local skillLevel = character and character:GetSkillLevel(skillGroupId) or 1
            local skillDetailCfg = XTool.IsNumberValid(skillId) and XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel) or nil
            awarenessIcon = skillDetailCfg and skillDetailCfg.Icon
        elseif XTool.IsNumberValid(cfg.ShowOverrunSkillId) then
            -- 2 级：激活技能，显该技能图标
            local skillCfg = XMVCA.XEquip:GetWeaponOverrunSkillConfigById(cfg.ShowOverrunSkillId)
            awarenessIcon = skillCfg and skillCfg.Icon
        end
        table.insert(levelList, {
            Level = cfg.Level,
            IsPreviewActive = (cfg.Level or 0) <= targetLevel,
            Title = cfg.Name,
            Desc = cfg.Desc,
            AwarenessIcon = awarenessIcon,
        })
    end
    table.sort(levelList, function(a, b)
        return (a.Level or 0) < (b.Level or 0)
    end)
    return levelList, #levelList
end

----------------------------------------
-- 【弹窗】一键养成执行链（照意识强化五件套：先兑换，再各模块串行）
----------------------------------------

--- 启动一键养成串行链路
---@param result XWeaponOneClickCultureResult
---@param callbacks table|nil 阶段回调：onLevelStart/onResonanceStart/onOverrunStart(resume)、onAllDone()、onAbort()
---@return boolean started 是否成功启动
function XEquipOneClickCultureControl:StartWeaponOneClickCulture(result, callbacks)
    self:CancelWeaponOneClickCulture()
    self._WeaponCultureCallbacks = callbacks or table.empty
    if not result then
        if self._WeaponCultureCallbacks.onAbort then
            self._WeaponCultureCallbacks.onAbort("NoResult")
        end
        return false
    end
    -- 不再用 IsEnough 拦截：材料是否足够由确认按钮的置灰/toast 前置把关，
    -- 升级/谐振材料真不够时执行请求会走服务端 TipCode，不在此假失败

    self._WeaponCultureTaskInfo = {
        Result = result,
        TaskList = self:_BuildWeaponCultureTaskList(result),
        Index = 1,
    }
    -- 多步串行会收到大量任务推送，压住逐条派发，链结束（Cancel）时统一放开一次
    XDataCenter.TaskManager.CloseSyncTasksEvent()
    self._WeaponCultureRunning = true
    self:_ExecuteNextWeaponCultureTask(self._WeaponCultureTaskInfo)
    return true
end

--- 打断当前一键养成链路；已发出的请求无法取消，但后续回调会因 taskInfo 失效而被忽略
function XEquipOneClickCultureControl:CancelWeaponOneClickCulture()
    if self._WeaponCultureRunning then
        self._WeaponCultureRunning = false
        XDataCenter.TaskManager.OpenSyncTasksEvent()
    end
    self._WeaponCultureTaskInfo = nil
    self._WeaponCultureCallbacks = nil
end

--- 弹窗销毁/中止时释放链路（与 CancelWeaponOneClickCulture 同义，语义化命名供 UI 层调用）
function XEquipOneClickCultureControl:ReleaseWeaponOneClickCulture()
    self:CancelWeaponOneClickCulture()
end

--- 本次链路实际参与的养成模块单元（供进度弹窗展示，兑换属前置不算独立单元）
---@param result XWeaponOneClickCultureResult
---@return table[] units { Key, Name, Target }
function XEquipOneClickCultureControl:GetWeaponOneClickCultureUnits(result)
    local units = {}
    local taskList = self:_BuildWeaponCultureTaskList(result)
    local nameTextKey = {
        Level = "RoleCultureUnitLevel",
        Resonance = "CharacterSkillLevelDetailResonanace",
        Overrun = "EquipWeaponCultureUnitOverrun",
    }
    -- 各单元目标描述（进度弹窗预览行，均返回字符串避免赋 nil 到 text）
    local targetTextGetter = {
        Level = function()
            local targetLevel = result.LevelPreview and result.LevelPreview.TargetLevel or 0
            return CS.XTextManager.GetText("EquipWeaponOneClickUpgradePreview", targetLevel)
        end,
        Resonance = function()
            local count = result.ResonanceTaskList and #result.ResonanceTaskList or 0
            return CS.XTextManager.GetText("EquipWeaponOneClickResonancePreview", count)
        end,
        Overrun = function()
            return CS.XTextManager.GetText("EquipWeaponCultureUnitOverrunTarget", result.TargetOverrunLevel or 0)
        end,
    }
    for i = 1, #taskList do
        local phase = WeaponCultureTaskPhase[taskList[i].Type]
        if phase then
            local unit = {
                Key = phase,
                Name = CS.XTextManager.GetText(nameTextKey[phase]),
                Target = targetTextGetter[phase](),
            }
            if phase == "Level" then
                unit.BreakIcon = self._MainControl:GetEquipBreakThroughIcon(
                    result.LevelPreview and result.LevelPreview.TargetBreakthrough or 0)
            end
            table.insert(units, unit)
        end
    end
    return units
end

--- 当前 taskInfo 是否仍是有效的执行链（防止旧回调污染新链路）
---@param taskInfo XWeaponOneClickCultureTaskInfo
---@return boolean
function XEquipOneClickCultureControl:_IsWeaponCultureTaskValid(taskInfo)
    return self._WeaponCultureTaskInfo == taskInfo
end

--- 构建串行任务列表：先兑换，再升级/共鸣/谐振
---@param result XWeaponOneClickCultureResult
---@return XWeaponOneClickCultureTask[]
function XEquipOneClickCultureControl:_BuildWeaponCultureTaskList(result)
    local taskList = {}
    local mainControl = self._MainControl
    local equipId = result.EquipId
    local equip = mainControl:GetEquip(equipId)
    local levelPreview = result.LevelPreview

    -- 升级：勾选 且 目标升级单位 > 当前才算有提升；无提升则升级和其前置兑换都不入链
    if result.IncludeLevel and levelPreview and equip then
        local hasLevelUp = (levelPreview.TargetLevelUnit or 0) > mainControl.StrengthenControl:GetEquipLevelUnit(equipId)
        if hasLevelUp then
            for itemId, exchangeInfo in pairs(levelPreview.AutoExchangeInfo or table.empty) do
                if exchangeInfo.ExchangeTimes and exchangeInfo.ExchangeTimes > 0 then
                    table.insert(taskList, { Type = WeaponCultureTaskType.Exchange, Id = itemId })
                end
            end
            table.insert(taskList, { Type = WeaponCultureTaskType.Level })
        end
    end

    -- 共鸣：勾选 且 有实际共鸣任务（选了目标槽）才入链
    if result.IncludeResonance and not XTool.IsTableEmpty(result.ResonanceTaskList) then
        table.insert(taskList, { Type = WeaponCultureTaskType.Resonance })
    end

    -- 谐振：勾选 且（有材料消耗 或 目标套装已激活但未绑定）才入链
    local overrunEquip = self._MainControl:GetEquip(result.EquipId)
    local targetSuitId = result.TargetData and result.TargetData.WeaponOverrunChoseSuit or 0
    local currentSuitId = overrunEquip and overrunEquip:GetOverrunChoseSuit() or 0
    local isSuitActivated = (result.TargetOverrunLevel or 0) >= 1
    local needBindSuit = XTool.IsNumberValid(targetSuitId) and currentSuitId ~= targetSuitId
    -- 代币不足不列入激活/绑定操作
    local canBindSuit = not (isSuitActivated and needBindSuit)
        or self:_IsOverrunSuitBindable(result.EquipId, result.TargetData, result.UsedTokenMap, result.IsLevelMaxed)
    if result.IncludeOverrun
        and (not XTool.IsTableEmpty(result.OverrunCostList) or (isSuitActivated and needBindSuit and canBindSuit)) then
        table.insert(taskList, { Type = WeaponCultureTaskType.Overrun })
    end

    table.sort(taskList, function(a, b)
        return a.Type < b.Type
    end)
    return taskList
end

--- 推进下一个任务
---@param taskInfo XWeaponOneClickCultureTaskInfo
function XEquipOneClickCultureControl:_ExecuteNextWeaponCultureTask(taskInfo)
    if not self:_IsWeaponCultureTaskValid(taskInfo) then
        return
    end
    local task = taskInfo.TaskList[taskInfo.Index]
    if not task then
        self:_FinishWeaponCulture(taskInfo, true)
        return
    end

    local onFinish = function()
        if not self:_IsWeaponCultureTaskValid(taskInfo) then
            return
        end
        taskInfo.Index = taskInfo.Index + 1
        self:_ExecuteNextWeaponCultureTask(taskInfo)
    end
    local onFail = function(code)
        self:_FinishWeaponCulture(taskInfo, false, code)
    end

    -- 真正发起该任务的请求（阶段动画放行后执行）
    local result = taskInfo.Result
    local function doRequest()
        if not self:_IsWeaponCultureTaskValid(taskInfo) then
            return
        end
        if task.Type == WeaponCultureTaskType.Exchange then
            local exchangeInfo = result.LevelPreview.AutoExchangeInfo[task.Id]
            XShopManager.BuyShop(exchangeInfo.ShopId, exchangeInfo.GoodsId, exchangeInfo.ExchangeTimes, onFinish, onFail)
        elseif task.Type == WeaponCultureTaskType.Level then
            local lv = result.LevelPreview
            XMVCA.XEquip:EquipOneKeyFeedRequest(result.EquipId, lv.TargetBreakthrough, lv.TargetLevel, lv.Operations, onFinish, onFail)
        elseif task.Type == WeaponCultureTaskType.Resonance then
            self:_ExecuteResonanceSubChain(result, onFinish, onFail)
        elseif task.Type == WeaponCultureTaskType.Overrun then
            self:_ExecuteOverrunSubChain(result, onFinish, onFail)
        else
            onFail("InvalidTaskType")
        end
    end

    -- 升级/共鸣/谐振任务先触发进度弹窗阶段动画，放行后再发请求；兑换为静默前置直接发
    local callbacks = self._WeaponCultureCallbacks or table.empty
    local phase = WeaponCultureTaskPhase[task.Type]
    local onStart = phase and callbacks["on" .. phase .. "Start"]
    if onStart then
        onStart(doRequest)
    else
        doRequest()
    end
end

--- 谐振执行子链：从当前谐振等级逐级升到目标等级，再绑定目标意识套装（逐个串行）
---@param result XWeaponOneClickCultureResult
---@param onFinish fun()
---@param onFail fun(code:any)
function XEquipOneClickCultureControl:_ExecuteOverrunSubChain(result, onFinish, onFail)
    local taskInfo = self._WeaponCultureTaskInfo
    local equipId = result.EquipId
    local equip = self._MainControl:GetEquip(equipId)
    if not equip then
        onFail("OverrunEquipNil")
        return
    end
    local targetLevel = result.TargetOverrunLevel or 0
    local targetSuitId = result.TargetData and result.TargetData.WeaponOverrunChoseSuit or 0
    local currentSuitId = equip:GetOverrunChoseSuit() or 0
    local needBindSuit = XTool.IsNumberValid(targetSuitId) and currentSuitId ~= targetSuitId

    -- 绑套装（升级 + 兑换绑套装材料完成后）
    local function bindSuit()
        if not self:_IsWeaponCultureTaskValid(taskInfo) then
            return
        end
        if not needBindSuit then
            onFinish()
            return
        end
        -- 激活直接绑定
        if self:IsOverrunSuitActivated(equipId, targetSuitId) then
            XMVCA.XEquip:EquipWeaponChoseOverrunSuitRequest(equipId, targetSuitId, onFinish)
            return
        end
        -- 未激活：先激活（消耗材料）再绑定
        XMVCA.XEquip:EquipWeaponActiveOverrunSuitRequest(equipId, targetSuitId, function()
            if not self:_IsWeaponCultureTaskValid(taskInfo) then
                return
            end
            XMVCA.XEquip:EquipWeaponChoseOverrunSuitRequest(equipId, targetSuitId, onFinish)
        end)
    end

    -- 兑换绑套装材料：OverrunCostList 里 IsSuitBind 且 ExchangeCount>0 的项，逐个购买补足后再绑套装
    local function exchangeSuitMaterials(onDone)
        local exchangeList = {}
        for _, cost in ipairs(result.OverrunCostList or table.empty) do
            if cost.IsSuitBind and (cost.ExchangeCount or 0) > 0 then
                local info = XDataCenter.ItemManager.GetItemAutoExchangeInfo(cost.ItemId)
                local rewardPerTime = info and info.RewardCountList and info.RewardCountList[1] or 0
                if info and info.ShopIdList and info.GoodsIdList and rewardPerTime > 0 then
                    table.insert(exchangeList, {
                        ShopId = info.ShopIdList[1],
                        GoodsId = info.GoodsIdList[1],
                        Times = math.ceil(cost.ExchangeCount / rewardPerTime),
                    })
                end
            end
        end
        local idx = 1
        local function step()
            if not self:_IsWeaponCultureTaskValid(taskInfo) then
                return -- 链路已取消
            end
            local ex = exchangeList[idx]
            if not ex then
                onDone()
                return
            end
            idx = idx + 1
            XShopManager.BuyShop(ex.ShopId, ex.GoodsId, ex.Times, step, onFail)
        end
        step()
    end

    -- 逐级升级：每次升 1 级，callback 里读最新等级继续，达到目标后兑换绑套装材料再绑套装
    local function stepLevelUp()
        if not self:_IsWeaponCultureTaskValid(taskInfo) then
            return -- 链路已取消
        end
        if equip:GetOverrunLevel() >= targetLevel then
            exchangeSuitMaterials(bindSuit)
            return
        end
        XMVCA.XEquip:EquipWeaponOverrunLevelUpRequest(equipId, stepLevelUp)
    end
    stepLevelUp()
end

--- 共鸣执行子链：按 result.ResonanceTaskList 逐槽发起共鸣请求（首绑槽消耗武器/代币，换技能槽不消耗）
---@param result XWeaponOneClickCultureResult
---@param onFinish fun()
---@param onFail fun(code:any)
function XEquipOneClickCultureControl:_ExecuteResonanceSubChain(result, onFinish, onFail)
    local taskInfo = self._WeaponCultureTaskInfo
    local taskList = result.ResonanceTaskList or table.empty
    local equipId = result.EquipId
    local equip = self._MainControl:GetEquip(equipId)
    local characterId = equip and equip.CharacterId or 0
    -- 五星武器不选技能
    local isFiveStar = equip ~= nil and IsFiveStarWeapon(equip)
    local index = 1
    local function stepNext()
        if not self:_IsWeaponCultureTaskValid(taskInfo) then
            return -- 链路已取消/超时
        end
        local task = taskList[index]
        if not task then
            onFinish()
            return
        end
        index = index + 1
        local selectSkillIds = { task.SkillId }
        local selectType = task.ResonanceType
        if isFiveStar then
            selectSkillIds = table.empty
            selectType = nil
        end
        XMVCA.XEquip:CallEquipResonanceRequest(equipId, { task.Pos }, characterId,
            task.UseEquipId, task.UseItemId, selectSkillIds, selectType,
            stepNext, onFail)
    end
    stepNext()
end

--- 结束链路，回调结果
---@param taskInfo XWeaponOneClickCultureTaskInfo
---@param isSuccess boolean
---@param errorCode any|nil
function XEquipOneClickCultureControl:_FinishWeaponCulture(taskInfo, isSuccess, errorCode)
    if not self:_IsWeaponCultureTaskValid(taskInfo) then
        return
    end
    local callbacks = self._WeaponCultureCallbacks or table.empty
    local onAllDone = callbacks.onAllDone
    local onAbort = callbacks.onAbort
    self:CancelWeaponOneClickCulture()
    if isSuccess then
        if onAllDone then
            onAllDone()
        end
    elseif onAbort then
        onAbort(errorCode)
    end
end

function XEquipOneClickCultureControl:OnRelease()
    self:CancelWeaponOneClickCulture()
end

return XEquipOneClickCultureControl
