--- 装备强化子 control：升级 + 突破 相关接口
---@class XEquipStrengthenControl: XControl
---@field private _Model XEquipModel
---@field private _MainControl XEquipControl
---@field private _AwarenessStrengthenTaskInfo XEquipAwarenessStrengthenTaskInfo|nil 意识强化串行任务运行态，异步回调用它校验链路是否仍有效
---@field private _AwarenessStrengthenCallback fun(isSuccess:boolean, errorCode:any)|nil 意识强化链路完成后的业务回调
local XEquipStrengthenControl = XClass(XControl, 'XEquipStrengthenControl')

local XEquipLevelUpConsume = require("XEntity/XEquip/XEquipLevelUpConsume")

---@class XEquipStrengthenAutoExchangeInfo
---@field ItemId number 自动兑换补足的目标道具 Id
---@field ShopId number 兑换商店 Id
---@field GoodsId number 兑换商品 Id
---@field LackCount number 目标道具缺口数量
---@field ExchangeTimes number 补足缺口所需的计划兑换次数
---@field RewardCount number 按计划兑换次数可获得的目标道具数量
---@field AvailableExchangeTimes number 当前兑换材料可支持的兑换次数
---@field AvailableRewardCount number 当前兑换材料可支持获得的目标道具数量
---@field ConsumeList table<number, table> 按计划兑换次数需要消耗的道具列表

---@class XEquipAwarenessStrengthenPreviewResult
---@field TargetLevelUnit number 六件意识共用的目标进度单位
---@field TargetBreakthrough number 参考意识的目标突破次数
---@field TargetLevel number 参考意识的目标等级
---@field BreakMoney number 突破消耗货币
---@field BreakList table<number, table> 突破消耗列表
---@field CanBreakThrough boolean 是否满足突破条件和材料
---@field LevelUpMoney number 升级消耗货币
---@field CostMoney number 总消耗货币
---@field UsedExp number 已消耗经验
---@field LackExp number 剩余缺口经验
---@field SiteResults table<number, table> 每个意识最终到达的突破、等级和单站位操作列表
---@field OperationAwarenessCount number 实际存在升级操作的意识数量
---@field CanLevelUp boolean 是否可完成升级
---@field IsMoneyEnough boolean 螺母是否足够
---@field CanBreakThroughCondition boolean 是否满足突破条件
---@field AutoExchangeInfo table<number, XEquipStrengthenAutoExchangeInfo> 自动兑换信息
---@field IsAutoExchangeConsumeEnough boolean 自动兑换消耗是否足够

---@class XEquipAwarenessStrengthenTargetInfo
---@field Site number 意识穿戴位
---@field EquipId number 意识装备 Id
---@field TemplateId number 意识模板 Id
---@field Breakthrough number 目标突破次数
---@field Level number 目标等级

---@class XEquipAwarenessStrengthenTaskInfo
---@field PreviewResult XEquipAwarenessStrengthenPreviewResult 预览结果
---@field TaskList XEquipAwarenessStrengthenTask[] 任务列表
---@field Index number 当前执行索引

---@class XEquipAwarenessStrengthenTask
---@field Type number 任务类型
---@field Id number 任务 Id
---@field State number 任务状态

---@class XEquipLevelUpAutoExchangeExpItemInfo
---@field ItemId number 自动兑换得到的经验道具 Id
---@field AddExp number 单个自动兑换经验道具提供的经验
---@field CostMoney number 单个自动兑换经验道具的升级螺母消耗

---@class XEquipLevelUpSegmentResult
---@field CanLevelUp boolean 当前突破段是否可达目标等级
---@field UsedExp number 当前突破段实际投入经验
---@field CostMoney number 当前突破段升级消耗货币
---@field RequiredExp number 当前突破段目标等级所需经验
---@field ReachLevel number 当前突破段最终到达等级
---@field ReachExp number 到达 ReachLevel 后的等级内经验

---@class XEquipLevelUpAcrossBreakthroughsParams
---@field TemplateId number 装备模板 Id
---@field Consumes XEquipLevelUpConsume[] 强化消耗池
---@field StartBreakthrough number 起始突破段
---@field StartLevel number 起始等级
---@field StartExp number|nil 起始等级内经验
---@field TargetBreakthrough number 目标突破段
---@field TargetLevel number 目标等级
---@field AutoExchangeExpItemInfo XEquipLevelUpAutoExchangeExpItemInfo|nil 自动兑换经验道具信息
---@field CheckOverflowConfirm boolean|nil 是否检查不可保留经验溢出确认

---@class XEquipLevelUpAcrossBreakthroughsResult
---@field CanLevelUp boolean 是否可完成跨突破段升级
---@field UsedExp number 实际投入经验
---@field CostMoney number 升级消耗货币
---@field LackExp number 距离目标等级仍缺少的经验
---@field ReachBreakthrough number 最终到达突破段
---@field ReachLevel number 最终到达等级
---@field ReachExp number 到达 ReachLevel 后的等级内经验
---@field Operations table<number, table> 升级请求操作列表
---@field ShowExpOverflowConfirm boolean 是否需要提示不可保留经验溢出

---@class XEquipSingleStrengthenPreviewResult: XEquipLevelUpAcrossBreakthroughsResult
---@field TargetLevelUnit number 目标升级单位
---@field TargetBreakthrough number 目标突破次数
---@field TargetLevel number 目标等级
---@field BreakMoney number 突破消耗货币
---@field BreakList table<number, table> 突破消耗列表
---@field CanBreakThrough boolean 是否满足突破条件和材料
---@field CanBreakThroughCondition boolean 是否满足突破条件
---@field LevelUpMoney number 升级消耗货币
---@field CostMoney number 强化总消耗货币
---@field IsMoneyEnough boolean 螺母是否足够
---@field AutoExchangeInfo table<number, XEquipStrengthenAutoExchangeInfo> 自动兑换信息
---@field IsAutoExchangeConsumeEnough boolean 自动兑换消耗是否足够

---@class XEquipStrengthenPreviewOptions
---@field IsAutoExchangeEnabled boolean 是否计算自动兑换补足

---@class XEquipConsumeItemOptions
---@field IncludeItems boolean|nil 是否包含消耗道具，默认 true
---@field ConsumeStarDic table<number, boolean>|nil 星级筛选字典
---@field ForceAutoSelect boolean|nil 是否强制进入自动选择

----------------------------------------
-- 生命周期
----------------------------------------
-- 初始化装备强化 Control。
function XEquipStrengthenControl:OnInit()
end

-- 注册装备强化相关事件。
function XEquipStrengthenControl:AddAgencyEvent()
end

-- 移除装备强化相关事件。
function XEquipStrengthenControl:RemoveAgencyEvent()
end

-- 释放装备强化 Control。
function XEquipStrengthenControl:OnRelease()
    self:CancelAwarenessStrengthen()
end

----------------------------------------
-- 升级基础查询
----------------------------------------
--- 升级单位转换为突破次数和等级。
---@param templateId number 装备模板 Id
---@param levelUnit number 升级单位
---@return number breakthrough 突破次数
---@return number level 等级
function XEquipStrengthenControl:ConvertToBreakThroughAndLevel(templateId, levelUnit)
    return self._Model:ConvertToBreakThroughAndLevel(templateId, levelUnit)
end

--- 突破次数和等级转换为升级单位。
---@param templateId number 装备模板 Id
---@param breakthrough number 突破次数
---@param level number 等级
---@return number levelUnit 升级单位
function XEquipStrengthenControl:ConvertToLevelUnit(templateId, breakthrough, level)
    return self._Model:ConvertToLevelUnit(templateId, breakthrough, level)
end

--- 获取装备最大升级单位（全突破）
---@param templateId number 装备模板 Id
---@return number levelUnit 最大升级单位
function XEquipStrengthenControl:GetEquipMaxLevelUnit(templateId)
    return self._Model:GetEquipMaxLevelUnit(templateId)
end

--- 获取装备当前升级单位（当前突破次数等级之和+当前等级）
---@param equipId number 装备 Id
---@return number levelUnit 当前升级单位
function XEquipStrengthenControl:GetEquipLevelUnit(equipId)
    return self._Model:GetEquipLevelUnit(equipId)
end

--- 获取指定突破阶段和等级的升级配置。
---@param templateId number 装备模板 Id
---@param times number 突破次数
---@param level number 等级
---@return table levelUpCfg 升级配置
function XEquipStrengthenControl:GetLevelUpCfg(templateId, times, level)
    return self._Model:GetLevelUpCfg(templateId, times, level)
end

