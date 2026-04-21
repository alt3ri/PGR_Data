local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local SkillUtils = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillUtils")
local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")
local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")

local IsPropPieceId = SkillUtils.IsPropPieceId
local ValidateSkillParams = SkillUtils.ValidateSkillParams
local TriggerState = XLuckyTenant2Enum.TriggerState

---角色技能子执行器
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器
local function Register(skillExecutor)
---技能类型301：倒计时（被动）- 每N回合等级+M
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type301, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    local rounds = params[1] or 0
    local levelDelta = params[2] or 0
    local maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()

    if rounds <= 0 or levelDelta <= 0 then
        return false
    end

    local currentLevel = piece:GetLevel() or 0
    if currentLevel >= maxLevel then
        return false
    end

    local actualRounds = rounds
    local resolveStateSkillId = context.game and context.game:GetResolveStateSkillIdFn()
    local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, resolveStateSkillId) or {}
    for _, otherSkill in ipairs(skills) do
        if otherSkill:GetType() == SkillType.Type303 then
            local reduceRounds = otherSkill:GetParams()[1] or 0
            if reduceRounds > 0 then
                actualRounds = math.max(1, rounds - reduceRounds)
            end
        end
    end

    if context.isExpiredStateSkill then
        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        local alreadyExecuted = context.proxy:MarkRoundSkillExecuted(markKey)

        if alreadyExecuted then
            return false
        end

        local actualDelta = math.min(levelDelta, maxLevel - currentLevel)
        if actualDelta > 0 then
            context.proxy:ModifyPieceLevel(piece, actualDelta)
        end

        local newLevel = (currentLevel + (actualDelta or 0))
        if newLevel < maxLevel then
            context.proxy:ApplyState(piece, TriggerState.Upgrade, skill:GetId(), actualRounds)
        end
        return actualDelta > 0
    end

    local upgradeState = piece:GetState(TriggerState.Upgrade)
    local isCountdownZero = upgradeState and upgradeState:GetRemainRounds() <= 0

    if not upgradeState then
        context.proxy:ApplyState(piece, TriggerState.Upgrade, skill:GetId(), actualRounds)
        return true
    elseif isCountdownZero then
        piece:RemoveState(TriggerState.Upgrade)

        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        local actualDelta = math.min(levelDelta, maxLevel - currentLevel)
        if actualDelta > 0 then
            context.proxy:ModifyPieceLevel(piece, actualDelta)
        end

        local newLevel = (currentLevel + (actualDelta or 0))
        if newLevel < maxLevel then
            context.proxy:ApplyState(piece, TriggerState.Upgrade, skill:GetId(), actualRounds)
        end
        return actualDelta > 0
    end

    return false
end)

---技能类型303：倒计时（技能）- 角色升级倒计时减少（被动效果）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type303, function(skill, context)
    return false
end)

