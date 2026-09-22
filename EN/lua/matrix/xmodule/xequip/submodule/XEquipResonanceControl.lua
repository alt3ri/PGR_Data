--- 装备共鸣子 Control：共鸣目标判断、消耗构建等复用逻辑
---@class XEquipResonanceControl: XControl
---@field private _Model XEquipModel
---@field private _MainControl XEquipControl
---@field private _AwarenessResonanceContext XEquipAwarenessResonanceContext|nil
local XEquipResonanceControl = XClass(XControl, "XEquipResonanceControl")

local TARGET_MATCH_MODE = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE
local AWARENESS_RESONANCE_INTERVAL = 500

-- 判断共鸣技能是否绑定到当前角色之外的角色。
---@param resonanceInfo table|nil 共鸣信息
---@param characterId number 当前角色 Id
---@return boolean 是否绑定其他角色
local function IsBindOtherCharacter(resonanceInfo, characterId)
    local bindCharacterId = resonanceInfo and resonanceInfo.CharacterId or 0
    return bindCharacterId ~= 0 and bindCharacterId ~= characterId
end

---@class XEquipAwarenessResonanceTargetState
---@field HasTarget boolean 是否存在有效目标技能
---@field IsAchieved boolean 当前装备是否已达成目标
---@field IsBindOtherCharacter boolean 当前共鸣是否绑定其他角色

---@class XEquipAwarenessResonanceCostInfo
---@field Type number 共鸣消耗类型
---@field Star number|nil 意识星级，仅意识材料和随机代币使用
---@field ItemId number|nil 道具 Id，仅定向材料和随机代币使用
---@field Count number|nil 可消耗意识数量，仅意识材料使用
---@field SuitId number|nil 意识套装 Id，仅意识材料使用
---@field IconTemplateId number|nil 意识图标模板 Id，仅意识材料使用
---@field AwarenessIdList number[]|nil 可消耗意识装备 Id 列表，供 UI 记录本次选中的意识

---@class XEquipAwarenessResonanceContext
---@field Plan XUiPanelAwarenessOneClickResonanceResult 一键共鸣执行计划
---@field Index number 当前执行索引
---@field Callbacks { onFinish: fun(isSuccess:boolean, errorCode:any)|nil, onProgress: fun(materialBudget:XUiPanelAwarenessOneClickResonanceMaterialBudget)|nil, onTaskExecuting: fun(task:XUiPanelAwarenessOneClickResonanceTask) } 执行回调
---@field NextTaskTimer number|nil 下一次共鸣任务的延迟定时器

---@class XEquipAwarenessResonanceTarget
---@field Pos number 共鸣槽位
---@field MatchMode XEquipAwarenessResonanceTargetMatchMode 目标匹配模式
---@field TargetType number|nil 目标共鸣类型，仅指定目标技能模式使用
---@field TargetSkillId number|nil 目标共鸣技能 Id，仅指定目标技能模式使用

----------------------------------------
-- 生命周期
----------------------------------------
-- 初始化装备共鸣 Control
function XEquipResonanceControl:OnInit()
end

-- 注册装备共鸣相关事件
function XEquipResonanceControl:AddAgencyEvent()
end

-- 移除装备共鸣相关事件
function XEquipResonanceControl:RemoveAgencyEvent()
end

-- 释放装备共鸣 Control
function XEquipResonanceControl:OnRelease()
end

----------------------------------------
-- 共鸣目标查询
----------------------------------------
-- 判断共鸣数据是否属于攻击类共鸣
---@param resonanceType number 共鸣类型，取值见 XEnumConst.EQUIP.RESONANCE_TYPE
---@param skillId number 共鸣技能 Id
---@return boolean 是否攻击类共鸣
function XEquipResonanceControl:IsAttackResonanceSkill(resonanceType, skillId)
    -- 角色技能都属于攻击类
    if resonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL then
        return true
    end

    -- 属性技能只有配置的技能才属于攻击类
    if resonanceType ~= XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB or not XTool.IsNumberValid(skillId) then
        return false
    end

    local attackSkillIds = self._Model:GetEquipConfigValuesByKey("ChipResonanceAttackSkillIds")
    for _, attackSkillId in ipairs(attackSkillIds) do
        if attackSkillId == skillId then
            return true
        end
    end

    return false
