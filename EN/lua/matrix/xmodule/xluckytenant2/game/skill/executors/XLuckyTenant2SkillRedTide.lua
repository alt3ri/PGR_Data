local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local SkillUtils = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillUtils")

local ValidateSkillParams = SkillUtils.ValidateSkillParams
local PieceType = XLuckyTenant2Enum.PieceType
local TriggerState = XLuckyTenant2Enum.TriggerState

---红潮技能子执行器
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器
local function Register(skillExecutor)
---技能类型601：红潮被动01（被动）- 每回合传染相邻棋子
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type601, function(skill, context)
    local piece = context.piece or skill:GetPiece()

    if not piece then
        return false
    end

    if piece:GetPieceType() ~= PieceType.RedTide then
        return false
    end

    local adjacentPieces = context.proxy:GetAdjacentPieces()
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

            -- 检查目标棋子是否拥有对应的感染技能（如506），只有拥有该技能才能被感染
            if targetStateSkillId then
                local hasTargetSkill = false
                local adjSkills = adjPiece:GetSkills(context.model)
                for _, adjSkill in ipairs(adjSkills) do
                    if adjSkill:GetType() == targetStateSkillId then
                        hasTargetSkill = true
                        break
                    end
                end
                if hasTargetSkill and not adjPiece:HasState(TriggerState.Infection) then
                    context.proxy:ApplyState(adjPiece, TriggerState.Infection, targetStateSkillId, -1)
                    infectedCount = infectedCount + 1
                end
            end
        end
    end

    return infectedCount > 0
end)

---技能类型602：红潮lv1（技能）- 相邻棋子每发生1次被消除，红潮基础金币+N
---仅通过删除流程在 XLuckyTenant2OnDeleteEffects.ApplyType602 中触发并实现
skillExecutor:Register(SkillType.Type602, function()
    return false
end)

---技能类型603：红潮lv2（技能）- 相邻棋子存在倒计时时，概率将倒计回合清零，且基础金币+N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type603, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    if piece:GetPieceType() ~= PieceType.RedTide then
        return false
    end

    local markKey = piece:GetUid() .. "_" .. skill:GetId()
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false
    end

    local probability = params[1] or 30
    local valueDelta = params[2] or 0

    if valueDelta <= 0 then
        return false
    end

    local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
    local affectedCount = 0

    for _, adjPiece in ipairs(adjacentPieces) do
        if adjPiece then
            local upgradeState = adjPiece:GetState(TriggerState.Upgrade)
            if upgradeState and upgradeState:GetRemainRounds() > 0 then
                if context.proxy:RandomCheck(probability) then
                    upgradeState:SetRemainRounds(0)
                    affectedCount = affectedCount + 1
                end
            end

            local deathState = adjPiece:GetState(TriggerState.Death)
            if deathState and deathState:GetRemainRounds() > 0 then
                if context.proxy:RandomCheck(probability) then
                    deathState:SetRemainRounds(0)
                    affectedCount = affectedCount + 1
                end
            end
        end
    end

    if affectedCount > 0 then
        context.proxy:ModifyPieceValue(piece, valueDelta)
        return true
    end

    return false
end)
end

return { Register = Register }
