---@class XPartnerOneKeyCultureCommitControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerOneKeyCultureControl
--- 职责：遍历消费原子，模拟扣减虚拟池，记录每类消费到第几个原子
local XPartnerOneKeyCultureCommitControl = XClass(XControl, "XPartnerOneKeyCultureCommitControl")

function XPartnerOneKeyCultureCommitControl:OnInit()
    self._OneKeyCultureModel = self._Model:GetOneKeyCultureModel()
    self._CostItemModel = self._Model:GetOneKeyCultureModel():GetBaseCostItemModel()

    --- 虚拟持有池 { [itemId] = count }
    self._VirtualPool = {}
    --- 每类消费到的原子 index（0 = 一个都没消费）
    self._LevelUpConsumeIndex = 0
    self._StarUpConsumeIndex = 0
    self._SkillConsumeIndex = 0
    --- 完整升星阶段后剩余可继续喂养的狗粮数量
    self._StarUpTailFeedCount = 0
    --- 分类型消耗列表缓存
    self._LevelUpConsumedList = {}
    self._StarUpConsumedList = {}
    self._SkillConsumedList = {}
    self._ItemIdSet = {}
    self._SkillLevelResult = {}

    --- 分类型兑换产物列表 { {Id, Count} }
    self._LevelUpExchangedList = {}
    self._StarUpExchangedList = {}
    self._SkillExchangedList = {}
    --- 兑换执行计划 { {ItemId, ShopId, GoodsId, Times, GainCount} }
    self._ExchangePlanList = {}
    --- 兑换货币总花费 { {Id, Count} }
    self._ExchangeCostList = {}
    self._ExchangeCostDic = {}
    --- 单个 MO 校验期临时表
    self._TempDeltaPool = {}
    self._TempPlanList = {}
    --- 单批次兑换产物临时字典 { [itemId] = count }
    self._TempExchangedDic = {}
end

function XPartnerOneKeyCultureCommitControl:OnRelease()
    table.clear(self._VirtualPool)
    table.clear(self._LevelUpConsumedList)
    table.clear(self._StarUpConsumedList)
    table.clear(self._SkillConsumedList)
    table.clear(self._ItemIdSet)
    table.clear(self._LevelUpExchangedList)
    table.clear(self._StarUpExchangedList)
    table.clear(self._SkillExchangedList)
    table.clear(self._ExchangePlanList)
    table.clear(self._ExchangeCostList)
    table.clear(self._ExchangeCostDic)
    table.clear(self._TempDeltaPool)
    table.clear(self._TempPlanList)
    table.clear(self._TempExchangedDic)
end

--region 计算提交结果
function XPartnerOneKeyCultureCommitControl:CalcCommit()
    self:_ClearResult()

    --虚拟材料池先收集一波材料。
    self:_InitVirtualPool()

    local XPartnerEnum = XMVCA.XPartner.Enum

    -- 尝试消耗这一波升级用的
    if self._OneKeyCultureModel:IsCultureSelected(XPartnerEnum.CultureType.LevelUp) then
        table.clear(self._TempExchangedDic)
        self._LevelUpConsumeIndex = self:_ConsumeMOList(self._CostItemModel:GetLevelUpMOList(), self._TempExchangedDic)
        self:_BuildExchangedList(self._TempExchangedDic, self._LevelUpExchangedList)
    end

    -- 尝试消耗这一波升星用的
    if self._OneKeyCultureModel:IsCultureSelected(XPartnerEnum.CultureType.StarUp) then
        table.clear(self._TempExchangedDic)
        self._StarUpConsumeIndex = self:_ConsumeMOList(self._CostItemModel:GetStarUpMOList(), self._TempExchangedDic)
        self._StarUpTailFeedCount = self:_CalcStarUpTailFeedCount()
        self:_BuildExchangedList(self._TempExchangedDic, self._StarUpExchangedList)
    end

    -- 尝试消耗一波技能用的开销
    if self._OneKeyCultureModel:IsCultureSelected(XPartnerEnum.CultureType.SkillLevelUp) then
        table.clear(self._TempExchangedDic)
        self._SkillConsumeIndex = self:_ConsumeMOList(self._CostItemModel:GetSkillMOList(), self._TempExchangedDic)
        self:_BuildExchangedList(self._TempExchangedDic, self._SkillExchangedList)
    end

    -- 汇总开销
    self:_BuildConsumedListByMOList(self._CostItemModel:GetLevelUpMOList(), self._LevelUpConsumeIndex, self._LevelUpConsumedList)
    self:_BuildConsumedListByMOList(self._CostItemModel:GetStarUpMOList(), self._StarUpConsumeIndex, self._StarUpConsumedList)
    self:_AppendStarUpTailFeedConsumed()
    self:_BuildConsumedListByMOList(self._CostItemModel:GetSkillMOList(), self._SkillConsumeIndex, self._SkillConsumedList)

    -- 汇总兑换货币总花费
    self:_BuildExchangedList(self._ExchangeCostDic, self._ExchangeCostList)

    -- log