end

-- 判断指定意识共鸣槽位是否还未达到目标。
---@param equip XEquip 装备数据
---@param target XEquipAwarenessResonanceTarget 共鸣目标
---@param characterId number 当前角色 Id
---@return boolean 是否未达成目标共鸣
function XEquipResonanceControl:IsAwarenessResonanceTargetUnachieved(equip, target, characterId)
    local resonanceInfo = equip:GetResonanceInfo(target.Pos)
    if not resonanceInfo then
        return true
    end

    return not self:IsAwarenessResonanceTargetReached(target, characterId, resonanceInfo)
end

-- 判断已有共鸣信息是否满足目标，供预览筛选和执行流程共用。
---@param target XEquipAwarenessResonanceTarget 共鸣目标
---@param characterId number 当前角色 Id
---@param resonanceInfo table|nil 当前或待确认的共鸣信息
---@return boolean 是否已达成目标
function XEquipResonanceControl:IsAwarenessResonanceTargetReached(target, characterId, resonanceInfo)
    -- 没有共鸣信息表示槽位尚未填充，不能视为已达成
    if not resonanceInfo then
        return false
    end

    if target.MatchMode == TARGET_MATCH_MODE.ANY then
        return true
    end

    if target.MatchMode == TARGET_MATCH_MODE.ATTACK then
        return self:IsAttackResonanceSkill(resonanceInfo.Type, resonanceInfo.TemplateId)
    end

    if target.MatchMode == TARGET_MATCH_MODE.TARGET then
        -- 未配置目标类型或目标技能时，表示没有指定目标技能，无需继续匹配即可视为达成
        if not XTool.IsNumberValid(target.TargetSkillId) or not XTool.IsNumberValid(target.TargetType) then
            return true
        end

        if IsBindOtherCharacter(resonanceInfo, characterId) then
            return false
        end

        return resonanceInfo.Type == target.TargetType and resonanceInfo.TemplateId == target.TargetSkillId
    end

    return false
end

-- 获取当前共鸣技能对指定方案目标的达成和角色绑定状态。
---@param equip XEquip 意识装备数据
---@param target XEquipAwarenessResonanceTarget 共鸣目标
---@param characterId number 当前角色 Id
---@return XEquipAwarenessResonanceTargetState
function XEquipResonanceControl:GetAwarenessResonanceTargetMatchState(equip, target, characterId)
    local resonanceInfo = equip:GetResonanceInfo(target.Pos)
    return {
        HasTarget = true,
        IsAchieved = self:IsAwarenessResonanceTargetReached(target, characterId, resonanceInfo),
        IsBindOtherCharacter = IsBindOtherCharacter(resonanceInfo, characterId),
    }
end

--- 获取意识共鸣目标状态，供目标技能 Grid 统一刷新展示状态。
---@param equip XEquip 当前穿戴且模板匹配的意识装备
---@param pos number 共鸣槽位
---@param targetResonanceData table|nil 目标共鸣数据
---@param characterId number 当前角色 Id
---@return XEquipAwarenessResonanceTargetState
function XEquipResonanceControl:GetAwarenessResonanceTargetState(equip, pos, targetResonanceData, characterId)
    return XMVCA.XEquip:GetAwarenessResonanceTargetState(equip and equip.Id, pos, targetResonanceData, characterId)
end

----------------------------------------
-- 共鸣消耗预览
----------------------------------------
-- 判断共鸣消耗在请求时是否需要传入目标技能。
---@param costData table 共鸣消耗数据
---@return boolean 是否需要指定共鸣技能
function XEquipResonanceControl:IsAwarenessResonanceCostNeedSelectSkill(costData)
    return costData.NeedSelectSkill == true
            or costData.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.TARGETED
            or costData.IsSelectSkillItem == true
end

-- 判断共鸣消耗是否可用于当前目标，需要指定技能的材料只服务于指定目标技能模式。
---@param target XEquipAwarenessResonanceTarget 共鸣目标
---@param costData table 共鸣消耗数据
---@return boolean 是否可用于当前目标
function XEquipResonanceControl:IsAwarenessResonanceCostAvailable(target, costData)
    if not self:IsAwarenessResonanceCostNeedSelectSkill(costData) then
        return true
    end

    return target.MatchMode == TARGET_MATCH_MODE.TARGET
            and XTool.IsNumberValid(target.TargetSkillId)
            and XTool.IsNumberValid(target.TargetType)
