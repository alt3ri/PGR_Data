local XLuckyTenant2ChessBoard = require("XModule/XLuckyTenant2/Game/XLuckyTenant2ChessBoard")
local XLuckyTenant2Bag = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Bag")
local XLuckyTenant2RandomPool = require("XModule/XLuckyTenant2/Game/XLuckyTenant2RandomPool")
local XLuckyTenant2ChessSkill = require("XModule/XLuckyTenant2/Game/XLuckyTenant2ChessSkill")
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2BondManager = require("XModule/XLuckyTenant2/Game/XLuckyTenant2BondManager")
local XLuckyTenant2StateApplier = require("XModule/XLuckyTenant2/Game/XLuckyTenant2StateApplier")
local GameState = XLuckyTenant2Enum.GameState
local SkillType = XLuckyTenant2Enum.Skill
-- 兼容旧版 Enum 未定义 PieceId 的情况（子虫 ID=2）
local PieceId = XLuckyTenant2Enum.PieceId or { Subworm = 2 }

---计算上下文
---@class XLuckyTenant2CalculationContext
---@field model XLuckyTenant2Model 模型实例
---@field animationGroups table|false 动画组（可选）
---@field proxy XLuckyTenant2OperationProxy 操作代理
---@field round number 当前回合数
---@field skillsByPriority table 按优先级分组的技能表
---@field times number 执行次数（第几次计算，在循环中动态添加）

---@class XLuckyTenant2Game
local XLuckyTenant2Game = XClass(nil, "XLuckyTenant2Game")

-- ==================== 构造函数 ====================

function XLuckyTenant2Game:Ctor()
    -- 游戏组件
    ---@type XLuckyTenant2ChessBoard
    self._ChessBoard = XLuckyTenant2ChessBoard.New()
    ---@type XLuckyTenant2Bag
    self._Bag = XLuckyTenant2Bag.New()
    ---@type XLuckyTenant2RandomPool
    self._RandomPool = XLuckyTenant2RandomPool.New()
    ---@type XLuckyTenant2BondManager
    self._BondManager = nil

    -- 游戏基础数据
    self._Seed = 0
    self._StageId = 0
    self._IsFirstTimeEntering = false
    self._Round = 0
    self._GameState = GameState.ShowQuestGoalsOnFirstRound

    -- 羁绊刷新标记（延迟处理）
    ---@type table<number, boolean>|nil 需要刷新技能的羁绊ID集合
    self._BondsNeedRefresh = nil

    -- 棋子选择相关
    self._AmountOfPiecesToSelect = 3
    ---@type XLuckyTenant2Piece[]
    self._PiecesToSelect = {}
    self._PiecesFixedBucket = {}
    self._PiecesRandomBucket = {}
    self._ConditionBucket = {}
    self._IsDirtyPiecesToSelect = true
    self._HasSelectOrDelete = false

    -- 分数相关
    self._TotalScore = 0
    self._ScoreThisRound = 0
    ---@type table<number, number> 当前回合每个羁绊的得分 {bondId: score}
    self._BondsIncomeThisRound = {}

    -- 任务相关
    ---@type XTableLuckyTenant2StageTask[]
    self._Quest = {}
    self._QuestHasBeenCompleted = 0
    self._IsNormalClear = false

    -- 其他状态
    self._FreeRefreshTimes = 0
    self._TestCase = false
    self._Animations = {}
    self._HasSupplyChess = false
    self._RoundFin = false
    self._IsOver = false

    -- 记录
    self._Record = {
        SelectPiece = {},
        DeletePiece = {}
    }

    -- 按技能类型缓存的 skillId（如 Type208），惰性计算、避免重复遍历配置
    self._CachedSkillIdByType = {}  -- { [skillType] = skillId | false } false 表示已查过但不存在
end

-- ==================== 初始化 ====================

---初始化游戏
---@param model XLuckyTenant2Model
---@param stageId number 关卡ID
---@param seed number 随机种子
---@param isFirstTimeEntering boolean 是否首次进入
---@param isResumeGame boolean 是否恢复游戏
function XLuckyTenant2Game:Init(model, stageId, seed, isFirstTimeEntering, isResumeGame)
    local config = model:GetLuckyTenant2StageConfigById(stageId)
    if not config then
        XLog.Error("[XLuckyTenant2Game] 不存在的关卡:" .. tostring(stageId))
        return
    end

    self._Seed = seed
    math.randomseed(seed)
    self._FreeRefreshTimes = config.FirstSupplyCnt
    self._StageId = stageId
    self._IsFirstTimeEntering = isFirstTimeEntering

    -- 初始化记录中的StageId
    self._Record.StageId = stageId

    -- 记录回合开始时间（用于计算回合耗时）
    self._RoundStartTime = XTime.GetServerNowTimestamp()

    -- 初始化游戏组件
    self._Bag:Init(model, config, isResumeGame, self)
    self._ChessBoard:Init(config)
    self._RandomPool:Init(model)

    -- 初始化羁绊管理器（传入配置数据，而不是 model）
    local bondConfigs = model:GetLuckyTenant2BondConfigs()
    self._BondManager = XLuckyTenant2BondManager.New(bondConfigs)
    -- 设置等级变化回调
    self._BondManager:SetOnLevelChangedCallback(function(bondId, oldLevel, newLevel)
        self:OnBondLevelChanged(bondId, oldLevel, newLevel)
    end)

    -- 初始化技能执行器的状态技能ID缓存
    local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
    SkillExecutor.InitStateSkillIds(model)

    -- 初始化角色等级上限（从Type301技能配置读取params[3]）
    self:InitRoleMaxLevel(model)

    -- 初始化任务
    self:InitQuest(model)
end

---初始化角色等级上限（从Type301技能配置读取）
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:InitRoleMaxLevel(model)
    -- 获取Type301技能配置
    local SkillType = XLuckyTenant2Enum.Skill
    local allSkillConfigs = model:GetLuckyTenant2ChessSkillConfigs()

    for _, skillConfig in pairs(allSkillConfigs) do
        if skillConfig and skillConfig.Type == SkillType.Type301 then
            -- 从params[3]读取角色等级上限
            local params = skillConfig.Params or {}
            local roleMaxLevel = params[3]
            if roleMaxLevel and roleMaxLevel > 0 then
                local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")
                XLuckyTenant2Piece.SetRoleMaxLevel(roleMaxLevel)
                break
            end
        end
    end

    -- 从401的params[1]读取武器等级上限
    for _, skillConfig in pairs(allSkillConfigs) do
        if skillConfig and skillConfig.Type == SkillType.Type401 then
            local params = skillConfig.Params or {}
            local weaponMaxLevel = params[1]
            if weaponMaxLevel and weaponMaxLevel > 0 then
                local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")
                XLuckyTenant2Piece.SetWeaponMaxLevel(weaponMaxLevel)
                break
            end
        end
    end
end

---初始化任务
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:InitQuest(model)
    local stageId = self._StageId
    local questConfigs = model:GetStageTasks(stageId)

    -- 创建可修改的副本，并添加完成状态字段
    self._Quest = {}
    for i = 1, #questConfigs do
        local config = questConfigs[i]
        self._Quest[i] = {
            Round = config.Round,
            Score = config.Score,
            Desc = config.Desc,
            RewardPieces = config.RewardPieces,
            RewardPiecesAmount = config.RewardPiecesAmount,
            PerfectClear = false, -- 完美通关标记
            NormalClear = false,  -- 普通通关标记
        }
    end

end

-- ==================== 游戏流程 ====================

---进入下一回合
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:EnterNextRound(model)
    self._IsDirtyPiecesToSelect = true
    self._HasSelectOrDelete = false
    self._Round = self._Round + 1
    self:ResetRoundState()
end

---重置回合状态（回合开始时的清理）
function XLuckyTenant2Game:ResetRoundState()
    self._ScoreThisRound = 0
    self._RoundFin = false
    self._RoundStartTime = XTime.GetServerNowTimestamp()
end