----------------------------------------
-- 突破
----------------------------------------
--- 获取装备突破次数对应图片
---@param breakthroughTimes number 突破次数
---@return string iconPath 突破图标路径
function XEquipStrengthenControl:GetEquipBreakThroughIcon(breakthroughTimes)
    return self._Model:GetEquipBreakThroughIcon(breakthroughTimes)
end

--- 获取装备模板的最大突破次数和最大等级。
---@param templateId number 装备模板 Id
---@return number maxBreakthrough 最大突破次数
---@return number maxLevel 最大等级
function XEquipStrengthenControl:GetEquipMaxBreakthrough(templateId)
    return self._Model:GetEquipMaxBreakthrough(templateId)
end

--- 获取装备模板在指定突破次数下的等级上限。
---@param templateId number 装备模板 Id
---@param times number 突破次数
---@return number levelLimit 等级上限
function XEquipStrengthenControl:GetBreakthroughLevelLimit(templateId, times)
    return self._Model:GetEquipBreakthroughLevelLimit(templateId, times)
end

--- 获取目标突破次数对应的突破条件 Id。
---@param templateId number 装备模板 Id
---@param breakthrough number 目标突破次数
---@return number|nil conditionId 突破条件 Id
function XEquipStrengthenControl:GetBreakthroughConditionId(templateId, breakthrough)
    local cfgs = self._Model:GetEquipBreakthroughCfgs(templateId)
    for _, config in pairs(cfgs) do
        if config.Times == breakthrough - 1 then
            return config.ConditionId
        end
    end

    return nil
end

-- 检测目标突破次数的条件是否满足
---@param templateId number 装备模板 Id
---@param targetBreakthrough number 目标突破次数
---@return boolean isPass 是否满足条件
---@return string errorDesc 条件未满足提示
function XEquipStrengthenControl:CheckBreakthroughCondition(templateId, targetBreakthrough)
    local conditionId = self:GetBreakthroughConditionId(templateId, targetBreakthrough)
    if conditionId and conditionId ~= 0 then
        return XConditionManager.CheckCondition(conditionId)
    end

    return true, ""
end

--获取装备从当前到目标突破次数总消耗道具
---@param equipId number 装备 Id
---@param targetBreakthrough number 目标突破次数
---@return table<number, table> consumeItems 突破消耗道具列表
---@return boolean canBreakThrough 突破材料是否足够
function XEquipStrengthenControl:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
    return self._Model:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
end

--获取装备从当前到目标突破次数总消耗货币
---@param equipId number 装备 Id
---@param targetBreakthrough number 目标突破次数
---@return number money 突破消耗货币
function XEquipStrengthenControl:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
    return self._Model:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
end

-- 获取该模板从 0 突破到最大突破期间所有可能出现过的突破材料 Id 集合（去重、按 Id 升序）
-- 用于 UI 固定显示槽位：哪怕当前目标不需要某材料，也要把槽位空出来显示 0
---@param templateId number 装备模板 Id
---@return number[] itemIds 突破材料 Id 列表
function XEquipStrengthenControl:GetAllBreakthroughItemIds(templateId)
    local cfgs = self._Model:GetEquipBreakthroughCfgs(templateId)
    local idSet = {}
    if cfgs then
        for _, cfg in pairs(cfgs) do
            if cfg.ItemId then
                for _, id in ipairs(cfg.ItemId) do
                    idSet[id] = true
                end
            end
        end
    end
    local list = {}
    for id in pairs(idSet) do
        table.insert(list, id)
    end
    table.sort(list)
    return list
end

-- 获取六件意识当前最低进度和各自满级进度中的最大值。
---@param equipIds table<number, number> 意识站位 -> 装备 Id
---@return number minLevelUnit 当前最低进度单位
---@return number maxLevelUnit 六件意识各自满级进度单位的最大值
function XEquipStrengthenControl:_GetAwarenessLevelUnitRange(equipIds)
    local minLevelUnit = math.huge
    local maxLevelUnit = 0
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = equipIds[site]
        local equip = assert(self._MainControl:GetEquip(equipId), string.format(
            "XEquipStrengthenControl._GetAwarenessLevelUnitRange error: 缺少意识装备, site=%s, equipId=%s",
            tostring(site), tostring(equipId)))
        minLevelUnit = math.min(minLevelUnit, self:GetEquipLevelUnit(equipId))
        maxLevelUnit = math.max(maxLevelUnit, self:GetEquipMaxLevelUnit(equip.TemplateId))
    end
    return minLevelUnit, maxLevelUnit
end

----------------------------------------
-- 内部工具：强化操作记录
----------------------------------------
-- 创建升级操作记录。
---@return table operation 升级请求操作记录，保存本次升级消耗的装备和道具
local function NewLevelUpOperation()
    return {
        OperationType = 1,
        UseEquipIdDic = {},
        UseItems = {},
    }
end

-- 将一次消耗写入升级操作记录。
---@param operation table 升级请求操作记录
---@param index number 消耗在模拟消耗池中的索引
---@param consume XEquipLevelUpConsume 本次写入的消耗对象
local function AddConsumeToOperation(operation, index, consume)
    local id = consume.Id
    if consume:IsEquip() then
        operation.UseEquipIdDic[id] = true
        return
    end

    local count = (operation.UseItems[id] or 0) + 1
    operation.UseItems[id] = count
end

-- 获取某个消耗对象在操作记录中已使用的数量。
---@param operation table 升级请求操作记录
---@param consume XEquipLevelUpConsume 待查询的消耗对象
---@return number count 操作记录中已使用的数量
local function GetOperationConsumeCount(operation, consume)
    local id = consume.Id
    if consume:IsEquip() then
        return operation.UseEquipIdDic[id] and 1 or 0
    end
    return operation.UseItems[id] or 0
end

-- 从升级操作记录中移除一次或多次消耗。
---@param operation table 升级请求操作记录
---@param index number 消耗在模拟消耗池中的索引
---@param consume XEquipLevelUpConsume 本次回退的消耗对象
---@param remainCount number 回退后该道具仍保留在操作记录中的数量
local function RemoveConsumeFromOperation(operation, index, consume, remainCount)
    local id = consume.Id
    if consume:IsEquip() then
        operation.UseEquipIdDic[id] = nil
        return
    end

    if remainCount <= 0 then
        operation.UseItems[id] = nil
    else
        operation.UseItems[id] = remainCount
    end
end

-- 将自动兑换产生的道具消耗写入操作记录。
---@param operation table 升级请求操作记录
---@param itemId number|nil 自动兑换得到的经验道具 Id
---@param count number|nil 写入操作记录的道具数量
local function AddItemToOperation(operation, itemId, count)
    if not itemId or not count or count <= 0 then
        return
    end
    operation.UseItems[itemId] = (operation.UseItems[itemId] or 0) + count
end

-- 累加自动兑换相关资源数量。
---@param counts table<number, number> 自动兑换资源数量统计
---@param itemId number|nil 自动兑换相关道具 Id
---@param count number|nil 本次累加数量
local function AddAutoExchangeCount(counts, itemId, count)
    if not itemId or not count or count <= 0 then
        return
    end
    counts[itemId] = (counts[itemId] or 0) + count
end

-- 内部工具：升级模拟
----------------------------------------
-- 计算当前突破段从当前等级升级到目标等级还需要的经验。
---@param templateId number 装备模板 Id
---@param breakthrough number 当前突破次数
---@param curLevel number 当前等级
---@param curExp number|nil 当前等级内已有经验
---@param targetLevel number 目标等级
---@return number requiredExp 扣除当前等级内已有经验后的剩余需求经验
function XEquipStrengthenControl:_CalcLevelUpRequiredExp(templateId, breakthrough, curLevel, curExp, targetLevel)
    local requiredExp = 0
    -- 突破配置预提取
    local cfgs = self._Model:GetLevelUpCfgs(templateId, breakthrough)
    if cfgs then
        for level = curLevel, targetLevel - 1 do
            local cfg = cfgs[level]
            if cfg then
                requiredExp = requiredExp + cfg.Exp
            end
        end
    end
    return requiredExp - (curExp or 0)
end

-- 返回的 exp 表示到达返回 level 后，该等级内已填充的经验。
---@param templateId number 装备模板 Id
---@param breakthrough number 当前突破次数
---@param curLevel number 当前等级
---@param curExp number|nil 当前等级内已有经验
---@param targetLevel number 目标等级
---@param addExp number|nil 本次投入经验
---@return number level 可到达等级
---@return number exp 返回等级内已填充的经验
function XEquipStrengthenControl:_CalculateReachLevelInBreakthrough(templateId, breakthrough, curLevel, curExp, targetLevel, addExp)
    local level = curLevel
    local exp = (curExp or 0) + (addExp or 0)
    -- 突破配置预提取
    local cfgs = self._Model:GetLevelUpCfgs(templateId, breakthrough)
    if not cfgs then
        return level, exp
    end
    while level < targetLevel do
        local cfg = cfgs[level]
        if not cfg or exp < cfg.Exp then
            break
        end
        exp = exp - cfg.Exp
        level = level + 1
    end
    return level, exp