end

-- 获取单次意识共鸣消耗数量，6 星定向材料固定消耗 1 个，其他代币读取配置。
---@param costData table 共鸣消耗数据
---@param equip XEquip 意识装备数据
---@return number|nil 单次消耗数量
function XEquipResonanceControl:GetAwarenessResonanceCostCount(costData, equip)
    if costData.Type == XEnumConst.EQUIP.RESONANCE_COST_TYPE.TARGETED and equip:GetStar() == XEnumConst.EQUIP.SIX_STAR then
        return 1
    end

    local tokenInfoDic = self._MainControl:GetResonanceTokenInfoDic(equip.TemplateId)
    local tokenInfo = tokenInfoDic[costData.ItemId]
    return tokenInfo and tokenInfo.CostCnt or nil
end

-- 构建意识共鸣通用消耗数据列表。
---@param awarenessEquipIdBySite table<number, number> 部位到意识装备 Id 的映射
---@return table<number, XEquipAwarenessResonanceCostInfo> 随机代币和意识材料消耗列表
---@return XEquipAwarenessResonanceCostInfo|nil 存在 6 星意识时返回定向共鸣材料入口
function XEquipResonanceControl:BuildAwarenessResonanceCostInfoList(awarenessEquipIdBySite)
    local costInfos = {}
    local awarenessCostInfos = {}
    local tokenItemIdDic = {}
    local targetedCostInfo = nil
    if XTool.IsTableEmpty(awarenessEquipIdBySite) then
        return costInfos, targetedCostInfo
    end

    local resonanceStarList = { XEnumConst.EQUIP.SIX_STAR, XEnumConst.EQUIP.FIVE_STAR }
    for _, star in ipairs(resonanceStarList) do
        local starTokenInfos, starAwarenessCostInfos, hasStar = self:_BuildAwarenessResonanceCostInfoListByStar(awarenessEquipIdBySite, star)
        if star == XEnumConst.EQUIP.SIX_STAR and hasStar then
            targetedCostInfo = { Type = XEnumConst.EQUIP.RESONANCE_COST_TYPE.TARGETED, ItemId = XDataCenter.ItemManager.ItemId.QuickReasonanceCoin }
        end

        for _, tokenInfo in ipairs(starTokenInfos) do
            local itemId = tokenInfo.ItemId
            if not tokenItemIdDic[itemId] then
                tokenItemIdDic[itemId] = true
                table.insert(costInfos, {
                    Type = XEnumConst.EQUIP.RESONANCE_COST_TYPE.TOKEN,
                    Star = star,
                    ItemId = itemId,
                    IsSelectSkillItem = tokenInfo.IsSelectSkillItem,
                })
            end
        end

        for _, costInfo in ipairs(starAwarenessCostInfos) do
            table.insert(awarenessCostInfos, costInfo)
        end
    end

    for _, costInfo in ipairs(awarenessCostInfos) do
        table.insert(costInfos, costInfo)
    end

    return costInfos, targetedCostInfo
end

----------------------------------------
-- 共鸣执行入口
----------------------------------------
--- 启动意识一键养成共鸣串行流程。
---@param resonancePlan XUiPanelAwarenessOneClickResonanceResult|nil
---@param callbacks { onFinish: fun(isSuccess:boolean, errorCode:any)|nil, onProgress: fun(materialBudget:XUiPanelAwarenessOneClickResonanceMaterialBudget)|nil, onTaskExecuting: fun(task:XUiPanelAwarenessOneClickResonanceTask) } 执行回调
---@return boolean
function XEquipResonanceControl:StartAwarenessResonance(resonancePlan, callbacks)
    self:CancelAwarenessResonance()

    local isValid, errorCode = self:_CheckAwarenessResonancePlan(resonancePlan)
    if not isValid then
        if callbacks and callbacks.onFinish then
            callbacks.onFinish(false, errorCode)
        end
        return false
    end

    self._AwarenessResonanceContext = {
        Plan = resonancePlan,
        Index = 1,
        Callbacks = callbacks,
        NextTaskTimer = nil,
    }
    self:_ExecuteNextAwarenessResonanceTask(self._AwarenessResonanceContext)
    return true
