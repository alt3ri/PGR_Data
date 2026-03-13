local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local TriggerState = XLuckyTenant2Enum.TriggerState
local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")

---状态显示管理器
---整合棋子状态的UI显示逻辑
---@class XLuckyTenant2StateDisplay
local StateDisplay = {}

---需要显示的状态技能类型配置
---@type table<number, boolean>
local DisplaySkillTypes = {
    [SkillType.Type210] = true, -- 子虫死亡倒计时
    [SkillType.Type508] = true, -- 宝盒死亡倒计时
    [SkillType.Type208] = true, -- 子虫死亡传染（显示图标，不显示回合数）
    [SkillType.Type201] = true, -- 怪物生产倒计时
    [SkillType.Type209] = true, -- 怪物分裂倒计时
    [SkillType.Type102] = true, -- 金融生产倒计时（被传染后）
}

---不显示回合数的技能类型（只显示状态图标）
---@type table<number, boolean>
local NoRoundDisplaySkills = {
    [SkillType.Type208] = true, -- 死亡时触发，不是倒计时
    [SkillType.Type408] = true, -- 永久感染状态，不是倒计时
    [SkillType.Type506] = true, -- 永久感染状态，不是倒计时
}

---感染状态技能类型（显示感染特效）
---@type table<number, boolean>
local InfectionSkillTypes = {
    [SkillType.Type102] = true, -- 金融被传染
    [SkillType.Type408] = true, -- 武器被传染
    [SkillType.Type506] = true, -- 宝盒被传染
}

---检查技能类型是否需要显示
---@param skillType number 技能类型
---@return boolean
function StateDisplay.ShouldDisplay(skillType)
    return DisplaySkillTypes[skillType] == true
end

---检查技能类型是否不显示回合数
---@param skillType number 技能类型
---@return boolean
function StateDisplay.ShouldHideRound(skillType)
    return NoRoundDisplaySkills[skillType] == true
end

---检查技能类型是否为感染状态
---@param skillType number 技能类型
---@return boolean
function StateDisplay.IsInfectionSkill(skillType)
    return InfectionSkillTypes[skillType] == true
end

