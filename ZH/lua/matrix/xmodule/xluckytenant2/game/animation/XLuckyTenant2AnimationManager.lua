local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local Skill = XLuckyTenant2Enum.Skill

---@class XLuckyTenant2AnimationManager
---动画管理器：统一管理所有动画的播放
local XLuckyTenant2AnimationManager = XClass(nil, "XLuckyTenant2AnimationManager")

-- 常量
local DEFAULT_TIME_SCALE = 1.0        -- 默认倍速
local FAST_TIME_SCALE = 2.0           -- 加速倍速
local DELTA_INTERVAL = 0.5            -- 棋子之间的间隔时间（秒）
local COUNTDOWN_INTERVAL = 0.15       -- 倒计时特效之间的间隔时间（秒）
local SCORE_ANIM_DURATION = 0.5       -- 飘字动画持续时间（秒）
local PIECE_ANIM_DURATION = 0.8       -- 棋子动画持续时间（秒）- AddPiece/UpdatePiece/DeletePiece
local DELETE_PIECE_FINISH_DELAY = 0.1 -- DeletePiece 在 HideGridPiece 后额外等待时间（秒）

function XLuckyTenant2AnimationManager:Ctor()
    -- 播放状态
    self._IsPlaying = false
    self._TimeScale = DEFAULT_TIME_SCALE
    self._ElapsedTime = 0

    -- 预计算数据
    self._TotalScoreThisRound = 0
    self._AnimationLevel = 0
    self._BaseScore = 0
    self._AnimationCommands = {}

    -- 动画等级阈值（在 Prepare 中预计算，飘字过程中动态比较）
    self._Threshold1 = 0
    self._Threshold2 = 0
    self._Threshold3 = 0

    -- 分数动画状态
    self._AccumulatedScore = 0
    self._ScoreAnimationsPlayed = 0
    self._TotalScoreAnimations = 0

    -- 循环动画
    self._ShakeLevel = 0
    self._LoopEffectsStarted = false

    -- UI 引用
    self._Ui = nil
    self._Control = nil

    -- 位置阻塞追踪（通用，key: "x,y"）
    self._PendingPositions = {}

    -- 定时器管理
    self._Timers = {}
end

---准备动画（预处理）
---@param animGroups table 动画组列表
---@param game XLuckyTenant2Game 游戏实例
---@param control XLuckyTenant2Control 控制器实例
---@param initialPieceValues table|nil 初始基础价值 {[uid] = {uid, x, y, value}}
function XLuckyTenant2AnimationManager:Prepare(animGroups, game, control, initialPieceValues)
    self._Control = control
    self._Ui = nil
    self._IsPlaying = false
    self._ElapsedTime = 0
    self._AnimationCommands = {}
    self._AccumulatedScore = 0
    self._ScoreAnimationsPlayed = 0
    self._PendingPositions = {}
    self._ShakeLevel = 0
    self._LoopEffectsStarted = false
    self:_CancelAllTimers()

    -- 1. 计算基准分数和本回合总得分
    self._BaseScore = game:GetTotalScore() - game:GetScoreThisRound()
    self._TotalScoreThisRound = game:GetScoreThisRound()
    self._AccumulatedScore = self._BaseScore

    -- 2. 预计算动画等级阈值（动画等级将在飘字过程中动态升级）
    self._AnimationLevel = 0
    self:_PrepareThresholds(game, control)

    -- 3. 收集所有技能动画指令
    self:_CollectAnimationCommands(animGroups)

    -- 4. 收集基础价值动画指令（跳过被技能消除或替换的棋子）
    self:_CollectBaseValueAnimations(game, initialPieceValues)

    -- 5. 收集最终剩余价值动画指令（结果棋盘value - 已飞的基础value）
    self:_CollectFinalValueAnimations(game, initialPieceValues)

    -- 6. 按棋子分组，计算 startTime（同一位置：先基础价值，再技能，最后剩余价值）
    self:_AssignStartTimes()

    -- 6. 合并同一棋子的连续 Duang
    self:_MergeDuangCommands()

    -- 统计分数动画数量
    self._TotalScoreAnimations = 0
    for _, cmd in ipairs(self._AnimationCommands) do
        if cmd.type == XLuckyTenant2Enum.AnimationType.GetScore then
            self._TotalScoreAnimations = self._TotalScoreAnimations + 1
        end
    end