end

--endregion 



---region public Get

---@return number
function XPartnerOneKeyCultureCommitControl:GetLevelUpConsumeIndex()
    return self._LevelUpConsumeIndex
end

---@return number
function XPartnerOneKeyCultureCommitControl:GetStarUpConsumeIndex()
    return self._StarUpConsumeIndex
end

---@return boolean
function XPartnerOneKeyCultureCommitControl:HasStarUpTailFeed()
    return self._StarUpTailFeedCount > 0
end

---@return number
function XPartnerOneKeyCultureCommitControl:GetSkillConsumeIndex()
    return self._SkillConsumeIndex
end

---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureCommitControl:GetLevelUpConsumedList()
    return self._LevelUpConsumedList
end

---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureCommitControl:GetStarUpConsumedList()
    return self._StarUpConsumedList
end

---@return number
function XPartnerOneKeyCultureCommitControl:GetCurCostPartnerChipCount()
    local XPartnerEnum = XMVCA.XPartner.Enum
    for _, item in ipairs(self._StarUpConsumedList) do
        if item.Id == XPartnerEnum.XPartnerQualityClip then
            return item.Count
        end
    end
    return 0
end

---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureCommitControl:GetSkillConsumedList()
    return self._SkillConsumedList
end

--region 兑换结果 Get

---@return table<{Id: number, Count: number}> 升级升阶批次通过兑换补足的材料
function XPartnerOneKeyCultureCommitControl:GetLevelUpExchangedList()
    return self._LevelUpExchangedList
end

---@return table<{Id: number, Count: number}> 升星批次通过兑换补足的材料
function XPartnerOneKeyCultureCommitControl:GetStarUpExchangedList()
    return self._StarUpExchangedList
end

---@return table<{Id: number, Count: number}> 技能升级批次通过兑换补足的材料
function XPartnerOneKeyCultureCommitControl:GetSkillExchangedList()
    return self._SkillExchangedList
end

---@return table<{ItemId: number, ShopId: number, GoodsId: number, Times: number, GainCount: number, ConsumeList: table}> 兑换执行计划（按发生顺序）
function XPartnerOneKeyCultureCommitControl:GetExchangePlanList()
    return self._ExchangePlanList
end

---@return table<{Id: number, Count: number}> 兑换花费的货币汇总
function XPartnerOneKeyCultureCommitControl:GetExchangeCostList()
    return self._ExchangeCostList
end

---@return boolean 本次计算是否存在兑换
function XPartnerOneKeyCultureCommitControl:HasExchange()
    return #self._ExchangePlanList > 0
end

--endregion

---@return number 已选狗粮辅助机 + 碎片数量
function XPartnerOneKeyCultureCommitControl:GetSelectFoodCount()
    local commitModel = self._OneKeyCultureModel:GetCommitModel()
    return commitModel:GetSelectFoodCount()
            + commitModel:GetSelectClipCount()
            + self:GetSelectOreExchangeClipCount()
end

---@return table<number, boolean> 选中狗粮辅助机 Id 字典
function XPartnerOneKeyCultureCommitControl:GetSelectFoodDic()
    return self._OneKeyCultureModel:GetCommitModel():GetSelectFoodDic()
end

---@return number 选中的散碎片数量（折算为狗粮只数）
function XPartnerOneKeyCultureCommitControl:GetSelectClipCount()
    return self._OneKeyCultureModel:GetCommitModel():GetSelectClipCount()
end

---@return number 选中的矿石兑换碎片数量（折算为狗粮只数）
function XPartnerOneKeyCultureCommitControl:GetSelectOreExchangeClipCount()
    if not self._MainControl:IsAutoExchange() then
        return 0
    end
    return self._OneKeyCultureModel:GetCommitModel():GetSelectOreExchangeClipCount()
