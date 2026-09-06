local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local STEDefine = require("XModule/XPunishaar/STEDefine/STEDefine")
local STEEnum = require("STEVM/STEEnum")
local Effect = require("XModule/XPunishaar/STEDefine/Effect")
local XList = require("XCommon/XList")

-- 模块级复用 buffer（编排函数不碰 self，用 upvalue；每调 :Clear() 复用，零 per-call GC）
local PassedEffectsList = XList.New()
local EffectIdsList = XList.New()

-- 待落地伤害 land buffer（DrainScheduledDamages 填充，持 XPunishaarInstruction 引用，零 per-tick GC）#75
-- #76 重构：buffer 装的是 Instruction 引用（非 {target,...} table），TickScheduledDamages 调 ins:Execute 后回池
local SchedLandBuf = {}

--region 私有辅助方法

--- 数指定颜色的球数量（纯读）
---@param vm STEVM.VM
local CountBallByColor = function(vm, color)
    local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
    local count = 0
    local len = vm:PropLen(ballList)
    for i = 1, len do
        if vm:PropGet(ballList, i) == color then
            count = count + 1
        end
    end
    return count
end

--- 球是否足够（纯读，供发动前校验）
---@param vm STEVM.VM
local CheckBallEnough = function(vm, color, needCount)
    if not needCount or needCount <= 0 then
        return true
    end
    return CountBallByColor(vm, color) >= needCount
end

--- 按颜色 FIFO 消耗球（先产先消，跳过其他颜色）
---@param vm STEVM.VM
---@param executorId any 消耗球的实体（用于帧缓存登记）
local ConsumeBall = function(vm, executorId, color, count)
    if not count or count <= 0 then
        return
    end
    local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
    local removed = 0
    local index = 1
    -- while+手动index：删除后元素前移，index 不前进
    while index <= vm:PropLen(ballList) and removed < count do
        if vm:PropGet(ballList, index) == color then
            vm:PropRemoveByKey(ballList, index)
            removed = removed + 1
        else
            index = index + 1
        end
    end
    -- 球池真变化才发事件（removed==0 天然不发，避免空事件）
    if removed > 0 then
        vm:Emit(STECustomEnum.EventEnum.BallListChanged)
        -- 埋点统计：信号球消费总量累加（循环后一次 Store，非每球；事务可回滚）
        vm:Store(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TotalBallConsumed, STEEnum.ValChangeType.Add, removed)
    end
    -- 帧缓存：本帧有实体消耗了球
    local consumeList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickConsumeBallEntityList)
    vm:PropAppend(consumeList, executorId)

    -- 消耗球的实体不一定是卡（CardId 读不到则只显示 uid）
    local cardId = vm:ReadProperty(executorId, STECustomEnum.FieldNameType.CardId) and vm:Read(executorId, STECustomEnum.FieldNameType.CardId)
    XLog.Debug(string.format("实体 [uid%s cid%s] 消耗球：色%s x%s（实消%s），剩余球池[%s]",
            tostring(executorId), tostring(cardId), tostring(color), tostring(count), tostring(removed), tostring(vm:PropLen(ballList))))
end

--- 产球（入队尾，保持产出次序）
--- 总容量上限：球池满则挤压队头最早产的球（FIFO，新球入队尾）#球槽挤压
---@param vm STEVM.VM
---@param executorId any 产球的实体（用于帧缓存登记）
local ProduceBall = function(vm, executorId, color, count)
    if not count or count <= 0 then
        return
    end
    local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
    -- 容量上限由 Global 的 Single property 提供（外部初始化传入）
    local capacity = vm:Read(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallSlotCapacity)

    local produced = 0
    for _ = 1, count do
        if vm:PropLen(ballList) >= capacity then
            -- 池满，挤压队头最早产的球（FIFO），新球入队尾 #球槽挤压
            vm:PropRemoveByKey(ballList, 1)
        end
        vm:PropAppend(ballList, color)
        produced = produced + 1
    end

    -- 帧缓存：仅当实际产出 >0 才登记（全溢出不算"本帧产球实体"）
    if produced > 0 then
        local productList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickProductBallEntityList)
        vm:PropAppend(productList, executorId)
        -- 球池真变化才发事件（全溢出 produced==0 不进块，天然不发）
        vm:Emit(STECustomEnum.EventEnum.BallListChanged)
        -- 埋点统计：信号球生成总量累加（循环后一次 Store，非每球；事务可回滚）
        vm:Store(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TotalBallProduced, STEEnum.ValChangeType.Add, produced)
    end

    XLog.Debug(string.format("实体 [uid%s cid%s] 产球：色%s 请求%s 实产%s（满则挤压队头 FIFO），当前球池[%s/%s]",
            tostring(executorId),
            tostring(vm:ReadProperty(executorId, STECustomEnum.FieldNameType.CardId) and vm:Read(executorId, STECustomEnum.FieldNameType.CardId)),
            tostring(color), tostring(count), tostring(produced),
            tostring(vm:PropLen(ballList)), tostring(capacity)))
end

--- 把某效果组的 effectId 追加到 out 列表（保持组内配置顺序）。用于合并主/副卡效果。
---@param out table 目标列表（追加写）
---@param control XPunishaarFightControl
---@param effectGroupId number
local AppendGroupEffectIds = function(out, control, effectGroupId)
    if not effectGroupId then
        return
    end
    local groupCfg = control:GetTablePunishaarEffectGroup(effectGroupId)
    if not groupCfg or not groupCfg.EffectIds then
        return
    end
    for _, id in ipairs(groupCfg.EffectIds) do
        out:Append(id)
    end
