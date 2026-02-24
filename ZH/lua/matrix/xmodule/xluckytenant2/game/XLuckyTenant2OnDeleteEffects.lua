---删除时触发逻辑：Type204/208/507/502 等「棋子被删除时」的效果统一在此处理
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local PieceType = XLuckyTenant2Enum.PieceType
local PieceId = XLuckyTenant2Enum.PieceId or { Coin = 1, Subworm = 2, WeaponFragmentLv4 = 3, WeaponFragmentLv6 = 4 }
local SkillType = XLuckyTenant2Enum.Skill
local TriggerState = XLuckyTenant2Enum.TriggerState
local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")
local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")

local XLuckyTenant2OnDeleteEffects = {}

-- ==================== 删除时技能效果 ====================

---Type208 传染相邻棋子（供 SkillExecutor.Type208 与 ApplyOnDeleteEffects 共用）
---@param piece XLuckyTenant2Piece
---@param skill XLuckyTenant2ChessSkill
---@param context table 需含 proxy
---@return number 成功传染的数量
function XLuckyTenant2OnDeleteEffects.DoType208InfectAdjacent(piece, skill, context)
    local params = skill:GetParams() or {}
    local scoreDelta = params[1] or 0
    local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
    local infectedCount = 0
    for _, adjPiece in ipairs(adjacentPieces) do
        local adjBondIdStr = adjPiece:GetBondId()
        if adjBondIdStr and adjBondIdStr ~= "" then
            local targetStateSkillId = nil
            for bondIdStr in string.gmatch(adjBondIdStr, "([^|]+)") do
                local bondId = tonumber(bondIdStr)
                if XLuckyTenant2Enum.BondToInfectionSkillMap[bondId] then
                    targetStateSkillId = XLuckyTenant2Enum.BondToInfectionSkillMap[bondId]
                    break
                end
            end
            if targetStateSkillId and not adjPiece:HasState(TriggerState.Infection) then
                context.proxy:ApplyState(adjPiece, TriggerState.Infection, targetStateSkillId, -1)
                infectedCount = infectedCount + 1
                if scoreDelta > 0 then
                    context.proxy:AddScore(scoreDelta)
                end
            end
        end
    end
    return infectedCount
end

---Type204：当子虫/怪物被删除时，按羁绊技能额外得基础金币*N（从棋子所属 bond 取技能）
---@param bondsListCached table|nil 可选，同一次删除内复用避免重复计算
local function ApplyType204(ctx, piece, pieceId, baseValue, model, game, bondsListCached)
    local isMonster = piece:GetPieceType() == PieceType.Monster
    if not isMonster and pieceId ~= PieceId.Subworm then
        return
    end
    if not model or not game then
        return
    end
    XLuckyTenant2BondSkills.ForEachBondSkillOfType(piece, model, game, SkillType.Type204, function(skillId, skillConfig, bondId)
        local params = skillConfig.Params or {}
        local bugPieceId = params[1] or 0
        local multiplier = params[2] or 0
        if (bugPieceId ~= 0 and bugPieceId ~= pieceId) or multiplier <= 0 then
            return
        end
        local extraScore = baseValue * multiplier
        if extraScore > 0 then
            ctx:AddScoreThisRound(extraScore)
            if XMVCA.XLuckyTenant2 then
                XMVCA.XLuckyTenant2:Print("[OnDeleteEffects] Type204: 额外得分", extraScore, "基础金币:", baseValue, "倍数:", multiplier)
            end
        end
    end, bondsListCached)
end