end

--- 中断当前意识共鸣流程。已发出的请求不能取消，后续回调会因 context 失效被忽略。
function XEquipResonanceControl:CancelAwarenessResonance()
    local context = self._AwarenessResonanceContext
    if context and context.NextTaskTimer then
        XScheduleManager.UnSchedule(context.NextTaskTimer)
        context.NextTaskTimer = nil
    end

    self._AwarenessResonanceContext = nil
end

----------------------------------------
-- 共鸣消耗预览内部构建
----------------------------------------
-- 收集指定星级意识对应的随机共鸣代币和可吞噬意识材料。
---@param awarenessEquipIdBySite table<number, number> 部位到意识装备 Id 的映射
---@param star number 意识星级
---@return table<number, table> 随机共鸣代币信息列表，元素包含 ItemId 和 IsSelectSkillItem
---@return table<number, XEquipAwarenessResonanceCostInfo> 可吞噬意识材料信息列表
---@return boolean 是否存在指定星级意识
function XEquipResonanceControl:_BuildAwarenessResonanceCostInfoListByStar(awarenessEquipIdBySite, star)
    local hasStar = false
    local starTokenInfos = {}
    local collectedSuitIdDic = {}
    local starAwarenessCostInfos = {}
    for equipSite = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = awarenessEquipIdBySite[equipSite]
        local equip = equipId and self._MainControl:GetEquip(equipId)
        if equip and equip:GetStar() == star then
            hasStar = true

            local config = self._MainControl:GetEquipResonanceUseItem(equip.TemplateId)
            for _, itemId in ipairs(config.ItemId) do
                if self._MainControl:IsResonanceItemShowInTokenTab(itemId) then
                    table.insert(starTokenInfos, { ItemId = itemId, IsSelectSkillItem = false })
                end
            end

            for _, itemId in ipairs(config.SelectSkillItemId) do
                if self._MainControl:IsResonanceItemShowInTokenTab(itemId) then
                    table.insert(starTokenInfos, { ItemId = itemId, IsSelectSkillItem = true })
                end
            end

            local suitId = equip:GetSuitId()
            if not collectedSuitIdDic[suitId] then
                collectedSuitIdDic[suitId] = true
                local awarenessIdList = self._MainControl:GetAwarenessResonanceCanEatEquipIds(equipId)
                local firstAwarenessId = awarenessIdList[1]
                if firstAwarenessId then
                    local firstAwareness = self._MainControl:GetEquip(firstAwarenessId)
                    if firstAwareness then
                        local awarenessCostInfo = {
                            Type = XEnumConst.EQUIP.RESONANCE_COST_TYPE.AWARENESS,
                            Star = star,
                            Count = #awarenessIdList,
                            SuitId = suitId,
                            IconTemplateId = firstAwareness.TemplateId,
                            AwarenessIdList = awarenessIdList,
                        }
                        table.insert(starAwarenessCostInfos, awarenessCostInfo)
                    end
                end
            end
        end
    end

    return starTokenInfos, starAwarenessCostInfos, hasStar
end

----------------------------------------
-- 共鸣执行内部流程
----------------------------------------
--- 校验一键共鸣执行计划是否具备执行条件。
---@param resonancePlan XUiPanelAwarenessOneClickResonanceResult|nil
---@return boolean
---@return string|nil
function XEquipResonanceControl:_CheckAwarenessResonancePlan(resonancePlan)
    -- 未生成执行结果通常表示一键养成入口没有正确完成预览或结果传递。
    if not resonancePlan then
        return false, "AwarenessResonanceResultMissing"
    end

    -- 没有待处理的共鸣目标，说明目标选择结果与执行结果不一致。
    if (resonancePlan.TargetCount or 0) <= 0 then
        return false, "AwarenessResonanceTargetInvalid"
    end

    -- 非“培养至目标”模式必须提供明确的执行次数。
    if not resonancePlan.IsUntilTarget and (resonancePlan.TimesCount or 0) <= 0 then
        return false, "AwarenessResonanceTimesInvalid"
    end

    -- 已选择目标但没有可执行任务，通常表示预览阶段可用材料不足。
    if XTool.IsTableEmpty(resonancePlan.TaskList) then
        return false, "ResonanceMaterialNotEnough"
    end

    -- 执行任务必须共享预览阶段生成的材料预算，缺失时不能读取实时背包兜底。
    if not resonancePlan.MaterialBudget then
        return false, "AwarenessResonanceMaterialBudgetMissing"
    end

    return true
