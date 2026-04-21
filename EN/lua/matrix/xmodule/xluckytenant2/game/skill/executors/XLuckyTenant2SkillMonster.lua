local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local SkillUtils = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillUtils")

local ValidateSkillParams = SkillUtils.ValidateSkillParams
local UpdateBondDeletionDelta = SkillUtils.UpdateBondDeletionDelta
local TriggerState = XLuckyTenant2Enum.TriggerState
local PieceType = XLuckyTenant2Enum.PieceType

---怪物技能子执行器
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器
local function Register(skillExecutor)
    ---技能类型201：怪物羁绊lv0「侵蚀」（被动）- 确保棋子拥有 Production 状态
    ---实际生产子虫的逻辑由 Type209 状态技能执行
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type201, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 3) then
            return false
        end

        local rounds = params[1] or 0 -- 每N回合
        if rounds <= 0 then
            return false
        end

        -- 如果棋子还没有 Production 状态，用 Type209 的 skillId 创建
        local productionState = piece:GetState(TriggerState.Production)
        if not productionState then
            local se = context.game and context.game:GetSkillExecutor()
            local skill209Id = se and se:GetStateSkillId(SkillType.Type209) or nil
            local stateSkillId = skill209Id or skill:GetId()
            context.proxy:ApplyState(piece, TriggerState.Production, stateSkillId, rounds)
            return true
        end

        return false
    end)

    ---技能类型202：怪物被动01-补偿 - 若相邻无空位生成赤bug，则基础金币+N
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type202, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 1) then
            return false
        end

        local valueDelta = params[1] or 0 -- 增加的基础金币

        if valueDelta <= 0 then
            return false
        end

        -- 只有当 Type209 实际尝试生成子虫但因无空位失败时，才触发补偿
        local pieceUid = piece:GetUid()
        local failKey = "Type209_NoSpace_" .. pieceUid
        if not context.proxy._RoundExecutedSkills[failKey] then
            return false
        end

        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        context.proxy:ModifyPieceValue(piece, valueDelta)
        return true
    end)

    ---技能类型203：怪物lv1（技能）- 子虫基础金币+N，消除金币+M
    ---实际逻辑在 XLuckyTenant2OperationAddNewPiece 中实现
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type203, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()

        if not ValidateSkillParams(piece, params, 2) then
            return false
        end

        local pieceType = piece:GetPieceType()
        if pieceType ~= PieceType.Monster then
            return false
        end

        local baseValueDelta = params[1] or 0
        local deletionValueDelta = params[3] or 0

        if baseValueDelta <= 0 and deletionValueDelta <= 0 then
            return false
        end

        return true
    end)

    ---技能类型204：怪物lv2（技能）- 当子虫、怪物在死亡或被消除时，额外得基础金币*N
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type204, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 2) then
            return false
        end

        local bugPieceId = params[1] or 0
        local multiplier = params[2] or 0
        if multiplier <= 0 then
            return false
        end

        local pieceId = piece:GetId()
        local isMonster = piece:GetPieceType() == PieceType.Monster
        local isBug = bugPieceId == 0 or bugPieceId == pieceId
        if not (isMonster or isBug) then
            return false
        end

        local baseValue = piece:GetBaseValue() or 0
        local delta = baseValue * multiplier
        return UpdateBondDeletionDelta(piece, delta, skill:GetId())
    end)

    ---技能类型205：怪物lv3（技能）- 子虫改为N回合后死亡
    ---实际逻辑在 XLuckyTenant2OperationAddNewPiece 中实现
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type205, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()

        if not ValidateSkillParams(piece, params, 1) then
            return false
        end

        if piece:GetPieceType() ~= PieceType.Monster then
            return false
        end

        local newDeathRounds = params[1] or 0
        if newDeathRounds < 0 then
            return false
        end

        return true
    end)

    ---技能类型207：怪物lv4（技能）- 当子虫死亡或被消除时，可传染相邻棋子，每成功传染1枚+N金币收益
    ---实际逻辑在 XLuckyTenant2OperationAddNewPiece 中实现
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type207, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()

        if not ValidateSkillParams(piece, params, 1) then
            return false
        end

        if piece:GetPieceType() ~= PieceType.Monster then
            return false
        end

        local valuePerInfection = params[1] or 0
        if valuePerInfection <= 0 then
            return false
        end

        return true
    end)

    ---技能类型208：子虫技能02（死亡传染）- 子虫死亡时可传染相邻棋子
    ---传染逻辑在 XLuckyTenant2OnDeleteEffects.DoType208InfectAdjacent()
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type208, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 1) then
            return false
        end

        if not piece:HasState(TriggerState.Death) then
            return false
        end

        local deathState = piece:GetState(TriggerState.Death)
        if not deathState or not deathState:IsExpired() then
            return false
        end

        local OnDeleteEffects = require("XModule/XLuckyTenant2/Game/XLuckyTenant2OnDeleteEffects")
        local infectedCount = OnDeleteEffects.DoType208InfectAdjacent(piece, skill, context)
        return infectedCount > 0
    end)

    ---技能类型209：怪物状态技能01（倒计时）- 每N回合在相邻空位产生子虫
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type209, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 2) then
            return false
        end

        local rounds = params[1] or 0
        local amount = params[2] or 1
        local pieceId = params[3] or 0

        if rounds <= 0 or pieceId <= 0 then
            return false
        end

        if context.isExpiredStateSkill then
        else
            local productionState = piece:GetState(TriggerState.Production)
            local isCountdownZero = productionState and productionState:GetRemainRounds() <= 0

            if not productionState then
                context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
            elseif isCountdownZero then
                piece:RemoveState(TriggerState.Production)
            else
                return false
            end

            if not isCountdownZero then
                return false
            end
        end

        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId

        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        local emptyPositions = context.proxy:GetAdjacentEmptyPositions()
        if #emptyPositions == 0 then
            -- 标记本次生产因无空位而失败，供 Type202 补偿技能检测
            local failKey = "Type209_NoSpace_" .. piece:GetUid()
            context.proxy._RoundExecutedSkills[failKey] = true
            context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
            return false
        end

        local model = context.model
        local skill210Id = nil
        local deathRounds = 2
        if model then
            local bugChessConfig = model:GetLuckyTenant2ChessConfigById(pieceId)
            if bugChessConfig and bugChessConfig.StateSkillId then
                local stateSkillIds = bugChessConfig.StateSkillId
                if type(stateSkillIds) == "table" then
                    local resolveFn = context.game and context.game:GetResolveStateSkillIdFn()
                    for _, stateSkillId in ipairs(stateSkillIds) do
                        if stateSkillId and stateSkillId > 0 and resolveFn then
                            local actualSkillId, skillConfig = resolveFn(stateSkillId, model)
                            if skillConfig and skillConfig.Type == SkillType.Type210 then
                                skill210Id = actualSkillId
                                local skill210Params = skillConfig.Params or {}
                                deathRounds = skill210Params[1] or 2
                                break
                            end
                        end
                    end
                end
            end
        end

        local created = 0
        for i = 1, math.min(amount, #emptyPositions) do
            local pos = emptyPositions[i]
            context.proxy:AddNewPieceWithDeathSkill(pieceId, pos[1], pos[2], skill210Id, deathRounds)
            created = created + 1
        end

        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)

        return created > 0
    end)

    ---技能类型210：子虫技能01 - 存在N回合后死亡
    ---@param skill XLuckyTenant2ChessSkill 技能对象
    ---@param context XLuckyTenant2SkillContext 执行上下文
    skillExecutor:Register(SkillType.Type210, function(skill, context)
        local piece = context.piece or skill:GetPiece()
        local params = skill:GetParams()
        if not ValidateSkillParams(piece, params, 1) then
            return false
        end

        local rounds = params[1] or 0

        if rounds <= 0 then
            return false
        end

        local deathState = piece:GetState(TriggerState.Death)

        if not deathState then
            if context.isExpiredStateSkill == true then
                -- 状态技能到期：若该子虫受 Type207 影响，则在删除前播放一次感染来源特效
                local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")
                if XLuckyTenant2BondSkills.BondHasType207ForPieceId(context.model, context.game, XLuckyTenant2Enum.Bond.Monster) then
                    local x, y = piece:GetPosition()
                    context.proxy:AddExtraAnimation({
                        type = XLuckyTenant2Enum.AnimationType.InfectionSourceEnable,
                        pieceUid = piece:GetUid(),
                        x = x,
                        y = y,
                        skillId = skill:GetId(),
                    })
                end
                context.proxy:DeletePiece(piece)
                return true
            else
                context.proxy:ApplyState(piece, TriggerState.Death, skill:GetId(), rounds)
                return true
            end
        end

        if deathState then
            local isExpired = deathState:IsExpired()

            if isExpired then
                context.proxy:DeletePiece(piece)
                return true
            end

            return false
        end
    end)
end

return { Register = Register }
