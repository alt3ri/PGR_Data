local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local SkillUtils = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillUtils")
local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")

local ValidateSkillParams = SkillUtils.ValidateSkillParams
local GetBoxPieceIdByQuality = SkillUtils.GetBoxPieceIdByQuality
local PieceType = XLuckyTenant2Enum.PieceType
local TriggerState = XLuckyTenant2Enum.TriggerState

---根据品质获取随机棋子ID（辅助函数）
---@param model XLuckyTenant2Model 配置模型
---@param quality number 品质值
---@return number 随机棋子ID（如果没有找到则返回0）
local function GetRandomChessIdByQuality(model, quality)
    if not model or not quality then
        return 0
    end

    local allChessConfigs = model:GetLuckyTenant2ChessConfigs()
    if not allChessConfigs then
        return 0
    end

    local candidates = {}
    for _, config in pairs(allChessConfigs) do
        if config and config.Quality == quality and config.Type ~= XLuckyTenant2Enum.PieceType.Box and not SkillUtils.IsPropPieceId(config.Id) then
            table.insert(candidates, config.Id)
        end
    end

    if #candidates == 0 and quality > 1 then
        return GetRandomChessIdByQuality(model, quality - 1)
    end

    if #candidates == 0 then
        for _, config in pairs(allChessConfigs) do
            if config and config.Type ~= XLuckyTenant2Enum.PieceType.Box and not SkillUtils.IsPropPieceId(config.Id) then
                table.insert(candidates, config.Id)
            end
        end
    end

    if #candidates == 0 then
        return 0
    end

    local randomIndex = math.random(1, #candidates)
    return candidates[randomIndex]
end

---根据品质与棋子类型获取随机棋子ID（辅助函数）
---@param model XLuckyTenant2Model 配置模型
---@param quality number 品质值
---@param pieceType number 棋子类型
---@return number 随机棋子ID（如果没有找到则返回0）
local function GetRandomChessIdByQualityAndType(model, quality, pieceType)
    if not model or not quality or not pieceType then
        return 0
    end

    local allChessConfigs = model:GetLuckyTenant2ChessConfigs()
    if not allChessConfigs then
        return 0
    end

    local candidates = {}
    for id, config in pairs(allChessConfigs) do
        if config and config.Quality == quality and config.Type == pieceType and not SkillUtils.IsPropPieceId(config.Id) then
            table.insert(candidates, config.Id)
        end
    end

    if #candidates == 0 then
        return 0
    end

    local randomIndex = math.random(1, #candidates)
    return candidates[randomIndex]
end

--- 获取棋子的羁绊技能列表（辅助函数）
---@param piece XLuckyTenant2Piece 棋子
---@param context XLuckyTenant2SkillContext 执行上下文
---@return XLuckyTenant2ChessSkill[] 羁绊技能列表
local function GetBondSkills(piece, context)
    if not context.game or not piece then
        return {}
    end
    local resolveFn = context.game:GetResolveStateSkillIdFn()
    return XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, resolveFn)
end

--- 在羁绊技能列表中查找指定类型的技能（辅助函数）
---@param skills XLuckyTenant2ChessSkill[] 技能列表
---@param skillType number 目标技能类型
---@return XLuckyTenant2ChessSkill|nil 找到的技能，未找到返回nil
local function FindSkillByType(skills, skillType)
    for _, s in ipairs(skills) do
        if s:GetType() == skillType then
            return s
        end
    end
    return nil
end

--- 从棋子配置的 StateSkillId 中解析 Type508 状态技能（与 StateApplier/OnDeleteEffects 保持一致）
---@param piece XLuckyTenant2Piece
---@param context XLuckyTenant2SkillContext
---@return table|nil skillConfig, number|nil actualSkillId
local function GetType508FromPieceConfig(piece, context)
    if not piece or not context or not context.model or not context.game then
        return nil, nil
    end

    local model = context.model
    local game = context.game
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
    if #stateSkillIds == 0 then
        return nil, nil
    end

    local se = game:GetSkillExecutor()
    if not se then
        return nil, nil
    end

    for i = 1, #stateSkillIds do
        local stateSkillId = stateSkillIds[i]
        if stateSkillId and stateSkillId > 0 then
            local actualSkillId, skillConfig = se:ResolveStateSkillId(stateSkillId, model)
            if skillConfig and skillConfig.Type == SkillType.Type508 then
                return skillConfig, actualSkillId or stateSkillId
            end
        end
    end

    return nil, nil
end

--- 计算倒计时减免回合数（辅助函数）
--- 来源1：Type506感染状态技能的参数[1]（感染减免）
--- 来源2：Type503羁绊技能的参数[1]（羁绊减免）
---@param piece XLuckyTenant2Piece 棋子
---@param context XLuckyTenant2SkillContext 执行上下文
---@return number 总减免回合数
local function CalcReduceRounds(piece, context)
    local reduceRounds = 0

    -- 来源1：感染状态（Type506）的倒计时减免
    local infectionState = piece:GetState(TriggerState.Infection)
    if infectionState and context.model then
        local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(infectionState:GetSkillId())
        if stateSkillConfig and stateSkillConfig.Type == SkillType.Type506 then
            local stateParams = stateSkillConfig.Params or {}
            reduceRounds = reduceRounds + (stateParams[1] or 0)
        end
    end

    -- 来源2：Type503羁绊技能的倒计时减免
    local bondSkills = GetBondSkills(piece, context)
    local type503Skill = FindSkillByType(bondSkills, SkillType.Type503)
    if type503Skill then
        local skillParams = type503Skill:GetParams() or {}
        reduceRounds = reduceRounds + (skillParams[1] or 0)
    end

    return reduceRounds
end

--- 施加死亡倒计时（计算减免后）
---@param piece XLuckyTenant2Piece 棋子
---@param deathSkillId number 死亡技能ID（Type508）
---@param baseRounds number 基础回合数
---@param context XLuckyTenant2SkillContext 执行上下文
local function ApplyDeathCountdown(piece, deathSkillId, baseRounds, context)
    local reduceRounds = CalcReduceRounds(piece, context)
    local finalRounds = math.max(1, baseRounds - reduceRounds)
    context.proxy:ApplyState(piece, TriggerState.Death, deathSkillId, finalRounds)
end

--- 计算新宝盒重生后的倒计时减免回合数（辅助函数）
--- 与 CalcReduceRounds 类似，但额外检查 Type505 感染减免，
--- 并通过遍历新棋子的羁绊配置来获取 Type503 减免
---@param oldPiece XLuckyTenant2Piece 旧棋子（用于读取感染状态）
---@param newPiece XLuckyTenant2Piece 新棋子（用于读取羁绊）
---@param context XLuckyTenant2SkillContext 执行上下文
---@return number 总减免回合数
local function CalcReduceRoundsForRebornBox(oldPiece, newPiece, context)
    local reduceRounds = 0

    -- 来源1：旧棋子的感染状态 → 通过Type505获取感染倒计时减免
    local oldInfectionState = oldPiece:GetState(TriggerState.Infection)
    if oldInfectionState and context.model then
        local infectionSkillId = oldInfectionState:GetSkillId()
        local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(infectionSkillId)
        if stateSkillConfig and stateSkillConfig.Type == SkillType.Type506 then
            local bondSkills = GetBondSkills(oldPiece, context)
            local type505Skill = FindSkillByType(bondSkills, SkillType.Type505)
            if type505Skill then
                local type505Params = type505Skill:GetParams() or {}
                reduceRounds = reduceRounds + (type505Params[1] or 0)
            end
        end
    end

    -- 来源2：新棋子的羁绊配置中的Type503减免
    local bondIdStr = newPiece:GetBondId()
    if bondIdStr and bondIdStr ~= "" and context.game then
        local bondManager = context.game:GetBondManager()
        if not bondManager then
            return reduceRounds
        end
        for bondIdPart in string.gmatch(bondIdStr, "([^|]+)") do
            local bondId = tonumber(bondIdPart)
            if bondId then
                local bond = bondManager:GetBond(bondId)
                if bond and bond:GetLevel() > 0 then
                    local bondSkillConfigs = context.model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bond:GetLevel())
                    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
                        local skillId = bondSkillConfig.SkillId
                        if type(skillId) == "table" then
                            skillId = skillId[1] or 0
                        end
                        if skillId and skillId > 0 then
                            local skillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(skillId)
                            if skillConfig and skillConfig.Type == SkillType.Type503 then
                                local skillParams = skillConfig.Params or {}
                                reduceRounds = reduceRounds + (skillParams[1] or 0)
                            end
                        end
                    end
                end
            end
        end
    end

    return reduceRounds