end

--- 推进意识一键共鸣任务：已达成、次数耗尽、材料不足都会跳到下一个任务。
---@param context XEquipAwarenessResonanceContext
function XEquipResonanceControl:_ExecuteNextAwarenessResonanceTask(context)
    -- 流程取消或被新流程替换后，旧异步链不能继续推进。
    if not self:_IsCurrentAwarenessResonanceContext(context) then
        return
    end

    local task = context.Plan.TaskList[context.Index]
    -- 所有任务均已处理，当前一键共鸣流程正常结束。
    if not task then
        self:_FinishAwarenessResonance(context, true)
        return
    end

    -- 目标已经达成或执行次数用尽时，不再消耗材料，直接处理下一个任务。
    local isTargetReached = self:_IsAwarenessResonanceTaskReached(context.Plan, task)
    local isTimesExhausted = task.ExecutedTimes >= task.MaxTimes
    if isTargetReached or isTimesExhausted then
        self:_CompleteCurrentAwarenessResonanceTask(context)
        return
    end

    if self:_TryConfirmPendingAwarenessResonance(context, task) then
        return
    end

    self:_ExecuteCurrentAwarenessResonanceTask(context, task)
end

--- 确认当前槽位遗留的未确认共鸣结果；确认完成后重新判断当前任务。
---@param context XEquipAwarenessResonanceContext
---@param task XUiPanelAwarenessOneClickResonanceTask
---@return boolean 是否已发起未确认结果的确认流程
function XEquipResonanceControl:_TryConfirmPendingAwarenessResonance(context, task)
    local equip = self._MainControl:GetEquip(task.EquipId)
    local unconfirmedResonanceInfo = equip:GetResonanceUnConfirmInfo(task.Pos)
    if not unconfirmedResonanceInfo then
        return false
    end

    local isUseUnconfirmedResonance = self:IsAwarenessResonanceTargetReached(
        task.Target,
        context.Plan.CharacterId,
        unconfirmedResonanceInfo
    )
    XMVCA.XEquip:ResonanceConfirm(task.EquipId, task.Pos, isUseUnconfirmedResonance, function()
        -- 确认期间流程可能已取消，过期回调不能继续执行任务。
        if not self:_IsCurrentAwarenessResonanceContext(context) then
            return
        end

        self:_ExecuteNextAwarenessResonanceTask(context)
    end)
    return true
end

--- 为当前任务取材并发起一次新的共鸣请求。
---@param context XEquipAwarenessResonanceContext
---@param task XUiPanelAwarenessOneClickResonanceTask
function XEquipResonanceControl:_ExecuteCurrentAwarenessResonanceTask(context, task)
    -- 取材会从所有任务共享的材料预算中预扣本次消耗；无可用材料时结束当前任务。
    local cost = self:_TakeAwarenessResonanceCost(context.Plan, task)
    if not cost then
        self:_CompleteCurrentAwarenessResonanceTask(context)
        return
    end

    -- 直接传递当前任务，避免 UI 将 TaskList 下标误认为共鸣技能下标。
    context.Callbacks.onTaskExecuting(task)

    self:_RequestAwarenessResonance(context, task, cost)
end

---@param context XEquipAwarenessResonanceContext
---@param task XUiPanelAwarenessOneClickResonanceTask
---@param cost table
-- 发起当前任务的共鸣请求，并在响应成功后直接推进流程。
function XEquipResonanceControl:_RequestAwarenessResonance(context, task, cost)
    local selectSkillIds = {}
    local selectType = nil
    if self:IsAwarenessResonanceCostNeedSelectSkill(cost) and self:IsAwarenessResonanceCostAvailable(task.Target, cost) then
        selectSkillIds = { task.Target.TargetSkillId }
        selectType = task.Target.TargetType
    end

    XMVCA.XEquip:CallEquipResonanceRequest(
        task.EquipId,
        { task.Pos },
        context.Plan.CharacterId,
        cost.UseEquipId,
        cost.UseItemId,
        selectSkillIds,
        selectType,
        function()
            if not self:_IsCurrentAwarenessResonanceContext(context) then
                return
            end

            task.ExecutedTimes = task.ExecutedTimes + 1
            self:_ConfirmNewAwarenessResonanceResult(context, task)
        end,
        function(errorCode)
            if not self:_IsCurrentAwarenessResonanceContext(context) then
                return
            end

            self:_FinishAwarenessResonance(context, false, errorCode)
        end)
