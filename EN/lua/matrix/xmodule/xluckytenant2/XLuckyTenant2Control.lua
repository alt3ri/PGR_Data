local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Game = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Game")
local GameState = XLuckyTenant2Enum.GameState

---@class XLuckyTenant2Control : XControl
---@field private _Model XLuckyTenant2Model
local XLuckyTenant2Control = XClass(XControl, "XLuckyTenant2Control")

---羁绊等级对应 icon/字色（0~4），等级>4 使用等级4颜色
local BondLevelColors = { [0] = "8893a4", [1] = "dcc0b7", [2] = "eaeaea", [3] = "fff8e5", [4] = "ffffff" }
local function GetBondLevelColorHex(level)
    return BondLevelColors[math.min(level or 0, 4)] or BondLevelColors[4]
end

function XLuckyTenant2Control:OnInit()
    ---@type XLuckyTenant2Game
    self._Game = false
    ---@type number|nil 结算时的StageId
    self._SettlementStageId = nil

    -- Toast队列相关
    self._ToastQueue = {}        -- Toast消息队列
    self._IsShowingToast = false -- 是否正在显示Toast

    -- 本局游戏中已获得的棋子ID集合（用于判断"新"标记）
    self._ObtainedChessIds = {}

    -- 若打开了关卡图文教程，则延迟第一次选棋界面弹出，直到教程关闭
    self._PendingSelectPieceUntilTutorialClosed = false

    self._UiData = {
        HelpKey = self._Model:GetHelpKey(),
        GameState = 0,
        Round = 0,
        TotalRound = 0,
        Score = 0,
        AddScore = 0,
        QuestCompletedAmount = 0,
        QuestTotalAmount = 0,
        QuestDesc = "",
        PiecesAmount = 0,
        Chessboard = {},
        StageName = "",

        ---@type table[] 动画组（暂时用table，后续根据实际需求定义类型）
        AnimationGroups = false,
        ---@type table[]|nil 棋盘数据快照（用于动画播放期间显示删除前的状态）
        ChessboardSnapshot = nil,

        IsDirty = false,
        IsNormalClear = false,
        SelectPiecesData = {
            Pieces = {},
        },
        ---@type table[] 背包数据
        Bag = {},
        ---@type table|false 选中的背包棋子数据
        SelectedBagPiece = false,
        IsBagDirty = false,
        IsPropDirty = false,
        Prop = {},
        DeletePiece = {
            Desc = "",
            Piece = false
        },
        QuestRewards = {},
        ---@type table[] 任务列表数据，用于显示回合列表
        Quests = {},
        ---@type table[] 羁绊数据列表
        Bonds = {},
        ---@type table[] 当前回合羁绊得分记录数据列表
        BondsIncome = {},
        Settlement = {
            Score = 0,
            QuestTotalAmount = 0,
            QuestCompletedAmount = 0,
            Round = 0,
            IsPerfectClear = false,
            IsFail = false,
            IsNormalClear = false,
            IsNewRecord = false,
        },
        IsShowDeleteOption = false,
        FreeRefreshTimes = 0,
        RemainTime = 0,
        ---@type table[] 关卡列表数据
        Stages = {},
        StageDetail = {
            Id = 0,
            Name = "",
            ChapterName = "",
            BestScore = 0,
            BestRound = 0,
            IsMax = false,
            RoundsToPerfectClear = 0,
            QuestAmount = 0,
            Desc = "",
            PerfectDesc = "",
            ---@type table[] 棋子数据
            Pieces = {},
            IsPlaying = false,
            IsChallengeStage = false,
            ---@type number 当前关卡在章节中的序号（1/2/3），关1只显示UiStage1，关2只显示UiStage2
            StageIndexInChapter = 0,
        },
        Icon4Animation = {},
    }

    -- TODO: 根据实际需求添加临时棋子对象
    -- local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")
    -- self._TempPiece = XLuckyTenant2Piece.New()
end

function XLuckyTenant2Control:GetSkillDescById(skillId)
    if not self._Model or not skillId or skillId <= 0 then
        return ""
    end
    local skillDesc = self._Model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
    if skillDesc == "" then
        return ""
    end
    local params = self._Model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
    if params and #params > 0 then
        -- 对于某些技能（Type205、Type207），第一个参数是子虫ID，描述应该从第二个参数开始
        local skillType = self._Model:GetLuckyTenant2ChessSkillTypeById(skillId)
        local SkillType = XLuckyTenant2Enum.Skill
        local formatParams = params
        if skillType == SkillType.Type205 or skillType == SkillType.Type207 then
            -- 跳过第一个参数（子虫ID），从第二个参数开始格式化
            formatParams = { table.unpack(params, 2) }
        end

        local success, formattedDesc = pcall(function()
            return XUiHelper.FormatText(skillDesc, table.unpack(formatParams))
        end)
        if success and formattedDesc then
            return formattedDesc
        end
    end
    return skillDesc
end

---根据技能ID获取羁绊品质背景（用于 Buff 等状态图标背景，按羁绊技能配置的 Level 取品质）
---@param skillId number 技能ID（羁绊技能表 SkillId）
---@return string 背景图路径
function XLuckyTenant2Control:GetBondQualityBgBySkillId(skillId)
    if not self._Model or not skillId or skillId <= 0 then
        return ""
    end
    local configs = self._Model:GetLuckyTenant2BondSkillConfigs()
    if not configs then
        return ""
    end
    for _, config in ipairs(configs) do
        if config.SkillId == skillId then
            local level = config.Level or 0
            local qualityId = level -- 支持等级 0 使用配置表 quality id=0
            return self._Model:GetLuckyTenant2BondQualityBgById(qualityId) or ""
        end
    end
    return ""
end

function XLuckyTenant2Control:ShouldShowDecrementedCountdown()
    local gameState = self._UiData and self._UiData.GameState or 0
    local GameState = XLuckyTenant2Enum.GameState
    return gameState == GameState.Animation
        or gameState == GameState.CheckQuestCompletionStatus
        or gameState == GameState.ShowNextQuestGoals
end

function XLuckyTenant2Control:GetCountdownDisplayOffset()
    return self:ShouldShowDecrementedCountdown() and 0 or -1
end

function XLuckyTenant2Control:AppendStateSkillDisplayIfMissing(piece, data, round)
    if not self._Model or not piece or not data then
        return
    end
    local chessConfig = self._Model:GetLuckyTenant2ChessConfigById(piece:GetId())
    local stateSkillIds = chessConfig and chessConfig.StateSkillId or nil
    if not stateSkillIds then
        return
    end
    if type(stateSkillIds) ~= "table" then
        stateSkillIds = { stateSkillIds }
    end

    local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
    local SkillType = XLuckyTenant2Enum.Skill
    local displaySkillTypes = {
        [SkillType.Type210] = true, -- 子虫死亡倒计时
        [SkillType.Type508] = true, -- 宝盒死亡倒计时
        [SkillType.Type208] = true, -- 子虫死亡传染（显示图标，不显示回合数）
        -- 注意：Type102/Type405/Type506是条件状态技能，只有在实际被感染时才通过data.States显示
        -- 注意：Type201/Type101等周期性生产技能现在使用Production状态，不再需要特殊显示逻辑
    }

    -- 不显示回合数的技能类型（只显示状态图标）
    local noRoundDisplaySkills = {
        [SkillType.Type208] = true, -- 死亡时触发，不是倒计时
        [SkillType.Type405] = true, -- 永久感染状态，不是倒计时
    }

    -- 已有状态可能存的是 skillType 或 skillId，用 ResolveStateSkillId 统一成实际 skillId 再去重
    local existingSkillIdMap = {}
    if data.States then
        for _, state in ipairs(data.States) do
            if state.SkillId and state.SkillId > 0 then
                local resolvedId = SkillExecutor.ResolveStateSkillId(state.SkillId, self._Model)
                local idToMark = (resolvedId and resolvedId > 0) and resolvedId or state.SkillId
                existingSkillIdMap[idToMark] = true
            end
        end
    end

    for _, stateSkillId in ipairs(stateSkillIds) do
        if stateSkillId and stateSkillId > 0 then
            -- 配置里可能是 skillType 或 skillId，用已有逻辑统一解析
            local actualSkillId, skillConfig = SkillExecutor.ResolveStateSkillId(stateSkillId, self._Model)
            local finalSkillId = actualSkillId or stateSkillId
            if not existingSkillIdMap[finalSkillId] and skillConfig then
                local skillType = skillConfig.Type or 0
                if displaySkillTypes[skillType] then
                    local params = skillConfig.Params or {}
                    local displayRound = params[1] or 0

                    -- 不显示回合数的技能，设置 Round = nil
                    if noRoundDisplaySkills[skillType] then
                        displayRound = nil
                    end

                    data.States = data.States or {}
                    data.States[#data.States + 1] = {
                        StateType = 0,
                        Round = displayRound,
                        Desc = self:GetSkillDescById(finalSkillId),
                        SkillId = finalSkillId,
                        ImageBg = self:GetBondQualityBgBySkillId(finalSkillId) or "",
                    }
                end
            end
        end
    end
end

function XLuckyTenant2Control:AppendRoleUpgradeStateIfMissing(piece, data)
    if not self._Game or not self._Model or not piece or not data then
        return
    end
    local TriggerState = XLuckyTenant2Enum.TriggerState
    local hasUpgrade = false
    if data.States then
        for _, state in ipairs(data.States) do
            if state.StateType == TriggerState.Upgrade then
                hasUpgrade = true
                break
            end
        end
    end
    if hasUpgrade then
        return
    end

    local bondIdStr = piece:GetBondId()
    if not bondIdStr or bondIdStr == "" then
        return
    end

    local bondManager = self._Game:GetBondManager()
    if not bondManager then
        return
    end

    local SkillType = XLuckyTenant2Enum.Skill
    local rounds = 0
    local levelDelta = 0
    local maxLevel = 999
    local maxReduceRounds = 0
    local hasMode1 = false
    local mode1SkillId = 0

    for bondIdStr in string.gmatch(bondIdStr, "([^|]+)") do
        local bondId = tonumber(bondIdStr)
        if bondId then
            local bond = bondManager:GetBond(bondId)
            local bondLevel = bond and bond:GetLevel() or 0
            if bondLevel > 0 then
                local bondSkillConfigs = self._Model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)
                for _, bondSkillConfig in ipairs(bondSkillConfigs) do
                    local skillId = bondSkillConfig.SkillId
                    if type(skillId) == "table" then
                        skillId = skillId[1]
                    end
                    if skillId and skillId > 0 then
                        local skillType = self._Model:GetLuckyTenant2ChessSkillTypeById(skillId)
                        local skillMode = bondSkillConfig.SkillMode
                        if skillMode == nil then
                            local skillConfig = self._Model:GetLuckyTenant2ChessSkillConfigById(skillId)
                            skillMode = skillConfig and skillConfig.SkillMode or 0
                        end
                        local params = self._Model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                        if skillType == SkillType.Type301 then
                            if (skillMode == 1 or skillMode == 0) and not hasMode1 then
                                rounds = params[1] or 0
                                levelDelta = params[2] or 0
                                maxLevel = params[3] or 999
                                hasMode1 = rounds > 0 and levelDelta > 0
                                if hasMode1 then
                                    mode1SkillId = skillId
                                end
                            elseif skillMode == 2 then
                                local reduceRounds = params[1] or 0
                                if reduceRounds > maxReduceRounds then
                                    maxReduceRounds = reduceRounds
                                end
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

    if not hasMode1 then
        return
    end
    if rounds <= 0 or levelDelta <= 0 then
        return
    end

    local currentLevel = piece:GetLevel() or 0
    if currentLevel >= maxLevel then
        return
    end

    local actualRounds = rounds
    if maxReduceRounds > 0 then
        actualRounds = math.max(1, rounds - maxReduceRounds)
    end

    local desc = self:GetSkillDescById(mode1SkillId)

    local stateData = {
        StateType = TriggerState.Upgrade,
        Round = actualRounds,
        Desc = desc,
        SkillId = mode1SkillId,
    }
    data.States = data.States or {}
    data.States[#data.States + 1] = stateData
    if not data.Round then
        data.Round = actualRounds
    end
end

function XLuckyTenant2Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    self:UpdateActivityTimeLeft()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateActivityTimeLeft()
        self:CheckInTime()
    end, XScheduleManager.SECOND)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT2_SET_TEST_CASE, self._SetTestCase, self)
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT2_CLEAR_BAG, self._TestClearBag, self)
end

function XLuckyTenant2Control:RemoveAgencyEvent()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    -- TODO: 根据实际需求移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT2_SET_TEST_CASE, self._SetTestCase)
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT2_CLEAR_BAG, self._TestClearBag)
end

function XLuckyTenant2Control:OnRelease()
    self._Game = false
end

function XLuckyTenant2Control:ClearGame()
    self._Game = false
    self._UiData.SelectPiecesData.Pieces = {}
    self._UiData.SelectedBagPiece = false
end