---填充棋子的状态数据
---整合了原来的 FillPieceStatesData、AppendStateSkillDisplayIfMissing、AppendRoleUpgradeStateIfMissing
---@param piece XLuckyTenant2Piece 棋子对象
---@param model XLuckyTenant2Model 模型实例
---@param game XLuckyTenant2Game|nil 游戏实例（用于获取羁绊等级）
---@param getSkillDescFunc function 获取技能描述的函数
---@param getBondQualityBgFunc function 获取羁绊品质背景的函数
---@return table states 状态数据列表
---@return number|nil round 首个有剩余回合的状态的回合数
function StateDisplay.FillStatesData(piece, model, game, getSkillDescFunc, getBondQualityBgFunc)
    if not piece or not model then
        return {}, nil
    end

    local states = {}
    local round = nil
    local existingSkillIdMap = {}

    -- 1. 从棋子的实际状态获取数据
    local resolveFn = game and game:GetResolveStateSkillIdFn()
    for _, state in ipairs(piece:GetAllStates()) do
        local skillId = state:GetSkillId()
        local remainRounds = state:GetRemainRounds()

        -- 解析实际技能ID
        local actualSkillId = skillId
        if skillId and skillId > 0 and resolveFn then
            local resolvedId = resolveFn(skillId, model)
            if resolvedId and resolvedId > 0 then
                actualSkillId = resolvedId
            end
        end

        -- 技能类型101不显示
        local skillConfig = actualSkillId and actualSkillId > 0 and model:GetLuckyTenant2ChessSkillConfigById(actualSkillId)
        local isType101 = skillConfig and skillConfig.Type == SkillType.Type101
        -- 升级状态（Type301）满级时不显示
        local isType301AtMaxLevel = skillConfig and skillConfig.Type == SkillType.Type301
            and (piece:GetLevel() or 0) >= XLuckyTenant2Piece.GetRoleMaxLevel()
        if not isType101 and not isType301AtMaxLevel then
            states[#states + 1] = {
                StateType = state:GetStateType(),
                Round = remainRounds,
                Desc = getSkillDescFunc and getSkillDescFunc(actualSkillId) or "",
                SkillId = actualSkillId,
                ImageBg = getBondQualityBgFunc and getBondQualityBgFunc(actualSkillId) or "",
            }

            if actualSkillId and actualSkillId > 0 then
                existingSkillIdMap[actualSkillId] = true
            end

            if remainRounds and remainRounds > 0 and not round then
                round = remainRounds
            end
        end
    end

    -- 2. 添加角色升级状态（Type301）
    -- local roleUpgradeState = StateDisplay._GetRoleUpgradeState(piece, model, game, getSkillDescFunc, existingSkillIdMap)
    -- local currentLevel = piece:GetLevel() or 0
    -- local maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()
    -- local isAtMaxLevel = currentLevel >= maxLevel
    -- if roleUpgradeState and not isAtMaxLevel then
    --     states[#states + 1] = roleUpgradeState
    --     if roleUpgradeState.SkillId then
    --         existingSkillIdMap[roleUpgradeState.SkillId] = true
    --     end
    --     if roleUpgradeState.Round and roleUpgradeState.Round > 0 and not round then
    --         round = roleUpgradeState.Round
    --     end
    -- end

    -- 这个处理会导致显示与数据实际拥有的状态不一致，所以暂时注释掉
    -- 3. 从配置的StateSkillId添加状态显示
    -- StateDisplay._AppendConfiguredStates(piece, model, states, existingSkillIdMap, getSkillDescFunc, getBondQualityBgFunc)

    return states, round
end

---获取角色升级状态数据
---@param piece XLuckyTenant2Piece 棋子对象
---@param model XLuckyTenant2Model 模型实例
---@param game XLuckyTenant2Game|nil 游戏实例
---@param getSkillDescFunc function 获取技能描述的函数
---@param existingSkillIdMap table 已存在的技能ID映射
---@return table|nil 状态数据
function StateDisplay._GetRoleUpgradeState(piece, model, game, getSkillDescFunc, existingSkillIdMap)
    if not game or not model or not piece then
        return nil
    end

    -- 检查是否已有升级状态
    for skillId, _ in pairs(existingSkillIdMap) do
        local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
        if skillConfig and skillConfig.Type == SkillType.Type301 then
            return nil -- 已有Type301状态
        end
    end

    local bondIdStr = piece:GetBondId()
    if not bondIdStr or bondIdStr == "" then
        return nil
    end

    local bondManager = game:GetBondManager()
    if not bondManager then
        return nil
    end

    local rounds = 0
    local levelDelta = 0
    local maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()
    local maxReduceRounds = 0
    local hasType301 = false
    local type301SkillId = 0

    -- 遍历羁绊获取Type301和Type303技能参数
    for bondIdPart in string.gmatch(bondIdStr, "([^|]+)") do
        local bondId = tonumber(bondIdPart)
        if bondId then
            local bond = bondManager:GetBond(bondId)
            local bondLevel = bond and bond:GetLevel() or 0
            if bondLevel > 0 then
                local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
                for _, bondSkillConfig in ipairs(bondSkillConfigs) do
                    local skillId = bondSkillConfig.SkillId
                    if type(skillId) == "table" then
                        skillId = skillId[1]
                    end
                    if skillId and skillId > 0 then
                        local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
                        if skillConfig then
                            local skillType = skillConfig.Type
                            local params = skillConfig.Params or {}

                            if skillType == SkillType.Type301 and not hasType301 then
                                rounds = params[1] or 0
                                levelDelta = params[2] or 0
                                hasType301 = rounds > 0 and levelDelta > 0
                                if hasType301 then
                                    type301SkillId = skillId
                                end
                            elseif skillType == SkillType.Type303 then
                                local reduceRounds = params[1] or 0
                                if reduceRounds > maxReduceRounds then
                                    maxReduceRounds = reduceRounds
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not hasType301 or rounds <= 0 or levelDelta <= 0 then
        return nil
    end

    local currentLevel = piece:GetLevel() or 0
    if currentLevel >= maxLevel then
        return nil
    end

    local actualRounds = rounds
    if maxReduceRounds > 0 then
        actualRounds = math.max(1, rounds - maxReduceRounds)
    end

    return {
        StateType = TriggerState.Upgrade,
        Round = actualRounds,
        Desc = getSkillDescFunc and getSkillDescFunc(type301SkillId) or "",
        SkillId = type301SkillId,
        ImageBg = "",
    }
end

---从配置的StateSkillId添加状态显示
---@param piece XLuckyTenant2Piece 棋子对象
---@param model XLuckyTenant2Model 模型实例
---@param states table 状态数据列表
---@param existingSkillIdMap table 已存在的技能ID映射
---@param getSkillDescFunc function 获取技能描述的函数
---@param getBondQualityBgFunc function 获取羁绊品质背景的函数
---@param game XLuckyTenant2Game|nil 游戏实例（用于解析技能ID）
function StateDisplay._AppendConfiguredStates(piece, model, states, existingSkillIdMap, getSkillDescFunc, getBondQualityBgFunc, game)
    if not model or not piece then
        return
    end

    local chessConfig = model:GetLuckyTenant2ChessConfigById(piece:GetId())
    local stateSkillIds = chessConfig and chessConfig.StateSkillId or nil
    if not stateSkillIds then
        return
    end
    if type(stateSkillIds) ~= "table" then
        stateSkillIds = { stateSkillIds }
    end

    local resolveFn = game and game:GetResolveStateSkillIdFn()
    if not resolveFn then
        return
    end

    for _, stateSkillId in ipairs(stateSkillIds) do
        if stateSkillId and stateSkillId > 0 then
            local actualSkillId, skillConfig = resolveFn(stateSkillId, model)
            local finalSkillId = actualSkillId or stateSkillId

            if not existingSkillIdMap[finalSkillId] and skillConfig then
                local skillType = skillConfig.Type or 0

                if StateDisplay.ShouldDisplay(skillType) then
                    local params = skillConfig.Params or {}
                    local displayRound = params[1] or 0

                    -- 不显示回合数的技能，设置 Round = nil
                    if StateDisplay.ShouldHideRound(skillType) then
                        displayRound = nil
                    end

                    states[#states + 1] = {
                        StateType = 0,
                        Round = displayRound,
                        Desc = getSkillDescFunc and getSkillDescFunc(finalSkillId) or "",
                        SkillId = finalSkillId,
                        ImageBg = getBondQualityBgFunc and getBondQualityBgFunc(finalSkillId) or "",
                    }

                    existingSkillIdMap[finalSkillId] = true
                end
            end
        end
    end
end

---检查棋子是否有感染状态（用于显示感染特效）
---@param piece XLuckyTenant2Piece 棋子对象
---@return boolean
function StateDisplay.HasInfectionState(piece)
    if not piece then
        return false
    end
    return piece:HasState(TriggerState.Infection)
end

---获取棋子的感染技能类型（用于判断显示哪种感染特效）
---@param piece XLuckyTenant2Piece 棋子对象
---@param model XLuckyTenant2Model 模型实例
---@return number|nil 感染技能类型
function StateDisplay.GetInfectionSkillType(piece, model)
    if not piece or not model then
        return nil
    end

    local infectionState = piece:GetState(TriggerState.Infection)
    if not infectionState then
        return nil
    end

    local skillId = infectionState:GetSkillId()
    if not skillId or skillId <= 0 then
        return nil
    end

    local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
    if skillConfig then
        return skillConfig.Type
    end

    return nil
end

return StateDisplay
