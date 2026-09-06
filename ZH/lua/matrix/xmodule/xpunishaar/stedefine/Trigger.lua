local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local STEQuery = require("XModule/XPunishaar/STEDefine/STEQuery")

local Trigger = {}

--region 内部Trigger，用于封装、复用，不暴露给策划

--- 判断某个实体的某个属性值(最终值）是否在指定区间（左闭右开）
---@field targetFieldNameEnum @STECustomEnum.FieldNameEnum (必须是数值类型）
---@param vm STEVM.VM
function Trigger._CheckFinalValueRange(vm, entityId, targetFieldNameEnum, leftVal, rightVal)
    local fieldName = STECustomEnum.FieldNameEnum[targetFieldNameEnum]
    local curVal = vm:Read(entityId, fieldName) or 0
    return curVal >= leftVal and curVal < rightVal
end

--- 比较某个实体的某个属性值(最终值）与给定值的结果
---@field targetFieldNameEnum @STECustomEnum.FieldNameEnum (必须是数值类型）
---@field op @STEEnum.OpType
---@param vm STEVM.VM
function Trigger._CheckFinalValueCompare(vm, entityId, targetFieldNameEnum, op, rightVal)
    local fieldName = STECustomEnum.FieldNameEnum[targetFieldNameEnum]
    local curVal = vm:Read(entityId, fieldName) or 0
    vm:Compare(curVal, op, rightVal)
end

--endregion

--region 公开到配置表中的Trigger

--- 判断指定的牌是否在指定的位置上
---@param vm STEVM.VM
function Trigger.CheckTargetCardPosIn(vm, cardId, index)
    -- 加载紧凑索引字段
    local curIndex = vm:Read(cardId, STECustomEnum.FieldNameType.Index)

    -- 比较
    return curIndex == index
end

--- 判断主体是否在指定位置上
---@param vm STEVM.VM
function Trigger.CheckSelfPosIn(vm, index)
    -- 获取主体
    local entityId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)

    return Trigger.CheckTargetCardPosIn(vm, entityId, index)
end

--- 判断主体是否处于某位置（绝对/相对自身/最左/最右 统一入口）
--- 仅适用一维紧凑索引、1卡占1格
---@param vm STEVM.VM
---@param mode number STECustomEnum.PosMode
---@param param number|nil 绝对模式=索引；相对模式=偏移(左负右正)；最左/最右忽略
function Trigger.CheckSelfPosMatch(vm, mode, param)
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    local targetIndex = STEQuery.ResolveIndex(vm, mode, param)
    if not ownId or not targetIndex then
        return false
    end
    return vm:Read(ownId, STECustomEnum.FieldNameType.Index) == targetIndex
end

--- 判断触发的牌是否满足指定位置
---@param vm STEVM.VM
function Trigger.CheckDoneCardPosIn(vm, index, color, cardType)
    -- 加载当前时刻触发的牌
    local tickDoneCardList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDoneCardList)

    -- 检查是否存在满足位置的牌
    if not tickDoneCardList or tickDoneCardList:Len() == 0 then
        return false
    end

    local len = tickDoneCardList:Len()

    for i = 1, len do
        local entityId = tickDoneCardList:GetByKey(i)

        if Trigger.CheckTargetCardPosIn(vm, entityId, index) then
            -- 颜色/类型约束（nil/0=不限；对齐 GetCardsByConfigFilter 范式）#4.8
            if (not color or color == 0) and (not cardType or cardType == 0) then
                return true  -- 无约束，位置匹配即满足
            end
            local cfgProp = vm:ReadProperty(entityId, STECustomEnum.FieldNameType.CardConfig)
            local cfg = cfgProp and cfgProp:GetConfig()
            if cfg then
                local colorOk = (not color or color == 0) or cfg.Color == color
                local typeOk = (not cardType or cardType == 0) or cfg.Type == cardType
                if colorOk and typeOk then
                    return true
                end
            end
        end
    end

    return false
end

--- 判断是否任意牌CD发生改变
function Trigger.CheckAnyCardCdChanged(vm)
    -- 加载当前时刻触发的牌
    local tickCardCDChangeList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickCardCDMaxChangeList)

    if tickCardCDChangeList and tickCardCDChangeList:Len() > 0 then
        return true
    end

    return false
end

--- 判断所属牌的某个属性值(最终值）是否在指定区间（左闭右开）
---@field targetFieldNameEnum @STECustomEnum.FieldNameEnum (必须是数值类型）
---@param vm STEVM.VM
function Trigger.CheckOwnCardFinalValueRange(vm, targetFieldNameEnum, leftVal, rightVal)
    local ownCardId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)

    return Trigger._CheckFinalValueRange(vm, ownCardId, targetFieldNameEnum, leftVal, rightVal)
end

--- 进行概率判定
---@param vm STEVM.VM
---@param value number 万分比值
function Trigger.CheckRandomHit(vm, value)
    local random = vm:RandInt(0, 10000)

    return value >= random
end

--- 判断指定颜色的球数量是否满足比较条件（支持全部比较运算）。
---@param vm STEVM.VM
---@param color number 球颜色（STECustomEnum.BallColor）
---@param op number STEEnum.OpType 比较运算
---@param count number 比较阈值
---@return boolean
function Trigger.CheckBallColorCount(vm, color, op, count)
    local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
    local cur = 0
    local len = vm:PropLen(ballList)

    if color == 0 then
        -- 颜色值为0表示不限制颜色
        cur = len
    else
        for i = 1, len do
            if vm:PropGet(ballList, i) == color then
                cur = cur + 1
            end
        end
    end

    return vm:Compare(cur, op, count)
end

--- 判断玩家/敌人的血量百分比是否满足比较条件（支持全部比较运算）。

--- 百分比 = HP/HPMax*100（0~100 整数域比较，阈值也是 0~100 整数，避免浮点）。
---@param vm STEVM.VM
---@param targetType number 1=玩家 2=敌人
---@param op number STEEnum.OpType 比较运算
---@param percent number 百分比阈值（0~100）
---@return boolean
function Trigger.CheckHpPercent(vm, targetType, op, percent)
    local entityId = targetType == 1 and STECustomEnum.GlobalEntityIds.Player or STECustomEnum.GlobalEntityIds.Enemy
    local hp = vm:Read(entityId, STECustomEnum.FieldNameType.HP) or 0
    local hpMax = vm:Read(entityId, STECustomEnum.FieldNameType.HPMax) or 0
    if hpMax <= 0 then
        return false
    end
    local curPercent = hp * 100 / hpMax
    return vm:Compare(curPercent, op, percent)
end

--region 公开：本帧产球/消球过滤

--- 判断本帧是否有满足约束的实体产球。
--- color=0 不过滤颜色；cardType=0 不过滤类型；side=0 不约束相邻（STECustomEnum.AdjacentSide）。
--- 全 0 = 任意实体产球。
---@param vm STEVM.VM
---@param color number
---@param cardType number
---@param side number
---@return boolean
function Trigger.CheckBallProduced(vm, color, cardType, side)
    local list = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickProductBallEntityList)
    local selfIndex
    if side ~= 0 then
        local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        if not ownId then
            return false
        end
        selfIndex = vm:Read(ownId, STECustomEnum.FieldNameType.Index)
        if not selfIndex then
            return false
        end
    end
    return STEQuery.CheckTickListMatch(vm, list, color, cardType, side, selfIndex)
end

--- 判断本帧是否有满足约束的实体消球。参数语义同 CheckBallProduced。
---@param vm STEVM.VM
---@param color number
---@param cardType number
---@param side number
---@return boolean
function Trigger.CheckBallConsumed(vm, color, cardType, side)
    local list = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickConsumeBallEntityList)
    local selfIndex
    if side ~= 0 then
        local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        if not ownId then
            return false
        end
        selfIndex = vm:Read(ownId, STECustomEnum.FieldNameType.Index)
        if not selfIndex then
            return false
        end
    end
    return STEQuery.CheckTickListMatch(vm, list, color, cardType, side, selfIndex)
