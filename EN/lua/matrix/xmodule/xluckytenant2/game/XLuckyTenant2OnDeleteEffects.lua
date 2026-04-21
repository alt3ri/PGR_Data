---删除时触发逻辑：Type204/208/507/502 等「棋子被删除时」的效果统一在此处理
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local PieceType = XLuckyTenant2Enum.PieceType
local PieceId = XLuckyTenant2Enum.PieceId or { Coin = 1, Subworm = 2, WeaponFragmentLv4 = 3, WeaponFragmentLv6 = 4 }
local SkillType = XLuckyTenant2Enum.Skill
local TriggerState = XLuckyTenant2Enum.TriggerState
local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")
local XLuckyTenant2SkillBox = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillBox")

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
    local sourcePiece = context.piece or piece
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
                context.proxy:ApplyState(adjPiece, TriggerState.Infection, targetStateSkillId, -1, sourcePiece)
                infectedCount = infectedCount + 1
                if scoreDelta > 0 then
                    context.proxy:AddScore(scoreDelta, piece, piece)
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
        local bugPieceId = XLuckyTenant2Enum.PieceId.Subworm
        local multiplier = params[1] or 0
        if (bugPieceId ~= 0 and bugPieceId ~= pieceId) or multiplier <= 0 then
            return
        end
        local extraScore = baseValue * multiplier
        if extraScore > 0 then
            ctx:AddScoreThisRound(extraScore, piece)
        end
    end, bondsListCached)
end

---从棋子配置 StateSkillId 中按类型查找第一个技能（用于 bondId 为空的棋子）
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param skillType number
---@param game XLuckyTenant2Game|nil 用于获取 ResolveStateSkillId
---@return number|nil skillId, table|nil skillConfig
local function FindSkillInPieceConfigByType(piece, model, skillType, game)
    if not piece or not model or not skillType or not game then
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
    local se = game:GetSkillExecutor()
    local raw = config.StateSkillId
    local stateSkillIds = (type(raw) == "number" and raw > 0) and { raw } or (raw or {})
    for i = 1, #stateSkillIds do
        local stateSkillId = stateSkillIds[i]
        if stateSkillId and stateSkillId > 0 and se then
            local actualSkillId, cfg = se:ResolveStateSkillId(stateSkillId, model)
            if cfg and cfg.Type == skillType then
                return actualSkillId or stateSkillId, cfg
            end
        end
    end
    return nil, nil
end

---根据技能配置构造供共享函数使用的技能对象（提供 GetParams/GetId 接口）
local function BuildSkillFromConfig(skillId, skillConfig)
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

    -- 子虫：优先从运行时感染状态查找 Type208，其次从配置 StateSkillId 查找
    if pieceId == PieceId.Subworm and (not bondIdStr or bondIdStr == "") then
        -- 1. 优先检查运行时感染状态（由207技能挂上）
        if piece:HasState(TriggerState.Infection) then
            local infectionState = piece:GetState(TriggerState.Infection)
            if infectionState then
                local stateSkillId = infectionState:GetSkillId()
                if stateSkillId and stateSkillId > 0 then
                    skillConfig = model:GetLuckyTenant2ChessSkillConfigById(stateSkillId)
                    if skillConfig and skillConfig.Type == SkillType.Type208 then
                        skillId = stateSkillId
                    end
                end
            end
        end

        -- 2. 如果没有找到，再从配置表 StateSkillId 查找
        if not skillId then
            local se = game:GetSkillExecutor()
            local config = model:GetLuckyTenant2ChessConfigById(pieceId)
            if config and se then
                local raw = config.StateSkillId
                local stateSkillIds = (type(raw) == "number" and raw > 0) and { raw } or (raw or {})
                for i = 1, #stateSkillIds do
                    local stateSkillId = stateSkillIds[i]
                    if stateSkillId and stateSkillId > 0 then
                        local actualSkillId, cfg = se:ResolveStateSkillId(stateSkillId, model)
                        if cfg and cfg.Type == SkillType.Type208 then
                            skillId = actualSkillId or stateSkillId
                            skillConfig = cfg
                            break
                        end
                    end
                end
            end
        end
    elseif bondIdStr and bondIdStr ~= "" then
        -- 有 BondId：从所属 bond 取 Type208；无 BondId 且非子虫（如 PieceId.Coin、PieceId.WeaponFragmentLv4/WeaponFragmentLv6）不查 bond，避免误用其他羁绊的 Type208
        skillId, skillConfig, bondId = XLuckyTenant2BondSkills.FindSkillInBondsForPiece(piece, model, game, SkillType.Type208, nil, bondsListCached)
    end

    if skillId and skillConfig then
        local skill = BuildSkillFromConfig(skillId, skillConfig)
        local context = { piece = piece, proxy = ctx.proxy, model = model }
        XLuckyTenant2OnDeleteEffects.DoType208InfectAdjacent(piece, skill, context)
    end
end

---从羁绊或棋子配置中查找指定类型的技能（宝盒通用）
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
---@param skillType number 目标技能类型（如 SkillType.Type507 / SkillType.Type502）
---@param bondsListCached table|nil 可选，同一次删除内复用避免重复计算
---@return number|nil skillId, table|nil skillConfig
local function FindBoxSkillByType(piece, model, game, skillType, bondsListCached)
    local bondIdStr = piece:GetBondId() or ""
    if bondIdStr ~= "" then
        return XLuckyTenant2BondSkills.FindSkillInBondsForPiece(
            piece, model, game, skillType, nil, bondsListCached)
    else
        return FindSkillInPieceConfigByType(piece, model, skillType, game)
    end
end

