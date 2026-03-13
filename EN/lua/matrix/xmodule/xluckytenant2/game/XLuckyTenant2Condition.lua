local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local ConditionType = XLuckyTenant2Enum.Condition

---@class XLuckyTenant2Condition
local XLuckyTenant2Condition = XClass(nil, "XLuckyTenant2Condition")

---@param model XLuckyTenant2Model
---@param conditionStr string condition字符串，支持|&（）公式组合
---@param context table 上下文（包含piece、board、bag等）
---@return boolean
function XLuckyTenant2Condition.Evaluate(model, conditionStr, context)
    if not conditionStr or conditionStr == "" then
        return true
    end

    -- 解析condition字符串，支持|&（）组合
    -- 这里简化处理，实际需要完整的表达式解析器
    local result = XLuckyTenant2Condition._EvaluateExpression(model, conditionStr, context)
    return result
end

---@param model XLuckyTenant2Model
---@param conditionId number condition表id
---@param context table 上下文
---@return boolean
function XLuckyTenant2Condition.EvaluateById(model, conditionId, context)
    local config = model:GetLuckyTenant2ChessConditionConfigById(conditionId)
    if not config then
        return false
    end

    -- ConditionDesc是字符串，需要转换为数字类型（枚举值）
    -- 如果是数字字符串，直接转换；否则可能需要映射表
    local conditionType = tonumber(config.ConditionDesc) or 0
    local param0 = (config.Param and config.Param[1]) or 0
    local param1 = (config.Param and config.Param[2]) or 0
    local param2 = (config.Param and config.Param[3]) or 0

    return XLuckyTenant2Condition._EvaluateCondition(model, conditionType, param0, param1, param2, context)
end

---@private
function XLuckyTenant2Condition._EvaluateExpression(model, expr, context)
    -- 简化版表达式解析，实际需要更完整的解析器
    -- 支持 | & ( ) 操作符
    
    -- 移除空格
    expr = string.gsub(expr, "%s+", "")
    
    -- 处理括号
    while string.find(expr, "%(") do
        expr = string.gsub(expr, "%(([^%(%)]+)%)", function(match)
            local result = XLuckyTenant2Condition._EvaluateExpression(model, match, context)
            return result and "1" or "0"
        end)
    end
    
    -- 处理 & (AND)
    while string.find(expr, "&") do
        expr = string.gsub(expr, "([^&|]+)&([^&|]+)", function(left, right)
            local leftResult = XLuckyTenant2Condition._EvaluateSimple(model, left, context)
            local rightResult = XLuckyTenant2Condition._EvaluateSimple(model, right, context)
            return (leftResult and rightResult) and "1" or "0"
        end)
    end
    
    -- 处理 | (OR)
    while string.find(expr, "|") do
        expr = string.gsub(expr, "([^&|]+)|([^&|]+)", function(left, right)
            local leftResult = XLuckyTenant2Condition._EvaluateSimple(model, left, context)
            local rightResult = XLuckyTenant2Condition._EvaluateSimple(model, right, context)
            return (leftResult or rightResult) and "1" or "0"
        end)
    end
    
    -- 最终结果
    return XLuckyTenant2Condition._EvaluateSimple(model, expr, context)
end

---@private
function XLuckyTenant2Condition._EvaluateSimple(model, expr, context)
    -- 如果是数字，直接返回
    local num = tonumber(expr)
    if num then
        return num ~= 0
    end
    
    -- 如果是condition id，调用EvaluateById
    local conditionId = tonumber(expr)
    if conditionId then
        return XLuckyTenant2Condition.EvaluateById(model, conditionId, context)
    end
    
    return false
end

---@private
function XLuckyTenant2Condition._EvaluateCondition(model, conditionType, param0, param1, param2, context)
    local piece = context.piece
    local board = context.board
    local bag = context.bag
    local game = context.game
    
    if conditionType == ConditionType.BondLevel then
        -- 指定羁绊id{0}等级是否={1}
        local bondId = param0
        local targetLevel = param1
        if game and game._BondManager then
            local bond = game._BondManager:GetBond(bondId)
            if bond then
                return bond:GetLevel() == targetLevel
            end
        end
        return false
        
    elseif conditionType == ConditionType.PieceQuality then
        -- 本棋子是否为指定品质等级{0}数组中的一个
        if not piece then return false end
        local quality = piece:GetQuality()
        -- 只检查非0的参数（0表示无效参数）
        return (param0 > 0 and quality == param0) 
            or (param1 > 0 and quality == param1) 
            or (param2 > 0 and quality == param2)
        
    elseif conditionType == ConditionType.PieceBond then
        -- 本棋子是否为指定羁绊{0}的棋子
        if not piece then return false end
        local bondId = param0
        local pieceBondId = piece:GetBondId()
        if type(pieceBondId) == "string" then
            -- 支持多个羁绊id，用|隔开
            if pieceBondId == "" then
                return false
            end
            for bondIdStr in string.gmatch(pieceBondId, "([^|]+)") do
                local id = tonumber(bondIdStr)
                if id and id == bondId then
                    return true
                end
            end
        else
            -- pieceBondId可能是数字或字符串，都转换为数字比较
            local id = tonumber(pieceBondId)
            if id and id == bondId then
                return true
            end
        end
        return false
        
    elseif conditionType == ConditionType.HasState then
        -- 本棋子是否含有状态{0}
        if not piece then return false end
        local stateType = param0
        return piece:HasState(stateType)
        
    elseif conditionType == ConditionType.AdjacentHasState then
        -- 本棋子的相邻棋子是否含有状态{0}
        if not piece or not board then return false end
        local stateType = param0
        local adjacentPieces = board:GetAdjacentPieces(piece)
        for _, adjPiece in ipairs(adjacentPieces) do
            if adjPiece:HasState(stateType) then
                return true
            end
        end
        return false
        
    elseif conditionType == ConditionType.StateInCountdown then
        -- 触发状态技能{0}后，是否在倒计时{1}回合内
        if not piece then return false end
        local stateId = param0
        local maxRounds = param1
        local state = piece:GetState(stateId)
        if state then
            return state:GetRemainRounds() <= maxRounds
        end
        return false
        
    elseif conditionType == ConditionType.OnBoard then
        -- 本棋子在棋盘上，填1表示在返回true，填0表示不在返回true
        if not piece then return false end
        local onBoard = piece:IsOnBoard()
        local expectOnBoard = param0 == 1
        return onBoard == expectOnBoard
    end
    
    return false
end

return XLuckyTenant2Condition