---从棋子配置 StateSkillId 中按类型查找第一个技能（用于 bondId 为空的棋子）
---@return number|nil skillId, table|nil skillConfig
local function FindSkillInPieceConfigByType(piece, model, skillType)
    if not piece or not model or not skillType then
        return nil, nil
    end
    local pieceId = piece:GetId()
    if not pieceId or pieceId <= 0 then
        return nil, nil
    end
    local config = model:GetLuckyTenant2ChessConfigById(pieceId)
    if not config then
        return nil, nil
    end
    local raw = config.StateSkillId
    local stateSkillIds = (type(raw) == "number" and raw > 0) and { raw } or (raw or {})
    for i = 1, #stateSkillIds do
        local stateSkillId = stateSkillIds[i]
        if stateSkillId and stateSkillId > 0 then
            local actualSkillId, cfg = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
            if cfg and cfg.Type == skillType then
                return actualSkillId or stateSkillId, cfg
            end
        end
    end
    return nil, nil
end

---从羁绊中取 Type208 技能配置，构造供 DoType208InfectAdjacent 用的「技能」表（GetParams/GetId）
local function BuildType208SkillFromConfig(skillId, skillConfig)
    local params = (skillConfig and skillConfig.Params) or {}
    return {
        GetParams = function() return params end,
        GetId = function() return skillId end,
    }
end

---Type208：被删除时传染相邻。有 BondId 则从所属 bond 取 Type208；子虫（pieceId=Subworm）从棋子配置 StateSkillId 遍历取 Type208
---@param bondsListCached table|nil 可选，同一次删除内复用避免重复计算
local function ApplyType208(ctx, piece, model, game, bondsListCached)
    if not model or not game then
        return
    end
    local pieceId = piece:GetId()
    local bondIdStr = piece:GetBondId() or ""
    local skillId, skillConfig, bondId = nil, nil, nil

    -- 子虫：从棋子配置 StateSkillId 遍历得到 Type208，不判断羁绊
    if pieceId == PieceId.Subworm and (not bondIdStr or bondIdStr == "") then
        local config = model:GetLuckyTenant2ChessConfigById(pieceId)
        if config then
            local raw = config.StateSkillId
            local stateSkillIds = (type(raw) == "number" and raw > 0) and { raw } or (raw or {})
            for i = 1, #stateSkillIds do
                local stateSkillId = stateSkillIds[i]
                if stateSkillId and stateSkillId > 0 then
                    local actualSkillId, cfg = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
                    if cfg and cfg.Type == SkillType.Type208 then
                        skillId = actualSkillId or stateSkillId
                        skillConfig = cfg
                        break
                    end
                end
            end
        end
    elseif bondIdStr and bondIdStr ~= "" then
        -- 有 BondId：从所属 bond 取 Type208；无 BondId 且非子虫（如 PieceId.Coin、PieceId.WeaponFragmentLv4/WeaponFragmentLv6）不查 bond，避免误用其他羁绊的 Type208
        skillId, skillConfig, bondId = XLuckyTenant2BondSkills.FindSkillInBondsForPiece(piece, model, game, SkillType.Type208, nil, bondsListCached)
    end

    if skillId and skillConfig then
        local skill = BuildType208SkillFromConfig(skillId, skillConfig)
        local context = { piece = piece, proxy = ctx.proxy, model = model }
        local infectedCount = XLuckyTenant2OnDeleteEffects.DoType208InfectAdjacent(piece, skill, context)
        local success = infectedCount > 0
        if XMVCA.XLuckyTenant2 then
            XMVCA.XLuckyTenant2:Print("[OnDeleteEffects] Type208: 执行", success and "成功" or "失败", "感染相邻", infectedCount, "个 (bondId=" .. tostring(bondId or "") .. ")")
        end
    end
end

