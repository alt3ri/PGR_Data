local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill
local XLuckyTenant2BondSkills = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondSkills")
local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")

---技能执行上下文
---@class XLuckyTenant2SkillContext
---@field piece XLuckyTenant2Piece 技能所属棋子
---@field skill XLuckyTenant2ChessSkill 当前技能（由SkillExecutor填充）
---@field proxy XLuckyTenant2OperationProxy 操作代理
---@field model XLuckyTenant2Model 模型实例
---@field game XLuckyTenant2Game 游戏实例
---@field board XLuckyTenant2ChessBoard 棋盘
---@field bag XLuckyTenant2Bag 背包
---@field round number 当前回合数
---@field times number 执行次数（第几次计算）

---技能执行器
---使用函数表模式，所有技能类型的执行逻辑集中在此文件
local SkillExecutor = {}

---技能类型到执行函数的映射表
local _SkillExecutors = {}

---状态技能类型缓存表 {skillType: {skillId1, skillId2, ...}}
---用于快速查找指定类型的状态技能ID
local _StateSkillIdCache = {}

---初始化状态技能ID缓存
---在游戏初始化时调用，预查找所有状态类型的技能ID
---@param model XLuckyTenant2Model 模型实例
function SkillExecutor.InitStateSkillIds(model)
    if not model then
        return
    end

    -- 清空缓存
    _StateSkillIdCache = {}

    -- 需要查找的技能类型列表（供 ResolveStateSkillId 将 type 解析为 skillId；含状态技能 + 常出现在 StateSkillId 的被动如 301）
    local stateSkillTypes = {
        SkillType.Type210, -- 子虫死亡技能
        SkillType.Type209, -- 怪物分裂技能
        SkillType.Type508, -- 宝盒生成技能
        SkillType.Type102, -- 感染状态
        SkillType.Type405, -- 其他状态技能
        SkillType.Type506, -- 其他状态技能
        SkillType.Type208, -- 子虫死亡传染技能
        SkillType.Type301, -- 角色被动倒计时（配置可能填类型 301，需能解析为实际技能 ID 避免误报「不存在」）
    }

    -- 使用pairs遍历配置表，直接获取所有技能配置
    local allSkillConfigs = model:GetLuckyTenant2ChessSkillConfigs()
    if allSkillConfigs then
        -- 遍历所有技能配置
        for skillId, skillConfig in pairs(allSkillConfigs) do
            if skillConfig then
                local skillType = skillConfig.Type
                -- 检查是否是需要查找的状态技能类型
                for _, targetType in ipairs(stateSkillTypes) do
                    if skillType == targetType then
                        if not _StateSkillIdCache[skillType] then
                            _StateSkillIdCache[skillType] = {}
                        end
                        table.insert(_StateSkillIdCache[skillType], skillId)
                        break
                    end
                end
            end
        end
    end
end

---获取指定类型的状态技能ID列表
---@param skillType number 技能类型
---@return number[] 技能ID列表
function SkillExecutor.GetStateSkillIds(skillType)
    return _StateSkillIdCache[skillType] or {}
end

---获取指定类型的状态技能ID（返回第一个）
---@param skillType number 技能类型
---@return number|nil 技能ID
function SkillExecutor.GetStateSkillId(skillType)
    local skillIds = _StateSkillIdCache[skillType]
    if skillIds and #skillIds > 0 then
        return skillIds[1]
    end
    return nil
end

---统一处理stateSkillId：先尝试作为技能类型查找，再尝试作为技能ID查找
---@param stateSkillId number 状态技能ID（可能是技能类型或技能ID）
---@param model XLuckyTenant2Model 模型实例
---@return number|nil, XTableLuckyTenant2ChessSkill|nil 实际技能ID, 技能配置
function SkillExecutor.ResolveStateSkillId(stateSkillId, model)
    if not stateSkillId or stateSkillId <= 0 or not model then
        return nil, nil
    end

    -- 先尝试作为技能类型（Type）查找对应的技能ID
    local actualSkillId = SkillExecutor.GetStateSkillId(stateSkillId)
    local skillConfig = nil

    if actualSkillId then
        -- 通过技能类型找到了对应的技能ID，使用该ID获取配置
        local success, config = pcall(function()
            return model:GetLuckyTenant2ChessSkillConfigById(actualSkillId)
        end)
        if success and config then
            return actualSkillId, config
        end
    end

    -- 如果通过技能类型找不到，再尝试作为技能ID直接查找
    local success, config = pcall(function()
        return model:GetLuckyTenant2ChessSkillConfigById(stateSkillId)
    end)
    if success and config then
        return stateSkillId, config
    end

    -- 都找不到，返回nil
    return nil, nil
end

---注册技能执行器
---@param skillType number 技能类型
---@param executorFunc function 执行函数
function SkillExecutor.Register(skillType, executorFunc)
    _SkillExecutors[skillType] = executorFunc
end

---执行技能
---@param skill XLuckyTenant2ChessSkill 技能对象 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
function SkillExecutor.Execute(skill, context)
    local skillType = skill:GetType()
    local skillId = skill:GetId()

    -- 在执行技能前，检查棋子是否已被标记为删除
    local piece = context.piece or skill:GetPiece()
    if not piece or type(piece) ~= "table" then
        return false
    end

    -- 使用 rawget 绕过元表，安全访问可能已回池的对象
    local deletedFlag = rawget(piece, "_IsDeleted")

    if deletedFlag == nil then
        -- _IsDeleted 字段不存在，说明对象已回池或不是 XLuckyTenant2Piece
        return false
    end

    if deletedFlag then
        -- 棋子已标记删除，跳过执行
        return false
    end

    local executor = _SkillExecutors[skillType]
    if executor then
        context.skill = skill -- 确保skill在context中
        local result = executor(skill, context)

        -- 只打印成功执行的技能
        if result then
            local skillName = skill:GetName() or ""
            local pieceId = context.piece and context.piece:GetId() or 0
            local pieceName = context.piece and context.piece:GetName() or "未知"
            local x, y = 0, 0
            if context.piece then
                x, y = context.piece:GetPosition()
            end
            local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
            XMVCA.XLuckyTenant2:Print(string.format("【技能发动】%s (棋子: %s[ID:%d], %s, 技能ID:%d, 类型:%d)",
                skillName, pieceName, pieceId, posStr, skillId, skillType))
        end

        return result -- 返回技能执行器的实际结果
    else
        XLog.Warning("[SkillExecutor] 未实现的技能类型: " .. skillType)
        return false
    end
end

---获取技能执行器（用于测试或调试）
---@param skillType number 技能类型
---@return function|nil 执行函数
function SkillExecutor.GetExecutor(skillType)
    return _SkillExecutors[skillType]
end

-- ==================== 辅助函数 ====================

---验证技能执行参数
---@param piece XLuckyTenant2Piece|nil 棋子对象
---@param params table|nil 技能参数
---@param minParamCount number|nil 最小参数数量（默认1，0表示不需要参数）
---@return boolean 验证是否通过
local function ValidateSkillParams(piece, params, minParamCount)
    if piece == nil or params == nil then
        return false
    end
    if minParamCount == nil or minParamCount == 0 then
        return true -- 不需要参数验证
    end
    return #params >= minParamCount
end


---是否为道具棋子ID（刷新/删除道具），随机与消除逻辑中需排除
---@param pieceId number 棋子ID
---@return boolean 是道具则返回true
local function IsPropPieceId(pieceId)
    if not pieceId then
        return false
    end
    local PropId = XLuckyTenant2Enum.PropId
    return pieceId == PropId.RefreshProp or pieceId == PropId.DeleteProp
end