end

--- 判断一条 effect 的触发条件是否满足（纯读，不改状态）
--- 判定顺序：先判「时机」(triggerCfg.TriggerType 是否在 timingMask 接受集内)，再判「条件」(ConditionType 谓词)。
--- 时机与条件正交：时机=何时来问(装备/战斗开始/运行时)，条件=来问时通不通过。
--- TriggerId 为空/0：无 trigger 配置，时机视为 Other(运行时)、条件视为无条件通过。
---@param vm STEVM.VM
---@param triggerId number
---@param control XPunishaarFightControl
---@param timingMask number 接受的时机 mask（STECustomEnum.TriggerTimeMask.*）；(mask & (1<<triggerType))==0 则时机不符
---@return boolean
local CheckEffectTrigger = function(vm, triggerId, control, timingMask)
    -- 无 trigger：时机=Other。仅当 mask 接受 Other 才通过（且无条件）
    if not triggerId or triggerId == 0 then
        return (timingMask & (1 << STECustomEnum.TriggerTimeType.Other)) ~= 0
    end

    local triggerCfg = control:GetTablePunishaarTrigger(triggerId)
    if not triggerCfg then
        return (timingMask & (1 << STECustomEnum.TriggerTimeType.Other)) ~= 0
    end

    -- 先判时机：TriggerType 为配置层的触发时机（空/0=Other）；不在接受 mask 内直接否
    local triggerType = triggerCfg.TriggerType or STECustomEnum.TriggerTimeType.Other
    if (timingMask & (1 << triggerType)) == 0 then
        return false
    end

    if XTool.IsNumberValidEx(triggerCfg.ConditionType) then
        -- 再判条件：ConditionType 才是代码里的 trigger 原语键（与 TriggerType 时机正交）
        local triggerFunc = STEDefine.Trigger[triggerCfg.ConditionType]
        if not triggerFunc then
            vm:Error("Trigger函数不存在，ConditionType：" .. tostring(triggerCfg.ConditionType))
            return false
        end

        return triggerFunc(vm, table.unpack(triggerCfg.ConditionParams)) and true or false
    else
        -- 没有判断类型，说明默认通过
        return true
    end
    
    
end

--- 根据一个effect配置，执行它的具体逻辑
---@param vm STEVM.VM
---@param config XTablePunishaarEffect
local ExecuteEffectByConfig = function(vm, selectFunc, selectorParams, effectFunc, effectParams)
    -- 第一步，找目标
    local entityIds = selectFunc(vm, table.unpack(selectorParams))

    effectFunc(vm, entityIds, table.unpack(effectParams))
end

--- 对某实体、某 EffectGroup，按指定时机 mask 跑一遍「先判后执」两阶段。
--- 主体黑板 OwnCardId=ownerId；仅执行时机匹配 timingMask 的 effect。
---@param vm STEVM.VM
---@param control XPunishaarFightControl
---@param ownerId any 执行主体（黑板 OwnCardId）
---@param groupId number EffectGroupId
---@param timingMask number 接受的时机 mask
local RunEntityEffectGroup = function(vm, control, ownerId, groupId, timingMask)
    if not groupId or groupId == 0 then
        return
    end
    local groupCfg = control:GetTablePunishaarEffectGroup(groupId)
    local effectIds = groupCfg and groupCfg.EffectIds
    if not effectIds then
        return
    end

    vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId, ownerId)

    -- 阶段1：判定（含时机过滤）
    PassedEffectsList:Clear()
    for _, effectId in ipairs(effectIds) do
        local effectCfg = control:GetTablePunishaarEffect(effectId)
        if effectCfg and CheckEffectTrigger(vm, effectCfg.TriggerId, control, timingMask) then
            PassedEffectsList:Append(effectCfg)
        end
    end
    -- 阶段2：执行
    for i = 1, PassedEffectsList:GetCount() do
        local effectCfg = PassedEffectsList:GetValueByIndex(i)
        local effectFunc = STEDefine.Effect[effectCfg.EffectType]
        local selectorFunc = STEDefine.Selector[effectCfg.ScopeType]
        if effectFunc and selectorFunc then
            ExecuteEffectByConfig(vm, selectorFunc, effectCfg.ScopeParams, effectFunc, effectCfg.EffectParams)
        else
            vm:Error(string.format("战斗开始 effect 函数/选择器不存在 EffectType=%s ScopeType=%s",
                    tostring(effectCfg.EffectType), tostring(effectCfg.ScopeType)))
        end
    end
end