---开始游戏
---@param stageId number 关卡ID
---@param seed number 随机种子
---@param isFirstTimeEntering boolean 是否首次进入
---@param record table|nil 游戏记录（用于恢复游戏）
function XLuckyTenant2Control:StartGame(stageId, seed, isFirstTimeEntering, record)
    -- 在清除日志之前，先输出关键信息
    if record then
        XLog.Error("====== [Control StartGame] 收到恢复记录 ======")
        XLog.Error("record.RoundProgress = " .. tostring(record.RoundProgress))
        XLog.Error("record.Round = " .. tostring(record.Round))
        XLog.Error("record.SuppleChess = " .. tostring(record.SuppleChess and #record.SuppleChess or "nil"))
        XLog.Error("record.Bag = " .. tostring(record.Bag and #record.Bag or "nil"))
        XLog.Error("record.ChessBoard = " .. tostring(record.ChessBoard and #record.ChessBoard or "nil"))
        XLog.Error("===============================================")
    end

    XMVCA.XLuckyTenant2:ClearLog()
    self:SetStageHasPlayed(stageId)
    -- 清除已获得棋子记录（新游戏开始）
    self:ClearObtainedChessIds()
    -- 设置当前正在游玩的 stageId
    self._Model:SetPlayingStageId(stageId)
    self._Game = XLuckyTenant2Game.New()
    local isResumeGame = false
    if record then
        if record.Bag and next(record.Bag) then
            isResumeGame = true
        else
        end
    end
    self._Game:Init(self._Model, stageId, seed, isFirstTimeEntering, isResumeGame)
    if record and self._Game then
        -- 实现游戏恢复逻辑
        XLog.Error("====== [Control] 开始恢复游戏 ======")
        XLog.Error("record.RoundProgress = " .. tostring(record.RoundProgress))
        XLog.Error("record.Round = " .. tostring(record.Round))
        XLog.Error("record.SuppleChess数量 = " .. tostring(record.SuppleChess and #record.SuppleChess or 0))
        XLog.Error("record.Bag数量 = " .. tostring(record.Bag and #record.Bag or 0))
        self._Game:Resume(self._Model, record)
        XLog.Error("恢复后游戏状态 = " .. tostring(self._Game:GetState()))
        XLog.Error("====== [Control] 恢复游戏完成 ======")
    end
    if not record or not record.ChessBoard then
        self._Game:PlacePiecesOnBoard(self._Model)
    end

    local stageConfig = self._Model:GetLuckyTenant2StageConfigById(stageId)
    if stageConfig and stageConfig.ShowDeleteOption then
        self._UiData.IsShowDeleteOption = true
    else
        self._UiData.IsShowDeleteOption = false
    end

    self:UpdateUiData(true)
    -- 第一次看到棋盘，不显示回合数
    if self._Game:GetRound() == 1 then
        for i = 1, #self._UiData.Chessboard do
            local data = self._UiData.Chessboard[i]
            if data then
                data.Round = false
            end
        end
    end

    -- 标记初始背包中的棋子为已获得
    if self._Game then
        local bag = self._Game:GetBag()
        if bag then
            local allPieces = bag:GetAllPieces()
            for _, piece in pairs(allPieces) do
                if piece and not piece:IsDeleted() then
                    self:MarkChessAsObtained(piece:GetId())
                end
            end
        end
    end

    -- 第一次进入关卡时，根据配置的图文教程页数打开教学界面，并用 SaveUtil 记录已展示
    self:TryShowStageTutorial(stageId)
end

---首次进入关卡时尝试展示图文教程（未展示过且配置了 TutorialPage 时打开，关闭时写入 SaveUtil）
---若打开了教程，则延迟第一次选棋界面弹出，直到教程关闭后再弹出
---@param stageId number
function XLuckyTenant2Control:TryShowStageTutorial(stageId)
    if not stageId or self._Model:IsStageTutorialShown(stageId) then
        return
    end
    local tutorialPage = self._Model:GetLuckyTenant2StageTutorialPageById(stageId)
    if not tutorialPage or tutorialPage <= 0 then
        return
    end
    self._PendingSelectPieceUntilTutorialClosed = true
    local helpKey = self._Model:GetHelpKey()
    XUiManager.ShowHelpTip(helpKey, nil, tutorialPage, function()
        self._Model:SetStageTutorialShown(stageId)
        self._PendingSelectPieceUntilTutorialClosed = false
        self:StartSelectPiece()
    end)
end

---更新游戏状态
function XLuckyTenant2Control:UpdateGameState()
    if not self._Game then
        return
    end
    local state = self._Game:GetState()
    if state ~= self._UiData.GameState then
        self._UiData.GameState = state
        self._UiData.IsDirty = true
        self:UpdateInfo()
    end
end

---进入下一个游戏状态
function XLuckyTenant2Control:NextGameState()
    if not self._Game then
        return
    end
    self._Game:NextState(self._Model)
    self:UpdateGameState()
end

---执行Roll（计算分数）
function XLuckyTenant2Control:Roll()
    if not self._Game then
        return
    end

    local animationGroups = {}
    self._UiData.IsRoundCountdownApplied = false
    self._Game:PlacePiecesOnBoard(self._Model)
    self._UiData.AnimationGroups = animationGroups
    -- 保存开始roll之前的棋盘（在ExecuteRoundCalculation之前，保存删除前的状态）
    self:UpdateUiData(false)

    -- 数据和动画分离：保存棋盘数据快照，供动画播放期间使用
    local snapshot = {}
    local snapshotCount = 0
    for i = 1, #self._UiData.Chessboard do
        local data = self._UiData.Chessboard[i]
        if data then
            snapshot[i] = {}
            for k, v in pairs(data) do
                snapshot[i][k] = v
            end
            if data.IsValid then
                snapshotCount = snapshotCount + 1
            end
        end
    end
    self._UiData.ChessboardSnapshot = snapshot

    -- 动画开始前先将快照倒计时-1，避免依赖UI层时机
    self:ApplyRoundCountdownForAnimation()

    self:UpdateIcon4Animation()
    self._Game:ExecuteRoundCalculation(self._Model, animationGroups)
    self:InsertRollAnimation(animationGroups)
    -- 数据和动画分离：数据已立即删除，这里不再更新UI数据，保持删除前的状态供动画使用
    -- 动画播放完成后，会在FinishAnimation中调用UpdateUiData更新到最新状态
    self:NextGameState()
    XMVCA.XLuckyTenant2:RequestUpdateScore(self._Game)
end

function XLuckyTenant2Control:ApplyRoundCountdownForAnimation()
    local uiData = self._UiData
    if not uiData or uiData.IsRoundCountdownApplied then
        return
    end
    local snapshot = uiData.ChessboardSnapshot
    if not snapshot then
        return
    end

    local totalAdjusted = 0
    for i = 1, #snapshot do
        local data = snapshot[i]
        if data and data.IsValid then
            if data.Round and data.Round > 0 then
                data.Round = math.max(0, data.Round - 1)
                totalAdjusted = totalAdjusted + 1
            end
            if data.States then
                for _, state in ipairs(data.States) do
                    if state.Round and state.Round > 0 then
                        state.Round = math.max(0, state.Round - 1)
                        totalAdjusted = totalAdjusted + 1
                    end
                end
            end
        end
    end

    uiData.IsRoundCountdownApplied = true
end

---插入Roll动画
---@param animationGroups table 动画组列表
function XLuckyTenant2Control:InsertRollAnimation(animationGroups)
    -- 动画组已经在 ExecuteRoundCalculation 中创建并添加到列表中
    -- 这里不需要额外处理，动画组会由 UI 层的 UpdateAnimation 更新
end

---设置UI数据脏标记
---@param isDirty boolean 是否脏
function XLuckyTenant2Control:SetUiDataDirty(isDirty)
    local uiData = self._UiData
    uiData.IsDirty = isDirty
    uiData.IsBagDirty = isDirty
    uiData.IsPropDirty = isDirty
end

---更新UI数据
---@param isDirty boolean 是否标记为脏
function XLuckyTenant2Control:UpdateUiData(isDirty)
    if not self._Game then
        return
    end

    local game = self._Game
    local uiData = self._UiData
    self:UpdateGameState()
    self:SetUiDataDirty(isDirty)

    local chessboard = game:GetChessBoard()
    local pieces = chessboard:GetAllPieces()
    self:UpdateChessboardSize(chessboard:GetPiecesAmount())

    uiData.Score = game:GetTotalScore()
    uiData.AddScore = game:GetScoreThisRound()

    -- 更新羁绊得分记录数据
    self:UpdateBondsIncome()

    self:UpdateChessboard()
    self:UpdateInfo()
end

---更新信息（回合数、任务进度等）
function XLuckyTenant2Control:UpdateInfo()
    if not self._Game then
        return
    end

    local game = self._Game
    local uiData = self._UiData
    uiData.Round = game:GetRound()

    -- 更新总回合数
    local stageId = self._Model:GetPlayingStageId()
    -- 如果 Model 中的 stageId 为 0，尝试从 Game 中获取
    if not stageId or stageId <= 0 then
        stageId = game:GetStageId()
    end

    if stageId and stageId > 0 then
        local totalRound = self._Model:GetRoundsToPerfectClear(stageId) or 0
        -- 获取 quest 列表中的最大回合数
        local allQuests = game:GetAllQuest()
        local maxQuestRound = 0
        if allQuests and #allQuests > 0 then
            for i = 1, #allQuests do
                local quest = allQuests[i]
                if quest and quest.Round and quest.Round > maxQuestRound then
                    maxQuestRound = quest.Round
                end
            end
        end
        -- 总回合数不能超过 quest 的最大回合数（如果有quest的话）
        if maxQuestRound > 0 then
            uiData.TotalRound = math.min(totalRound, maxQuestRound)
        else
            uiData.TotalRound = totalRound
        end
    end

    -- 获取任务进度
    local questCompletedAmount, questTotalAmount = game:GetQuestProgress()
    uiData.QuestCompletedAmount = questCompletedAmount
    uiData.QuestTotalAmount = questTotalAmount
    uiData.IsNormalClear = game:IsNormalClear()

    self:UpdateBagAmount()
    -- 不在UpdateInfo中重置AddScore，因为UpdateBonds需要这个值
    -- uiData.AddScore会在UpdateUiData中从game:GetScoreThisRound()获取
    self:UpdateQuest()
    self:UpdateQuestList()
    self:UpdateBonds()
end

---更新任务信息
function XLuckyTenant2Control:UpdateQuest()
    if not self._Game then
        return
    end

    local game = self._Game
    local quest = game:GetCurrentQuest()
    local uiData = self._UiData

    if not quest then
        uiData.QuestRewards = {}
        uiData.QuestDesc = ""
        return
    end

    uiData.QuestDesc = quest.Desc
    local questRewards = self._UiData.QuestRewards
    local rewardPieces = quest.RewardPieces

    -- 调整奖励数组大小
    if #questRewards ~= #rewardPieces then
        for i = #questRewards, 1, -1 do
            questRewards[i] = nil
        end
    end

    local rewardAmount = quest.RewardPiecesAmount
    for i = 1, #rewardPieces do
        local pieceId = rewardPieces[i]
        local amount = rewardAmount[i] or 1
        local data = questRewards[i]
        if not data then
            data = {
                Icon = "",
                Amount = 0,
                Desc = ""
            }
            questRewards[i] = data
        end
        -- 填充奖励数据
        data.Icon = self._Model:GetLuckyTenant2ChessIconById(pieceId)
        data.Amount = amount
        -- Desc是数组，取第一个元素
        local config = self._Model:GetLuckyTenant2ChessConfigById(pieceId)
        if config and config.Desc and #config.Desc > 0 then
            data.Desc = config.Desc[1] or ""
        else
            data.Desc = ""
        end
    end
end

---更新任务列表（用于显示回合列表）
function XLuckyTenant2Control:UpdateQuestList()
    if not self._Game then
        return
    end

    local game = self._Game
    local uiData = self._UiData
    local currentRound = game:GetRound()
    local allQuests = game:GetAllQuest()
    local quests = uiData.Quests

    -- 调整数组大小
    if #quests ~= #allQuests then
        for i = #quests, 1, -1 do
            quests[i] = nil
        end
        for i = 1, #allQuests do
            quests[i] = {
                Round = 0,
                IsCurrentQuest = false,
                PerfectClear = false,
                NormalClear = false,
            }
        end
    end

    -- 获取关卡配置中的静态 quest 数据
    local stageId = game:GetStageId()
    local questConfigs = self._Model:GetStageTasks(stageId)

    -- 更新 quest 数据和标识当前 quest
    local currentQuestIndex = 0
    for i = 1, #allQuests do
        local quest = allQuests[i]
        local questData = quests[i]
        questData.Round = quest.Round or 0
        questData.Index = i

        -- 从配置表中读取静态的 PerfectClear 和 NormalClear（表示 quest 类型标记：显示为"完美通关目标"或"普通通关目标"）
        -- 注意：这与 Game._Quest[i].PerfectClear（运行时完成状态）不同
        local questConfig = questConfigs[i]
        if questConfig then
            questData.PerfectClear = questConfig.PerfectClear or false -- 静态类型：是否为完美通关目标
            questData.NormalClear = questConfig.NormalClear or false   -- 静态类型：是否为普通通关目标
        else
            questData.PerfectClear = false
            questData.NormalClear = false
        end

        -- 找到当前回合所在的 quest
        -- 如果当前回合数 <= quest.Round，且还没有找到当前 quest，则标记为当前 quest
        if currentQuestIndex == 0 and currentRound <= questData.Round then
            currentQuestIndex = i
            questData.IsCurrentQuest = true
        else
            questData.IsCurrentQuest = false
        end
    end

    -- 实现虚假轮次，加入一个IsPlaceholder，跳过当前quest之后2个quest到最后一个quest之间的所有quest
    -- 首先清掉当前quest之后2个quest到最后一个quest之间的所有quest
    local isRemove = false
    for i = #quests - 1, currentQuestIndex + 2, -1 do
        isRemove = true
        table.remove(quests, i)
    end
    if isRemove then
        -- 加入一个IsPlaceholder
        table.insert(quests, currentQuestIndex + 2, {
            IsPlaceholder = true
        })
    end

    -- 移除当前轮次之前2个quest之后的所有quest
    for i = 1, currentQuestIndex - 2 do
        table.remove(quests, 1)
    end

    -- 逆序 quest（只遍历到一半，否则会交换两次等于没逆序）
    local len = #quests
    for i = 1, math.floor(len / 2) do
        local j = len - i + 1
        quests[i], quests[j] = quests[j], quests[i]
    end

    -- 如果没有找到当前 quest（可能已经完成所有 quest），标记最后一个为当前 quest
    if currentQuestIndex == 0 and #quests > 0 then
        quests[#quests].IsCurrentQuest = true
    end
end

---获取当前关卡配置的羁绊显示顺序（ShowBondId 字符串 "6|1|2|3|4|5" 解析为有序数组）
---@return number[]
function XLuckyTenant2Control:GetStageShowBondIdOrder()
    local stageId = self._Model and self._Model.GetPlayingStageId and self._Model:GetPlayingStageId()
    if (not stageId or stageId <= 0) and self._Game and self._Game.GetStageId then
        stageId = self._Game:GetStageId()
    end
    if not stageId or stageId <= 0 then
        return {}
    end
    local str = self._Model:GetLuckyTenant2StageShowBondIdById(stageId) or ""
    local order = {}
    for idStr in string.gmatch(str, "([^|]+)") do
        local id = tonumber(idStr)
        if id then
            table.insert(order, id)
        end
    end
    return order
end

---羁绊是否应在当前关卡显示：等级>0 必定显示；等级=0 仅当在关卡 ShowBondId 配置中时显示；配置为空则显示全部
---@param bondId number
---@param level number
---@return boolean
function XLuckyTenant2Control:ShouldShowBond(bondId, level)
    if level and level > 0 then
        return true
    end
    local order = self:GetStageShowBondIdOrder()
    if not order or #order == 0 then
        return true
    end
    for _, id in ipairs(order) do
        if id == bondId then
            return true
        end
    end
    return false
end

---获取羁绊在关卡配置顺序中的下标（用于排序，不在配置中的排最后）
---@param bondId number
---@return number
function XLuckyTenant2Control:GetBondDisplayOrderIndex(bondId)
    local order = self:GetStageShowBondIdOrder()
    for idx, id in ipairs(order) do
        if id == bondId then
            return idx
        end
    end
    return 9999
end

---更新羁绊得分记录数据
function XLuckyTenant2Control:UpdateBondsIncome()
    if not self._Game then
        return
    end

    local uiData = self._UiData
    local bondsIncomeData = uiData.BondsIncome

    -- 获取当前回合的羁绊得分记录
    local bondsIncomeThisRound = self._Game:GetBondsIncomeThisRound() or {}

    -- 清空数组
    for i = #bondsIncomeData, 1, -1 do
        bondsIncomeData[i] = nil
    end

    -- 获取所有羁绊配置
    local bondManager = self._Game:GetBondManager()
    if not bondManager then
        -- bondManager不存在，直接返回（不添加任何数据）
        return
    end

    -- 确保羁绊等级已刷新（在获取羁绊列表前）
    local bag = self._Game:GetBag()
    if bag then
        bondManager:RefreshBondLevels(bag, self._Model)
    end

    local allBonds = bondManager:GetAllBonds()

    -- 如果没有羁绊，直接返回（不添加任何数据）
    if not allBonds or #allBonds == 0 then
        return
    end

    -- 转换为 UI 数据格式（仅显示应显示的羁绊：等级>0 必显示，等级=0 受关卡 ShowBondId 控制）
    for _, bond in ipairs(allBonds) do
        local bondId = bond:GetBondId()
        local score = bondsIncomeThisRound[bondId] or 0
        local level = bond:GetLevel()
        if not self:ShouldShowBond(bondId, level) then
            goto continue
        end
        -- 获取羁绊配置
        ---@type XTableLuckyTenant2Bond
        local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
        if bondConfig then
            local pieceCount = 0
            if bag then
                pieceCount = bond:CalculateSatisfyCount(bag)
            end
            -- 根据羁绊等级取品质背景（等级 0 使用配置表里的 quality id=0）
            local qualityId = level or 0
            local imageBg = self._Model:GetLuckyTenant2BondQualityBgById(qualityId) or ""
            local bondIncomeData = {
                BondId = bondId,
                Name = bondConfig.BondName or "",
                Icon = bondConfig.Icon or "",
                Level = level,
                LevelColor = GetBondLevelColorHex(level), -- 当前羁绊等级对应 icon/字色
                PieceCount = pieceCount,                  -- 棋子数量或类型数量（与羁绊列表 TxtLv 一致）
                Score = score,                            -- 可能为0（如果没有得分记录）
                ImageBg = imageBg,
            }
            bondsIncomeData[#bondsIncomeData + 1] = bondIncomeData
        end
        ::continue::
    end

    -- 按关卡配置顺序显示，同顺序内按得分降序、再按 BondId 升序
    if #bondsIncomeData > 0 then
        table.sort(bondsIncomeData, function(a, b)
            local orderA = self:GetBondDisplayOrderIndex(a.BondId)
            local orderB = self:GetBondDisplayOrderIndex(b.BondId)
            if orderA ~= orderB then
                return orderA < orderB
            end
            if a.Score ~= b.Score then
                return a.Score > b.Score
            end
            return a.BondId < b.BondId
        end)
    end
end

---更新羁绊列表数据
function XLuckyTenant2Control:UpdateBonds()
    if not self._Game then
        return
    end

    local bondManager = self._Game:GetBondManager()
    if not bondManager then
        return
    end

    local uiData = self._UiData
    local bondsData = uiData.Bonds
    local allBonds = bondManager:GetAllBonds()
    local tempList = {}

    -- 转换为 UI 数据格式（仅显示应显示的羁绊：等级>0 必显示，等级=0 受关卡 ShowBondId 控制）
    for i = 1, #allBonds do
        local bond = allBonds[i]
        local bondId = bond:GetBondId()
        local level = bond:GetLevel()
        if not self:ShouldShowBond(bondId, level) then
            goto continue
        end
        -- 获取羁绊配置
        local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
        if bondConfig then
            -- 获取羁绊技能配置，用于生成等级文本
            local levelText = ""
            local bondSkillConfigs = self._Model:GetLuckyTenant2BondSkillConfigsByBondId(bondId)

            if bondSkillConfigs and #bondSkillConfigs > 0 then
                -- 从所有配置中收集 SkillRequire 值（每个 level 只取第一个配置）
                local skillRequireMap = {} -- {level: skillRequire}
                for _, bondSkillConfig in ipairs(bondSkillConfigs) do
                    local skillRequire = bondSkillConfig.SkillRequire
                    local configLevel = bondSkillConfig.Level
                    if skillRequire and skillRequire > 0 and configLevel and configLevel > 0 then
                        -- 如果该 level 还没有 SkillRequire，使用当前配置的值（同一 level 只取第一个）
                        if not skillRequireMap[configLevel] then
                            skillRequireMap[configLevel] = skillRequire
                        end
                    end
                end

                -- 转换为列表并按 level 排序
                local allSkillRequires = {}
                for configLevel, skillRequire in pairs(skillRequireMap) do
                    table.insert(allSkillRequires, { level = configLevel, require = skillRequire })
                end
                table.sort(allSkillRequires, function(a, b) return a.level < b.level end)

                if #allSkillRequires > 0 then
                    -- 生成等级文本，每个等级数字使用对应等级颜色（0~4 见 BondLevelColors），已激活用该等级色，未激活用 0 级灰色
                    local levelParts = {}
                    local partColors = {}
                    for j = 1, #allSkillRequires do
                        local skillRequireData = allSkillRequires[j]
                        local requireText = tostring(skillRequireData.require)
                        local configLevel = skillRequireData.level
                        local colorHex = (configLevel <= level) and GetBondLevelColorHex(configLevel) or BondLevelColors[0]
                        partColors[j] = colorHex
                        requireText = string.format("<color=#%s>%s</color>", colorHex, requireText)
                        table.insert(levelParts, requireText)
                    end
                    levelText = ""
                    for j = 1, #levelParts do
                        if j > 1 then
                            levelText = levelText .. string.format("<color=#%s>/</color>", partColors[j - 1])
                        end
                        levelText = levelText .. levelParts[j]
                    end
                end
            end

            -- 如果仍然为空，尝试使用 UpgradeRequireDesc 作为备选
            if levelText == "" and bondConfig.UpgradeRequireDesc and bondConfig.UpgradeRequireDesc ~= "" then
                levelText = bondConfig.UpgradeRequireDesc
            end

            -- 如果仍然为空，使用默认的等级文本（根据 CalculateLevel 的逻辑，默认是 2/4/6/9）
            if levelText == "" then
                levelText = ""
                XLog.Warning("羁绊等级文本为空，bondId:", bondId)
            end

            ---@class XUiLuckyTenant2GameGridBondsData
            local bondData = {}
            bondData.BondId = bondId
            bondData.Name = bond:GetName() or bondConfig.BondName or ""
            bondData.Icon = bond:GetIcon() or bondConfig.Icon or ""
            bondData.Level = level
            bondData.LevelText = levelText
            bondData.LevelColor = GetBondLevelColorHex(level) -- 当前羁绊等级对应 icon/字色
            -- 根据羁绊等级取品质背景（等级 0 使用配置表里的 quality id=0）
            local qualityId = level or 0
            bondData.ImageBg = self._Model:GetLuckyTenant2BondQualityBgById(qualityId) or ""

            -- 计算当前羁绊的棋子数量（根据升级要求类型：类型数量或总数量）
            local bag = self._Game:GetBag()
            local pieceCount = 0
            if bag then
                pieceCount = bond:CalculateSatisfyCount(bag)
            end
            bondData.PieceCount = pieceCount

            -- 获取技能列表（用于显示 Buff 列表）
            -- 总是获取所有等级的 Buffs，然后根据每个 Buff 的等级判断是否拥有
            bondData.Buffs = self:GetBondAllSkills(bondId)
            -- 为每个 Buff 添加 IsOwned、未拥有时用 0 级背景、等级对应字色
            for i = 1, #bondData.Buffs do
                local buffLevel = bondData.Buffs[i].Level or 0
                local isOwned = level > 0 and level >= buffLevel
                bondData.Buffs[i].IsOwned = isOwned
                if not isOwned then
                    bondData.Buffs[i].ImageBg = self._Model:GetLuckyTenant2BondQualityBgById(0) or ""
                    bondData.Buffs[i].LevelColor = BondLevelColors[0]
                else
                    bondData.Buffs[i].LevelColor = GetBondLevelColorHex(buffLevel)
                end
            end

            -- 获取关联的棋子列表（用于显示关联棋子列表）
            bondData.ChessRequires = self:GetBondRelatedChessList(bondId)
            tempList[#tempList + 1] = bondData
        end
        ::continue::
    end

    -- 清空并按关卡配置顺序填充（同顺序内按等级降序、再按 BondId 升序）
    for idx = #bondsData, 1, -1 do
        bondsData[idx] = nil
    end
    table.sort(tempList, function(a, b)
        local orderA = self:GetBondDisplayOrderIndex(a.BondId)
        local orderB = self:GetBondDisplayOrderIndex(b.BondId)
        if orderA ~= orderB then
            return orderA < orderB
        end
        if a.Level ~= b.Level then
            return a.Level > b.Level
        end
        return a.BondId < b.BondId
    end)
    for _, bondData in ipairs(tempList) do
        bondsData[#bondsData + 1] = bondData
    end
end

---刷新羁绊等级（重新计算所有羁绊的等级）
function XLuckyTenant2Control:RefreshBondLevels()
    if not self._Game then
        return
    end

    local bondManager = self._Game:GetBondManager()
    local bag = self._Game:GetBag()
    if bondManager and bag then
        -- 记录刷新前的等级
        local oldLevels = {}
        local allBonds = bondManager:GetAllBonds()
        for _, bond in ipairs(allBonds) do
            local bondId = bond:GetBondId()
            oldLevels[bondId] = bond:GetLevel()
        end

        -- 刷新羁绊等级
        bondManager:RefreshBondLevels(bag, self._Model)

        -- 检查等级变化并显示Toast
        for _, bond in ipairs(allBonds) do
            local bondId = bond:GetBondId()
            local newLevel = bond:GetLevel()
            local oldLevel = oldLevels[bondId] or 0

            if oldLevel ~= newLevel then
                self:OnBondLevelChanged(bondId, oldLevel, newLevel)
            end
        end
    end
end

---刷新羁绊等级（但不立即显示Toast，返回变化记录）
---@return table|nil 返回变化记录 {bondId, oldLevel, newLevel}[]
function XLuckyTenant2Control:RefreshBondLevelsWithoutToast()
    if not self._Game then
        return nil
    end

    local bondManager = self._Game:GetBondManager()
    local bag = self._Game:GetBag()
    if not bondManager or not bag then
        return nil
    end

    -- 记录刷新前的等级
    local oldLevels = {}
    local allBonds = bondManager:GetAllBonds()
    for _, bond in ipairs(allBonds) do
        local bondId = bond:GetBondId()
        oldLevels[bondId] = bond:GetLevel()
    end

    -- 刷新羁绊等级
    bondManager:RefreshBondLevels(bag, self._Model)

    -- 记录等级变化
    local changes = {}
    for _, bond in ipairs(allBonds) do
        local bondId = bond:GetBondId()
        local newLevel = bond:GetLevel()
        local oldLevel = oldLevels[bondId] or 0

        if oldLevel ~= newLevel then
            table.insert(changes, {
                bondId = bondId,
                oldLevel = oldLevel,
                newLevel = newLevel,
            })
        end
    end

    return #changes > 0 and changes or nil
end

---应用羁绊等级变化记录（显示Toast）
---@param changes table 变化记录 {bondId, oldLevel, newLevel}[]
function XLuckyTenant2Control:ApplyBondLevelChanges(changes)
    if not changes or #changes == 0 then
        return
    end

    for _, change in ipairs(changes) do
        self:OnBondLevelChanged(change.bondId, change.oldLevel, change.newLevel)
    end
end

---更新背包数量
function XLuckyTenant2Control:UpdateBagAmount()
    if not self._Game then
        return
    end

    local game = self._Game
    local uiData = self._UiData
    uiData.PiecesAmount = game:GetBag():GetPiecesAmount()
end

---开始选棋
function XLuckyTenant2Control:StartSelectPiece()
    if not self._Game then
        return
    end
    -- 若当前因图文教程而延迟选棋界面，等教程关闭后再由 TryShowStageTutorial 的 closeCb 调用本方法
    if self._PendingSelectPieceUntilTutorialClosed then
        return
    end

    if self._Game:HasSupplyChess() then
        -- 恢复选棋（已有补充棋子，不需要请求服务器）
        self._Game:ClearHasSupplyChess()
        self._Model:SetPlayingStageRound(self._Game:GetRound())
        self._UiData.Round = self._Game:GetRound()
        self:UpdateSelectPiece()
        XLuaUiManager.Open("UiLuckyTenant2Chess")
        return
    end

    -- 开始新回合选棋
    self._Game:EnterNextRound(self._Model)
    self._Model:SetPlayingStageRound(self._Game:GetRound())
    self._UiData.Round = self._Game:GetRound()
    self:UpdateSelectPiece()
    XLuaUiManager.Open("UiLuckyTenant2Chess")
    XMVCA.XLuckyTenant2:RequestSupplyPieces(self._Game)
end

---更新选择棋子数据
function XLuckyTenant2Control:UpdateSelectPiece()
    if not self._Game then
        return
    end

    local pieces = self._Game:GetOptionsThisRound(self._Model)
    local pieceData = {}
    self._UiData.SelectPiecesData.Pieces = pieceData

    -- 遍历所有棋子，只保留有效的（非nil）棋子，并重新分配索引
    local validIndex = 1
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece then
            local data = {}
            data.Id = piece:GetId()
            data.Name = piece:GetName()
            data.Uid = piece:GetUid()
            data.Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId())
            data.Value = piece:GetTotalValue()
            data.ValueUponDeletion = piece:GetValueUponDeletion()
            data.Desc = self._Model:GetLuckyTenant2ChessDescById(piece:GetId()) or {}
            data.IsFromSelectPiece = true -- 标记来自选棋界面
            local quality = piece:GetQuality()
            data.Quality = self._Model:GetQualityIconQuad(quality)
            data.QualityValue = quality
            -- 使用原始数组索引，因为 SelectPiece 使用的是原始数组索引
            data.Index = i
            data.IsCanDelete = piece:IsCanDelete()
            data.TypeName = self._Model:GetLuckyTenant2ChessTypeNameById(piece:GetPieceType())
            data.Level = piece:GetLevel()
            data.IsCanUpgrade = piece._CanUpgrade or false
            data.IsNew = self:IsChessNew(piece:GetId())
            pieceData[validIndex] = data
            validIndex = validIndex + 1
        end
    end
    self._UiData.FreeRefreshTimes = self._Game:GetFreeRefreshTimes()
end

---更新棋盘大小
---@param amount number 棋盘格子数量
function XLuckyTenant2Control:UpdateChessboardSize(amount)
    local dataChessboard = self._UiData.Chessboard
    if amount ~= #dataChessboard then
        for i = amount + 1, #dataChessboard do
            dataChessboard[i] = nil
        end
        for i = 1, amount do
            if dataChessboard[i] == nil then
                dataChessboard[i] = {}
            end
        end
    end
end

---更新棋盘数据
function XLuckyTenant2Control:UpdateChessboard()
    if not self._Game then
        return
    end

    local game = self._Game
    local uiData = self._UiData

    -- 如果有快照且处于动画状态，使用快照数据（数据和动画分离）
    if uiData.ChessboardSnapshot and uiData.GameState == XLuckyTenant2Enum.GameState.Animation then
        -- 使用快照数据，将快照数据复制到Chessboard供UI使用
        local snapshot = uiData.ChessboardSnapshot
        local dataChessboard = uiData.Chessboard
        local validCount = 0
        for i = 1, #snapshot do
            local snapshotData = snapshot[i]
            if snapshotData then
                if not dataChessboard[i] then
                    dataChessboard[i] = {}
                end
                for k, v in pairs(snapshotData) do
                    dataChessboard[i][k] = v
                end
                if snapshotData.IsValid then
                    validCount = validCount + 1
                end
            end
        end
        -- 快照数据长度可能与当前棋盘长度不同，需要清理多余的数据
        for i = #snapshot + 1, #dataChessboard do
            dataChessboard[i] = nil
        end
        return
    end

    local chessboard = game:GetChessBoard()
    local pieces = chessboard:GetAllPieces()
    local dataChessboard = uiData.Chessboard

    -- 初始化棋盘数据数组大小
    local piecesAmount = chessboard:GetPiecesAmount()
    self:UpdateChessboardSize(piecesAmount)

    -- 创建一个位置映射，用于快速查找棋子
    local pieceMapByIndex = {}
    for _, piece in ipairs(pieces) do
        local x, y = piece:GetPosition()
        if x > 0 and y > 0 then
            local index = chessboard:GetIndex(x, y)
            pieceMapByIndex[index] = piece
        end
    end

    -- 收集所有已开始播放的动画组中被标记为删除的棋子UID（延迟消除状态）
    -- 只有在动画组状态为 "playing" 或 "finished" 时，才标记为 IsDead
    -- 这样 PanelDead 只在动画开始播放后才显示
    local deletedPieceUids = {}
    local debugLogUids = {}
    if uiData.AnimationGroups and type(uiData.AnimationGroups) == "table" then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        for i, animationGroup in ipairs(uiData.AnimationGroups) do
            -- 只检查状态为 "playing" 或 "finished" 的动画组（已开始播放的动画）
            if animationGroup and animationGroup._State then
                if animationGroup._AnimationData then
                    for _, animData in ipairs(animationGroup._AnimationData) do
                        if animData.type == XLuckyTenant2Enum.AnimationType.DeletePiece and animData.pieceUid then
                            if animationGroup._State == "playing" or animationGroup._State == "finished" then
                                deletedPieceUids[animData.pieceUid] = true
                                table.insert(debugLogUids, { uid = animData.pieceUid, state = animationGroup._State, index = i })
                            end
                        end
                    end
                end
            end
        end
    end


    -- 填充棋盘数据
    for i = 1, piecesAmount do
        local piece = pieceMapByIndex[i]
        local x, y = chessboard:GetXY(i)
        ---@class XUiLuckyTenant2GameGridChessData
        local data = dataChessboard[i]

        if piece then
            -- 填充棋子UI数据
            data.IsValid = true
            data.Uid = piece:GetUid()
            data.Id = piece:GetId()
            data.Name = piece:GetName()
            data.Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId())
            -- Quality使用数字值，UI层可以根据值显示对应品质图标
            data.Quality = piece:GetQuality()
            data.Score = piece:GetTotalValue()
            data.Value = piece:GetTotalValue()
            data.Level = piece:GetLevel()
            data.IsCanUpgrade = piece._CanUpgrade or false

            -- 获取状态信息（倒计时）
            local states = piece:GetAllStates()
            data.States = {}
            local round = nil
            for _, state in ipairs(states) do
                local skillId = state:GetSkillId()
                local remainRounds = state:GetRemainRounds()
                data.States[#data.States + 1] = {
                    StateType = state:GetStateType(),
                    Round = remainRounds,
                    Desc = self:GetSkillDescById(skillId),
                    SkillId = skillId,
                    ImageBg = self:GetBondQualityBgBySkillId(skillId) or "",
                }
                if remainRounds and remainRounds > 0 and not round then
                    round = remainRounds
                end
            end
            self:AppendRoleUpgradeStateIfMissing(piece, data)
            self:AppendStateSkillDisplayIfMissing(piece, data, game:GetRound())
            data.Round = round or data.Round

            data.X = x
            data.Y = y
            data.Position = i
        else
            -- 空位置
            data.IsValid = false
            data.Icon = false
            data.Uid = 0
            data.Id = 0
            data.X = x
            data.Y = y
            data.Position = i
            data.Round = nil
            data.States = nil
        end
    end
end

---从当前游戏状态获取指定格子的显示数据（用于 AddPiece 动画时先显示新棋子再播特效，不读快照）
---@param x number X坐标
---@param y number Y坐标
---@return table|nil 格子显示数据（与 Chessboard[i] 结构一致），无棋子时返回 nil
function XLuckyTenant2Control:GetCellDisplayDataFromGame(x, y)
    if not self._Game or not x or not y then
        return nil
    end
    local chessboard = self._Game:GetChessBoard()
    local piece = chessboard:GetPieceByPosition(x, y)
    local index = chessboard:GetIndex(x, y)
    local data = {}
    data.X = x
    data.Y = y
    data.Position = index
    if piece then
        data.IsValid = true
        data.Uid = piece:GetUid()
        data.Id = piece:GetId()
        data.Name = piece:GetName()
        data.Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId())
        data.Quality = piece:GetQuality()
        data.Score = piece:GetTotalValue()
        data.Value = piece:GetTotalValue()
        data.Level = piece:GetLevel()
        data.IsCanUpgrade = piece._CanUpgrade or false
        data.States = {}
        local round = nil
        local states = piece:GetAllStates()
        for _, state in ipairs(states) do
            local skillId = state:GetSkillId()
            local remainRounds = state:GetRemainRounds()
            data.States[#data.States + 1] = {
                StateType = state:GetStateType(),
                Round = remainRounds,
                Desc = self:GetSkillDescById(skillId),
                SkillId = skillId,
                ImageBg = self:GetBondQualityBgBySkillId(skillId) or "",
            }
            if remainRounds and remainRounds > 0 and not round then
                round = remainRounds
            end
        end
        self:AppendRoleUpgradeStateIfMissing(piece, data)
        self:AppendStateSkillDisplayIfMissing(piece, data, self._Game:GetRound())
        data.Round = round or data.Round
    else
        data.IsValid = false
        data.Icon = false
        data.Uid = 0
        data.Id = 0
        data.Round = nil
        data.States = nil
    end
    return data
end

---停止游戏
function XLuckyTenant2Control:StopGame()
    self._Game = false
end

---获取活动结束时间
---@return number
function XLuckyTenant2Control:GetActivityEndTime()
    local config = self._Model:GetActivityConfig()
    if not config then
        return 0
    end
    local timeId = config.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    return endTime
end

---获取任务分组ID列表
---@return number[]
function XLuckyTenant2Control:GetTaskGroupIds()
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig and activityConfig.TaskGroup then
        return activityConfig.TaskGroup
    end
    return {}
end

---获取活动时间ID（用于显示倒计时）
---@return number
function XLuckyTenant2Control:GetActivityTimerId()
    local config = self._Model:GetActivityConfig()
    if not config then
        return 0
    end
    return config.TimeId or 0
end

---更新活动剩余时间
function XLuckyTenant2Control:UpdateActivityTimeLeft()
    local config = self._Model:GetActivityConfig()
    if not config then
        return
    end
    local timeId = config.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime - currentTime
    remainTime = math.max(0, remainTime)
    self._UiData.RemainTime = remainTime
end

---检查活动时间
function XLuckyTenant2Control:CheckInTime()
    if XMVCA.XLuckyTenant2:IsOffline() then
        return
    end
    if self._UiData.RemainTime <= 0 then
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end
end

---设置关卡已游玩标记
---@param stageId number 关卡ID
function XLuckyTenant2Control:SetStageHasPlayed(stageId)
    if not stageId or stageId <= 0 then
        return
    end
    local key = XMVCA.XLuckyTenant2:GetKeyHasPlayed(stageId)
    XSaveTool.SaveData(key, true)
end

---更新动画图标
function XLuckyTenant2Control:UpdateIcon4Animation()
    self._UiData.Icon4Animation = {}
    local result = self._UiData.Icon4Animation

    if not self._Game then
        return
    end

    local bag = self._Game:GetBag()
    local pieces = bag:GetPieces()
    for uid, piece in pairs(pieces) do
        result[#result + 1] = {
            Uid = piece:GetUid(),
            Id = piece:GetId(),
            Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId()),
            QualityIcon = self._Model:GetQualityIconQuad(piece:GetQuality())
        }
    end
end

-- ==================== 玩家操作 ====================

---选择棋子
---@param index number 棋子索引
function XLuckyTenant2Control:SelectPiece(index)
    if not self._Game then
        return
    end
    if XMVCA.XLuckyTenant2:IsRequesting() then
        return
    end

    local success, piece = self._Game:SelectPiece(self._Model, index)
    if not success then
        XLog.Error("[XLuckyTenant2Control] 选择棋子失败，index:" .. tostring(index))
        return
    end

    -- 标记棋子为已获得（用于"新"标记）
    if piece then
        self:MarkChessAsObtained(piece:GetId())
    end

    -- 选择棋子后立即刷新羁绊等级与数值（但不显示Toast）
    if XMVCA.XLuckyTenant2 then
    end
    local bondLevelChanges = self:RefreshBondLevelsWithoutToast()
    if XMVCA.XLuckyTenant2 then
    end
    self._Game:_ProcessBondLevelChanges(self._Model)
    if XMVCA.XLuckyTenant2 then
    end
    self:UpdateGameState()
    XLuaUiManager.SafeClose("UiLuckyTenant2Chess")
    -- 选择棋子后，关闭选棋界面，回到游戏界面
    self._UiData.IsBagDirty = true
    -- 刷新羁绊列表（因为选择棋子后羁绊等级可能已改变）
    self:UpdateBonds()
    -- 返回棋盘界面前刷新棋盘数据（确保倒计时及时更新）
    self:UpdateChessboard()

    -- 关闭选棋界面后，再显示Toast
    if bondLevelChanges then
        self:ApplyBondLevelChanges(bondLevelChanges)
    end

    -- 状态推进由 Control 层管理，根据在线/离线状态决定推进时机
    if XMVCA.XLuckyTenant2:IsOffline() then
        -- 离线状态下，选择棋子后立即推进状态
        self:NextGameState()
    else
        -- 在线状态下，服务器请求成功后推进状态
        XMVCA.XLuckyTenant2:RequestNextRound(self._Game, function()
            -- 服务器请求成功后，手动推进状态
            self:NextGameState()
        end)
    end
end

---删除棋子
---@param uid number 棋子UID
function XLuckyTenant2Control:DeletePiece(uid)
    if not self._Game then
        return
    end
    self._Game:DeletePieceByUid(uid, true) -- true表示来自玩家操作
    -- 删除棋子后立即刷新羁绊等级与数值
    self:RefreshBondLevels()
    self._Game:_ProcessBondLevelChanges(self._Model)
end

---确认使用删除道具并删除棋子（弹窗确认后调用）
---@param uid number 棋子UID
---@return boolean 是否成功（道具不足或删除失败为 false）
function XLuckyTenant2Control:ConfirmDeletePieceWithProp(uid)
    if not self._Game or not uid or uid <= 0 then
        return false
    end
    if not self:HasEnoughPropToDelete() then
        XUiManager.TipText("LuckyTenantPropNotEnough")
        return false
    end
    local bag = self._Game:GetBag()
    bag:ReducePropAmount(XLuckyTenant2Enum.Item.DeleteProp)
    self:DeletePiece(uid)
    self._UiData.IsBagDirty = true
    self._UiData.IsPropDirty = true
    return true
end

---刷新选择棋子（使用道具）
---@param useProp boolean 是否使用道具
function XLuckyTenant2Control:RefreshSelectPiece(useProp)
    if not self._Game then
        return
    end

    self._UiData.IsPropDirty = true
    -- 标记需要刷新选项
    self._Game._IsDirtyPiecesToSelect = true
    self._Game:RefreshOptions(self._Model)
    self:UpdateSelectPiece()
    XMVCA.XLuckyTenant2:RequestSupplyPieces(self._Game, useProp)
end

---使用道具刷新选择棋子
---@return boolean 是否成功
function XLuckyTenant2Control:RefreshSelectPiecesByProp()
    if not self._Game then
        return false
    end

    -- 检查随机池大小，如果只有3个则无法刷新选项
    local game = self._Game
    local needAmount = game._AmountOfPiecesToSelect or 3
    local randomBucketSize = #(game._PiecesRandomBucket or {})
    local fixedBucketSize = #(game._PiecesFixedBucket or {})

    -- 如果随机池大小正好等于需要的数量，且没有固定池，则无法刷新
    if randomBucketSize == needAmount and fixedBucketSize == 0 then
        XLog.Warning("[XLuckyTenant2Control] 随机池里只有" .. tostring(needAmount) .. "个棋子，无法刷新选项")
        XUiManager.TipText("LuckyTenantRefreshNotAvailable")
        return false
    end

    if game:GetFreeRefreshTimes() > 0 then
        game:ReduceFreeRefreshTimes()
        self:RefreshSelectPiece(false) -- 不使用道具，使用免费次数
        return true
    end

    -- 检查道具数量
    local bag = game:GetBag()
    local prop = bag:GetProp(XLuckyTenant2Enum.Item.RefreshProp)
    if prop then
        local amount = prop:GetAmount()
        if amount and amount > 0 then
            bag:ReducePropAmount(XLuckyTenant2Enum.Item.RefreshProp)
            self:RefreshSelectPiece(true)
            return true
        end
    end

    XUiManager.TipText("LuckyTenantPropNotEnough")
    return false
end

function XLuckyTenant2Control:IsRefreshOptionAvailable()
    if not self._Game then
        return false
    end
    local game = self._Game
    local needAmount = game._AmountOfPiecesToSelect or 3
    local randomBucketSize = #(game._PiecesRandomBucket or {})
    local fixedBucketSize = #(game._PiecesFixedBucket or {})
    return not (randomBucketSize == needAmount and fixedBucketSize == 0)
end

---更新背包数据（按类型分组）
function XLuckyTenant2Control:UpdateBag()
    -- 每次更新, 都清空选中, 防止残留
    if not self._UiData.IsBagDirty then
        -- 即使不脏，如果只是点击选择棋子，也需要刷新选中状态
        local selectedPiece = self._UiData.SelectedBagPiece
        if selectedPiece and selectedPiece.Uid then
            -- 更新选中棋子的选中状态到所有 grid 数据中
            self:UpdateBagGridSelectedState()
        end
        -- 即使提前返回，也要更新棋子数量（因为棋子数量可能已改变）
        if self._Game then
            self._UiData.PiecesAmount = self._Game:GetBag():GetPiecesAmount()
        end
        return
    end

    local selectedPieceLastTime = self._UiData.SelectedBagPiece
    local selectedUid = nil
    if selectedPieceLastTime then
        if not self._Game or not self._Game:GetBag():GetPieceByUid(selectedPieceLastTime.Uid) then
            self._UiData.SelectedBagPiece = false
        else
            selectedUid = selectedPieceLastTime.Uid
        end
    end

    self._UiData.IsBagDirty = false
    local uiData = self._UiData.Bag
    for i = #uiData, 1, -1 do
        uiData[i] = nil
    end

    if not self._Game then
        return
    end

    local bag = self._Game:GetBag()
    local pieces = bag:GetPieces()

    -- 按类型分组（过滤掉道具，不显示在背包UI中）
    local dictionary = {}
    for uid, piece in pairs(pieces) do
        -- 过滤掉 RefreshProp 和 DeleteProp（不显示在背包中）
        local pieceId = piece:GetId()
        if pieceId ~= XLuckyTenant2Enum.PropId.RefreshProp and pieceId ~= XLuckyTenant2Enum.PropId.DeleteProp then
            local pieceType = piece:GetPieceType()
            local array = dictionary[pieceType]
            if not array then
                array = {}
                dictionary[pieceType] = array
            end
            table.insert(array, piece)
        end
    end

    -- 获取当前回合数（用于计算状态剩余回合）
    local currentRound = self._Game:GetRound()

    -- 为每个类型创建分组数据
    for pieceType, piecesOfType in pairs(dictionary) do
        local piecesData = {}
        for _, piece in ipairs(piecesOfType) do
            -- 获取状态剩余回合数
            local states = piece:GetAllStates()
            local round = nil
            for _, state in ipairs(states) do
                local remainRounds = state:GetRemainRounds()
                if remainRounds and remainRounds > 0 then
                    round = remainRounds
                    break
                end
            end

            ---@class XUiLuckyTenant2ChessBagGridData
            local pieceData = {
                Name = piece:GetName(),
                Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId()),
                Value = piece:GetTotalValue(),
                ValueUponDeletion = piece:GetValueUponDeletion(),
                Desc = self._Model:GetLuckyTenant2ChessDescById(piece:GetId()) or {},
                QualityValue = piece:GetQuality(),
                Quality = self._Model:GetQualityIconQuad(piece:GetQuality()),
                IsCanDelete = piece:IsCanDelete() and 1 or 0,
                Uid = piece:GetUid(),
                Id = piece:GetId(),
                Round = round,
                IsDirty = true,
                IsSelected = (selectedUid and piece:GetUid() == selectedUid) or false,
                TypeName = self._Model:GetLuckyTenant2ChessTypeNameById(piece:GetPieceType())
            }
            piecesData[#piecesData + 1] = pieceData
        end

        -- 排序（按品质和UID）
        table.sort(piecesData, function(a, b)
            if a.QualityValue ~= b.QualityValue then
                return a.QualityValue > b.QualityValue
            end
            return a.Uid < b.Uid
        end)

        -- 分组标题与图标使用羁绊名和羁绊图标（取该组第一个棋子的羁绊）
        local bondId = tonumber(piecesOfType[1]:GetBondId())
        local typeDesc = self._Model:GetLuckyTenant2BondNameById(bondId) or self._Model:GetLuckyTenant2ChessTypeNameById(pieceType) or ""
        local iconBond = self._Model:GetLuckyTenant2BondIconById(bondId) or ""
        ---@class XUiLuckyTenant2ChessBagGroupData
        local groupData = {
            Type = pieceType,
            TypeDesc = typeDesc,
            IconBond = iconBond,
            ---@type XUiLuckyTenant2ChessBagGridData[]
            Pieces = piecesData,
        }
        uiData[#uiData + 1] = groupData
    end

    -- 按类型ID排序分组
    table.sort(uiData, function(a, b)
        return a.Type < b.Type
    end)

    -- 更新棋子数量
    self._UiData.PiecesAmount = bag:GetPiecesAmount()
end

---更新背包 Grid 的选中状态（用于在非脏数据更新时刷新选中状态）
function XLuckyTenant2Control:UpdateBagGridSelectedState()
    local selectedPiece = self._UiData.SelectedBagPiece
    if not selectedPiece or not selectedPiece.Uid then
        return
    end

    local bagData = self._UiData.Bag
    local selectedUid = selectedPiece.Uid

    -- 遍历所有分组，找到并更新选中状态
    for _, groupData in ipairs(bagData) do
        if groupData.Pieces then
            for _, pieceData in ipairs(groupData.Pieces) do
                pieceData.IsSelected = (pieceData.Uid == selectedUid)
            end
        end
    end
end

---关卡通过（record 需含 StageId、Score、Round、IsNormalClear，与 Model:OnStagePassed / 主界面关卡列表使用一致）
function XLuckyTenant2Control:OnStagePassed()
    if not self._Game then
        return
    end

    local game = self._Game
    local record = game:GetRecord4Server()
    -- 确保 record 包含有效的 StageId 及通关数据（GetRecord4Server 仅有 StageId/SelectPiece/DeletePiece，需补全）
    if not record.StageId or record.StageId <= 0 then
        local stageId = game:GetStageId()
        if stageId and stageId > 0 then
            record.StageId = stageId
        else
            XMVCA.XLuckyTenant2:Print("[XLuckyTenant2Control] OnStagePassed: cannot get valid StageId from Game")
            return
        end
    end
    record.Score = record.Score or game:GetTotalScore()
    record.Round = record.Round or game:GetRound()
    record.IsNormalClear = record.IsNormalClear or game:IsNormalClear()
    -- 保存 stageId 用于结算界面
    self._SettlementStageId = record.StageId
    self._Model:OnStagePassed(record)
    self._Model:ClearPlayingStage()
    -- 更新结算数据
    self:UpdateSettlement()
end

---更新结算数据
function XLuckyTenant2Control:UpdateSettlement()
    local settlementData = self._UiData.Settlement

    if self._Game then
        -- 从Game获取数据
        settlementData.Score = self._Game:GetTotalScore() or 0
        settlementData.Round = self._Game:GetRound() or 0
        local questCompletedAmount, questTotalAmount = self._Game:GetQuestProgress()
        settlementData.QuestCompletedAmount = questCompletedAmount or 0
        settlementData.QuestTotalAmount = questTotalAmount or 0

        local GameState = XLuckyTenant2Enum.GameState
        local gameState = self._Game:GetState()
        settlementData.IsPerfectClear = (gameState == GameState.PerfectClear)
        settlementData.IsNormalClear = (gameState == GameState.NormalClear) or self._Game:IsNormalClear()
        settlementData.IsFail = (gameState == GameState.GameOver)
    else
        -- 如果Game已经不存在，从UiData获取最后的数据
        settlementData.Score = self._UiData.Score or 0
        settlementData.Round = self._UiData.Round or 0
        settlementData.QuestCompletedAmount = self._UiData.QuestCompletedAmount or 0
        settlementData.QuestTotalAmount = self._UiData.QuestTotalAmount or 0
        settlementData.IsNormalClear = self._UiData.IsNormalClear or false
    end

    -- 从Model的record获取IsNewRecord信息（无论Game是否存在）
    local stageId = self._SettlementStageId or self._Model:GetPlayingStageId()
    if stageId and stageId > 0 then
        local record = self._Model:GetStageRecord(stageId)
        if record then
            settlementData.IsNewRecord = record.IsNewRecord or false
        else
            settlementData.IsNewRecord = false
        end
    else
        settlementData.IsNewRecord = false
    end
end

---获取结算界面的StageId
---@return number|nil
function XLuckyTenant2Control:GetStageIdForSettlement()
    return self._SettlementStageId or self._Model:GetPlayingStageId()
end

---完成动画
function XLuckyTenant2Control:FinishAnimation()
    self._UiData.AnimationGroups = false
    -- 清理快照数据，使用真实数据
    self._UiData.ChessboardSnapshot = nil
    self:NextGameState()
    self:UpdateUiData(true)
end

-- ==================== Getter/Setter ====================

---获取UI数据
---@return table
function XLuckyTenant2Control:GetUiData()
    return self._UiData
end

---获取棋盘列数
---@return number|nil
function XLuckyTenant2Control:GetChessBoardColumn()
    if self._Game then
        local chessboard = self._Game:GetChessBoard()
        if chessboard then
            return chessboard:GetColumn()
        end
    end
    return nil
end

---获取棋盘数量上限（列×行，用于显示「背包数量/上限」）
---@return number
function XLuckyTenant2Control:GetChessBoardMaxPieces()
    if self._Game then
        local chessboard = self._Game:GetChessBoard()
        if chessboard then
            return chessboard:GetPiecesAmount() or 0
        end
    end
    return 0
end

---获取游戏对象
---@return XLuckyTenant2Game|false
function XLuckyTenant2Control:GetGame()
    return self._Game
end

---获取当前阶段需要的分数（当前任务的目标分数）
---@return number 目标分数
function XLuckyTenant2Control:GetTargetQuestScore()
    if not self._Game then
        -- 如果游戏不存在，返回完美通关分数作为后备
        local stageId = self._Model:GetPlayingStageId()
        if stageId > 0 then
            local _, perfectClearScore = self._Model:GetRoundsToPerfectClear(stageId)
            return perfectClearScore or 0
        end
        return 0
    end

    local game = self._Game
    -- 使用当前任务的目标分数
    local currentQuest = game:GetCurrentQuest()
    if currentQuest and currentQuest.Score then
        return currentQuest.Score
    else
        -- 如果没有当前任务，使用完美通关分数作为后备
        local stageId = self._Model:GetPlayingStageId()
        if stageId > 0 then
            local _, perfectClearScore = self._Model:GetRoundsToPerfectClear(stageId)
            return perfectClearScore or 0
        end
        return 0
    end
end

---获取上一个目标任务（Round <= round 的最后一个，即已到达或已过的目标）
---@param round number|nil 回合数（可选，默认使用当前回合）
---@return table|nil 上一个 quest，含 Round、Score、Desc、RewardPieces 等
function XLuckyTenant2Control:GetLastTargetQuest(round)
    if not self._Game then
        return nil
    end
    local game = self._Game
    round = round or game:GetRound()
    local allQuests = game:GetAllQuest()
    if not allQuests or #allQuests == 0 then
        return nil
    end
    -- 从后往前找第一个 Round <= round 的 quest
    for i = #allQuests, 1, -1 do
        local quest = allQuests[i]
        if quest and quest.Round and quest.Round <= round then
            return quest
        end
    end
    return nil
end

---获取下一个quest的回合数（用于计算剩余回合数）
---@return number 下一个quest的回合数，如果没有则返回总回合数
function XLuckyTenant2Control:GetNextQuestRound()
    if not self._Game then
        return 0
    end

    local game = self._Game
    local currentRound = game:GetRound()
    local allQuests = game:GetAllQuest()

    if not allQuests or #allQuests == 0 then
        return 0
    end

    -- 找到下一个quest（第一个回合数 > 当前回合的quest）
    for i = 1, #allQuests do
        local quest = allQuests[i]
        if quest and quest.Round >= currentRound then
            return quest.Round
        end
    end

    -- 如果没有下一个quest，返回最后一个quest的回合数
    local lastQuest = allQuests[#allQuests]
    return lastQuest and lastQuest.Round or 0
end

---获取棋子标签数据
---获取品质图标（圆形）
---@param qualityValue number 品质值
---@return string
function XLuckyTenant2Control:GetQualityIconCircle(qualityValue)
    return self._Model:GetQualityIconCircle(qualityValue)
end

---获取刷新道具图标
---@return string
function XLuckyTenant2Control:GetRefreshPropIcon()
    local icon = self._Model:GetLuckyTenant2ChessIconById(XLuckyTenant2Enum.PropId.RefreshProp)
    return icon or ""
end

---获取删除道具图标
---@return string
function XLuckyTenant2Control:GetDeletePropIcon()
    local icon = self._Model:GetLuckyTenant2ChessIconById(XLuckyTenant2Enum.PropId.DeleteProp)
    return icon or ""
end

---获取棋子详情背景图路径（来自 LuckyTenant2Quality 配置表 BgChessDetail）
---@param qualityId number 品质ID
---@return string
function XLuckyTenant2Control:GetChessDetailBgPath(qualityId)
    if not qualityId or qualityId <= 0 then
        return ""
    end
    return self._Model:GetLuckyTenant2QualityBgChessDetailById(qualityId) or ""
end

---获取删除币数量
---@return number
function XLuckyTenant2Control:GetDeleteCoin()
    if not self._Game then
        return 0
    end
    local bag = self._Game:GetBag()
    if not bag then
        return 0
    end
    local prop = bag:GetProp(XLuckyTenant2Enum.Item.DeleteProp)
    if prop then
        return prop:GetAmount() or 0
    end
    return 0
end

---获取刷新币数量
---@return number
function XLuckyTenant2Control:GetRefreshCoin()
    if not self._Game then
        return 0
    end
    local bag = self._Game:GetBag()
    if not bag then
        return 0
    end
    local prop = bag:GetProp(XLuckyTenant2Enum.Item.RefreshProp)
    if prop then
        return prop:GetAmount() or 0
    end
    return 0
end

---获取羁绊被动技能描述列表
---@param bondId number 羁绊ID
---@param bondLevel number 羁绊等级（可选，默认使用等级1）
---@return string[] 被动技能描述数组
function XLuckyTenant2Control:GetBondPassiveSkillDesc(bondId, bondLevel)
    if not bondId then
        return {}
    end

    -- 使用当前等级，如果等级为0或不存在，则使用等级1
    local level = bondLevel or 1
    if level <= 0 then
        level = 1
    end

    -- 获取该羁绊在当前等级下的技能配置
    local bondSkillConfigs = self._Model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, level)

    -- 收集所有被动技能的描述
    local passiveSkillDescs = {}

    -- 查找当前等级下的所有被动技能
    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        if bondSkillConfig.IsPassive then
            local skillId = bondSkillConfig.SkillId
            if skillId and skillId > 0 then
                local skillDesc = self._Model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
                if skillDesc ~= "" then
                    local params = self._Model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                    if params and #params > 0 then
                        -- 对于某些技能（Type205、Type207），第一个参数是子虫ID，描述应该从第二个参数开始
                        local skillType = self._Model:GetLuckyTenant2ChessSkillTypeById(skillId)
                        local SkillType = XLuckyTenant2Enum.Skill
                        local formatParams = params
                        if skillType == SkillType.Type205 or skillType == SkillType.Type207 then
                            -- 跳过第一个参数（子虫ID），从第二个参数开始格式化
                            formatParams = { table.unpack(params, 2) }
                        end

                        -- 使用pcall安全地调用FormatText，避免格式化错误导致崩溃
                        local success, formattedDesc = pcall(function()
                            return XUiHelper.FormatText(skillDesc, table.unpack(formatParams))
                        end)
                        if success then
                            table.insert(passiveSkillDescs, formattedDesc)
                        else
                            -- 格式化失败，使用原始描述并记录错误
                            XLog.Warning("[XLuckyTenant2Control] GetBondPassiveSkillDesc格式化技能描述失败，skillId:", skillId, "skillDesc:", skillDesc, "params:", params)
                            table.insert(passiveSkillDescs, skillDesc) -- 使用原始描述
                        end
                    else
                        table.insert(passiveSkillDescs, skillDesc)
                    end
                end
            end
        end
    end

    -- 如果没有找到当前等级的被动技能，尝试使用等级1的被动技能（作为默认）
    if #passiveSkillDescs == 0 and level ~= 1 then
        local level1Configs = self._Model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, 1)
        for _, bondSkillConfig in ipairs(level1Configs) do
            if bondSkillConfig.IsPassive then
                local skillId = bondSkillConfig.SkillId
                if skillId and skillId > 0 then
                    local skillDesc = self._Model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
                    if skillDesc ~= "" then
                        local params = self._Model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                        if params and #params > 0 then
                            local success, formattedDesc = pcall(function()
                                return XUiHelper.FormatText(skillDesc, table.unpack(params))
                            end)
                            if success then
                                table.insert(passiveSkillDescs, formattedDesc)
                            else
                                XLog.Warning("[XLuckyTenant2Control] GetBondPassiveSkillDesc格式化技能描述失败，skillId:", skillId, "skillDesc:", skillDesc, "params:", params)
                                table.insert(passiveSkillDescs, skillDesc)
                            end
                        else
                            table.insert(passiveSkillDescs, skillDesc)
                        end
                    end
                end
            end
        end
    end

    -- 字符串都使用XUiHelper.ReplaceTextNewLine(content)替换
    for i = 1, #passiveSkillDescs do
        passiveSkillDescs[i] = XUiHelper.ReplaceTextNewLine(passiveSkillDescs[i])
    end

    -- 返回所有被动技能描述数组
    return passiveSkillDescs
end

---获取羁绊升级需求描述
---@param bondId number 羁绊ID
---@return string 升级需求描述
function XLuckyTenant2Control:GetBondUpgradeRequireDesc(bondId)
    if not bondId or not self._Model then
        return ""
    end

    local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
    if bondConfig and bondConfig.UpgradeRequireDesc and bondConfig.UpgradeRequireDesc ~= "" then
        return bondConfig.UpgradeRequireDesc
    end

    return ""
end

---获取羁绊当前生效的技能列表（用于显示 Buff 列表）
---@param bondId number 羁绊ID
---@param bondLevel number 羁绊等级
---@return table[] 技能列表，每个元素包含 Index 和 Desc 字段
function XLuckyTenant2Control:GetBondActiveSkills(bondId, bondLevel)
    local result = {}
    if not bondId or bondLevel <= 0 then
        return result
    end

    -- 获取该羁绊在当前等级下的技能配置
    local bondSkillConfigs = self._Model:GetLuckyTenant2BondSkillConfigsByBondIdAndMaxLevel(bondId, bondLevel)

    local index = 1
    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        -- 显示所有技能（无论是否被动）
        local skillId = bondSkillConfig.SkillId
        if skillId and skillId > 0 then
            local skillDesc = self._Model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
            if skillDesc ~= "" then
                -- 格式化技能描述（将 Params 的值填入描述中）
                local params = self._Model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                if params and #params > 0 then
                    -- 使用pcall安全地调用FormatText，避免格式化错误导致崩溃
                    local success, formattedDesc = pcall(function()
                        return XUiHelper.FormatText(skillDesc, table.unpack(params))
                    end)
                    if success then
                        skillDesc = formattedDesc
                    else
                        -- 格式化失败，使用原始描述并记录错误
                        XLog.Warning("[XLuckyTenant2Control] GetBondActiveSkills格式化技能描述失败，skillId:", skillId, "skillDesc:", skillDesc, "params:", params)
                        -- 继续使用原始描述
                    end
                end
                table.insert(result, {
                    Index = index,
                    Desc = skillDesc,
                    Require = bondSkillConfig.SkillRequire, -- 需求数量（棋子数量/类型数量）
                })
                index = index + 1
            end
        end
    end

    return result
end

---获取羁绊所有等级的技能列表（用于显示未拥有羁绊的所有 Buffs）
---@param bondId number 羁绊ID
---@return table[] 技能列表，每个元素包含 Index 和 Desc 字段
function XLuckyTenant2Control:GetBondAllSkills(bondId)
    local result = {}
    if not bondId then
        return result
    end

    -- 获取该羁绊的所有技能配置（不限制等级）
    local bondSkillConfigs = self._Model:GetLuckyTenant2BondSkillConfigsByBondId(bondId)

    local index = 1
    for _, bondSkillConfig in ipairs(bondSkillConfigs) do
        -- 过滤掉被动技能（被动技能不应该显示在Buffs列表中）
        -- IsPassive: 1=被动技能，0=非被动技能
        if not bondSkillConfig.IsPassive or bondSkillConfig.IsPassive == 0 then
            local skillId = bondSkillConfig.SkillId
            if skillId and skillId > 0 then
                local skillDesc = self._Model:GetLuckyTenant2ChessSkillDescById(skillId) or ""
                if skillDesc ~= "" then
                    -- 格式化技能描述（将 Params 的值填入描述中）
                    local params = self._Model:GetLuckyTenant2ChessSkillParamsById(skillId) or {}
                    if params and #params > 0 then
                        -- 对于某些技能（Type205、Type207），第一个参数是子虫ID，描述应该从第二个参数开始
                        local skillType = self._Model:GetLuckyTenant2ChessSkillTypeById(skillId)
                        local SkillType = XLuckyTenant2Enum.Skill
                        local formatParams = params
                        if skillType == SkillType.Type205 or skillType == SkillType.Type207 then
                            -- 跳过第一个参数（子虫ID），从第二个参数开始格式化
                            formatParams = { table.unpack(params, 2) }
                        end

                        -- 使用pcall安全地调用FormatText，避免格式化错误导致崩溃
                        local success, formattedDesc = pcall(function()
                            return XUiHelper.FormatText(skillDesc, table.unpack(formatParams))
                        end)
                        if success then
                            skillDesc = formattedDesc
                        else
                            -- 格式化失败，使用原始描述并记录错误
                            XLog.Error("[XLuckyTenant2Control] GetBondAllSkills格式化技能描述失败，skillId:", skillId, "skillDesc:", skillDesc, "params:", params)
                            -- 继续使用原始描述
                        end
                    end
                    local level = bondSkillConfig.Level or 0
                    local qualityId = level -- 支持等级 0 使用配置表 quality id=0
                    local imageBg = self._Model:GetLuckyTenant2BondQualityBgById(qualityId) or ""
                    table.insert(result, {
                        Index = index,
                        Desc = skillDesc,
                        Require = bondSkillConfig.SkillRequire, -- 需求数量（棋子数量/类型数量）
                        Level = level,                          -- 技能等级
                        ImageBg = imageBg,                      -- 根据羁绊等级的品质背景
                    })
                    index = index + 1
                end
            end
        end
    end

    return result
end

---获取羁绊关联的棋子列表（用于显示关联棋子列表）
---@param bondId number 羁绊ID
---@return table[] 棋子列表，每个元素包含 Id, Icon, Quality, QualityValue, IsOwned 等字段
function XLuckyTenant2Control:GetBondRelatedChessList(bondId)
    local result = {}
    if not bondId then
        return result
    end

    -- 获取羁绊配置中的关联棋子ID列表（字符串，用|分隔）
    local relatedChessStr = self._Model:GetLuckyTenant2BondRelatedChessById(bondId) or ""
    if relatedChessStr == "" then
        return result
    end

    -- 解析棋子ID列表（用|分隔），并去重
    local chessIds = {}
    local chessIdSet = {} -- 用于去重
    for chessIdStr in string.gmatch(relatedChessStr, "([^|]+)") do
        local chessId = tonumber(chessIdStr)
        if chessId and chessId > 0 and not chessIdSet[chessId] then
            chessIdSet[chessId] = true
            table.insert(chessIds, chessId)
        end
    end

    -- 获取背包中的棋子数量（用于判断是否拥有）
    local bag = nil
    if self._Game then
        bag = self._Game:GetBag()
    end
    local bagPiecesMap = {}
    if bag then
        local bagPieces = bag:GetAllPieces()
        for _, piece in ipairs(bagPieces) do
            local pieceId = piece:GetId()
            if pieceId and pieceId > 0 then
                bagPiecesMap[pieceId] = true
            end
        end
    end

    -- 构建棋子数据列表
    for _, chessId in ipairs(chessIds) do
        local chessConfig = self._Model:GetLuckyTenant2ChessConfigById(chessId)
        if chessConfig then
            local chessData = {
                Id = chessId,
                Icon = self._Model:GetLuckyTenant2ChessIconById(chessId) or "",
                Quality = chessConfig.Quality or "",
                QualityValue = chessConfig.QualityValue or 0,
                IsOwned = bagPiecesMap[chessId] or false
            }
            table.insert(result, chessData)
        end
    end

    return result
end

---选择背包中的棋子
---@param data table 棋子数据
function XLuckyTenant2Control:SelectBagPiece(data)
    if self._UiData.SelectedBagPiece then
        self._UiData.SelectedBagPiece.IsSelected = false
    end
    if not data then
        self._UiData.SelectedBagPiece = false
        return
    end
    data.IsSelected = true

    -- 更新选中棋子的完整数据（包括状态等信息）
    if data.Uid then
        self:UpdateBagPieceDetailData(data)
    end

    self._UiData.SelectedBagPiece = data
end

---获取棋子对应的羁绊名字
---@param piece XLuckyTenant2Piece 棋子对象
---@return string 羁绊名字（多个羁绊用逗号分隔）
function XLuckyTenant2Control:GetPieceBondsText(piece)
    if not piece then
        return ""
    end

    local bondIdStr = piece:GetBondId()
    if not bondIdStr or bondIdStr == "" then
        return ""
    end

    local bondNames = {}
    -- 解析羁绊ID（可能用|分隔多个羁绊）
    for bondIdStr in string.gmatch(bondIdStr, "([^|]+)") do
        local bondId = tonumber(bondIdStr)
        if bondId and bondId > 0 then
            local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
            if bondConfig and bondConfig.BondName then
                table.insert(bondNames, bondConfig.BondName)
            end
        end
    end

    if #bondNames > 0 then
        return table.concat(bondNames, "、")
    end

    return ""
end

---根据棋子数据获取羁绊名字（用于UI层）
---@param data table 棋子数据（包含Position或Uid）
---@return string 羁绊名字（多个羁绊用逗号分隔）
function XLuckyTenant2Control:GetPieceBondsTextByData(data)
    if not data then
        return ""
    end

    local piece = nil
    if self._Game then
        if data.Position then
            -- 棋盘上的棋子
            local chessboard = self._Game:GetChessBoard()
            if chessboard then
                piece = chessboard:GetPieceByIndex(data.Position)
            end
        elseif data.Uid then
            -- 背包中的棋子
            local bag = self._Game:GetBag()
            if bag then
                piece = bag:GetPieceByUid(data.Uid)
            end
        end

        if piece then
            return self:GetPieceBondsText(piece)
        end
    end

    -- 如果没有找到棋子实例，尝试从配置读取（选棋界面的未拥有棋子）
    if data.Id then
        local bondIdStr = self._Model:GetLuckyTenant2ChessBondIdById(data.Id)
        if not bondIdStr or bondIdStr == "" then
            return ""
        end

        local bondNames = {}
        -- 解析羁绊ID（可能用|分隔多个羁绊）
        for bondIdStr in string.gmatch(bondIdStr, "([^|]+)") do
            local bondId = tonumber(bondIdStr)
            if bondId and bondId > 0 then
                local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
                if bondConfig and bondConfig.BondName then
                    table.insert(bondNames, bondConfig.BondName)
                end
            end
        end

        if #bondNames > 0 then
            return table.concat(bondNames, "、")
        end
    end

    return ""
end

---判断棋子是否是"新"的（本局游戏中首次获得）
---@param chessId number 棋子ID
---@return boolean 是否是新棋子
function XLuckyTenant2Control:IsChessNew(chessId)
    if not self._ObtainedChessIds then
        self._ObtainedChessIds = {}
    end
    return not self._ObtainedChessIds[chessId]
end

---标记棋子为已获得
---@param chessId number 棋子ID
function XLuckyTenant2Control:MarkChessAsObtained(chessId)
    if not self._ObtainedChessIds then
        self._ObtainedChessIds = {}
    end
    self._ObtainedChessIds[chessId] = true
end

---清除已获得棋子记录（新游戏开始时调用）
function XLuckyTenant2Control:ClearObtainedChessIds()
    self._ObtainedChessIds = {}
end

function XLuckyTenant2Control:BuildChessDetailDataByChessId(chessId)
    if not chessId or chessId <= 0 then
        return nil
    end
    if not self._Model then
        return nil
    end
    local config = self._Model:GetLuckyTenant2ChessConfigById(chessId)
    if not config then
        return nil
    end

    local canBeEliminatedValue = nil
    if config.CanBeEliminated ~= nil then
        canBeEliminatedValue = tonumber(config.CanBeEliminated)
        if canBeEliminatedValue == nil then
            canBeEliminatedValue = config.CanBeEliminated and 1 or 0
        end
    else
        canBeEliminatedValue = 0
    end

    return {
        Id = chessId,
        Name = self._Model:GetLuckyTenant2ChessNameById(chessId),
        Icon = self._Model:GetLuckyTenant2ChessIconById(chessId),
        QualityValue = config.QualityValue or config.Quality or 0,
        Value = self._Model:GetLuckyTenant2ChessValueById(chessId) or 0,
        ValueUponDeletion = config.ValueUponDeletion or 0,
        Desc = self._Model:GetLuckyTenant2ChessDescById(chessId) or {},
        TypeName = self._Model:GetLuckyTenant2ChessTypeNameById(config.Type),
        Level = config.DefaultLevel or 1,
        IsCanDelete = canBeEliminatedValue,
        CanBeEliminated = canBeEliminatedValue,
        IsCanUpgrade = false,
        IsFromSelectPiece = true,
        IsNew = self:IsChessNew(chessId),
    }
end

---更新背包中选中棋子的详情数据
---@param data table 棋子数据（会被填充完整信息）
function XLuckyTenant2Control:UpdateBagPieceDetailData(data)
    if not self._Game or not data or not data.Uid then
        return
    end

    local bag = self._Game:GetBag()
    local piece = bag:GetPieceByUid(data.Uid)
    if not piece then
        return
    end

    -- 填充完整的棋子详情数据
    data.Uid = piece:GetUid()
    data.Id = piece:GetId()
    data.Name = piece:GetName()
    data.Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId())
    data.QualityValue = piece:GetQuality()
    data.Quality = self._Model:GetQualityIconQuad(piece:GetQuality())
    data.Value = piece:GetTotalValue()
    data.ValueUponDeletion = piece:GetValueUponDeletion()
    data.Desc = self._Model:GetLuckyTenant2ChessDescById(piece:GetId()) or {}
    data.TypeName = self._Model:GetLuckyTenant2ChessTypeNameById(piece:GetPieceType())
    data.IsCanDelete = piece:IsCanDelete() and 1 or 0
    data.Level = piece:GetLevel()
    data.IsCanUpgrade = piece._CanUpgrade or false

    -- 获取棋子对应的羁绊名字
    data.BondsText = self:GetPieceBondsText(piece)

    -- 判断是否是新棋子
    data.IsNew = self:IsChessNew(piece:GetId())

    -- 获取状态信息
    local pieceStates = piece:GetAllStates()
    data.States = {}
    local round = nil
    for i = 1, #pieceStates do
        local state = pieceStates[i]
        local skillId = state:GetSkillId()
        local stateData = {
            StateType = state:GetStateType(),
            Round = state:GetRemainRounds(),
            Desc = self:GetSkillDescById(skillId),
            SkillId = skillId,
            ImageBg = self:GetBondQualityBgBySkillId(skillId) or "",
        }
        data.States[#data.States + 1] = stateData
        if state:GetRemainRounds() and state:GetRemainRounds() > 0 then
            round = state:GetRemainRounds()
        end
    end
    self:AppendRoleUpgradeStateIfMissing(piece, data)
    local displayRound = (self._UiData and self._UiData.Round) or (self._Game and self._Game:GetRound()) or 0
    self:AppendStateSkillDisplayIfMissing(piece, data, displayRound)
    -- 兼容旧代码：设置 data.Round
    data.Round = round or data.Round
end

---检查是否有足够的道具来删除棋子
---@return boolean
function XLuckyTenant2Control:HasEnoughPropToDelete()
    if not self._Game then
        return false
    end
    local bag = self._Game:GetBag()
    local prop = bag:GetProp(XLuckyTenant2Enum.Item.DeleteProp)
    if prop then
        local amount = prop:GetAmount()
        return amount and amount > 0
    end
    return false
end

---更新棋盘上棋子的详情数据
---@param data table 棋子数据（会被填充）
function XLuckyTenant2Control:UpdatePieceDataOnChessboard(data)
    if not self._Game or not data then
        return
    end

    local position = data.Position
    if position then
        local chessboard = self._Game:GetChessBoard()
        local piece = chessboard:GetPieceByIndex(position)
        if piece then
            -- 填充棋子详情数据
            data.Uid = piece:GetUid()
            data.Id = piece:GetId()
            data.Name = piece:GetName()
            data.Icon = self._Model:GetLuckyTenant2ChessIconById(piece:GetId())
            data.Quality = piece:GetQuality()
            data.QualityValue = piece:GetQuality()
            data.Value = piece:GetTotalValue()
            data.ValueUponDeletion = piece:GetValueUponDeletion()
            data.Desc = self._Model:GetLuckyTenant2ChessDescById(piece:GetId()) or {}
            data.TypeName = self._Model:GetLuckyTenant2ChessTypeNameById(piece:GetPieceType())
            data.IsCanDelete = piece:IsCanDelete()
            data.IsCanUpgrade = piece._CanUpgrade or false
            data.Level = piece:GetLevel()

            -- 获取棋子对应的羁绊名字
            data.BondsText = self:GetPieceBondsText(piece)

            -- 获取状态信息
            local pieceStates = piece:GetAllStates()
            data.States = {}
            for i = 1, #pieceStates do
                local state = pieceStates[i]
                local skillId = state:GetSkillId()
                local stateData = {
                    StateType = state:GetStateType(),
                    Round = state:GetRemainRounds(),
                    Desc = self:GetSkillDescById(skillId),
                    SkillId = skillId,
                    ImageBg = self:GetBondQualityBgBySkillId(skillId) or "",
                }
                data.States[#data.States + 1] = stateData
            end
            self:AppendRoleUpgradeStateIfMissing(piece, data)
            local displayRound = (self._UiData and self._UiData.Round) or (self._Game and self._Game:GetRound()) or 0
            self:AppendStateSkillDisplayIfMissing(piece, data, displayRound)
            -- 兼容旧代码：如果只有一个状态，也设置到 data.Round
            if #data.States > 0 then
                data.Round = data.States[1].Round
            end
        else
            data.IsValid = false
        end
    end
end

-- ==================== 主界面相关 ====================

---更新关卡列表
function XLuckyTenant2Control:UpdateStageList()
    self._UiData.Stages = {}
    local stages = self._UiData.Stages
    ---@type XTable.XTableLuckyTenant2Stage[]
    local configs = self._Model:GetStages()

    for i = 1, #configs do
        local config = configs[i]
        local id = config.Id
        local record = self._Model:GetStageRecord(id)
        local bestScore = 0
        local bestRound = 0
        if record then
            bestScore = record.Score or 0
            bestRound = record.Round or 0
        end

        local roundsToNormalClear, scoreToNormalClear = self._Model:GetRoundsToNormalClear(id)
        local roundsToPerfectClear, scoreToPerfectClear = self._Model:GetRoundsToPerfectClear(id)
        roundsToNormalClear = roundsToNormalClear or 0
        scoreToNormalClear = scoreToNormalClear or 0
        roundsToPerfectClear = roundsToPerfectClear or 0
        scoreToPerfectClear = scoreToPerfectClear or 0

        local isClear = self._Model:IsStagePassed(id)
        local isNormalClear = bestRound >= roundsToNormalClear and bestScore >= scoreToNormalClear and isClear
        local isPerfectClear = bestRound >= roundsToPerfectClear and bestScore >= scoreToPerfectClear and isClear

        local isPlaying = false
        local playingRound = false
        local playingStageId = self._Model:GetPlayingStageId()
        local isOtherStagePlaying = false
        if playingStageId and playingStageId > 0 then
            if playingStageId == id then
                isPlaying = true
                playingRound = self._Model:GetPlayingStageRound() or 0
            else
                isOtherStagePlaying = true
            end
        end

        local isNew = false
        local key = XMVCA.XLuckyTenant2:GetKeyHasPlayed(id)
        if XSaveTool.GetData(key) == nil then
            isNew = true
        end

        local isOnTime = true
        local timeId = config.TimeId
        if timeId and timeId > 0 then
            if not XFunctionManager.CheckInTimeByTimeId(timeId) then
                isOnTime = false
            end
        end

        local isPreStagePass = true
        local preStageId = config.PreStage
        if preStageId and preStageId > 0 then
            if not self._Model:IsStagePassed(preStageId) then
                isPreStagePass = false
            end
        end

        local isCanChallenge = isOnTime and isPreStagePass

        ---@class XUiLuckyTenant2MainStageGridData
        local stage = {
            Id = id,
            Name = config.Name or "",
            BestScore = bestScore,
            BestRound = bestRound,
            IsPerfectClear = isPerfectClear,
            IsNormalClear = isNormalClear,
            PlayingRound = playingRound,
            IsNew = isNew and isCanChallenge,
            IsCanChallenge = isCanChallenge,
            IsOnTime = isOnTime,
            IsPreStagePass = isPreStagePass,
            IsPlaying = isPlaying,
            IsSelected = false,
            IsOtherStagePlaying = isOtherStagePlaying,
            TimeId = timeId or 0,
            IsChallengeStage = config.IsChallenge or false,
            CoverImage = config.CoverImage or "",
        }
        stages[i] = stage
    end

    table.sort(stages, function(a, b)
        return a.Id < b.Id
    end)
end

---获取主界面UI数据
---@return table
function XLuckyTenant2Control:GetUiMain()
    self:UpdateStageList()
    local uiData = self._UiData

    -- 格式化剩余时间
    local timeStr = "00:00:00"
    if uiData.RemainTime and uiData.RemainTime > 0 then
        timeStr = XUiHelper.GetTime(uiData.RemainTime, XUiHelper.TimeFormatType.ACTIVITY)
    end

    -- 获取所有关卡数据（按ID索引）
    local allStagesMap = {}
    for _, stage in ipairs(uiData.Stages or {}) do
        allStagesMap[stage.Id] = stage
    end

    -- 获取章节配置
    local chapterConfigs = self._Model:GetChapters()
    local chapters = {}

    if #chapterConfigs > 0 then
        -- 有章节配置，按章节组织关卡
        for _, chapterConfig in ipairs(chapterConfigs) do
            ---@class XUiLuckyTenant2MainChapterData
            local chapterData = {
                Id = chapterConfig.Id,
                Name = chapterConfig.Name or "",
                Stages = {},
            }

            -- 根据章节配置的StageId数组，获取对应的关卡数据
            if chapterConfig.StageId then
                for index, stageId in ipairs(chapterConfig.StageId) do
                    local stage = allStagesMap[stageId]
                    if stage then
                        -- 添加序号（从1开始）
                        stage.Index = index
                        chapterData.Stages[#chapterData.Stages + 1] = stage
                    end
                end
            end

            chapters[#chapters + 1] = chapterData
        end
    else
        -- 没有章节配置，所有关卡放在一个默认章节下
        local defaultStages = uiData.Stages or {}
        for index, stage in ipairs(defaultStages) do
            stage.Index = index
        end
        ---@class XUiLuckyTenant2MainChapterData
        local chapterData = {
            Id = 1,
            Name = "",
            Stages = defaultStages,
        }
        chapters[#chapters + 1] = chapterData
    end

    -- 主界面展示奖励：使用 Activity 表 RewardId 通过 XRewardManager.GetRewardList 获取
    local rewards = {}
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig and activityConfig.RewardId and activityConfig.RewardId > 0 then
        rewards = XRewardManager.GetRewardList(activityConfig.RewardId) or {}
    end

    return {
        RemainTime = timeStr,
        Chapters = chapters,
        Rewards = rewards,
    }
end

---更新关卡详情数据
---@param stageId number 关卡ID
function XLuckyTenant2Control:UpdateStageDetail(stageId)
    local data = self._UiData.StageDetail
    local bestScore = 0
    local bestRound = 0
    local record = self._Model:GetStageRecord(stageId)
    if record then
        bestScore = record.Score or 0
        bestRound = record.Round or 0
    end
    data.BestScore = bestScore
    data.BestRound = bestRound
    local roundsToPerfectClear = self._Model:GetRoundsToPerfectClear(stageId)
    data.IsMax = (bestRound >= roundsToPerfectClear and bestRound > 0)
    data.IsPlaying = (self._Model:GetPlayingStageId() == stageId)

    -- 如果已经是当前关卡，只更新记录数据
    if data.Id == stageId then
        return
    end

    ---@type XTable.XTableLuckyTenant2Stage
    local stageConfig = self._Model:GetLuckyTenant2StageConfigById(stageId)
    if not stageConfig then
        XLog.Warning("[XLuckyTenant2Control] UpdateStageDetail stageId not found:", tostring(stageId))
        return
    end

    data.RoundsToPerfectClear = roundsToPerfectClear
    data.QuestAmount = self._Model:GetQuestAmount(stageId)
    data.Id = stageConfig.Id
    data.Name = stageConfig.Name or ""
    data.IsChallengeStage = (stageConfig.IsChallenge and stageConfig.IsChallenge > 0) or false
    data.Desc = stageConfig.Desc or ""
    data.PerfectDesc = self._Model:GetLuckyTenant2StagePerfectDescById(stageId) or ""
    data.Bonds = {}

    -- 当前关卡在章节中的序号（1/2/3）：关1只显示 UiStage1，关2只显示 UiStage2；章节名用于显示「章节名·关卡名」
    data.StageIndexInChapter = 0
    data.ChapterName = ""
    local chapterConfigs = self._Model:GetChapters()
    if chapterConfigs and #chapterConfigs > 0 and stageId then
        for _, chapterConfig in ipairs(chapterConfigs) do
            local stageIds = chapterConfig.StageId
            if stageIds and #stageIds > 0 then
                for idx, sid in ipairs(stageIds) do
                    if sid == stageId then
                        data.ChapterName = chapterConfig.Name or ""
                        -- 当前是第几关（1/2/3），超过3取前3
                        data.StageIndexInChapter = math.min(3, idx)
                        break
                    end
                end
                if data.StageIndexInChapter > 0 then
                    break
                end
            end
        end
    end

    -- 解析ShowBondId字符串（用|分隔）
    local showBondIdStr = stageConfig.ShowBondId or ""
    local bondIds = {}
    if showBondIdStr ~= "" then
        bondIds = string.Split(showBondIdStr, "|")
    end

    -- 准备羁绊数据
    for i, bondIdStr in ipairs(bondIds) do
        local bondId = tonumber(bondIdStr)
        if bondId and bondId > 0 then
            local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
            if bondConfig then
                local bondData = {
                    BondId = bondId,
                    Icon = self._Model:GetLuckyTenant2BondIconById(bondId) or bondConfig.Icon or "",
                    IsDirty = true,
                }
                data.Bonds[#data.Bonds + 1] = bondData
            end
        end
    end
end

---获取羁绊详情数据（用于关卡详情弹窗）
---@param bondId number 羁绊ID
---@return table|nil 羁绊详情数据
function XLuckyTenant2Control:GetBondDetailDataForStagePopup(bondId)
    -- 获取羁绊配置
    local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
    if not bondConfig then
        return nil
    end

    -- 准备羁绊详情数据（Name/Icon 与游戏内羁绊列表一致，便于 BondsDetail 共用）
    local bondData = {
        BondId = bondId,
        Name = bondConfig.BondName or "",
        BondName = bondConfig.BondName or "",
        BondDesc = bondConfig.BondDesc or "",
        Icon = self._Model:GetLuckyTenant2BondIconById(bondId) or bondConfig.Icon or "",
        BondIcon = bondConfig.Icon or "",
        CurrentLevel = 0,   -- 关卡详情中没有当前等级，显示为0
        PieceCount = 0,     -- 关卡详情中没有棋子数量
        Buffs = {},         -- 显示该羁绊的所有技能
        ChessRequires = {}, -- 关联的棋子列表
    }

    -- 获取所有技能列表（用于显示 Buff 列表）
    bondData.Buffs = self:GetBondAllSkills(bondId)
    -- 关卡详情中全部标记为未拥有，未达到的等级用 0 级背景和 0 级字色
    local imageBgLevel0 = self._Model:GetLuckyTenant2BondQualityBgById(0) or ""
    for i = 1, #bondData.Buffs do
        bondData.Buffs[i].IsOwned = false
        bondData.Buffs[i].ImageBg = imageBgLevel0
        bondData.Buffs[i].LevelColor = BondLevelColors[0]
    end

    -- 获取关联的棋子列表（用于显示关联棋子列表）
    bondData.ChessRequires = self:GetBondRelatedChessList(bondId)
    XLog.Error(bondData.ChessRequires)

    return bondData
end

---准备任务成功弹窗数据
---@param quest table Quest配置数据
---@param currentScore number 当前分数
---@return table Quest弹窗数据
function XLuckyTenant2Control:PrepareQuestSuccessData(quest, currentScore)
    local questData = {
        CurrentScore = currentScore,
        TargetScore = quest.Score or 0,
        Round = quest.Round or 0,
        Rewards = {},
    }

    -- 准备奖励数据
    local rewardPieces = quest.RewardPieces or {}
    local rewardAmounts = quest.RewardPiecesAmount or {}

    for i = 1, #rewardPieces do
        local pieceId = rewardPieces[i]
        local amount = rewardAmounts[i] or 1

        if pieceId and pieceId > 0 then
            -- 获取棋子配置
            local pieceConfig = self._Model:GetLuckyTenant2ChessConfigById(pieceId)
            if pieceConfig then
                local rewardData = {
                    PieceId = pieceId,
                    Amount = amount,
                    Icon = self._Model:GetLuckyTenant2ChessIconById(pieceId) or "",
                }
                table.insert(questData.Rewards, rewardData)
            end
        end
    end

    return questData
end

function XLuckyTenant2Control:_SetTestCase(id)
    id = tonumber(id)
    if id == 0 then
        self._Game:RemoveTestCase()
        XLog.Error("[XLuckyTenant2Control] 移除测试用例")
        return
    end
    if not id then
        XLog.Error("[XLuckyTenant2Control] id错误")
        return
    end
    local testCase = self._Model:GetTestCase(id)
    if not testCase then
        XLog.Error("[XLuckyTenant2Control] 找不到用例配置")
        return
    end
    self._Game:SetTestCase(testCase)
    XLog.Error("[XLuckyTenant2Control] 作弊成功")
end

---结束游戏（放弃当前进行中的游戏）
---@param callback function|nil 回调函数
function XLuckyTenant2Control:RequestEndGame(callback)
    local stageId = self._Model:GetPlayingStageId()
    if not stageId or stageId <= 0 then
        if callback then
            callback(false)
        end
        return
    end

    -- 调用 Agency 的方法，传入当前游戏对象
    XMVCA.XLuckyTenant2:RequestEndGame(stageId, self._Game, function(success)
        if success then
            -- 清除本地游戏记录（调试用）
            self._Model:DebugClearStageRecord(stageId)
        end

        if callback then
            callback(success)
        end
    end)
end

---准备重新开始游戏（清空本地状态）
---@return number|nil stageId 当前正在游玩的关卡ID
function XLuckyTenant2Control:PrepareRestart()
    local stageId = self._Model:GetPlayingStageId()
    if not stageId or stageId <= 0 then
        return nil
    end

    -- 清除当前游戏记录（调试用）
    self._Model:DebugClearStageRecord(stageId)
    self._Model:ClearPlayingStage()

    return stageId
end

function XLuckyTenant2Control:_TestClearBag()
    local bag = self._Game:GetBag()
    local pieces = bag:GetPieces()
    local toDelete = {}
    for _, piece in pairs(pieces) do
        toDelete[#toDelete + 1] = piece:GetUid()
    end
    for i = 1, #toDelete do
        self:DeletePiece(toDelete[i])
    end
end

function XLuckyTenant2Control:GetQuestTotalAmount()
    if not self._Game then
        return 0
    end
    local game = self._Game
    local quests = game:GetAllQuest()
    return #quests
end

function XLuckyTenant2Control:GetQuestCompletedAmount()
    if not self._Game then
        return 0
    end
    local game = self._Game
    local quests = game:GetAllQuest()
    local completedAmount = 0
    for _, quest in ipairs(quests) do
        if quest.PerfectClear or quest.NormalClear then
            completedAmount = completedAmount + 1
        end
    end
    return completedAmount
end

---添加Toast到队列
---@param bondId number 羁绊ID
---@param oldLevel number 旧等级
---@param newLevel number 新等级
function XLuckyTenant2Control:AddToastToQueue(bondId, oldLevel, newLevel)
    -- 获取羁绊名称
    local bondConfig = self._Model:GetLuckyTenant2BondConfigById(bondId)
    if not bondConfig then
        return
    end

    local toastData = {
        BondId = bondId,
        BondName = bondConfig.BondName or "",
        OldLevel = oldLevel,
        NewLevel = newLevel,
    }

    table.insert(self._ToastQueue, toastData)

    -- 如果当前没有正在显示的Toast，立即显示
    if not self._IsShowingToast then
        self:ShowNextToast()
    end
end

---显示队列中的下一个Toast
function XLuckyTenant2Control:ShowNextToast()
    -- 如果队列为空，直接返回
    if #self._ToastQueue == 0 then
        self._IsShowingToast = false
        return
    end

    if not XLuaUiManager.IsUiShow("UiLuckyTenant2Game") then
        return
    end

    -- 取出队列中的第一个Toast
    local toastData = table.remove(self._ToastQueue, 1)

    -- 标记正在显示Toast
    self._IsShowingToast = true

    -- 打开Toast UI
    XLuaUiManager.Open("UiLuckyTenant2Toast", toastData)
end

---羁绊等级变化回调（由Game调用）
---@param bondId number 羁绊ID
---@param oldLevel number 旧等级
---@param newLevel number 新等级
function XLuckyTenant2Control:OnBondLevelChanged(bondId, oldLevel, newLevel)
    -- 只在等级真正变化时才显示Toast
    if oldLevel ~= newLevel then
        self:AddToastToQueue(bondId, oldLevel, newLevel)
    end
end

return XLuckyTenant2Control