---放置棋子到棋盘
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:PlacePiecesOnBoard(model)
    -- 调试日志
    local XLuckyTenant2DebugLog = require("XModule/XLuckyTenant2/XLuckyTenant2DebugLog")
    XLuckyTenant2DebugLog.Log("========== PlacePiecesOnBoard 开始 ==========")
    XLuckyTenant2DebugLog.LogFormat("StageId: %d, Round: %d", self._StageId or 0, self._Round or 0)

    -- 记录放置前的背包棋子数量
    local bagPiecesBefore = self._Bag:GetPieces()
    local bagCountBefore = 0
    for _ in pairs(bagPiecesBefore) do
        bagCountBefore = bagCountBefore + 1
    end
    XLuckyTenant2DebugLog.LogFormat("放置前背包棋子数量: %d", bagCountBefore)

    -- 1. 将背包棋子放置到棋盘上（会设置棋子位置，使IsOnBoard返回true）
    if self._TestCase then
        self._ChessBoard:SetTestCase(self, model, self._Bag, self._TestCase)
    else
        self._ChessBoard:SetPieces(self._Bag)
    end

    -- 记录放置后的棋盘棋子数量
    local chessboardPieces = self._ChessBoard:GetAllPieces()
    XLuckyTenant2DebugLog.LogFormat("放置后棋盘棋子数量: %d", #chessboardPieces)

    -- 2. 刷新羁绊等级（基于Bag计算，此时棋子已在棋盘上，可以正确计算）
    self:_RefreshBondLevels(model)

    -- 3. 处理羁绊等级变化（如果有变化，会标记到_BondsNeedRefresh）
    self:_ProcessBondLevelChanges(model)

    -- 4. 应用羁绊技能到棋子（会根据当前等级重新应用所有技能）
    self:_ApplyBondSkillsToPieces(model)

    XLuckyTenant2DebugLog.Log("========== PlacePiecesOnBoard 结束 ==========")
end

function XLuckyTenant2Game:SetTestCase(testCase)
    self._TestCase = testCase
end

function XLuckyTenant2Game:RemoveTestCase()
    self._TestCase = false
end

---添加新棋子到背包
---@param model XLuckyTenant2Model
---@param pieceId number 棋子ID
---@return boolean 是否成功
---@return XLuckyTenant2Piece|false 添加的棋子
function XLuckyTenant2Game:AddNewPieceToBag(model, pieceId)
    if self._Bag:IsFull() then
        return false, false
    end

    local uid = self._Bag:GetNewUid()
    local piece = self._Bag:NewPiece(model, pieceId, uid)
    if piece then
        self._Bag:AddPiece(piece)

        -- 只在游戏已初始化（_BondManager存在）后才立即应用技能
        -- 游戏初始化时会统一调用_ApplyBondSkillsToPieces，不需要这里重复应用
        if self._BondManager then
            -- 立即对新棋子应用羁绊技能和状态技能（确保Type503等技能生效）
            -- 重置羁绊数值增量
            piece:ResetBondValueDeltas()
            -- 清除原有技能
            piece:ClearSkills()

            -- 应用羁绊技能
            self:_ApplyBondSkillsToPiece(piece, model)

            -- 添加棋子自身技能
            self:_ApplyPieceOwnSkills(piece, model)

            -- 应用状态技能
            self:_ApplyStateSkills(piece, model)

            -- 立即刷新基础金币/删除得分显示
            self:_ApplyImmediateValueSkillsToPiece(piece, model)

            -- 对于子虫，应用怪物羁绊技能
            local bondId = piece:GetBondId()
            if not bondId or bondId == "" or bondId == "0" then
                self:ApplyMonsterSkillsToNewPiece(piece, model)
            end
        end

        return true, piece
    end

    return false, false
end

---任务完成后发放配置的奖励道具棋子到背包（来自 LuckyTenant2StageTask 的 RewardPieces / RewardPiecesAmount）
---道具（刷新/删除）增加已有道具的 Amount；普通棋子调用 AddNewPieceToBag
---@param model XLuckyTenant2Model
---@param quest table 已完成的任务（含 RewardPieces、RewardPiecesAmount）
function XLuckyTenant2Game:GrantQuestRewardPieces(model, quest)
    if not model or not quest then
        return
    end
    local rewardPieces = quest.RewardPieces
    local rewardAmounts = quest.RewardPiecesAmount
    if not rewardPieces or #rewardPieces == 0 then
        return
    end
    rewardAmounts = rewardAmounts or {}
    local PropId = XLuckyTenant2Enum.PropId
    for i = 1, #rewardPieces do
        local pieceId = rewardPieces[i]
        local amount = (rewardAmounts[i] and rewardAmounts[i] > 0) and rewardAmounts[i] or 1
        if pieceId and pieceId > 0 then
            -- 刷新/删除道具：增加 _Props 中对应道具的 Amount，不新建棋子
            if pieceId == PropId.RefreshProp or pieceId == PropId.DeleteProp then
                local itemType = model:GetLuckyTenant2ChessTypeById(pieceId)
                local prop = self._Bag:GetProp(itemType)
                if prop then
                    prop:SetAmount((prop:GetAmount() or 0) + amount)
                else
                    -- 未初始化到 _Props 时退化为添加棋子（并会占用背包格子）
                    for _ = 1, amount do
                        if self._Bag:IsFull() then break end
                        self:AddNewPieceToBag(model, pieceId)
                    end
                end
            else
                for _ = 1, amount do
                    if self._Bag:IsFull() then
                        return
                    end
                    self:AddNewPieceToBag(model, pieceId)
                end
            end
        end
    end
end

---按技能类型查找第一个对应的 skillId（带缓存，避免重复遍历配置）
---@param model XLuckyTenant2Model 配置模型
---@param skillType number 技能类型（如 SkillType.Type208）
---@return number|nil
function XLuckyTenant2Game:GetFirstSkillIdByType(model, skillType)
    if not model or not skillType then
        return nil
    end
    local cache = self._CachedSkillIdByType
    if cache[skillType] ~= nil then
        return (cache[skillType] ~= false) and cache[skillType] or nil
    end
    local allSkillConfigs = model:GetLuckyTenant2ChessSkillConfigs()
    local skillId = nil
    if allSkillConfigs then
        for sid, cfg in pairs(allSkillConfigs) do
            if cfg and cfg.Type == skillType then
                skillId = (type(sid) == "number") and sid or tonumber(sid)
                break
            end
        end
    end
    self._CachedSkillIdByType[skillType] = skillId or false
    return skillId
end

---应用怪物羁绊技能到新创建的棋子（Type203/205/207）
---@param piece XLuckyTenant2Piece 新创建的棋子
---@param model XLuckyTenant2Model 配置模型
function XLuckyTenant2Game:ApplyMonsterSkillsToNewPiece(piece, model)
    if not piece or not model then
        return
    end

    -- 检查羁绊管理器是否存在（游戏刚开始时可能还没初始化）
    if not self._BondManager then
        return
    end

    local SkillTypeEnum = XLuckyTenant2Enum.Skill
    local PieceType = XLuckyTenant2Enum.PieceType
    local pieceId = piece:GetId()
    local pieceType = piece:GetPieceType()

    -- 遍历所有怪物羁绊，检查是否有影响新棋子的技能
    local monsterBondId = XLuckyTenant2Enum.Bond.Monster -- 怪物羁绊ID = 1

    if not monsterBondId then
        return
    end

    local bond = self._BondManager:GetBond(monsterBondId)
    if not bond then
        return
    end

    local bondLevel = bond:GetLevel()
    if bondLevel <= 0 then
        return
    end

    -- 获取该羁绊在当前等级下的所有技能配置
    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(monsterBondId, bondLevel)

    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        local configLevel = bondSkillConfig.Level or 0

        if bondLevel >= configLevel then
            local skillId = bondSkillConfig.SkillId
            if type(skillId) == "table" then
                skillId = skillId[1] or 0
            end

            if skillId and skillId > 0 then
                local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)

                if skillConfig then
                    local skillType = skillConfig.Type
                    local params = skillConfig.Params or {}

                    -- Type203：子虫基础金币+N，消除金币+M
                    if skillType == SkillTypeEnum.Type203 then
                        local baseValueDelta = params[1] or 0     -- 基础金币增加值
                        local bugPieceId = params[2] or 0         -- 子虫棋子ID（0表示所有子虫）
                        local deletionValueDelta = params[3] or 0 -- 消除金币增加值

                        -- 检查棋子是否是子虫（BondId为空）
                        local bondId = piece:GetBondId() or ""
                        local isChildBug = (bondId == "" or bondId == "0")
                        local valueOk = (baseValueDelta > 0 or deletionValueDelta > 0)
                        local idMatch = (bugPieceId == 0 or bugPieceId == pieceId)

                        if isChildBug and valueOk and idMatch then
                            local skillKey = "MonsterType203_" .. skillId

                            -- 设置基础金币增益
                            if baseValueDelta > 0 then
                                piece:SetBondValueDelta(skillKey, baseValueDelta)
                            end

                            -- 设置消除金币增益
                            if deletionValueDelta > 0 then
                                piece:SetBondDeletionValueDelta(skillKey .. "_Delete", deletionValueDelta)
                            end
                        end
                    end

                    -- Type207：给子虫挂上208感染状态
                    if skillType == SkillTypeEnum.Type207 then
                        local bugPieceId = params[1] or 0  -- 子虫棋子ID（0表示所有子虫）

                        -- 检查棋子是否是子虫（BondId为空）
                        local bondId = piece:GetBondId() or ""
                        local isChildBug = (bondId == "" or bondId == "0")
                        local idMatch = (bugPieceId == 0 or bugPieceId == pieceId)

                        if isChildBug and idMatch then
                            -- 按技能类型查找 Type208 对应的 skillId（带缓存），然后应用
                            local skill208Id = self:GetFirstSkillIdByType(model, SkillTypeEnum.Type208)

                            if skill208Id then
                                -- 给子虫挂上感染状态（TriggerState.Infection），关联208技能ID
                                local TriggerState = XLuckyTenant2Enum.TriggerState
                                piece:AddStateByType(TriggerState.Infection, skill208Id, -1)

                                if XMVCA.XLuckyTenant2 then
                                    XMVCA.XLuckyTenant2:Print(string.format(
                                        "[ApplyMonsterSkillsToNewPiece] Type207: 给子虫挂上208感染状态, pieceId=%d, skill208Id=%d",
                                        pieceId, skill208Id
                                    ))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ==================== 棋子选择相关 ====================

---获取本回合可选择的棋子选项
---@param model XLuckyTenant2Model
---@return XLuckyTenant2Piece[] 棋子选项列表
function XLuckyTenant2Game:GetOptionsThisRound(model)
    if self._IsDirtyPiecesToSelect then
        self._IsDirtyPiecesToSelect = false
        -- 将之前的选择放回对象池
        local size = #self._PiecesToSelect
        for i = 1, size do
            local piece = self._PiecesToSelect[i]
            if piece then
                -- TODO: 根据实际对象池实现调整
                -- self._Bag:EnterPool(piece)
            end
        end
        self._PiecesToSelect = {}
        -- 更新随机池
        self:UpdateRandomBucket(model, true)
        -- 刷新选项
        self:RefreshOptions(model)
    end
    return self._PiecesToSelect
end