--- 推进单个 buff 的 Ex 效果释放（周期性跑 ExEffectGroupId）。仅 Active 态调用。
--- 首次（ExTickCD==-1 哨兵）据 ExFirstImmediate 定初值：立刻放→0，否则→ExEffectCD 转帧。
--- 到点：主体=buff 的 OwnEntityId，内联跑 ExEffectGroup 两阶段（同卡牌/敌人内核），次数+1，CD 重置。
--- 限次：ExEffectMaxTimes==0 不限次；否则 ExDoneTimes>=上限 停放（仅停 Ex，buff 生命周期不受影响）。
---@param vm STEVM.VM
---@param control XPunishaarFightControl
---@param uid any buff 实体 id
---@param cfg table buff 配置
---@param logicFrame number 逻辑帧率
local TickBuffEx = function(vm, control, uid, cfg, logicFrame)
    local exGroupId = cfg.ExEffectGroupId
    if not exGroupId or exGroupId == 0 then
        return   -- 无 Ex 效果配置
    end

    local exCdTick = math.max(1, math.floor((cfg.ExEffectCD or 0) / 1000 * logicFrame))

    -- 首次：据 ExFirstImmediate 定 ExTickCD 初值（哨兵 -1 表示未初始化）
    local tickCd = vm:Read(uid, STECustomEnum.FieldNameType.ExTickCD)
    if tickCd == -1 then
        tickCd = cfg.ExFirstImmediate and 0 or exCdTick
        vm:Store(uid, STECustomEnum.FieldNameType.ExTickCD, STEEnum.ValChangeType.Set, tickCd)
    end

    -- 限次检查（0=不限次）
    local maxTimes = cfg.ExEffectMaxTimes or 0
    if maxTimes ~= 0 and vm:Read(uid, STECustomEnum.FieldNameType.ExDoneTimes) >= maxTimes then
        return   -- 次数用尽，仅停放 Ex（buff 继续走生命周期）
    end

    -- 递减；未到点则返回
    vm:Store(uid, STECustomEnum.FieldNameType.ExTickCD, STEEnum.ValChangeType.Subtract, 1)
    if vm:Read(uid, STECustomEnum.FieldNameType.ExTickCD) > 0 then
        return
    end

    -- 到点：放 Ex 效果。主体 = 产生/承载 buff 的实体（同 CountDownTrigger 口径）
    local ownId = vm:Read(uid, STECustomEnum.FieldNameType.OwnEntityId)
    vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId, ownId)
    vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnBuffId, uid)

    local groupCfg = control:GetTablePunishaarEffectGroup(exGroupId)
    local effectIds = groupCfg and groupCfg.EffectIds
    if effectIds then
        -- 阶段1：判定
        PassedEffectsList:Clear()
        for _, effectId in ipairs(effectIds) do
            local effectCfg = control:GetTablePunishaarEffect(effectId)
            if effectCfg and CheckEffectTrigger(vm, effectCfg.TriggerId, control, STECustomEnum.TriggerTimeMask.Runtime) then
                PassedEffectsList:Append(effectCfg)
            end
        end
        -- 阶段2：执行
        for i = 1, PassedEffectsList:GetCount() do
            local effectCfg = PassedEffectsList:GetValueByIndex(i)
            local effectFunc = STEDefine.Effect[effectCfg.EffectType]
            local selectorFunc = STEDefine.Selector[effectCfg.ScopeType]
            if effectFunc and selectorFunc then
                ExecuteEffectByConfig(vm, selectorFunc, effectCfg.ScopeParams, effectFunc, effectCfg.EffectParams)
            else
                vm:Error(string.format("Buff Ex 效果函数/选择器不存在 EffectType=%s ScopeType=%s",
                        tostring(effectCfg.EffectType), tostring(effectCfg.ScopeType)))
            end
        end
    end

    -- 善后：次数+1，CD 重置
    vm:Store(uid, STECustomEnum.FieldNameType.ExDoneTimes, STEEnum.ValChangeType.Add, 1)
    vm:Store(uid, STECustomEnum.FieldNameType.ExTickCD, STEEnum.ValChangeType.Set, exCdTick)
    
    -- XLog.Debug(string.format("Buff [uid%s] 释放 Ex 效果（第%s次）", tostring(uid), tostring(vm:Read(uid, STECustomEnum.FieldNameType.ExDoneTimes))))
end
--endregion

--- 流水线函数，注意所有函数都需要直接或间接通过单步引擎调用
---@class XPunishaarSTEPipeline
local XPunishaarSTEPipeline = {}

--region 单步流水线

--- 在新一帧开始时清理掉全局的帧记录
---@param vm STEVM.VM
function XPunishaarSTEPipeline.ResetGlobalTickData(vm)
    local tickDoneCardList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDoneCardList)
    local tickCardCDChangeList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickCardCDMaxChangeList)
    local tickProductBallEntityList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickProductBallEntityList)
    local tickConsumeBallEntityList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickConsumeBallEntityList)
    local tickDamageDealtDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDamageDealtDict)
    local tickAccelEntityList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickAccelEntityList)
    -- 帧级数值快照（buff 修正 ATK/CD 供 UI 一瞬显示，跨一帧清）#buff修正快照
    local tickAtkSnapshot = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickAtkSnapshot)
    local tickCdMaxSnapshot = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickCdMaxSnapshot)

    vm:PropClear(tickDoneCardList)
    vm:PropClear(tickCardCDChangeList)
    vm:PropClear(tickProductBallEntityList)
    vm:PropClear(tickConsumeBallEntityList)
    vm:PropClear(tickDamageDealtDict)
    vm:PropClear(tickAccelEntityList)
    vm:PropClear(tickAtkSnapshot)
    vm:PropClear(tickCdMaxSnapshot)

    -- 单卡同帧激发次数计数清零（每帧重置；限同帧连锁激发次数）#同帧激发上限
    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    local cardLen = cardIds and vm:PropLen(cardIds) or 0
    for i = 1, cardLen do
        vm:Store(vm:PropGet(cardIds, i), STECustomEnum.FieldNameType.TickDoneTimes, STEEnum.ValChangeType.Set, 0)
    end