end

--- 获取感染产出信息（辅助函数）
--- 检查棋子是否处于Type506感染状态，如果是则通过Type505获取产出类型和红潮概率
---@param piece XLuckyTenant2Piece 棋子
---@param context XLuckyTenant2SkillContext 执行上下文
---@return number|nil targetPieceType 产出棋子类型（感染时为Monster，否则nil）
---@return number redTideProbability 红潮额外产出概率
---@return number redTidePieceId 红潮棋子ID
---@param skillExecutor XLuckyTenant2SkillExecutor 技能执行器
local function GetInfectionSpawnInfo(piece, context, skillExecutor)
    local infectionState = piece:GetState(TriggerState.Infection)
    if not infectionState or not context.model then
        return nil, 0, 0
    end

    local infectionSkillId = infectionState:GetSkillId()
    local skillId = skillExecutor:GetStateSkillId(infectionSkillId)
    local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(skillId)
    if not stateSkillConfig or stateSkillConfig.Type ~= SkillType.Type506 then
        return nil, 0, 0
    end

    -- 通过Type505获取感染产出参数
    local bondSkills = GetBondSkills(piece, context)
    local type505Skill = FindSkillByType(bondSkills, SkillType.Type505)
    if not type505Skill then
        return nil, 0, 0
    end

    local type505Params = type505Skill:GetParams() or {}
    return PieceType.Monster, (type505Params[2] or 0), (type505Params[3] or 0)
