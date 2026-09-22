--- STE 通用查询原语，供 Trigger / Selector / Effect 单向引用，自身不依赖三者。
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

local STEQuery = {}

--region 位置/索引查询

--- 全体卡牌 Index 极值（最左=min, 最右=max）；无卡返回 nil, nil。
--- CardEntityIds 约定 Index == 下标，O(1) 直取首尾。
---@param vm STEVM.VM
---@return number|nil minIndex, number|nil maxIndex
function STEQuery.GetCardIndexRange(vm)
    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    local len = cardIds and cardIds:Len() or 0
    if len <= 0 then
        return nil, nil
    end
    return 1, len
end

--- 把 (mode, param) 解析成绝对 Index；解析不出返回 nil。
---@param vm STEVM.VM
---@param mode number STECustomEnum.PosMode
---@param param number|nil
---@return number|nil
function STEQuery.ResolveIndex(vm, mode, param)
    if mode == STECustomEnum.PosMode.Absolute then
        return param
    elseif mode == STECustomEnum.PosMode.RelativeToSelf then
        local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        local selfIndex = ownId and vm:Read(ownId, STECustomEnum.FieldNameType.Index)
        if not selfIndex then
            return nil
        end
        return selfIndex + param
    elseif mode == STECustomEnum.PosMode.Leftmost then
        return STEQuery.GetCardIndexRange(vm)
    elseif mode == STECustomEnum.PosMode.Rightmost then
        local _, maxIndex = STEQuery.GetCardIndexRange(vm)
        return maxIndex
    end
    return nil
end

--- 按紧凑索引取卡牌 uid（CardEntityIds 下标 == Index，O(1)）。
---@param vm STEVM.VM
---@param index number
---@return any|nil uid
function STEQuery.GetCardByIndex(vm, index)
    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    if not cardIds or index < 1 or index > cardIds:Len() then
        return nil
    end
    return cardIds:GetByKey(index)
end

--- 返回 uid 左侧空间紧贴的卡牌 uid；无左邻或有缝隙则返回 nil。
--- 算法：取 Index-1 处的紧凑邻居，验证 PosIndex_neighbor + Size_neighbor == PosIndex_self。
---@param vm STEVM.VM
---@param uid any 自身卡牌 uid
---@return any|nil
function STEQuery.GetLeftAdjacentCard(vm, uid)
    local selfIndex = vm:Read(uid, STECustomEnum.FieldNameType.Index)
    if not selfIndex then
        return nil
    end
    local neighborUid = STEQuery.GetCardByIndex(vm, selfIndex - 1)
    if not neighborUid then
        return nil
    end
    local neighborPos = vm:Read(neighborUid, STECustomEnum.FieldNameType.PosIndex)
    local neighborCfg = vm:ReadProperty(neighborUid, STECustomEnum.FieldNameType.CardConfig)
    local neighborCfgData = neighborCfg and neighborCfg:GetConfig()
    local neighborSize = (neighborCfgData and neighborCfgData.Size) or 1
    local selfPos = vm:Read(uid, STECustomEnum.FieldNameType.PosIndex)
    if neighborPos + neighborSize == selfPos then
        return neighborUid
    end
    return nil
end

--- 返回 uid 右侧空间紧贴的卡牌 uid；无右邻或有缝隙则返回 nil。
--- 算法：取 Index+1 处的紧凑邻居，验证 PosIndex_self + Size_self == PosIndex_neighbor。
---@param vm STEVM.VM
---@param uid any 自身卡牌 uid
---@return any|nil
function STEQuery.GetRightAdjacentCard(vm, uid)
    local selfIndex = vm:Read(uid, STECustomEnum.FieldNameType.Index)
    if not selfIndex then
        return nil
    end
    local neighborUid = STEQuery.GetCardByIndex(vm, selfIndex + 1)
    if not neighborUid then
        return nil
    end
    local selfPos = vm:Read(uid, STECustomEnum.FieldNameType.PosIndex)
    local selfCfg = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
    local selfCfgData = selfCfg and selfCfg:GetConfig()
    local selfSize = (selfCfgData and selfCfgData.Size) or 1
    local neighborPos = vm:Read(neighborUid, STECustomEnum.FieldNameType.PosIndex)
    if selfPos + selfSize == neighborPos then
        return neighborUid
    end
    return nil
