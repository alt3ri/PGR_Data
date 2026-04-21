local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local SkillUtils = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillUtils")

local ValidateSkillParams = SkillUtils.ValidateSkillParams
local UpdateBondBaseDelta = SkillUtils.UpdateBondBaseDelta
local UpdateBondDeletionDelta = SkillUtils.UpdateBondDeletionDelta
local TriggerState = XLuckyTenant2Enum.TriggerState

---金融技能子执行器
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器
local function Register(skillExecutor)
---技能类型101：金融被动01 - 可被传染，被传染后每N回合产生金币
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type101, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    local skillId = skill:GetId()

    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查棋子是否被感染（只有被感染时才产生金币）
    local hasInfection = piece:HasState(TriggerState.Infection)
    if not hasInfection then
        return false
    end

    local rounds = params[1] or 0  -- 每N回合
    local pieceId = params[2] or 0 -- 产生的金币棋子ID
    local amount = params[3] or 1  -- 产生的数量

    if rounds <= 0 or pieceId <= 0 then
        return false
    end

    -- 判断是否由过期状态触发（Production倒计时到期）
    if context.isExpiredStateSkill then
        -- 过期触发：执行生产逻辑并重置倒计时
    else
        -- 正常技能循环：检查Production状态
        local productionState = piece:GetState(TriggerState.Production)
        -- 检查是否被外部清零（如Type407）
        local isCountdownZero = productionState and productionState:GetRemainRounds() <= 0

        if not productionState then
            context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        elseif isCountdownZero then
            -- 倒计时被清零，移除旧状态后走生产逻辑
            piece:RemoveState(TriggerState.Production)
        else
            return false
        end

        if not isCountdownZero then
            return false
        end
    end

    -- 倒计时到期，执行生产逻辑
    local pieceUid = piece:GetUid()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false
    end

    -- 获取相邻空位
    local emptyPositions = context.proxy:GetAdjacentEmptyPositions()
    if #emptyPositions == 0 then
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false
    end

    -- 在相邻空位产生金币棋子
    local created = 0
    for i = 1, math.min(amount, #emptyPositions) do
        local pos = emptyPositions[i]
        context.proxy:AddNewPiece(pieceId, pos[1], pos[2])
        created = created + 1
    end

    -- 重置倒计时
    context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)

    return created > 0
end)

---技能类型102：金融状态技能（被传染）- 状态标记，不执行逻辑
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type102, function(skill, context)
    -- Type102是状态技能，主要通过Type101来实现产生金币的功能
    return false
end)

---技能类型103：金融羁绊lv.1 - 基础金币额外+N；被消除金币+N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type103, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    local hasChanged = false
    local skillKey = skill:GetId()
    local baseValueAdd = params[1] or 0
    if baseValueAdd > 0 then
        if UpdateBondBaseDelta(piece, baseValueAdd, skillKey) then
            hasChanged = true
        end
    else
        UpdateBondBaseDelta(piece, 0, skillKey)
    end

    local deleteValueAdd = params[2] or 0
    if deleteValueAdd > 0 then
        if UpdateBondDeletionDelta(piece, deleteValueAdd, skillKey .. "_Delete") then
            hasChanged = true
        end
    else
        UpdateBondDeletionDelta(piece, 0, skillKey .. "_Delete")
    end

    return hasChanged
end)

---技能类型105：金融羁绊lv.3 - 基础金币+N，被消除金币*倍数
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type105, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    local hasChanged = false
    local skillKey = skill:GetId()
    local baseValueAdd = params[1] or 0
    if baseValueAdd > 0 then
        if UpdateBondBaseDelta(piece, baseValueAdd, skillKey) then
            hasChanged = true
        end
    else
        UpdateBondBaseDelta(piece, 0, skillKey)
    end

    local deleteMultiplier = params[2] or 0
    if deleteMultiplier > 0 then
        local currentDeleteValue = piece:GetValueUponDeletion()
        local existingDelta = piece:GetBondDeletionValueDelta(skillKey .. "_Delete")
        local baseDeleteValue = currentDeleteValue - existingDelta
        local delta = baseDeleteValue * (deleteMultiplier - 1)
        if UpdateBondDeletionDelta(piece, delta, skillKey .. "_Delete") then
            hasChanged = true
        end
    else
        UpdateBondDeletionDelta(piece, 0, skillKey .. "_Delete")
    end

    return hasChanged
end)
end

return { Register = Register }