---根据品质获取宝盒棋子ID（辅助函数）
---@param model XLuckyTenant2Model 配置模型
---@param quality number 品质值
---@return number 宝盒棋子ID（如果没有找到则返回0）
local function GetBoxPieceIdByQuality(model, quality)
    if not model or not quality then
        return 0
    end

    -- 获取所有棋子配置
    local allChessConfigs = model:GetLuckyTenant2ChessConfigs()
    if not allChessConfigs then
        return 0
    end

    -- 筛选出同品质的宝盒棋子（Type=Box），排除道具
    local PieceType = XLuckyTenant2Enum.PieceType
    local candidates = {}
    for _, config in pairs(allChessConfigs) do
        if config and config.Quality == quality and config.Type == PieceType.Box and not IsPropPieceId(config.Id) then
            table.insert(candidates, config.Id)
        end
    end

    if #candidates == 0 then
        return 0
    end

    -- 随机选择一个同品质的宝盒棋子
    local randomIndex = math.random(1, #candidates)
    return candidates[randomIndex]
end

---光环类 value 增益：按 skillKey 存储，RefreshBondLevels 时会 ResetBondValueDeltas 回退，仅用于「羁绊等级/棋盘状态」变化需重算的技能（如 Type103/105 基础/消除加成）
local function UpdateBondBaseDelta(piece, delta, skillKey)
    if delta ~= 0 then
        piece:ApplyBondBaseValueDelta(skillKey, delta)
        return true
    end
    piece:ApplyBondBaseValueDelta(skillKey, 0)
    return false
end

---光环类消除价值增益：同上，用于「被消除时金币」的羁绊加成（Type103/105/204），会随 ResetBondValueDeltas 回退
local function UpdateBondDeletionDelta(piece, delta, skillKey)
    if delta ~= 0 then
        piece:ApplyBondDeletionValueDelta(skillKey, delta)
        return true
    end
    piece:ApplyBondDeletionValueDelta(skillKey, 0)
    return false
end

-- ==================== 技能类型执行函数 ====================
-- 按照技能类型编号顺序定义
-- 注意：Type 1-27 已废弃，配置表中不再使用，相关执行器已删除

-- ==================== 角色羁绊技能（Type301-Type306）====================

---技能类型301：倒计时（被动）- 每N回合等级+M（SkillMode=1: 升级等级模式, SkillMode=2: 减少倒计时模式）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type301] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    -- XMVCA.XLuckyTenant2:Print("[Type301] 开始执行，技能ID:", skill:GetId(), "棋子ID:", piece and piece:GetId() or "nil")

    if not ValidateSkillParams(piece, params, 2) then
        -- XMVCA.XLuckyTenant2:Print("[Type301] 参数验证失败")
        return false
    end

    local skillMode = skill:GetSkillMode()
    if skillMode == 0 then
        skillMode = 1
    end
    -- XMVCA.XLuckyTenant2:Print("[Type301] SkillMode:", skillMode, "Params:", params[1], params[2], params[3])

    if skillMode == 1 then
        -- SkillMode=1: 升级等级模式（每N回合等级+M，上限从配置读取）
        local rounds = params[1] or 0     -- 每N回合
        local levelDelta = params[2] or 0 -- 等级+M
        -- 使用缓存的角色等级上限（从配置表params[3]读取）
        local maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()

        -- XMVCA.XLuckyTenant2:Print("[Type301-Mode1] rounds:", rounds, "levelDelta:", levelDelta, "maxLevel:", maxLevel)

        if rounds <= 0 or levelDelta <= 0 then
            -- XMVCA.XLuckyTenant2:Print("[Type301-Mode1] 参数无效，rounds或levelDelta<=0")
            return false
        end
        -- 检查当前等级是否已达到上限
        local currentLevel = piece:GetLevel() or 0
        -- XMVCA.XLuckyTenant2:Print("[Type301-Mode1] 当前等级:", currentLevel, "上限等级:", maxLevel)
        if currentLevel >= maxLevel then
            -- XMVCA.XLuckyTenant2:Print("[Type301-Mode1] 已达到上限，不再升级")
            return false -- 已达到上限，不再升级
        end
        -- 检查是否有Type301-Mode2技能或Type303技能（减少倒计时上限）（从 bonds 获取技能）
        local actualRounds = rounds
        local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
        for _, otherSkill in ipairs(skills) do
            -- 检查Type301-Mode2技能
            if otherSkill:GetType() == SkillType.Type301 and otherSkill:GetSkillMode() == 2 then
                local reduceRounds = otherSkill:GetParams()[1] or 0
                if reduceRounds > 0 then
                    actualRounds = math.max(1, rounds - reduceRounds) -- 至少为1
                    -- XMVCA.XLuckyTenant2:Print("[Type301-Mode1] 检测到Type301-Mode2技能，减少倒计时上限从", rounds, "到", actualRounds)
                end
            end
            -- 检查Type303技能（替换301技能，减少倒计时）
            if otherSkill:GetType() == SkillType.Type303 then
                local reduceRounds = otherSkill:GetParams()[1] or 0
                if reduceRounds > 0 then
                    actualRounds = math.max(1, rounds - reduceRounds) -- 至少为1
                    XMVCA.XLuckyTenant2:Print("[Type301-Mode1] 检测到Type303技能，减少倒计时上限从", rounds, "到", actualRounds)
                end
            end
        end

        local TriggerState = XLuckyTenant2Enum.TriggerState

        -- 获取升级状态
        local upgradeState = piece:GetState(TriggerState.Upgrade)
        -- 如果没有升级状态，创建状态（倒计时为actualRounds）
        if not upgradeState then
            context.proxy:ApplyState(piece, TriggerState.Upgrade, skill:GetId(), actualRounds)
            return true
        end
        -- 如果状态倒计时为1（下一回合结束时会被移除），触发升级并重置状态
        local remainRounds = upgradeState:GetRemainRounds()
        if remainRounds <= 1 then
            -- 检查是否已在本回合为这个棋子触发过升级（防止一回合内重复升级）
            -- 使用MarkRoundSkillExecuted，标记在整个回合内有效
            -- 使用 pieceUid + skillId 作为key，确保不同技能的防重复标记不会互相影响
            local pieceUid = piece:GetUid()
            local skillId = skill:GetId()
            local markKey = pieceUid .. "_" .. skillId
            local alreadyExecuted = context.proxy:MarkRoundSkillExecuted(markKey)

            if alreadyExecuted then
                return false -- 已在本回合执行过
            end
            -- 计算实际可增加的等级（不超过上限）
            local actualDelta = math.min(levelDelta, maxLevel - currentLevel)
            if actualDelta > 0 then
                -- ModifyPieceLevel会自动标记"刚升级"（Upgrade状态倒计时设为0）
                -- 供Type504等技能检测，无需在这里手动标记
                context.proxy:ModifyPieceLevel(piece, actualDelta)
                return true
            end
        end
    elseif skillMode == 2 then
        -- SkillMode=2: 减少倒计时上限模式（这是一个被动效果，不需要执行逻辑）
        -- Type301-Mode2的效果已经在Type301-Mode1中处理（减少倒计时上限）
        -- 这里不需要执行任何逻辑，返回false表示不执行
        -- XMVCA.XLuckyTenant2:Print("[Type301-Mode2] 这是被动效果，不需要执行")
        return false
    else
        -- XMVCA.XLuckyTenant2:Print("[Type301] 未知的SkillMode:", skillMode)
    end

    -- XMVCA.XLuckyTenant2:Print("[Type301] 执行失败或无需执行")
    return false
end

---技能类型302：属性（被动）- 等级关联金币
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type302] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查是否已在本回合执行过（防止同一回合内多次循环重复执行）
    local pieceUid = piece:GetUid()
    if context.proxy:MarkRoundSkillExecuted(pieceUid) then
        return false -- 已在本回合执行过
    end

    local divisor = params[1] or 1       -- 每N个等级
    local valuePerLevel = params[2] or 0 -- 每N个等级增加M金币

    if divisor <= 0 or valuePerLevel <= 0 then
        return false
    end

    -- 计算当前等级应该增加的value总量
    local currentLevel = piece:GetLevel() or 0
    local targetValue = math.floor(currentLevel / divisor) * valuePerLevel

    -- 获取初始value
    local initialValue = piece:GetInitialValue() or 0

    -- 计算目标总value（初始value + Type302应该增加的value）
    local targetTotalValue = initialValue + targetValue

    -- 获取当前value
    local currentValue = piece:GetBaseValue() or 0

    -- 计算需要增加的value（目标总value - 当前value）
    local valueToAdd = targetTotalValue - currentValue

    -- 只有在需要增加value时才执行
    if valueToAdd > 0 then
        piece:AddValue(valueToAdd)
        return true
    end

    return false
end

---技能类型303：倒计时（技能）- 角色升级倒计时减少（替换301技能）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type303] = function(skill, context)
    -- Type303是"被动效果"，它的作用是减少Type301的倒计时上限（例如从4回合减少到3回合）
    -- Type303本身不执行任何操作，它的效果已经在Type301中通过检查技能并计算actualRounds来实现
    -- 如果Type303每回合都执行减少倒计时，会导致双重减少（系统自动-1 + Type303再-1 = 每回合-2），
    -- 这会让倒计时过快到期，导致每回合都升级的bug

    -- Type303作为被动效果，不需要执行任何操作，返回false
    return false
end