end

--- 为当前任务从共享材料预算中取出一次可用消耗。
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult
---@param task XUiPanelAwarenessOneClickResonanceTask
---@return table|nil
function XEquipResonanceControl:_TakeAwarenessResonanceCost(resonanceResult, task)
    -- 执行时从共享预算动态取材：优先消耗已选意识，再消耗道具；目标提前达成后剩余预算留给后续任务。
    local awarenessCost = self:_TakeAwarenessResonanceAwarenessCost(resonanceResult, task)
    if awarenessCost then
        return awarenessCost
    end

    return self:_TakeAwarenessResonanceItemCost(resonanceResult, task)
end

--- 优先从已选择的意识材料中取出一次共鸣消耗。
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult
---@param task XUiPanelAwarenessOneClickResonanceTask
---@return table|nil
function XEquipResonanceControl:_TakeAwarenessResonanceAwarenessCost(resonanceResult, task)
    local materialBudget = resonanceResult.MaterialBudget
    local materialKey = task.AwarenessMaterialKey
    local selectedAwarenessIdList = materialBudget.SelectedAwarenessIdListByKey[materialKey]
    local remainCount = materialBudget.SelectedCountMap[materialKey] or 0
    if XTool.IsTableEmpty(selectedAwarenessIdList) or remainCount <= 0 then
        return nil
    end

    local useEquipId = table.remove(selectedAwarenessIdList, 1)
    materialBudget.SelectedCountMap[materialKey] = remainCount - 1
    return { UseEquipId = useEquipId, NeedSelectSkill = false }
end

--- 从已选择的道具材料中取出一次满足当前目标的共鸣消耗。
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult
---@param task XUiPanelAwarenessOneClickResonanceTask
---@return table|nil
function XEquipResonanceControl:_TakeAwarenessResonanceItemCost(resonanceResult, task)
    local materialBudget = resonanceResult.MaterialBudget
    local equip = self._MainControl:GetEquip(task.EquipId)
    for _, itemData in ipairs(materialBudget.SelectedItemList) do
        if self:IsAwarenessResonanceCostAvailable(task.Target, itemData) then
            local costCount = self:GetAwarenessResonanceCostCount(itemData, equip)
            local materialKey = itemData.MaterialKey
            local remainCount = materialBudget.SelectedCountMap[materialKey] or 0
            if costCount and costCount > 0 and remainCount >= costCount then
                materialBudget.SelectedCountMap[materialKey] = remainCount - costCount
                return {
                    UseItemId = itemData.ItemId,
                    NeedSelectSkill = self:IsAwarenessResonanceCostNeedSelectSkill(itemData),
                }
            end
        end
    end

    return nil
end

--- 根据本次共鸣结果决定是否确认使用，并继续推进或完成当前任务。
---@param context XEquipAwarenessResonanceContext
---@param task XUiPanelAwarenessOneClickResonanceTask
function XEquipResonanceControl:_ConfirmNewAwarenessResonanceResult(context, task)
    local isUse = self:_ShouldUseAwarenessResonanceResult(context.Plan, task)
    self:_LogAwarenessResonanceResult(context, task, isUse)

    XMVCA.XEquip:ResonanceConfirm(task.EquipId, task.Pos, isUse, function()
        if not self:_IsCurrentAwarenessResonanceContext(context) then
            return
        end

        local callbacks = context.Callbacks
        if callbacks and callbacks.onProgress then
            callbacks.onProgress(context.Plan.MaterialBudget)
        end

        if self:_IsAwarenessResonanceTaskReached(context.Plan, task) or task.ExecutedTimes >= task.MaxTimes then
            self:_CompleteCurrentAwarenessResonanceTask(context, true)
            return
        end

        self:_ScheduleNextAwarenessResonanceTask(context)
    end)