end

---@return number 选中的矿石兑换格实际需要兑换的碎片数
function XPartnerOneKeyCultureCommitControl:GetSelectOreExchangeChipCount()
    return self._MainControl:GetFoodSelectControl():GetSelectOreExchangeChipCount()
end

---@return table<number, boolean>
function XPartnerOneKeyCultureCommitControl:GetSelectClipIndexDic()
    return self._OneKeyCultureModel:GetCommitModel():GetSelectClipDic()
end

---@return table<number, boolean>
function XPartnerOneKeyCultureCommitControl:GetSelectOreExchangeClipIndexDic()
    return self._OneKeyCultureModel:GetCommitModel():GetSelectOreExchangeClipDic()
end

--- 批量追加兑换出来的辅助机 Id 到选中狗粮列表
---@param ids number[]
function XPartnerOneKeyCultureCommitControl:AddExchangedFoodIds(ids)
    self._OneKeyCultureModel:GetCommitModel():AddExchangedFoodIds(ids)
end

--- 清理选中的碎片索引（兑换完成后调用）
function XPartnerOneKeyCultureCommitControl:ClearSelectClip()
    self._OneKeyCultureModel:GetCommitModel():ClearSelectClip()
end

--- 从选中狗粮列表中移除已消耗的辅助机 Id
---@param ids number[]
function XPartnerOneKeyCultureCommitControl:RemoveSelectFood(ids)
    self._OneKeyCultureModel:GetCommitModel():RemoveSelectFood(ids)
end

---endregion

--region 养成选项勾选

---@param cultureType XPartnerEnum.CultureType
---@param isSelected boolean
function XPartnerOneKeyCultureCommitControl:SetCultureSelectedWithNotify(cultureType, isSelected)
    self._OneKeyCultureModel:SetCultureSelected(cultureType, isSelected)
    self._MainControl:GetRootControl():DispatchEvent(XMVCA.XPartner.EventIds.EVENT_CULTURE_SELECT_CHANGE, cultureType)
end

---@param cultureType XPartnerEnum.CultureType
---@return boolean
function XPartnerOneKeyCultureCommitControl:IsCultureSelected(cultureType)
    return self._OneKeyCultureModel:IsCultureSelected(cultureType)
end

--endregion

--region 预览 - 从 index 求解可达成结果

--- 等级突破可达到的等级
---@return number
function XPartnerOneKeyCultureCommitControl:GetCanReachLevel()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    local index = self._LevelUpConsumeIndex
    if index == 0 then
        return partner:GetLevel()
    end
    -- MO[i] 覆盖突破阶段 curBt+i-1，消费到第 index 个 = 到达该阶段等级上限
    local curBt = partner:GetBreakthrough()
    local targetBt = math.min(curBt + index - 1, partner:GetBreakthroughLimit())
    return partner:GetBreakthroughLevelLimit(targetBt)
end