end

----------------------------------------
-- 内部工具：意识突破消耗
----------------------------------------
-- 按六件意识各自的模板和目标突破段聚合突破消耗。
---@param targets XEquipAwarenessStrengthenTargetInfo[] 六件意识各自的强化目标
---@return number totalMoney 突破总螺母
---@return table<number, table> breakList { {Id=..., Count=...}, ... } 按 Id 升序
---@return boolean canBreakThrough 突破条件和材料是否都满足
---@return boolean canBreakThroughCondition 突破条件是否全部满足
function XEquipStrengthenControl:_CalcAwarenessBreakthroughCost(targets)
    local itemCountMap = {}
    for _, target in ipairs(targets) do
        for _, itemId in ipairs(self:GetAllBreakthroughItemIds(target.TemplateId)) do
            itemCountMap[itemId] = itemCountMap[itemId] or 0
        end
    end

    local totalMoney, canBreakThroughCondition = 0, true
    for _, target in ipairs(targets) do
        local equip = self._MainControl:GetEquip(target.EquipId)
        if equip.Breakthrough < target.Breakthrough then
            local passCondition = self:CheckBreakthroughCondition(target.TemplateId, target.Breakthrough)
            canBreakThroughCondition = canBreakThroughCondition and passCondition

            local items = self:GetMutiBreakthroughConsumeItems(target.EquipId, target.Breakthrough)
            for _, item in ipairs(items) do
                itemCountMap[item.Id] = (itemCountMap[item.Id] or 0) + item.Count
            end
            totalMoney = totalMoney + self:GetMutiBreakthroughUseMoney(
                target.EquipId, target.Breakthrough)
        end
    end

    local breakList = {}
    local hasEnoughBreakthroughItems = true
    for itemId, itemCount in pairs(itemCountMap) do
        table.insert(breakList, { Id = itemId, Count = itemCount })
        if itemCount > 0 and not XDataCenter.ItemManager.CheckItemCountById(itemId, itemCount) then
            hasEnoughBreakthroughItems = false
        end
    end
    -- 按材料 Id 升序整理意识突破材料列表。
    table.sort(breakList, function(a, b) return a.Id < b.Id end)

    local canBreakThrough = canBreakThroughCondition and hasEnoughBreakthroughItems
    return totalMoney, breakList, canBreakThrough, canBreakThroughCondition
end

----------------------------------------
-- 强化模拟（升级 + 突破多段）
----------------------------------------
-- 单突破次数下强化到指定等级（按 consumes 顺序 Eat 到经验 >= requiredExp，再 Vomit 多余的）
---@param templateId number 装备模板 Id
---@param breakthrough number 当前突破次数
---@param curLevel number 当前等级
---@param curExp number|nil 当前等级内经验
---@param targetLevel number 目标等级
---@param consumes XEquipLevelUpConsume[] 强化消耗池，会被 Eat/Vomit 并保留本段模拟后的 SelectCount
---@param operations table<number, table> 操作记录列表，达成目标时会追加本段升级操作
---@param autoExchangeExpItemInfo XEquipLevelUpAutoExchangeExpItemInfo|nil 自动兑换经验道具信息
---@return XEquipLevelUpSegmentResult result 单突破段升级模拟结果
function XEquipStrengthenControl:SimulateLevelUpInBreakthrough(templateId, breakthrough, curLevel, curExp, targetLevel, consumes, operations, autoExchangeExpItemInfo)
    curExp = curExp or 0
    consumes = consumes or {}

    -- 守卫：当前等级已 >= 目标等级时，无需消耗（避免 requiredExp 出现负值污染外层 overExp 推进）
    if curLevel >= targetLevel then
        return {
            CanLevelUp = true,
            UsedExp = 0,
            CostMoney = 0,
            RequiredExp = 0,
            ReachLevel = curLevel,
            ReachExp = curExp,
        }
    end

    local usedExp, costMoney = 0, 0
    local requiredExp = self:_CalcLevelUpRequiredExp(templateId, breakthrough, curLevel, curExp, targetLevel)
    local operation = NewLevelUpOperation()

    -- 从消耗队列中顺序消耗，直至累积经验达到/超过所需总经验
    for index, consume in ipairs(consumes) do
        if consume.CanAutoSelect then
            while consume:GetLeftCount() > 0 and usedExp < requiredExp do
                consume:Eat()
                usedExp = usedExp + consume:GetAddExp()
                costMoney = costMoney + consume:GetCostMoney()
                AddConsumeToOperation(operation, index, consume)
            end
        end
    end

    local autoExchangeItemId
    local autoExchangeUseCount = 0
    if usedExp < requiredExp and autoExchangeExpItemInfo then
        autoExchangeItemId = autoExchangeExpItemInfo.ItemId
        local autoExchangeAddExp = autoExchangeExpItemInfo.AddExp or 0
        if autoExchangeItemId and autoExchangeAddExp > 0 then
            -- 自动兑换只按缺口经验 ceil 补足，溢出必然小于单个兑换道具经验。
            -- 后续只需回退普通消耗池中的小经验材料，不需要再回退自动兑换道具。
            autoExchangeUseCount = math.ceil((requiredExp - usedExp) / autoExchangeAddExp)
            usedExp = usedExp + autoExchangeUseCount * autoExchangeAddExp
            costMoney = costMoney + autoExchangeUseCount * (autoExchangeExpItemInfo.CostMoney or 0)
        end
    end

    -- 尝试从消耗队列中顺序去除多余的消耗，直至累积经验刚好满足所需总经验
    for index, consume in ipairs(consumes) do
        local hasEatItemCount = GetOperationConsumeCount(operation, consume)
        while hasEatItemCount > 0 do
            local exp = consume:GetAddExp()
            -- 经验已经满足，再吐就低于 requiredExp，停止
            if usedExp - exp < requiredExp then
                break
            end

            consume:Vomit()
            usedExp = usedExp - exp
            costMoney = costMoney - consume:GetCostMoney()

            -- 同步 operation 簿记
            hasEatItemCount = consume:IsEquip() and 0 or hasEatItemCount - 1
            RemoveConsumeFromOperation(operation, index, consume, hasEatItemCount)
        end
    end

    AddItemToOperation(operation, autoExchangeItemId, autoExchangeUseCount)

    if requiredExp > 0 then
        table.insert(operations, operation)
    end

    local levelLimit = self:GetBreakthroughLevelLimit(templateId, breakthrough)
    local reachLevel, reachExp = self:_CalculateReachLevelInBreakthrough(
        templateId,
        breakthrough,
        curLevel,
        curExp,
        levelLimit,
        usedExp
    )

    return {
        CanLevelUp = usedExp >= requiredExp,
        UsedExp = usedExp,
        CostMoney = costMoney,
        RequiredExp = requiredExp,
        ReachLevel = reachLevel,
        ReachExp = reachExp,
    }
end