end

---预计算动画等级阈值
---@param game XLuckyTenant2Game
---@param control XLuckyTenant2Control
function XLuckyTenant2AnimationManager:_PrepareThresholds(game, control)
    self._Threshold1 = 0
    self._Threshold2 = 0
    self._Threshold3 = 0

    -- 从 Control 的 UiData 获取目标分数和总回合数
    local targetScore = 0
    local totalRounds = 1
    if self._Control then
        local uiData = self._Control:GetUiData()
        if uiData then
            -- 从任务列表获取目标分数
            local currentRound = game:GetRound()
            local lastRound = game:GetRound() - 1

            -- 获取上一回合的目标分数 和 上一回合数
            local lastQuest = control:GetLastTargetQuest(lastRound)
            local lastQuestRound = lastQuest and lastQuest.Round or 0
            local lastQuestTargetScore = lastQuest and lastQuest.Score or 0

            -- 获取当前回合的目标分数 和 当前回合数
            local currentQuest = game:GetCurrentQuest(currentRound)
            local currentQuestRound = currentQuest and currentQuest.Round or 0
            local currentQuestTargetScore = currentQuest and currentQuest.Score or 0

            -- 计算目标分数和回合数
            targetScore = currentQuestTargetScore - lastQuestTargetScore
            totalRounds = currentQuestRound - lastQuestRound or 1
        end
    end

    if totalRounds <= 0 then
        totalRounds = 1
    end
    if targetScore <= 0 then
        return
    end

    -- 每回合平均目标分数
    local avgScorePerRound = targetScore / totalRounds

    -- 等级阈值：从配置读取（默认 90% / 110% / 130%）
    if self._CachedAnimLevel1 == nil then
        self._CachedAnimLevel1 = CS.XGame.ClientConfig:GetInt("LuckyTenant2AnimationLevel1") or 90
        self._CachedAnimLevel2 = CS.XGame.ClientConfig:GetInt("LuckyTenant2AnimationLevel2") or 110
        self._CachedAnimLevel3 = CS.XGame.ClientConfig:GetInt("LuckyTenant2AnimationLevel3") or 130
    end
    self._Threshold1 = avgScorePerRound * self._CachedAnimLevel1 / 100
    self._Threshold2 = avgScorePerRound * self._CachedAnimLevel2 / 100
    self._Threshold3 = avgScorePerRound * self._CachedAnimLevel3 / 100

    -- local scoreThisRound = game:GetScoreThisRound()
    -- XLog.Debug(string.format("[得分动画] 等级阈值 T1=%.1f T2=%.1f T3=%.1f 本回合分数=%.1f", self._Threshold1, self._Threshold2, self._Threshold3, scoreThisRound))
end

---根据当前分数计算动画等级
---@param scoreThisRound number 本回合已累计分数
---@return number 等级 0/1/2/3
function XLuckyTenant2AnimationManager:_CalcAnimationLevelByScore(scoreThisRound)
    if scoreThisRound <= 0 then
        return 0
    end
    if self._Threshold3 > 0 and scoreThisRound >= self._Threshold3 then
        return 3
    elseif self._Threshold2 > 0 and scoreThisRound >= self._Threshold2 then
        return 2
    elseif self._Threshold1 > 0 and scoreThisRound >= self._Threshold1 then
        return 1
    end
    return 0
end