---技能类型304：消除（技能）- 可发动消除（配合305和306）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type304] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    XMVCA.XLuckyTenant2:Print(string.format("[Type304] 开始执行: 棋子=%s[ID:%d,UID:%d], 技能ID:%d",
        piece:GetName() or "未知", piece:GetId(), piece:GetUid(), skill:GetId()))

    if not ValidateSkillParams(piece, params, 3) then
        XMVCA.XLuckyTenant2:Print("[Type304] 参数验证失败")
        return false
    end

    -- 检查是否已执行（基于棋子UID+skillId，在整个回合内有效）
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        XMVCA.XLuckyTenant2:Print(string.format("[Type304] 已执行过，跳过: markKey=%s", markKey))
        return false -- 已执行过
    end

    -- 检查棋子是否有305和306技能（通过技能类型检查，从 bonds 获取）
    local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
    local hasSkill305 = false
    local hasSkill306 = false
    local skill305Params = nil
    local skill306Params = nil

    for _, s in ipairs(skills) do
        local skillType = s:GetType()
        if skillType == SkillType.Type305 then
            hasSkill305 = true
            skill305Params = s:GetParams()
        elseif skillType == SkillType.Type306 then
            hasSkill306 = true
            skill306Params = s:GetParams()
        end
    end

    -- 优先级：306 > 305 > 304基础
    local eliminateCount = 0
    local range = "adjacent" -- "adjacent" 或 "sameRowCol"

    if hasSkill306 and skill306Params and #skill306Params >= 1 then
        -- 检查306条件：等级是否为N的倍数
        local currentLevel = piece:GetLevel() or 0
        local divisor = skill306Params[1] or 1
        if currentLevel % divisor == 0 then
            -- 使用306的参数和范围（同行同列）
            eliminateCount = skill306Params[2] or params[1] or 1
            range = "sameRowCol"
        else
            -- 条件不满足，检查305
            if hasSkill305 and skill305Params and #skill305Params >= 1 then
                eliminateCount = skill305Params[1] or params[1] or 1
                range = "adjacent"
            else
                eliminateCount = params[1] or 1
                range = "adjacent"
            end
        end
    elseif hasSkill305 and skill305Params and #skill305Params >= 1 then
        -- 使用305的参数（覆盖304的Params[0]）
        eliminateCount = skill305Params[1] or params[1] or 1
        range = "adjacent"
    else
        -- 使用304基础参数
        eliminateCount = params[1] or 1
        range = "adjacent"
    end

    -- 获取可消除的棋子列表
    local candidatePieces = {}
    if range == "sameRowCol" then
        -- 同行同列
        candidatePieces = context.board:GetSameRowColPieces(piece)
    else
        -- 相邻（九宫格）
        candidatePieces = context.proxy:GetAdjacentPieces(piece)
    end

    -- 过滤出可消除的棋子
    local eliminatablePieces = {}
    XMVCA.XLuckyTenant2:Print(string.format("[Type304] 棋子UID:%d, 相邻棋子数:%d, 消除数量:%d, 范围:%s",
        piece:GetUid(), #candidatePieces, eliminateCount, range))

    for _, targetPiece in ipairs(candidatePieces) do
        local pieceId = targetPiece and targetPiece:GetId()
        if pieceId and pieceId > 0 and not IsPropPieceId(pieceId) then
            local canBeEliminated = context.model:GetLuckyTenant2ChessCanBeEliminatedById(pieceId)
            XMVCA.XLuckyTenant2:Print(string.format("[Type304] 检查棋子ID:%d, CanBeEliminated:%s",
                pieceId, tostring(canBeEliminated)))
            if canBeEliminated then
                table.insert(eliminatablePieces, targetPiece)
            end
        end
    end

    XMVCA.XLuckyTenant2:Print(string.format("[Type304] 可消除棋子数:%d", #eliminatablePieces))

    if #eliminatablePieces == 0 then
        XMVCA.XLuckyTenant2:Print("[Type304] 没有可消除的棋子，返回false")
        return false -- 没有可消除的棋子
    end

    -- 随机选择要消除的棋子
    local eliminatedPieces = {}
    local countToEliminate = math.min(eliminateCount, #eliminatablePieces)

    -- 使用Lua的随机数生成器（注意：需要初始化随机种子）
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

    -- 如果有305，执行鞭尸（对每个被消除的棋子执行多次DeletePiece）
    if hasSkill305 and skill305Params and #skill305Params >= 2 then
        local whipCount = skill305Params[2] or 1 -- 鞭尸次数
        XMVCA.XLuckyTenant2:Print(string.format("[Type304] 执行鞭尸，次数:%d", whipCount))
        for _, targetPiece in ipairs(eliminatedPieces) do
            for i = 1, whipCount do
                -- 每鞭尸一次，计算一次数值
                context.proxy:DeletePiece(targetPiece, piece)
                -- 动画：抖动效果（由Operation系统处理）
            end
        end
    else
        -- 没有305，直接删除
        XMVCA.XLuckyTenant2:Print(string.format("[Type304] 执行消除，数量:%d", #eliminatedPieces))
        for _, targetPiece in ipairs(eliminatedPieces) do
            XMVCA.XLuckyTenant2:Print(string.format("[Type304] 消除棋子: ID:%d, UID:%d",
                targetPiece:GetId(), targetPiece:GetUid()))
            context.proxy:DeletePiece(targetPiece, piece)
        end
    end

    -- 每成功消除N个，等级+M（不超过角色等级上限）
    local eliminateForLevel = params[2] or 1 -- 每成功消除N个
    local levelDelta = params[3] or 1        -- 等级+M
    local successCount = #eliminatedPieces

    if successCount >= eliminateForLevel then
        local levelIncrease = math.floor(successCount / eliminateForLevel) * levelDelta
        if levelIncrease > 0 then
            -- 检查等级上限（角色羁绊棋子使用缓存的上限）
            local currentLevel = piece:GetLevel() or 0
            local maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()
            local actualIncrease = math.min(levelIncrease, maxLevel - currentLevel)
            if actualIncrease > 0 then
                context.proxy:ModifyPieceLevel(piece, actualIncrease)
                XMVCA.XLuckyTenant2:Print(string.format("[Type304] 角色升级:%d", actualIncrease))
            end
        end
    end

    XMVCA.XLuckyTenant2:Print("[Type304] 执行成功")
    return true
end

---技能类型305：消除（技能）- 鞭尸增强（配合304）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type305] = function(skill, context)
    -- Type305和Type306只作为标记，不独立执行
    -- 实际逻辑在Type304中处理
    return false
end

---技能类型306：消除（技能）- 范围扩大增强（配合304）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type306] = function(skill, context)
    -- Type305和Type306只作为标记，不独立执行
    -- 实际逻辑在Type304中处理
    return false
end

-- ==================== 金融羁绊技能（Type101-Type105）====================

---技能类型103：金融羁绊lv.1 - 基础金币额外+N；被消除金币+N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type103] = function(skill, context)
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
end

---技能类型105：金融羁绊lv.3 - 基础金币+N，被消除金币*倍数
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type105] = function(skill, context)
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
end

---技能类型101：金融被动01（被动）- 金融只有被感染时，才会产生金币，且只在相邻空位产生Params[3]枚金币
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type101] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    local skillId = skill:GetId()

    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查棋子是否被感染（只有被感染时才产生金币）
    local TriggerState = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum").TriggerState
    local hasInfection = piece:HasState(TriggerState.Infection)
    if not hasInfection then
        return false -- 未被感染，不产生金币
    end

    local rounds = params[1] or 0  -- 每N回合
    local pieceId = params[2] or 0 -- 产生的金币棋子ID
    local amount = params[3] or 1  -- 产生的数量（Params[3]）

    if rounds <= 0 or pieceId <= 0 then
        return false
    end

    local productionState = piece:GetState(TriggerState.Production)

    -- 如果没有Production状态，创建一个（初始倒计时=rounds）
    if not productionState then
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false -- 刚创建状态，不执行生产
    end

    -- 检查倒计时是否为1（即将在本回合结束时过期）
    local remainRounds = productionState:GetRemainRounds()
    if remainRounds ~= 1 then
        return false -- 倒计时未到，不执行
    end

    -- 倒计时到期，执行生产逻辑
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false -- 已在本回合执行过
    end

    -- 获取相邻空位
    local emptyPositions = context.proxy:GetAdjacentEmptyPositions()
    if #emptyPositions == 0 then
        -- 重置倒计时（即使没有空位也重置）
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false -- 没有空位
    end

    -- 在相邻空位产生金币棋子（最多产生amount个，使用Params[3]）
    local created = 0
    for i = 1, math.min(amount, #emptyPositions) do
        local pos = emptyPositions[i]
        context.proxy:AddNewPiece(pieceId, pos[1], pos[2])
        created = created + 1
    end

    -- 重置倒计时
    context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)

    return created > 0
end

-- ==================== 状态技能（Type102-Type508）====================

---技能类型102：金融状态技能（被传染）- 状态技能，不执行，主要通过101来实现
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type102] = function(skill, context)
    -- Type102是状态技能，不执行任何逻辑，主要通过Type101来实现产生金币的功能
    -- Type101会检查棋子是否有感染状态（Type102对应的状态），如果被感染则产生金币
    return false
end

---技能类型202：怪物被动02（被动）- 相邻无空位时，不生成子虫，基础金币+N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type202] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    local valueDelta = params[1] or 0 -- 增加的基础金币

    if valueDelta <= 0 then
        return false
    end

    -- 检查相邻是否有空位
    local emptyPositions = context.proxy:GetAdjacentEmptyPositions()

    -- 如果相邻无空位，增加基础金币
    if #emptyPositions == 0 then
        -- 检查是否已在本回合执行过（防止同一回合内多次循环重复执行）
        -- 使用 pieceUid + skillId 作为key，确保不同技能的防重复标记不会互相影响
        local pieceUid = piece:GetUid()
        local skillId = skill:GetId()
        local markKey = pieceUid .. "_" .. skillId
        if context.proxy:MarkRoundSkillExecuted(markKey) then
            return false -- 已在本回合执行过
        end

        context.proxy:ModifyPieceValue(piece, valueDelta)
        return true
    end

    return false
end

---技能类型208：子虫技能02（死亡传染）- 子虫死亡时可传染相邻棋子（传染逻辑在 XLuckyTenant2OnDeleteEffects）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type208] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end
    local TriggerState = XLuckyTenant2Enum.TriggerState
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
end

---技能类型209：怪物状态技能01（倒计时）- 每N回合在相邻空位产生子虫
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type209] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    local rounds = params[1] or 0  -- 每N回合
    local amount = params[2] or 1  -- 产生数量
    local pieceId = params[3] or 0 -- 产生的子虫棋子ID

    if rounds <= 0 or pieceId <= 0 then
        return false
    end

    local TriggerState = XLuckyTenant2Enum.TriggerState
    local productionState = piece:GetState(TriggerState.Production)

    -- 如果没有Production状态，创建一个（初始倒计时=rounds）
    if not productionState then
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false -- 刚创建状态，不执行生产
    end

    -- 检查倒计时是否为1（即将在本回合结束时过期）
    local remainRounds = productionState:GetRemainRounds()
    if remainRounds ~= 1 then
        return false -- 倒计时未到，不执行
    end

    -- 倒计时到期，执行生产逻辑
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId

    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false -- 已在本回合执行过
    end

    -- 获取相邻空位
    local emptyPositions = context.proxy:GetAdjacentEmptyPositions()
    if #emptyPositions == 0 then
        -- 重置倒计时（即使没有空位也重置）
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false -- 没有空位
    end

    -- 获取技能210的ID和参数（用于给子虫添加死亡状态）
    local model = context.model
    local skill210Id = nil
    local deathRounds = 2 -- 默认2回合
    if model then
        local bugChessConfig = model:GetLuckyTenant2ChessConfigById(pieceId)
        if bugChessConfig and bugChessConfig.StateSkillId then
            local stateSkillIds = bugChessConfig.StateSkillId
            if type(stateSkillIds) == "table" then
                for _, stateSkillId in ipairs(stateSkillIds) do
                    if stateSkillId and stateSkillId > 0 then
                        local actualSkillId, skillConfig = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
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

    -- 在相邻空位产生子虫（最多产生amount个）
    local created = 0
    for i = 1, math.min(amount, #emptyPositions) do
        local pos = emptyPositions[i]
        context.proxy:AddNewPieceWithDeathSkill(pieceId, pos[1], pos[2], skill210Id, deathRounds)
        created = created + 1
    end

    -- 重置倒计时
    context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)

    return created > 0