---刷新棋子选项
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:RefreshOptions(model)
    local needAmount = self._AmountOfPiecesToSelect
    if #self._PiecesRandomBucket < needAmount then
        XLog.Error("[XLuckyTenant2Game] 随机池数量小于" .. tostring(self._AmountOfPiecesToSelect))
        return
    end

    -- 清空当前选项
    for i = 1, #self._PiecesToSelect do
        self._PiecesToSelect[i] = nil
    end

    -- 先使用固定池的棋子
    local fixedBucket = self._PiecesFixedBucket
    local fixedBucketSize = #fixedBucket
    if fixedBucketSize > 0 then
        local size = math.min(needAmount, fixedBucketSize)
        for i = 1, size do
            local pieceId = fixedBucket[1]
            if pieceId and pieceId > 0 then
                table.remove(fixedBucket, 1)
                local uid = self._Bag:GetNewUid()
                local piece = self._Bag:NewPiece(model, pieceId, uid)
                if piece then
                    self._PiecesToSelect[#self._PiecesToSelect + 1] = piece
                    needAmount = needAmount - 1
                end
            end
        end
    end

    -- 从随机池中选择剩余的棋子：优先抓取背包没有的棋子，不够再随机补满
    if needAmount > 0 then
        local selected = self:SelectPiecesPrioritizeNotInBag(model, needAmount)
        for i = 1, #selected do
            local groupConfig = selected[i]
            local pieceId = groupConfig.PieceId
            if pieceId and pieceId > 0 then
                local uid = self._Bag:GetNewUid()
                local piece = self._Bag:NewPiece(model, pieceId, uid)
                if piece then
                    self._PiecesToSelect[#self._PiecesToSelect + 1] = piece
                end
            end
        end
    end

    if #self._PiecesToSelect == 0 then
        XLog.Error("[XLuckyTenant2Game] 可选择棋子为0, 必有问题")
    end
end

---选棋随机逻辑：优先抓取背包没有的棋子，不足 needAmount 时再从随机池补满
---@param model XLuckyTenant2Model
---@param needAmount number 需要选择的数量
---@return table XTable.XTableLuckyTenant2ChessRandomGroup[] 选中的配置列表
function XLuckyTenant2Game:SelectPiecesPrioritizeNotInBag(model, needAmount)
    local bucket = self._PiecesRandomBucket
    if not bucket or #bucket == 0 then
        return {}
    end
    -- 收集背包已有棋子 ID（用于判断“背包没有的棋子”）
    local bagPieceIds = {}
    local pieces = self._Bag:GetPieces()
    if pieces then
        for _, piece in pairs(pieces) do
            local id = piece and piece:GetId()
            if id and id > 0 then
                bagPieceIds[id] = true
            end
        end
    end
    -- 随机池中背包没有的棋子（PieceId 不在 bagPieceIds 中的配置）
    local notInBagBucket = {}
    for _, g in ipairs(bucket) do
        if g and g.PieceId and not bagPieceIds[g.PieceId] then
            table.insert(notInBagBucket, g)
        end
    end
    -- 优先从“背包没有”的池里选，最多选 needAmount 个
    local selected = self:RandomSelect(model, notInBagBucket, needAmount)
    -- 不足 needAmount 时，从全池中补选（排除已选，避免重复）
    if #selected < needAmount then
        local remainingNeed = needAmount - #selected
        local remainingBucket = {}
        for _, g in ipairs(bucket) do
            table.insert(remainingBucket, g)
        end
        for _, g in ipairs(selected) do
            for k, h in ipairs(remainingBucket) do
                if h == g then
                    table.remove(remainingBucket, k)
                    break
                end
            end
        end
        local selectedRest = self:RandomSelect(model, remainingBucket, remainingNeed)
        for _, g in ipairs(selectedRest) do
            table.insert(selected, g)
        end
    end
    return selected
end

---从随机池中选择棋子（根据权重）
---@param model XLuckyTenant2Model
---@param elements table XTable.XTableLuckyTenant2ChessRandomGroup[] 元素列表（RandomGroup配置）
---@param n number 需要选择的数量
---@return table XTable.XTableLuckyTenant2ChessRandomGroup[] 选中的元素列表
function XLuckyTenant2Game:RandomSelect(model, elements, n)
    n = n or 3
    local selected = {}
    local remaining = {}

    -- 复制元素到 remaining 数组
    for _, element in ipairs(elements) do
        table.insert(remaining, element)
    end

    for i = 1, n do
        if #remaining == 0 then
            break
        end

        -- 计算总权重
        local totalWeight = 0
        for _, element in ipairs(remaining) do
            totalWeight = totalWeight + self:GetPieceWeight(model, element)
        end

        -- 随机选择
        local rand = math.random() * totalWeight
        local cumulativeWeight = 0

        for j = 1, #remaining do
            cumulativeWeight = cumulativeWeight + self:GetPieceWeight(model, remaining[j])
            if rand <= cumulativeWeight then
                table.insert(selected, remaining[j]) -- 选择该元素
                table.remove(remaining, j)           -- 从剩余元素中移除该元素
                break
            end
        end
    end

    return selected
end

---获取棋子权重（根据条件动态计算）
---@param model XLuckyTenant2Model
---@param groupConfig XTable.XTableLuckyTenant2ChessRandomGroup RandomGroup配置
---@return number 权重值
function XLuckyTenant2Game:GetPieceWeight(model, groupConfig)
    local conditions = groupConfig.Condition
    local weight = groupConfig.PieceWeight
    if #conditions == 0 then
        return weight
    end
    local isMatchCondition = nil
    for i = 1, #conditions do
        local conditionId = conditions[i]
        if self._ConditionBucket[conditionId] ~= nil then
            isMatchCondition = self._ConditionBucket[conditionId]
        else
            isMatchCondition = false
            local condition = model:GetLuckyTenant2ChessConditionConfigById(conditionId)
            if condition then
                -- ConditionDesc是字符串，转换为数字类型（枚举值）
                local conditionType = tonumber(condition.ConditionDesc) or 0
                -- Param是int[]，不再是string[]
                local param0 = (condition.Param and condition.Param[1]) or 0
                local param1 = (condition.Param and condition.Param[2]) or 0
                local param2 = (condition.Param and condition.Param[3]) or 0

                if conditionType == XLuckyTenant2Enum.Condition.Round then
                    -- 回合条件：当前回合 >= 配置的回合数（param0）
                    if self:GetRound() >= param0 then
                        isMatchCondition = true
                    else
                        isMatchCondition = false
                    end
                elseif conditionType == XLuckyTenant2Enum.Condition.TagAmount then
                    -- Tag数量条件：指定Tag的数量 > 配置的数量
                    -- param0是Tag ID（需要转换为字符串），param1是比较值
                    if self._Bag:GetTagAmount(tostring(param0)) > param1 then
                        isMatchCondition = true
                    else
                        isMatchCondition = false
                    end
                elseif conditionType == XLuckyTenant2Enum.Condition.Identical then
                    -- 相同ID棋子数量条件：指定棋子ID的数量 >= 配置的数量
                    -- param0是棋子ID，param1是比较值
                    local amount = self._Bag:GetPieceAmountById(param0)
                    if amount >= param1 then
                        isMatchCondition = true
                    else
                        isMatchCondition = false
                    end
                end
            end
            self._ConditionBucket[conditionId] = isMatchCondition
        end
        if isMatchCondition then
            weight = weight + groupConfig.IncreaseWeight[i]
        end
    end
    if weight < 0 then
        weight = 0
    end
    return weight
end

---更新随机池（根据当前回合和配置）
---@param model XLuckyTenant2Model
---@param force boolean 是否强制更新
function XLuckyTenant2Game:UpdateRandomBucket(model, force)
    if not force and not self._IsDirtyPiecesToSelect then
        return
    end

    self._PiecesRandomBucket = {}
    self._ConditionBucket = {}
    if #self._PiecesFixedBucket > 0 then
        self._PiecesFixedBucket = {}
    end

    ---@type XTable.XTableLuckyTenant2ChessRound
    local round = model:GetValidRoundConfig(self._StageId, self:GetRound())
    if not round then
        XLog.Error("[XLuckyTenant2Game] 找不到匹配的round配置，StageId:" .. tostring(self._StageId) .. ", Round:" .. tostring(self:GetRound()))
        return
    end

    -- 使用提前配置好的棋子（首次进入关卡或首次进入该回合）
    local presetPieces
    if self._IsFirstTimeEntering then
        presetPieces = round.FirstUseInStage
    elseif self:GetRound() == round.StartRound then
        presetPieces = round.FirstUseInRound
    end
    if presetPieces then
        for i = 1, #presetPieces do
            local id = presetPieces[i]
            self._PiecesFixedBucket[#self._PiecesFixedBucket + 1] = id
        end
    end

    -- 根据Round配置中的Group列表，获取对应的RandomGroup配置
    local elements = self._PiecesRandomBucket
    local groups = round.Group
    for i = 1, #groups do
        local groupId = groups[i]
        self:GetRandomBucketByGroupId(elements, model, groupId)
    end
end

---根据GroupId获取RandomBucket中的配置
---@param elements table 目标数组
---@param model XLuckyTenant2Model
---@param groupId number GroupId
function XLuckyTenant2Game:GetRandomBucketByGroupId(elements, model, groupId)
    -- RandomGroup配置的ID格式：groupId * 1000 + index（例如groupId=1，则配置ID为1001, 1002, ...）
    for i = 1, 99 do
        local groupConfig = model:GetLuckyTenant2ChessRandomGroupConfigById(groupId * 1000 + i)
        if groupConfig and groupConfig.GroupId == groupId then
            elements[#elements + 1] = groupConfig
        else
            if i == 1 then
                XLog.Error("[XLuckyTenant2Game] 随机池group的配置不存在，应该是groupId * 1000 + index格式，检查配置，groupId:" .. tostring(groupId))
            end
            break
        end
    end
end

---选择棋子
---@param model XLuckyTenant2Model
---@param index number 棋子索引（从1开始）
---@return boolean 是否成功
---@return XLuckyTenant2Piece|false 选中的棋子
function XLuckyTenant2Game:SelectPiece(model, index)
    local options = self:GetOptionsThisRound(model)
    local piece = options[index]
    if not piece then
        XLog.Error("[XLuckyTenant2Game] 选择棋子失败,该index没有对应棋子:" .. tostring(index))
        return false, false
    end
    options[index] = nil -- 从选项中移除
    -- 添加到背包
    local success, addedPiece = self:AddNewPieceToBag(model, piece:GetId())
    if success then
        self._HasSelectOrDelete = true
        table.insert(self._Record.SelectPiece, piece:GetId())
        return true, addedPiece
    end
    return false, false
end

---根据UID删除棋子
---@param uid number 棋子UID
---@param fromPlayer boolean 是否来自玩家操作
function XLuckyTenant2Game:DeletePieceByUid(uid, fromPlayer)
    -- 从棋盘删除
    self._ChessBoard:DeletePieceByUid(uid)
    -- 从背包删除
    local piece = self._Bag:GetPieceByUid(uid)
    if piece then
        if fromPlayer then
            table.insert(self._Record.DeletePiece, piece:GetId())
        end
        -- TODO: 删除棋子相关的技能（如果需要）
        -- self:DeletePieceSkill(piece)
        self._Bag:DeletePieceByUid(uid)
        self._HasSelectOrDelete = true
    else
        XLog.Error("[XLuckyTenant2Game] 删除棋子失败，找不到UID:" .. tostring(uid))
    end
end

---获取免费刷新次数
---@return number
function XLuckyTenant2Game:GetFreeRefreshTimes()
    -- 第一期只在第一回合有免费刷新
    if self:GetRound() == 1 then
        return self._FreeRefreshTimes
    end
    return 0
end

---减少免费刷新次数
function XLuckyTenant2Game:ReduceFreeRefreshTimes()
    self._FreeRefreshTimes = math.max(0, self._FreeRefreshTimes - 1)
end

---检查是否有补充棋子（用于恢复游戏）
---@return boolean
function XLuckyTenant2Game:HasSupplyChess()
    return self._HasSupplyChess
end

---清除补充棋子标记
function XLuckyTenant2Game:ClearHasSupplyChess()
    self._HasSupplyChess = false
end

-- ==================== 技能执行 ====================

---执行回合计算（主入口）
---@param model XLuckyTenant2Model
---@param animationGroups table|false 动画组（可选）
function XLuckyTenant2Game:ExecuteRoundCalculation(model, animationGroups)
    -- 0. 递减所有棋盘上棋子的状态倒计时（在技能执行前）
    -- 收集过期的状态技能，确保它们能够执行
    local pieces = self._ChessBoard:GetAllPieces()
    local expiredStateSkills = {} -- 存储过期的状态技能 {piece, stateSkillId}

    for _, piece in ipairs(pieces) do
        local pieceId = piece:GetId()
        local pieceName = piece:GetName() or "未知"
        local x, y = piece:GetPosition()
        local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"

        -- 记录减少状态回合数前的状态信息
        local TriggerState = XLuckyTenant2Enum.TriggerState
        local deathStateBefore = piece:GetState(TriggerState.Death)
        local remainRoundsBefore = deathStateBefore and deathStateBefore:GetRemainRounds() or -1
        local expiredStates = piece:ReduceStateRounds(1)

        -- 收集过期的状态技能
        for _, expiredData in ipairs(expiredStates) do
            local stateSkillId = expiredData.stateSkillId
            local stateType = expiredData.stateType
            if stateSkillId and stateSkillId > 0 then
                table.insert(expiredStateSkills, {
                    piece = piece,
                    stateSkillId = stateSkillId,
                    stateType = stateType
                })
            end
        end
    end

    -- 1. 创建计算上下文
    local context = self:_CreateCalculationContext(model, animationGroups)

    -- 1.1. 清空回合级别的技能执行记录（每个回合开始时清空）
    context.proxy._RoundExecutedSkills = {}

    -- 1.5. 执行过期的状态技能（在正常技能执行前）
    if #expiredStateSkills > 0 then
        local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
        local XLuckyTenant2ChessSkill = require("XModule/XLuckyTenant2/Game/XLuckyTenant2ChessSkill")

        for i, expiredData in ipairs(expiredStateSkills) do
            local piece = expiredData.piece
            local stateSkillId = expiredData.stateSkillId
            local stateType = expiredData.stateType
            local pieceId = piece and piece:GetId() or 0
            local pieceName = piece and piece:GetName() or "未知"
            local x, y = 0, 0
            if piece then
                x, y = piece:GetPosition()
            end
            local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"

            -- 统一处理stateSkillId：先尝试作为技能类型查找，再尝试作为技能ID查找
            local actualSkillId, skillConfig = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
            local finalSkillId = actualSkillId or stateSkillId -- 如果找不到，直接使用原值

            if skillConfig then
                -- 创建技能并执行
                local skill = XLuckyTenant2ChessSkill.New()
                skill:Set(piece, finalSkillId, model)
                local skillContext = self:_CreateSkillContext(piece, context)
                -- 标记这是过期状态技能触发的，用于Type210判断
                skillContext.isExpiredStateSkill = true
                context.proxy:SetPieceAndSkill(piece, skill)
                local result = SkillExecutor.Execute(skill, skillContext)
                -- 立即执行操作
                context.proxy:ExecuteAllOperations(context.model, false)
            end
        end
    end

    -- 2. 执行技能循环（最多9次）
    self:_ExecuteSkillLoop(context)

    -- 3. 执行所有剩余的延迟删除（在所有技能执行完毕后统一处理）
    context.proxy:ExecuteDeferredDeletions()

    -- 4. 计算最终分数
    self:_CalculateFinalScore()
end

---创建计算上下文
---@param model XLuckyTenant2Model
---@param animationGroups table|false
---@return XLuckyTenant2CalculationContext 计算上下文
function XLuckyTenant2Game:_CreateCalculationContext(model, animationGroups)
    local XLuckyTenant2OperationProxy = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationProxy")
    return {
        model = model,
        animationGroups = animationGroups,
        proxy = XLuckyTenant2OperationProxy.New(self, model),
        round = self._Round,
        skillsByPriority = self:_CollectSkillsByPriority(model),
    }
end

---执行技能循环
---@param context XLuckyTenant2CalculationContext 计算上下文
function XLuckyTenant2Game:_ExecuteSkillLoop(context)
    local maxLoop = XLuckyTenant2Enum.GameConstants.MAX_SKILL_LOOP -- 技能循环最大次数

    for times = 1, maxLoop do
        context.times = times

        -- 执行所有优先级的技能
        local hasTriggered = self:_ExecuteSkillsByPriority(context)

        -- 如果没有技能被触发，结束循环
        if not hasTriggered then
            break
        end

        -- 重新收集技能（可能有新棋子产生）
        if times < maxLoop then
            context.skillsByPriority = self:_CollectSkillsByPriority(context.model)
            -- 清空执行状态，准备下一次循环
            context.proxy:ClearExecutionState()
        end
    end
end

---按优先级执行技能
---@param context XLuckyTenant2CalculationContext 计算上下文
---@return boolean 是否有技能被触发
function XLuckyTenant2Game:_ExecuteSkillsByPriority(context)
    local hasTriggered = false

    for priority = 0, 10 do
        local skills = context.skillsByPriority[priority]
        if #skills > 0 then
            -- 按棋盘顺序排序（从左到右，从上到下）
            -- 注意：每个优先级都需要排序，如果性能敏感可以考虑在收集时就按位置排序
            self:_SortSkillsByPosition(skills)

            -- 执行该优先级的所有技能（每个技能执行后立即执行其操作并创建动画组）
            for _, skillData in ipairs(skills) do
                local piece = skillData.piece

                -- 使用 rawget 安全检查，避免触发对象池的 __index
                if not piece or type(piece) ~= "table" then
                    goto continue_skill
                end

                -- 用 rawget 绕过元表检查 _IsDeleted
                local isDeleted = rawget(piece, "_IsDeleted")
                if isDeleted == nil then
                    -- _IsDeleted 字段不存在，说明对象已回池或不是 XLuckyTenant2Piece
                    goto continue_skill
                end

                if isDeleted then
                    -- 棋子已标记删除
                    goto continue_skill
                end

                if self:_ExecuteSkill(skillData, context) then
                    hasTriggered = true
                    -- 立即执行该技能的操作并创建动画组
                    self:_ExecuteSkillOperationsAndCreateAnimation(skillData, context)
                end

                ::continue_skill::
            end
        end
    end

    return hasTriggered
end

---执行单个技能
---@param skillData table 技能数据 {piece, skill, isStateSkill}
---@param context XLuckyTenant2CalculationContext 计算上下文
---@return boolean 是否执行成功
function XLuckyTenant2Game:_ExecuteSkill(skillData, context)
    local skill = skillData.skill
    local piece = skillData.piece
    local skillId = skill:GetId()
    local skillType = skill:GetType()

    -- 创建技能上下文
    local skillContext = self:_CreateSkillContext(piece, context)

    -- 检查技能是否满足执行条件
    if not skill:CanExecute(context.model, skillContext) then
        return false
    end

    -- 设置当前操作的棋子和技能
    context.proxy:SetPieceAndSkill(piece, skill)

    -- 执行技能（使用技能执行器）
    local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
    local success = SkillExecutor.Execute(skill, skillContext)

    return success
end

---执行技能的操作并创建动画组
---@param skillData table 技能数据 {piece, skill, isStateSkill}
---@param context XLuckyTenant2CalculationContext 计算上下文
function XLuckyTenant2Game:_ExecuteSkillOperationsAndCreateAnimation(skillData, context)
    if not context.animationGroups then
        -- 如果没有动画组，直接执行操作（兼容旧逻辑）
        context.proxy:ExecuteAllOperations(context.model, false)
        return
    end

    local skill = skillData.skill
    local piece = skillData.piece

    -- 保存当前操作包（仅当本技能产生过操作时才会 push；Type103 等只改数值不调 proxy 的技能不会 push）
    local ManyOperationPackages = context.proxy.ManyOperationPackages
    local countBefore = #ManyOperationPackages
    context.proxy:SaveOperationPackage()
    local extraAnimations = context.proxy:GetAndClearExtraAnimations()
    -- 若本技能未产生任何操作且无额外动画（如 Type103 只改数值），则不应复用上一个技能的包创建动画组
    if #ManyOperationPackages <= countBefore and (not extraAnimations or #extraAnimations == 0) then
        return
    end

    local animationDataList = nil
    if #ManyOperationPackages > countBefore then
        local operationPackage = ManyOperationPackages[#ManyOperationPackages]
        -- 执行操作并收集动画数据（注意：延迟删除会在所有技能执行完毕后统一处理）
        local XLuckyTenant2OperationContext = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationContext")
        local ctx = XLuckyTenant2OperationContext.New(self, context.model, context.proxy, context.animationGroups)
        animationDataList = operationPackage:Do(ctx)
    end
    -- 合并本技能仅播放的额外动画（如 Type508 原地生成新宝盒，不经过 Operation 但需播生成动画）
    if extraAnimations and #extraAnimations > 0 then
        if not animationDataList then
            animationDataList = {}
        end
        for _, anim in ipairs(extraAnimations) do
            animationDataList[#animationDataList + 1] = anim
        end
    end

    -- 注意：不在这里执行延迟删除，延迟删除会在 ExecuteRoundCalculation 的最后统一执行
    -- 这样可以避免在执行动画期间删除棋子，影响后续技能的触发

    -- 如果有动画数据，创建动画组（注入主动发动/受影响的格子动画）
    if animationDataList and #animationDataList > 0 then
        local AnimationType = XLuckyTenant2Enum.AnimationType
        local activatorUid = piece:GetUid()
        local ax, ay = piece:GetPosition()

        -- 先插入：主动发动技能的棋子动画
        local enrichedList = {
            { type = AnimationType.ActivateSkillEnable, pieceUid = activatorUid, x = ax, y = ay },
        }
        -- 收集受技能影响的格子（去重，排除发动者）
        local affectedSet = {} -- key = pieceUid or ("xy", x, y)
        for _, anim in ipairs(animationDataList) do
            local key, pieceUid, x, y
            if anim.type == AnimationType.GetScore then
                key = string.format("xy,%d,%d", anim.x or 0, anim.y or 0)
                pieceUid = nil
                x = anim.x
                y = anim.y
            elseif anim.type == AnimationType.DeletePiece then
                if anim.pieceUid == activatorUid then goto continue end
                key = "uid," .. tostring(anim.pieceUid or 0)
                pieceUid = anim.pieceUid
                x = anim.x
                y = anim.y
            elseif anim.type == AnimationType.UpdatePiece then
                if anim.pieceUid == activatorUid then goto continue end
                key = "uid," .. tostring(anim.pieceUid or 0)
                pieceUid = anim.pieceUid
                x = nil
                y = nil
            elseif anim.type == AnimationType.AddPiece then
                key = string.format("xy,%d,%d", anim.x or 0, anim.y or 0)
                pieceUid = nil
                x = anim.x
                y = anim.y
            else
                goto continue
            end
            if not affectedSet[key] then
                affectedSet[key] = true
                enrichedList[#enrichedList + 1] = {
                    type = AnimationType.AffectedBySkillEnable,
                    pieceUid = pieceUid,
                    x = x,
                    y = y,
                }
            end
            ::continue::
        end
        -- 再接上原有动画数据，并按固定顺序：先 AddPiece/UpdatePiece（先刷出棋子或数值变化），再 GetScore（飞分数），最后 DeletePiece
        local addPieceList = {}
        local updatePieceList = {}
        local getScoreList = {}
        local deletePieceList = {}
        for _, anim in ipairs(animationDataList) do
            if anim.type == AnimationType.AddPiece then
                addPieceList[#addPieceList + 1] = anim
            elseif anim.type == AnimationType.UpdatePiece then
                updatePieceList[#updatePieceList + 1] = anim
            elseif anim.type == AnimationType.GetScore then
                getScoreList[#getScoreList + 1] = anim
            elseif anim.type == AnimationType.DeletePiece then
                deletePieceList[#deletePieceList + 1] = anim
            end
        end
        for _, anim in ipairs(addPieceList) do enrichedList[#enrichedList + 1] = anim end
        for _, anim in ipairs(updatePieceList) do enrichedList[#enrichedList + 1] = anim end
        for _, anim in ipairs(getScoreList) do enrichedList[#enrichedList + 1] = anim end
        for _, anim in ipairs(deletePieceList) do enrichedList[#enrichedList + 1] = anim end

        local skillId = skill:GetId()
        local pieceUid = piece:GetUid()
        local XLuckyTenant2AnimationGroup = require("XModule/XLuckyTenant2/Game/Animation/XLuckyTenant2AnimationGroup")
        local isFirst = (#context.animationGroups == 0) -- 第一个动画组立即开始，不需要等待间隔
        local animationGroup = XLuckyTenant2AnimationGroup.New(skillId, pieceUid, enrichedList, isFirst)
        -- 含有格子特效（UpdatePiece/DeletePiece）的组延长最小显示时间，确保特效播完再进入下一步
        if #updatePieceList > 0 or #deletePieceList > 0 then
            animationGroup:SetMinDisplayTime(1.5)
        end

        -- 添加到动画组列表
        context.animationGroups[#context.animationGroups + 1] = animationGroup
    end

    -- 从操作包列表中移除（已执行完毕，但延迟删除保留到最终处理）
    table.remove(ManyOperationPackages, #ManyOperationPackages)
end

---创建技能上下文
---@param piece XLuckyTenant2Piece
---@param context XLuckyTenant2CalculationContext 计算上下文
---@return XLuckyTenant2SkillContext 技能上下文
function XLuckyTenant2Game:_CreateSkillContext(piece, context)
    return {
        piece = piece,
        skill = nil, -- 由SkillExecutor填充
        proxy = context.proxy,
        model = context.model,
        game = self,
        board = self._ChessBoard,
        bag = self._Bag,
        round = context.round,
        times = context.times,
    }
end

---收集技能并按优先级分组
---@param model XLuckyTenant2Model
---@return table 按优先级分组的技能表
function XLuckyTenant2Game:_CollectSkillsByPriority(model)
    local skillsByPriority = {}
    for priority = 0, 10 do
        skillsByPriority[priority] = {}
    end

    local pieces = self._ChessBoard:GetAllPieces()
    for _, piece in ipairs(pieces) do
        -- 添加调试日志：检查棋子状态
        local pieceId = piece and piece:GetId() or 0
        local TriggerState = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum").TriggerState
        local hasInfection = piece:HasState(TriggerState.Infection)
        self:_CollectPieceSkills(piece, skillsByPriority, model)
        self:_CollectStateSkills(piece, skillsByPriority, model)
    end

    return skillsByPriority
end

---收集棋子技能
---@param piece XLuckyTenant2Piece
---@param skillsByPriority table 技能优先级表
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_CollectPieceSkills(piece, skillsByPriority, model)
    local skills = piece:GetSkills(model)
    local pieceId = piece:GetId()

    -- XMVCA.XLuckyTenant2:Print(string.format("[_CollectPieceSkills] 棋子ID=%d 技能数量=%d",
    --     pieceId, skills and #skills or 0))

    if skills then
        for _, skill in ipairs(skills) do
            local skillId = skill:GetId()
            local skillType = skill:GetType()
            local priority = skill:GetPriority()
            local maxPriority = XLuckyTenant2Enum.GameConstants.MAX_SKILL_PRIORITY

            -- XMVCA.XLuckyTenant2:Print(string.format("[_CollectPieceSkills] 棋子ID=%d 技能ID=%d Type=%d 优先级=%d",
            --     pieceId, skillId, skillType, priority))

            if priority >= 0 and priority <= maxPriority then
                table.insert(skillsByPriority[priority], {
                    piece = piece,
                    skill = skill,
                    isStateSkill = false
                })
                -- XMVCA.XLuckyTenant2:Print(string.format("[_CollectPieceSkills] ✅ 已收集技能 - 棋子ID=%d 技能Type=%d",
                --     pieceId, skillType))
            else
                -- XMVCA.XLuckyTenant2:Print(string.format("[_CollectPieceSkills] ❌ 优先级无效 - 棋子ID=%d 技能Type=%d 优先级=%d",
                --     pieceId, skillType, priority))
            end
        end
        -- else
        --     XMVCA.XLuckyTenant2:Print(string.format("[_CollectPieceSkills] ❌ 棋子ID=%d 没有技能", pieceId))
    end
end

---收集状态技能
---@param piece XLuckyTenant2Piece
---@param skillsByPriority table 技能优先级表
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_CollectStateSkills(piece, skillsByPriority, model)
    local states = piece:GetAllStates()
    local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
    local TriggerState = XLuckyTenant2Enum.TriggerState

    for _, state in ipairs(states) do
        local stateSkillId = state:GetSkillId()
        local stateType = state:GetStateType()

        -- 添加调试日志（仅对子虫和死亡状态）
        if piece:GetId() == PieceId.Subworm and stateType == TriggerState.Death then
        end

        if stateSkillId > 0 then
            -- 统一处理stateSkillId：先尝试作为技能类型查找，再尝试作为技能ID查找
            local actualSkillId, skillConfig = SkillExecutor.ResolveStateSkillId(stateSkillId, model)
            local finalSkillId = actualSkillId or stateSkillId -- 如果找不到，直接使用原值

            if skillConfig then
                local skill = XLuckyTenant2ChessSkill.New()
                skill:Set(piece, finalSkillId, model)
                local priority = skill:GetPriority()
                local maxPriority = XLuckyTenant2Enum.GameConstants.MAX_SKILL_PRIORITY
                if priority >= 0 and priority <= maxPriority then
                    table.insert(skillsByPriority[priority], {
                        piece = piece,
                        skill = skill,
                        isStateSkill = true
                    })
                end
            end
        end
    end
end

---按位置排序技能
---@param skills table 技能数据数组
function XLuckyTenant2Game:_SortSkillsByPosition(skills)
    table.sort(skills, function(a, b)
        local ax, ay = 0, 0
        local bx, by = 0, 0

        -- 使用 rawget 安全获取 a.piece 的位置
        if a.piece and type(a.piece) == "table" then
            -- 检查对象是否有效（未回池）
            local isDeleted = rawget(a.piece, "_IsDeleted")
            if isDeleted == false then
                -- 对象有效，获取位置
                local x = rawget(a.piece, "_X")
                local y = rawget(a.piece, "_Y")
                if x and y then
                    ax, ay = x, y
                end
            end
        end

        -- 使用 rawget 安全获取 b.piece 的位置
        if b.piece and type(b.piece) == "table" then
            -- 检查对象是否有效（未回池）
            local isDeleted = rawget(b.piece, "_IsDeleted")
            if isDeleted == false then
                -- 对象有效，获取位置
                local x = rawget(b.piece, "_X")
                local y = rawget(b.piece, "_Y")
                if x and y then
                    bx, by = x, y
                end
            end
        end

        if ay ~= by then
            return ay > by -- 从上到下
        end
        return ax < bx     -- 从左到右
    end)
end

---计算最终分数
function XLuckyTenant2Game:_CalculateFinalScore()
    local pieces = self._ChessBoard:GetAllPieces()

    -- 清空当前回合的羁绊得分记录（重新计算）
    self._BondsIncomeThisRound = {}

    -- 如果羁绊管理器不存在，使用简单的计算方式
    if not self._BondManager then
        for _, piece in ipairs(pieces) do
            local value = piece:GetTotalValue()
            if value > 0 then
                self._ScoreThisRound = self._ScoreThisRound + value
            end
        end
    else
        -- 统计每个羁绊的得分
        for _, piece in ipairs(pieces) do
            local value = piece:GetTotalValue()
            if value > 0 then
                self._ScoreThisRound = self._ScoreThisRound + value

                -- 统计该棋子贡献给哪些羁绊的得分
                local pieceId = piece:GetId()
                local allBonds = self._BondManager:GetAllBonds()

                for _, bond in ipairs(allBonds) do
                    local bondId = bond:GetBondId()
                    local relatedChessForScoreIds = bond:GetRelatedChessForScoreIds()

                    -- 检查该棋子的ID是否在该羁绊的RelatedChessForScoreIds中
                    for _, relatedId in ipairs(relatedChessForScoreIds) do
                        if pieceId == relatedId then
                            -- 累加到该羁绊的得分（一个棋子可能为多个羁绊贡献得分）
                            if not self._BondsIncomeThisRound[bondId] then
                                self._BondsIncomeThisRound[bondId] = 0
                            end
                            self._BondsIncomeThisRound[bondId] = self._BondsIncomeThisRound[bondId] + value
                            break -- 该羁绊已经匹配，不需要继续检查该羁绊的其他相关棋子
                        end
                    end
                end
            end
        end
    end

    self._TotalScore = self._TotalScore + self._ScoreThisRound
    self._TotalScore = math.min(self._TotalScore, 9999)
end

-- ==================== 羁绊相关 ====================

---刷新羁绊等级（购买或删除棋子时调用）
---@param model XLuckyTenant2Model|nil 配置模型（可选）
function XLuckyTenant2Game:RefreshBondLevels(model)
    if self._BondManager then
        self._BondManager:RefreshBondLevels(self._Bag, model)
    end
end

---应用羁绊技能到棋子
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_ApplyBondSkillsToPieces(model)
    local pieces = self._ChessBoard:GetAllPieces()

    for _, piece in ipairs(pieces) do
        local pieceId = piece:GetId()
        local bondId = piece:GetBondId()

        -- 重置羁绊数值增量，保证升降级/移除技能能回退
        piece:ResetBondValueDeltas()
        -- 清除原有技能（保留状态技能）
        piece:ClearSkills()

        -- 应用羁绊技能
        self:_ApplyBondSkillsToPiece(piece, model)

        -- 添加棋子自身技能
        self:_ApplyPieceOwnSkills(piece, model)

        -- 应用状态技能（根据配置自动触发）
        self:_ApplyStateSkills(piece, model)

        -- 立即刷新基础金币/删除得分显示（不等回合执行）
        self:_ApplyImmediateValueSkillsToPiece(piece, model)

        -- 对于子虫（BondId为空的棋子），应用怪物羁绊技能（Type203/205/207）
        if not bondId or bondId == "" or bondId == "0" then
            self:ApplyMonsterSkillsToNewPiece(piece, model)
        end

        local skills = piece:GetSkills(model)
    end
end

---应用羁绊技能到单个棋子
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_ApplyBondSkillsToPiece(piece, model)
    local bondIdStr = piece:GetBondId()
    local pieceId = piece:GetId()

    if not bondIdStr or bondIdStr == "" then
        return
    end

    -- 解析多个羁绊ID（用|隔开）
    for bondIdStr in string.gmatch(bondIdStr, "([^|]+)") do
        local bondId = tonumber(bondIdStr)
        if bondId then
            local bond = self._BondManager:GetBond(bondId)
            if bond then
                local bondLevel = bond:GetLevel()
                if bondLevel > 0 then
                    -- 使用新方法获取该羁绊在当前等级下应该添加的所有技能配置
                    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
                    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
                        -- 检查等级条件（虽然 GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel 已经过滤了，但这里再次确认）
                        local configLevel = bondSkillConfig.Level or 0
                        if bondLevel >= configLevel then
                            local skillId = bondSkillConfig.SkillId
                            -- SkillId 可能是数组或数字，需要处理
                            if type(skillId) == "table" then
                                -- 如果是数组，取第一个元素
                                skillId = skillId[1] or 0
                            end

                            if skillId and skillId > 0 then
                                -- 获取技能配置
                                local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
                                if skillConfig then
                                    -- 创建技能上下文
                                    local context = {
                                        piece = piece,
                                        board = self._ChessBoard,
                                        bag = self._Bag,
                                        game = self,
                                        model = model,
                                    }

                                    -- 创建技能实例
                                    local skill = XLuckyTenant2ChessSkill.New()
                                    skill:Set(piece, skillId, model)

                                    -- 设置技能模式（用于区分相同SkillType但不同行为模式的技能，如3001和3003都是Type=301）
                                    local skillMode = bondSkillConfig.SkillMode or 0
                                    skill:SetSkillMode(skillMode)

                                    local skillType = skill:GetType()
                                    -- 检查技能是否满足执行条件
                                    local canExecute = skill:CanExecute(model, context)

                                    -- XMVCA.XLuckyTenant2:Print(string.format(
                                    --     "[_ApplyBondSkillsToPiece] 棋子ID=%d 羁绊ID=%d 技能ID=%d Type=%d CanExecute=%s",
                                    --     pieceId, bondId, skillId, skillType, tostring(canExecute)))

                                    if canExecute then
                                        if not piece._Skills then
                                            piece._Skills = {}
                                        end
                                        table.insert(piece._Skills, skill)
                                        -- XMVCA.XLuckyTenant2:Print(string.format(
                                        --     "[_ApplyBondSkillsToPiece] ✅ 已添加技能 - 棋子ID=%d 技能Type=%d",
                                        --     pieceId, skillType))

                                        -- 如果是Type503，立即更新已存在的死亡状态回合数（只在首次应用时生效）
                                        if skillType == SkillType.Type503 then
                                            local TriggerState = XLuckyTenant2Enum.TriggerState
                                            local deathState = piece:GetState(TriggerState.Death)
                                            if deathState and deathState:GetRemainRounds() > 0 then
                                                -- 获取死亡状态的原始回合数（从Type508的配置中读取）
                                                local deathSkillId = deathState:GetSkillId()
                                                local deathSkillConfig = model:GetLuckyTenant2ChessSkillConfigById(deathSkillId)
                                                local originalRounds = 3 -- 默认值
                                                if deathSkillConfig and deathSkillConfig.Params then
                                                    originalRounds = deathSkillConfig.Params[1] or 3
                                                end

                                                local currentRounds = deathState:GetRemainRounds()
                                                -- 只有当前回合数等于原始回合数时，才应用Type503的减少效果（避免重复减少）
                                                if currentRounds == originalRounds then
                                                    local params = skillConfig.Params or {}
                                                    local reduceRounds = params[1] or 0
                                                    local newRounds = math.max(1, currentRounds - reduceRounds)

                                                    if newRounds ~= currentRounds then
                                                        deathState:SetRemainRounds(newRounds)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

---统一添加或更新棋子状态（两处添加 state 均走此逻辑，避免重复与不一致）
---@param piece XLuckyTenant2Piece
---@param stateType number 状态类型（TriggerState）
---@param skillId number 技能ID
---@param rounds number 剩余回合数（-1 表示永久）
---@param model XLuckyTenant2Model|nil 配置模型（条件评估时需要）
---@param context table|nil 条件评估上下文（条件评估时需要）
---@param options table|nil 可选 { conditionId = number } 条件ID，非 0 时先评估条件
---@return boolean 是否应用了状态（新增或更新）
function XLuckyTenant2Game:ApplyStateToPiece(piece, stateType, skillId, rounds, model, context, options)
    options = options or {}
    local conditionId = options.conditionId
    if conditionId and conditionId > 0 and model and context then
        local XLuckyTenant2Condition = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Condition")
        if not XLuckyTenant2Condition.EvaluateById(model, conditionId, context) then
            return false
        end
    end
    local XLuckyTenant2State = require("XModule/XLuckyTenant2/Game/XLuckyTenant2State")
    if piece:HasState(stateType) then
        local state = piece:GetState(stateType)
        if state then
            state:SetSkillId(skillId)
            state:SetRemainRounds(rounds)
        end
        return true
    end
    local state = XLuckyTenant2State.New(stateType, skillId, rounds)
    piece:AddState(state)
    return true
end

---应用状态技能（根据配置自动触发，逻辑统一在 XLuckyTenant2StateApplier）
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_ApplyStateSkills(piece, model)
    XLuckyTenant2StateApplier.ApplyStateSkillsFromPieceConfig(self, piece, model)
end

---添加棋子自身技能
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_ApplyPieceOwnSkills(piece, model)
    local pieceSkillIds = piece._SkillId
    if not pieceSkillIds then
        return
    end

    if not piece._Skills then
        piece._Skills = {}
    end

    for i = 1, #pieceSkillIds do
        local skillId = pieceSkillIds[i]
        if skillId and skillId > 0 then
            local skill = XLuckyTenant2ChessSkill.New()
            skill:Set(piece, skillId, model)
            table.insert(piece._Skills, skill)
        end
    end
end

---刷新羁绊等级
---@param model XLuckyTenant2Model|nil 配置模型（可选）
function XLuckyTenant2Game:_RefreshBondLevels(model)
    if self._BondManager then
        self._BondManager:RefreshBondLevels(self._Bag, model)
    end
end

---羁绊等级变化回调（延迟处理：只标记需要刷新）
---@param bondId number 羁绊ID
---@param oldLevel number 旧等级
---@param newLevel number 新等级
function XLuckyTenant2Game:OnBondLevelChanged(bondId, oldLevel, newLevel)
    -- 延迟处理：只记录需要刷新的羁绊ID，实际刷新在 PlacePiecesOnBoard 等时机统一处理
    -- 这样可以避免 Game 和 BondManager 持有 Model 引用

    if XMVCA.XLuckyTenant2 then
    end

    if not self._BondsNeedRefresh then
        self._BondsNeedRefresh = {}
    end
    self._BondsNeedRefresh[bondId] = true
end

---处理羁绊等级变化（延迟处理的实际执行）
---@param model XLuckyTenant2Model
---@note 注意：在 PlacePiecesOnBoard 流程中，由于 _ApplyBondSkillsToPieces 会重新应用所有技能，
---      等级变化会自动被处理，所以此方法主要用于其他场景（如游戏过程中单独添加/删除棋子时）
function XLuckyTenant2Game:_ProcessBondLevelChanges(model)
    if not self._BondsNeedRefresh or next(self._BondsNeedRefresh) == nil then
        if XMVCA.XLuckyTenant2 then
        end
        return
    end

    -- 输出需要刷新的羁绊列表
    local bondsToRefresh = {}
    for bondId, _ in pairs(self._BondsNeedRefresh) do
        table.insert(bondsToRefresh, bondId)
    end
    if XMVCA.XLuckyTenant2 then
    end

    -- 获取棋盘上的棋子和背包中的棋子（包含新选择的棋子）
    local pieces = {}
    local boardPieces = self._ChessBoard:GetAllPieces()
    for _, piece in ipairs(boardPieces) do
        table.insert(pieces, piece)
    end
    local bagPieces = self._Bag:GetAllPieces()
    for _, piece in ipairs(bagPieces) do
        table.insert(pieces, piece)
    end

    -- 对每个需要刷新的羁绊，重新应用受影响棋子的技能
    for bondId, _ in pairs(self._BondsNeedRefresh) do
        local affectedPieces = {}

        -- 找出所有受影响的棋子（拥有该羁绊的棋子）
        for _, piece in ipairs(pieces) do
            local pieceBondId = piece:GetBondId()
            if pieceBondId and pieceBondId ~= "" then
                -- 检查棋子是否拥有该羁绊ID（支持多个羁绊，用|隔开）
                for bondIdStr in string.gmatch(pieceBondId, "([^|]+)") do
                    local pid = tonumber(bondIdStr)
                    if pid == bondId then
                        table.insert(affectedPieces, piece)
                        break
                    end
                end
            end
        end

        -- 重新应用这些棋子的技能
        -- 注意：需要清除技能（但不包括状态技能），然后重新应用
        for _, piece in ipairs(affectedPieces) do
            local pieceId = piece:GetId()
            local pieceName = model:GetLuckyTenant2ChessConfigById(pieceId)
            pieceName = pieceName and pieceName.Name or "未知"

            -- 重置羁绊数值增量，保证升降级/移除技能能回退
            piece:ResetBondValueDeltas()
            -- 清除原有技能（保留状态技能，因为状态技能与羁绊等级无关）
            piece:ClearSkills()

            -- 重新应用羁绊技能（会根据新的等级自动应用或移除技能）
            self:_ApplyBondSkillsToPiece(piece, model)

            -- 重新添加棋子自身技能
            self:_ApplyPieceOwnSkills(piece, model)

            -- 重新应用状态技能
            self:_ApplyStateSkills(piece, model)

            -- 立即刷新基础金币/删除得分显示（不等回合执行）
            self:_ApplyImmediateValueSkillsToPiece(piece, model)

            -- 输出技能列表
            local skills = piece:GetSkills()
            local skillIds = {}
            for _, skill in ipairs(skills) do
                table.insert(skillIds, skill:GetId())
            end
            if XMVCA.XLuckyTenant2 then
            end
        end
    end

    -- 清空刷新标记
    self._BondsNeedRefresh = nil
end

function XLuckyTenant2Game:_ApplyImmediateValueSkillsToPiece(piece, model)
    if not piece or not model then
        return
    end
    local skills = piece:GetSkills(model)
    if not skills then
        return
    end

    local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
    local XLuckyTenant2OperationProxy = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationProxy")
    local SkillType = XLuckyTenant2Enum.Skill
    local context = {
        piece = piece,
        model = model,
        game = self,
        board = self._ChessBoard,
        bag = self._Bag,
        round = self._Round,
        times = 0,
        proxy = XLuckyTenant2OperationProxy.New(self, model),
    }

    -- Type602 仅在「相邻棋子被消除」时在 OnDeleteEffects 中触发，不在此处执行
    local baseSkillTypes = {
        [SkillType.Type103] = true,
        [SkillType.Type105] = true,
        [SkillType.Type302] = true,
        [SkillType.Type202] = true,
        [SkillType.Type402] = true,
    }
    local deletionSkillTypes = {
        [SkillType.Type204] = true,
        [SkillType.Type507] = true,
    }

    for _, skill in ipairs(skills) do
        local skillType = skill:GetType()
        if baseSkillTypes[skillType] and skillType ~= SkillType.Type105 then
            SkillExecutor.Execute(skill, context)
        end
    end
    for _, skill in ipairs(skills) do
        if deletionSkillTypes[skill:GetType()] then
            SkillExecutor.Execute(skill, context)
        end
    end
    for _, skill in ipairs(skills) do
        if skill:GetType() == SkillType.Type105 then
            SkillExecutor.Execute(skill, context)
        end
    end
end

-- ==================== 状态更新 ====================

---更新棋子状态（回合结束时调用）
function XLuckyTenant2Game:UpdatePieceStates()
    local pieces = self._ChessBoard:GetAllPieces()
    for _, piece in ipairs(pieces) do
        piece:ReduceStateRounds(1)
    end
end

-- ==================== Getter/Setter ====================

---@return XLuckyTenant2BondManager
function XLuckyTenant2Game:GetBondManager()
    return self._BondManager
end

---@return table<number, number> 当前回合每个羁绊的得分 {bondId: score}
function XLuckyTenant2Game:GetBondsIncomeThisRound()
    return self._BondsIncomeThisRound
end

---@return XLuckyTenant2Bag
function XLuckyTenant2Game:GetBag()
    return self._Bag
end

---@return XLuckyTenant2ChessBoard
function XLuckyTenant2Game:GetChessBoard()
    return self._ChessBoard
end

---@return number
function XLuckyTenant2Game:GetRound()
    return self._Round
end

---@return number
function XLuckyTenant2Game:GetScoreThisRound()
    return self._ScoreThisRound
end

---@param value number
function XLuckyTenant2Game:SetScoreThisRound(value)
    self._ScoreThisRound = value
end

---@return number
function XLuckyTenant2Game:GetTotalScore()
    return self._TotalScore
end

---@return number
function XLuckyTenant2Game:GetStageId()
    return self._StageId
end

---获取当前回合开始时间戳（秒）
---@return number
function XLuckyTenant2Game:GetRoundStartTime()
    return self._RoundStartTime or 0
end

---@return number
function XLuckyTenant2Game:GetGameState()
    return self._GameState
end

---@param state number
function XLuckyTenant2Game:SetGameState(state)
    self._GameState = state
end

---获取当前游戏状态
---@return number
function XLuckyTenant2Game:GetState()
    return self._GameState
end

---设置游戏状态
---@param state number 游戏状态
function XLuckyTenant2Game:SetState(state)
    self._GameState = state
    -- XMVCA.XLuckyTenant2:Print("设置游戏状态:", state)
end

---进入下一个游戏状态
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:NextState(model)
    local gameState = self._GameState

    if gameState == GameState.ShowQuestGoalsOnFirstRound then
        self:SetState(GameState.SelectPiece)
        return
    end

    if gameState == GameState.SelectPiece then
        if self._HasSelectOrDelete then
            self:SetState(GameState.Roll)
        else
            XLog.Error("[XLuckyTenant2Game] 尚未选择棋子")
        end
        return
    end

    if gameState == GameState.Roll then
        self:SetState(GameState.Animation)
        return
    end

    if gameState == GameState.Animation then
        self:SetState(GameState.CheckQuestCompletionStatus)
        return
    end

    if gameState == GameState.CheckQuestCompletionStatus then
        local roundFin = self:GetRoundFin()
        local stateFromServer
        if roundFin and roundFin > 0 then
            if roundFin == 1 then
                stateFromServer = GameState.PerfectClear
            elseif roundFin == 2 then
                stateFromServer = GameState.GameOver
            end
        end

        -- 如果服务端已经标记游戏结束，使用服务端的状态
        if stateFromServer then
            self:SetState(stateFromServer)
            return
        end

        local currentRound = self:GetRound()
        local currentScore = self:GetTotalScore()

        -- 检查是否刚完成了一个阶段性任务
        local shouldShowQuestGoals = false
        local justCompletedQuest = nil

        -- 遍历所有任务，找到刚完成的任务（当前分数达标 且 尚未标记为完成）
        local justCompletedQuestIndex = 0
        for i = 1, #self._Quest do
            local quest = self._Quest[i]
            -- 检查：1. 当前回合 <= 任务回合；2. 当前分数 >= 任务目标分数；3. 任务尚未标记为完成
            if currentRound <= quest.Round and currentScore >= (quest.Score or 0) and not quest.PerfectClear and not quest.NormalClear then
                -- 找到了刚完成的任务
                justCompletedQuest = quest
                justCompletedQuestIndex = i
                -- 标记任务为完成（完美通关）
                quest.PerfectClear = true
                self._QuestHasBeenCompleted = self._QuestHasBeenCompleted + 1
                break
            end
        end

        if justCompletedQuest then
            -- 发放该任务配置的奖励道具棋子到背包（RewardPieces / RewardPiecesAmount）
            self:GrantQuestRewardPieces(model, justCompletedQuest)
            -- 检查刚完成的任务是否是最后一个任务
            local isLastQuest = (justCompletedQuestIndex >= #self._Quest)
            if not isLastQuest then
                -- 不是最后一个任务，检查是否还有下一个任务
                local nextQuest = self:GetNextQuest()
                if nextQuest then
                    -- 有下一个任务，显示目标达成弹窗
                    shouldShowQuestGoals = true
                end
            end
            -- 如果是最后一个任务，不显示弹窗，直接进入结算流程
        end

        if shouldShowQuestGoals then
            -- 显示目标达成弹窗
            self:SetState(GameState.ShowNextQuestGoals)
        else
            -- 检查是否还有下一个任务
            local nextQuest = self:GetNextQuest()

            if nextQuest then
                -- 还有任务，继续选择棋子
                self:SetState(GameState.SelectPiece)
            else
                -- 没有下一个任务了，说明所有任务都完成了或者当前回合已经超过了所有任务的Round
                -- 检查是否有完美通关的任务
                local hasPerfectClear = false
                for i = 1, #self._Quest do
                    local quest = self._Quest[i]
                    if quest and quest.PerfectClear then
                        hasPerfectClear = true
                        break
                    end
                end

                if hasPerfectClear then
                    self:SetState(GameState.PerfectClear)
                elseif self._IsNormalClear then
                    self:SetState(GameState.NormalClear)
                else
                    -- 没有达成通关条件，游戏失败
                    self:SetState(GameState.GameOver)
                end
            end
        end
        return
    end

    if gameState == GameState.ShowNextQuestGoals then
        self:SetState(GameState.SelectPiece)
        return
    end
end

---获取任务列表或指定回合的任务
---@param round number|nil 回合数（可选，如果提供则返回该回合的任务）
---@return XTableLuckyTenant2StageTask|XTableLuckyTenant2StageTask[]|nil
function XLuckyTenant2Game:GetQuest(round)
    if round then
        -- 返回指定回合的任务
        for i = 1, #self._Quest do
            local quest = self._Quest[i]
            if quest.Round == round then
                return quest
            end
        end
        return nil
    else
        -- 返回当前回合的任务（暂时返回第一个任务，后续根据实际需求调整）
        if #self._Quest > 0 then
            return self._Quest[1]
        end
        return nil
    end
end

---获取当前任务（当前阶段正在朝向的目标，用于界面显示目标分数/奖励等）
---@param round number|nil 回合数（默认当前回合）
---@return XTableLuckyTenant2StageTask|nil
function XLuckyTenant2Game:GetCurrentQuest(round)
    round = round or self:GetRound()

    -- 查找当前阶段目标：第一个 回合数 > 当前回合 的任务（即本阶段要达成的目标）
    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if quest and quest.Round > round then
            return quest
        end
    end

    -- 已超过所有任务回合，返回最后一个任务
    if #self._Quest > 0 then
        return self._Quest[#self._Quest]
    end
    return nil
end

---获取所有任务列表
---@return XTableLuckyTenant2StageTask[]
function XLuckyTenant2Game:GetAllQuest()
    return self._Quest
end

---@return number
function XLuckyTenant2Game:GetQuestHasBeenCompleted()
    return self._QuestHasBeenCompleted
end

---@return boolean
function XLuckyTenant2Game:IsNormalClear()
    return self._IsNormalClear
end

---@return boolean
function XLuckyTenant2Game:IsOver()
    return self._IsOver
end

---获取回合结束标记
---@return number|false 1=完美通关, 2=失败, false=未结束
function XLuckyTenant2Game:GetRoundFin()
    return self._RoundFin
end

---设置回合结束标记
---@param roundFin number|false 1=完美通关, 2=失败, false=未结束
function XLuckyTenant2Game:SetRoundFin(roundFin)
    self._RoundFin = roundFin
end

---获取下一个任务
---@param round number|nil 回合数（默认当前回合）
---@return XTableLuckyTenant2StageTask|nil
function XLuckyTenant2Game:GetNextQuest(round)
    round = round or self:GetRound()

    -- 先找到所有任务中的最大回合数
    local maxQuestRound = 0
    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if quest and quest.Round and quest.Round > maxQuestRound then
            maxQuestRound = quest.Round
        end
    end

    -- 如果当前回合已经超过或等于最大任务回合数，说明没有下一个任务了
    if maxQuestRound > 0 and round >= maxQuestRound then
        return nil
    end

    -- 查找下一个未完成的任务
    -- 任务按Round字段排序，找到第一个Round大于当前回合的任务
    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if quest and quest.Round and quest.Round > round then
            return quest
        end
    end

    -- 如果没有找到下一个任务，返回nil
    return nil
end

---检查是否完美通关
---@return boolean
function XLuckyTenant2Game:IsPerfectClear()
    return self._GameState == XLuckyTenant2Enum.GameState.PerfectClear
end

---获取游戏记录（用于服务器同步）
---@return table
function XLuckyTenant2Game:GetRecord4Server()
    return self._Record
end

---获取任务进度
---@return number 已完成任务数
---@return number 总任务数
function XLuckyTenant2Game:GetQuestProgress()
    return self._QuestHasBeenCompleted, #self._Quest
end

---恢复游戏状态
---@param model XLuckyTenant2Model
---@param record table 游戏记录
function XLuckyTenant2Game:Resume(model, record)
    self._Seed = XTime.GetServerNowTimestamp()
    math.randomseed(self._Seed)
    self._Round = record.Round
    self._TotalScore = record.Score

    -- 确保记录中包含StageId
    if not self._Record.StageId or self._Record.StageId <= 0 then
        self._Record.StageId = self._StageId
    end

    if self._Round == 1 then
        -- 恢复免费刷新次数（如果有刷新记录）
        -- record.SupplyRefresh 是已使用的刷新次数
        -- 暂时保持原有逻辑
        -- self._FreeRefreshTimes = math.max(0, self._FreeRefreshTimes - (record.SupplyRefresh or 0) + 1)
    end

    -- 恢复任务进度
    local questConfigs = model:GetStageTasks(self._StageId)

    -- 创建可修改的副本
    self._Quest = {}
    local questAmount = 0
    for i = 1, #questConfigs do
        local config = questConfigs[i]
        local isPerfectClear = false
        local isNormalClear = false

        -- 如果当前回合已经超过了任务回合，说明任务已完成
        -- TODO: 从服务端 record 中恢复实际的完成状态
        if config.Round < self._Round then
            questAmount = questAmount + 1
            isPerfectClear = true -- 暂时默认为完美通关
        elseif config.Round == self._Round then
            -- 当前回合的任务，需要检查分数
            if self._TotalScore >= config.Score then
                questAmount = questAmount + 1
                isPerfectClear = true
            end
        end

        self._Quest[i] = {
            Round = config.Round,
            Score = config.Score,
            Desc = config.Desc,
            RewardPieces = config.RewardPieces,
            RewardPiecesAmount = config.RewardPiecesAmount,
            PerfectClear = isPerfectClear,
            NormalClear = isNormalClear,
        }

        if isNormalClear then
            self._IsNormalClear = true
        end
    end
    self._QuestHasBeenCompleted = questAmount

    -- 根据 RoundProgress 恢复游戏状态
    local RoundProgress = XLuckyTenant2Enum.RoundProgress
    local roundProgress = record.RoundProgress or 0

    if roundProgress == RoundProgress.SelectPiece then
        -- 玩家在选棋阶段退出，恢复到选棋状态
        self._GameState = GameState.SelectPiece
        -- 如果有补充棋子记录，恢复选棋选项
        if record.SuppleChess and #record.SuppleChess > 0 then
            self._HasSupplyChess = true
            self._IsDirtyPiecesToSelect = false
            self:UpdateRandomBucket(model, true)
            self._PiecesToSelect = {}
            -- 从record中恢复补充的棋子到_PiecesToSelect
            for i = 1, #record.SuppleChess do
                local pieceId = record.SuppleChess[i]
                local piece = self._Bag:NewPiece(model, pieceId)
                self._PiecesToSelect[i] = piece
            end
        else
        end
    elseif roundProgress == RoundProgress.Roll then
        -- 玩家在Roll阶段退出，恢复到Roll状态
        self._GameState = GameState.Roll
    elseif roundProgress == RoundProgress.Animation then
        -- 玩家在动画阶段退出
        -- 客户端在动画补棋时回合数+1，服务端在播放动画前回合数+1
        -- 这个阶段其实是上一个回合的动画阶段，所以恢复游戏时手动-1
        self._Round = self._Round - 1
        self._GameState = GameState.CheckQuestCompletionStatus
    else
        -- 未知的RoundProgress，默认处理
        if record.Bag and #record.Bag > 0 and (not record.SuppleChess or #record.SuppleChess == 0) then
            self._GameState = GameState.Roll
        else
            self._GameState = GameState.SelectPiece
        end
    end

    -- 恢复背包数据
    local bag = record.Bag
    if bag then
        for _, pieceData in pairs(bag) do
            local pieceId = pieceData.ChessId
            local uid = pieceData.Uid
            local isSuccess, piece = self:AddNewPieceToBag(model, pieceId, uid)
            if isSuccess and piece then
                if pieceData.ChessParams then
                    local message = XMessagePack.Decode(pieceData.ChessParams)
                    piece:DecodeMessage(message)
                end
            else
                XLog.Warning("[XLuckyTenant2Game] 恢复棋子失败: ChessId=" .. tostring(pieceId) .. ", Uid=" .. tostring(uid))
            end
        end
    end
    -- 恢复背包后初始化道具到 _Props（Bag:Init 在 isResumeGame 时跳过了 InitProps）
    self._Bag:InitProps(self, model)

    -- 恢复棋盘数据
    local chessboard = record.ChessBoard
    if chessboard then
        local PropId = XLuckyTenant2Enum.PropId
        for i = 1, #chessboard do
            local uid = chessboard[i]
            if uid and uid > 0 then
                local piece = self._Bag:GetPieceByUid(uid)
                if piece then
                    -- 过滤道具（刷新/删除道具不放到棋盘上）
                    local pieceId = piece:GetId()
                    if pieceId == PropId.RefreshProp or pieceId == PropId.DeleteProp then
                        XLog.Debug("[XLuckyTenant2Game] 恢复棋盘跳过道具: Uid=" .. tostring(uid) .. ", PieceId=" .. tostring(pieceId))
                    else
                        self._ChessBoard:SetPieceByIndex(piece, i)
                    end
                else
                    XLog.Warning("[XLuckyTenant2Game] 恢复棋盘失败，找不到棋子: Uid=" .. tostring(uid))
                end
            end
        end
    end
end

---检查是否游戏结束
---@return boolean
function XLuckyTenant2Game:IsGameOver()
    return self._GameState == GameState.GameOver or self._IsOver
end

return XLuckyTenant2Game
