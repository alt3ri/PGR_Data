---棋子羁绊技能统一获取：GetBondsForPiece / FindSkillInBondsForPiece / ForEachBondSkillOfType / GetSkillsFromBonds
---供 OnDeleteEffects、SkillExecutor 等共用，技能来源统一为 bonds 而非棋子自身配置
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local PieceId = XLuckyTenant2Enum.PieceId or { Coin = 1, Subworm = 2, WeaponFragmentLv4 = 3, WeaponFragmentLv6 = 4 }
local XLuckyTenant2SkillBase = require("XModule/XLuckyTenant2/Game/XLuckyTenant2SkillBase")

local XLuckyTenant2BondSkills = {}

---判断羁绊是否含有 Type207 且 params[1] 匹配指定棋子 ID（用于子虫取 Type208）
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
---@param bondId number
---@param pieceId number 子虫等棋子 ID
---@return boolean
function XLuckyTenant2BondSkills.BondHasType207ForPieceId(model, game, bondId)
    if not model or not game or not bondId then
        return false
    end
    local bondManager = game:GetBondManager()
    if not bondManager then
        return false
    end
    local bond = bondManager:GetBond(bondId)
    if not bond then
        return false
    end
    local bondLevel = bond:GetLevel()
    if bondLevel <= 0 then
        return false
    end
    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel) or {}
    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        local configLevel = bondSkillConfig.Level or 0
        if bondLevel >= configLevel then
            local skillId = bondSkillConfig.SkillId
            if type(skillId) == "table" then
                skillId = skillId[1] or 0
            end
            if skillId and skillId > 0 then
                local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
                if skillConfig and skillConfig.Type == SkillType.Type207 then
                    return true
                end
            end
        end
    end
    return false
end

-- ==================== 从棋子所属 bond 获取羁绊列表 ====================

---获取「该棋子要考虑的羁绊」列表：有 BondId 则只返回这些羁绊，无 BondId（如子虫）则返回全部羁绊
---@param piece XLuckyTenant2Piece
---@param game XLuckyTenant2Game
---@return table[] 每项 { bondId, bond, bondLevel }
function XLuckyTenant2BondSkills.GetBondsForPiece(piece, game)
    local bondManager = game and game:GetBondManager()
    if not bondManager then
        return {}
    end
    local bondIdStr = piece and piece:GetBondId() or ""
    if bondIdStr and bondIdStr ~= "" then
        local list = {}
        for oneBondStr in string.gmatch(bondIdStr, "([^|]+)") do
            local bondId = tonumber(oneBondStr)
            if bondId then
                local bond = bondManager:GetBond(bondId)
                if bond then
                    local bondLevel = bond:GetLevel()
                    if bondLevel >= 0 then
                        list[#list + 1] = { bondId = bondId, bond = bond, bondLevel = bondLevel }
                    end
                end
            end
        end
        return list
    end
    local allBonds = bondManager:GetAllBonds() or {}
    local list = {}
    for _, bond in ipairs(allBonds) do
        local bondId = bond:GetBondId()
        local bondLevel = bond:GetLevel()
        if bondLevel >= 0 then
            list[#list + 1] = { bondId = bondId, bond = bond, bondLevel = bondLevel }
        end
    end
    return list
end

---在棋子所属羁绊中查找指定类型的技能
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
---@param skillType number 技能类型
---@param optFilter function|nil 可选，function(skillConfig, bondId) -> boolean
---@param bondsListCached table|nil 可选，若传入则复用不重新计算
---@return number|nil skillId, table|nil skillConfig, number|nil bondId
function XLuckyTenant2BondSkills.FindSkillInBondsForPiece(piece, model, game, skillType, optFilter, bondsListCached)
    if not model or not game then
        return nil, nil, nil
    end
    local bondsList = bondsListCached or XLuckyTenant2BondSkills.GetBondsForPiece(piece, game)
    for _, entry in ipairs(bondsList) do
        local bondId = entry.bondId
        local bondLevel = entry.bondLevel
        local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel) or {}
        for _, bondSkillConfig in ipairs(bondSkillConfigs) do
            local configLevel = bondSkillConfig.Level or 0
            if bondLevel >= configLevel then
                local skillId = bondSkillConfig.SkillId
                if type(skillId) == "table" then
                    skillId = skillId[1] or 0
                end
                if skillId and skillId > 0 then
                    local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
                    if skillConfig and skillConfig.Type == skillType then
                        if (not optFilter) or optFilter(skillConfig, bondId) then
                            return skillId, skillConfig, bondId
                        end
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

---遍历棋子所属羁绊中的指定类型技能
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
---@param skillType number
---@param callback function(skillId, skillConfig, bondId) 返回 true 表示停止遍历
---@param bondsListCached table|nil 可选
function XLuckyTenant2BondSkills.ForEachBondSkillOfType(piece, model, game, skillType, callback, bondsListCached)
    if not model or not game or not callback then
        return
    end
    local bondsList = bondsListCached or XLuckyTenant2BondSkills.GetBondsForPiece(piece, game)
    for _, entry in ipairs(bondsList) do
        local bondId = entry.bondId
        local bondLevel = entry.bondLevel
        local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel) or {}
        for _, bondSkillConfig in ipairs(bondSkillConfigs) do
            local configLevel = bondSkillConfig.Level or 0
            if bondLevel >= configLevel then
                local skillId = bondSkillConfig.SkillId
                if type(skillId) == "table" then
                    skillId = skillId[1] or 0
                end
                if skillId and skillId > 0 then
                    local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
                    if skillConfig and skillConfig.Type == skillType then
                        if callback(skillId, skillConfig, bondId) then
                            return
                        end
                    end
                end
            end
        end
    end