end

---技能类型405：武器状态技能（被传染）- 被感染后可融合相邻武器
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type405] = function(skill, context)
    -- Type405是被动效果，实际融合逻辑应该在武器融合相关逻辑中处理
    -- 这里只返回true表示状态已应用
    return true
end

---技能类型404：武器羁绊lv.2（技能）- 可被传染（标记技能）
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type404] = function(skill, context)
    -- Type404为标记技能，用于开启武器可被传染的展示
    return true
end

---技能类型502：宝盒被动02（被动）- 宝盒死亡后，原地产生1个宝盒
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type502] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查棋子类型是否为宝盒
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Box then
        return false
    end

    local probabilityOriginal = params[1] or 70 -- 原品质概率（默认70%）
    local probabilityUpgrade = params[2] or 30  -- 品质+1概率（默认30%）

    local TriggerState = XLuckyTenant2Enum.TriggerState
    local deathState = piece:GetState(TriggerState.Death)

    -- 获取棋子信息
    local pieceId = piece:GetId()
    local pieceName = piece:GetName() or "未知"
    local pieceUid = piece:GetUid()
    local x, y = piece:GetPosition()
    local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"

    XMVCA.XLuckyTenant2:Print(string.format("[Type502] 执行检查: 棋子=%s[ID:%d,UID:%d], %s, 死亡状态存在=%s, 过期状态触发=%s",
        pieceName, pieceId, pieceUid, posStr, tostring(deathState ~= nil), tostring(context.isExpiredStateSkill == true)))

    -- Type502是被动技能，只在宝盒真正死亡时触发（即过期状态触发时）
    if not context.isExpiredStateSkill then
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 不是过期状态触发，跳过"))
        return false
    end

    -- 获取棋子位置
    if not x or not y or x <= 0 or y <= 0 then
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 棋子位置无效: x=%s, y=%s", tostring(x), tostring(y)))
        return false -- 没有位置信息
    end

    -- 获取棋子品质
    local currentQuality = piece:GetQuality()
    if not currentQuality or currentQuality <= 0 then
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 棋子品质无效: %s", tostring(currentQuality)))
        return false
    end

    -- 根据概率决定新宝盒的品质
    local random = math.random(1, 100)
    local newQuality = currentQuality

    if random <= probabilityOriginal then
        -- 原品质
        newQuality = currentQuality
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 随机=%d, 保持原品质=%d", random, newQuality))
    elseif random <= probabilityOriginal + probabilityUpgrade then
        -- 品质+1，但不能超过最高品质
        local maxQuality = 5 -- 最高品质为5（橙色）
        newQuality = math.min(currentQuality + 1, maxQuality)
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 随机=%d, 品质提升: %d -> %d (最高=%d)",
            random, currentQuality, newQuality, maxQuality))
    else
        -- 其他情况保持原品质
        newQuality = currentQuality
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 随机=%d, 保持原品质=%d", random, newQuality))
    end

    -- 获取新宝盒的棋子ID（根据品质）
    local newPieceId = GetBoxPieceIdByQuality(context.model, newQuality)
    if not newPieceId or newPieceId <= 0 then
        -- 如果按品质找不到，尝试获取当前棋子的ID作为备用
        newPieceId = pieceId
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 按品质找不到宝盒，使用当前棋子ID: %d", newPieceId))
    else
        XMVCA.XLuckyTenant2:Print(string.format("[Type502] 找到品质=%d的宝盒ID: %d", newQuality, newPieceId))
    end

    -- 先删除当前宝盒，再在当前位置产生新宝盒
    XMVCA.XLuckyTenant2:Print(string.format("[Type502] 删除旧宝盒[UID:%d]，在%s产生新宝盒[ID:%d,品质:%d]",
        pieceUid, posStr, newPieceId, newQuality))
    context.proxy:DeletePiece(piece)
    context.proxy:AddNewPiece(newPieceId, x, y)

    XMVCA.XLuckyTenant2:Print(string.format("[Type502] 成功：原品质=%d, 新品质=%d, 随机数=%d",
        currentQuality, newQuality, random))

    return true
end

---技能类型506：宝盒状态技能02（被传染）- 感染后宝盒倒计时-N，死亡时只产出同品质怪物棋子
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
---技能类型506：宝盒状态技能02（被传染）- 感染状态标记，实际效果由Type508处理
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type506] = function(skill, context)
    -- Type506只是一个状态标记，不执行任何逻辑
    -- 实际的感染效果（减少倒计时、只产出侵蚀、概率产出红雾）由Type508处理
    return true