end

--- 步骤2c：在相邻空位产出棋子（独立函数，供 Type508 与 OnDeleteEffects 共用）
---@param piece XLuckyTenant2Piece 当前宝盒棋子（可能已被 Type502/507 替换）
---@param amount number 产出数量
---@param noEmptyGold number 无空位时的补偿金币
---@param context XLuckyTenant2SkillContext 执行上下文
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器（用于获取感染信息）
---@param hasType502 boolean 是否有 Type502 技能
---@param hasType507Triggered boolean 是否触发了 Type507 技能
---@param skipDelete boolean|nil 是否跳过删除旧宝盒（外部删除流程已处理时传 true）
---@return boolean 是否成功产出
local function SpawnAdjacentPieces(piece, amount, noEmptyGold, context, skillExecutor, hasType502, hasType507Triggered, skipDelete)
    local emptyPositions = context.proxy:GetAdjacentEmptyPositions()

    if #emptyPositions > 0 then
        -- 获取感染产出信息（是否产出怪物、红潮概率等）
        local checkPiece = hasType502 and context.piece or piece
        local targetPieceType, redTideProbability, redTidePieceId = GetInfectionSpawnInfo(checkPiece, context, skillExecutor)

        -- 在空位产出棋子
        local pieceQuality = piece:GetQuality()
        local created = 0
        for i = 1, math.min(amount, #emptyPositions) do
            local pos = emptyPositions[i]
            local randomPieceId = 0
            if targetPieceType then
                -- 感染状态：优先产出同品质怪物
                randomPieceId = GetRandomChessIdByQualityAndType(context.model, pieceQuality, targetPieceType)
                if randomPieceId <= 0 then
                    randomPieceId = GetRandomChessIdByQuality(context.model, pieceQuality)
                end
            else
                -- 正常状态：产出同品质随机棋子
                randomPieceId = GetRandomChessIdByQuality(context.model, pieceQuality)
            end
            if randomPieceId > 0 then
                context.proxy:AddNewPiece(randomPieceId, pos[1], pos[2])
                created = created + 1
            end
        end

        -- 感染额外效果：概率在剩余空位产出红潮棋子
        if targetPieceType == PieceType.Monster and redTideProbability > 0 and redTidePieceId > 0 then
            local random = math.random(1, 100)
            if random <= redTideProbability then
                if created < #emptyPositions then
                    local pos = emptyPositions[created + 1]
                    context.proxy:AddNewPiece(redTidePieceId, pos[1], pos[2])
                    created = created + 1
                end
            end
        end

        -- 删除旧宝盒（Type502/Type507 已自行处理替换时无需删除；外部删除流程已处理时跳过）
        if not skipDelete and not hasType502 and not hasType507Triggered then
            context.proxy:DeletePiece(piece)
        end
        return created > 0
    else
        -- 无空位时给予补偿金币
        if noEmptyGold > 0 then
            context.proxy:ModifyPieceValue(piece, noEmptyGold)
        end
        if not skipDelete and not hasType502 and not hasType507Triggered then
            context.proxy:DeletePiece(piece)
        end
        return true
    end
end

--- 执行Type502重生逻辑（辅助函数）
--- 宝盒死亡后，根据概率决定新品质，替换为新宝盒，继承感染状态，施加新倒计时
---@param type502Skill XLuckyTenant2ChessSkill Type502技能对象
---@param piece XLuckyTenant2Piece 当前宝盒棋子
---@param pieceId number 当前棋子ID
---@param x number 棋子X坐标
---@param y number 棋子Y坐标
---@param baseRounds number 基础倒计时回合数
---@param deathSkill XLuckyTenant2ChessSkill Type508技能对象（用于施加死亡状态）
---@param context XLuckyTenant2SkillContext 执行上下文
---@return XLuckyTenant2Piece 新宝盒棋子（替换失败时返回原棋子）
local function ExecuteType502Reborn(type502Skill, piece, pieceId, x, y, baseRounds, deathSkill, context)
    -- 步骤1：根据概率决定新宝盒品质
    local type502Params = type502Skill:GetParams() or {}
    local probabilityOriginal = type502Params[1] or 70
    local probabilityUpgrade = type502Params[2] or 30

    local currentQuality = piece:GetQuality()
    local random = math.random(1, 100)
    local newQuality = currentQuality
    if random > probabilityOriginal and random <= probabilityOriginal + probabilityUpgrade then
        local maxQuality = 5
        newQuality = math.min(currentQuality + 1, maxQuality)
    end

    local newPieceId = GetBoxPieceIdByQuality(context.model, newQuality)
    if not newPieceId or newPieceId <= 0 then
        newPieceId = pieceId
    end

    -- 步骤2：在原位替换为新宝盒
    local bag = context.game:GetBag()
    local board = context.game:GetChessBoard()
    if not bag or not board then
        return piece
    end

    local oldInfectionState = context.piece:GetState(TriggerState.Infection)

    -- 删除旧棋子，创建新棋子
    context.proxy:MarkPieceForDeletion(piece)
    piece:MarkAsDeleted()
    local oldUid = piece:GetUid()
    local newUid = bag:GetNewUid()
    local newPiece = bag:NewPiece(context.model, newPieceId, newUid)
    if not newPiece then
        return piece
    end

    bag:AddPiece(newPiece)
    board:RemovePieceByPosition(x, y)
    bag:DeletePieceByUid(oldUid)
    board:SetPieceByPosition(newPiece, x, y)

    -- 宝盒重生品质提升时播放特效
    if newQuality > currentQuality then
        context.proxy:AddExtraAnimation({
            type = XLuckyTenant2Enum.AnimationType.ActivateSkillEnable,
            pieceUid = newPiece:GetUid(),
            x = x,
            y = y,
            skillId = type502Skill:GetId(),
        })
    end

    -- 步骤3：继承感染状态
    if oldInfectionState then
        local oldInfectionSkillId = oldInfectionState:GetSkillId()
        context.proxy:ApplyState(newPiece, TriggerState.Infection, oldInfectionSkillId, -1)
    end

    -- 步骤4：计算减免回合并施加新的死亡倒计时（deathSkill 为 nil 时跳过，由下一回合 Type508 自然施加）
    if deathSkill and baseRounds and baseRounds > 0 then
        local reduceRounds = CalcReduceRoundsForRebornBox(context.piece, newPiece, context)
        local finalRounds = math.max(1, baseRounds - reduceRounds)
        context.proxy:ApplyState(newPiece, TriggerState.Death, deathSkill:GetId(), finalRounds)
    end

    return newPiece
end

--- 内部共享：品质未满时产生品质+1的新宝盒替换原宝盒
---@param type507Skill XLuckyTenant2ChessSkill Type507 技能对象
---@param piece XLuckyTenant2Piece 当前宝盒棋子
---@param x number 棋子 X 坐标
---@param y number 棋子 Y 坐标
---@param context XLuckyTenant2SkillContext 执行上下文
---@return XLuckyTenant2Piece 新宝盒棋子（替换失败时返回原棋子）
---@return boolean 是否成功替换
local function TryType507QualityUpgrade(type507Skill, piece, x, y, context)
    local currentQuality = piece:GetQuality() or 0
    local maxQuality = 5
    if currentQuality >= maxQuality then
        return piece, false
    end

    local newQuality = currentQuality + 1
    local newPieceId = GetBoxPieceIdByQuality(context.model, newQuality)
    if newPieceId <= 0 then
        return piece, false
    end

    local bag = context.game and context.game:GetBag()
    local board = context.game and context.game:GetChessBoard()
    if not bag or not board then
        return piece, false
    end

    context.proxy:MarkPieceForDeletion(piece)
    piece:MarkAsDeleted()
    local oldUid = piece:GetUid()
    local newUid = bag:GetNewUid()
    local newPiece = bag:NewPiece(context.model, newPieceId, newUid)
    if not newPiece then
        return piece, false
    end

    bag:AddPiece(newPiece)
    board:RemovePieceByPosition(x, y)
    bag:DeletePieceByUid(oldUid)
    board:SetPieceByPosition(newPiece, x, y)
    -- 宝盒品质提升时播放特效
    context.proxy:AddExtraAnimation({
        type = XLuckyTenant2Enum.AnimationType.ActivateSkillEnable,
        pieceUid = newPiece:GetUid(),
        x = x,
        y = y,
        skillId = type507Skill:GetId(),
    })
    return newPiece, true
end

--- 执行 Type507 宝盒被消除时的特殊处理（品质+1 新宝盒 或 橙色加金币）
--- 用于 Type508 倒计时归零场景，优先于 Type502 执行。
---@param type507Skill XLuckyTenant2ChessSkill|nil Type507 技能对象，nil 则不执行
---@param piece XLuckyTenant2Piece 当前宝盒棋子
---@param x number 棋子 X 坐标
---@param y number 棋子 Y 坐标
---@param context XLuckyTenant2SkillContext 执行上下文
---@param deathSkill XLuckyTenant2ChessSkill Type508 死亡技能，用于橙色品质时刷新倒计时
---@param baseRounds number 基础倒计时回合数
---@return XLuckyTenant2Piece 当前棋子（若触发品质+1 则为新宝盒，否则为原 piece）
---@return boolean 是否触发了 Type507
local function ExecuteType507OnBoxDeath(type507Skill, piece, x, y, context, deathSkill, baseRounds)
    if not type507Skill or not piece or piece:GetPieceType() ~= PieceType.Box or not x or not y or x <= 0 or y <= 0 then
        return piece, false
    end

    local type507Params = type507Skill:GetParams() or {}
    local currentQuality = piece:GetQuality() or 0
    local maxQuality = 5
    local goldValue = type507Params[1] or 10

    if currentQuality < maxQuality then
        return TryType507QualityUpgrade(type507Skill, piece, x, y, context)
    end

    if currentQuality == maxQuality and goldValue > 0 then
        -- 橙色品质：先刷新死亡倒计时，再增加棋子基础金币
        if deathSkill and baseRounds and baseRounds > 0 then
            ApplyDeathCountdown(piece, deathSkill:GetId(), baseRounds, context)
        end
        context.proxy:ModifyPieceValue(piece, goldValue)
        return piece, true
    end

    return piece, false
end

--- 执行 Type507 宝盒被外部消除时的特殊处理（品质+1 新宝盒 或 橙色加金币）
--- 用于 OnDeleteEffects 场景，旧棋子由外部 DeletePiece 自动删除。
---@param type507Skill XLuckyTenant2ChessSkill|nil Type507 技能对象，nil 则不执行
---@param piece XLuckyTenant2Piece 当前宝盒棋子
---@param x number 棋子 X 坐标
---@param y number 棋子 Y 坐标
---@param context XLuckyTenant2SkillContext 执行上下文
---@return XLuckyTenant2Piece 当前棋子（若触发则为新宝盒，否则为原 piece）
---@return boolean 是否触发了 Type507
local function ExecuteType507OnBoxDelete(type507Skill, piece, x, y, context)
    if not type507Skill or not piece or piece:GetPieceType() ~= PieceType.Box or not x or not y or x <= 0 or y <= 0 then
        return piece, false
    end

    local type507Params = type507Skill:GetParams() or {}
    local currentQuality = piece:GetQuality() or 0
    local maxQuality = 5
    local goldValue = type507Params[1] or 10

    if currentQuality < maxQuality then
        return TryType507QualityUpgrade(type507Skill, piece, x, y, context)
    end

    if currentQuality == maxQuality and goldValue > 0 then
        -- 橙色品质：原棋子由外部 DeletePiece 自动删除，
        -- 在原地用相同 pieceId 生成一个新宝盒，再对新棋子加金币
        local bag = context.game and context.game:GetBag()
        local board = context.game and context.game:GetChessBoard()
        if bag and board then
            local pieceId = piece:GetId()
            local newUid = bag:GetNewUid()
            local newPiece = bag:NewPiece(context.model, pieceId, newUid)
            if newPiece then
                bag:AddPiece(newPiece)
                board:SetPieceByPosition(newPiece, x, y)

                -- 通过棋子配置的 StateSkillId 解析 Type508，并为新宝盒施加死亡倒计时（与初始化逻辑保持一致）
                local deathConfig, deathSkillId = GetType508FromPieceConfig(newPiece, context)
                if deathConfig and deathSkillId then
                    local deathParams = deathConfig.Params or {}
                    local baseRounds = deathParams[1] or 0
                    if baseRounds > 0 then
                        ApplyDeathCountdown(newPiece, deathSkillId, baseRounds, context)
                    end
                end

                -- 继承旧棋子的value，再增加goldValue固定值
                local oldValue = piece:GetBaseValueWithoutBond() or 0
                local newBaseValue = newPiece:GetBaseValue() or 0
                context.proxy:ModifyPieceValue(newPiece, oldValue - newBaseValue + goldValue)
                return newPiece, true
            end
        end
    end

    return piece, false
end

---宝盒技能子执行器
---@param skillExecutor XLuckyTenant2SkillExecutor 主技能执行器
local function Register(skillExecutor)
---技能类型501：宝盒被动01（被动）- 倒计时N回合后死亡，并在相邻空位产生棋子
---功能实际上是通过Type508实现的
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type501, function(skill, context)
    return true
end)

