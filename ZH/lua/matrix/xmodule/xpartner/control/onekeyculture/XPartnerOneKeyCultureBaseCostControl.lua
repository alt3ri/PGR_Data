---@class XPartnerOneKeyCultureBaseCostControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerOneKeyCultureControl
--- 职责：生成完备的 BaseCostItemModel（消费原子），以及整理/查询出结果
local XPartnerOneKeyCultureBaseCostControl = XClass(XControl, "XPartnerOneKeyCultureBaseCostControl")

function XPartnerOneKeyCultureBaseCostControl:OnInit()
    self._CostItemModel = self._Model:GetOneKeyCultureModel():GetBaseCostItemModel()
end     

function XPartnerOneKeyCultureBaseCostControl:AddAgencyEvent()
end

function XPartnerOneKeyCultureBaseCostControl:RemoveAgencyEvent()
end

function XPartnerOneKeyCultureBaseCostControl:OnRelease()
end

---region getCost - 获取需要

--- 获取升级原子列表
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostControl:GetLevelUpMOList()
    return self._CostItemModel:GetLevelUpMOList()
end

--- 获取升阶原子列表
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostControl:GetStarUpMOList()
    return self._CostItemModel:GetStarUpMOList()
end

--- 获取技能原子列表
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostControl:GetSkillMOList()
    return self._CostItemModel:GetSkillMOList()
end

--- 获取升级材料总汇（合并所有阶段）
---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostControl:GetLevelUpTotalCostData()
    return self._CostItemModel:GetLevelUpAllCostList()
end

--- 获取升阶材料数据
---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostControl:GetStarUpCostData()
    return self._CostItemModel:GetStarUpAllCostList()
end

--- 获取技能升级材料数据
---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostControl:GetSkillCostData()
    return self._CostItemModel:GetSkillAllCostList()
end

--- 升到满阶需要的 0 阶辅助机个数（从 MOList 累加 XPartnerQualityClip）
---@return number
function XPartnerOneKeyCultureBaseCostControl:GetStarUpPartnerNeedCount()
    local XPartnerEnum = XMVCA.XPartner.Enum
    local count = 0
    for _, mo in ipairs(self._CostItemModel:GetStarUpMOList()) do
        for _, item in ipairs(mo:GetNeedList()) do
            if item.Id == XPartnerEnum.XPartnerQualityClip then
                count = count + item.Count
            end
        end
    end
    return count
end

---endregion

---region getCurHave - 当前持有获取接口

---@param itemId number
---@return number
function XPartnerOneKeyCultureBaseCostControl:GetItemHaveCount(itemId)
    return XDataCenter.ItemManager.GetCount(itemId)
end

--- 当前折合的 0 阶辅助机个数（狗粮辅助机 + 散碎碎片；开启自动兑换时再加矿石可兑换碎片）
---@return number
function XPartnerOneKeyCultureBaseCostControl:GetStarUpPartnerHaveCount()
    local partner = self._MainControl:GetCurPartnerEntity()
    if not partner then
        return 0
    end

    local chipPerPartner = partner:GetChipNeedCount()
    if not chipPerPartner or chipPerPartner <= 0 then
        return 0
    end

    local list = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partner:GetId())
    local ownFoodChips = 0
    for _, entity in ipairs(list) do
        ownFoodChips = ownFoodChips + entity:GetChipCurCount()
    end

    local XPartnerUtil = XMVCA.XPartner.Util
    local chipItemId = partner:GetChipItemId()
    local looseChips = XPartnerUtil.GetChipHaveCount(chipItemId)
    local oreChips = 0
    if self._MainControl:IsAutoExchange() then
        oreChips = XPartnerUtil.GetOreExchangeChipCount(chipItemId)
    end

    local totalChips = ownFoodChips + looseChips + oreChips
    return math.floor(totalChips / chipPerPartner)
end

---endregion

---region 内部 - 统一计算入口