end

--- 延迟调度下一次意识共鸣任务，避免连续请求过快。
---@param context XEquipAwarenessResonanceContext
function XEquipResonanceControl:_ScheduleNextAwarenessResonanceTask(context)
    context.NextTaskTimer = XScheduleManager.ScheduleOnce(function()
        context.NextTaskTimer = nil
        if self:_IsCurrentAwarenessResonanceContext(context) then
            self:_ExecuteNextAwarenessResonanceTask(context)
        end
    end, AWARENESS_RESONANCE_INTERVAL)
end

--- 判断本次共鸣结果是否应该确认使用。
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult
---@param task XUiPanelAwarenessOneClickResonanceTask
---@return boolean
function XEquipResonanceControl:_ShouldUseAwarenessResonanceResult(resonanceResult, task)
    -- 首次共鸣只负责填空槽，必定确认使用；非首次只在结果命中目标时确认。
    if task.IsFirstResonance then
        return true
    end

    local equip = self._MainControl:GetEquip(task.EquipId)
    local resonanceInfo = equip:GetResonanceUnConfirmInfo(task.Pos) or equip:GetResonanceInfo(task.Pos)
    return self:IsAwarenessResonanceTargetReached(task.Target, resonanceResult.CharacterId, resonanceInfo)
end

--- 判断当前任务的共鸣槽位是否已经达成目标。
---@param resonanceResult XUiPanelAwarenessOneClickResonanceResult
---@param task XUiPanelAwarenessOneClickResonanceTask
---@return boolean
function XEquipResonanceControl:_IsAwarenessResonanceTaskReached(resonanceResult, task)
    local equip = self._MainControl:GetEquip(task.EquipId)
    local resonanceInfo = equip:GetResonanceInfo(task.Pos)
    return self:IsAwarenessResonanceTargetReached(task.Target, resonanceResult.CharacterId, resonanceInfo)
end

--- 标记当前任务完成，并切换到下一个一键共鸣任务。
---@param context XEquipAwarenessResonanceContext
---@param needDelay boolean|nil 是否延迟切换到下一个任务
function XEquipResonanceControl:_CompleteCurrentAwarenessResonanceTask(context, needDelay)
    if not self:_IsCurrentAwarenessResonanceContext(context) then
        return
    end

    context.Index = context.Index + 1
    if needDelay then
        self:_ScheduleNextAwarenessResonanceTask(context)
    else
        self:_ExecuteNextAwarenessResonanceTask(context)
    end
end

--- 结束当前一键共鸣流程并清理运行时状态。
---@param context XEquipAwarenessResonanceContext
---@param isSuccess boolean
---@param errorCode any
function XEquipResonanceControl:_FinishAwarenessResonance(context, isSuccess, errorCode)
    if not self:_IsCurrentAwarenessResonanceContext(context) then
        return
    end

    local callbacks = context.Callbacks
    if context.NextTaskTimer then
        XScheduleManager.UnSchedule(context.NextTaskTimer)
        context.NextTaskTimer = nil
    end

    self._AwarenessResonanceContext = nil
    if callbacks and callbacks.onFinish then
        callbacks.onFinish(isSuccess, errorCode)
    end
end

--- 判断回调持有的任务上下文是否仍是当前运行中的流程。
---@param context XEquipAwarenessResonanceContext|nil
---@return boolean
function XEquipResonanceControl:_IsCurrentAwarenessResonanceContext(context)
    return context and self._AwarenessResonanceContext == context
end

----------------------------------------
-- 共鸣调试日志
----------------------------------------
-- 共鸣调试日志文件名，统一输出到各平台的应用持久化目录。
local AWARENESS_RESONANCE_LOG_FILE_NAME = "XEquipAwarenessResonanceDebug.txt"
-- 默认关闭；专项调试包可显式开启，避免正式包产生高频文件 IO。
local ENABLE_AWARENESS_RESONANCE_LOG = false

-- 共鸣类型 Id 到日志中文名称的映射。
local AWARENESS_RESONANCE_TYPE_NAME = {
    [XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB] = "属性",
    [XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL] = "角色技能",
    [XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL] = "武器技能",
}