--- 等级突破可达到的突破阶级（从消费原子中分析）
---@return number
function XPartnerOneKeyCultureCommitControl:GetCanReachBreakthrough()
    local partner = self._MainControl:GetCurPartnerEntity()
    local index = self._LevelUpConsumeIndex
    if index == 0 then
        return partner:GetBreakthrough()
    end

    -- 反向遍历到第一个 BreakUp MO，它的 targetBreakthrough 是突破前的阶段，+1 即为当前
    local levelUpMOList = self._CostItemModel:GetLevelUpMOList()
    local XPartnerEnum = XMVCA.XPartner.Enum
    for i = math.min(index, #levelUpMOList), 1, -1 do
        local mo = levelUpMOList[i]
        if mo:GetCultureType() == XPartnerEnum.CultureType.BreakUp then
            return mo:GetTargetBreakUpData() + 1
        end
    end
    return partner:GetBreakthrough()
end

--- 进化升阶可达到的品质
---@return number
function XPartnerOneKeyCultureCommitControl:GetCanReachQuality()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end
    local index = self._StarUpConsumeIndex
    if index == 0 then
        return partner:GetQuality()
    end
    return math.min(partner:GetQuality() + index, partner:GetQualityLimit())
end

--- 技能升级后每个技能的等级
---@return table<number, number> { [skillId] = level }
function XPartnerOneKeyCultureCommitControl:GetCanReachSkillLevels()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return table.empty
    end

    local result = self._SkillLevelResult
    table.clear(result)

    local remaining = self._SkillConsumeIndex

    local mainList = partner:GetCarryMainSkillGroupList()
    local passiveList = partner:GetCarryPassiveSkillGroupList()

    -- 先初始化为当前等级
    for _, entity in ipairs(mainList) do
        result[entity:GetId()] = entity:GetLevel()
    end
    for _, entity in ipairs(passiveList) do
        result[entity:GetId()] = entity:GetLevel()
    end

    -- 按 MO 创建顺序分配 consumed index
    for _, entity in ipairs(mainList) do
        if remaining <= 0 then break end
        local curLevel = entity:GetLevel()
        local maxLevel = entity:GetLevelLimit()
        local gained = math.min(remaining, maxLevel - curLevel)
        result[entity:GetId()] = curLevel + gained
        remaining = remaining - gained
    end
    for _, entity in ipairs(passiveList) do
        if remaining <= 0 then break end
        local curLevel = entity:GetLevel()
        local maxLevel = entity:GetLevelLimit()
        local gained = math.min(remaining, maxLevel - curLevel)
        result[entity:GetId()] = curLevel + gained
        remaining = remaining - gained
    end

    return result
end

--- 技能升级后的平均等级
---@return number
function XPartnerOneKeyCultureCommitControl:GetCanReachSkillAvgLevel()
    local levels = self:GetCanReachSkillLevels()
    local total = 0
    local count = 0
    for _, level in pairs(levels) do
        total = total + level
        count = count + 1
    end
    if count == 0 then
        return 0
    end
    return math.floor(total / count)
end

--endregion



---region 内部 - 虚拟池

function XPartnerOneKeyCultureCommitControl:_ClearResult()
    table.clear(self._VirtualPool)
    table.clear(self._LevelUpConsumedList)
    table.clear(self._StarUpConsumedList)
    table.clear(self._SkillConsumedList)
    self._LevelUpConsumeIndex = 0
    self._StarUpConsumeIndex = 0
    self._SkillConsumeIndex = 0
    self._StarUpTailFeedCount = 0
    table.clear(self._SkillLevelResult)
    table.clear(self._LevelUpExchangedList)
    table.clear(self._StarUpExchangedList)
    table.clear(self._SkillExchangedList)
    table.clear(self._ExchangePlanList)
    table.clear(self._ExchangeCostList)
    table.clear(self._ExchangeCostDic)
end

 
---@param moList XPartnerOneKeyCultureBaseCostItemMO[]
---@param count number
---@param outList table<{Id: number, Count: number}>
function XPartnerOneKeyCultureCommitControl:_BuildConsumedListByMOList(moList, count, outList)
    table.clear(outList)
    local mergedDic = {}
    for i = 1, count do
        local mo = moList[i]
        if mo then
            for _, item in ipairs(mo:GetNeedList()) do
                mergedDic[item.Id] = (mergedDic[item.Id] or 0) + item.Count
            end
        end
    end

    for id, itemCount in pairs(mergedDic) do
        if itemCount > 0 then
            table.insert(outList, { Id = id, Count = itemCount })
        end
    end
end

--- 从 BaseCostControl 初始化虚拟持有池
function XPartnerOneKeyCultureCommitControl:_InitVirtualPool()
    local XPartnerEnum = XMVCA.XPartner.Enum
    local itemIdSet = self._ItemIdSet
    table.clear(itemIdSet)

    local function CollectItemIds(costList)
        for _, item in ipairs(costList) do
            itemIdSet[item.Id] = true
        end
    end

    CollectItemIds(self._CostItemModel:GetLevelUpAllCostList())
    CollectItemIds(self._CostItemModel:GetStarUpAllCostList())
    CollectItemIds(self._CostItemModel:GetSkillAllCostList())

    for itemId in pairs(itemIdSet) do
        if itemId == XPartnerEnum.XPartnerQualityClip then
            self._VirtualPool[itemId] = self:_GetStarUpPartnerHaveCount()
        else
            self._VirtualPool[itemId] = self:_GetItemHaveCount(itemId)
        end
    end
end

---@param itemId number
---@return number
function XPartnerOneKeyCultureCommitControl:_GetItemHaveCount(itemId)
    return XDataCenter.ItemManager.GetCount(itemId)
end

---@return number
function XPartnerOneKeyCultureCommitControl:_GetStarUpPartnerHaveCount()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local chipPerPartner = partner:GetChipNeedCount()
    local commitModel = self._OneKeyCultureModel:GetCommitModel()
    local totalChips = 0

    -- 选中狗粮辅助机的碎片
    local selectFoodDic = commitModel:GetSelectFoodDic()
    if next(selectFoodDic) then
        local list = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partner:GetId())
        for _, entity in ipairs(list) do
            if selectFoodDic[entity:GetId()] then
                totalChips = totalChips + entity:GetChipCurCount()
            end
        end
    end

    -- 选中的散碎片和矿石兑换碎片（每个已折算为一只狗粮）
    local selectClipCount = commitModel:GetSelectClipCount()
    local selectOreExchangeClipCount = self:GetSelectOreExchangeClipCount()
    return math.floor(totalChips / chipPerPartner) + selectClipCount + selectOreExchangeClipCount