----------------------------------------
-- 内部工具：多段升级模拟
----------------------------------------
-- 多段升级模拟，consumes 会被 Reset/Eat/Vomit 并保留本次模拟后的 SelectCount。
-- SiteResults 对外保持 { [equipId] = { BT = , Lv = , Operations = } } 形态。
---@param params XEquipLevelUpAcrossBreakthroughsParams
---@return XEquipLevelUpAcrossBreakthroughsResult result 多段升级模拟结果
function XEquipStrengthenControl:_SimulateLevelUpAcrossBreakthroughs(params)
    local templateId = params.TemplateId
    local operations = {}
    local consumes = params.Consumes
    local startBreakthrough = params.StartBreakthrough
    local startLevel = params.StartLevel
    local startExp = params.StartExp or 0
    local targetBreakthrough = params.TargetBreakthrough
    local targetLevel = params.TargetLevel
    local autoExchangeExpItemInfo = params.AutoExchangeExpItemInfo
    local checkOverflowConfirm = params.CheckOverflowConfirm
    local result = {
        CanLevelUp = true,
        UsedExp = 0,
        CostMoney = 0,
        LackExp = 0,
        ReachBreakthrough = startBreakthrough,
        ReachLevel = startLevel,
        ReachExp = startExp, -- 到达 ReachLevel 后，该等级内已填充的经验。
        Operations = operations,
        ShowExpOverflowConfirm = false,
    }

    for breakthrough = startBreakthrough, targetBreakthrough do
        local levelLimit = self:GetBreakthroughLevelLimit(templateId, breakthrough)
        local segmentTargetLevel = (breakthrough == targetBreakthrough) and targetLevel or levelLimit
        local segmentStartLevel = (breakthrough == startBreakthrough) and startLevel or XEnumConst.EQUIP.MIN_LEVEL
        local segmentStartExp = (breakthrough == startBreakthrough) and startExp or 0

        local segmentResult = self:SimulateLevelUpInBreakthrough(
            templateId,
            breakthrough,
            segmentStartLevel,
            segmentStartExp,
            segmentTargetLevel,
            consumes,
            operations,
            autoExchangeExpItemInfo
        )
        result.UsedExp = result.UsedExp + segmentResult.UsedExp
        result.CostMoney = result.CostMoney + segmentResult.CostMoney

        local segmentLackExp = segmentResult.RequiredExp - segmentResult.UsedExp
        if segmentLackExp > 0 then
            result.LackExp = result.LackExp + segmentLackExp
        end

        result.ReachBreakthrough = breakthrough
        result.ReachLevel = segmentResult.ReachLevel
        result.ReachExp = segmentResult.ReachExp
        if not segmentResult.CanLevelUp then
            result.CanLevelUp = false
            -- 当前段都未达成时不能继续模拟后续突破段，否则会产生不可执行的操作和预览等级。
            break
        end

        local overflowExp = segmentResult.UsedExp - segmentResult.RequiredExp
        -- 若已到达当前突破等级上限，ReachExp 表示无法继续升级、无法保留的溢出经验。
        if checkOverflowConfirm and overflowExp > 0 and result.ReachLevel >= levelLimit
            and result.ReachExp > XEnumConst.EQUIP.STRENGTHEN_EXP_OVERFLOW_CONFIRM then
            result.ShowExpOverflowConfirm = true
        end

        if breakthrough ~= targetBreakthrough then
            table.insert(operations, { OperationType = 2 })
        end

    end

    return result
end

-- 模拟单件装备升级到目标突破段和等级。
---@param equipId number 装备 Id
---@param targetBreakthrough number 目标突破次数
---@param targetLevel number 目标等级
---@param consumes XEquipLevelUpConsume[] 强化消耗池，会被排序、Reset，并保留本次模拟后的 SelectCount
---@return XEquipLevelUpAcrossBreakthroughsResult result 单件装备升级预览结果
function XEquipStrengthenControl:SimulateEquipLevelUp(equipId, targetBreakthrough, targetLevel, consumes)
    consumes = consumes or {}
    table.sort(consumes, XEquipStrengthenControl.EatOrderSort)
    for _, consume in pairs(consumes) do
        consume:Reset()
    end

    local templateId = self._MainControl:GetEquipTemplateId(equipId)
    local equip = self._MainControl:GetEquip(equipId)
    local result = self:_SimulateLevelUpAcrossBreakthroughs({
        TemplateId = templateId,
        StartBreakthrough = equip.Breakthrough,
        StartLevel = equip.Level,
        StartExp = equip.Exp,
        TargetBreakthrough = targetBreakthrough,
        TargetLevel = targetLevel,
        Consumes = consumes,
        CheckOverflowConfirm = true,
    })
    result.UsedExp = XMath.ToInt(result.UsedExp)
    return result
end

-- 将公共进度单位换算为六件意识各自的强化目标，超过自身成长上限时按满级封顶。
---@param equipIds table<number, number> 意识站位 -> 装备 Id
---@param targetLevelUnit number 六件意识共用的目标进度单位
---@return XEquipAwarenessStrengthenTargetInfo[] targets 六件意识各自的强化目标
function XEquipStrengthenControl:_BuildAwarenessStrengthenTargets(equipIds, targetLevelUnit)
    local targets = {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = equipIds[site]
        local equip = assert(self._MainControl:GetEquip(equipId), string.format(
            "XEquipStrengthenControl._BuildAwarenessStrengthenTargets error: 缺少意识装备, site=%s, equipId=%s",
            tostring(site), tostring(equipId)))
        local templateId = equip.TemplateId
        local levelUnit = math.min(targetLevelUnit, self:GetEquipMaxLevelUnit(templateId))
        local breakthrough, level = self:ConvertToBreakThroughAndLevel(templateId, levelUnit)
        targets[site] = {
            Site = site,
            EquipId = equipId,
            TemplateId = templateId,
            Breakthrough = breakthrough,
            Level = level,
        }
    end
    return targets
end

----------------------------------------
-- 强化自动兑换资源状态
----------------------------------------
-- 根据预览选项和装备类型对应的经验道具创建自动兑换信息。
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@param expItemId number 装备类型对应的强化经验道具 Id
---@return XEquipLevelUpAutoExchangeExpItemInfo|nil autoExchangeExpItemInfo 自动兑换经验道具信息；未开启或配置无效时返回 nil
function XEquipStrengthenControl:_CreateAutoExchangeExpItemInfo(isAutoExchangeEnabled, expItemId)
    if not isAutoExchangeEnabled then
        return nil
    end

    local addExp = XDataCenter.ItemManager.GetItemsAddEquipExp(expItemId)
    if not addExp or addExp <= 0 then
        return nil
    end

    return {
        ItemId = expItemId,
        AddExp = addExp,
        CostMoney = XDataCenter.ItemManager.GetItemsAddEquipCost(expItemId) or 0,
    }
end

-- 根据升级操作、突破消耗和螺母消耗构造计划及当前可执行的自动兑换信息。
---@param operations table<number, table> 升级请求操作列表
---@param breakList table<number, table> 突破消耗列表
---@param costMoney number 强化总螺母消耗
---@param autoExchangeExpItemInfo XEquipLevelUpAutoExchangeExpItemInfo|nil 自动兑换经验道具信息
---@return table<number, XEquipStrengthenAutoExchangeInfo> autoExchangeInfo 自动兑换信息
---@return boolean isExchangeConsumeEnough 兑换消耗是否足够
function XEquipStrengthenControl:_BuildStrengthenAutoExchangeInfo(operations, breakList, costMoney, autoExchangeExpItemInfo)
    local requiredCounts = {}
    local expItemId = autoExchangeExpItemInfo and autoExchangeExpItemInfo.ItemId
    if expItemId then
        for _, operation in ipairs(operations) do
            AddAutoExchangeCount(requiredCounts, expItemId, operation.UseItems and operation.UseItems[expItemId] or 0)
        end
    end

    for _, item in ipairs(breakList) do
        AddAutoExchangeCount(requiredCounts, item.Id, item.Count)
    end

    AddAutoExchangeCount(requiredCounts, XDataCenter.ItemManager.ItemId.Coin, costMoney)

    local autoExchangeInfo = {}
    local reservedConsumeCounts = {}
    local isExchangeConsumeEnough = true
    local coinItemId = XDataCenter.ItemManager.ItemId.Coin
    -- 可兑换数量按螺母 -> 经验道具 -> 突破材料顺序共享预占兑换消耗。
    local priorityItemIds = {}
    if requiredCounts[coinItemId] then
        table.insert(priorityItemIds, coinItemId)
    end
    if expItemId and requiredCounts[expItemId] then
        table.insert(priorityItemIds, expItemId)
    end
    for _, item in ipairs(breakList) do
        if requiredCounts[item.Id] then
            table.insert(priorityItemIds, item.Id)
        end
    end

    -- 只按目标资源单层兑换，不递归补齐兑换所需消耗。
    for _, itemId in ipairs(priorityItemIds) do
        local requiredCount = requiredCounts[itemId]
        local ownCount = XDataCenter.ItemManager.GetCount(itemId) or 0
        local lackCount = requiredCount - ownCount
        if lackCount > 0 then
            local exchangeInfo = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId)
            assert(exchangeInfo, string.format(
                "XEquipStrengthenControl._BuildStrengthenAutoExchangeInfo error: 缺少自动兑换路线, itemId=%s",
                tostring(itemId)))

            local rewardCount = exchangeInfo.RewardCountList[1]
            assert(rewardCount and rewardCount > 0, string.format(
                "XEquipStrengthenControl._BuildStrengthenAutoExchangeInfo error: 自动兑换奖励数量无效, itemId=%s",
                tostring(itemId)))

            local exchangeTimes = math.ceil(lackCount / rewardCount)
            local availableExchangeTimes = exchangeTimes
            local requiredConsumeList = {}
            local singleConsumeList = exchangeInfo.ConsumeList and exchangeInfo.ConsumeList[1] or {}
            for _, consume in ipairs(singleConsumeList) do
                local singleConsumeCount = consume.ConsumeCount or 0
                local requiredConsumeCount = singleConsumeCount * exchangeTimes
                table.insert(requiredConsumeList, {
                    Id = consume.ConsumeId,
                    Count = requiredConsumeCount,
                })

                if singleConsumeCount > 0 then
                    local reservedConsumeCount = reservedConsumeCounts[consume.ConsumeId] or 0
                    local consumeOwnCount = XDataCenter.ItemManager.GetCount(consume.ConsumeId) or 0
                    local remainingConsumeCount = math.max(0, consumeOwnCount - reservedConsumeCount)
                    local availableTimesByConsume = math.floor(remainingConsumeCount / singleConsumeCount)
                    availableExchangeTimes = math.min(availableExchangeTimes, availableTimesByConsume)
                end
            end
            table.sort(requiredConsumeList, function(a, b) return a.Id < b.Id end)

            -- 只预占当前可兑换次数对应的消耗，供后续目标计算剩余预算。
            for _, consume in ipairs(singleConsumeList) do
                local consumeCountToReserve = (consume.ConsumeCount or 0) * availableExchangeTimes
                AddAutoExchangeCount(reservedConsumeCounts, consume.ConsumeId, consumeCountToReserve)
            end
            if availableExchangeTimes < exchangeTimes then
                isExchangeConsumeEnough = false
            end

            autoExchangeInfo[itemId] = {
                ItemId = itemId,
                ShopId = exchangeInfo.ShopIdList[1],
                GoodsId = exchangeInfo.GoodsIdList[1],
                LackCount = lackCount,
                ExchangeTimes = exchangeTimes,
                RewardCount = rewardCount * exchangeTimes,
                AvailableExchangeTimes = availableExchangeTimes,
                AvailableRewardCount = rewardCount * availableExchangeTimes,
                ConsumeList = requiredConsumeList,
            }
        end
    end

    return autoExchangeInfo, isExchangeConsumeEnough