---技能类型502：宝盒被动02（被动）- 宝盒死亡后，原地产生1个宝盒
---实际重生逻辑由Type508中的ExecuteType502Reborn驱动，此处仅作为技能标记
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type502, function(skill, context)
    return true
end)

---技能类型503：宝盒羁绊lv.1 - 宝盒倒计回合上限-N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type503, function(skill, context)
    return true
end)

---技能类型504：宝盒lv2（技能）- 宝盒相邻棋子升级时，宝盒倒计时-N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type504, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    if piece:GetPieceType() ~= PieceType.Box then
        return false
    end

    local reduceRounds = params[1] or 0
    if reduceRounds <= 0 then
        return false
    end

    local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
    local hasUpgrade = false

    for _, adjPiece in ipairs(adjacentPieces) do
        if adjPiece and adjPiece:IsJustLeveledUp() then
            hasUpgrade = true
            break
        end
    end

    if hasUpgrade then
        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false
        end

        local deathState = piece:GetState(TriggerState.Death)
        if deathState and deathState:GetRemainRounds() > 0 then
            local currentRounds = deathState:GetRemainRounds()
            local newRounds = math.max(0, currentRounds - reduceRounds)
            deathState:SetRemainRounds(newRounds)
            return true
        end
    end

    return false
end)