end

---@return number
function XPartnerOneKeyCultureCommitControl:_CalcStarUpTailFeedCount()
    local XPartnerEnum = XMVCA.XPartner.Enum
    local nextMO = self._CostItemModel:GetStarUpMOList()[self._StarUpConsumeIndex + 1]
    if not nextMO then
        return 0
    end

    return self._VirtualPool[XPartnerEnum.XPartnerQualityClip] or 0
end

function XPartnerOneKeyCultureCommitControl:_AppendStarUpTailFeedConsumed()
    local tailFeedCount = self._StarUpTailFeedCount
    if tailFeedCount <= 0 then
        return
    end

    -- 之前可能没消耗。所以这里要追加
    local XPartnerEnum = XMVCA.XPartner.Enum
    for _, item in ipairs(self._StarUpConsumedList) do
        if item.Id == XPartnerEnum.XPartnerQualityClip then
            item.Count = item.Count + tailFeedCount
            return
        end
    end
    table.insert(self._StarUpConsumedList, {
        Id = XPartnerEnum.XPartnerQualityClip,
        Count = tailFeedCount,
    })
end

--- 逐个原子尝试消费，返回成功消费的个数
---@param moList XPartnerOneKeyCultureBaseCostItemMO[]
---@param exchangedDic table<number, number> 该批次兑换产物输出字典 { [itemId] = count }
---@return number
function XPartnerOneKeyCultureCommitControl:_ConsumeMOList(moList, exchangedDic)
    for i, mo in ipairs(moList) do
        if not self:_TryConsumeMO(mo, exchangedDic) then
            return i - 1
        end
    end
    return #moList
end

--- 尝试消费单个原子，够则扣减，不够且开启自动兑换时尝试从虚拟池发起兑换补足
--- 校验期只写 _TempDeltaPool / _TempPlanList，整单通过后统一提交，失败不污染虚拟池
---@param mo XPartnerOneKeyCultureBaseCostItemMO
---@param exchangedDic table<number, number>
---@return boolean
function XPartnerOneKeyCultureCommitControl:_TryConsumeMO(mo, exchangedDic)
    local XPartnerEnum = XMVCA.XPartner.Enum
    local isAutoExchange = self._OneKeyCultureModel:IsAutoExchange()
    local deltaPool = self._TempDeltaPool
    local planList = self._TempPlanList
    table.clear(deltaPool)
    table.clear(planList)

    -- 校验：逐材料检查，不足则尝试规划兑换
    for _, item in ipairs(mo:GetNeedList()) do
        local have = self:_GetPoolCount(item.Id) + (deltaPool[item.Id] or 0)
        local lack = item.Count - have
        if lack > 0 then
            -- 碎片/狗粮是虚拟 Id，不走道具兑换
            if not isAutoExchange or item.Id == XPartnerEnum.XPartnerQualityClip then
                return false
            end
            if not self:_TryPlanExchange(item.Id, lack, deltaPool, planList) then
                return false
            end
        end
        deltaPool[item.Id] = (deltaPool[item.Id] or 0) - item.Count
    end

    -- 整单通过，提交：兑换计划入全局记录
    for _, plan in ipairs(planList) do
        table.insert(self._ExchangePlanList, plan)
        exchangedDic[plan.ItemId] = (exchangedDic[plan.ItemId] or 0) + plan.GainCount
        for _, consume in ipairs(plan.ConsumeList) do
            local costCount = consume.ConsumeCount * plan.Times
            self._ExchangeCostDic[consume.ConsumeId] = (self._ExchangeCostDic[consume.ConsumeId] or 0) + costCount
        end
    end

    -- 提交：delta 合入虚拟池
    for itemId, delta in pairs(deltaPool) do
        self._VirtualPool[itemId] = self:_GetPoolCount(itemId) + delta
    end

    return true