end

--- 驱动所有卡牌的CD减去一个tick，并将可以发动的卡牌注册到全局列表
---@param vm STEVM.VM
function XPunishaarSTEPipeline.TickAllCards(vm)
    ---@type PropertyList
    local entityIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)

    local len = entityIds:Len()

    if len <= 0 then
        return
    end

    for i = 1, len do
        local id = entityIds:GetByKey(i)

        -- 判断是卡牌且不处于等待激发中
        if vm:HasTag(id, STECustomEnum.EntityTags.Card) and not vm:HasTag(id, STECustomEnum.EntityTags.WaittingDone) then
            vm:Store(id, STECustomEnum.FieldNameType.TickCD, STEEnum.ValChangeType.Subtract, 1)
            -- 有卡 CD 推进即视为变化，通知表现层刷 CD（去重集，本帧多卡只留一条）
            vm:Emit(STECustomEnum.EventEnum.CardCdChanged)
            local cd = vm:Read(id, STECustomEnum.FieldNameType.TickCD)

            if cd <= 0 then
                local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.WaittingDoneCardIdList)

                vm:PropAppend(handler, id)
                vm:AddTag(id, STECustomEnum.EntityTags.WaittingDone)
            end
        end
    end
end

--- 按顺序读取待激发卡牌列表，筛选满足发动条件的卡入 queue。
--- （B 方案：此处只判定+入队，不移出 waitting；移出在 ExecuteOneCardEffects 执行成功后做）
---@param vm STEVM.VM
---@param queue XQueue
---@param control XPunishaarFightControl 只使用配置表读取接口
---@param maxActivate number 单卡本帧最大激发次数（math.huge=不限；由 STEControl 缓存传入，防每帧读配置）#同帧激发上限
function XPunishaarSTEPipeline.OutputCanActiveCardIds(vm, queue, control, maxActivate)
    local list = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.WaittingDoneCardIdList)
    local len = vm:PropLen(list)

    local tickClickCardIdDict = nil

    -- 不移出，正序遍历即可
    for index = 1, len do
        local cardEntityId = vm:PropGet(list, index)
        local cardId = vm:Read(cardEntityId, STECustomEnum.FieldNameType.CardId)

        -- 单卡同帧激发次数上限：本帧已激发达上限的卡本帧不再入队（留 waitting，下帧 ResetGlobalTickData 清零后可再激发）#同帧激发上限
        -- maxActivate=math.huge（配置缺省/非法）时永不命中，等同不限（保默认行为）
        if vm:Read(cardEntityId, STECustomEnum.FieldNameType.TickDoneTimes) >= maxActivate then
            goto CONTINUE
        end

        -- 卡牌能否发动的条件：
        -- 1. 自动 or 手动且本帧有输入
        -- 2. CD 已到（能进 waitting 的卡天然满足）
        -- 3. 球是否足够消耗 —— 放到 ExecuteOneCardEffects 执行时校验（球是共享资源，
        --    此处判定不准；且 B 方案由执行阶段统一处理消耗/移出）
        if vm:HasTag(cardEntityId, STECustomEnum.EntityTags.ByHand) then
            -- Auto 开启时 Global 持 Auto 特征 tag，ByHand 牌跳过输入检查直接入激活 queue（同普通牌）；
            -- 吃球校验仍由 ExecuteOneCardEffects:CheckBallEnough 兜底，球不足 skip（不跳过球检验）#Auto
            if not vm:HasTag(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.EntityTags.Auto) then
                tickClickCardIdDict = tickClickCardIdDict or vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickClickCardIdDict)
                if vm:PropGet(tickClickCardIdDict, cardEntityId) == nil then
                    goto CONTINUE
                end
            end
            XLog.Debug(string.format("卡牌 [uid%s cid%s]（手动）检测到输入，进入激活", tostring(cardEntityId), tostring(cardId)))
        end

        queue:Enqueue(cardEntityId)

        :: CONTINUE ::
    end
end

