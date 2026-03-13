local XLuckyTenant2ChessBoard = require("XModule/XLuckyTenant2/Game/XLuckyTenant2ChessBoard")
local XLuckyTenant2SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
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
---@field initialBoardPieceUidSet table<number, boolean> 回合计算开始时棋盘上已有棋子UID集合
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
    ---@type boolean 本回合是否使用固定池（在 UpdateRandomBucket 中根据是否有预设棋子设置，用于刷新按钮判断）
    self._RoundUsesFixedPool = false

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
    self._CachedSkillIdByType = {} -- { [skillType] = skillId | false } false 表示已查过但不存在

    -- 技能执行器（持有各子执行器）
    ---@type XLuckyTenant2SkillExecutor
    self._SkillExecutor = XLuckyTenant2SkillExecutor.New()
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
    self._SkillExecutor:InitStateSkillIds(model)

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
    self._IsNormalClear = false
    self._QuestHasBeenCompleted = 0
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
    -- 1. 将背包棋子放置到棋盘上（会设置棋子位置，使IsOnBoard返回true）
    if self._TestCase then
        self._ChessBoard:SetTestCase(self, model, self._Bag, self._TestCase)
    else
        self._ChessBoard:SetPieces(self._Bag)
    end

    -- 2. 刷新羁绊等级（基于Bag计算，此时棋子已在棋盘上，可以正确计算）
    self:_RefreshBondLevels(model)

    -- 3. 处理羁绊等级变化（如果有变化，会标记到_BondsNeedRefresh）
    self:_ProcessBondLevelChanges(model)

    -- 4. 应用羁绊技能到棋子（会根据当前等级重新应用所有技能）
    self:_ApplyBondSkillsToPieces(model)
end

---设置测试用例，同时将缺少的棋子预先补充到背包
---@param model XLuckyTenant2Model 配置模型
---@param testCase table 测试用例棋子ID列表
function XLuckyTenant2Game:SetTestCase(model, testCase)
    self._TestCase = testCase

    -- 预先补全缺少的棋子到背包，避免等到回合开始才创建
    if not model or not testCase or not self._Bag then
        return
    end

    local usedPiece = {}
    for i = 1, #testCase do
        local pieceId = testCase[i]
        if pieceId and pieceId ~= 0 then
            local piece = self._Bag:FindPiece(pieceId, usedPiece)
            if not piece or usedPiece[piece:GetUid()] then
                local isSuccess
                isSuccess, piece = self:AddNewPieceToBag(model, pieceId)
            end
            if piece then
                usedPiece[piece:GetUid()] = true
            else
                XLog.Warning("[XLuckyTenant2Game] SetTestCase预创建棋子失败，pieceId=" .. tostring(pieceId))
            end
        end
    end
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
    -- 移除 bondLevel <= 0 的提前返回，允许 Level=0 的技能在羁绊等级=0时生效
    -- 后续通过 bondLevel >= configLevel 判断来决定是否处理技能

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
                        local bugPieceId = params[1] or 0 -- 子虫棋子ID（0表示所有子虫）

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
        -- local size = #self._PiecesToSelect
        -- for i = 1, size do
        --     local piece = self._PiecesToSelect[i]
        --     if piece then
        --         -- TODO: 根据实际对象池实现调整
        --         -- self._Bag:EnterPool(piece)
        --     end
        -- end
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

    -- 测试模式：将所有选项替换为金币，避免选棋影响技能测试
    if self._TestCase then
        for i = 1, #self._PiecesToSelect do
            local uid = self._Bag:GetNewUid()
            local piece = self._Bag:NewPiece(model, 16, uid)
            if piece then
                self._PiecesToSelect[i] = piece
            end
        end
    end
end

---获取本回合需要选择的棋子数量
---@return number
function XLuckyTenant2Game:GetAmountOfPiecesToSelect()
    return self._AmountOfPiecesToSelect or 3
end

---获取固定池当前数量（用于刷新按钮显隐等判断）
---@return number
function XLuckyTenant2Game:GetPiecesFixedBucketSize()
    return #(self._PiecesFixedBucket or {})
end

---获取随机池当前数量（用于刷新按钮显隐等判断）
---@return number
function XLuckyTenant2Game:GetPiecesRandomBucketSize()
    return #(self._PiecesRandomBucket or {})
end