end

--endregion

--region 邻居属性匹配

--- 判断自身指定方向的空间邻居是否存在，且其指定配置字段（PropertyConfig）的 Color/Type 满足约束。
--- side 语义同 AdjacentSide；color/cardType 以 0 表示不约束。
--- Either 时任一邻居满足即返回 true。
---@param vm STEVM.VM
---@param side number STECustomEnum.AdjacentSide
---@param ownId any 自身卡牌 uid
---@param color number 0=不限
---@param cardType number 0=不限
---@param configField string FieldNameType 中的 PropertyConfig 字段名
---@return boolean
function STEQuery.CheckAnyNeighborConfigMatch(vm, side, ownId, color, cardType, configField)
    local s = STECustomEnum.AdjacentSide
    local function check(neighborUid)
        if not neighborUid then
            return false
        end
        local cfgProp = vm:ReadProperty(neighborUid, configField)
        local cfg = cfgProp and cfgProp:GetConfig()
        if not cfg then
            return false
        end
        local colorOk = color == 0 or cfg.Color == color
        local typeOk = cardType == 0 or cfg.Type == cardType
        return colorOk and typeOk
    end
    if side == s.Left or side == s.Either then
        if check(STEQuery.GetLeftAdjacentCard(vm, ownId)) then
            return true
        end
    end
    if side == s.Right or side == s.Either then
        if check(STEQuery.GetRightAdjacentCard(vm, ownId)) then
            return true
        end
    end
    return false
end

--endregion

--region tick 列表匹配

--- 判断 tick 列表中是否有满足 color / cardType / side 约束的实体（紧凑邻接：Index offset ±1）。
--- 所有参数均以 0 表示"不约束"，与 BallColor / AdjacentSide 枚举从 1 起一致。
---@param vm STEVM.VM
---@param tickList PropertyList
---@param color number 0=不限
---@param cardType number 0=不限
---@param side number 0=不限，见 STECustomEnum.AdjacentSide
---@param selfIndex number|nil side≠0 时须传入自身 Index
---@return boolean
function STEQuery.CheckTickListMatch(vm, tickList, color, cardType, side, selfIndex)
    if not tickList or tickList:Len() == 0 then
        return false
    end
    local needCardFilter = color ~= 0 or cardType ~= 0
    local s = STECustomEnum.AdjacentSide

    for i = 1, tickList:Len() do
        local uid = tickList:GetByKey(i)
        local passes = true

        if side ~= 0 then
            local idx = vm:Read(uid, STECustomEnum.FieldNameType.Index)
            if not idx then
                passes = false
            else
                local offset = idx - selfIndex
                passes = (side == s.Left and offset == -1)
                        or (side == s.Right and offset == 1)
                        or (side == s.Either and (offset == -1 or offset == 1))
            end
        end

        if passes and needCardFilter then
            local cfgProp = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
            local cfg = cfgProp and cfgProp:GetConfig()
            passes = cfg ~= nil
                    and (color == 0 or cfg.Color == color)
                    and (cardType == 0 or cfg.Type == cardType)
        end

        if passes then
            return true
        end
    end
    return false
end