end

---从棋子配置 StateSkillId 收集技能（用于 bondId 为空的棋子，如 PieceId.Coin/Subworm/WeaponFragmentLv4/WeaponFragmentLv6）
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param resolveStateSkillIdFn function(stateSkillId, model) -> actualSkillId, skillConfig
---@return table[] 技能对象列表，每项支持 :GetType() :GetParams() :GetId() :GetSkillMode()
function XLuckyTenant2BondSkills.GetSkillsFromPieceConfig(piece, model, resolveStateSkillIdFn)
    if not model or not piece or not resolveStateSkillIdFn then
        return {}
    end
    local pieceId = piece:GetId()
    if not pieceId or pieceId <= 0 then
        return {}
    end
    local config = model:GetLuckyTenant2ChessConfigById(pieceId)
    if not config then
        return {}
    end
    local raw = config.StateSkillId
    local stateSkillIds = (type(raw) == "number" and raw > 0) and { raw } or (raw or {})
    -- 无 bondId 的棋子（PieceId 1/2/3/4）必须配置 StateSkillId，否则技能来源为空
    local isNoBondIdPiece = (pieceId == PieceId.Coin or pieceId == PieceId.Subworm or pieceId == PieceId.WeaponFragmentLv4 or pieceId == PieceId.WeaponFragmentLv6)
    if isNoBondIdPiece then
        local hasValid = false
        for i = 1, #stateSkillIds do
            if stateSkillIds[i] and stateSkillIds[i] > 0 then
                hasValid = true
                break
            end
        end
        if not hasValid and XLog and XLog.Warning then
            XLog.Warning(string.format("[BondSkills] 棋子配置 ID=%d（无 bondId 类型）未配置或 StateSkillId 为空，请在配置表中为该棋子填写 StateSkillId", pieceId))
        end
    end
    local list = {}
    local seen = {}
    for i = 1, #stateSkillIds do
        local stateSkillId = stateSkillIds[i]
        if stateSkillId and stateSkillId > 0 then
            local actualSkillId, skillConfig = resolveStateSkillIdFn(stateSkillId, model)
            if skillConfig and actualSkillId and not seen[actualSkillId] then
                seen[actualSkillId] = true
                local skillMode = skillConfig.SkillMode or 0
                local params = skillConfig.Params or {}
                local st = skillConfig.Type
                list[#list + 1] = XLuckyTenant2SkillBase.New(actualSkillId, st, params, skillMode, skillConfig.Name)
            end
        end
    end
    return list
end

---从棋子所属羁绊收集「所有技能」并返回与 piece:GetSkills 兼容的列表；若棋子 bondId 为空则从棋子配置 StateSkillId 取（需传入 resolveStateSkillIdFn）
---每项为 { GetType, GetParams, GetId, GetSkillMode }，按 skillId 去重（同一技能只保留一条）
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
---@param bondsListCached table|nil 可选
---@param resolveStateSkillIdFn function|nil 当棋子 bondId 为空时用此解析 StateSkillId（如 SkillExecutor.ResolveStateSkillId）
---@return table[] 技能对象列表，每项支持 :GetType() :GetParams() :GetId() :GetSkillMode()
function XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, model, game, bondsListCached, resolveStateSkillIdFn)
    if not model or not game then
        return {}
    end
    local bondIdStr = piece and piece:GetBondId() or ""
    -- bondId 为空的棋子（如 PieceId.Coin/Subworm/WeaponFragmentLv4/WeaponFragmentLv6）从棋子配置 StateSkillId 取技能，不从羁绊取
    if (not bondIdStr or bondIdStr == "") and resolveStateSkillIdFn then
        return XLuckyTenant2BondSkills.GetSkillsFromPieceConfig(piece, model, resolveStateSkillIdFn)
    end
    local bondsList = bondsListCached or XLuckyTenant2BondSkills.GetBondsForPiece(piece, game)
    local seen = {}
    local list = {}
    for _, entry in ipairs(bondsList) do
        local bondId = entry.bondId
        local bondLevel = entry.bondLevel
        local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel) or {}
        for _, bondSkillConfig in ipairs(bondSkillConfigs) do
            local configLevel = bondSkillConfig.Level or 0
            if bondLevel >= configLevel then
                local skillId = bondSkillConfig.SkillId
                if type(skillId) == "table" then
                    skillId = skillId[1] or 0
                end
                if skillId and skillId > 0 and not seen[skillId] then
                    local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
                    if skillConfig then
                        seen[skillId] = true
                        local skillMode = bondSkillConfig.SkillMode or skillConfig.SkillMode or 0
                        local params = skillConfig.Params or {}
                        local st = skillConfig.Type
                        list[#list + 1] = XLuckyTenant2SkillBase.New(skillId, st, params, skillMode, skillConfig.Name)
                    end
                end
            end
        end
    end
    return list
end

return XLuckyTenant2BondSkills
