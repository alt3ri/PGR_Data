---状态应用器：统一「根据配置/来源羁绊生成并应用 state」的逻辑
---两处入口：1) 棋子配置（StateSkillId/TriggerState） 2) 来源怪物羁绊（Type203/205/207）
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local TriggerState = XLuckyTenant2Enum.TriggerState
local SkillType = XLuckyTenant2Enum.Skill
local PieceId = XLuckyTenant2Enum.PieceId

local XLuckyTenant2StateApplier = {}

-- ==================== 公用：按 skillType 解析/执行 ====================

---根据技能类型解析出「要应用的状态规格」（两边共用：210/508→死亡，208→感染）
---@param skillType number
---@param skillId number
---@param params number[]
---@return table|nil stateSpec 表 { stateType, skillId, rounds } 或 nil
function XLuckyTenant2StateApplier.GetStateSpecFromSkillType(skillType, skillId, params)
    params = params or {}
    if skillType == SkillType.Type210 then
        return { stateType = TriggerState.Death, skillId = skillId, rounds = params[2] or 2 }
    end
    if skillType == SkillType.Type508 then
        return { stateType = TriggerState.Death, skillId = skillId, rounds = params[1] or 2 }
    end
    if skillType == SkillType.Type208 then
        return { stateType = TriggerState.Infection, skillId = skillId, rounds = -1 }
    end
    -- Type301：角色被动倒计时，放置时自动挂上升级状态（params[1]=每N回合）
    if skillType == SkillType.Type301 then
        return { stateType = TriggerState.Upgrade, skillId = skillId, rounds = params[1] or 4 }
    end
    if skillType == SkillType.Type209 then
        return { stateType = TriggerState.Production, skillId = skillId, rounds = params[1] or 4 }
    end
    return nil
end

---Type203：给子虫应用基础金币/消除金币增益（两边共用，由 HandleSkillType 调用）
---@param piece XLuckyTenant2Piece
---@param pieceId number
---@param skillId number
---@param params number[]
function XLuckyTenant2StateApplier.ApplyType203ToPiece(piece, pieceId, skillId, params)
    params = params or {}
    local baseValueDelta = params[1] or 0
    local bugPieceId = params[2] or 0
    local deletionValueDelta = params[3] or 0
    if (baseValueDelta <= 0 and deletionValueDelta <= 0) or (bugPieceId ~= 0 and bugPieceId ~= pieceId) then
        return
    end
    local skillKey = "MonsterType203_" .. skillId
    if baseValueDelta > 0 then
        piece:SetBondValueDelta(skillKey, baseValueDelta)
    end
    if deletionValueDelta > 0 then
        piece:SetBondDeletionValueDelta(skillKey .. "_Delete", deletionValueDelta)
    end
end

---Type205：从 params 解析出「死亡回合数」（两边共用，由 HandleSkillType 调用）
---@param pieceId number
---@param params number[] params[1]=bugPieceId, params[2]=newDeathRounds
---@return number|nil 若命中子虫则返回回合数，否则 nil
function XLuckyTenant2StateApplier.GetDeathRoundsFromType205(pieceId, params)
    params = params or {}
    local bugPieceId = params[1] or 0
    local newDeathRounds = params[2] or 0
    if newDeathRounds < 0 or (bugPieceId ~= 0 and bugPieceId ~= pieceId) then
        return nil
    end
    return newDeathRounds
end

---在羁绊配置中查找 Type208 技能 ID（Type207 用，两边有 bondId 时共用）
---@param model XLuckyTenant2Model
---@param bondId number
---@return number|nil
function XLuckyTenant2StateApplier.FindType208SkillIdInBond(model, bondId)
    if not model or not bondId then
        return nil
    end
    local allBondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondId(bondId)
    for _, cfg in ipairs(allBondSkillConfigs or {}) do
        local sId = cfg.SkillId
        if type(sId) == "table" then
            sId = sId[1] or 0
        end
        if sId and sId > 0 then
            local sConfig = model:GetLuckyTenant2ChessSkillConfigById(sId)
            if sConfig and sConfig.Type == SkillType.Type208 then
                return sId
            end
        end
    end
    return nil
end

---统一按 skillType 处理单个技能（两边共用，所有类型都走这里）
---@param skillType number
---@param skillId number
---@param params number[]
---@param opts table { piece, pieceId, model, bondId? } bondId 为可选，Type207 需要
---@return table|nil result 表 { stateSpec = { stateType, skillId, rounds } } 或 { deathRounds = number } 或 nil
function XLuckyTenant2StateApplier.HandleSkillType(skillType, skillId, params, opts)
    opts = opts or {}
    local piece = opts.piece
    local pieceId = opts.pieceId or (piece and piece:GetId())
    local model = opts.model
    local bondId = opts.bondId
    params = params or {}

    -- Type203：基础/消除金币（两边都可能出现）
    if skillType == SkillType.Type203 then
        if piece and pieceId then
            XLuckyTenant2StateApplier.ApplyType203ToPiece(piece, pieceId, skillId, params)
        end
        return nil
    end

    -- Type205：死亡回合数（两边都可能出现）
    if skillType == SkillType.Type205 then
        local rounds = XLuckyTenant2StateApplier.GetDeathRoundsFromType205(pieceId or 0, params)
        if rounds ~= nil then
            return { deathRounds = rounds }
        end
        return nil
    end

    -- Type207：需在羁绊中找 Type208，再得到感染状态规格（有 bondId 时两边都可处理）
    if skillType == SkillType.Type207 then
        local bugPieceId = params[1] or 0
        if (bugPieceId ~= 0 and bugPieceId ~= pieceId) or not model or not bondId then
            return nil
        end
        local skill208Id = XLuckyTenant2StateApplier.FindType208SkillIdInBond(model, bondId)
        if skill208Id then
            local stateSpec = XLuckyTenant2StateApplier.GetStateSpecFromSkillType(SkillType.Type208, skill208Id, {})
            if stateSpec then
                return { stateSpec = stateSpec }
            end
        end
        return nil
    end

    -- Type208 / Type210 / Type508：直接得到状态规格（两边共用）
    local stateSpec = XLuckyTenant2StateApplier.GetStateSpecFromSkillType(skillType, skillId, params)
    if stateSpec then
        return { stateSpec = stateSpec }
    end
    return nil
