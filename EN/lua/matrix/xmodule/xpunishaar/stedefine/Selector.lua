local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local STEQuery = require("XModule/XPunishaar/STEDefine/STEQuery")

local Selector = {}

--- 选择隶属主体
---@param vm STEVM.VM
function Selector.GetOwnerEntityId(vm)
    return vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
end

--- 选择指定索引的卡牌
--- CardEntityIds 有序表约定 Index == 列表下标，直接取址 O(1)。
---@param vm STEVM.VM
function Selector.GetTargetIndexCardId(vm, index)
    return STEQuery.GetCardByIndex(vm, index)
end

--- 选择处于某位置的卡牌（绝对/相对自身/最左/最右 统一入口）
--- 仅适用一维紧凑索引、1卡占1格；解析不出位置返回 nil
---@param vm STEVM.VM
---@param mode number STECustomEnum.PosMode
---@param param number|nil 绝对模式=索引；相对模式=偏移(左负右正)；最左/最右忽略
function Selector.GetCardIdByPos(vm, mode, param, color, cardType)
    local targetIndex = STEQuery.ResolveIndex(vm, mode, param)
    if not targetIndex then
        return nil
    end
    local uid = STEQuery.GetCardByIndex(vm, targetIndex)
    if not uid then
        return nil
    end
    -- 颜色/类型约束（nil/0=不限；对齐 GetCardsByConfigFilter 范式）#4.8
    if (color and color ~= 0) or (cardType and cardType ~= 0) then
        local cfgProp = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
        local cfg = cfgProp and cfgProp:GetConfig()
        if not cfg then
            return nil
        end
        if color and color ~= 0 and cfg.Color ~= color then
            return nil
        end
        if cardType and cardType ~= 0 and cfg.Type ~= cardType then
            return nil
        end
    end
    return uid
end

--- 选择玩家
---@param vm STEVM.VM
function Selector.GetPlayer(vm)
    return STECustomEnum.GlobalEntityIds.Player
end

--- 选择敌人
---@param vm STEVM.VM
function Selector.GetEnemy(vm)
    return STECustomEnum.GlobalEntityIds.Enemy
end

--- 选择全局
---@param vm STEVM.VM
function Selector.GetGlobal(vm)
    return STECustomEnum.GlobalEntityIds.Global
end

--- 选择「指定属性值满足比较条件」的所有卡牌。
--- 遍历 Global.CardEntityIds，逐个读指定属性(FieldNameEnum)与 value 按 op 比较，满足者收集成列表。
--- 无匹配返回空表（调用方 Effect 对空表/nil 已容错）。
---@param vm STEVM.VM
---@param fieldEnum number 属性字段枚举（STECustomEnum.FieldNameEnum，数值类型）
---@param op number STEEnum.OpType 比较运算
---@param value number 比较阈值
---@return any[] 满足条件的卡牌 uid 列表
function Selector.GetCardsByFieldCompare(vm, fieldEnum, op, value)
    local fieldName = STECustomEnum.FieldNameEnum[fieldEnum]
    local result = {}
    if not fieldName then
        return result
    end
    ---@type PropertyList
    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    local len = cardIds and cardIds:Len() or 0
    for i = 1, len do
        local uid = cardIds:GetByKey(i)
        local curVal = vm:Read(uid, fieldName) or 0
        if vm:Compare(curVal, op, value) then
            result[#result + 1] = uid
        end
    end
    return result
end

--- 选择「指定配置属性」满足约束的所有卡牌（Color / Type；0=不约束）。
--- 配置常量来自 PropertyConfig，不参与事务，不走 FieldNameEnum。
--- includeSelf 非零则将所属牌纳入候选（黑板 OwnCardId）；为 0 则排除。
--- 无匹配返回空表。
---@param vm STEVM.VM
---@param color number 球颜色（STECustomEnum.BallColor），0=不限
---@param cardType number 卡牌类型（XTablePunishaarCard.Type），0=不限
---@param includeSelf number 0=排除所属牌，非0=包括所属牌
---@return any[] 满足条件的卡牌 uid 列表
function Selector.GetCardsByConfigFilter(vm, color, cardType, includeSelf)
    local ownId = includeSelf == 0 and vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId) or nil
    local result = {}
    local cardIds = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
    local len = cardIds and cardIds:Len() or 0
    for i = 1, len do
        local uid = cardIds:GetByKey(i)
        if uid ~= ownId then
            local cfgProp = vm:ReadProperty(uid, STECustomEnum.FieldNameType.CardConfig)
            local cfg = cfgProp and cfgProp:GetConfig()
            if cfg then
                local colorOk = color == 0 or cfg.Color == color
                local typeOk = cardType == 0 or cfg.Type == cardType
                if colorOk and typeOk then
                    result[#result + 1] = uid
                end
            end
        end
    end
    return result
end

--- 选择所属牌的紧凑邻居（Index ±1，不校验空间缝隙），返回列表（0~2 个元素）。
---@param vm STEVM.VM
---@param side number STECustomEnum.AdjacentSide（Left/Right/Either）
---@return any[] uid 列表
function Selector.GetAdjacentCardsByIndex(vm, side)
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    if not ownId then
        return {}
    end
    local selfIndex = vm:Read(ownId, STECustomEnum.FieldNameType.Index)
    if not selfIndex then
        return {}
    end
    local s = STECustomEnum.AdjacentSide
    local result = {}
    if side == s.Left or side == s.Either then
        local uid = STEQuery.GetCardByIndex(vm, selfIndex - 1)
        if uid then
            result[#result + 1] = uid
        end
    end
    if side == s.Right or side == s.Either then
        local uid = STEQuery.GetCardByIndex(vm, selfIndex + 1)
        if uid then
            result[#result + 1] = uid
        end
    end
    return result
end

--- 选择所属牌的空间邻居（PosIndex+Size 无缝隙），返回列表（0~2 个元素）。
---@param vm STEVM.VM
---@param side number STECustomEnum.AdjacentSide（Left/Right/Either）
---@return any[] uid 列表
function Selector.GetAdjacentCardsBySpatial(vm, side)
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    if not ownId then
        return {}
    end
    local s = STECustomEnum.AdjacentSide
    local result = {}
    if side == s.Left or side == s.Either then
        local uid = STEQuery.GetLeftAdjacentCard(vm, ownId)
        if uid then
            result[#result + 1] = uid
        end
    end
    if side == s.Right or side == s.Either then
        local uid = STEQuery.GetRightAdjacentCard(vm, ownId)
        if uid then
            result[#result + 1] = uid
        end
    end
    return result
end

return Selector