---Type507：宝盒羁绊lv.4 - 宝盒被消除时品质+1 或 橙色加金币。有 BondId 从 bond 取；无 BondId 从棋子配置 StateSkillId 取
---@param bondsListCached table|nil 可选，同一次删除内复用避免重复计算
---@return boolean 是否已触发（用于 Type502 跳过）
local function ApplyType507(ctx, piece, x, y, fromPieceUid, model, game, bondsListCached)
    if not piece or piece:GetPieceType() ~= PieceType.Box or not (x > 0 and y > 0) then
        return false
    end
    if not model or not game then
        return false
    end
    local bondIdStr = piece:GetBondId() or ""
    local skillId, skillConfig = nil, nil
    if bondIdStr and bondIdStr ~= "" then
        skillId, skillConfig = XLuckyTenant2BondSkills.FindSkillInBondsForPiece(piece, model, game, SkillType.Type507, nil, bondsListCached)
    else
        -- bondId 为空的宝盒从棋子配置 StateSkillId 取 Type507
        skillId, skillConfig = FindSkillInPieceConfigByType(piece, model, SkillType.Type507)
    end
    if not skillConfig then
        return false
    end
    local type507Params = skillConfig.Params or {}
    local currentQuality = piece:GetQuality() or 0
    local maxQuality = 5
    local goldValue = type507Params[1] or 10
    if currentQuality < maxQuality then
        local newQuality = currentQuality + 1
        local newPieceId = 0
        if model and model.GetLuckyTenant2ChessConfigs then
            local configs = model:GetLuckyTenant2ChessConfigs()
            local candidates = {}
            for _, config in pairs(configs or {}) do
                if config and config.Type == PieceType.Box and config.Quality == newQuality then
                    table.insert(candidates, config.Id)
                end
            end
            if #candidates > 0 then
                newPieceId = candidates[math.random(1, #candidates)]
            end
        end
        if newPieceId > 0 then
            local ok, newPiece = ctx:AddNewPieceToBag(newPieceId)
            if ok and newPiece then
                ctx:SetPieceByPosition(newPiece, x, y)
                if XMVCA.XLuckyTenant2 then
                    XMVCA.XLuckyTenant2:Print(string.format("[OnDeleteEffects] Type507: 宝盒被消除，品质+1 新宝盒 品质%d→%d", currentQuality, newQuality))
                end
                return true
            end
        end
    elseif currentQuality == maxQuality and goldValue > 0 then
        local fromPiece = ctx:FindPieceByUid(fromPieceUid)
        if fromPiece then
            ctx.proxy:ModifyPieceValue(fromPiece, goldValue)
        else
            ctx:AddScoreThisRound(goldValue)
        end
        if XMVCA.XLuckyTenant2 then
            XMVCA.XLuckyTenant2:Print(string.format("[OnDeleteEffects] Type507: 橙色宝盒被消除，增加金币+%d", goldValue))
        end
        return true
    end
    return false
end

---Type502：宝盒被动02 - 宝盒被消除时原地产生宝盒。有 BondId 从 bond 取；无 BondId 从棋子配置 StateSkillId 取
---@param bondsListCached table|nil 可选，同一次删除内复用避免重复计算
local function ApplyType502(ctx, piece, x, y, deleteSkillId, model, game, bondsListCached)
    if not piece or piece:GetPieceType() ~= PieceType.Box or deleteSkillId == SkillType.Type502 then
        return
    end
    if not (x > 0 and y > 0) then
        return
    end
    if not model or not game then
        return
    end
    local bondIdStr = piece:GetBondId() or ""
    local skillId, skillConfig = nil, nil
    if bondIdStr and bondIdStr ~= "" then
        skillId, skillConfig = XLuckyTenant2BondSkills.FindSkillInBondsForPiece(piece, model, game, SkillType.Type502, nil, bondsListCached)
    else
        skillId, skillConfig = FindSkillInPieceConfigByType(piece, model, SkillType.Type502)
    end
    if not skillConfig then
        return
    end
    local type502Params = skillConfig.Params or {}
    local probabilityOriginal = type502Params[1] or 70
    local probabilityUpgrade = type502Params[2] or 30
    local currentQuality = piece:GetQuality() or 0
    if currentQuality <= 0 then
        return
    end
    local maxQuality = 5
    local random = math.random(1, 100)
    local newQuality = currentQuality
    if random <= probabilityOriginal then
        newQuality = currentQuality
    elseif random <= probabilityOriginal + probabilityUpgrade then
        newQuality = math.min(currentQuality + 1, maxQuality)
    end
    local newPieceId = 0
    if model and model.GetLuckyTenant2ChessConfigs then
        local configs = model:GetLuckyTenant2ChessConfigs()
        local candidates = {}
        for _, config in pairs(configs or {}) do
            if config and config.Type == PieceType.Box and config.QualityValue == newQuality then
                table.insert(candidates, config.Id)
            end
        end
        if #candidates > 0 then
            newPieceId = candidates[math.random(1, #candidates)]
        end
    end
    if newPieceId <= 0 then
        newPieceId = piece:GetId()
    end
    local ok, newPiece = ctx:AddNewPieceToBag(newPieceId)
    if ok and newPiece then
        ctx:SetPieceByPosition(newPiece, x, y)
    end
end

---Type602：红潮lv1 - 相邻棋子被消除时，该红潮基础金币+N。仅通过删除流程触发，在此直接实现，不经过 SkillExecutor。
---@param ctx XLuckyTenant2OperationContext
---@param piece XLuckyTenant2Piece 即将被删除的棋子（其相邻红潮会触发 Type602）
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
local function ApplyType602(ctx, piece, model, game)
    if not ctx or not piece or not model or not game then
        return
    end
    local adjacentPieces = ctx.proxy:GetAdjacentPieces(piece)
    if not adjacentPieces then
        return
    end
    for _, adjPiece in ipairs(adjacentPieces) do
        if adjPiece and adjPiece:GetPieceType() == PieceType.RedTide then
            local skills = XLuckyTenant2BondSkills.GetSkillsFromBonds(adjPiece, model, game, nil, SkillExecutor.ResolveStateSkillId)
            if skills then
                for _, skill in ipairs(skills) do
                    if skill and skill:GetType() == SkillType.Type602 then
                        local params = skill:GetParams() or {}
                        local addValue = params[1] or 0
                        if addValue > 0 then
                            adjPiece:AddValue(addValue)
                        end
                        break
                    end
                end
            end
        end
    end
end

---统一入口：棋子被删除前调用，执行 Type204/208/507/502/602
---@param ctx XLuckyTenant2OperationContext
---@param piece XLuckyTenant2Piece 即将被删除的棋子（删除前保存）
---@param baseValue number 棋子的基础金币（删除前保存）
---@param opts table|nil { x, y, fromPieceUid, skillId } 删除位置与来源，用于 507/502
function XLuckyTenant2OnDeleteEffects.ApplyOnDeleteEffects(ctx, piece, baseValue, opts)
    if not ctx or not piece then
        return
    end
    opts = opts or {}
    local model = ctx.model
    local game = ctx:GetGame()
    local pieceId = piece:GetId()
    -- 同一次删除内只算一次羁绊列表，避免 204/208/507/502 各算一遍
    local bondsList = (game and piece) and XLuckyTenant2BondSkills.GetBondsForPiece(piece, game) or {}

    ApplyType204(ctx, piece, pieceId, baseValue, model, game, bondsList)
    ApplyType208(ctx, piece, model, game, bondsList)

    local x, y = opts.x or 0, opts.y or 0
    local fromPieceUid = opts.fromPieceUid or 0
    local deleteSkillId = opts.skillId or 0

    local hasType507Triggered = ApplyType507(ctx, piece, x, y, fromPieceUid, model, game, bondsList)
    if not hasType507Triggered then
        ApplyType502(ctx, piece, x, y, deleteSkillId, model, game, bondsList)
    end

    -- 相邻红潮：被删棋子的相邻格上的红潮每有一个就触发一次 Type602（基础金币+N）
    ApplyType602(ctx, piece, model, game)
end

return XLuckyTenant2OnDeleteEffects