end


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
        if config and config.Quality == quality and config.Type ~= XLuckyTenant2Enum.PieceType.Box and not IsPropPieceId(config.Id) then
            table.insert(candidates, config.Id)
        end
    end

    if #candidates == 0 and quality > 1 then
        return GetRandomChessIdByQuality(model, quality - 1)
    end

    if #candidates == 0 then
        for _, config in pairs(allChessConfigs) do
            if config and config.Type ~= XLuckyTenant2Enum.PieceType.Box and not IsPropPieceId(config.Id) then
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
        if config and config.Quality == quality and config.Type == pieceType and not IsPropPieceId(config.Id) then
            table.insert(candidates, config.Id)
        end
    end

    if #candidates == 0 then
        return 0
    end

    local randomIndex = math.random(1, #candidates)
    return candidates[randomIndex]
end

---技能类型508：宝盒状态技能01（倒计时）- N回合后死亡并在相邻产生棋子
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type508] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查棋子类型是否为宝盒
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Box then
        return false
    end

    local rounds = params[1] or 0      -- 死亡倒计时回合
    local amount = params[2] or 1      -- 产生数量
    local noEmptyGold = params[3] or 0 -- 无空位加金币数量

    if rounds <= 0 then
        return false
    end

    local TriggerState = XLuckyTenant2Enum.TriggerState
    local deathState = piece:GetState(TriggerState.Death)

    -- 获取棋子信息
    local pieceId = piece:GetId()
    local pieceName = piece:GetName() or "未知"
    local x, y = piece:GetPosition()
    local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"

    -- 检查死亡状态是否倒计时为0（由Type504等技能减少到0）
    local isCountdownZero = deathState and deathState:GetRemainRounds() <= 0

    -- 如果死亡状态不存在，有两种情况：
    -- 1. 初始化时：还没有死亡状态，需要应用
    -- 2. 状态已过期被移除：需要执行死亡逻辑（产生棋子/金币，删除宝盒）
    -- 3. 倒计时为0（由其他技能减少到0）：需要执行死亡逻辑
    if not deathState or isCountdownZero then
        -- 如果这是通过过期状态技能触发的，或者倒计时为0，应该执行死亡逻辑
        if context.isExpiredStateSkill == true or isCountdownZero then
            if isCountdownZero then
                -- 移除死亡状态，避免重复触发
                piece:RemoveState(TriggerState.Death)
            end

            -- 检查宝盒是否有Type502技能（宝盒被动02：消失后原地产生新宝盒，从 bonds 获取）
            local hasType502 = false
            local type502Skill = nil
            local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
            for _, s in ipairs(skills) do
                if s:GetType() == SkillType.Type502 then
                    hasType502 = true
                    type502Skill = s
                    XMVCA.XLuckyTenant2:Print(string.format("[Type508] 检测到Type502技能（宝盒被动02），将在原地产生新宝盒"))
                    break
                end
            end

            -- 如果有Type502技能，先执行Type502逻辑：在原地产生新宝盒
            if hasType502 and type502Skill then
                -- 执行Type502逻辑：在原地产生新宝盒（可能品质提升）
                local type502Params = type502Skill:GetParams() or {}
                local probabilityOriginal = type502Params[1] or 70 -- 原品质概率（默认70%）
                local probabilityUpgrade = type502Params[2] or 30  -- 品质+1概率（默认30%）

                local currentQuality = piece:GetQuality()
                local random = math.random(1, 100)
                local newQuality = currentQuality

                if random <= probabilityOriginal then
                    newQuality = currentQuality
                elseif random <= probabilityOriginal + probabilityUpgrade then
                    local maxQuality = 5
                    newQuality = math.min(currentQuality + 1, maxQuality)
                else
                    newQuality = currentQuality
                end

                local newPieceId = GetBoxPieceIdByQuality(context.model, newQuality)
                if not newPieceId or newPieceId <= 0 then
                    newPieceId = pieceId
                end

                -- 创建新宝盒
                local bag = context.game:GetBag()
                local board = context.game:GetChessBoard()
                if bag and board then
                    -- 先保存旧棋子状态（删除前读取），并标记删除，再移除棋盘/背包，避免访问已回收对象
                    local oldInfectionState = context.piece:GetState(TriggerState.Infection)
                    context.proxy:MarkPieceForDeletion(piece)
                    piece:MarkAsDeleted()
                    local oldUid = piece:GetUid()
                    local newUid = bag:GetNewUid()
                    local newPiece = bag:NewPiece(context.model, newPieceId, newUid)
                    if newPiece then
                        bag:AddPiece(newPiece)
                        board:RemovePieceByPosition(x, y)
                        bag:DeletePieceByUid(oldUid)
                        board:SetPieceByPosition(newPiece, x, y)

                        local verifyPiece = board:GetPieceByPosition(x, y)
                        if not (verifyPiece and verifyPiece:GetUid() == newPiece:GetUid()) then
                            XMVCA.XLuckyTenant2:Print(string.format("[Type508] ❌ 错误：新宝盒放置失败！位置(%d,%d)", x, y))
                        end

                        -- 原地生成新宝盒不经过 Operation，需补一条生成动画
                        context.proxy:AddExtraAnimation({
                            type = XLuckyTenant2Enum.AnimationType.AddPiece,
                            pieceId = newPieceId,
                            x = x,
                            y = y,
                        })

                        if oldInfectionState then
                            local oldInfectionSkillId = oldInfectionState:GetSkillId()
                            context.proxy:ApplyState(newPiece, TriggerState.Infection, oldInfectionSkillId, -1)
                        end

                        -- 更新piece引用为新宝盒，以便后续Type508逻辑使用新宝盒的位置
                        piece = newPiece

                        local reduceRounds = 0
                        -- 使用删除前保存的感染状态，避免访问已回收的 context.piece
                        if oldInfectionState and context.model then
                            local infectionSkillId = oldInfectionState:GetSkillId()
                            local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(infectionSkillId)

                            if stateSkillConfig and stateSkillConfig.Type == SkillType.Type506 then
                                local skills = (context.game and context.piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(context.piece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
                                for _, s in ipairs(skills) do
                                    if s:GetType() == SkillType.Type505 then
                                        local type505Params = s:GetParams() or {}
                                        local type505Reduce = type505Params[1] or 0
                                        reduceRounds = reduceRounds + type505Reduce
                                        break
                                    end
                                end
                            end
                        end

                        local bondIdStr = newPiece:GetBondId()
                        if bondIdStr and bondIdStr ~= "" and context.game then
                            local bondManager = context.game:GetBondManager()
                            if bondManager then
                                for bondIdPart in string.gmatch(bondIdStr, "([^|]+)") do
                                    local bondId = tonumber(bondIdPart)
                                    if bondId then
                                        local bond = bondManager:GetBond(bondId)
                                        if bond then
                                            local bondLevel = bond:GetLevel()
                                            if bondLevel > 0 then
                                                local bondSkillConfigs = context.model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
                                                for _, bondSkillConfig in ipairs(bondSkillConfigs) do
                                                    local skillId = bondSkillConfig.SkillId
                                                    if type(skillId) == "table" then
                                                        skillId = skillId[1] or 0
                                                    end
                                                    if skillId and skillId > 0 then
                                                        local skillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(skillId)
                                                        if skillConfig and skillConfig.Type == SkillType.Type503 then
                                                            local params = skillConfig.Params or {}
                                                            local reduce = params[1] or 0
                                                            reduceRounds = reduceRounds + reduce
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        local finalRounds = math.max(1, rounds - reduceRounds)
                        context.proxy:ApplyState(newPiece, TriggerState.Death, skill:GetId(), finalRounds)
                    else
                        XMVCA.XLuckyTenant2:Print(string.format("[Type508] ❌ 错误：创建新宝盒失败，ID=%d", newPieceId))
                    end
                else
                    XMVCA.XLuckyTenant2:Print("[Type508] ❌ 错误：背包或棋盘不存在")
                end
            end

            if hasType502 then
                context.proxy.Piece = piece
            end

            local emptyPositions = context.proxy:GetAdjacentEmptyPositions()

            if #emptyPositions > 0 then
                local pieceQuality = piece:GetQuality()
                local targetPieceType = nil
                local redTideProbability = 0
                local redTidePieceId = 0

                local checkPiece = hasType502 and context.piece or piece
                local infectionState = checkPiece:GetState(TriggerState.Infection)

                if infectionState and context.model then
                    local infectionSkillId = infectionState:GetSkillId()
                    local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(infectionSkillId)

                    if stateSkillConfig and stateSkillConfig.Type == SkillType.Type506 then
                        local skills = (context.game and checkPiece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(checkPiece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
                        for _, s in ipairs(skills) do
                            if s:GetType() == SkillType.Type505 then
                                targetPieceType = XLuckyTenant2Enum.PieceType.Monster
                                local type505Params = s:GetParams() or {}
                                redTideProbability = type505Params[2] or 0
                                redTidePieceId = type505Params[3] or 0
                                XMVCA.XLuckyTenant2:Print(string.format("[Type508] ✅ 检测到Type505，产出侵蚀棋子，红雾概率=%d%%", redTideProbability))
                                break
                            end
                        end

                        if not targetPieceType then
                            XMVCA.XLuckyTenant2:Print("[Type508] ⚠️ 有Type506感染但没有Type505技能")
                        end
                    end
                end

                local created = 0
                for i = 1, math.min(amount, #emptyPositions) do
                    local pos = emptyPositions[i]
                    local randomPieceId = 0
                    if targetPieceType then
                        randomPieceId = GetRandomChessIdByQualityAndType(context.model, pieceQuality, targetPieceType)
                        if randomPieceId <= 0 then
                            XMVCA.XLuckyTenant2:Print("[Type508] ⚠️ 按类型找不到棋子，降级为任意类型")
                            randomPieceId = GetRandomChessIdByQuality(context.model, pieceQuality)
                        end
                    else
                        randomPieceId = GetRandomChessIdByQuality(context.model, pieceQuality)
                    end
                    if randomPieceId > 0 then
                        context.proxy:AddNewPiece(randomPieceId, pos[1], pos[2])
                        created = created + 1
                    end
                end

                if targetPieceType == XLuckyTenant2Enum.PieceType.Monster and redTideProbability > 0 and redTidePieceId > 0 then
                    local random = math.random(1, 100)
                    if random <= redTideProbability then
                        if created < #emptyPositions then
                            local pos = emptyPositions[created + 1]
                            XMVCA.XLuckyTenant2:Print(string.format("[Type508] ✅ 额外产出红雾: 位置=(%d,%d)", pos[1], pos[2]))
                            context.proxy:AddNewPiece(redTidePieceId, pos[1], pos[2])
                            created = created + 1
                        else
                            XMVCA.XLuckyTenant2:Print("[Type508] ⚠️ 无剩余空位产出红雾")
                        end
                    end
                end
                -- 如果没有Type502，删除宝盒（有Type502时新宝盒已在原地，不需要删除）
                if not hasType502 then
                    context.proxy:DeletePiece(piece)
                end
                return created > 0
            else
                if noEmptyGold > 0 then
                    context.proxy:ModifyPieceValue(piece, noEmptyGold)
                end
                if not hasType502 then
                    context.proxy:DeletePiece(piece)
                end
                return true
            end
        else
            local reduceRounds = 0
            local infectionState = piece:GetState(TriggerState.Infection)
            if infectionState and context.model then
                local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(infectionState:GetSkillId())
                if stateSkillConfig and stateSkillConfig.Type == SkillType.Type506 then
                    local params = stateSkillConfig.Params or {}
                    reduceRounds = reduceRounds + (params[1] or 0)
                end
            end
            local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
            for _, s in ipairs(skills) do
                if s:GetType() == SkillType.Type503 then
                    local params = s:GetParams() or {}
                    reduceRounds = reduceRounds + (params[1] or 0)
                end
            end
            local finalRounds = math.max(1, rounds - reduceRounds)
            context.proxy:ApplyState(piece, TriggerState.Death, skill:GetId(), finalRounds)
            return true
        end
    end

    return false
end

-- ==================== 怪物羁绊技能（Type201-Type209）====================

---技能类型201：怪物被动01（被动）- 每N回合在相邻空位产生子虫
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type201] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 3) then
        return false
    end

    local rounds = params[1] or 0     -- 每N回合
    local amount = params[2] or 1     -- 产生数量
    local bugPieceId = params[3] or 0 -- 子虫棋子ID

    if rounds <= 0 or bugPieceId <= 0 then
        return false
    end

    local TriggerState = XLuckyTenant2Enum.TriggerState
    local productionState = piece:GetState(TriggerState.Production)

    -- 如果没有Production状态，创建一个（初始倒计时=rounds）
    if not productionState then
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false -- 刚创建状态，不执行生产
    end

    -- 检查倒计时是否为1（即将在本回合结束时过期）
    local remainRounds = productionState:GetRemainRounds()
    if remainRounds ~= 1 then
        return false -- 倒计时未到，不执行
    end

    -- 倒计时到期，执行生产逻辑
    -- 检查是否已在本回合执行过（防止同一回合内多次循环重复执行）
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId

    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false -- 已在本回合执行过
    end

    -- 获取相邻空位
    local emptyPositions = context.proxy:GetAdjacentEmptyPositions()
    if #emptyPositions == 0 then
        -- 重置倒计时（即使没有空位也重置）
        context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)
        return false -- 没有空位
    end

    -- 获取技能210的ID和参数（用于给子虫添加死亡状态）
    local model = context.model
    local skill210Id = nil
    local deathRounds = 2 -- 默认2回合
    if model then
        local bugChessConfig = model:GetLuckyTenant2ChessConfigById(bugPieceId)
        if bugChessConfig and bugChessConfig.StateSkillId then
            local stateSkillIds = bugChessConfig.StateSkillId
            if type(stateSkillIds) == "table" then
                for _, stateSkillId in ipairs(stateSkillIds) do
                    if stateSkillId and stateSkillId > 0 then
                        local actualSkillId, skillConfig = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
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

    -- 在相邻空位产生子虫（最多产生amount个）
    local created = 0
    for i = 1, math.min(amount, #emptyPositions) do
        local pos = emptyPositions[i]
        context.proxy:AddNewPieceWithDeathSkill(bugPieceId, pos[1], pos[2], skill210Id, deathRounds)
        created = created + 1
    end

    -- 重置倒计时
    context.proxy:ApplyState(piece, TriggerState.Production, skill:GetId(), rounds)

    return created > 0
end

---技能类型203：怪物lv1（技能）- 子虫基础金币+N，消除金币+M
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type203] = function(skill, context)
    -- Type203是怪物羁绊技能，当怪物产生子虫时，给子虫增加基础金币和消除金币
    -- 实际逻辑在 XLuckyTenant2OperationAddNewPiece 中实现
    -- 当怪物通过Type201产生子虫时，会检查怪物是否有Type203技能
    -- 如果有，就给新产生的子虫设置增益：
    --   piece:SetBondValueDelta(key, baseValueDelta)        -- 基础金币
    --   piece:SetBondDeletionValueDelta(key, deletionValueDelta) -- 消除金币
    -- 这里返回 true 表示技能已激活，使其能在界面展示
    -- 参数：
    --   params[1] = 基础金币增加值（必须）
    --   params[2] = 子虫棋子ID（0表示所有子虫）
    --   params[3] = 消除金币增加值（可选）

    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    XMVCA.XLuckyTenant2:Print(string.format("[Type203] 开始执行: 棋子=%s[ID:%d,UID:%d], 技能ID:%d, Params:{%s}",
        piece:GetName() or "未知", piece:GetId(), piece:GetUid(), skill:GetId(),
        params and table.concat(params, ",") or "无"))

    -- 验证参数（至少需要2个参数）
    if not ValidateSkillParams(piece, params, 2) then
        XMVCA.XLuckyTenant2:Print("[Type203] 参数验证失败")
        return false
    end

    -- 检查棋子类型：Type203只能应用在怪物身上
    local PieceType = XLuckyTenant2Enum.PieceType
    local pieceType = piece:GetPieceType()
    XMVCA.XLuckyTenant2:Print(string.format("[Type203] 棋子类型检查: pieceType=%d, Monster=%d",
        pieceType, PieceType.Monster))

    if pieceType ~= PieceType.Monster then
        XMVCA.XLuckyTenant2:Print("[Type203] 棋子类型不是怪物，跳过")
        return false
    end

    local baseValueDelta = params[1] or 0     -- 基础金币增加值
    local deletionValueDelta = params[3] or 0 -- 消除金币增加值（可选）

    if baseValueDelta <= 0 and deletionValueDelta <= 0 then
        XMVCA.XLuckyTenant2:Print("[Type203] 两个delta都<=0，跳过")
        return false
    end

    -- Type203是被动技能，不需要在每回合执行逻辑
    -- 只需要返回true，使其出现在技能列表中，并在界面展示
    XMVCA.XLuckyTenant2:Print(string.format("[Type203] 技能激活成功: 棋子UID:%d, baseValueDelta=%d, deletionValueDelta=%d",
        piece:GetUid(), baseValueDelta, deletionValueDelta))
    return true
end

---技能类型204：怪物lv2（技能）- 当子虫、怪物在死亡或被消除时，额外得基础金币*N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type204] = function(skill, context)
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

    local PieceType = XLuckyTenant2Enum.PieceType
    local pieceId = piece:GetId()
    local isMonster = piece:GetPieceType() == PieceType.Monster
    local isBug = bugPieceId == 0 or bugPieceId == pieceId
    if not (isMonster or isBug) then
        return false
    end

    local baseValue = piece:GetBaseValue() or 0
    local delta = baseValue * multiplier
    return UpdateBondDeletionDelta(piece, delta, skill:GetId())
end

---技能类型205：怪物lv3（技能）- 子虫改为N回合后死亡
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type205] = function(skill, context)
    -- Type205是怪物羁绊技能，当怪物产生子虫时，修改子虫的死亡回合数
    -- 实际逻辑在 XLuckyTenant2OperationAddNewPiece 中实现
    -- 当怪物通过Type201产生子虫时，会检查怪物是否有Type205技能
    -- 如果有，就修改子虫的死亡倒计时回合数
    -- 这里返回 true 表示技能已激活，使其能在界面展示

    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    -- 验证参数
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    -- 检查棋子类型：Type205只能应用在怪物身上
    local PieceType = XLuckyTenant2Enum.PieceType
    if piece:GetPieceType() ~= PieceType.Monster then
        return false
    end

    local newDeathRounds = params[1] or 0 -- 新的死亡回合数
    if newDeathRounds < 0 then
        return false
    end

    -- Type205是被动技能，不需要在每回合执行逻辑
    -- 只需要返回true，使其出现在技能列表中，并在界面展示
    return true