--- 执行一张牌的完整效果
--- 流程：球校验 → 消球 → effect 两阶段(先判后执) → 产球 → 移出waitting+重置CD
--- 球不足则 skip（不移出、不重置），卡留 waitting 下帧重试。
---@param vm STEVM.VM
---@param control XPunishaarFightControl 只使用配置表读取接口
---@return boolean activated 是否真正激发成功（false=球不足等原因 skip，卡留 waitting）
function XPunishaarSTEPipeline.ExecuteOneCardEffects(vm, entityId, control)
    local cardId = vm:Read(entityId, STECustomEnum.FieldNameType.CardId)

    local color = control:GetConfigCardColor(cardId)
    local effectGroupId = control:GetConfigCardEffectGroupId(cardId)

    -- 取卡色与球消耗/产出数量（等级战斗内不变，实体字段即该等级值）
    local consumeCount = vm:Read(entityId, STECustomEnum.FieldNameType.BallConsumeCount)
    local productCount = vm:Read(entityId, STECustomEnum.FieldNameType.BallProductCount)
    
    consumeCount = math.floor(consumeCount)
    productCount = math.floor(productCount)

    -- 「下次触发不消耗球」标签（一次性）：本次跳过球校验+消球，执行后清除
    local noConsumeBall = vm:HasTag(entityId, STECustomEnum.EntityTags.NoConsumeBall)

    -- 条件3 二次校验：球不足则跳过本次发动（不移出 waitting、不重置 CD，下帧重试）
    -- 持有「不消耗球」标签时免校验（本次不消球，不受球量约束）
    if not noConsumeBall and not CheckBallEnough(vm, color, consumeCount) then
        return false
    end

    -- 执行前将卡牌标记为正在激活
    vm:AddTag(entityId, STECustomEnum.EntityTags.Active)

    -- 载入黑板数据
    vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId, entityId)

    -- 先消球（消耗是前提）；持有「不消耗球」标签则本次跳过消球并清除标签（一次性）
    if noConsumeBall then
        vm:RemoveTag(entityId, STECustomEnum.EntityTags.NoConsumeBall)
        XLog.Debug(string.format("卡牌 [uid%s cid%s] 本次不消耗球（消耗「下次不消球」标签）", tostring(entityId), tostring(cardId)))
    else
        ConsumeBall(vm, entityId, color, consumeCount)
    end

    -- 组装本次激发的 effectId 列表：副卡在前、主卡在后（先副后主）。
    -- 副卡非独立实体，登记在 Global.SubCardDict（主卡uid → {cardId,level}）；有副卡则其 effectGroup 前置。
    EffectIdsList:Clear()
    local subDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.SubCardDict)
    local subCard = subDict and vm:PropGet(subDict, entityId)
    
    if subCard and XTool.IsNumberValidEx(subCard.cardId)then
        AppendGroupEffectIds(EffectIdsList, control, control:GetConfigCardEffectGroupId(subCard.cardId))
    end
    
    AppendGroupEffectIds(EffectIdsList, control, effectGroupId)

    if EffectIdsList:GetCount() > 0 then
        -- 阶段1：判定。逐个 effect 跑 trigger，收集通过的（纯读，不改状态）
        PassedEffectsList:Clear()
        for i = 1, EffectIdsList:GetCount() do
            local effectId = EffectIdsList:GetValueByIndex(i)
            local effectCfg = control:GetTablePunishaarEffect(effectId)
            if effectCfg and CheckEffectTrigger(vm, effectCfg.TriggerId, control, STECustomEnum.TriggerTimeMask.Runtime) then
                PassedEffectsList:Append(effectCfg)
            end
        end

        -- 阶段2：执行。只执行判定通过的 effect
        ---@param effectCfg XTablePunishaarEffect
        for i = 1, PassedEffectsList:GetCount() do
            local effectCfg = PassedEffectsList:GetValueByIndex(i)
            local effectFunc = STEDefine.Effect[effectCfg.EffectType]
            local selectorFunc = STEDefine.Selector[effectCfg.ScopeType]

            if not effectFunc then
                vm:Error("Effect函数不存在，枚举值：" .. effectCfg.EffectType)
                return
            end

            if not selectorFunc then
                vm:Error("Selector函数不存在，枚举值：" .. effectCfg.ScopeType)
                return
            end

            XLog.Debug(string.format("卡牌 [uid%s cid%s] 打出效果：effectId=%s EffectType=%s ScopeType=%s",
                    tostring(entityId), tostring(cardId), tostring(effectCfg.Id), tostring(effectCfg.EffectType), tostring(effectCfg.ScopeType)))

            ExecuteEffectByConfig(vm, selectorFunc, effectCfg.ScopeParams, effectFunc, effectCfg.EffectParams)
        end
    end

    -- 后产球（产出是结果）
    ProduceBall(vm, entityId, color, productCount)

    -- 激发成功的善后
    -- 移出 waitting（B 方案：移出与执行同原子，回滚一致，避免僵尸卡）
    local waittingList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.WaittingDoneCardIdList)
    vm:PropRemoveValue(waittingList, entityId)
    vm:RemoveTag(entityId, STECustomEnum.EntityTags.WaittingDone)

    -- 移除激活状态
    vm:RemoveTag(entityId, STECustomEnum.EntityTags.Active)

    -- 恢复CD
    local cdMax = vm:Read(entityId, STECustomEnum.FieldNameType.TickCDMax)
    vm:Store(entityId, STECustomEnum.FieldNameType.TickCD, STEEnum.ValChangeType.Set, cdMax)

    -- 累计激活次数（CheckNthTrigger 预判依赖：本次激发后 DoneTimes 命中 n 倍数；此前漏累加致 CheckNthTrigger 对 n>1 永不触发 #H1）
    vm:Store(entityId, STECustomEnum.FieldNameType.DoneTimes, STEEnum.ValChangeType.Add, 1)

    -- 累计本帧激发次数（ResetGlobalTickData 每帧清零；OutputCanActiveCardIds 据此拦同帧超限激发）#同帧激发上限
    vm:Store(entityId, STECustomEnum.FieldNameType.TickDoneTimes, STEEnum.ValChangeType.Add, 1)

    -- 记录到当前帧激活列表中
    local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDoneCardList)
    vm:PropAppend(handler, entityId)

    -- 卡牌攻击动画：善后派发（卡牌发动即播，XPresentEventBus 去重同帧多卡只派发一次）#71
    vm:Emit(STECustomEnum.EventEnum.CardAttackAnim)

    return true
end

