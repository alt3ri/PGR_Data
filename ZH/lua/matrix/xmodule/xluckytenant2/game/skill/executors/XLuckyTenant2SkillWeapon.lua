local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local SkillUtils = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillUtils")
local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")
local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")

local ValidateSkillParams = SkillUtils.ValidateSkillParams
local PieceType = XLuckyTenant2Enum.PieceType
local TriggerState = XLuckyTenant2Enum.TriggerState
local GameConstants = XLuckyTenant2Enum.GameConstants

---武器技能子执行器
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器
local function Register(skillExecutor)
---技能类型401：武器被动01（被动）- 2个相同品质武器融合升品质
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type401, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 0) then
            return false
        end

        -- 检查棋子类型是否为武器
        if piece:GetPieceType() ~= PieceType.Weapon then
            return false
        end

        -- 判断武器等级是否满级
        local maxLevel = params[1] or GameConstants.MAX_PIECE_LEVEL
        if piece:GetLevel() >= maxLevel then
            return false
        end

        -- 检查是否已在本回合执行过
        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        -- 检查是否有Type403技能（可以融合武器碎片）
        local hasType403 = false
        local weaponFragmentIds = {}
        local resolveFn = context.game and context.game:GetResolveStateSkillIdFn()
        local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, resolveFn) or {}
        for _, s in ipairs(skills) do
            if s:GetType() == SkillType.Type403 then
                hasType403 = true
                local type403Params = s:GetParams() or {}
                for i = 1, #type403Params do
                    if type403Params[i] and type403Params[i] > 0 then
                        table.insert(weaponFragmentIds, type403Params[i])
                    end
                end
                break
            end
        end

        -- 获取相邻棋子
        local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
        local currentQuality = piece:GetQuality()

        -- 从感染状态判断：若当前感染状态关联的技能为Type408，可融合任意相邻武器
        local infectionState = piece:GetState(TriggerState.Infection)
        local isType408ByState = false
        local extraLevel = 0
        if infectionState and context.model then
            local stateSkillId = infectionState:GetSkillId()
            if stateSkillId then
                local skillId = skillExecutor:GetStateSkillId(stateSkillId)
                local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(skillId)
                if stateSkillConfig.Type == SkillType.Type408 then
                    isType408ByState = true
                    local stateParams = stateSkillConfig.Params or {}
                    extraLevel = stateParams[1] or 0
                end
            end
        end
        if isType408ByState then
            for _, adjPiece in ipairs(adjacentPieces) do
                if adjPiece and adjPiece:GetPieceType() == PieceType.Weapon and adjPiece:GetLevel() < maxLevel then
                    local adjValue = adjPiece:GetBaseValue() or 0
                    local adjLevel = adjPiece:GetLevel() or 0
                    local newLevel = (piece:GetLevel() or 0) + adjLevel + extraLevel
                    local newValue = (piece:GetBaseValue() or 0) + adjValue
                    local adjQuality = adjPiece:GetQuality()

                    -- 计算新品质
                    local newQuality = currentQuality
                    if adjQuality == currentQuality then
                        newQuality = newQuality + 1
                    else
                        newQuality = math.max(currentQuality, adjQuality)
                    end
                    if newQuality >= GameConstants.MAX_QUALITY then
                        newQuality = GameConstants.MAX_QUALITY
                    end

                    context.proxy:DeletePiece(adjPiece, piece)
                    context.proxy:ModifyPieceLevel(piece, newLevel - (piece:GetLevel() or 0))
                    context.proxy:ModifyPieceValue(piece, newValue - (piece:GetBaseValue() or 0))
                    context.proxy:ModifyPieceQuality(piece, newQuality - (piece:GetQuality() or 0))

                    return true
                end
            end
        end

        -- 优先检查是否可以融合武器碎片（Type403）
        if hasType403 and #weaponFragmentIds > 0 then
            for _, adjPiece in ipairs(adjacentPieces) do
                if adjPiece then
                    local adjPieceId = adjPiece:GetId()
                    for _, fragmentId in ipairs(weaponFragmentIds) do
                        if adjPieceId == fragmentId then
                            local adjQuality = adjPiece:GetQuality()
                            local adjLevel = adjPiece:GetLevel() or 0
                            local adjValue = adjPiece:GetBaseValue() or 0

                            local newQuality = math.max(currentQuality, adjQuality)
                            local newLevel = (piece:GetLevel() or 0) + adjLevel
                            local newValue = (piece:GetBaseValue() or 0) + adjValue

                            context.proxy:DeletePiece(adjPiece, piece)
                            context.proxy:ModifyPieceLevel(piece, newLevel - (piece:GetLevel() or 0))
                            context.proxy:ModifyPieceValue(piece, newValue - (piece:GetBaseValue() or 0))

                            return true
                        end
                    end
                end
            end
        end

        -- 检查是否可以融合同品质武器（Type401基础逻辑）
        for _, adjPiece in ipairs(adjacentPieces) do
            if adjPiece and adjPiece:GetPieceType() == PieceType.Weapon then
                local adjQuality = adjPiece:GetQuality()

                if adjQuality == currentQuality and adjPiece:GetLevel() < maxLevel then
                    local maxQuality = XLuckyTenant2Enum.Quality.Max
                    local newQuality = math.min(currentQuality + 1, maxQuality)
                    local newLevel = (piece:GetLevel() or 0) + (adjPiece:GetLevel() or 0)
                    local newValue = (piece:GetBaseValue() or 0) + (adjPiece:GetBaseValue() or 0)

                    if newQuality >= maxQuality and currentQuality < maxQuality then
                        newLevel = newLevel + 1
                    end

                    context.proxy:DeletePiece(adjPiece, piece)
                    context.proxy:ModifyPieceLevel(piece, newLevel - (piece:GetLevel() or 0))
                    context.proxy:ModifyPieceValue(piece, newValue - (piece:GetBaseValue() or 0))
                    context.proxy:ModifyPieceQuality(piece, newQuality - (piece:GetQuality() or 0))

                    return true
                end
            end
        end

        return false
    end)

    ---技能类型402：武器被动02（被动）- 等级关联金币
    ---使用 UpdateBondBaseDelta 按 skillKey 存储增益，与 Type103/105 等一致，避免覆盖其他技能对 value 的修改；RefreshBondLevels 时会 ResetBondValueDeltas 后重算。
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type402, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 2) then
            return false
        end

        if piece:GetPieceType() ~= PieceType.Weapon then
            return false
        end

        local quality = piece:GetQuality() or 0
        local valuePerLevel = params[quality - 1] or params[1] or 0
        local currentLevel = piece:GetLevel() or 0
        local delta = math.floor(currentLevel * valuePerLevel)

        local skillKey = "Type402_" .. tostring(skill:GetId())
        return SkillUtils.UpdateBondBaseDelta(piece, delta, skillKey)
    end)

    ---技能类型403：武器lv1（技能）- 武器融合武器碎片等级
    ---功能已集成到Type401中
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type403, function(skill, context)
        return true
    end)

    ---技能类型404：武器羁绊lv.2（技能）- 可被传染（标记技能）
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type404, function(skill, context)
        return true
    end)

    ---技能类型406： 已废弃
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type406, function(skill, context)
        return true
    end)

    ---技能类型405：武器羁绊lv.3（技能）- 相邻可升级棋子升级，自身升级
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type405, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 3) then
            return false
        end

        local maxLevel = XLuckyTenant2Piece.GetWeaponMaxLevel()
        if piece:GetLevel() >= maxLevel then
            return false
        end

        if piece:GetPieceType() ~= PieceType.Weapon then
            return false
        end

        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        local adjacentCount = params[1] or 0
        local targetLevelDelta = params[2] or 0
        local selfLevelDelta = params[3] or 0
        if adjacentCount <= 0 or targetLevelDelta <= 0 or selfLevelDelta <= 0 then
            return false
        end

        local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
        local affectedCount = 0
        for _, adjPiece in ipairs(adjacentPieces) do
            if adjPiece and adjPiece:CanUpgrade() and affectedCount < adjacentCount then
                context.proxy:ModifyPieceLevel(adjPiece, targetLevelDelta)
                affectedCount = affectedCount + 1
            end
        end

        if affectedCount > 0 then
            context.proxy:ModifyPieceLevel(piece, selfLevelDelta)
            return true
        end

        return false
    end)

    ---技能类型407：武器lv4（技能）- 概率清零相邻棋子倒计时，自身升级
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type407, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 2) then
            return false
        end

        local maxLevel = XLuckyTenant2Piece.GetWeaponMaxLevel()
        if piece:GetLevel() >= maxLevel then
            return false
        end

        if piece:GetPieceType() ~= PieceType.Weapon then
            return false
        end

        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        local triggerPercent = params[3] or 0
        if triggerPercent <= 0 or triggerPercent > 100 then
            return false
        end
        if math.random(1, 100) > triggerPercent then
            return false
        end

        local adjacentCount = params[1] or 1
        local levelDelta = params[2] or 0

        if adjacentCount <= 0 or levelDelta <= 0 then
            return false
        end

        local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
        local affectedCount = 0

        for _, adjPiece in ipairs(adjacentPieces) do
            if adjPiece and affectedCount < adjacentCount then
                local allStates = adjPiece:GetAllStates()
                local pieceAffected = false
                for _, state in ipairs(allStates) do
                    if state and state:GetRemainRounds() and state:GetRemainRounds() > 0 then
                        state:SetRemainRounds(0)
                        pieceAffected = true
                    end
                end
                if pieceAffected then
                    affectedCount = affectedCount + 1
                end
            end
        end

        if affectedCount > 0 then
            context.proxy:ModifyPieceLevel(piece, levelDelta)
            return true
        end

        return false
    end)

    ---技能类型408：武器状态技能（被传染）- 被传染帕弥什中，可融合任意相邻武器，且等级额外+N
    ---这是Type404激活后添加的状态技能
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type408, function(skill, context)
        -- Type408是状态技能，实际融合逻辑在Type401中处理
        -- 当武器有Type408感染状态时，Type401会检测并允许融合任意相邻武器
        -- 这里只返回true表示状态已应用
        return true
    end)
end

return { Register = Register }