end

---技能类型207：怪物lv4（技能）- 当子虫死亡或被消除时，可传染相邻棋子，每成功传染1枚+N金币收益
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type207] = function(skill, context)
    -- Type207是怪物羁绊技能，当怪物产生子虫时，给子虫赋予死亡传染技能（Type208）
    -- 实际逻辑在 XLuckyTenant2OperationAddNewPiece 中实现
    -- 当怪物通过Type201产生子虫时，会检查怪物是否有Type207技能
    -- 如果有，就给子虫赋予Type208技能，使其死亡时可以传染相邻棋子
    -- 这里返回 true 表示技能已激活，使其能在界面展示

    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()

    -- 验证参数
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    -- 检查棋子类型：Type207只能应用在怪物身上
    local PieceType = XLuckyTenant2Enum.PieceType
    if piece:GetPieceType() ~= PieceType.Monster then
        return false
    end

    local valuePerInfection = params[1] or 0 -- 每成功传染1枚获得的金币
    if valuePerInfection <= 0 then
        return false
    end

    -- Type207是被动技能，不需要在每回合执行逻辑
    -- 只需要返回true，使其出现在技能列表中，并在界面展示
    return true
end

---技能类型210：子虫技能01 - 存在N回合后死亡
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type210] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    local rounds = params[1] or 0 -- N回合后死亡

    if rounds <= 0 then
        return false
    end

    local TriggerState = XLuckyTenant2Enum.TriggerState

    -- 获取死亡状态
    local deathState = piece:GetState(TriggerState.Death)

    -- 获取棋子信息
    local pieceId = piece:GetId()
    local pieceName = piece:GetName() or "未知"
    local x, y = piece:GetPosition()
    local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"

    XMVCA.XLuckyTenant2:Print(string.format("[Type210] 执行检查: 棋子=%s[ID:%d], %s, 技能ID=%d, rounds=%d, 死亡状态存在=%s",
        pieceName, pieceId, posStr, skill:GetId(), rounds, tostring(deathState ~= nil)))

    -- 如果死亡状态不存在，有两种情况：
    -- 1. 初始化时：还没有死亡状态，需要应用
    -- 2. 状态已过期被移除：需要删除棋子
    -- 通过检查context中是否有标记来判断是否是过期状态触发的
    if not deathState then
        -- 如果这是通过过期状态技能触发的（说明状态刚被移除），应该删除棋子
        if context.isExpiredStateSkill == true then
            -- 状态已过期被移除，删除棋子
            XMVCA.XLuckyTenant2:Print(string.format("【倒计时死亡执行】Type210 - 子虫倒计时到期（状态已移除），删除棋子: %s[ID:%d], %s",
                pieceName, pieceId, posStr))
            context.proxy:DeletePiece(piece)
            return true
        else
            -- 初始化时，应用死亡状态
            XMVCA.XLuckyTenant2:Print(string.format("[Type210] 应用死亡状态: 棋子=%s[ID:%d], %s, 回合数=%d",
                pieceName, pieceId, posStr, rounds))
            context.proxy:ApplyState(piece, TriggerState.Death, skill:GetId(), rounds)
            return true
        end
    end

    -- 如果已有死亡状态，检查倒计时是否已过期（倒计时==0）
    if deathState then
        local remainRounds = deathState:GetRemainRounds()
        local isExpired = deathState:IsExpired()

        XMVCA.XLuckyTenant2:Print(string.format("[Type210] 检查死亡状态: 棋子=%s[ID:%d], %s, 剩余回合数=%d, 是否过期=%s",
            pieceName, pieceId, posStr, remainRounds, tostring(isExpired)))

        if isExpired then
            -- 删除棋子
            XMVCA.XLuckyTenant2:Print(string.format("【倒计时死亡执行】Type210 - 子虫倒计时到期，删除棋子: %s[ID:%d], %s",
                pieceName, pieceId, posStr))
            context.proxy:DeletePiece(piece)
            return true
        end

        -- 状态存在但未过期，不需要执行
        XMVCA.XLuckyTenant2:Print(string.format("[Type210] 状态未过期，不执行: 棋子=%s[ID:%d], %s, 剩余回合数=%d",
            pieceName, pieceId, posStr, remainRounds))
        return false
    end
end

-- ==================== 武器羁绊技能（Type401-Type407）====================

