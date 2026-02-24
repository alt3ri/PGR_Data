local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---@class XLuckyTenant2Bond
local XLuckyTenant2Bond = XClass(nil, "XLuckyTenant2Bond")

---@param bondId number 羁绊ID
---@param config XTableLuckyTenant2Bond 羁绊配置
function XLuckyTenant2Bond:Ctor(bondId, config)
    self._BondId = bondId
    self._Config = config
    self._Level = 0  -- 当前等级（0表示未激活）
    self._RelatedChessIds = {}  -- 关联棋子ID列表
    self._RelatedChessForScoreIds = {}  -- 关联计算金币的棋子ID列表
    self._UpgradeRequire = config and config.UpgradeRequire or 0
    self._UpgradeRequireDesc = config and config.UpgradeRequireDesc or ""
    
    -- 解析关联棋子
    if config and config.RelatedChess then
        self._RelatedChessIds = XLuckyTenant2Bond._ParseChessIds(config.RelatedChess)
    end
    if config and config.RelatedChessForScore then
        self._RelatedChessForScoreIds = XLuckyTenant2Bond._ParseChessIds(config.RelatedChessForScore)
    end
end

---@private
function XLuckyTenant2Bond._ParseChessIds(chessIdsStr)
    local result = {}
    if not chessIdsStr or chessIdsStr == "" then
        return result
    end
    for idStr in string.gmatch(chessIdsStr, "([^|]+)") do
        local id = tonumber(idStr)
        if id then
            table.insert(result, id)
        end
    end
    return result
end

function XLuckyTenant2Bond:GetBondId()
    return self._BondId
end

function XLuckyTenant2Bond:GetLevel()
    return self._Level
end

function XLuckyTenant2Bond:SetLevel(level)
    self._Level = level
end

function XLuckyTenant2Bond:GetName()
    return self._Config and self._Config.BondName or ""
end

function XLuckyTenant2Bond:GetIcon()
    return self._Config and self._Config.Icon or ""
end

function XLuckyTenant2Bond:GetRelatedChessIds()
    return self._RelatedChessIds
end

function XLuckyTenant2Bond:GetRelatedChessForScoreIds()
    return self._RelatedChessForScoreIds
end

function XLuckyTenant2Bond:GetUpgradeRequire()
    return self._UpgradeRequire
end

function XLuckyTenant2Bond:GetUpgradeRequireDesc()
    return self._UpgradeRequireDesc
end

---@param bag XLuckyTenant2Bag
---@return number 满足条件的棋子数量
function XLuckyTenant2Bond:CalculateSatisfyCount(bag)
    -- 如果UpgradeRequire未设置或为0，默认使用TypeCount
    local upgradeRequire = self._UpgradeRequire or XLuckyTenant2Enum.BondUpgradeRequire.TypeCount
    
    if upgradeRequire == XLuckyTenant2Enum.BondUpgradeRequire.TypeCount then
        -- 凑不同的关联棋子id种类（不计重复棋子）
        local typeSet = {}
        local pieces = bag:GetAllPieces()
        
        for _, piece in ipairs(pieces) do
            local pieceId = piece:GetId()
            
            -- 无论是否在棋盘上，都计入羁绊计算
            for _, relatedId in ipairs(self._RelatedChessIds) do
                if pieceId == relatedId then
                    typeSet[pieceId] = true
                    break
                end
            end
        end
        local count = 0
        for _ in pairs(typeSet) do
            count = count + 1
        end
        
        return count
    elseif upgradeRequire == XLuckyTenant2Enum.BondUpgradeRequire.TotalCount then
        -- 凑关卡棋子总数量（计重复棋子）
        local count = 0
        local pieces = bag:GetAllPieces()
        
        for _, piece in ipairs(pieces) do
            local pieceId = piece:GetId()
            
            -- 无论是否在棋盘上，都计入羁绊计算
            for _, relatedId in ipairs(self._RelatedChessIds) do
                if pieceId == relatedId then
                    count = count + 1
                    break
                end
            end
        end
        
        return count
    end
    return 0
end

---@param bag XLuckyTenant2Bag
---@param model XLuckyTenant2Model|nil 配置模型（可选，用于获取SkillRequire数据）
---@return number 应该达到的等级
function XLuckyTenant2Bond:CalculateLevel(bag, model)
    local satisfyCount = self:CalculateSatisfyCount(bag)
    
    -- 如果提供了model，使用SkillRequire字段计算等级
    if model and model.GetLuckyTenant2BondSkillRequiresByBondId then
        local skillRequires = model:GetLuckyTenant2BondSkillRequiresByBondId(self._BondId)
        
        if skillRequires and #skillRequires > 0 then
            -- 从高等级到低等级检查
            for i = #skillRequires, 1, -1 do
                local skillRequire = skillRequires[i]
                if satisfyCount >= skillRequire then
                    return i  -- 等级从1开始，索引i对应等级i
                end
            end
            return 0
        end
    end
    
    return 0
end

---@return boolean 是否激活（至少1级）
function XLuckyTenant2Bond:IsActivated()
    return self._Level > 0
end

return XLuckyTenant2Bond