---收集所有动画指令
---@param animGroups table 动画组列表
function XLuckyTenant2AnimationManager:_CollectAnimationCommands(animGroups)
    if not animGroups then
        return
    end

    for _, group in ipairs(animGroups) do
        local animDataList = group:GetAnimationData()
        local skillId = group:GetSkillId()
        local groupPieceUid = group:GetPieceUid()
        local isCountdown = group.IsCountdown and group:IsCountdown() or false

        if animDataList then
            for _, animData in ipairs(animDataList) do
                local cmd = {
                    type = animData.type,
                    startTime = 0,
                    duration = SCORE_ANIM_DURATION,
                    pieceUid = animData.pieceUid or groupPieceUid or 0,
                    x = animData.x or 0,
                    y = animData.y or 0,
                    value = animData.value or 0,
                    skillId = animData.skillId or skillId or 0,
                    fromPieceUid = animData.fromPieceUid or 0,
                    pieceId = animData.pieceId or 0,
                    -- 针对 AddPiece 操作，携带克隆的棋子数据，避免动画期间原棋子被删除导致显示异常
                    clonePieceData = animData.clonePieceData,
                    isPlayed = false,
                    isBaseValue = false,
                    isCountdown = isCountdown,
                }
                self._AnimationCommands[#self._AnimationCommands + 1] = cmd
            end

            -- todo 打印所有的animDataList
            local str = ""
            for _, animData in ipairs(animDataList) do
                str = str .. "type: " .. tostring(animData.type) .. " skillId: " .. tostring(animData.skillId) .. " pieceUid: " .. tostring(animData.pieceUid) .. " x: " .. tostring(animData.x) .. " y: " .. tostring(animData.y) .. "\n"
            end
            XLog.Debug("animDataList: " .. str)
        end
    end
end

---收集基础价值动画指令（跳过被技能消除或替换的棋子）
---@param game XLuckyTenant2Game 游戏实例（技能执行后的最终状态）
---@param initialPieceValues table|nil 初始基础价值 {[uid] = {uid, x, y, value}}
function XLuckyTenant2AnimationManager:_CollectBaseValueAnimations(game, initialPieceValues)
    if not initialPieceValues or not game then
        return
    end

    local chessBoard = game:GetChessBoard()

    for uid, data in pairs(initialPieceValues) do
        if data.value and data.value > 0 and data.x and data.y then
            -- 检查最终棋盘上该位置是否仍是同一个棋子
            local skip = false
            if chessBoard then
                local boardPiece = chessBoard:GetPieceByPosition(data.x, data.y)
                if not boardPiece or boardPiece:GetUid() ~= uid then
                    skip = true
                end
            end

            if not skip then
                local cmd = {
                    type = XLuckyTenant2Enum.AnimationType.GetScore,
                    startTime = 0,
                    duration = SCORE_ANIM_DURATION,
                    pieceUid = uid,
                    x = data.x,
                    y = data.y,
                    value = data.value,
                    skillId = 0,
                    fromPieceUid = 0,
                    pieceId = 0,
                    isPlayed = false,
                    isBaseValue = true, -- 标记为基础价值动画
                }
                self._AnimationCommands[#self._AnimationCommands + 1] = cmd
            end
        end
    end
end

---收集最终剩余价值动画指令（结果棋盘value - 已飞的基础value）
---@param game XLuckyTenant2Game 游戏实例（技能执行后的最终状态）
---@param initialPieceValues table|nil 初始基础价值 {[uid] = {uid, x, y, value}}
function XLuckyTenant2AnimationManager:_CollectFinalValueAnimations(game, initialPieceValues)
    if not game then
        return
    end

    local chessBoard = game:GetChessBoard()
    if not chessBoard then
        return
    end

    -- 构建已飞基础价值的查找表（按uid）
    local flewBaseValues = {}
    if initialPieceValues then
        for uid, data in pairs(initialPieceValues) do
            flewBaseValues[uid] = data.value or 0
        end
    end

    local pieces = chessBoard:GetAllPieces()
    for _, piece in ipairs(pieces) do
        local uid = piece:GetUid()
        local x, y = piece:GetPosition()
        local currentValue = piece:GetTotalValue() or 0
        local flewValue = flewBaseValues[uid] or 0
        local remainingValue = currentValue - flewValue
        if remainingValue > 0 and x and y then
            local cmd = {
                type = XLuckyTenant2Enum.AnimationType.GetScore,
                startTime = 0,
                duration = SCORE_ANIM_DURATION,
                pieceUid = uid,
                x = x,
                y = y,
                value = remainingValue,
                skillId = 0,
                fromPieceUid = 0,
                pieceId = 0,
                isPlayed = false,
                isBaseValue = false,
                isFinalValue = true, -- 标记为最终剩余价值动画
            }
            self._AnimationCommands[#self._AnimationCommands + 1] = cmd
        end
    end
end

---按棋子分组，计算 startTime（倒计时优先，同一位置：先基础价值，再技能，最后剩余价值）
function XLuckyTenant2AnimationManager:_AssignStartTimes()
    -- 倒计时指令按位置排序，错开播放
    local hasCountdown = false
    local countdownCmds = {}
    local groups = {}
    for _, cmd in ipairs(self._AnimationCommands) do
        if cmd.isCountdown then
            countdownCmds[#countdownCmds + 1] = cmd
            hasCountdown = true
        else
            local key = cmd.x .. "," .. cmd.y
            if not groups[key] then
                groups[key] = { skill = {}, baseValue = {}, finalValue = {} }
            end
            if cmd.isBaseValue then
                groups[key].baseValue[#groups[key].baseValue + 1] = cmd
            elseif cmd.isFinalValue then
                groups[key].finalValue[#groups[key].finalValue + 1] = cmd
            else
                groups[key].skill[#groups[key].skill + 1] = cmd
            end
        end
    end

    -- 倒计时指令按位置从左上到右下排序，错开播放，记录每个位置的倒计时结束时间
    local countdownEndByPos = {}
    if hasCountdown then
        table.sort(countdownCmds, function(a, b)
            if a.y ~= b.y then
                return a.y < b.y
            end
            return a.x < b.x
        end)
        for i, cmd in ipairs(countdownCmds) do
            cmd.startTime = (i - 1) * COUNTDOWN_INTERVAL
            local key = cmd.x .. "," .. cmd.y
            countdownEndByPos[key] = cmd.startTime + DELTA_INTERVAL
        end
    end

    -- 收集位置 key 并按从左上到右下排序（先 y 小后 x 小）
    local sortedKeys = {}
    for key in pairs(groups) do
        sortedKeys[#sortedKeys + 1] = key
    end
    table.sort(sortedKeys, function(a, b)
        local ax, ay = a:match("(%d+),(%d+)")
        local bx, by = b:match("(%d+),(%d+)")
        ax, ay, bx, by = tonumber(ax), tonumber(ay), tonumber(bx), tonumber(by)
        if ay ~= by then
            return ay < by
        end
        return ax < bx
    end)

    local positionCount = #sortedKeys

    -- 按从左上到右下的顺序为每个位置分配 startTime
    -- 每格内顺序：基础价值 → 技能 → 最终剩余价值，按该格实际拥有的阶段错开
    local nonCountdownIndex = 0
    for _, key in ipairs(sortedKeys) do
        local group = groups[key]
        local posOffset = countdownEndByPos[key]
        local currentTime
        if posOffset then
            currentTime = posOffset
        else
            currentTime = nonCountdownIndex * DELTA_INTERVAL
            nonCountdownIndex = nonCountdownIndex + 1
        end
        -- 阶段1：基础价值
        for _, cmd in ipairs(group.baseValue) do
            cmd.startTime = currentTime
        end
        if #group.baseValue > 0 then
            currentTime = currentTime + DELTA_INTERVAL
        end
        -- 阶段2：技能
        for _, cmd in ipairs(group.skill) do
            cmd.startTime = currentTime
        end
        if #group.skill > 0 then
            currentTime = currentTime + DELTA_INTERVAL
        end
        -- 阶段3：最终剩余价值（始终在该格最后）
        for _, cmd in ipairs(group.finalValue) do
            cmd.startTime = currentTime
        end
    end
end

---合并同一棋子的连续 Duang 指令
function XLuckyTenant2AnimationManager:_MergeDuangCommands()
    local duangByPos = {}
    local toRemove = {}

    for i, cmd in ipairs(self._AnimationCommands) do
        if cmd.type == XLuckyTenant2Enum.AnimationType.Duang then
            local key = cmd.x .. "," .. cmd.y
            if duangByPos[key] then
                toRemove[i] = true
            else
                duangByPos[key] = true
            end
        end
    end

    if next(toRemove) then
        local newCommands = {}
        for i, cmd in ipairs(self._AnimationCommands) do
            if not toRemove[i] then
                newCommands[#newCommands + 1] = cmd
            end
        end
        self._AnimationCommands = newCommands
    end
end

---开始播放
function XLuckyTenant2AnimationManager:Start()
    self._IsPlaying = true
    self._ElapsedTime = 0
    self._TimeScale = DEFAULT_TIME_SCALE
    CS.UnityEngine.Time.timeScale = DEFAULT_TIME_SCALE
end

---每帧更新
---@param deltaTime number 时间增量（秒）
---@param ui XUiLuckyTenant2Game UI实例
---@return boolean 是否完成
function XLuckyTenant2AnimationManager:Update(deltaTime, ui)
    if not self._IsPlaying then
        return true
    end

    self._Ui = ui

    -- deltaTime 已被 Unity Time.timeScale 缩放，无需再乘倍速
    self._ElapsedTime = self._ElapsedTime + deltaTime

    -- 启动循环动画（只启动一次）
    if not self._LoopEffectsStarted then
        self:_StartLoopEffects(ui)
        self._LoopEffectsStarted = true
        -- 每回合动画开始时清空格子特效播放记录，确保沙漏等一次性特效每回合都能播放
        if ui.ClearGridEffectPlayedInGroup then
            ui:ClearGridEffectPlayedInGroup()
        end
    end

    -- 遍历所有指令，检查是否到达 startTime
    for _, cmd in ipairs(self._AnimationCommands) do
        if not cmd.isPlayed and self._ElapsedTime >= cmd.startTime then
            local posKey = cmd.x .. "," .. cmd.y
            if self._PendingPositions[posKey] then
                -- 被阻塞：推迟 startTime，避免阻塞解除后同位置指令同帧全部播放
                cmd.startTime = self._ElapsedTime + COUNTDOWN_INTERVAL
            else
                self:_PlayCommand(cmd, ui)
                cmd.isPlayed = true
            end
        end
    end

    -- 检查是否全部完成
    return self:_CheckAllFinished()
end

---播放单个动画指令
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_PlayCommand(cmd, ui)
    if not ui then
        return
    end

    local animType = cmd.type
    if animType == XLuckyTenant2Enum.AnimationType.GetScore then
        self:_PlayScoreCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.AddPiece then
        self:_PlayAddPieceCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.DeletePiece then
        self:_PlayDeletePieceCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.UpdatePiece then
        self:_PlayUpdatePieceCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.ActivateSkillEnable then
        self:_PlayActivateSkillCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.AffectedBySkillEnable then
        self:_PlayAffectedBySkillCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.Duang then
        self:_PlayDuangCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.Countdown then
        self:_PlayCountdownCommand(cmd, ui)
    elseif animType == XLuckyTenant2Enum.AnimationType.InfectionSourceEnable then
        self:_PlayInfectionSourceCommand(cmd, ui)
    end

    -- 通用位置阻塞：播放函数可设置 cmd.waitDuration 来阻塞该位置
    if cmd.waitDuration and cmd.waitDuration > 0 then
        self:_BlockPosition(cmd.x, cmd.y, cmd.waitDuration)
    end
end

---播放分数动画（飘字 + 抖动同时）
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_PlayScoreCommand(cmd, ui)
    local x, y, value = cmd.x, cmd.y, cmd.value
    if value <= 0 then
        return
    end

    -- 同时播放抖动
    local grid = ui:GetGridByXY(x, y)
    if grid and grid.PlayShakeAnimation then
        grid:PlayShakeAnimation()
    end

    -- 播放飘字
    local duration = cmd.duration
    ui:PlayAnimationGetScore(x, y, value, duration, function()
        -- 更新累计分数
        self._AccumulatedScore = self._AccumulatedScore + value
        self._ScoreAnimationsPlayed = self._ScoreAnimationsPlayed + 1

        -- 更新分数显示
        if ui.TxtNumScore then
            ui.TxtNumScore.text = tostring(math.floor(self._AccumulatedScore))
        end

        -- 根据当前累计分数动态计算动画等级
        local currentScoreThisRound = self._AccumulatedScore - self._BaseScore
        local newLevel = self:_CalcAnimationLevelByScore(currentScoreThisRound)

        -- 等级提升时升级循环动画
        if newLevel > self._AnimationLevel then
            -- 等级2/3时播放 TxtTargetScoreEnable 动画
            if newLevel >= 1 then
                ui:PlayTxtTargetScoreEnableAnimation()
            end
            self:_UpgradeLoopEffects(newLevel, ui)
            self._AnimationLevel = newLevel
        end

        -- 每次飘字到达进度条时播放小特效
        ui:PlayEffectLevel0()
    end)
end

---播放添加棋子动画
---中点刷新机制：动画播放到一半时刷新显示新棋子
---即使此刷新失败，Control:FinishAnimation() 的保底刷新也会修正最终显示
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game
function XLuckyTenant2AnimationManager:_PlayAddPieceCommand(cmd, ui)
    local x, y = cmd.x, cmd.y

    -- 优先使用克隆出来的棋子数据刷新格子显示，避免原棋子在动画开始前被删除导致看不到新棋子
    local clonePiece = cmd.clonePieceData
    if clonePiece and self._Control and ui and ui.GetGridByXY then
        local grid = ui:GetGridByXY(x, y)
        if grid and grid.Update then
            local data = {}
            data.X = x
            data.Y = y
            data.IsValid = true

            -- 尽量还原与 Chessboard 单元一致的显示结构
            local game = self._Control._Game
            if game and game.GetChessBoard then
                local chessboard = game:GetChessBoard()
                if chessboard and chessboard.GetIndex then
                    data.Position = chessboard:GetIndex(x, y)
                end
            end

            -- 复用 Control 的填充逻辑，保持 UI 显示一致
            self._Control:FillPieceCoreData(data, clonePiece)
            local round = game and game:GetRound() or 0
            self._Control:FillPieceStatesData(data, clonePiece, round)

            grid:Update(data)
        end
    elseif ui.RefreshGridFromGame then
        -- 兼容老逻辑：无克隆数据时，从当前游戏状态刷新
        ui:RefreshGridFromGame(x, y)
    end

    ui:PlayAnimationAddPiece(cmd.pieceId, x, y)
end

---播放删除棋子动画
---中点刷新机制：动画播放到一半时隐藏棋子
---即使此刷新失败，Control:FinishAnimation() 的保底刷新也会修正最终显示
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game
function XLuckyTenant2AnimationManager:_PlayDeletePieceCommand(cmd, ui)
    if ui.PlayAnimationDeletePiece then
        local duration = PIECE_ANIM_DURATION / self._TimeScale
        local halfDuration = duration / 2
        -- 设置等待时长：HideGridPiece 时间 + 额外缓冲
        cmd.waitDuration = halfDuration + DELETE_PIECE_FINISH_DELAY
        -- 先播放动画（此时显示旧棋子）
        ui:PlayAnimationDeletePiece(cmd.pieceUid, cmd.x, cmd.y, cmd.fromPieceUid, cmd.pieceId, cmd.skillId, false)
        -- 中点刷新：动画播放到一半时隐藏棋子
        self:_AddTimer(XScheduleManager.ScheduleOnce(function()
            if ui.HideGridPiece then
                ui:HideGridPiece(cmd.x, cmd.y)
            end
        end, math.floor(halfDuration * 1000)))
    end
end

---播放更新棋子动画
---中点刷新机制：动画播放到一半时刷新数值
---即使此刷新失败，Control:FinishAnimation() 的保底刷新也会修正最终显示
function XLuckyTenant2AnimationManager:_PlayUpdatePieceCommand(cmd, ui)
    local duration = PIECE_ANIM_DURATION / self._TimeScale
    local halfDuration = duration / 2
    -- 中点刷新：动画播放到一半时刷新数值
    self:_AddTimer(XScheduleManager.ScheduleOnce(function()
        if ui.RefreshGridFromGame then
            ui:RefreshGridFromGame(cmd.x, cmd.y)
        end
    end, math.floor(halfDuration * 1000)))
end

---播放主动技能动画
function XLuckyTenant2AnimationManager:_PlayActivateSkillCommand(cmd, ui)
    if ui.PlayAnimationActivateSkillEnable then
        ui:PlayAnimationActivateSkillEnable(cmd.pieceUid, cmd.x, cmd.y, cmd.skillId)
    end
end

---播放受技能影响动画
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_PlayAffectedBySkillCommand(cmd, ui)
    if ui.PlayAnimationAffectedBySkillEnable then
        ui:PlayAnimationAffectedBySkillEnable(cmd.pieceUid, cmd.x, cmd.y, cmd.skillId, cmd.fromPieceUid)
    end
    -- Type305（鞭尸增强）会播放两次消除特效，需要等待播完
    if self._Control and cmd.skillId then
        local skillType = self._Control:GetSkillTypeBySkillId(cmd.skillId)
        if skillType == Skill.Type305 then
            cmd.waitDuration = PIECE_ANIM_DURATION / self._TimeScale
        end
    end
end

---播放倒计时特效（沙漏）
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_PlayCountdownCommand(cmd, ui)
    local grid = ui:GetGridByXY(cmd.x, cmd.y)
    if grid and grid.PlayEffectCountdownDecrease then
        grid:PlayEffectCountdownDecrease(cmd.skillId)
    end
end

---播放感染来源棋子特效（用于 Type210 结算且拥有 Type207 技能时）
---@param cmd table 动画指令
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_PlayInfectionSourceCommand(cmd, ui)
    if not ui or not ui.GetGridByPieceUidOrXY then
        return
    end
    local grid = ui:GetGridByPieceUidOrXY(cmd.pieceUid, cmd.x, cmd.y)
    if grid and grid.PlayEffectInfectionSkill then
        grid:PlayEffectInfectionSkill(cmd.skillId)
    end
end

---播放 Duang 特效
function XLuckyTenant2AnimationManager:_PlayDuangCommand(cmd, ui)
    local grid = ui:GetGridByXY(cmd.x, cmd.y)
    if grid and grid.PlayEffectDuang then
        grid:PlayEffectDuang()
    end
end

---启动循环动画（初始为空，随分数累加在飘字回调中动态升级）
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_StartLoopEffects(ui)
    self._ShakeLevel = 0
end

---升级循环动画（当动画等级提升时调用）
---@param newLevel number 新的动画等级
---@param ui XUiLuckyTenant2Game UI实例
function XLuckyTenant2AnimationManager:_UpgradeLoopEffects(newLevel, ui)
    -- 停止当前循环动画
    if self._ShakeLevel > 0 and ui.StopLoopAnimation then
        ui:StopLoopAnimation()
    end

    -- 启动新等级的循环动画
    if newLevel >= 3 then
        if ui.StartLoopAnimation then
            ui:StartLoopAnimation("Shake3")
        end
        if ui.FxUiLuckyTenant202Loop02 then
            ui.FxUiLuckyTenant202Loop02.gameObject:SetActiveEx(true)
        end
    elseif newLevel >= 2 then
        if ui.StartLoopAnimation then
            ui:StartLoopAnimation("Shake2")
        end
        -- 1级动画不播放
        -- elseif newLevel >= 1 then
        --     if ui.StartLoopAnimation then
        --         ui:StartLoopAnimation("Shake1")
        --     end
    end

    self._ShakeLevel = newLevel
end

---检查是否全部完成
---@return boolean
function XLuckyTenant2AnimationManager:_CheckAllFinished()
    -- 检查所有指令是否都已播放
    for _, cmd in ipairs(self._AnimationCommands) do
        if not cmd.isPlayed then
            return false
        end
    end

    -- 检查分数动画是否都已完成回调
    if self._ScoreAnimationsPlayed < self._TotalScoreAnimations then
        return false
    end

    return true
end

---结束播放，停止循环动画
---注意：此方法只负责停止动画管理器自身的状态和循环特效
---棋盘数据的保底刷新由 Control:FinishAnimation() 负责（调用 UpdateUiData(true)）
function XLuckyTenant2AnimationManager:Finish()
    self._IsPlaying = false
    self:_CancelAllTimers()

    -- 停止循环动画（Shake1/2/3）和循环特效
    local ui = self._Ui
    if ui then
        if ui.StopLoopAnimation then
            ui:StopLoopAnimation()
        end
        if ui.FxUiLuckyTenant202Loop02 then
            ui.FxUiLuckyTenant202Loop02.gameObject:SetActiveEx(false)
        end
    end

    -- 重置状态
    self._TimeScale = 1.0
    CS.UnityEngine.Time.timeScale = 1.0
    self._ElapsedTime = 0
    self._ShakeLevel = 0
    self._LoopEffectsStarted = false
    self._PendingPositions = {}
    self._AnimationCommands = {}
    self._TotalScoreAnimations = 0
    self._ScoreAnimationsPlayed = 0

    -- 释放外部引用，避免持有已销毁的 UI/Control
    self._Ui = nil
    self._Control = nil
end

---销毁动画管理器运行时资源（UI 关闭/Control 释放时调用）
function XLuckyTenant2AnimationManager:Dispose()
    self:Finish()
end

---阻塞指定位置，duration 秒后自动解除
---播放函数通过设置 cmd.waitDuration 来触发（由 _PlayCommand 统一调用）
---@param x number X坐标
---@param y number Y坐标
---@param duration number 阻塞时长（秒）
function XLuckyTenant2AnimationManager:_BlockPosition(x, y, duration)
    local posKey = x .. "," .. y
    self._PendingPositions[posKey] = (self._PendingPositions[posKey] or 0) + 1
    self:_AddTimer(XScheduleManager.ScheduleOnce(function()
        self._PendingPositions[posKey] = self._PendingPositions[posKey] - 1
        if self._PendingPositions[posKey] <= 0 then
            self._PendingPositions[posKey] = nil
        end
    end, math.floor(duration * 1000)))
end

---记录定时器ID，便于统一取消
---@param timerId number 定时器ID
function XLuckyTenant2AnimationManager:_AddTimer(timerId)
    if timerId then
        self._Timers[#self._Timers + 1] = timerId
    end
end

---取消所有已记录的定时器
function XLuckyTenant2AnimationManager:_CancelAllTimers()
    for _, timerId in ipairs(self._Timers) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._Timers = {}
end

---设置倍速
---@param scale number 倍速值
function XLuckyTenant2AnimationManager:SetTimeScale(scale)
    self._TimeScale = scale or DEFAULT_TIME_SCALE
end

---切换到加速模式
function XLuckyTenant2AnimationManager:SetFastMode()
    self._TimeScale = FAST_TIME_SCALE
    CS.UnityEngine.Time.timeScale = FAST_TIME_SCALE
end

---切换到正常模式
function XLuckyTenant2AnimationManager:SetNormalMode()
    self._TimeScale = DEFAULT_TIME_SCALE
    CS.UnityEngine.Time.timeScale = DEFAULT_TIME_SCALE
end

---是否正在播放
---@return boolean
function XLuckyTenant2AnimationManager:IsPlaying()
    return self._IsPlaying
end

---是否已完成
---@return boolean
function XLuckyTenant2AnimationManager:IsFinished()
    return not self._IsPlaying or self:_CheckAllFinished()
end

---获取动画等级
---@return number
function XLuckyTenant2AnimationManager:GetAnimationLevel()
    return self._AnimationLevel
end

return XLuckyTenant2AnimationManager