---技能类型401：武器被动01（被动）- 2个相同品质武器融合升品质
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type401] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 0) then
        return false
    end

    -- 检查棋子类型是否为武器
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Weapon then
        return false
    end

    -- 判断武器等级是否满级, 满级的情况下, 不再执行401技能
    local maxLevel = params[1] or XLuckyTenant2Enum.GameConstants.MAX_PIECE_LEVEL
    if piece:GetLevel() >= maxLevel then
        return false
    end

    -- 检查是否已在本回合执行过（防止同一回合内多次融合）
    -- 使用 pieceUid + skillId 作为key，确保不同技能的防重复标记不会互相影响
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false -- 已在本回合执行过
    end

    -- 检查是否有Type403技能（可以融合武器碎片，从 bonds 获取）
    local hasType403 = false
    local type403Skill = nil
    local weaponFragmentIds = {} -- 武器碎片ID列表
    local skills = (context.game and piece) and XLuckyTenant2BondSkills.GetSkillsFromBonds(piece, context.model, context.game, nil, SkillExecutor.ResolveStateSkillId) or {}
    for _, s in ipairs(skills) do
        if s:GetType() == SkillType.Type403 then
            hasType403 = true
            type403Skill = s
            local type403Params = s:GetParams() or {}
            -- 收集武器碎片ID
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

    -- 如果被感染（Type405），可融合任意相邻武器
    local TriggerState = XLuckyTenant2Enum.TriggerState
    local infectionState = piece:GetState(TriggerState.Infection)
    if infectionState then
        local extraLevel = 0
        local stateSkillId = infectionState:GetSkillId()
        if stateSkillId and context.model then
            local stateSkillConfig = context.model:GetLuckyTenant2ChessSkillConfigById(stateSkillId)
            if stateSkillConfig and stateSkillConfig.Type == SkillType.Type405 then
                local params = stateSkillConfig.Params or {}
                extraLevel = params[1] or 0
            end
        end
        for _, adjPiece in ipairs(adjacentPieces) do
            if adjPiece and adjPiece:GetPieceType() == XLuckyTenant2Enum.PieceType.Weapon and adjPiece:GetLevel() < maxLevel then
                local adjValue = adjPiece:GetBaseValue() or 0
                local newLevel = (piece:GetLevel() or 0) + extraLevel
                local newValue = (piece:GetBaseValue() or 0) + adjValue
                local adjQuality = adjPiece:GetQuality()

                -- 计算新品质
                local currentQuality = piece:GetQuality()
                local newQuality = currentQuality
                if adjQuality == currentQuality then
                    newQuality = newQuality + 1
                else
                    newQuality = math.max(currentQuality, adjQuality)
                end
                if newQuality >= XLuckyTenant2Enum.GameConstants.MAX_QUALITY then
                    newQuality = XLuckyTenant2Enum.GameConstants.MAX_QUALITY
                end

                context.proxy:DeletePiece(adjPiece, piece)
                context.proxy:ModifyPieceLevel(piece, newLevel - (piece:GetLevel() or 0))
                context.proxy:ModifyPieceValue(piece, newValue - (piece:GetBaseValue() or 0))
                context.proxy:ModifyPieceQuality(piece, newQuality - (piece:GetQuality() or 0))

                local pieceUid = piece:GetUid()
                XMVCA.XLuckyTenant2:Print("[Type401+Type405] 武器感染融合，棋子UID:", pieceUid,
                    "新等级:", newLevel, "新金币:", newValue, "额外等级:", extraLevel)
                return true
            end
        end
    end

    -- 优先检查是否可以融合武器碎片（Type403）
    if hasType403 and #weaponFragmentIds > 0 then
        for _, adjPiece in ipairs(adjacentPieces) do
            if adjPiece then
                local adjPieceId = adjPiece:GetId()
                -- 检查是否是武器碎片
                for _, fragmentId in ipairs(weaponFragmentIds) do
                    if adjPieceId == fragmentId then
                        -- 融合武器碎片：品质保留最高，等级求和，基础金币求和
                        local adjQuality = adjPiece:GetQuality()
                        local adjLevel = adjPiece:GetLevel() or 0
                        local adjValue = adjPiece:GetBaseValue() or 0

                        local newQuality = math.max(currentQuality, adjQuality)
                        local newLevel = (piece:GetLevel() or 0) + adjLevel
                        local newValue = (piece:GetBaseValue() or 0) + adjValue

                        -- 删除武器碎片
                        context.proxy:DeletePiece(adjPiece, piece)

                        -- 更新当前武器的属性
                        context.proxy:ModifyPieceLevel(piece, newLevel - (piece:GetLevel() or 0))
                        context.proxy:ModifyPieceValue(piece, newValue - (piece:GetBaseValue() or 0))

                        local pieceUid = piece:GetUid()
                        XMVCA.XLuckyTenant2:Print("[Type401+Type403] 武器融合武器碎片，棋子UID:", pieceUid,
                            "新品质:", newQuality, "新等级:", newLevel, "新金币:", newValue)

                        return true
                    end
                end
            end
        end
    end

    -- 检查是否可以融合同品质武器（Type401基础逻辑）
    for _, adjPiece in ipairs(adjacentPieces) do
        if adjPiece and adjPiece:GetPieceType() == XLuckyTenant2Enum.PieceType.Weapon then
            local adjQuality = adjPiece:GetQuality()

            -- 如果品质相同，执行融合
            if adjQuality == currentQuality and adjPiece:GetLevel() < maxLevel then
                -- 融合逻辑：品质+1，等级求和，基础金币求和
                local maxQuality = 5 -- 最高品质
                local newQuality = math.min(currentQuality + 1, maxQuality)
                local newLevel = (piece:GetLevel() or 0) + (adjPiece:GetLevel() or 0)
                local newValue = (piece:GetBaseValue() or 0) + (adjPiece:GetBaseValue() or 0)

                -- 如果达到最高品质，额外+1等级
                if newQuality >= maxQuality and currentQuality < maxQuality then
                    newLevel = newLevel + 1
                end

                -- 删除相邻的武器
                context.proxy:DeletePiece(adjPiece, piece)

                -- 更新当前武器的属性（通过Operation系统）
                -- 注意：这里需要通过Operation修改品质、等级、基础金币
                -- 由于Operation系统可能不支持直接修改品质，这里暂时只修改等级和金币
                context.proxy:ModifyPieceLevel(piece, newLevel - (piece:GetLevel() or 0))
                context.proxy:ModifyPieceValue(piece, newValue - (piece:GetBaseValue() or 0))

                local pieceUid = piece:GetUid()
                XMVCA.XLuckyTenant2:Print("[Type401] 武器融合，棋子UID:", pieceUid,
                    "新品质:", newQuality, "新等级:", newLevel, "新金币:", newValue)

                return true
            end
        end
    end

    return false
end

---技能类型403：武器lv1（技能）- 武器融合武器碎片等级
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type403] = function(skill, context)
    -- Type403的功能已经集成到Type401中
    -- 当有Type403技能时，Type401会检查是否可以融合武器碎片
    -- 这里只返回true表示技能已激活
    return true
end

---技能类型402：武器被动02（被动）- 等级关联金币
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type402] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查棋子类型是否为武器
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Weapon then
        return false
    end

    -- 检查是否已在本回合执行过（防止同一回合内多次循环重复执行）
    local pieceUid = piece:GetUid()
    if context.proxy:MarkRoundSkillExecuted(pieceUid) then
        return false -- 已在本回合执行过
    end

    local divisor = params[1] or 1       -- 每N个等级
    local valuePerLevel = params[2] or 0 -- 每N个等级增加M金币

    if divisor <= 0 or valuePerLevel <= 0 then
        return false
    end

    -- 计算当前等级应该增加的value总量
    local currentLevel = piece:GetLevel() or 0
    local targetValue = math.floor(currentLevel / divisor) * valuePerLevel

    -- 获取初始value
    local initialValue = piece:GetInitialValue() or 0

    -- 计算目标总value（初始value + Type402应该增加的value）
    local targetTotalValue = initialValue + targetValue

    -- 获取当前value
    local currentValue = piece:GetBaseValue() or 0

    -- 计算需要增加的value（目标总value - 当前value）
    local valueToAdd = targetTotalValue - currentValue

    -- 只有在需要增加value时才执行
    if valueToAdd > 0 then
        piece:AddValue(valueToAdd)
        return true
    end

    return false
end

---技能类型406：武器羁绊lv.3（技能）- 相邻可升级棋子升级，自身升级
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type406] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 3) then
        return false
    end

    -- 判断武器等级是否满级, 满级的情况下, 不再执行406技能
    local maxLevel = XLuckyTenant2Piece.GetWeaponMaxLevel()
    if piece:GetLevel() >= maxLevel then
        return false
    end

    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Weapon then
        return false
    end

    -- 检查是否已在本回合执行过（防止同一回合内多次升级）
    -- 使用 pieceUid + skillId 作为key，确保不同技能的防重复标记不会互相影响
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false -- 已在本回合执行过
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
end

---技能类型407：武器lv4（技能）- 相邻棋子升级时，清零倒计时并增加基础金币
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type407] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 判断武器等级是否满级, 满级的情况下, 不再执行407技能
    local maxLevel = XLuckyTenant2Piece.GetWeaponMaxLevel()
    if piece:GetLevel() >= maxLevel then
        return false
    end

    -- 检查棋子类型是否为武器
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Weapon then
        return false
    end

    -- 检查是否已在本回合执行过（防止同一回合内多次升级）
    -- 使用 pieceUid + skillId 作为key，确保不同技能的防重复标记不会互相影响
    local pieceUid = piece:GetUid()
    local skillId = skill:GetId()
    local markKey = pieceUid .. "_" .. skillId
    if context.proxy:MarkRoundSkillExecuted(markKey) then
        return false -- 已在本回合执行过
    end

    -- 407技能增加: 触发概率检查, 如果触发概率为0, 则不执行技能
    local triggerPercent = params[3] or 0 -- 触发的概率, 百分比
    if triggerPercent <= 0 or triggerPercent > 100 then
        return false
    end
    if math.random(1, 100) > triggerPercent then
        return false
    end

    local adjacentCount = params[1] or 1 -- 影响的相邻数量
    local levelDelta = params[2] or 0    -- 给自己增加的等级

    if adjacentCount <= 0 or levelDelta <= 0 then
        return false
    end

    -- 获取相邻棋子
    local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
    local affectedCount = 0

    -- 检查相邻棋子是否有任意倒计时状态（升级/死亡/感染等），有则全部清零
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

    -- 如果成功影响了相邻棋子，给自己增加等级
    if affectedCount > 0 then
        context.proxy:ModifyPieceLevel(piece, levelDelta)
        return true
    end

    return false