end

-- 应用强化资源是否足够及自动兑换后的可达状态。
---@param result XEquipAwarenessStrengthenPreviewResult|XEquipSingleStrengthenPreviewResult 强化预览结果
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@param operations table<number, table> 升级请求操作列表
---@param autoExchangeExpItemInfo XEquipLevelUpAutoExchangeExpItemInfo|nil 自动兑换经验道具信息
function XEquipStrengthenControl:_ApplyStrengthenResourceState(result, isAutoExchangeEnabled, operations, autoExchangeExpItemInfo)
    result.AutoExchangeInfo = {}
    result.IsAutoExchangeConsumeEnough = true

    if not isAutoExchangeEnabled then
        return
    end

    result.AutoExchangeInfo, result.IsAutoExchangeConsumeEnough = self:_BuildStrengthenAutoExchangeInfo(operations, result.BreakList, result.CostMoney, autoExchangeExpItemInfo)
end

----------------------------------------
-- 意识强化预览
----------------------------------------
-- 汇总六意识共享强化预览的升级操作。
---@param result XEquipAwarenessStrengthenPreviewResult 意识强化预览结果
---@return table<number, table> operations 全部意识的升级请求操作列表
local function CollectAwarenessOperations(result)
    local operations = {}
    for _, siteResult in pairs(result.SiteResults) do
        for _, operation in ipairs(siteResult.Operations) do
            table.insert(operations, operation)
        end
    end
    return operations
end

-- 判断强化预览是否能在当前资源及自动兑换设置下完成。
---@param result XEquipAwarenessStrengthenPreviewResult|XEquipSingleStrengthenPreviewResult 强化预览结果
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@return boolean isAchievable 是否可完成强化
local function IsStrengthenPreviewAchievable(result, isAutoExchangeEnabled)
    if isAutoExchangeEnabled then
        return result.CanLevelUp
            and result.CanBreakThroughCondition
            and result.IsAutoExchangeConsumeEnough
    end
    return result.CanLevelUp and result.CanBreakThrough and result.IsMoneyEnough
end

-- 模拟六件意识按各自模板升级到对应目标。
---@param targets XEquipAwarenessStrengthenTargetInfo[] 六件意识各自的强化目标
---@param consumes XEquipLevelUpConsume[] 共享强化消耗池，会被 Reset/Eat/Vomit 并保留整组模拟后的 SelectCount
---@param autoExchangeExpItemInfo XEquipLevelUpAutoExchangeExpItemInfo|nil 自动兑换经验道具信息
---@return XEquipAwarenessStrengthenPreviewResult result 意识组升级模拟结果
function XEquipStrengthenControl:_SimulateAwarenessGroupLevelUp(targets, consumes, autoExchangeExpItemInfo)
    for _, consume in pairs(consumes) do
        consume:Reset()
    end

    local result = {
        CanLevelUp = true,
        LevelUpMoney = 0,
        UsedExp = 0, -- 实际已消耗的经验总量。
        LackExp = 0, -- 距离目标等级仍缺少的经验总量。
        SiteResults = {}, -- 每个意识最终到达的突破、等级和单站位操作列表。
        OperationAwarenessCount = 0,
    }

    for _, target in ipairs(targets) do
        local equip = self._MainControl:GetEquip(target.EquipId)
        local curBT, curLv = equip.Breakthrough, equip.Level
        local needLevelUp = curBT < target.Breakthrough
            or (curBT == target.Breakthrough and curLv < target.Level)
        if needLevelUp then
            local siteResult = self:_SimulateLevelUpAcrossBreakthroughs({
                TemplateId = target.TemplateId,
                StartBreakthrough = curBT,
                StartLevel = curLv,
                StartExp = equip.Exp,
                TargetBreakthrough = target.Breakthrough,
                TargetLevel = target.Level,
                Consumes = consumes,
                AutoExchangeExpItemInfo = autoExchangeExpItemInfo,
            })

            result.CanLevelUp = result.CanLevelUp and siteResult.CanLevelUp
            result.LevelUpMoney = result.LevelUpMoney + siteResult.CostMoney
            result.UsedExp = result.UsedExp + siteResult.UsedExp
            result.LackExp = result.LackExp + siteResult.LackExp
            result.SiteResults[target.EquipId] = {
                Site = target.Site,
                BT = siteResult.ReachBreakthrough,
                Lv = siteResult.ReachLevel,
                Operations = siteResult.Operations,
            }
            if #siteResult.Operations > 0 then
                result.OperationAwarenessCount = result.OperationAwarenessCount + 1
            end
        else
            result.SiteResults[target.EquipId] = {
                Site = target.Site,
                BT = curBT,
                Lv = curLv,
                Operations = {},
            }
        end
    end

    result.UsedExp = XMath.ToInt(result.UsedExp)
    return result
end


-- 模拟一组意识到指定升级单位的完整强化预览。
---@param equipIds table<number, number> 意识站位 -> 装备 Id
---@param consumes XEquipLevelUpConsume[] 共享强化消耗池，会被排序并保留本次预览后的 SelectCount
---@param targetLevelUnit number 目标升级单位
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@return XEquipAwarenessStrengthenPreviewResult result 意识强化预览结果
function XEquipStrengthenControl:_SimulateAwarenessPreview(equipIds, consumes, targetLevelUnit, isAutoExchangeEnabled)
    assert(targetLevelUnit and targetLevelUnit > 0, "XEquipStrengthenControl._SimulateAwarenessPreview error: targetLevelUnit 必须大于 0")
    local targets = self:_BuildAwarenessStrengthenTargets(equipIds, targetLevelUnit)
    table.sort(consumes, XEquipStrengthenControl.EatOrderSort)

    -- 先按目标等级计算突破消耗，再模拟升级消耗。
    local breakMoney, breakList, canBreakThrough, canBreakThroughCondition = self:_CalcAwarenessBreakthroughCost(targets)

    local awarenessExpItemId = XDataCenter.ItemManager.ItemId.AwarenessStrengthenMaterial4
    local autoExchangeExpItemInfo = self:_CreateAutoExchangeExpItemInfo(isAutoExchangeEnabled, awarenessExpItemId)
    local result = self:_SimulateAwarenessGroupLevelUp(targets, consumes, autoExchangeExpItemInfo)
    local referenceTarget = targets[1]

    result.TargetLevelUnit = targetLevelUnit
    result.TargetBreakthrough = referenceTarget.Breakthrough
    result.TargetLevel = referenceTarget.Level
    result.BreakMoney = breakMoney
    result.BreakList = breakList
    result.CanBreakThrough = canBreakThrough
    result.CanBreakThroughCondition = canBreakThroughCondition
    result.CostMoney = result.BreakMoney + result.LevelUpMoney
    result.IsMoneyEnough = XDataCenter.ItemManager.GetCoinsNum() >= result.CostMoney

    local operations = CollectAwarenessOperations(result)
    self:_ApplyStrengthenResourceState(result, isAutoExchangeEnabled, operations, autoExchangeExpItemInfo)

    return result