function XPartnerOneKeyCultureBaseCostControl:CalcAllCostData()
    local partnerId = self._Model:GetOneKeyCultureModel():GetCurPartnerId()

    self._CostItemModel:ClearAll()

    if not partnerId then
        return
    end

    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
    if not partner then
        return
    end

    self:_CalcLevelUpCostData(partner)
    self:_CalcStarUpCostData(partner)
    self:_CalcSkillCostData(partner)

    self._CostItemModel:BuildAllCostLists()
end

---endregion

---region 内部 - 升级计算（按阶段原子化）

function XPartnerOneKeyCultureBaseCostControl:_CalcLevelUpCostData(partner)
    if partner:GetIsMaxBreakthrough() and partner:GetIsLevelMax() then
        return
    end

    local XPartnerEnum = XMVCA.XPartner.Enum
    local curBreakthrough = partner:GetBreakthrough()
    local maxBreakthrough = partner:GetBreakthroughLimit()
    local curLevel = partner:GetLevel()
    local curExp = partner:GetExp()

    for breakthrough = curBreakthrough, maxBreakthrough do
        local levelLimit = partner:GetBreakthroughLevelLimit(breakthrough)

        -- 该阶段升级所需经验
        local needExp = 0
        local startLevel = (breakthrough == curBreakthrough) and curLevel or 1
        for level = startLevel, levelLimit - 1 do
            needExp = needExp + partner:GetLevelUpInfoExp(breakthrough, level)
        end
        if breakthrough == curBreakthrough then
            needExp = needExp - curExp
        end

        -- 已达该阶等级上限（如当前正好卡在突破口）时无需喂经验，不生成空 MO
        if needExp > 0 then
            local mo = self._CostItemModel:CreateMO(XPartnerEnum.CultureType.LevelUp)
            mo:SetTargetLevelupData(startLevel, levelLimit)

            local expCostItems = {}
            self:_FillExpItems(expCostItems, needExp)
            for id, count in pairs(expCostItems) do
                if count > 0 then
                    mo:AppendItem(id, count)
                end
            end

            -- 喂经验道具的螺母手续费（与 PartnerLevelUpRequest 内 GetEatItemsCostMoney 一致），必须计入模拟池
            local feedCostMoney = XDataCenter.PartnerManager.GetEatItemsCostMoney(expCostItems)
            if feedCostMoney > 0 then
                mo:AppendItem(XDataCenter.ItemManager.ItemId.Coin, feedCostMoney)
            end
        end


        -- 非最后阶段才创建突破 MO
        if breakthrough < maxBreakthrough then
            local breakUPMO = self._CostItemModel:CreateMO(XPartnerEnum.CultureType.BreakUp)
            breakUPMO:SetTargetBreakUpData(breakthrough)
            -- 突破消耗取当前阶配置：从 b 突破到 b+1 的花费定义在 cfg[b]（与 PartnerBreakThroughRequest 内 GetBreakthroughItem() 一致）
            local breakItems = partner:GetBreakthroughCostItem(breakthrough)
            for _, item in ipairs(breakItems) do
                breakUPMO:AppendItem(item.Id, item.Count)
            end
        end
    end
end

-- 贪心填充经验道具
function XPartnerOneKeyCultureBaseCostControl:_FillExpItems(costItemDic, needExp)
    local expItemList = XDataCenter.PartnerManager.GetExpItemList()
    local ratedExp = needExp

    for _, item in ipairs(expItemList) do
        local itemId = item.Id
        local itemExp = item.GetExp()
        local haveCount = XDataCenter.ItemManager.GetCount(itemId)

        local needCount = math.floor(ratedExp / itemExp)
        if needCount > 0 then
            local useCount = math.min(needCount, haveCount)
            if useCount > 0 then
                costItemDic[itemId] = (costItemDic[itemId] or 0) + useCount
                ratedExp = ratedExp - useCount * itemExp
            end
        end
    end

    if ratedExp > 0 then
        -- 先尝试向上取整补1个（有剩余持有时）
        for i = #expItemList, 1, -1 do
            local item = expItemList[i]
            local itemId = item.Id
            local itemExp = item.GetExp()
            local haveCount = XDataCenter.ItemManager.GetCount(itemId)
            local alreadyUse = costItemDic[itemId] or 0
            if haveCount - alreadyUse > 0 then
                costItemDic[itemId] = alreadyUse + 1
                ratedExp = ratedExp - itemExp
                break
            end
        end
    end

    -- 持有全部用完后仍有缺口，剩余经验全部折算为大经验包
    if ratedExp > 0 then
        local bigExpItem = expItemList[1]
        local bigExpItemId = bigExpItem.Id
        local bigExpValue = bigExpItem.GetExp()
        local alreadyUse = costItemDic[bigExpItemId] or 0
        local exchangeCount = math.ceil(ratedExp / bigExpValue)
        costItemDic[bigExpItemId] = alreadyUse + exchangeCount
    end