end

-- ==================== 宝盒羁绊技能（Type501-Type508）====================

---技能类型501：宝盒被动01（被动）- 倒计时N回合后死亡，并在相邻空位产生棋子
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type501] = function(skill, context)
    -- Type501的功能实际上是通过Type508实现的
    -- 根据需求文档，Type501只赋予技能508给所有宝盒棋子，不做实际生效技能
    -- 这里返回true表示技能已应用
    return true
end

---技能类型503：宝盒羁绊lv.1 - 宝盒倒计回合上限-N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type503] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Box then
        return false
    end

    local reduceRounds = params[1] or 0
    if reduceRounds <= 0 then
        return false
    end

    local TriggerState = XLuckyTenant2Enum.TriggerState
    local deathState = piece:GetState(TriggerState.Death)
    if deathState and deathState:GetRemainRounds() > 0 then
        local currentRounds = deathState:GetRemainRounds()
        local newRounds = math.max(1, currentRounds - reduceRounds)
        if newRounds ~= currentRounds then
            deathState:SetRemainRounds(newRounds)
            return true
        end
    end

    return false
end

---技能类型504：宝盒lv2（技能）- 宝盒相邻棋子升级时，宝盒倒计时-N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type504] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 1) then
        return false
    end

    -- 检查棋子类型是否为宝盒
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.Box then
        return false
    end

    local reduceRounds = params[1] or 0 -- 减少的回合数
    local pieceId = piece:GetId()
    local pieceName = piece:GetName() or "未知"
    local x, y = piece:GetPosition()
    local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"

    if reduceRounds <= 0 then
        return false
    end

    -- 获取相邻棋子
    local adjacentPieces = context.proxy:GetAdjacentPieces(piece)

    local TriggerState = XLuckyTenant2Enum.TriggerState
    local hasUpgrade = false
    local upgradeCount = 0

    -- 检查相邻棋子是否有升级状态且倒计时==0（表示刚升级）
    -- Type301在升级后会将倒计时设为0，供Type504检测
    for _, adjPiece in ipairs(adjacentPieces) do
        if adjPiece then
            local upgradeState = adjPiece:GetState(TriggerState.Upgrade)

            if upgradeState and upgradeState:GetRemainRounds() == 0 then
                hasUpgrade = true
                upgradeCount = upgradeCount + 1
            end
        end
    end

    -- 如果相邻棋子有升级状态，减少宝盒的倒计时
    if hasUpgrade then
        local deathState = piece:GetState(TriggerState.Death)
        if deathState and deathState:GetRemainRounds() > 0 then
            local currentRounds = deathState:GetRemainRounds()
            local newRounds = math.max(0, currentRounds - reduceRounds)
            deathState:SetRemainRounds(newRounds)
            -- 将倒计时设为0，系统会在下一轮循环中检测到并触发Type508
            return true
        end
    end

    return false
end

---技能类型505：宝盒羁绊lv.3 - 可被传染，感染后宝盒倒计时-N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
---技能类型505：宝盒lv3（被动）- 可被传染，感染后效果由Type508处理
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type505] = function(skill, context)
    -- Type505是被动技能，不直接执行逻辑
    -- 实际效果（感染后减少倒计时、只产出侵蚀、概率产出红雾）由Type508处理
    return true
end

---技能类型507：宝盒lv4（技能）- 宝盒被消除时，品质+1；若为橙色品质，改为基础金币+N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type507] = function(skill, context)
    -- Type507的实际逻辑在 XLuckyTenant2OperationDeletePiece 中实现
    -- 当宝盒被消除时，会检查是否有Type507技能：
    -- - 如果品质 < 5（橙色），产生品质+1的新宝盒在原地
    -- - 如果品质 = 5（橙色），增加基础金币+N
    -- 这里只返回 true 表示技能已激活，使其能在界面展示
    return true
end

-- ==================== 红潮羁绊技能（Type601-Type603）====================

---技能类型601：红潮被动01（被动）- 每回合传染相邻棋子
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type601] = function(skill, context)
    local piece = context.piece or skill:GetPiece()

    if not piece then
        return false
    end

    -- 检查棋子类型是否为红潮
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.RedTide then
        return false
    end

    -- 获取相邻棋子
    local adjacentPieces = context.proxy:GetAdjacentPieces()
    local TriggerState = XLuckyTenant2Enum.TriggerState
    local infectedCount = 0

    -- 传染相邻棋子
    for _, adjPiece in ipairs(adjacentPieces) do
        local adjBondIdStr = adjPiece:GetBondId()
        if adjBondIdStr and adjBondIdStr ~= "" then
            local targetStateSkillId = nil

            -- 检查棋子是否属于可传染的羁绊类型
            for bondIdStr in string.gmatch(adjBondIdStr, "([^|]+)") do
                local bondId = tonumber(bondIdStr)
                -- 查找映射表，获取对应的状态技能ID
                if XLuckyTenant2Enum.BondToInfectionSkillMap[bondId] then
                    targetStateSkillId = XLuckyTenant2Enum.BondToInfectionSkillMap[bondId]
                    break
                end
            end

            if targetStateSkillId then
                -- 检查是否已经被感染（避免重复感染）
                if not adjPiece:HasState(TriggerState.Infection) then
                    -- 感染状态设置为-1表示永久状态，不显示倒计时
                    context.proxy:ApplyState(adjPiece, TriggerState.Infection, targetStateSkillId, -1)
                    infectedCount = infectedCount + 1
                end
            end
        end
    end

    return infectedCount > 0
end

---技能类型602：红潮lv1（技能）- 相邻棋子每发生1次被消除，红潮基础金币+N
---仅通过删除流程在 XLuckyTenant2OnDeleteEffects.ApplyType602 中触发并实现，此处不执行，避免被技能循环主动触发
---@return boolean 始终 false，不执行
_SkillExecutors[SkillType.Type602] = function()
    return false
end

---技能类型603：红潮lv2（技能）- 相邻棋子存在倒计时时，概率将倒计回合清零，且基础金币+N
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
_SkillExecutors[SkillType.Type603] = function(skill, context)
    local piece = context.piece or skill:GetPiece()
    local params = skill:GetParams()
    if not ValidateSkillParams(piece, params, 2) then
        return false
    end

    -- 检查棋子类型是否为红潮
    if piece:GetPieceType() ~= XLuckyTenant2Enum.PieceType.RedTide then
        return false
    end

    local probability = params[1] or 30 -- 清零概率（默认30%）
    local valueDelta = params[2] or 0   -- 增加的基础金币

    if valueDelta <= 0 then
        return false
    end

    -- 获取相邻棋子
    local adjacentPieces = context.proxy:GetAdjacentPieces(piece)
    local TriggerState = XLuckyTenant2Enum.TriggerState
    local affectedCount = 0

    -- 检查相邻棋子是否有倒计时状态
    for _, adjPiece in ipairs(adjacentPieces) do
        if adjPiece then
            local upgradeState = adjPiece:GetState(TriggerState.Upgrade)
            if upgradeState and upgradeState:GetRemainRounds() > 0 then
                -- 概率清零倒计时
                if context.proxy:RandomCheck(probability) then
                    local beforeRounds = upgradeState:GetRemainRounds()
                    upgradeState:SetRemainRounds(0)
                    affectedCount = affectedCount + 1
                    if XMVCA.XLuckyTenant2 then
                        local x, y = adjPiece:GetPosition()
                        local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
                        XMVCA.XLuckyTenant2:Print(string.format(
                            "[Type603] 清空升级倒计时: 目标=%s[ID:%d,UID:%d], %s, 回合=%d->0",
                            adjPiece:GetName() or "未知", adjPiece:GetId(), adjPiece:GetUid(), posStr, beforeRounds))
                    end
                end
            end

            -- 检查死亡状态（倒计时）
            local deathState = adjPiece:GetState(TriggerState.Death)
            if deathState and deathState:GetRemainRounds() > 0 then
                -- 概率清零倒计时
                if context.proxy:RandomCheck(probability) then
                    local beforeRounds = deathState:GetRemainRounds()
                    deathState:SetRemainRounds(0)
                    affectedCount = affectedCount + 1
                    if XMVCA.XLuckyTenant2 then
                        local x, y = adjPiece:GetPosition()
                        local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
                        XMVCA.XLuckyTenant2:Print(string.format(
                            "[Type603] 清空死亡倒计时: 目标=%s[ID:%d,UID:%d], %s, 回合=%d->0",
                            adjPiece:GetName() or "未知", adjPiece:GetId(), adjPiece:GetUid(), posStr, beforeRounds))
                    end
                end
            end
        end
    end

    -- 如果成功影响了相邻棋子，增加基础金币
    if affectedCount > 0 then
        context.proxy:ModifyPieceValue(piece, valueDelta)
        return true
    end

    return false
end

return SkillExecutor
