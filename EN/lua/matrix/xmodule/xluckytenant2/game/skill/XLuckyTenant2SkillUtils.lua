local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---技能公共工具函数
---@class XLuckyTenant2SkillUtils
local SkillUtils = {}

---验证技能执行参数
---@param piece XLuckyTenant2Piece|nil 棋子对象
---@param params table|nil 技能参数
---@param minParamCount number|nil 最小参数数量（默认1，0表示不需要参数）
---@return boolean 验证是否通过
function SkillUtils.ValidateSkillParams(piece, params, minParamCount)
    if piece == nil or params == nil then
        return false
    end
    if minParamCount == nil or minParamCount == 0 then
        return true -- 不需要参数验证
    end
    return #params >= minParamCount
end

---是否为道具棋子ID（刷新/删除道具），随机与消除逻辑中需排除
---@param pieceId number 棋子ID
---@return boolean 是道具则返回true
function SkillUtils.IsPropPieceId(pieceId)
    if not pieceId then
        return false
    end
    local PropId = XLuckyTenant2Enum.PropId
    return pieceId == PropId.RefreshProp or pieceId == PropId.DeleteProp
end

---根据品质获取宝盒棋子ID（辅助函数）
---@param model XLuckyTenant2Model 配置模型
---@param quality number 品质值
---@return number 宝盒棋子ID（如果没有找到则返回0）
function SkillUtils.GetBoxPieceIdByQuality(model, quality)
    if not model or not quality then
        return 0
    end

    -- 获取所有棋子配置
    local allChessConfigs = model:GetLuckyTenant2ChessConfigs()
    if not allChessConfigs then
        return 0
    end

    -- 筛选出同品质的宝盒棋子（Type=Box），排除道具
    local PieceType = XLuckyTenant2Enum.PieceType
    local candidates = {}
    for _, config in pairs(allChessConfigs) do
        if config and config.Quality == quality and config.Type == PieceType.Box and not SkillUtils.IsPropPieceId(config.Id) then
            table.insert(candidates, config.Id)
        end
    end

    if #candidates == 0 then
        return 0
    end

    -- 随机选择一个同品质的宝盒棋子
    local randomIndex = math.random(1, #candidates)
    return candidates[randomIndex]
end

---光环类 value 增益：按 skillKey 存储，RefreshBondLevels 时会 ResetBondValueDeltas 回退
---仅用于「羁绊等级/棋盘状态」变化需重算的技能（如 Type103/105 基础/消除加成）
---@param piece XLuckyTenant2Piece 棋子对象
---@param delta number 增益值
---@param skillKey string 技能key
---@return boolean 是否有变化
function SkillUtils.UpdateBondBaseDelta(piece, delta, skillKey)
    if delta ~= 0 then
        piece:ApplyBondBaseValueDelta(skillKey, delta)
        return true
    end
    piece:ApplyBondBaseValueDelta(skillKey, 0)
    return false
end

---光环类消除价值增益：同上，用于「被消除时金币」的羁绊加成（Type103/105/204）
---会随 ResetBondValueDeltas 回退
---@param piece XLuckyTenant2Piece 棋子对象
---@param delta number 增益值
---@param skillKey string 技能key
---@return boolean 是否有变化
function SkillUtils.UpdateBondDeletionDelta(piece, delta, skillKey)
    if delta ~= 0 then
        piece:ApplyBondDeletionValueDelta(skillKey, delta)
        return true
    end
    piece:ApplyBondDeletionValueDelta(skillKey, 0)
    return false
end

---获取相邻空位列表
---@param piece XLuckyTenant2Piece 棋子对象
---@param proxy XLuckyTenant2OperationProxy 操作代理
---@return table 空位坐标列表 {{x, y}, ...}
function SkillUtils.GetAdjacentEmptyPositions(piece, proxy)
    if not piece or not proxy then
        return {}
    end
    return proxy:GetAdjacentEmptyPositions(piece)
end

return SkillUtils