--- 推进敌人 CD（推CD阶段，玩家方之后执行——微观帧内严格"先玩家后怪物"）。
--- 唯一敌人，显式 GetEnemy，不入队/不加标签（单敌人无需筛选，执行阶段直接判 CD）。
---@param vm STEVM.VM
function XPunishaarSTEPipeline.TickEnemy(vm)
    local enemyId = STECustomEnum.GlobalEntityIds.Enemy
    -- 死了不推
    if vm:Read(enemyId, STECustomEnum.FieldNameType.HP) <= 0 then
        return
    end
    vm:Store(enemyId, STECustomEnum.FieldNameType.TickCD, STEEnum.ValChangeType.Subtract, 1)
    vm:Emit(STECustomEnum.EventEnum.CardCdChanged)   -- 复用 CD 变化事件（表现层刷）
end

--- 执行敌人效果（执行阶段，玩家方之后）。敌人=特殊卡牌：CD 到点执行 EffectGroup。
--- 复用卡牌效果两阶段内核；差异：多 EffectGroup 各自独立两阶段、无球校验、执行者=敌人、目标靠配置(GetPlayer)。
---@param vm STEVM.VM
---@param control XPunishaarFightControl
---@param groupIdBuffer table 调用方提供的可复用缓冲（承接 GetEnemyEffectGroupIds 填充）
---@return boolean activated 是否真正执行（供收敛循环判据）
function XPunishaarSTEPipeline.ExecuteEnemyEffects(vm, control, groupIdBuffer)
    local enemyId = STECustomEnum.GlobalEntityIds.Enemy

    -- ① 判存活：玩家本帧打死敌人后不反击
    if vm:Read(enemyId, STECustomEnum.FieldNameType.HP) <= 0 then
        return false
    end
    -- ② 直接判 CD：未到不执行（唯一敌人，不用 WaittingDone 队列）
    if vm:Read(enemyId, STECustomEnum.FieldNameType.TickCD) > 0 then
        return false
    end

    -- 现查 Fight（fightId 存 Global）→ EffectGroupId 列表
    local fightId = vm:Read(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.FightId)
    local groupCount = control:GetEnemyEffectGroupIds(fightId, groupIdBuffer)

    -- 执行者=敌人：Effect 内 _ReadDamageSource 取敌人 ATK；目标靠配置 ScopeType=GetPlayer
    vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId, enemyId)

    -- 多 EffectGroup 各自独立两阶段（不合并；无球校验）
    for gi = 1, groupCount do
        local effectGroupCfg = control:GetTablePunishaarEffectGroup(groupIdBuffer[gi])
        local effectIds = effectGroupCfg and effectGroupCfg.EffectIds
        if effectIds then
            -- 阶段1：判定
            PassedEffectsList:Clear()
            for _, effectId in ipairs(effectIds) do
                local effectCfg = control:GetTablePunishaarEffect(effectId)
                if effectCfg and CheckEffectTrigger(vm, effectCfg.TriggerId, control, STECustomEnum.TriggerTimeMask.Runtime) then
                    PassedEffectsList:Append({ id = effectId, cfg = effectCfg })
                end
            end
            -- 阶段2：执行
            for i = 1, PassedEffectsList:GetCount() do
                local item = PassedEffectsList:GetValueByIndex(i)
                local effectCfg = item.cfg
                local effectFunc = STEDefine.Effect[effectCfg.EffectType]
                local selectorFunc = STEDefine.Selector[effectCfg.ScopeType]
                if not effectFunc then
                    vm:Error("Effect函数不存在，枚举值：" .. tostring(effectCfg.EffectType))
                    return false
                end
                if not selectorFunc then
                    vm:Error("Selector函数不存在，枚举值：" .. tostring(effectCfg.ScopeType))
                    return false
                end
                XLog.Debug(string.format("敌人 [uid%s] 打出效果：effectId=%s EffectType=%s ScopeType=%s",
                        tostring(enemyId), tostring(item.id), tostring(effectCfg.EffectType), tostring(effectCfg.ScopeType)))
                ExecuteEffectByConfig(vm, selectorFunc, effectCfg.ScopeParams, effectFunc, effectCfg.EffectParams)
            end
        end
    end

    -- 善后：CD 重置（无球产出、无 waitting 移出——敌人不走那套）
    local cdMax = vm:Read(enemyId, STECustomEnum.FieldNameType.TickCDMax)
    vm:Store(enemyId, STECustomEnum.FieldNameType.TickCD, STEEnum.ValChangeType.Set, cdMax)

    -- 累计敌人激活次数（Trigger[15] CheckNthTrigger 预判依赖，敌人激发后+1；对齐卡牌激发善后 #H1）#4.8
    vm:Store(enemyId, STECustomEnum.FieldNameType.DoneTimes, STEEnum.ValChangeType.Add, 1)

    -- 记录到当前帧激活列表中
    local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDoneCardList)
    vm:PropAppend(handler, enemyId)
    
    -- 敌人准备攻击通知（CD 到 0 激发，表现层订阅触发 FxEnemyAttack 特效）#EnemyAttack
    vm:Emit(STECustomEnum.EventEnum.EnemyAttackPrepare)
    return true
end

