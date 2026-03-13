---状态应用器：统一「根据配置/来源羁绊生成并应用 state」的逻辑
---两处入口：1) 棋子配置（StateSkillId/TriggerState） 2) 来源怪物羁绊（Type203/205/207）
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local TriggerState = XLuckyTenant2Enum.TriggerState
local SkillType = XLuckyTenant2Enum.Skill
local PieceId = XLuckyTenant2Enum.PieceId or { Subworm = 2 }
local PieceId = XLuckyTenant2Enum.PieceId or { Subworm = 2 }

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
    if XMVCA.XLuckyTenant2 then
        XMVCA.XLuckyTenant2:Print(string.format("[StateApplier-Type203] 子虫ID=%d 技能=%d baseDelta=%d delDelta=%d", pieceId, skillId, baseValueDelta, deletionValueDelta))
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

---根据棋子配置应用状态技能（原 _ApplyStateSkills 的完整逻辑）
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

    local triggerStates = config.TriggerState or {}
    local stateConditionIds = config.StateConditionId or {}
    local stateSkillIds = config.StateSkillId or {}

    local context = {
        piece = piece,
        board = game._ChessBoard,
        bag = game._Bag,
        game = game,
        model = model,
    }

    local XLuckyTenant2Condition = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Condition")
    local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")

    -- 处理有 TriggerState 的状态技能（只更新已有状态的技能ID）
    local maxLen = math.max(#triggerStates, math.max(#stateConditionIds, #stateSkillIds))
    for i = 1, maxLen do
        local configTriggerState = triggerStates[i]
        if configTriggerState and configTriggerState > 0 then
            if piece:HasState(configTriggerState) then
                local stateConditionId = stateConditionIds[i]
                local stateSkillId = stateSkillIds[i]
                if stateSkillId and stateSkillId > 0 then
                    local actualSkillId = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
                    local finalSkillId = actualSkillId or stateSkillId
                    local shouldApply = true
                    if stateConditionId and stateConditionId > 0 then
                        shouldApply = XLuckyTenant2Condition.EvaluateById(model, stateConditionId, context)
                    end
                    if shouldApply then
                        local state = piece:GetState(configTriggerState)
                        if state then
                            state:SetSkillId(finalSkillId)
                        end
                    end
                end
            end
        end
    end

    -- 处理无 TriggerState 但配置了 StateSkillId 的情况（自动创建状态，如 202/209/508）
    for i = 1, #stateSkillIds do
        local stateSkillId = stateSkillIds[i]
        if stateSkillId and stateSkillId > 0 then
            local hasTriggerStateConfig = (i <= #triggerStates and triggerStates[i] and triggerStates[i] > 0)
            if not hasTriggerStateConfig then
                local actualSkillId, skillConfig = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
                if actualSkillId and actualSkillId ~= stateSkillId then
                    -- XLog.Warning(string.format("[StateApplier] 配置表 StateSkillId 类型%d 已转换为技能ID %d，棋子ID: %d",
                    --     stateSkillId, actualSkillId, pieceId))
                end
                if not skillConfig then
                    XLog.Warning(string.format("[StateApplier] 技能ID %d 不存在，棋子ID: %d", stateSkillId, pieceId))
                end
                if skillConfig then
                    local skillType = skillConfig.Type or 0
                    local skillParams = skillConfig.Params or {}
                    local finalSkillId = actualSkillId or stateSkillId
                    -- 两边共用：所有 skillType 都走 HandleSkillType（棋子配置无 bondId，Type207 会 no-op）
                    local result = XLuckyTenant2StateApplier.HandleSkillType(skillType, finalSkillId, skillParams, { piece = piece, pieceId = pieceId, model = model })
                    if result and result.stateSpec then
                        local stateSpec = result.stateSpec
                        -- 死亡状态：仅当尚未有时创建，避免覆盖
                        if stateSpec.stateType == TriggerState.Death then
                            if not piece:HasState(TriggerState.Death) then
                                local stateConditionId = (i <= #stateConditionIds) and stateConditionIds[i] or nil
                                local applied = game:ApplyStateToPiece(piece, stateSpec.stateType, stateSpec.skillId, stateSpec.rounds, model, context, { conditionId = stateConditionId })
                                if applied and XMVCA.XLuckyTenant2 then
                                    XMVCA.XLuckyTenant2:Print("[StateApplier] 从棋子配置创建状态，棋子ID:", pieceId, "状态类型:", stateSpec.stateType, "技能ID:", stateSpec.skillId, "回合数:", stateSpec.rounds)
                                end
                            elseif pieceId == PieceId.Subworm and XMVCA.XLuckyTenant2 then
                                local existingState = piece:GetState(TriggerState.Death)
                                local existingRounds = existingState and existingState:GetRemainRounds() or -1
                                local x, y = piece:GetPosition()
                                local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
                                XMVCA.XLuckyTenant2:Print(string.format("[StateApplier] 子虫[ID:%d] %s 已有死亡状态，剩余回合数=%d", pieceId, posStr, existingRounds))
                            end
                        else
                            -- 感染等其它状态：直接应用
                            game:ApplyStateToPiece(piece, stateSpec.stateType, stateSpec.skillId, stateSpec.rounds, model, context, {})
                            if XMVCA.XLuckyTenant2 then
                                XMVCA.XLuckyTenant2:Print("[StateApplier] 从棋子配置创建状态，棋子ID:", pieceId, "状态类型:", stateSpec.stateType, "技能ID:", stateSpec.skillId)
                            end
                        end
                    end
                    if result and result.deathRounds ~= nil and piece:HasState(TriggerState.Death) then
                        local state = piece:GetState(TriggerState.Death)
                        if state then
                            state:SetRemainRounds(result.deathRounds)
                        end
                    end
                end
            end
        end
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
            if XMVCA.XLuckyTenant2 then
                local x, y = piece:GetPosition()
                local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
                XMVCA.XLuckyTenant2:Print(string.format("[StateApplier] 给子虫添加死亡状态: 棋子ID=%d, %s, 技能ID=%d, 回合数=%d", pieceId, posStr, finalDeathSkillId, finalDeathRounds))
            end
        end
        return
    end

    local fromPiece = ctx:FindPieceByUid(fromPieceUid)
    if XMVCA.XLuckyTenant2 then
        XMVCA.XLuckyTenant2:Print(string.format("[StateApplier] 来源怪物 FromPieceUid=%d, fromPiece=%s", fromPieceUid, fromPiece and "存在" or "nil"))
    end
    if not fromPiece then
        if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
            ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
        end
        return
    end

    local model = ctx.model
    local bondIdStr = fromPiece:GetBondId()
    if XMVCA.XLuckyTenant2 then
        XMVCA.XLuckyTenant2:Print(string.format("[StateApplier] 怪物羁绊 BondId=%s, 子虫ID=%d", bondIdStr or "无", pieceId))
    end

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
        if bondLevel <= 0 then
            goto continue
        end

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
                    if XMVCA.XLuckyTenant2 then
                        XMVCA.XLuckyTenant2:Print("[StateApplier] Type205: 子虫死亡回合数=", result.deathRounds)
                    end
                end
                if result.stateSpec then
                    local stateSpec = result.stateSpec
                    ctx:ApplyStateToPiece(piece, stateSpec.stateType, stateSpec.skillId, stateSpec.rounds, {})
                    if XMVCA.XLuckyTenant2 then
                        XMVCA.XLuckyTenant2:Print("[StateApplier] 来源羁绊应用状态，类型:", stateSpec.stateType, "技能ID:", stateSpec.skillId)
                    end
                end
            end

            ::next_config::
        end
        ::continue::
    end

    if finalDeathSkillId and finalDeathRounds and finalDeathRounds > 0 then
        ctx:ApplyStateToPiece(piece, TriggerState.Death, finalDeathSkillId, finalDeathRounds, {})
        if XMVCA.XLuckyTenant2 then
            local x, y = piece:GetPosition()
            local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
            XMVCA.XLuckyTenant2:Print(string.format("[StateApplier] 给子虫添加死亡状态: 棋子ID=%d, %s, 技能ID=%d, 回合数=%d", pieceId, posStr, finalDeathSkillId, finalDeathRounds))
        end
    end
end

return XLuckyTenant2StateApplier