end

--- 判断本帧是否有满足约束的实体产球（空间邻接版：PosIndex+Size 无缝隙）。参数语义同 CheckBallProduced。
---@param vm STEVM.VM
---@param color number
---@param cardType number
---@param side number
---@return boolean
function Trigger.CheckBallProducedSpatial(vm, color, cardType, side)
    local list = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickProductBallEntityList)
    local ownId
    if side ~= 0 then
        ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        if not ownId then
            return false
        end
    end
    return STEQuery.CheckTickListMatchSpatial(vm, list, color, cardType, side, ownId)
end

--- 判断本帧是否有满足约束的实体消球（空间邻接版：PosIndex+Size 无缝隙）。参数语义同 CheckBallConsumed。
---@param vm STEVM.VM
---@param color number
---@param cardType number
---@param side number
---@return boolean
function Trigger.CheckBallConsumedSpatial(vm, color, cardType, side)
    local list = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickConsumeBallEntityList)
    local ownId
    if side ~= 0 then
        ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        if not ownId then
            return false
        end
    end
    return STEQuery.CheckTickListMatchSpatial(vm, list, color, cardType, side, ownId)
end

--- 判断指定方向的空间邻居（主卡）的 Color/Type 是否满足约束。邻居不存在返回 false。
--- color/cardType 以 0 表示不约束；Either 时任一邻居满足即为 true。
---@param vm STEVM.VM
---@param side number STECustomEnum.AdjacentSide
---@param color number 0=不限
---@param cardType number 0=不限
---@return boolean
function Trigger.CheckNeighborMainCardMatch(vm, side, color, cardType)
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    if not ownId then
        return false
    end
    return STEQuery.CheckAnyNeighborConfigMatch(vm, side, ownId, color, cardType, STECustomEnum.FieldNameType.CardConfig)