--- 战斗开始钩子：开局一次性执行所有卡牌+敌人的「装备时/战斗开始时」时机 effect。
--- 卡牌 effectGroup 取 Card.EffectGroupId（单组）；敌人取 GetEnemyEffectGroupIds（多组）。
--- 时机 mask=BattleStart（装备|战斗开始）；与运行时激发（只跑 Other）互斥分流。
---@param vm STEVM.VM
---@param control XPunishaarFightControl
---@param groupIdBuffer table 敌人 EffectGroupId 现查缓冲（复用）
function XPunishaarSTEPipeline.RunBattleStartEffects(vm, control, groupIdBuffer)
    local mask = STECustomEnum.TriggerTimeMask.BattleStart

    -- 卡牌：遍历 CardEntityIds，每张主卡先跑其副卡 EffectGroup（先副后主，与 ExecuteOneCardEffects 一致），
    -- 再跑主卡 Card.EffectGroupId。副卡无实体，ownerId=宿主主卡 uid（靠主卡黑板 OwnCardId 生效）。
    local subDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.SubCardDict)
    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    local cardLen = cardIds and vm:PropLen(cardIds) or 0
    for i = 1, cardLen do
        local uid = vm:PropGet(cardIds, i)
        -- 副卡先：副卡的「装备时/战斗开始时」effect 只能在此触发（运行时 Runtime mask 会过滤掉 BattleStart 时机）
        local subCard = subDict and vm:PropGet(subDict, uid)
        if subCard and XTool.IsNumberValidEx(subCard.cardId)then
            RunEntityEffectGroup(vm, control, uid, control:GetConfigCardEffectGroupId(subCard.cardId), mask)
        end
        -- 主卡
        local cardId = vm:Read(uid, STECustomEnum.FieldNameType.CardId)
        RunEntityEffectGroup(vm, control, uid, control:GetConfigCardEffectGroupId(cardId), mask)
    end

    -- 敌人：现查 Fight 的多 EffectGroup，逐组跑
    local enemyId = STECustomEnum.GlobalEntityIds.Enemy
    if vm:Read(enemyId, STECustomEnum.FieldNameType.HP) > 0 then
        local fightId = vm:Read(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.FightId)
        local groupCount = control:GetEnemyEffectGroupIds(fightId, groupIdBuffer)
        for gi = 1, groupCount do
            RunEntityEffectGroup(vm, control, enemyId, groupIdBuffer[gi], mask)
        end
    end
end

--- 推进所有 buff 的生命周期计量，到期只标记 PreEnd（不删结构，回收交给 RecycleBuffs）
--- 时序：必须在卡牌发动循环之后（次数型 CountDownTrigger 可能依赖 TickDoneCardList）
--- 阈值每帧现算：时间型(Tick)毫秒→帧向下取整；次数型(TriggerTick)直接用次数
---@param vm STEVM.VM
---@param control XPunishaarFightControl
---@param logicFrame number 逻辑帧率（每秒逻辑帧数），用于毫秒→帧换算
function XPunishaarSTEPipeline.TickAllBuffs(vm, control, logicFrame)
    local buffList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BuffEntityIds)
    local len = vm:PropLen(buffList)
    if len <= 0 then
        return
    end

    for i = 1, len do
        local uid = vm:PropGet(buffList, i)

        -- 只推进 Active 态的 buff
        if vm:Read(uid, STECustomEnum.FieldNameType.State) == STECustomEnum.BuffState.Active then
            local buffId = vm:Read(uid, STECustomEnum.FieldNameType.BuffId)
            local cfg = control:GetTablePunishaarBuff(buffId)

            -- Ex 效果：周期性释放 ExEffectGroup（独立于生命周期计量）
            TickBuffEx(vm, control, uid, cfg, logicFrame)

            -- 本帧是否累加：时间型每帧恒真；次数型判 CountDownTrigger
            local shouldCount
            if cfg.LifeTimesType == STECustomEnum.BuffLifeTimeType.Tick then
                shouldCount = true
            else
                -- buff 跑自己的 trigger 时，"所属牌" = 产生它的实体
                local ownId = vm:Read(uid, STECustomEnum.FieldNameType.OwnEntityId)
                vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId, ownId)
                vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.OwnBuffId, uid)
                shouldCount = CheckEffectTrigger(vm, cfg.CountDownTrigger, control, STECustomEnum.TriggerTimeMask.Runtime)
            end

            if shouldCount then
                vm:Store(uid, STECustomEnum.FieldNameType.LifeTimes, STEEnum.ValChangeType.Add, 1)

                -- 到期阈值现算（累加模型：LifeTimes 从 0 增到 >= 阈值即到期）
                local threshold
                if cfg.LifeTimesType == STECustomEnum.BuffLifeTimeType.Tick then
                    threshold = math.floor(cfg.LifeTimes / 1000 * logicFrame)   -- 毫秒→帧，向下取整
                else
                    threshold = cfg.LifeTimes                                    -- 次数型：直接是次数
                end

                local cur = vm:Read(uid, STECustomEnum.FieldNameType.LifeTimes)
                -- XLog.Debug(string.format("Buff [uid%s cid%s] 累计 %s/%s", tostring(uid), tostring(buffId), tostring(cur), tostring(threshold)))

                if cur >= threshold then
                    vm:Store(uid, STECustomEnum.FieldNameType.State, STEEnum.ValChangeType.Set, STECustomEnum.BuffState.PreEnd)
                    XLog.Debug(string.format("Buff [uid%s cid%s] 到期，标记 PreEnd（累计%s/%s）",
                            tostring(uid), tostring(buffId),
                            tostring(cur), tostring(threshold)))
                end
            end
        end
    end
end