end

-- 二分查找指定范围内可达的最高升级单位。
---@param minLevelUnit number 当前最低升级单位
---@param maxLevelUnit number 最大升级单位
---@param isAchievable fun(levelUnit:number):boolean 判断指定升级单位是否可达
---@return number levelUnit 最高可达升级单位
local function FindMaxAchievableLevelUnit(minLevelUnit, maxLevelUnit, isAchievable)
    local low, high = minLevelUnit, maxLevelUnit
    while low < high do
        local levelUnit = math.ceil((low + high) / 2)
        if isAchievable(levelUnit) then
            low = levelUnit
        else
            high = levelUnit - 1
        end
    end
    return low
end

-- 二分查找公共进度目标；已达到自身上限的意识保持满级，其余意识继续提升。
---@param equipIds table
---@param consumes XEquipLevelUpConsume[] 共享强化消耗池，会被排序并保留最高可达预览后的 SelectCount
---@param options XEquipStrengthenPreviewOptions|nil
---@return XEquipAwarenessStrengthenPreviewResult result 最高可达目标预览结果
function XEquipStrengthenControl:SimulateAwarenessMaxAchievablePreview(equipIds, consumes, options)
    local isAutoExchangeEnabled = options and options.IsAutoExchangeEnabled == true
    local minLevelUnit, maxLevelUnit = self:_GetAwarenessLevelUnitRange(equipIds)

    local targetLevelUnit = FindMaxAchievableLevelUnit(minLevelUnit, maxLevelUnit, function(levelUnit)
        local result = self:_SimulateAwarenessPreview(equipIds, consumes, levelUnit, isAutoExchangeEnabled)
        return IsStrengthenPreviewAchievable(result, isAutoExchangeEnabled)
    end)
    return self:_SimulateAwarenessPreview(equipIds, consumes, targetLevelUnit, isAutoExchangeEnabled)
end

----------------------------------------
--- 模拟当前六件意识提升一个公共等级单位后的预览；使用独立消耗池，不影响界面已选强化材料。
---@param equipIds table<number, number> 意识站位 -> 装备 Id
---@param isAutoExchangeEnabled boolean 是否启用自动兑换
---@return XEquipAwarenessStrengthenPreviewResult|nil previewResult 下一档强化预览；全部满级时返回 nil
function XEquipStrengthenControl:GetAwarenessNextStrengthenPreview(equipIds, isAutoExchangeEnabled)
    local currentLevelUnit, maxLevelUnit = self:_GetAwarenessLevelUnitRange(equipIds)
    if currentLevelUnit >= maxLevelUnit then
        return nil
    end

    local refEquipId = equipIds[1]
    local consumes = self:GetAllConsumeItems(refEquipId, {
        ForceAutoSelect = true,
    })
    return self:_SimulateAwarenessPreview(equipIds, consumes, currentLevelUnit + 1, isAutoExchangeEnabled)
end

-- 单件装备预览
----------------------------------------
-- 模拟单件装备到指定升级单位的完整强化预览。
---@param equipId number 装备 Id
---@param consumes XEquipLevelUpConsume[] 强化消耗池，会被排序并保留本次预览后的 SelectCount
---@param targetLevelUnit number 目标升级单位
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@return XEquipSingleStrengthenPreviewResult result 单件装备强化预览结果
function XEquipStrengthenControl:_SimulateSingleEquipPreview(equipId, consumes, targetLevelUnit, isAutoExchangeEnabled)
    local equip = self._MainControl:GetEquip(equipId)
    consumes = consumes or {}
    table.sort(consumes, XEquipStrengthenControl.EatOrderSort)
    for _, consume in pairs(consumes) do
        consume:Reset()
    end

    local templateId = equip.TemplateId
    local targetBreakthrough, targetLevel = self:ConvertToBreakThroughAndLevel(templateId, targetLevelUnit)
    local breakList, hasEnoughBreakthroughItems = self:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
    local breakMoney = self:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough) or 0
    local canBreakThroughCondition = true
    if equip.Breakthrough < targetBreakthrough then
        canBreakThroughCondition = self:CheckBreakthroughCondition(templateId, targetBreakthrough)
    end

    local expItemId = equip:IsAwareness()
        and XDataCenter.ItemManager.ItemId.AwarenessStrengthenMaterial4
        or XDataCenter.ItemManager.ItemId.WeaponStrengthenMaterial4
    local autoExchangeExpItemInfo = self:_CreateAutoExchangeExpItemInfo(isAutoExchangeEnabled, expItemId)
    local result = self:_SimulateLevelUpAcrossBreakthroughs({
        TemplateId = templateId,
        StartBreakthrough = equip.Breakthrough,
        StartLevel = equip.Level,
        StartExp = equip.Exp,
        TargetBreakthrough = targetBreakthrough,
        TargetLevel = targetLevel,
        Consumes = consumes,
        AutoExchangeExpItemInfo = autoExchangeExpItemInfo,
        CheckOverflowConfirm = true,
    })

    result.TargetLevelUnit = targetLevelUnit
    result.TargetBreakthrough = targetBreakthrough
    result.TargetLevel = targetLevel
    result.BreakMoney = breakMoney
    result.BreakList = breakList
    result.CanBreakThroughCondition = canBreakThroughCondition
    result.CanBreakThrough = canBreakThroughCondition and hasEnoughBreakthroughItems
    result.LevelUpMoney = result.CostMoney
    result.CostMoney = result.BreakMoney + result.LevelUpMoney
    result.IsMoneyEnough = XDataCenter.ItemManager.GetCoinsNum() >= result.CostMoney

    self:_ApplyStrengthenResourceState(result, isAutoExchangeEnabled, result.Operations, autoExchangeExpItemInfo)

    return result
end

-- 获取单件装备在当前资源下最高可达的强化预览。
---@param equipId number 装备 Id
---@param consumes XEquipLevelUpConsume[] 强化消耗池，会被排序并保留最高可达预览后的 SelectCount
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@return XEquipSingleStrengthenPreviewResult result 最高可达目标预览结果
function XEquipStrengthenControl:_SimulateSingleEquipMaxAchievablePreview(equipId, consumes, isAutoExchangeEnabled)
    local minLevelUnit = self:GetEquipLevelUnit(equipId)
    local templateId = self._MainControl:GetEquipTemplateId(equipId)
    local maxLevelUnit = self:GetEquipMaxLevelUnit(templateId)
    local targetLevelUnit = FindMaxAchievableLevelUnit(minLevelUnit, maxLevelUnit, function(levelUnit)
        local result = self:_SimulateSingleEquipPreview(equipId, consumes, levelUnit, isAutoExchangeEnabled)
        return IsStrengthenPreviewAchievable(result, isAutoExchangeEnabled)
    end)
    return self:_SimulateSingleEquipPreview(equipId, consumes, targetLevelUnit, isAutoExchangeEnabled)
end

-- 获取单把武器在当前资源下最高可达的强化预览。
---@param equipId number 武器装备 Id
---@param consumes XEquipLevelUpConsume[] 强化消耗池，会被排序并保留最高可达预览后的 SelectCount
---@param options XEquipStrengthenPreviewOptions|nil 预览选项
---@return XEquipSingleStrengthenPreviewResult result 最高可达目标预览结果
function XEquipStrengthenControl:SimulateWeaponMaxAchievablePreview(equipId, consumes, options)
    local isAutoExchangeEnabled = options and options.IsAutoExchangeEnabled == true
    return self:_SimulateSingleEquipMaxAchievablePreview(equipId, consumes, isAutoExchangeEnabled)
end

-- 获取单把武器再升一档的强化预览。
---@param equipId number 武器装备 Id
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
---@return XEquipSingleStrengthenPreviewResult|nil result 已满级时返回 nil
function XEquipStrengthenControl:GetWeaponNextStrengthenPreview(equipId, isAutoExchangeEnabled)
    if not XTool.IsNumberValid(equipId) then
        return nil
    end
    local currentLevelUnit = self:GetEquipLevelUnit(equipId)
    local templateId = self._MainControl:GetEquipTemplateId(equipId)
    local maxLevelUnit = self:GetEquipMaxLevelUnit(templateId)
    if currentLevelUnit >= maxLevelUnit then
        return nil
    end
    local consumes = self:GetAllConsumeItems(equipId, { ForceAutoSelect = true })
    return self:_SimulateSingleEquipPreview(equipId, consumes, currentLevelUnit + 1, isAutoExchangeEnabled)