end

--- 判断所属卡牌的颜色是否符合要求
---@param vm STEVM.VM
---@param color number
function Trigger.CheckOwnCardColor(vm, color)
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)

    ---@type PropertyConfig
    local cardCfgRoot = vm:ReadProperty(ownId, STECustomEnum.FieldNameType.CardConfig)
    ---@type XTablePunishaarCard
    local cardCfg = cardCfgRoot:GetConfig()

    if cardCfg then
        return cardCfg.Color == color
    else
        vm:Error(string.format("卡牌%s 实体配置引用丢失", ownId))
        return false
    end
end

--endregion

--region 公开：伤害与触发计数

--- CheckNthTrigger 内部：对单个实体做属性过滤 + DoneTimes 取余判断（无闭包，避免热路径 GC）。
---@param vm STEVM.VM
---@param uid any 目标实体 uid
---@param n number 每多少次触发一次
---@param color number 0=不限
---@param cardType number 0=不限
---@return boolean
function Trigger._CheckNthTriggerForEntity(vm, uid, n, color, cardType)
    if not uid then
        return false
    end
    if color ~= 0 or cardType ~= 0 then
        local cfgProp = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
        local cfg = cfgProp and cfgProp:GetConfig()
        if not cfg then
            return false
        end
        if color ~= 0 and cfg.Color ~= color then
            return false
        end
        if cardType ~= 0 and cfg.Type ~= cardType then
            return false
        end
    end
    -- DoneTimes 在激发结束后才累加，Phase1 读到的是激发前的值，+1 预判本次激发后是否命中倍数
    local doneTimes = vm:Read(uid, STECustomEnum.FieldNameType.DoneTimes) or 0
    return (doneTimes + 1) % n == 0
end

--- 本帧是否存在满足 (minHits, color, cardType, side) 约束的实体造成了 >= minHits 段有效攻击。
--- 有效攻击=AttackTarget atk>0（护盾减免不影响段数登记）。
--- minHits=1 color=0 cardType=0 side=0：任意实体本帧有造成过有效攻击即触发。
---@param vm STEVM.VM
---@param minHits number 有效攻击段数下限（attackTimes 按段累加）
---@param color number 0=不限颜色
---@param cardType number 0=不限类型
---@param side number STECustomEnum.AdjacentSide；0=不约束位置（任意卡牌），非零以 OwnCardId 为锚做空间过滤
---@param ignoreOwn number 非0表示忽略所属卡牌
---@return boolean
function Trigger.CheckDealtDamage(vm, minHits, color, cardType, side, ignoreOwn)
    local isIgnoreOwn = XTool.IsNumberValidEx(ignoreOwn)
    local ownId
    if side ~= 0 or isIgnoreOwn then
        ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        if not ownId then
            return false
        end
    end
    local dict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDamageDealtDict)
    return STEQuery.CheckDamageDealtMatch(vm, dict, minHits or 1, color, cardType, side, ownId, isIgnoreOwn)