end

--- 规划一次兑换补足：选可负担的路线，货币在虚拟池（含 delta）扣减，产物加入 delta
---@param itemId number 缺少的材料 Id
---@param lack number 缺口数量
---@param deltaPool table<number, number>
---@param planList table
---@return boolean
function XPartnerOneKeyCultureCommitControl:_TryPlanExchange(itemId, lack, deltaPool, planList)
    local info = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId)
    if not info or XTool.IsTableEmpty(info.ShopIdList) then
        return false
    end

    -- 逐路线尝试，取第一条货币足够的路线（单层兑换，不递归）
    for routeIndex = 1, #info.ShopIdList do
        local rewardCount = info.RewardCountList[routeIndex]
        local consumeList = info.ConsumeList[routeIndex]
        if XTool.IsNumberValid(rewardCount) and not XTool.IsTableEmpty(consumeList) then
            local times = math.ceil(lack / rewardCount)
            local canAfford = true
            for _, consume in ipairs(consumeList) do
                local haveCurrency = self:_GetPoolCount(consume.ConsumeId) + (deltaPool[consume.ConsumeId] or 0)
                if haveCurrency < consume.ConsumeCount * times then
                    canAfford = false
                    break
                end
            end

            if canAfford then
                for _, consume in ipairs(consumeList) do
                    deltaPool[consume.ConsumeId] = (deltaPool[consume.ConsumeId] or 0) - consume.ConsumeCount * times
                end
                deltaPool[itemId] = (deltaPool[itemId] or 0) + times * rewardCount
                table.insert(planList, {
                    ItemId = itemId,
                    ShopId = info.ShopIdList[routeIndex],
                    GoodsId = info.GoodsIdList[routeIndex],
                    Times = times,
                    GainCount = times * rewardCount,
                    ConsumeList = consumeList,
                })
                return true
            end
        end
    end

    return false
end

--- 读虚拟池数量，未收录的 Id（如兑换货币）惰性初始化为实际持有量
---@param itemId number
---@return number
function XPartnerOneKeyCultureCommitControl:_GetPoolCount(itemId)
    local count = self._VirtualPool[itemId]
    if not count then
        count = self:_GetItemHaveCount(itemId)
        self._VirtualPool[itemId] = count
    end
    return count
end

--- 兑换产物字典转列表输出
---@param exchangedDic table<number, number>
---@param outList table<{Id: number, Count: number}>
function XPartnerOneKeyCultureCommitControl:_BuildExchangedList(exchangedDic, outList)
    table.clear(outList)
    for itemId, count in pairs(exchangedDic) do
        if count > 0 then
            table.insert(outList, { Id = itemId, Count = count })
        end
    end
end

---endregion

--region log