end

----------------------------------------
-- 意识强化执行
----------------------------------------
-- 意识强化执行任务类型，数值顺序即执行阶段顺序：先自动兑换，再一键升级。
local AwarenessStrengthenTaskType = {
    -- 通过商店自动兑换补足预览所需资源。
    Exchange = 1,
    -- 对单个意识执行一键升级/突破。
    OneKeyFeed = 2,
}

-- 意识强化任务状态，用于标记当前串行链路内每个 task 的执行进度。
local AwarenessStrengthenTaskState = {
    -- 已构建但尚未开始。
    NotStarted = 0,
    -- 请求已发出，等待回调。
    Running = 1,
    -- 当前任务成功完成。
    Success = 2,
    -- 当前任务失败，链路中止。
    Failed = 3,
}

--- 根据预览结果启动意识强化串行链路。
--- 链路顺序：自动兑换任务逐个成功后，再按站位逐个执行一键升级。
---@param previewResult XEquipAwarenessStrengthenPreviewResult
---@param cb fun(isSuccess:boolean, errorCode:any)|nil
---@return boolean started
function XEquipStrengthenControl:StartAwarenessStrengthen(previewResult, cb)
    self:CancelAwarenessStrengthen()

    local isValid, errorCode = self:_CheckAwarenessStrengthenPreview(previewResult)
    if not isValid then
        if cb then
            cb(false, errorCode)
        end
        return false
    end

    self._AwarenessStrengthenCallback = cb
    self._AwarenessStrengthenTaskInfo = {
        PreviewResult = previewResult,
        TaskList = self:_BuildAwarenessStrengthenTaskList(previewResult),
        Index = 1,
    }

    self:_ExecuteNextAwarenessStrengthenTask(self._AwarenessStrengthenTaskInfo)
    return true
end

--- 打断当前意识强化链路；已发出的请求无法取消，但后续回调会因 taskInfo 失效而被忽略。
function XEquipStrengthenControl:CancelAwarenessStrengthen()
    self._AwarenessStrengthenTaskInfo = nil
    self._AwarenessStrengthenCallback = nil
end

--- 当前是否正在执行意识强化链路。
---@return boolean
function XEquipStrengthenControl:IsAwarenessStrengthenRunning()
    return self._AwarenessStrengthenTaskInfo ~= nil
end

--- 检查预览结果是否满足发起串行强化的基础条件。
---@param previewResult XEquipAwarenessStrengthenPreviewResult|nil
---@return boolean
---@return string|nil
function XEquipStrengthenControl:_CheckAwarenessStrengthenPreview(previewResult)
    if not previewResult or XTool.IsTableEmpty(previewResult.SiteResults) then
        return false, "InvalidPreview"
    end
    if previewResult.CanBreakThroughCondition == false then
        return false, "BreakthroughConditionNotMet"
    end
    local isAutoExchangeNeeded = next(previewResult.AutoExchangeInfo) ~= nil
    if isAutoExchangeNeeded then
        if previewResult.IsAutoExchangeConsumeEnough == false then
            return false, "AutoExchangeConsumeNotEnough"
        end
        return true
    end
    if previewResult.CanBreakThrough == false then
        return false, "BreakthroughMaterialNotEnough"
    end
    if previewResult.IsMoneyEnough == false then
        return false, "MoneyNotEnough"
    end
    if previewResult.CanLevelUp == false then
        return false, "LevelUpMaterialNotEnough"
    end
    return true
end

--- 根据预览结果构建串行任务列表：先按道具 Id 自动兑换，再按意识站位一键升级。
---@param previewResult XEquipAwarenessStrengthenPreviewResult
---@return XEquipAwarenessStrengthenTask[] taskList
function XEquipStrengthenControl:_BuildAwarenessStrengthenTaskList(previewResult)
    local taskList = {}
    for itemId, exchangeInfo in pairs(previewResult.AutoExchangeInfo or {}) do
        if exchangeInfo.ExchangeTimes and exchangeInfo.ExchangeTimes > 0 then
            table.insert(taskList, {
                Type = AwarenessStrengthenTaskType.Exchange,
                Id = itemId,
                State = AwarenessStrengthenTaskState.NotStarted,
            })
        end
    end

    for equipId, siteResult in pairs(previewResult.SiteResults or {}) do
        if not XTool.IsTableEmpty(siteResult.Operations) then
            table.insert(taskList, {
                Type = AwarenessStrengthenTaskType.OneKeyFeed,
                Id = equipId,
                State = AwarenessStrengthenTaskState.NotStarted,
            })
        end
    end

    table.sort(taskList, function(taskA, taskB)
        if taskA.Type ~= taskB.Type then
            return taskA.Type < taskB.Type
        end

        if taskA.Type == AwarenessStrengthenTaskType.OneKeyFeed then
            local siteA = previewResult.SiteResults[taskA.Id].Site
            local siteB = previewResult.SiteResults[taskB.Id].Site
            if siteA and siteB and siteA ~= siteB then
                return siteA < siteB
            end
        end
        return (tonumber(taskA.Id) or 0) < (tonumber(taskB.Id) or 0)
    end)
    return taskList
end

--- 启动下一个意识强化任务；所有任务完成后结束整条链路。
---@param taskInfo XEquipAwarenessStrengthenTaskInfo
function XEquipStrengthenControl:_ExecuteNextAwarenessStrengthenTask(taskInfo)
    if not self:_IsAwarenessStrengthenTaskValid(taskInfo) then
        return
    end

    local task = taskInfo.TaskList[taskInfo.Index]
    if not task then
        self:_FinishAwarenessStrengthen(taskInfo, true)
        return
    end

    task.State = AwarenessStrengthenTaskState.Running
    local onTaskFinish = function()
        self:_CompleteCurrentAwarenessStrengthenTask(taskInfo, task)
    end
    local onTaskFail = function(code)
        self:_FinishAwarenessStrengthen(taskInfo, false, code)
    end

    if task.Type == AwarenessStrengthenTaskType.Exchange then
        local exchangeInfo = taskInfo.PreviewResult.AutoExchangeInfo[task.Id]
        XShopManager.BuyShop(exchangeInfo.ShopId, exchangeInfo.GoodsId, exchangeInfo.ExchangeTimes, onTaskFinish, onTaskFail)
    elseif task.Type == AwarenessStrengthenTaskType.OneKeyFeed then
        local siteResult = taskInfo.PreviewResult.SiteResults[task.Id]
        XMVCA.XEquip:EquipOneKeyFeedRequest(task.Id, siteResult.BT, siteResult.Lv, siteResult.Operations, 
        onTaskFinish, onTaskFail)
    else
        self:_FinishAwarenessStrengthen(taskInfo, false, "InvalidTaskType")
    end
end

--- 标记当前任务完成并推进到下一个任务。
---@param taskInfo XEquipAwarenessStrengthenTaskInfo
---@param task XEquipAwarenessStrengthenTask
function XEquipStrengthenControl:_CompleteCurrentAwarenessStrengthenTask(taskInfo, task)
    if not self:_IsAwarenessStrengthenTaskValid(taskInfo) then
        return
    end
    task.State = AwarenessStrengthenTaskState.Success
    taskInfo.Index = taskInfo.Index + 1
    self:_ExecuteNextAwarenessStrengthenTask(taskInfo)
end

--- 结束整条意识强化链路，清理运行态并回调结果。
---@param taskInfo XEquipAwarenessStrengthenTaskInfo
---@param isSuccess boolean
---@param errorCode any
function XEquipStrengthenControl:_FinishAwarenessStrengthen(taskInfo, isSuccess, errorCode)
    if not self:_IsAwarenessStrengthenTaskValid(taskInfo) then
        return
    end
    local cb = self._AwarenessStrengthenCallback
    local task = taskInfo.TaskList[taskInfo.Index]
    if task then
        task.State = isSuccess and AwarenessStrengthenTaskState.Success or AwarenessStrengthenTaskState.Failed
    end
    self._AwarenessStrengthenTaskInfo = nil
    self._AwarenessStrengthenCallback = nil
    if cb then
        cb(isSuccess, errorCode)
    end
end

--- 校验异步回调持有的 taskInfo 是否仍是当前运行中的链路。
---@param taskInfo XEquipAwarenessStrengthenTaskInfo|nil
---@return boolean
function XEquipStrengthenControl:_IsAwarenessStrengthenTaskValid(taskInfo)
    return taskInfo and self._AwarenessStrengthenTaskInfo == taskInfo
end