---宝盒被消除后的专用处理（507/502/508 一整套逻辑）
---@param ctx XLuckyTenant2OperationContext
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param game XLuckyTenant2Game
---@param bondsList table
---@param opts table { x, y, skillId }
---@return XLuckyTenant2Piece 处理后的棋子（可能被替换）
local function HandleBoxOnDelete(ctx, piece, model, game, bondsList, opts)
    local x, y = opts.x or 0, opts.y or 0
    local deleteSkillId = opts.skillId or 0

    if piece:GetPieceType() ~= PieceType.Box or x <= 0 or y <= 0 then
        return piece
    end

    -- 构造 SkillBox 函数所需的技能上下文
    local skillContext = {
        model = model,
        game = game,
        proxy = ctx.proxy,
        piece = piece,
    }

    -- 查找 Type507 技能（从羁绊或棋子配置）
    local type507SkillId, type507Config = FindBoxSkillByType(piece, model, game, SkillType.Type507, bondsList)
    local hasType507Triggered = false
    if type507Config then
        local mockSkill507 = BuildSkillFromConfig(type507SkillId, type507Config)
        piece, hasType507Triggered = XLuckyTenant2SkillBox.ExecuteType507OnBoxDelete(
            mockSkill507, piece, x, y, skillContext)
    end

    -- 查找 Type502 技能（从羁绊或棋子配置），仅在 Type507 未触发时执行
    -- 通过 model 将 deleteSkillId 解析为技能类型，避免 id 与 type 混淆
    local hasType502 = false
    local deleteSkillType = 0
    if deleteSkillId > 0 and model then
        local deleteSkillConfig = model:GetLuckyTenant2ChessSkillConfigById(deleteSkillId)
        if deleteSkillConfig then
            deleteSkillType = deleteSkillConfig.Type or 0
        end
    end
    if not hasType507Triggered and deleteSkillType ~= SkillType.Type502 then
        local type502SkillId, type502Config = FindBoxSkillByType(piece, model, game, SkillType.Type502, bondsList)
        if type502Config then
            hasType502 = true
            local mockSkill502 = BuildSkillFromConfig(type502SkillId, type502Config)
            local rebornPieceId = piece:GetId()
            piece = XLuckyTenant2SkillBox.ExecuteType502Reborn(
                mockSkill502, piece, rebornPieceId, x, y, 0, nil, skillContext)
        end
    end

    -- 更新代理引用（Type502 或 Type507 可能替换了棋子）
    if hasType502 or hasType507Triggered then
        skillContext.proxy.Piece = piece
    end

    -- 步骤2c：在相邻空位产出棋子
    -- Type508 为状态技能，其技能配置来源于棋子配置的 StateSkillId 字段（通过 SkillExecutor 解析）
    local amount = 0
    local noEmptyGold = 0
    if model and game and piece then
        local pieceId = piece:GetId()
        if pieceId and pieceId > 0 then
            local config = model:GetLuckyTenant2ChessConfigById(pieceId)
            if config then
                local stateSkillIds = config.StateSkillId or {}
                local se = game:GetSkillExecutor()
                for i = 1, #stateSkillIds do
                    local stateSkillId = stateSkillIds[i]
                    if stateSkillId and stateSkillId > 0 and se then
                        local actualSkillId, skillConfig = se:ResolveStateSkillId(stateSkillId, model)
                        if skillConfig and skillConfig.Type == SkillType.Type508 then
                            local params = skillConfig.Params or {}
                            amount = params[2] or 1
                            noEmptyGold = params[3] or 0
                            break
                        end
                    end
                end
            end
        end
    end

    if amount > 0 then
        local se = game:GetSkillExecutor()
        XLuckyTenant2SkillBox.SpawnAdjacentPieces(
            piece, amount, noEmptyGold, skillContext, se, hasType502, hasType507Triggered, true)
    end

    return piece
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
            local resolveFn = game:GetResolveStateSkillIdFn()
            local skills = XLuckyTenant2BondSkills.GetSkillsFromBonds(adjPiece, model, game, nil, resolveFn)
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

---统一入口：棋子被删除前调用，执行默认消除得分 + Type204/208/507/502/602
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

    -- 默认消除得分：基础金币 + 消除分数
    local deletionValue = piece.GetValueUponDeletion and piece:GetValueUponDeletion() or 0
    local defaultScore = (baseValue or 0) + deletionValue
    if defaultScore > 0 then
        ctx:AddScoreThisRound(defaultScore, piece)
    end

    -- 同一次删除内只算一次羁绊列表，避免 204/208/507/502 各算一遍
    local bondsList = (game and piece) and XLuckyTenant2BondSkills.GetBondsForPiece(piece, game) or {}

    ApplyType204(ctx, piece, pieceId, baseValue, model, game, bondsList)
    ApplyType208(ctx, piece, model, game, bondsList)

    ----------------------------------------------------------------------
    -- 宝盒被消除后的处理流程（与 XLuckyTenant2SkillBox Type508 共用逻辑）：
    --   1. Type507 优先：若有 Type507 技能
    --      - 品质未满 → 产生品质+1 的新宝盒替换原宝盒
    --      - 橙色品质 → 增加基础金币
    --   2. Type502 重生：若有 Type502 且 Type507 未触发
    --      - 根据概率决定新品质（原品质 / 品质+1）
    --      - 替换为新品质宝盒，继承感染状态
    --      - 倒计时由下一回合 Type508 自然施加
    --   3. 步骤2c：在相邻空位产出棋子（与 Type508 共用 SpawnAdjacentPieces）
    ----------------------------------------------------------------------

    piece = HandleBoxOnDelete(ctx, piece, model, game, bondsList, opts)

    -- 相邻红潮：被删棋子的相邻格上的红潮每有一个就触发一次 Type602（基础金币+N）
    ApplyType602(ctx, piece, model, game)
end

return XLuckyTenant2OnDeleteEffects