function XPartnerOneKeyCultureCommitControl:LogCommitData()
    local sb = {}
    local partner = self._MainControl:GetCurPartnerEntity()
    table.insert(sb, "======== CommitControl Log ========")
    table.insert(sb, string.format("Partner: %s Id:%s", partner and partner:GetName() or "nil", tostring(partner and partner:GetId())))
    table.insert(sb, string.format("[LevelUp] consumeIndex = %d", self._LevelUpConsumeIndex))
    table.insert(sb, string.format("[StarUp]  consumeIndex = %d", self._StarUpConsumeIndex))
    table.insert(sb, string.format("[Skill]   consumeIndex = %d", self._SkillConsumeIndex))

    local levelUpMOList = self._CostItemModel:GetLevelUpMOList()
    table.insert(sb, string.format("[LevelUp] MO count=%d consumed=%d", #levelUpMOList, self._LevelUpConsumeIndex))
    for i, mo in ipairs(levelUpMOList) do
        table.insert(sb, self:_FormatMO(i, mo, self._LevelUpConsumeIndex))
    end

    local starUpMOList = self._CostItemModel:GetStarUpMOList()
    table.insert(sb, string.format("[StarUp]  MO count=%d consumed=%d", #starUpMOList, self._StarUpConsumeIndex))
    for i, mo in ipairs(starUpMOList) do
        table.insert(sb, self:_FormatMO(i, mo, self._StarUpConsumeIndex))
    end

    local skillMOList = self._CostItemModel:GetSkillMOList()
    table.insert(sb, string.format("[Skill]   MO count=%d consumed=%d", #skillMOList, self._SkillConsumeIndex))
    for i, mo in ipairs(skillMOList) do
        table.insert(sb, self:_FormatMO(i, mo, self._SkillConsumeIndex))
    end

    table.insert(sb, "[VirtualPool] remaining:")
    for itemId, count in pairs(self._VirtualPool) do
        table.insert(sb, string.format("  itemId=%d remaining=%d", itemId, count))
    end

    table.insert(sb, "[ConsumedList]")
    table.insert(sb, "  [LevelUp] " .. self:_FormatConsumedList(self._LevelUpConsumedList))
    table.insert(sb, "  [StarUp]  " .. self:_FormatConsumedList(self._StarUpConsumedList))
    table.insert(sb, "  [Skill]   " .. self:_FormatConsumedList(self._SkillConsumedList))

    table.insert(sb, "[ExchangedList]")
    table.insert(sb, "  [LevelUp] " .. self:_FormatConsumedList(self._LevelUpExchangedList))
    table.insert(sb, "  [StarUp]  " .. self:_FormatConsumedList(self._StarUpExchangedList))
    table.insert(sb, "  [Skill]   " .. self:_FormatConsumedList(self._SkillExchangedList))
    table.insert(sb, "  [Cost]    " .. self:_FormatConsumedList(self._ExchangeCostList))
    table.insert(sb, string.format("[ExchangePlan] count=%d", #self._ExchangePlanList))
    for i, plan in ipairs(self._ExchangePlanList) do
        table.insert(sb, string.format("  Plan[%d] itemId=%d shopId=%d goodsId=%d times=%d gain=%d",
            i, plan.ItemId, plan.ShopId, plan.GoodsId, plan.Times, plan.GainCount))
    end

    table.insert(sb, "======== End ========")
    XLog.Error(table.concat(sb, "\n"))
end

---@param index number
---@param mo XPartnerOneKeyCultureBaseCostItemMO
---@param consumeIndex number
---@return string
function XPartnerOneKeyCultureCommitControl:_FormatMO(index, mo, consumeIndex)
    local parts = {}
    for _, item in ipairs(mo:GetNeedList()) do
        table.insert(parts, string.format("Id=%d Count=%d", item.Id, item.Count))
    end

    local target = self:_FormatTarget(mo)
    local mark = index <= consumeIndex and "✓" or "✗"
    return string.format("  MO[%d] %s | target=%s | %s", index, mark, target, table.concat(parts, ", "))
end

---@param mo XPartnerOneKeyCultureBaseCostItemMO
---@return string
function XPartnerOneKeyCultureCommitControl:_FormatTarget(mo)
    local cultureType = mo:GetCultureType()
    local XPartnerEnum = XMVCA.XPartner.Enum

    if cultureType == XPartnerEnum.CultureType.LevelUp then
        local fromLv, toLv = mo:GetTargetLevelupData()
        return string.format("Lv%d→Lv%d", fromLv, toLv)
    elseif cultureType == XPartnerEnum.CultureType.BreakUp then
        return string.format("Bt%d", mo:GetTargetBreakUpData())
    elseif cultureType == XPartnerEnum.CultureType.StarUp then
        return string.format("Q%d", mo:GetTargetStarUpData())
    elseif cultureType == XPartnerEnum.CultureType.SkillLevelUp then
        local skillId, lv = mo:GetTargetSkillUpData()
        return string.format("Skill%d Lv%d", skillId, lv)
    end
    return "unknown"
end

---@param list table<{Id: number, Count: number}>
---@return string
function XPartnerOneKeyCultureCommitControl:_FormatConsumedList(list)
    if not list or #list == 0 then
        return "(empty)"
    end
    local parts = {}
    for _, item in ipairs(list) do
        table.insert(parts, string.format("Id=%d x%d", item.Id, item.Count))
    end
    return table.concat(parts, ", ")
end

--endregion

return XPartnerOneKeyCultureCommitControl