end

--- 满足 (color, cardType, side) 约束的目标实体，其激活次数（DoneTimes）是否满足"本次激发后命中 n 的倍数"。
--- side=0：检查自身（OwnCardId）；非零：以 OwnCardId 为锚检查空间邻居。
--- DoneTimes 在激发结束后才累加，Trigger 在 Phase1 预判：(DoneTimes+1) % n == 0。
---@param vm STEVM.VM
---@param n number 每多少次激发触发一次（n<=0 返回 false）
---@param color number 0=不限颜色
---@param cardType number 0=不限类型
---@param side number STECustomEnum.AdjacentSide；0=自身
---@return boolean
function Trigger.CheckNthTrigger(vm, n, color, cardType, side)
    if not n or n <= 0 then
        return false
    end
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    if not ownId then
        return false
    end

    local s = STECustomEnum.AdjacentSide
    if side == 0 then
        return Trigger._CheckNthTriggerForEntity(vm, ownId, n, color, cardType)
    end
    if side == s.Left or side == s.Either then
        if Trigger._CheckNthTriggerForEntity(vm, STEQuery.GetLeftAdjacentCard(vm, ownId), n, color, cardType) then
            return true
        end
    end
    if side == s.Right or side == s.Either then
        if Trigger._CheckNthTriggerForEntity(vm, STEQuery.GetRightAdjacentCard(vm, ownId), n, color, cardType) then
            return true
        end
    end
    return false
end

--- 本帧是否有牌的 CD 被加速推进过。
--- scope=0：任意牌被加速（TickAccelEntityList 中存在 Card 标签实体，敌人入列不计入"牌"）；
--- scope=1：自身被加速（OwnCardId 在 TickAccelEntityList 中，不做 Card 过滤——自身即自身）。
---@param vm STEVM.VM
---@param scope number 0=任意牌 / 1=自身
---@param ignoreOwn number 非0 忽略自身（仅当scope=0时有意义）
---@return boolean
function Trigger.CheckAccelCard(vm, scope, ignoreOwn)
    local list = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickAccelEntityList)
    if not list or list:Len() == 0 then
        return false
    end

    local isIgnoreOwn = XTool.IsNumberValidEx(ignoreOwn)
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    -- scope==1（自身被加速）或 isIgnoreOwn（排除自身）均需 ownId；缺失 return false
    -- （fail-closed，对齐 CheckDealtDamage isIgnoreOwn 守卫 + scope==1 既有守卫，消 ownId nil 时 fail-open 误匹配）
    if (scope == 1 or isIgnoreOwn) and not ownId then
        return false
    end

    if scope == 1 then
        for i = 1, list:Len() do
            if list:GetByKey(i) == ownId then
                return true
            end
        end
        return false
    end

    -- scope == 0：任意牌（Card 标签实体）；isIgnoreOwn 时排除自身
    for i = 1, list:Len() do
        local uid = list:GetByKey(i)
        if vm:HasTag(uid, STECustomEnum.EntityTags.Card) then
            if not isIgnoreOwn or uid ~= ownId then
                return true
            end
        end
    end
    return false
end

--- buff自用，判断buff的目标主体当帧是否触发过
---@param vm STEVM.VM
function Trigger.CheckBuffSelfTargetTickDone(vm)
    local buffId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnBuffId)

    if not XTool.IsNumberValidEx(buffId) then
        vm:Error("黑板中的BuffId无效：" .. tostring(buffId))
        return
    end
    
    local targetId = vm:Read(buffId, STECustomEnum.FieldNameType.TargetEntityId)

    if not XTool.IsNumberValidEx(targetId) then
        vm:Error("Buff记录的目标Id无效：" .. tostring(targetId))
        return
    end

    -- 加载当前时刻触发的牌
    ---@type PropertyList
    local tickDoneCardList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDoneCardList)

    -- 检查是否存在满足位置的牌
    if not tickDoneCardList or tickDoneCardList:Len() == 0 then
        return false
    end
    
    return vm:PropContains(tickDoneCardList, targetId)
end
--endregion

return Trigger