--- 判断 tick 列表中是否有满足 color / cardType / side 约束的实体（空间邻接：PosIndex+Size 无缝隙）。
--- 预算自身的空间邻居 uid，再对 tick 列表做 O(1) 身份比对；邻居均不存在则提前返回 false。
---@param vm STEVM.VM
---@param tickList PropertyList
---@param color number 0=不限
---@param cardType number 0=不限
---@param side number 0=不限，见 STECustomEnum.AdjacentSide
---@param selfId any|nil side≠0 时须传入自身卡牌 uid
---@return boolean
function STEQuery.CheckTickListMatchSpatial(vm, tickList, color, cardType, side, selfId)
    if not tickList or tickList:Len() == 0 then
        return false
    end
    local needCardFilter = color ~= 0 or cardType ~= 0
    local s = STECustomEnum.AdjacentSide

    local leftNeighbor, rightNeighbor
    if side ~= 0 and selfId then
        if side == s.Left or side == s.Either then
            leftNeighbor = STEQuery.GetLeftAdjacentCard(vm, selfId)
        end
        if side == s.Right or side == s.Either then
            rightNeighbor = STEQuery.GetRightAdjacentCard(vm, selfId)
        end
        if not leftNeighbor and not rightNeighbor then
            return false
        end
    end

    for i = 1, tickList:Len() do
        local uid = tickList:GetByKey(i)
        local passes = side == 0 or uid == leftNeighbor or uid == rightNeighbor

        if passes and needCardFilter then
            local cfgProp = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
            local cfg = cfgProp and cfgProp:GetConfig()
            passes = cfg ~= nil
                    and (color == 0 or cfg.Color == color)
                    and (cardType == 0 or cfg.Type == cardType)
        end

        if passes then
            return true
        end
    end
    return false
end

--endregion

--region 帧级伤害字典查询

--- 查询帧级伤害字典中是否存在满足 (minHits, color, cardType, side) 约束的实体。
--- 以 CardEntityIds 为遍历集，对每个实体做空间/属性过滤，再查 dict 命中次数。
--- side=0 不约束位置；color=0 不限颜色；cardType=0 不限类型（全 0=任意实体有造成伤害）。
---@param vm STEVM.VM
---@param dict any PropertyDict（TickDamageDealtDict）
---@param minHits number 命中次数下限（>= minHits 才通过）
---@param color number 0=不限
---@param cardType number 0=不限
---@param side number STECustomEnum.AdjacentSide；0=不约束位置
---@param ownId any|nil side≠0（空间锚点）或 ignoreOwn（排除自身）时须传入自身卡牌 uid
---@param ignoreOwn boolean 是否忽略自身卡牌
---@return boolean
function STEQuery.CheckDamageDealtMatch(vm, dict, minHits, color, cardType, side, ownId, ignoreOwn)
    -- 契约守卫：ignoreOwn=true 须 ownId 非空（排除自身需自身 uid）；违约 vm:Error 暴露 + return false
    -- （fail-closed，防 uid~=nil 恒真致静默退化为"不忽略自身"；当前唯一调用方 CheckDealtDamage 已守卫故不可达，防御未来调用方违约）
    if ignoreOwn and not ownId then
        vm:Error("CheckDamageDealtMatch: ignoreOwn=true 但 ownId=nil（调用方违约，ignoreOwn 时须传入自身 uid）")
        return false
    end
    local s = STECustomEnum.AdjacentSide
    local needCardFilter = color ~= 0 or cardType ~= 0

    local leftNeighbor, rightNeighbor
    
    -- 空间约束
    if side ~= 0 and ownId then
        if side == s.Left or side == s.Either then
            leftNeighbor = STEQuery.GetLeftAdjacentCard(vm, ownId)
        end
        if side == s.Right or side == s.Either then
            rightNeighbor = STEQuery.GetRightAdjacentCard(vm, ownId)
        end
        if not leftNeighbor and not rightNeighbor then
            return false
        end
    end

    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    local len = cardIds and cardIds:Len() or 0
    for i = 1, len do
        local uid = cardIds:GetByKey(i)

        if not ignoreOwn or uid ~= ownId then
            local passes = side == 0 or uid == leftNeighbor or uid == rightNeighbor

            if passes and needCardFilter then
                local cfgProp = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
                local cfg = cfgProp and cfgProp:GetConfig()
                passes = cfg ~= nil
                        and (color == 0 or cfg.Color == color)
                        and (cardType == 0 or cfg.Type == cardType)
            end

            if passes and (vm:PropGet(dict, uid) or 0) >= minHits then
                return true
            end
        end
    end
    return false
end

--endregion

return STEQuery