-- 获取共鸣类型的中文名称，未配置的类型保留 Id 便于排查。
local function GetAwarenessResonanceLogTypeName(resonanceType)
    return AWARENESS_RESONANCE_TYPE_NAME[resonanceType] or string.format("未知类型(%s)", tostring(resonanceType))
end

-- 将共鸣技能数据格式化为“类型(Id=技能 Id,角色=角色 Id)”的可读文本。
local function GetAwarenessResonanceLogSkillInfo(resonanceInfo)
    if not resonanceInfo then
        return "无"
    end

    local characterId = resonanceInfo.CharacterId or 0
    local characterInfo = characterId == 0 and "无" or tostring(characterId)
    return string.format("%s(Id=%s,角色=%s)", GetAwarenessResonanceLogTypeName(resonanceInfo.Type),
        tostring(resonanceInfo.TemplateId), characterInfo)
end

---@param context XEquipAwarenessResonanceContext
---@param task XUiPanelAwarenessOneClickResonanceTask
---@param isUse boolean 本次结果是否确认使用
-- 记录单次共鸣结果，首次尝试时同时输出当前任务的装备、槽位和目标信息。
function XEquipResonanceControl:_LogAwarenessResonanceResult(context, task, isUse)
    if not XMain.IsEditorDebug or not ENABLE_AWARENESS_RESONANCE_LOG then
        return
    end

    local logPath = CS.System.IO.Path.GetFullPath(CS.System.IO.Path.Combine(
        CS.UnityEngine.Application.persistentDataPath, AWARENESS_RESONANCE_LOG_FILE_NAME))
    local equip = self._MainControl:GetEquip(task.EquipId)
    local previousResonanceInfo
    local resultResonanceInfo
    if task.IsFirstResonance then
        resultResonanceInfo = equip:GetResonanceInfo(task.Pos)
    else
        previousResonanceInfo = equip:GetResonanceInfo(task.Pos)
        resultResonanceInfo = equip:GetResonanceUnConfirmInfo(task.Pos)
    end
    local totalExecutedTimes = 0
    for _, resonanceTask in ipairs(context.Plan.TaskList) do
        totalExecutedTimes = totalExecutedTimes + resonanceTask.ExecutedTimes
    end
    local isTargetReached = self:IsAwarenessResonanceTargetReached(task.Target, context.Plan.CharacterId, resultResonanceInfo)
    local target = task.Target
    local logTime = CS.System.DateTime.Now:ToString("yyyy-MM-dd HH:mm:ss.fff")
    local targetSkill = string.format("%s(Id=%s)", GetAwarenessResonanceLogTypeName(target.TargetType),
        tostring(target.TargetSkillId))
    local targetState = isTargetReached and "已命中" or "未命中"
    local processState = task.IsFirstResonance and "首次填槽，自动生效" or (isUse and "确认使用" or "丢弃结果")
    local logLine = string.format(
        "[%s] 第%02d次 共鸣结果=%s 目标状态=%s 处理方式=%s\r\n",
        logTime, totalExecutedTimes, GetAwarenessResonanceLogSkillInfo(resultResonanceInfo), targetState, processState)
    if task.ExecutedTimes == 1 then
        logLine = string.format("[%s] [任务 %s/%s] 装备=%s 槽位=%s 共鸣前=%s 目标=%s\r\n%s", logTime,
            tostring(context.Index), tostring(#context.Plan.TaskList), tostring(task.EquipId), tostring(task.Pos),
            GetAwarenessResonanceLogSkillInfo(previousResonanceInfo), targetSkill, logLine)
    end

    local isSuccess, errorMessage = pcall(function()
        CS.System.IO.File.AppendAllText(logPath, logLine, CS.System.Text.Encoding.UTF8)
    end)
    if isSuccess and totalExecutedTimes == 1 then
        XLog.Debug(string.format("XEquipResonanceControl: 已追加共鸣日志，完整路径=%s", logPath))
    elseif not isSuccess then
        XLog.Warning(string.format("XEquipResonanceControl: 追加共鸣日志失败，完整路径=%s error=%s", logPath, tostring(errorMessage)))
    end
end

----------------------------------------
-- 共鸣调试日志结束
----------------------------------------

return XEquipResonanceControl