end

-- ==================== 入口 1：棋子配置 ====================

---根据棋子配置应用状态技能
---@param game XLuckyTenant2Game
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
function XLuckyTenant2StateApplier.ApplyStateSkillsFromPieceConfig(game, piece, model)
    local pieceId = piece:GetId()
    if not pieceId or pieceId <= 0 then
        return
    end

    local config = model:GetLuckyTenant2ChessConfigById(pieceId)
    if not config then
        return
    end

    local stateSkillIds = config.StateSkillId or {}
    local se = game:GetSkillExecutor()

    for i = 1, #stateSkillIds do
        local stateSkillId = stateSkillIds[i]
        if not stateSkillId or stateSkillId <= 0 then
            goto continue
        end

        local actualSkillId, skillConfig = nil, nil
        if se then
            actualSkillId, skillConfig = se:ResolveStateSkillId(stateSkillId, model)
        end
        local finalSkillId = actualSkillId or stateSkillId
        if not skillConfig then
            goto continue
        end

        local skillType = skillConfig.Type or 0
        local skillParams = skillConfig.Params or {}

        local result = XLuckyTenant2StateApplier.HandleSkillType(skillType, finalSkillId, skillParams, {
            piece = piece, pieceId = pieceId, model = model,
        })
        if result and result.stateSpec then
            local spec = result.stateSpec
            -- 死亡状态不覆盖已有的
            if not (spec.stateType == TriggerState.Death and piece:HasState(TriggerState.Death)) then
                game:ApplyStateToPiece(piece, spec.stateType, spec.skillId, spec.rounds, model, nil, {})
            end
        end
        if result and result.deathRounds ~= nil and piece:HasState(TriggerState.Death) then
            local state = piece:GetState(TriggerState.Death)
            if state then
                state:SetRemainRounds(result.deathRounds)
            end
        end

        ::continue::
    end
end

---根据来源怪物羁绊应用状态与数值（原 AddNewPiece 中 Type203/205/207 + 最终死亡状态）
---@param ctx XLuckyTenant2OperationContext
---@param piece XLuckyTenant2Piece 新加的子虫棋子
---@param pieceId number 棋子配置ID
---@param fromPieceUid number 来源怪物 UID
---@param initialDeathSkillId number|nil 初始死亡技能ID（由 Operation 创建时传入）
---@param initialDeathRounds number|nil 初始死亡回合数
function XLuckyTenant2StateApplier.ApplyStateSkillsFromSourceBond(ctx, piece, pieceId, fromPieceUid, initialDeathSkillId, initialDeathRounds)
    local finalDeathSkillId = initialDeathSkillId
    local finalDeathRounds = initialDeathRounds or 0

    if not fromPieceUid or fromPieceUid <= 0 then
        if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
            ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
        end
        return
    end

    local fromPiece = ctx:FindPieceByUid(fromPieceUid)
    if not fromPiece then
        if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
            ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
        end
        return
    end

    local model = ctx.model
    local bondIdStr = fromPiece:GetBondId()

    if not bondIdStr or bondIdStr == "" then
        if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
            ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
        end
        return
    end

    local bondManager = ctx:GetGame():GetBondManager()
    if not bondManager then
        if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
            ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
        end
        return
    end

    for oneBondStr in string.gmatch(bondIdStr, "([^|]+)") do
        local bondId = tonumber(oneBondStr)
        if not bondId then
            goto continue
        end
        local bond = bondManager:GetBond(bondId)
        if not bond then
            goto continue
        end
        local bondLevel = bond:GetLevel()
        -- 移除 bondLevel <= 0 的提前跳过，允许 Level=0 的技能在羁绊等级=0时生效
        -- 后续通过 bondLevel >= configLevel 判断来决定是否处理技能

        local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
        for _, bondSkillConfig in ipairs(bondSkillConfigs) do
            local configLevel = bondSkillConfig.Level or 0
            if bondLevel < configLevel then
                goto next_config
            end
            local skillId = bondSkillConfig.SkillId
            if type(skillId) == "table" then
                skillId = skillId[1] or 0
            end
            if not skillId or skillId <= 0 then
                goto next_config
            end

            local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
            if not skillConfig then
                goto next_config
            end
            local skillType = skillConfig.Type
            local params = skillConfig.Params or {}

            -- 两边共用：所有 skillType 都走 HandleSkillType（来源羁绊有 bondId）
            local result = XLuckyTenant2StateApplier.HandleSkillType(skillType, skillId, params, {
                piece = piece,
                pieceId = pieceId,
                model = model,
                bondId = bondId,
            })
            if result then
                if result.deathRounds ~= nil then
                    finalDeathRounds = result.deathRounds
                end
                if result.stateSpec then
                    local stateSpec = result.stateSpec
                    ctx:ApplyStateToPiece(piece, stateSpec.stateType, stateSpec.skillId, stateSpec.rounds, {})
                end
            end

            ::next_config::
        end
        ::continue::
    end

    if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
        ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
    end
end

return XLuckyTenant2StateApplier