---技能类型505：宝盒羁绊lv.3 - 可被传染，感染后效果由Type508处理
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type505, function(skill, context)
    return true
end)

---技能类型506：宝盒状态技能02（被传染）- 感染状态标记，实际效果由Type508处理
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type506, function(skill, context)
    return true
end)

---技能类型507：宝盒lv4（技能）- 宝盒被消除时，品质+1；若为橙色品质，改为基础金币+N
---实际逻辑在 XLuckyTenant2OperationDeletePiece 中实现
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type507, function(skill, context)
    return true
end)

----------------------------------------------------------------------
-- Type508：宝盒状态技能01（倒计时）
-- 整体流程：
--   1. 【首次施加】无死亡状态 → 计算减免回合 → 施加死亡倒计时
--   2. 【倒计时归零】宝盒死亡 →
--      2a. Type507 优先：若有 Type507，品质未满则产生品质+1 新宝盒，橙色则加基础金币
--      2b. 若有 Type502（重生）且未触发 507 → 替换为新品质宝盒，继承感染，重新倒计时
--      2c. 在相邻空位产出棋子（感染时产出怪物，概率额外产出红潮）
--      2d. 无空位时给予补偿金币
----------------------------------------------------------------------

---技能类型508：宝盒状态技能01（倒计时）- N回合后死亡并在相邻产生棋子
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
skillExecutor:Register(SkillType.Type508, function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    if piece:GetPieceType() ~= PieceType.Box then
        return false
    end

    local rounds = params[1] or 0
    local amount = params[2] or 1
    local noEmptyGold = params[3] or 0

    if rounds <= 0 then
        return false
    end

    local deathState = piece:GetState(TriggerState.Death)
    local isCountdownZero = deathState and deathState:GetRemainRounds() <= 0

    ----------------------------------------------------------------
    -- 分支1：尚无死亡状态且非过期触发 → 首次施加倒计时
    -- 注意：ReduceStateRounds会在倒计时归零时移除Death状态，
    -- 此时deathState为nil但isExpiredStateSkill为true，不应进入此分支
    ----------------------------------------------------------------
    if not deathState and not isCountdownZero and not context.isExpiredStateSkill then
        ApplyDeathCountdown(piece, skill:GetId(), rounds, context)
        return true
    end

    ----------------------------------------------------------------
    -- 分支2：倒计时归零或状态过期 → 宝盒死亡，执行产出逻辑
    ----------------------------------------------------------------
    if not (context.isExpiredStateSkill == true or isCountdownZero) then
        return false
    end

    -- 清除已归零的死亡状态
    if isCountdownZero then
        piece:RemoveState(TriggerState.Death)
    end

    local pieceId = piece:GetId()
    local x, y = piece:GetPosition()

    -- 步骤2a：检查是否有 Type502（死亡后重生）、Type507（被消除时品质+1/橙色加金币）
    local bondSkills = GetBondSkills(piece, context)
    local type502Skill = FindSkillByType(bondSkills, SkillType.Type502)
    local hasType502 = type502Skill ~= nil
    local type507Skill = FindSkillByType(bondSkills, SkillType.Type507)
    local hasType507 = type507Skill ~= nil

    -- 步骤2a'：Type507 优先 - 宝盒被消除时的特殊处理（品质+1 或 橙色加金币）
    local hasType507Triggered = false
    if hasType507 then
        piece, hasType507Triggered = ExecuteType507OnBoxDeath(type507Skill, piece, x, y, context, skill, rounds)
    end

    -- 步骤2b：若有 Type502 且未触发 507，替换为新品质宝盒并继承感染状态
    if hasType502 and not hasType507Triggered then
        piece = ExecuteType502Reborn(type502Skill, piece, pieceId, x, y, rounds, skill, context)
    end

    -- 更新代理引用（Type502 或 Type507 可能替换了棋子）
    if hasType502 or hasType507Triggered then
        context.proxy.Piece = piece
    end

    -- 步骤2c：在相邻空位产出棋子（调用共享函数）
    return SpawnAdjacentPieces(piece, amount, noEmptyGold, context, skillExecutor, hasType502, hasType507Triggered)
end)
end

return {
    Register = Register,
    ExecuteType507OnBoxDeath = ExecuteType507OnBoxDeath,
    ExecuteType507OnBoxDelete = ExecuteType507OnBoxDelete,
    ExecuteType502Reborn = ExecuteType502Reborn,
    SpawnAdjacentPieces = SpawnAdjacentPieces,
}