end

---endregion

---region 内部 - 升阶计算（按星阶原子化）
--- 每个星阶一个原子：喂养多少 clip + 花多少螺母，到达下一 quality

function XPartnerOneKeyCultureBaseCostControl:_CalcStarUpCostData(partner)
    if partner:GetIsMaxQuality() then
        return
    end

    local XPartnerEnum = XMVCA.XPartner.Enum
    local curQuality = partner:GetQuality()
    local maxQuality = partner:GetQualityLimit()
    local chipPerPartner = partner:GetChipNeedCount()

    if not chipPerPartner or chipPerPartner <= 0 then
        return
    end

    -- 碎片进度是累计池，每阶只计算当前累计进度尚未覆盖的区间
    local starSchedule = partner:GetStarSchedule()
    local prevThreshold = curQuality > partner:GetInitQuality() and partner:GetClipMaxCount(curQuality - 1) or 0

    for quality = curQuality, maxQuality - 1 do
        local threshold = partner:GetClipMaxCount(quality)
        local coveredThreshold = math.max(starSchedule, prevThreshold)
        local chipsNeeded = math.max(0, threshold - coveredThreshold)
        local partnerCount = math.ceil(chipsNeeded / chipPerPartner)

        local mo = self._CostItemModel:CreateMO(XPartnerEnum.CultureType.StarUp)
        mo:SetTargetStarUpData(quality + 1)
        mo:AppendItem(XPartnerEnum.XPartnerQualityClip, partnerCount)

        local money = partner:GetQualityEvolutionMoney(quality)
        if money and money.Count > 0 then
            mo:AppendItem(money.Id, money.Count)
        end

        prevThreshold = threshold
    end
end

---endregion

---region 内部 - 技能计算（按技能按等级原子化）

function XPartnerOneKeyCultureBaseCostControl:_CalcSkillCostData(partner)
    local XPartnerEnum = XMVCA.XPartner.Enum
    local costItems = partner:GetSkillUpgradeCostItem()
    if not costItems or #costItems == 0 then
        return
    end

    -- 主动技
    local carryList = partner:GetCarryMainSkillGroupList()
    for _, entity in ipairs(carryList) do
        local skillId = entity:GetActiveSkillId()
            local curLevel = entity:GetLevel()
            local maxLevel = entity:GetLevelLimit()
            for level = curLevel, maxLevel - 1 do
                local mo = self._CostItemModel:CreateMO(XPartnerEnum.CultureType.SkillLevelUp)
                mo:SetTargetSkillUpData(skillId, level + 1)
                for _, item in ipairs(costItems) do
                    mo:AppendItem(item.Id, item.Count)
                end
            end
    end

    -- 被动技
    carryList = partner:GetCarryPassiveSkillGroupList()
    for _, entity in ipairs(carryList) do
        local skillId = entity:GetActiveSkillId()
            local curLevel = entity:GetLevel()
            local maxLevel = entity:GetLevelLimit()
            for level = curLevel, maxLevel - 1 do
                local mo = self._CostItemModel:CreateMO(XPartnerEnum.CultureType.SkillLevelUp)
                mo:SetTargetSkillUpData(skillId, level + 1)
                for _, item in ipairs(costItems) do
                    mo:AppendItem(item.Id, item.Count)
                end
            end
    end
end

---endregion

return XPartnerOneKeyCultureBaseCostControl