---刷新选项是否可用：本回合若使用固定池则按固定池剩余数量判断，否则按随机池数量判断
---（固定池在 RefreshOptions 中会被消耗，故用 UpdateRandomBucket 时记录的 _RoundUsesFixedPool 区分）
---@return boolean
function XLuckyTenant2Game:IsRefreshOptionAvailable()
    local needAmount = self:GetAmountOfPiecesToSelect()
    if self._RoundUsesFixedPool then
        return self:GetPiecesFixedBucketSize() > needAmount
    end
    return self:GetPiecesRandomBucketSize() > needAmount
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
    -- 记录本回合是否使用固定池（RefreshOptions 会消耗固定池，判断刷新时用此标记决定看固定池还是随机池数量）
    self._RoundUsesFixedPool = (#self._PiecesFixedBucket > 0)

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
    -- 在每回合“重新计算分数”开始前重置回合得分与羁绊收益
    -- 这样上一回合数据会一直保留到下一次实际计算开始
    self._ScoreThisRound = 0
    self._BondsIncomeThisRound = {}

    -- 0. 递减所有棋盘上棋子的状态倒计时（在技能执行前）
    -- 收集过期的状态技能，确保它们能够执行
    local pieces = self._ChessBoard:GetAllPieces()
    local expiredStateSkills = {}       -- 存储过期的状态技能 {piece, stateSkillId}
    local countdownDecreasedPieces = {} -- 倒计时被减少的棋子，用于播放沙漏特效

    for _, piece in ipairs(pieces) do
        local x, y = piece:GetPosition()

        -- 记录减少前是否有正数倒计时状态
        local hadPositiveCountdown = false
        for _, state in pairs(piece:GetAllStates()) do
            local r = state:GetRemainRounds()
            if r and r > 0 then
                hadPositiveCountdown = true
                break
            end
        end

        -- 记录减少状态回合数前的状态信息
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

        -- 收集倒计时被减少的棋子（用于播放沙漏特效）
        if hadPositiveCountdown then
            local pieceUid = piece:GetUid()
            if pieceUid and pieceUid > 0 and x and y and x > 0 and y > 0 then
                table.insert(countdownDecreasedPieces, {
                    pieceUid = pieceUid,
                    x = x,
                    y = y,
                })
            end
        end
    end

    -- 记录回合计算开始时的棋盘棋子UID；用于限制“本回合新生成棋子”触发特定技能
    local initialBoardPieceUidSet = {}
    for _, piece in ipairs(pieces) do
        if piece then
            local uid = piece:GetUid()
            if uid and uid > 0 then
                initialBoardPieceUidSet[uid] = true
            end
        end
    end

    -- 1. 创建计算上下文
    local context = self:_CreateCalculationContext(model, animationGroups, initialBoardPieceUidSet)

    -- 1.1. 清空回合级别的技能执行记录（每个回合开始时清空）
    context.proxy._RoundExecutedSkills = {}

    -- 1.2. 为倒计时减少的棋子创建动画组（播放沙漏特效）
    if animationGroups and #countdownDecreasedPieces > 0 then
        local XLuckyTenant2AnimationGroup = require("XModule/XLuckyTenant2/Game/Animation/XLuckyTenant2AnimationGroup")
        local AnimationType = XLuckyTenant2Enum.AnimationType
        local animDataList = {}
        for _, data in ipairs(countdownDecreasedPieces) do
            animDataList[#animDataList + 1] = {
                type = AnimationType.Countdown,
                pieceUid = data.pieceUid,
                x = data.x,
                y = data.y,
            }
        end
        local isFirst = (#animationGroups == 0)
        local animGroup = XLuckyTenant2AnimationGroup.New(0, 0, animDataList, isFirst)
        animGroup:SetIsCountdown(true)
        table.insert(animationGroups, 1, animGroup)
    end

    -- 1.5. 执行过期的状态技能（在正常技能执行前）
    if #expiredStateSkills > 0 then
        local XLuckyTenant2ChessSkill = require("XModule/XLuckyTenant2/Game/XLuckyTenant2ChessSkill")

        for i, expiredData in ipairs(expiredStateSkills) do
            local piece = expiredData.piece
            local stateSkillId = expiredData.stateSkillId
            local x, y = 0, 0
            if piece then
                x, y = piece:GetPosition()
            end

            -- 统一处理stateSkillId：先尝试作为技能类型查找，再尝试作为技能ID查找
            local actualSkillId, skillConfig = self._SkillExecutor:ResolveStateSkillId(stateSkillId, model)
            local finalSkillId = actualSkillId or stateSkillId -- 如果找不到，直接使用原值

            if skillConfig then
                -- 创建技能并执行
                local skill = XLuckyTenant2ChessSkill.New()
                skill:Set(piece, finalSkillId, model)
                local skillContext = self:_CreateSkillContext(piece, context)
                -- 标记这是过期状态技能触发的，用于Type210判断
                skillContext.isExpiredStateSkill = true
                context.proxy:SetPieceAndSkill(piece, skill)
                local result = self._SkillExecutor:Execute(skill, skillContext)
                -- 执行操作并收集动画数据（与正常技能走同一条路径）
                local skillData = { piece = piece, skill = skill, x = x, y = y }
                self:_ExecuteSkillOperationsAndCreateAnimation(skillData, context, result)
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
---@param initialBoardPieceUidSet table<number, boolean>|nil
---@return XLuckyTenant2CalculationContext 计算上下文
function XLuckyTenant2Game:_CreateCalculationContext(model, animationGroups, initialBoardPieceUidSet)
    local XLuckyTenant2OperationProxy = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationProxy")
    return {
        model = model,
        animationGroups = animationGroups,
        proxy = XLuckyTenant2OperationProxy.New(self, model),
        round = self._Round,
        initialBoardPieceUidSet = initialBoardPieceUidSet,
        skillsByPriority = self:_CollectSkillsByPriority(model, initialBoardPieceUidSet),
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
            context.skillsByPriority = self:_CollectSkillsByPriority(context.model, context.initialBoardPieceUidSet)
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
    local success = self._SkillExecutor:Execute(skill, skillContext)

    return success
end

---执行技能的操作并创建动画组
---@param skillData table 技能数据 {piece, skill, isStateSkill}
---@param context XLuckyTenant2CalculationContext 计算上下文
function XLuckyTenant2Game:_ExecuteSkillOperationsAndCreateAnimation(skillData, context)
    if not context.animationGroups then
        -- 如果没有动画组，直接执行操作（兼容旧逻辑）
        context.proxy:ExecuteAllOperations(context.model)
        return
    end

    -- 保存当前操作包并获取额外动画
    local ManyOperationPackages = context.proxy.ManyOperationPackages
    local countBefore = #ManyOperationPackages
    context.proxy:SaveOperationPackage()
    local extraAnimations = context.proxy:GetAndClearExtraAnimations()

    -- 若本技能未产生任何操作且无额外动画，跳过
    local hasNewPackage = #ManyOperationPackages > countBefore
    local hasExtraAnims = extraAnimations and #extraAnimations > 0
    if not hasNewPackage and not hasExtraAnims then
        return
    end

    -- 收集动画数据
    local animationDataList = self:_CollectAnimationDataList(context, ManyOperationPackages, countBefore, extraAnimations)
    if not animationDataList or #animationDataList == 0 then
        -- 即使没有动画数据，也需要移除已执行的操作包
        if hasNewPackage then
            table.remove(ManyOperationPackages, #ManyOperationPackages)
        end
        return
    end

    -- 如果技能执行成功, 添加一个额外动画Duang
    local duangAnim = {
        type = XLuckyTenant2Enum.AnimationType.Duang,
        x = skillData.x,
        y = skillData.y,
    }
    table.insert(animationDataList, 1, duangAnim)

    -- 创建动画组
    self:_CreateAnimationGroup(skillData, context, animationDataList)

    -- 从操作包列表中移除（已执行完毕，延迟删除保留到最终处理）
    if hasNewPackage then
        table.remove(ManyOperationPackages, #ManyOperationPackages)
    end
end

---收集动画数据列表（执行操作包 + 合并额外动画）
---@param context XLuckyTenant2CalculationContext 计算上下文
---@param ManyOperationPackages table 操作包列表
---@param countBefore number 保存前的操作包数量
---@param extraAnimations table|nil 额外动画
---@return table|nil 动画数据列表
function XLuckyTenant2Game:_CollectAnimationDataList(context, ManyOperationPackages, countBefore, extraAnimations)
    local animationDataList = nil

    -- 执行新产生的操作包
    if #ManyOperationPackages > countBefore then
        local operationPackage = ManyOperationPackages[#ManyOperationPackages]
        local XLuckyTenant2OperationContext = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationContext")
        local ctx = XLuckyTenant2OperationContext.New(self, context.model, context.proxy, context.animationGroups)
        animationDataList = operationPackage:Do(ctx)
    end

    -- 合并额外动画（如 Type508 原地生成新宝盒）
    if extraAnimations and #extraAnimations > 0 then
        animationDataList = animationDataList or {}
        for _, anim in ipairs(extraAnimations) do
            animationDataList[#animationDataList + 1] = anim
        end
    end

    return animationDataList
end

---动画排序权重（数值小的先播放）：AddPiece/UpdatePiece → GetScore → DeletePiece
local _AnimSortOrder = {
    [XLuckyTenant2Enum.AnimationType.AddPiece] = 0,
    [XLuckyTenant2Enum.AnimationType.UpdatePiece] = 1,
    [XLuckyTenant2Enum.AnimationType.GetScore] = 2,
    [XLuckyTenant2Enum.AnimationType.InfectionSourceEnable] = 3,
    [XLuckyTenant2Enum.AnimationType.DeletePiece] = 4,
}

---创建动画组（注入主动发动/受影响的格子动画，按类型排序）
---@param skillData table 技能数据 {piece, skill}
---@param context XLuckyTenant2CalculationContext 计算上下文
---@param animationDataList table 动画数据列表
function XLuckyTenant2Game:_CreateAnimationGroup(skillData, context, animationDataList)
    local piece = skillData.piece
    local skill = skillData.skill
    local AnimationType = XLuckyTenant2Enum.AnimationType
    local skillType = skill and skill:GetType() or 0
    local activatorUid = piece:GetUid()
    local ax, ay = piece:GetPosition()

    -- 主动发动技能的棋子动画
    local enrichedList = {
        { type = AnimationType.ActivateSkillEnable, pieceUid = activatorUid, x = ax, y = ay },
    }

    -- 收集受技能影响的格子（去重，排除发动者）
    local affectedSet = {}
    local hasUpdate = false
    local hasDelete = false

    for _, anim in ipairs(animationDataList) do
        local info = self:_ExtractAffectedAnimInfo(anim, activatorUid)
        if info then
            if not affectedSet[info.key] then
                affectedSet[info.key] = true
                enrichedList[#enrichedList + 1] = {
                    type = AnimationType.AffectedBySkillEnable,
                    pieceUid = info.pieceUid,
                    x = info.x,
                    y = info.y,
                    fromPieceUid = anim.fromPieceUid or activatorUid,
                }
            end
        end
        -- 记录是否包含 UpdatePiece/DeletePiece（用于设置最小显示时间）
        local animType = anim.type
        if animType == AnimationType.UpdatePiece then
            hasUpdate = true
        elseif animType == AnimationType.DeletePiece then
            hasDelete = true
        end
    end

    -- Type304 + Type305（鞭尸）：
    -- 304 会追加 skillId=305 的 AffectedBySkillEnable 额外动画，
    -- 这些动画必须放在 DeletePiece 之前，且紧跟在上面的 AffectedBySkillEnable 之后。
    if skillType == SkillType.Type304 and context and context.model then
        local remainAnims = {}
        for _, anim in ipairs(animationDataList) do
            local moveBeforeDelete = false
            if anim.type == AnimationType.AffectedBySkillEnable then
                local animSkillId = anim.skillId or 0
                local animSkillType = (animSkillId > 0) and context.model:GetLuckyTenant2ChessSkillTypeById(animSkillId) or 0
                moveBeforeDelete = (animSkillType == SkillType.Type305)
            end

            if moveBeforeDelete then
                enrichedList[#enrichedList + 1] = anim
            else
                remainAnims[#remainAnims + 1] = anim
            end
        end
        animationDataList = remainAnims
    end

    -- 按固定顺序排序：AddPiece/UpdatePiece → GetScore → DeletePiece
    table.sort(animationDataList, function(a, b)
        return (_AnimSortOrder[a.type] or 99) < (_AnimSortOrder[b.type] or 99)
    end)

    -- 追加排序后的动画数据
    for _, anim in ipairs(animationDataList) do
        enrichedList[#enrichedList + 1] = anim
    end

    -- 创建动画组
    local XLuckyTenant2AnimationGroup = require("XModule/XLuckyTenant2/Game/Animation/XLuckyTenant2AnimationGroup")
    local isFirst = (#context.animationGroups == 0)
    local animationGroup = XLuckyTenant2AnimationGroup.New(skill:GetId(), activatorUid, enrichedList, isFirst)

    -- 含有格子特效的组延长最小显示时间，确保特效播完再进入下一步
    if hasUpdate or hasDelete then
        animationGroup:SetMinDisplayTime(1.5)
    end

    context.animationGroups[#context.animationGroups + 1] = animationGroup
end

---从单个动画数据中提取受影响格子信息（用于去重和注入 AffectedBySkillEnable）
---@param anim table 动画数据
---@param activatorUid number 发动者的 UID（需排除）
---@return table|nil 返回 {key, pieceUid, x, y}，不匹配时返回 nil
function XLuckyTenant2Game:_ExtractAffectedAnimInfo(anim, activatorUid)
    local AnimationType = XLuckyTenant2Enum.AnimationType
    local animType = anim.type

    if animType == AnimationType.GetScore then
        return {
            key = string.format("xy,%d,%d", anim.x or 0, anim.y or 0),
            pieceUid = nil,
            x = anim.x,
            y = anim.y,
        }
    end

    if animType == AnimationType.DeletePiece then
        if anim.pieceUid == activatorUid then
            return nil
        end
        return {
            key = "uid," .. tostring(anim.pieceUid or 0),
            pieceUid = anim.pieceUid,
            x = anim.x,
            y = anim.y,
        }
    end

    if animType == AnimationType.UpdatePiece then
        if anim.pieceUid == activatorUid then
            return nil
        end
        return {
            key = "uid," .. tostring(anim.pieceUid or 0),
            pieceUid = anim.pieceUid,
            x = nil,
            y = nil,
        }
    end

    if animType == AnimationType.AddPiece then
        return {
            key = string.format("xy,%d,%d", anim.x or 0, anim.y or 0),
            pieceUid = nil,
            x = anim.x,
            y = anim.y,
        }
    end

    return nil
end

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
---@param initialBoardPieceUidSet table<number, boolean>|nil 回合开始时棋盘已有棋子UID
---@return table 按优先级分组的技能表
function XLuckyTenant2Game:_CollectSkillsByPriority(model, initialBoardPieceUidSet)
    local skillsByPriority = {}
    for priority = 0, 10 do
        skillsByPriority[priority] = {}
    end

    local pieces = self._ChessBoard:GetAllPieces()
    for _, piece in ipairs(pieces) do
        self:_CollectPieceSkills(piece, skillsByPriority, model, initialBoardPieceUidSet)
        self:_CollectStateSkills(piece, skillsByPriority, model)
    end

    return skillsByPriority
end

---收集棋子技能
---@param piece XLuckyTenant2Piece
---@param skillsByPriority table 技能优先级表
---@param model XLuckyTenant2Model
---@param initialBoardPieceUidSet table<number, boolean>|nil 回合开始时棋盘已有棋子UID
function XLuckyTenant2Game:_CollectPieceSkills(piece, skillsByPriority, model, initialBoardPieceUidSet)
    local skills = piece:GetSkills(model)
    if not skills then
        return
    end

    local pieceUid = piece:GetUid()
    local isNewPieceInCurrentRound = initialBoardPieceUidSet and not initialBoardPieceUidSet[pieceUid]
    local maxPriority = XLuckyTenant2Enum.GameConstants.MAX_SKILL_PRIORITY
    for _, skill in ipairs(skills) do
        -- 仅限制本回合新生成棋子的 Type304 不发动；其他技能不受影响
        local skipThisSkill = isNewPieceInCurrentRound and skill:GetType() == SkillType.Type304
        if not skipThisSkill then
            local priority = skill:GetPriority()
            if priority >= 0 and priority <= maxPriority then
                skillsByPriority[priority][#skillsByPriority[priority] + 1] = {
                    piece = piece,
                    skill = skill,
                    isStateSkill = false
                }
            end
        end
    end
end

---收集状态技能
---@param piece XLuckyTenant2Piece
---@param skillsByPriority table 技能优先级表
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_CollectStateSkills(piece, skillsByPriority, model)
    local states = piece:GetAllStates()
    local TriggerState = XLuckyTenant2Enum.TriggerState

    for _, state in ipairs(states) do
        local stateSkillId = state:GetSkillId()
        local stateType = state:GetStateType()

        -- 添加调试日志（仅对子虫和死亡状态）
        if piece:GetId() == PieceId.Subworm and stateType == TriggerState.Death then
        end

        if stateSkillId > 0 then
            -- 统一处理stateSkillId：先尝试作为技能类型查找，再尝试作为技能ID查找
            local actualSkillId, skillConfig = self._SkillExecutor:ResolveStateSkillId(stateSkillId, model)
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

---同位置时技能类型执行顺序（数值小的先执行）：先升级后融合，Type405 在 Type401 前
local _SkillTypeOrderForSort = {
    [SkillType.Type405] = 0, -- 武器羁绊lv3 相邻升级，先执行
    [SkillType.Type401] = 1, -- 武器融合，后执行
}

---按位置排序技能；同位置时按技能类型顺序（如 Type405 先于 Type401）
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
            return ay < by -- 从上到下
        end
        if ax ~= bx then
            return ax < bx -- 从左到右
        end
        -- 同位置（同一棋子）：按技能类型顺序，先升级(Type405)后融合(Type401)
        local orderA = _SkillTypeOrderForSort[a.skill and a.skill:GetType() or 0] or 99
        local orderB = _SkillTypeOrderForSort[b.skill and b.skill:GetType() or 0] or 99
        return orderA < orderB
    end)
end

---计算最终分数
function XLuckyTenant2Game:_CalculateFinalScore()
    local pieces = self._ChessBoard:GetAllPieces()

    -- 如果羁绊管理器不存在，使用简单的计算方式
    if not self._BondManager then
        for _, piece in ipairs(pieces) do
            local value = piece:GetTotalValue()
            if value > 0 then
                self:AddScoreThisRound(value, piece)
            end
        end
    else
        -- 统计每个羁绊的得分（存活棋子基础价值）
        for _, piece in ipairs(pieces) do
            local value = piece:GetTotalValue()
            if value > 0 then
                self:AddScoreThisRound(value, piece)
            end
        end
    end

    self._TotalScore = self._TotalScore + self._ScoreThisRound
    self._TotalScore = math.min(self._TotalScore, 999999)
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
    if not bondIdStr or bondIdStr == "" then
        return
    end

    -- 延迟创建上下文，所有羁绊技能共用同一个
    local context = nil

    -- 解析多个羁绊ID（用|隔开）
    for singleBondStr in string.gmatch(bondIdStr, "([^|]+)") do
        context = self:_ApplyBondSkillsForOneBond(piece, model, singleBondStr, context)
    end
end

---处理单个羁绊的技能应用
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param bondIdStr string 单个羁绊ID字符串
---@param context table|nil 共享上下文（延迟创建）
---@return table|nil 更新后的上下文
function XLuckyTenant2Game:_ApplyBondSkillsForOneBond(piece, model, bondIdStr, context)
    local bondId = tonumber(bondIdStr)
    if not bondId then
        return context
    end

    local bond = self._BondManager:GetBond(bondId)
    if not bond then
        return context
    end

    local bondLevel = bond:GetLevel()
    -- 需要兼容羁绊等级为0的情况（被动技能）
    if bondLevel < 0 then
        return context
    end

    local bondSkillConfigs = model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        context = self:_TryApplyOneBondSkill(piece, model, bondSkillConfig, context)
    end

    return context
end

---尝试应用单个羁绊技能配置到棋子
---@param piece XLuckyTenant2Piece
---@param model XLuckyTenant2Model
---@param bondSkillConfig table 羁绊技能配置
---@param context table|nil 共享上下文
---@return table|nil 更新后的上下文
function XLuckyTenant2Game:_TryApplyOneBondSkill(piece, model, bondSkillConfig, context)
    local skillId = self:_ResolveBondSkillId(bondSkillConfig)
    if skillId <= 0 then
        return context
    end

    local skillConfig = model:GetLuckyTenant2ChessSkillConfigById(skillId)
    if not skillConfig then
        return context
    end

    -- 创建技能实例
    local skill = XLuckyTenant2ChessSkill.New()
    skill:Set(piece, skillId, model)
    skill:SetSkillMode(bondSkillConfig.SkillMode or 0)

    -- 延迟创建上下文（仅在第一次需要时创建）
    if not context then
        context = {
            piece = piece,
            board = self._ChessBoard,
            bag = self._Bag,
            game = self,
            model = model,
        }
    end

    if not skill:CanExecute(model, context) then
        return context
    end

    -- 添加技能到棋子
    if not piece._Skills then
        piece._Skills = {}
    end
    piece._Skills[#piece._Skills + 1] = skill

    -- Type503：立即更新已存在的死亡状态回合数（首次应用时生效）
    if skill:GetType() == SkillType.Type503 then
        self:_ApplyType503DeathReduction(piece, skillConfig, model)
    end

    return context
end

---解析羁绊技能配置中的 SkillId（兼容数组和数字两种格式）
---@param bondSkillConfig table 羁绊技能配置
---@return number skillId（无效时返回0）
function XLuckyTenant2Game:_ResolveBondSkillId(bondSkillConfig)
    local skillId = bondSkillConfig.SkillId
    if type(skillId) == "table" then
        skillId = skillId[1] or 0
    end
    return (skillId and skillId > 0) and skillId or 0
end

---Type503：减少死亡状态的剩余回合数（仅在首次应用时生效）
---@param piece XLuckyTenant2Piece
---@param skillConfig table 技能配置
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_ApplyType503DeathReduction(piece, skillConfig, model)
    local TriggerState = XLuckyTenant2Enum.TriggerState
    local deathState = piece:GetState(TriggerState.Death)
    if not deathState or deathState:GetRemainRounds() <= 0 then
        return
    end

    -- 获取死亡状态的原始回合数（从关联技能配置中读取）
    local deathSkillConfig = model:GetLuckyTenant2ChessSkillConfigById(deathState:GetSkillId())
    local originalRounds = (deathSkillConfig and deathSkillConfig.Params) and deathSkillConfig.Params[1] or 3

    local currentRounds = deathState:GetRemainRounds()
    -- 只有当前回合数等于原始回合数时，才应用减少效果（避免重复减少）
    if currentRounds ~= originalRounds then
        return
    end

    local reduceRounds = (skillConfig.Params or {})[1] or 0
    local newRounds = math.max(1, currentRounds - reduceRounds)
    if newRounds ~= currentRounds then
        deathState:SetRemainRounds(newRounds)
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
            -- 只在新值更小时才更新剩余回合数，避免每回合重置倒计时
            local currentRounds = state:GetRemainRounds()
            if currentRounds >= 0 and rounds >= 0 and rounds < currentRounds then
                state:SetRemainRounds(rounds)
            end
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
        return
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
        end
    end

    -- 怪物羁绊等级变化时，对已存在的子虫重新应用怪物技能（Type203/205/207）
    local monsterBondId = XLuckyTenant2Enum.Bond.Monster
    if monsterBondId and self._BondsNeedRefresh[monsterBondId] then
        self:_RefreshMonsterSkillsForSubworms(pieces, model)
    end

    -- 清空刷新标记
    self._BondsNeedRefresh = nil
end

---怪物羁绊等级变化时，对已存在的子虫重新应用怪物技能（Type203/205/207）
---@param pieces XLuckyTenant2Piece[] 所有棋子（棋盘+背包）
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_RefreshMonsterSkillsForSubworms(pieces, model)
    for _, piece in ipairs(pieces) do
        local bondId = piece:GetBondId()
        if not bondId or bondId == "" or bondId == "0" then
            -- 子虫：重置怪物羁绊相关的数值增量，重新应用
            piece:ResetBondValueDeltas()
            self:ApplyMonsterSkillsToNewPiece(piece, model)
            self:_ApplyImmediateValueSkillsToPiece(piece, model)
        end
    end
end

-- _ApplyImmediateValueSkillsToPiece 使用的常量查找表
local _BaseSkillTypes = {
    [SkillType.Type103] = true,
    [SkillType.Type105] = true,
    [SkillType.Type302] = true,
    [SkillType.Type202] = true,
    [SkillType.Type402] = true,
}
local _DeletionSkillTypes = {
    [SkillType.Type204] = true,
    [SkillType.Type507] = true,
}

function XLuckyTenant2Game:_ApplyImmediateValueSkillsToPiece(piece, model)
    if not piece or not model then
        return
    end
    local skills = piece:GetSkills(model)
    if not skills then
        return
    end

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

    for _, skill in ipairs(skills) do
        local skillType = skill:GetType()
        if _BaseSkillTypes[skillType] and skillType ~= SkillType.Type105 then
            self._SkillExecutor:Execute(skill, context)
        end
    end
    for _, skill in ipairs(skills) do
        if _DeletionSkillTypes[skill:GetType()] then
            self._SkillExecutor:Execute(skill, context)
        end
    end
    for _, skill in ipairs(skills) do
        if skill:GetType() == SkillType.Type105 then
            self._SkillExecutor:Execute(skill, context)
        end
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

---获取技能执行器
---@return XLuckyTenant2SkillExecutor
function XLuckyTenant2Game:GetSkillExecutor()
    return self._SkillExecutor
end

---获取 ResolveStateSkillId 的包装函数（供 BondSkills.GetSkillsFromBonds 等使用）
---@return function(stateSkillId:number, model:XLuckyTenant2Model):number|nil, table|nil
function XLuckyTenant2Game:GetResolveStateSkillIdFn()
    return function(stateSkillId, model)
        local se = self:GetSkillExecutor()
        if se then
            return se:ResolveStateSkillId(stateSkillId, model)
        end
        return nil, nil
    end
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

---增加当前回合分数，并按来源棋子/羁绊记录到本回合羁绊得分
---@param value number 分数增量
---@param sourcePiece XLuckyTenant2Piece|nil 分数来源棋子（可选）
---@param sourceBondIds number[]|nil 明确的羁绊ID列表（可选，优先级高于sourcePiece）
function XLuckyTenant2Game:AddScoreThisRound(value, sourcePiece, sourceBondIds)
    value = tonumber(value) or 0
    if value <= 0 then
        return
    end

    self._ScoreThisRound = self._ScoreThisRound + value

    local bondIds = sourceBondIds
    if not bondIds or #bondIds == 0 then
        bondIds = self:GetScoreBondIdsByPiece(sourcePiece)
    end
    if not bondIds then
        return
    end

    for i = 1, #bondIds do
        local bondId = bondIds[i]
        if bondId and bondId > 0 then
            self._BondsIncomeThisRound[bondId] = (self._BondsIncomeThisRound[bondId] or 0) + value
        end
    end
end

---获取棋子用于得分归因的羁绊ID列表
---优先使用棋子BondId；若为空，则回退到 RelatedChessForScoreIds 匹配
---@param piece XLuckyTenant2Piece|nil
---@return number[]
function XLuckyTenant2Game:GetScoreBondIdsByPiece(piece)
    local result = {}
    if not piece then
        return result
    end

    local unique = {}
    local bondIdStr = piece.GetBondId and piece:GetBondId() or ""
    if bondIdStr and bondIdStr ~= "" then
        for oneBondStr in string.gmatch(bondIdStr, "([^|]+)") do
            local bondId = tonumber(oneBondStr)
            if bondId and bondId > 0 and not unique[bondId] then
                unique[bondId] = true
                result[#result + 1] = bondId
            end
        end
        return result
    end

    if not self._BondManager then
        return result
    end

    local pieceId = piece.GetId and piece:GetId() or 0
    if pieceId <= 0 then
        return result
    end

    local allBonds = self._BondManager:GetAllBonds() or {}
    for _, bond in ipairs(allBonds) do
        local bondId = bond:GetBondId()
        local relatedChessForScoreIds = bond:GetRelatedChessForScoreIds() or {}
        for _, relatedId in ipairs(relatedChessForScoreIds) do
            if pieceId == relatedId then
                if bondId and bondId > 0 and not unique[bondId] then
                    unique[bondId] = true
                    result[#result + 1] = bondId
                end
                break
            end
        end
    end

    return result
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
end

---进入下一个游戏状态
---状态流转：
---  首回合目标展示/阶段目标展示 → 选棋
---  选棋 → Roll（需已选择或删除棋子）
---  Roll → 播放动画
---  播放动画 → 检查任务完成
---  检查任务完成 → 阶段目标展示 / 选棋 / 通关 / 失败
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:NextState(model)
    local gameState = self._GameState

    -- 目标展示 → 选棋
    if gameState == GameState.ShowQuestGoalsOnFirstRound
        or gameState == GameState.ShowNextQuestGoals then
        self:SetState(GameState.SelectPiece)
        return
    end

    -- 选棋 → Roll（需已选择或删除棋子）
    if gameState == GameState.SelectPiece then
        if self._HasSelectOrDelete then
            self:SetState(GameState.Roll)
        else
            XLog.Error("[XLuckyTenant2Game] 尚未选择棋子")
        end
        return
    end

    -- Roll → 播放动画
    if gameState == GameState.Roll then
        self:SetState(GameState.Animation)
        return
    end

    -- 播放动画 → 检查任务完成
    if gameState == GameState.Animation then
        self:SetState(GameState.CheckQuestCompletionStatus)
        return
    end

    -- 检查任务完成 → 阶段目标展示 / 选棋 / 通关 / 失败
    if gameState == GameState.CheckQuestCompletionStatus then
        self:_HandleCheckQuestCompletion(model)
        return
    end
end

---服务端 RoundFin 值到游戏状态的映射
local _RoundFinStateMap = {
    [1] = GameState.PerfectClear,
    [2] = GameState.GameOver,
}

---处理任务完成检查状态的逻辑
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_HandleCheckQuestCompletion(model)
    -- 优先使用服务端标记的结束状态
    local roundFin = self:GetRoundFin()
    local stateFromServer = roundFin and _RoundFinStateMap[roundFin]
    if stateFromServer then
        if roundFin == 1 then
            self._IsNormalClear = true
        else
            self:_RefreshNormalClearFlag(model)
        end
        self:SetState(stateFromServer)
        return
    end

    -- 检查并处理刚完成的任务
    local justCompletedQuest, questIndex = self:_FindAndCompleteQuest()
    if justCompletedQuest then
        self:GrantQuestRewardPieces(model, justCompletedQuest)
        -- 非最后一个任务且有后续任务时，显示目标达成弹窗
        if questIndex < #self._Quest and self:GetNextQuest() then
            self:SetState(GameState.ShowNextQuestGoals)
            return
        end
    end

    self:_RefreshNormalClearFlag(model)

    -- 决定后续状态
    self:_ResolvePostQuestState()
end

---按关卡普通通关阈值刷新普通通关标记
---@param model XLuckyTenant2Model
function XLuckyTenant2Game:_RefreshNormalClearFlag(model)
    if self._IsNormalClear then
        return
    end

    local stageId = self._StageId
    if not stageId or stageId <= 0 then
        return
    end

    local roundsToNormalClear, scoreToNormalClear = model:GetRoundsToNormalClear(stageId)
    roundsToNormalClear = roundsToNormalClear or 0
    scoreToNormalClear = scoreToNormalClear or 0
    if roundsToNormalClear <= 0 then
        return
    end

    local currentRound = self:GetRound() or 0
    local currentScore = self:GetTotalScore() or 0
    if currentRound >= roundsToNormalClear and currentScore >= scoreToNormalClear then
        self._IsNormalClear = true
    end
end

---查找并标记第一个刚完成的任务
---@return table|nil 刚完成的任务
---@return number 任务索引（未找到时为0）
function XLuckyTenant2Game:_FindAndCompleteQuest()
    local currentRound = self:GetRound()
    local currentScore = self:GetTotalScore()

    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if currentRound >= quest.Round
            and currentScore >= (quest.Score or 0)
            and not quest.PerfectClear
            and not quest.NormalClear then
            quest.PerfectClear = true
            self._QuestHasBeenCompleted = self._QuestHasBeenCompleted + 1
            return quest, i
        end
    end
    return nil, 0
end

---决定任务检查后的游戏状态（还有任务 / 通关 / 失败）
function XLuckyTenant2Game:_ResolvePostQuestState()
    if self:GetNextQuest() then
        self:SetState(GameState.SelectPiece)
        return
    end

    -- 没有后续任务，判断通关结果
    if self:_HasAnyPerfectClear() then
        self:SetState(GameState.PerfectClear)
    elseif self._IsNormalClear then
        self:SetState(GameState.NormalClear)
    else
        self:SetState(GameState.GameOver)
    end
end

---检查是否有任何任务达成完美通关
---@return boolean
function XLuckyTenant2Game:_HasAnyPerfectClear()
    for i = 1, #self._Quest do
        if self._Quest[i] and self._Quest[i].PerfectClear then
            return true
        end
    end
    return false
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
        if quest and quest.Round >= round then
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
    self._IsNormalClear = record.IsNormalClear or false

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
    self:_RefreshNormalClearFlag(model)

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
                    if pieceId ~= PropId.RefreshProp and pieceId ~= PropId.DeleteProp then
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