--- 回收所有 PreEnd 的 buff：撤临时修正 + 销毁实体 + 摘索引
--- 独立于 TickAllBuffs（判定期只改状态不动结构，回收期集中删）
--- 销毁逻辑复用 Effect._DestroyBuff（与覆盖共用同一销毁路径）
---@param vm STEVM.VM
function XPunishaarSTEPipeline.RecycleBuffs(vm)
    local buffList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BuffEntityIds)

    -- 倒序遍历：_DestroyBuff 内部按值摘索引，倒序遍历避免下标错位
    for i = vm:PropLen(buffList), 1, -1 do
        local uid = vm:PropGet(buffList, i)
        if vm:Read(uid, STECustomEnum.FieldNameType.State) == STECustomEnum.BuffState.PreEnd then
            Effect._DestroyBuff(vm, uid)
        end
    end
end

--- 帧末执行的一些操作
---@param vm STEVM.VM
--- 战斗疲劳节奏：逻辑时间超阈值挂疲劳 buff 加速结束（fire-once，任意一方死亡不触发）#80
---@param vm STEVM.VM
---@param control XPunishaarFightControl
---@param logicFrameRate number 每秒逻辑帧数（秒→帧换算）
function XPunishaarSTEPipeline.TickBattlePacing(vm, control, logicFrameRate)
    local global = STECustomEnum.GlobalEntityIds.Global
    if vm:HasTag(global, STECustomEnum.EntityTags.Fatigued) then
        return  -- fire-once
    end
    -- 任意一方死亡不触发疲劳
    local playerHp = vm:Read(STECustomEnum.GlobalEntityIds.Player, STECustomEnum.FieldNameType.HP)
    local enemyHp = vm:Read(STECustomEnum.GlobalEntityIds.Enemy, STECustomEnum.FieldNameType.HP)
    if (playerHp and playerHp <= 0) or (enemyHp and enemyHp <= 0) then
        return
    end
    local fatigueMs = XMVCA.XPunishaar:GetClientNumberByKey("FatigueTimeMs")
    if not fatigueMs or fatigueMs <= 0 then
        return  -- 全局未配=无疲劳
    end
    -- 累计逻辑帧数取框架 env._tick（权威，每 STETick AdvanceTick +1；无需 GlobalEntity 存）#80 修正
    local elapsed = vm:GetEnv():GetTick()
    -- 阈值毫秒→帧（fatigueMs * 帧率 / 1000，向下取整；与 CD 毫秒域范式对齐 MsPerLogicFrame）
    if elapsed >= math.floor(fatigueMs * logicFrameRate / 1000) then
        local groupId = XMVCA.XPunishaar:GetClientNumberByKey("FatigueEffectGroupId")
        if groupId and groupId ~= 0 then
            RunEntityEffectGroup(vm, control, global, groupId, STECustomEnum.TriggerTimeMask.Runtime)
        end
        vm:AddTag(global, STECustomEnum.EntityTags.Fatigued)
    end
end

function XPunishaarSTEPipeline.OnTickEnd(vm)
    -- 输入信号延迟到帧末才清空，确保输入能够被正确消费
    local tickClickCardIdDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickClickCardIdDict)
    vm:PropClear(tickClickCardIdDict)
end
--endregion

--region 待落地伤害推进（#75 #77 时间轮分桶）

--- 推进待落地伤害时间轮并落地当前 tick 桶到点的指令。
--- 位置：ExecuteEnemyEffects 之后、TickAllBuffs 之前（让 buff 计量看到扣血后 HP）。
--- 流程：env:DrainScheduledDamages 查 curTick=GetTick() 桶，整桶 pop（_SchedByTick[curTick]=nil）：
---   skip 项回池不入 out、非 skip 项入 SchedLandBuf 待 Execute（O(1) pop + O(n) 生效）；
---   对每条 land-time 调 ins:Execute（M1 守卫+登记 TickDamageDealtDict+重读护盾+Store HP/Emit 或 扣护盾/Emit ShieldChanged），
---   Execute 后调 env:ReturnInstruction 回池。
---   落地副作用与回收分离：Drain 已整桶摘除，Execute 抛错不影响 Drain 状态；回池在 Execute 之后保证复用安全。
---@param vm STEVM.VM
function XPunishaarSTEPipeline.TickScheduledDamages(vm)
    ---@type XPunishaarSTEEnv
    local env = vm:GetEnv()
    local count = env:DrainScheduledDamages(SchedLandBuf)
    if count <= 0 then
        -- count=0 时 SchedLandBuf 全是上一帧 land 已回池的旧引用，清空防未来 ipairs 脏读 #76 精审
        for i = 1, #SchedLandBuf do
            SchedLandBuf[i] = nil
        end
        return
    end
    local damageDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDamageDealtDict)
    for i = 1, count do
        local ins = SchedLandBuf[i]
        if ins then
            ins:Execute(vm, damageDict)
            env:ReturnInstruction(ins)
        end
    end
    -- 按 count 截断 stale tail（DrainScheduledDamages 按 count 写 out[count] 不清旧尾；未来若改 ipairs 全量遍历即脏读）#75 L1
    for i = count + 1, #SchedLandBuf do
        SchedLandBuf[i] = nil
    end
end

--endregion

--region 其他外部接口

---@param vm STEVM.VM
function XPunishaarSTEPipeline.SetTickClickCardData(vm, uid)
    local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickClickCardIdDict)

    vm:PropSet(handler, uid, true)
end

--endregion

return XPunishaarSTEPipeline