----------------------------------------
-- 强化目标
----------------------------------------
-- 二分查找：当前消耗池下可达到的最高升级单位（包含突破段切换 + 货币/突破条件检查）
---@param equipId number 装备 Id
---@param consumes XEquipLevelUpConsume[] 强化消耗池，会被多次 Reset/Eat/Vomit 并保留最终模拟后的 SelectCount
---@return number levelUnit 最高可达升级单位
function XEquipStrengthenControl:GetMaxStrengthenTargetLevelUnit(equipId, consumes)
    local result = self:_SimulateSingleEquipMaxAchievablePreview(equipId, consumes, false)
    return result.TargetLevelUnit
end

----------------------------------------
-- 可消耗池构造
----------------------------------------
-- 消耗排序比较器（静态：以「.」调用，传给 table.sort）
-- 严格弱序：每档都需满足反对称性（a<b ⇒ ¬(b<a)）。Type 不同那档用 consumeA:IsEquip() 是反对称的：
--   a=equip,b=item → true；a=item,b=equip → false。改动时务必维持不变量，否则 table.sort 会越界 / 死循环
---@param consumeA XEquipLevelUpConsume 消耗对象 A
---@param consumeB XEquipLevelUpConsume 消耗对象 B
---@return boolean isBefore A 是否排在 B 前
function XEquipStrengthenControl.EatOrderSort(consumeA, consumeB)
    -- 提供经验从小到大
    if consumeA.AddExp ~= consumeB.AddExp then
        return consumeA.AddExp < consumeB.AddExp
    end
    -- 货币消耗从小到大
    if consumeA.CostMoney ~= consumeB.CostMoney then
        return consumeA.CostMoney < consumeB.CostMoney
    end
    -- 消耗类型（装备优先于道具）
    if consumeA.Type ~= consumeB.Type then
        return consumeA:IsEquip()
    end
    -- Id 从小到大
    return consumeA.Id < consumeB.Id
end

-- 把 SelectCount 抽成一份临时可吃池：Count 固定为选中数量，供后续模拟按「只使用选中材料」计算
---@param consumes XEquipLevelUpConsume[] 原始消耗池
---@return XEquipLevelUpConsume[] selectedConsumes 按已选数量克隆出的临时消耗池
function XEquipStrengthenControl:GetSelectedConsumeItems(consumes)
    local result = {}
    for _, consume in ipairs(consumes or {}) do
        local selectCount = consume.SelectCount or 0
        if selectCount > 0 then
            local clone = XTool.Clone(consume)
            clone.Count = selectCount
            clone.SelectCount = 0
            clone.CanAutoSelect = true
            table.insert(result, clone)
        end
    end
    return result
end

--- 构造装备/意识的可消耗资源列表（道具 + 可吃装备），统一排除 TeamPrefab
--- 不传 options 时：包含强化道具，装备材料默认允许 1-4 星，不强制自动选择。
---@param equipId number 目标装备/意识 id，用于查可吃池（意识场景 6 个同类型，任传一个即可）
---@param options XEquipConsumeItemOptions|nil
---@return XEquipLevelUpConsume[] consumes 可消耗资源列表
function XEquipStrengthenControl:GetAllConsumeItems(equipId, options)
    options = options or {}
    local includeItems = options.IncludeItems ~= false
    local consumeStarDic = options.ConsumeStarDic
    local forceAutoSelect = options.ForceAutoSelect

    local result = {}

    -- 1) 消耗道具
    if includeItems then
        local itemIdList = XMVCA.XEquip:GetCanEatItemIds(equipId)
        for _, itemId in pairs(itemIdList) do
            local obj = XEquipLevelUpConsume.New()
            obj:InitItem(itemId)
            table.insert(result, obj)
        end
    end

    -- 判断指定星级是否允许进入可消耗列表。
    local IsStarAllowed = function(star)
        if consumeStarDic then
            return consumeStarDic[star] == true
        end
        return star >= 1 and star <= 4
    end

    -- 2) 可吃装备（排除 TeamPrefab）
    local equipIds = XMVCA.XEquip:GetCanEatEquipIds(equipId)
    for _, eatEquipId in pairs(equipIds) do
        if not XDataCenter.TeamManager.CheckEquipIdIsInTeamPrefab(eatEquipId) then
            local templateId = XMVCA.XEquip:GetEquipTemplateId(eatEquipId)
            local star = XMVCA.XEquip:GetEquipStar(templateId)
            if IsStarAllowed(star) then
                local canAutoSelect = forceAutoSelect
                    or XMVCA.XEquip:IsEquipRecomendedToBeEat(equipId, eatEquipId, true)
                local obj = XEquipLevelUpConsume.New()
                obj:InitEquip(eatEquipId, canAutoSelect)
                table.insert(result, obj)
            end
        end
    end

    return result
end

----------------------------------------
-- 批量升满聚合开销
----------------------------------------
--- 计算单件装备升到满级所需的强化经验。
---@param equipId number 装备 Id
---@param templateId number 装备模板 Id
---@param maxBreakthrough number 最大突破次数
---@param maxLevel number 最大等级
---@return number totalExp 升到满级所需经验
function XEquipStrengthenControl:_CalcEquipUpgradeToMaxRequiredExp(equipId, templateId, maxBreakthrough, maxLevel)
    local equip = self._MainControl:GetEquip(equipId)
    local totalExp = 0
    local curBreakthrough = equip.Breakthrough
    local curLevel = equip.Level
    local curExp = equip.Exp or 0

    for breakthrough = curBreakthrough, maxBreakthrough do
        local segmentTargetLevel = (breakthrough == maxBreakthrough) and maxLevel or self:GetBreakthroughLevelLimit(templateId, breakthrough)
        local segmentStartLevel = (breakthrough == curBreakthrough) and curLevel or XEnumConst.EQUIP.MIN_LEVEL
        local segmentStartExp = (breakthrough == curBreakthrough) and curExp or 0
        local segmentExp = self:_CalcLevelUpRequiredExp(templateId, breakthrough, segmentStartLevel, segmentStartExp, segmentTargetLevel)

        totalExp = totalExp + math.max(0, segmentExp)
    end

    return totalExp
end

--- 计算一组穿戴意识升到「满级（最大突破段的最大等级）」的强化入口数据。
---@param equipIds table<number, number> 六件穿戴意识 Id 字典，key 为穿戴位
---@param options XEquipStrengthenPreviewOptions|nil
---@return number totalExp
---@return XEquipAwarenessStrengthenPreviewResult previewResult
function XEquipStrengthenControl:CalcFullAwarenessStrengthenPreviewCost(equipIds, options)
    local refEquipId = equipIds[1]
    local _, targetLevelUnit = self:_GetAwarenessLevelUnitRange(equipIds)
    local allConsumeItems = self:GetAllConsumeItems(refEquipId, { ForceAutoSelect = true })
    local isAutoExchangeEnabled = options and options.IsAutoExchangeEnabled == true
    local previewResult = self:_SimulateAwarenessPreview(equipIds, allConsumeItems, targetLevelUnit, isAutoExchangeEnabled)

    local totalExp = 0
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local equipId = equipIds[site]
        local equip = self._MainControl:GetEquip(equipId)
        local templateId = equip.TemplateId
        local maxBreakthrough, maxLevel = self:GetEquipMaxBreakthrough(templateId)
        totalExp = totalExp + self:_CalcEquipUpgradeToMaxRequiredExp(equipId, templateId, maxBreakthrough, maxLevel)
    end

    return totalExp, previewResult
end

--- 计算单把武器升到满级所需经验和完整强化预览。
---@param equipId number 武器装备 Id
---@param options XEquipStrengthenPreviewOptions|nil 预览选项
---@return number totalExp 升到满级所需经验
---@return XEquipSingleStrengthenPreviewResult previewResult 满级强化预览结果
function XEquipStrengthenControl:CalcFullWeaponStrengthenPreviewCost(equipId, options)
    local equip = self._MainControl:GetEquip(equipId)
    local templateId = equip.TemplateId
    local maxBreakthrough, maxLevel = self:GetEquipMaxBreakthrough(templateId)
    local targetLevelUnit = self:ConvertToLevelUnit(templateId, maxBreakthrough, maxLevel)
    local allConsumeItems = self:GetAllConsumeItems(equipId, { ForceAutoSelect = true })
    local isAutoExchangeEnabled = options and options.IsAutoExchangeEnabled == true
    local previewResult = self:_SimulateSingleEquipPreview(equipId, allConsumeItems, targetLevelUnit, isAutoExchangeEnabled)
    local totalExp = self:_CalcEquipUpgradeToMaxRequiredExp(equipId, templateId, maxBreakthrough, maxLevel)
    return totalExp, previewResult
end

return XEquipStrengthenControl