---技能类型304：消除（技能）- 可发动消除（配合305和306）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type304, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    if not ValidateSkillParams(piece, params, 3) then
        return false
    end

    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false
    end

    local resolveStateSkillId = context.game and context.game:GetResolveStateSkillIdFn()
    local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, resolveStateSkillId) or {}
    local hasSkill305 = false
    local hasSkill306 = false
    local skill305Params = nil
    local skill305Id = nil -- 305 技能配置 ID，鞭尸动画需传此值以正确播放特效
    local skill306Params = nil

    for _, s in ipairs(skills) do
        local st = s:GetType()
        if st == SkillType.Type305 then
            hasSkill305 = true
            skill305Params = s:GetParams()
            skill305Id = s:GetId()
        elseif st == SkillType.Type306 then
            hasSkill306 = true
            skill306Params = s:GetParams()
        end
    end

    -- 304基础消除数量（可被305增强）
    local eliminateCount = 0
    if hasSkill305 and skill305Params and #skill305Params >= 1 then
        if skill305Params[2] then
            eliminateCount = 1 + skill305Params[2]
        else
            eliminateCount = 1
        end
    else
        eliminateCount = params[1] or 1
    end

    -- 306额外同行列消除数量（条件满足时追加）
    local extraEliminateCount = 0
    if hasSkill306 and skill306Params and #skill306Params >= 1 then
        local currentLevel = piece:GetLevel() or 0
        local divisor = skill306Params[1] or 1
        if currentLevel % divisor == 0 then
            extraEliminateCount = skill306Params[2] or 0
        end
    end

    -- 304默认：相邻范围消除
    local candidatePieces = context.proxy:GetAdjacentPieces(piece)

    -- 306生效时：追加同行列范围的候选棋子
    if extraEliminateCount > 0 then
        local sameRowColPieces = context.board:GetSameRowColPieces(piece)
        -- 去重：排除已在相邻列表中的棋子
        local adjacentUidSet = {}
        for _, p in ipairs(candidatePieces) do
            adjacentUidSet[p:GetUid()] = true
        end
        for _, p in ipairs(sameRowColPieces) do
            if not adjacentUidSet[p:GetUid()] then
                table.insert(candidatePieces, p)
            end
        end
        eliminateCount = eliminateCount + extraEliminateCount
    end

    local eliminatablePieces = {}

    for _, targetPiece in ipairs(candidatePieces) do
        local tPieceId = targetPiece and targetPiece:GetId()
        if tPieceId and tPieceId > 0 and not IsPropPieceId(tPieceId) then
            local canBeEliminated = context.model:GetLuckyTenant2ChessCanBeEliminatedById(tPieceId)
            if canBeEliminated then
                table.insert(eliminatablePieces, targetPiece)
            end
        end
    end

    if #eliminatablePieces == 0 then
        return false
    end

    local eliminatedPieces = {}
    local countToEliminate = math.min(eliminateCount, #eliminatablePieces)

    for i = 1, countToEliminate do
        if #eliminatablePieces > 0 then
            local randomIndex = math.random(1, #eliminatablePieces)
            local selectedPiece = eliminatablePieces[randomIndex]
            table.insert(eliminatedPieces, selectedPiece)
            table.remove(eliminatablePieces, randomIndex)
        end
    end

    if #eliminatedPieces == 0 then
        return false
    end

    -- 第一次消除：正常DeletePiece（触发得分+删除动画）
    for _, targetPiece in ipairs(eliminatedPieces) do
        if hasSkill305 and skill305Params and #skill305Params >= 2 and (skill305Params[2] or 0) > 0 and skill305Id and skill305Id > 0 then
            context.proxy:DeletePiece(targetPiece, piece, {
                roleWhipCount = skill305Params[2] or 0,
                roleWhipSkillId = skill305Id,
            })
        else
            context.proxy:DeletePiece(targetPiece, piece)
        end
    end

    -- 305鞭尸：额外再次消除，每次独立触发得分飘字和消除动画
    if hasSkill305 and skill305Params and #skill305Params >= 2 then
        local whipCount = skill305Params[2] or 1
        for j = 1, whipCount do
            for _, targetPiece in ipairs(eliminatedPieces) do
                local baseValue = targetPiece:GetBaseValue() or 0
                local deletionValue = targetPiece.GetValueUponDeletion and targetPiece:GetValueUponDeletion() or 0
                local score = baseValue + deletionValue
                if score > 0 then
                    context.proxy:AddScore(score, targetPiece)
                end
            end
        end
    end

    local eliminateForLevel = params[2] or 1
    local levelDelta = params[3] or 1
    local successCount = #eliminatedPieces

    if successCount >= eliminateForLevel then
        local levelIncrease = math.floor(successCount / eliminateForLevel) * levelDelta
        if levelIncrease > 0 then
            local cl = piece:GetLevel() or 0
            local maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()
            local actualIncrease = math.min(levelIncrease, maxLevel - cl)
            if actualIncrease > 0 then
                context.proxy:ModifyPieceLevel(piece, actualIncrease)
            end
        end
    end

    return true
end)

---技能类型302：每N等级金币+M（被动）
---使用 UpdateBondBaseDelta 按 skillKey 存储增益，与 Type402 一致，避免覆盖其他技能对 value 的修改；RefreshBondLevels 时会 ResetBondValueDeltas 后重算。
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type302, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    local quality = piece:GetQuality() or 0
    if quality <= 0 then
        return false
    end

    local valuePerLevel = params[quality - 1] or params[1] or 0
    local currentLevel = piece:GetLevel() or 0
    local delta = math.floor(currentLevel * valuePerLevel)

    local skillKey = "Type302_" .. tostring(skill:GetId())
    return SkillUtils.UpdateBondBaseDelta(piece, delta, skillKey)
end)

---技能类型305：消除（技能）- 鞭尸增强（配合304）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type305, function(skill, context)
    return false
end)

---技能类型306：消除（技能）- 范围扩大增强（配合304）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type306, function(skill, context)
    return false
end)
end

return { Register = Register }
