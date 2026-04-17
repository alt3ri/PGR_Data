---@class XLineArithmetic3Control : XControl
---@field private _Model XLineArithmetic3Model
---@field private _Game XLineArithmetic3Game
---@field private _UiData table UI数据
---@field private _StageId number 当前关卡ID
local XLineArithmetic3Control = XClass(XControl, "XLineArithmetic3Control")

function XLineArithmetic3Control:OnInit()
    -- 创建游戏逻辑对象
    local XLineArithmetic3Game = require("XModule/XLineArithmetic3/XLineArithmetic3Game")
    self._Game = XLineArithmetic3Game.New()

    -- 上车移动时间（秒）
    self._Game.BoardMoveDuration = self._Model:GetClientConfigNumberByKey('BoardMoveDuration') or 0.2
    -- 上车移动延后多久播放跳跃动画(秒）
    self._Game.BoardJumpAnimDelay = self._Model:GetClientConfigNumberByKey('BoardJumpAnimDelay') or 0.1
    -- 下车移动时间（秒）
    self._Game.DisembarkDuration = self._Model:GetClientConfigNumberByKey('DisembarkDuration') or 0.2
    -- 下车移动延后多久播放跳跃动画(秒）
    self._Game.DisembarkJumpAnimDelay = self._Model:GetClientConfigNumberByKey('DisembarkJumpAnimDelay') or 0.1
    -- 上车冲突移动多久播放跳跃动画(秒）
    self._Game.ConflictJumpAnimDelay = self._Model:GetClientConfigNumberByKey('ConflictJumpAnimDelay') or 0.1
    -- 上车冲突乘客移动格距比例
    self._Game.ConflictMoveRatio = self._Model:GetClientConfigNumberByKey('ConflictMoveRatio') or 0.25
    -- 上车冲突乘客移动单段时长(秒）
    self._Game.ConflictMoveDuration = self._Model:GetClientConfigNumberByKey('BoardMoveDuration') or 0.15
    -- 上车后播放特效，等待多长时间结束当前步骤（秒）
    self._Game.BoardWaitFxTime = self._Model:GetClientConfigNumberByKey('BoardWaitFxTime') or 0.2

    -- 初始化UI数据
    self._UiData = {
        StarDescData = {},            -- 星星目标数据
        GridDescData = {},            -- 事件描述数据
        Settle = {},                  -- 结算数据
        Time = "",                    -- 活动时间
        Chapter = {},                 -- 章节列表
        RewardOnMainUi = {},          -- 主界面奖励列表
        Stage = {},                   -- 关卡列表
        CurrentChapterName = "",      -- 当前章节名称
        CurrentChapterStar = "",      -- 当前章节星数
        ChapterBg = "",               -- 章节背景
        UnlockChapters = {},          -- 已解锁章节索引列表
        IsDefaultSelectDirty = false, -- 是否需要默认选中关卡
        DefaultSelectStageIndex = 0   -- 默认选中的关卡索引
    }

    -- 初始化关卡ID
    self._StageId = 0

    -- 当前章节ID
    self._ChapterId = 0

    -- 当前关卡的开始方式：false=普通开始，true=从结算界面的“再来一次”（重新挑战）开始
    self._IsRestartFromAgain = false

    -- 地图尺寸
    self._MapSize = {
        X = 0,
        Y = 0
    }
end

function XLineArithmetic3Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XLineArithmetic3Control:RemoveAgencyEvent()

end

--- 获取起点格的完整信息
---@param stageId number 关卡ID
---@return table|nil 起点信息 {x, y, gridName, cellId}
function XLineArithmetic3Control:GetStartInfo(stageId)
    return self._Model:GetStartInfo(stageId)
end

--- 根据关卡ID获取地图数据
---@param stageId number 关卡ID
---@return table 地图数据，key为Row
function XLineArithmetic3Control:GetMapByStageId(stageId)
    return self._Model:GetMapByStageId(stageId)
end

--- 获取关卡配置
---@param stageId number 关卡ID
---@return XTableLineArithmeticStage|nil
function XLineArithmetic3Control:GetStageConfig(stageId)
    return self._Model:GetStageConfig(stageId)
end

--- 获取格子配置
---@param cellId number 格子ID
---@return XTableLineArithmeticCell|nil
function XLineArithmetic3Control:GetCellConfig(cellId)
    return self._Model:GetCellConfig(cellId)
end

function XLineArithmetic3Control:GetCellConfigByCharacterId(characterId)
    return self._Model:GetCellConfigByCharacterId(characterId)
end

--- 获取车辆配置
---@param carId number 车辆ID
---@return XTableLineArithmeticCar|nil
function XLineArithmetic3Control:GetCarConfig(carId)
    return self._Model:GetCarConfig(carId)
end

--- 获取当前关卡对应的帮助配置列表（按 mapId 查询，配置含 X、Y 表示指引路线格子坐标）
---@return table[]
function XLineArithmetic3Control:GetHelpConfigsForCurrentStage()
    if not self._StageId or self._StageId == 0 then
        return {}
    end
    local stageConfig = self._Model:GetStageConfig(self._StageId)
    if not stageConfig or not stageConfig.MapId then
        return {}
    end
    return self._Model:GetHelpConfigsByMapId(stageConfig.MapId)
end

--- 初始化游戏
---@param stageId number 关卡ID
---@param isRestart boolean|nil 是否为重新挑战（true 时不再发送 Start 请求）
function XLineArithmetic3Control:InitGame(stageId, isRestart)
    XLog.Debug("[XLineArithmetic3Control] 初始化游戏，stageId:", stageId)

    -- 非重新挑战时，请求服务端开始游戏
    if not isRestart then
        XMVCA.XLineArithmetic3:RequestStart(stageId)
    end

    -- 保存当前关卡ID
    self._StageId = stageId
    
    self._Model:SetCurrentGameStageId(self._StageId)

    -- 获取关卡配置
    local stageConfig = self._Model:GetStageConfig(stageId)
    if not stageConfig then
        XLog.Error("[XLineArithmetic3Control] 关卡配置为空，stageId:", stageId)
        return
    end

    -- 从Model获取地图数据
    local mapData = self._Model:GetMapByStageId(stageId)
    if not mapData or not next(mapData) then
        XLog.Error("[XLineArithmetic3Control] 地图数据为空，stageId:", stageId)
        return
    end

    -- 获取车辆配置（carId = mapId）
    local carConfig = self._Model:GetCarConfig(stageConfig.MapId)

    -- 计算地图尺寸
    self._MapSize.X = #mapData[1].Column
    self._MapSize.Y = #mapData

    -- 转换为Game期望的格式
    local mapConfig = {
        Row = 7, -- 默认行数
        Column = {}
    }

    -- 遍历地图数据，提取Column数组
    for row, rowConfig in pairs(mapData) do
        if rowConfig.Column then
            mapConfig.Column[row] = rowConfig.Column
            -- 更新行数（取最大行号）
            if row > mapConfig.Row then
                mapConfig.Row = row
            end
        end
    end

    -- 调用Game的ImportConfig初始化游戏逻辑
    self._Game:Clear()
    self._Game:ImportConfig(self._Model, mapConfig, carConfig)

    XLog.Debug("[XLineArithmetic3Control] 游戏初始化完成")
end

--- 检查车头是否到达终点格（胜利条件）
---@return boolean
function XLineArithmetic3Control:IsHeadAtEnd()
    return self._Game:IsHeadAtEnd()
end

--- 获取Game对象
---@return XLineArithmetic3Game
function XLineArithmetic3Control:GetGame()
    return self._Game
end

--- 获取Game层的地图数据（包含运行时状态）
---@return table
function XLineArithmetic3Control:GetGameMap()
    return self._Game:GetMap()
end

--- 获取UI数据
---@return table
function XLineArithmetic3Control:GetUiData()
    return self._UiData
end

--- 获取当前游戏已完成的星数（根据StarCondition实时判断）
---@return number 已完成的星数
function XLineArithmetic3Control:GetCurrentStar()
    if not self._StageId or self._StageId == 0 then
        return 0
    end
    local stageConfig = self._Model:GetStageConfig(self._StageId)
    if not stageConfig or not stageConfig.StarCondition then
        return 0
    end
    local star = 0
    for i = 1, #stageConfig.StarCondition do
        local conditionId = stageConfig.StarCondition[i]
        if conditionId then
            local condition = XConditionManager.GetConditionTemplate(conditionId)
            if condition and self._Game:IsMatchCondition(condition) then
                star = star + 1
            end
        end
    end
    return star
end

--- 更新星星目标数据
---@param step number|nil 指令步数（用于按动画进度预览星星状态）
function XLineArithmetic3Control:UpdateStarTarget(step)
    local starDescData = {}
    self._UiData.StarDescData = starDescData

    if not self._StageId or self._StageId == 0 then
        return
    end

    local stageConfig = self._Model:GetStageConfig(self._StageId)
    if not stageConfig then
        return
    end

    -- 遍历星星条件（最多3个）
    for i = 1, 3 do
        local conditionId = stageConfig.StarCondition and stageConfig.StarCondition[i]
        local desc = stageConfig.StarDesc and stageConfig.StarDesc[i]

        if conditionId and desc then
            local condition = XConditionManager.GetConditionTemplate(conditionId)
            local isFinish = false

            if condition then
                -- 判断条件是否满足
                if step then
                    isFinish = self._Game:IsMatchConditionAtStep(condition, step)
                else
                    isFinish = self._Game:IsMatchCondition(condition)
                end
            end

            ---@class XLineArithmetic3ControlDataStarDesc
            local starDesc = {
                Index = i,
                Desc = desc,
                IsFinish = isFinish
            }
            table.insert(starDescData, starDesc)
        end
    end
end

--- 更新事件描述数据
function XLineArithmetic3Control:UpdateGridDesc()
    local gridDescData = {}
    self._UiData.GridDescData = gridDescData

    if not self._StageId or self._StageId == 0 then
        return
    end

    local stageConfig = self._Model:GetStageConfig(self._StageId)
    if not stageConfig then
        return
    end

    -- 遍历事件描述（最多3个）
    for i = 1, 3 do
        local icon = stageConfig.MeshIcon and stageConfig.MeshIcon[i]
        local desc = stageConfig.MeshDesc and stageConfig.MeshDesc[i]

        if icon and desc then
            ---@class XLineArithmetic3ControlDataGridDesc
            local gridDesc = {
                Icon = icon,
                Desc = desc
            }
            table.insert(gridDescData, gridDesc)
        end
    end
end

--- 更新结算描述数据
function XLineArithmetic3Control:UpdateSettleDesc()
    if not self._StageId or self._StageId == 0 then
        self._UiData.Settle = {
            RoleIcon = "",
            Tip = ""
        }
        return
    end

    local stageConfig = self._Model:GetStageConfig(self._StageId)
    if not stageConfig then
        self._UiData.Settle = {
            RoleIcon = "",
            Tip = ""
        }
        return
    end

    -- 随机选择一个结算描述
    local settleDescList = stageConfig.SettleDesc or {}
    local tip = ""
    if #settleDescList > 0 then
        local randomIndex = math.random(1, #settleDescList)
        tip = settleDescList[randomIndex] or ""
    end

    self._UiData.Settle = {
        RoleIcon = stageConfig.SettleRoleIcon or "",
        Tip = tip
    }
end

function XLineArithmetic3Control:GetMapSize()
    return self._MapSize
end

--- 获取任务组ID列表
---@return number[]
function XLineArithmetic3Control:GetTaskIdList()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return {}
    end
    return activityConfig.TaskIds
end

--- 获取活动结束时间
---@return number
function XLineArithmetic3Control:GetActivityEndTime()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return 0
    end
    local timeId = activityConfig.TimeId
    if not timeId then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(timeId) or 0
end

--- 更新活动时间
---@return boolean 是否在活动时间内
function XLineArithmetic3Control:UpdateTime()
    if self._Model:IsExpire() then
        self._UiData.Time = ""
        return false
    end

    local endTime = self:GetActivityEndTime()
    if endTime == 0 then
        self._UiData.Time = ""
        return false
    end

    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = endTime - nowTime
    if leftTime <= 0 then
        self._UiData.Time = ""
        return false
    end

    self._UiData.Time = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    return true
end

--- 更新章节列表
function XLineArithmetic3Control:UpdateChapter()
    local chapters = {}
    self._UiData.Chapter = chapters
    self._UiData.UnlockChapters = {}

    -- 获取所有章节配置
    local chapterConfigs = self._Model:GetAllChapterConfigs()
    if not chapterConfigs then
        return
    end

    local activityId = self._Model:GetActivityId()
    if activityId == 0 then
        return chapters
    end

    local index = 1
    for _, chapterConfig in ipairs(chapterConfigs) do
        if chapterConfig.ActivityId == activityId then
            local isOpen, lockDesc = self._Model:IsChapterUnlock(chapterConfig.Id)

            -- 计算章节星级进度
            local totalStar, earnedStar = self:_CalcChapterStarProgress(chapterConfig.Id)

            ---@class XLineArithmetic3ControlDataChapter
            local chapterData = {
                Id = chapterConfig.Id,
                Name = chapterConfig.Name or "",
                IsOpen = isOpen,
                Icon = chapterConfig.Icon or "",
                ChapterIndex = index,
                TxtStar = string.format("%d/%d", earnedStar, totalStar),
                IsNew = self._Model:IsNewChapter(chapterConfig.Id),
                TxtLock = lockDesc,
            }
            table.insert(chapters, chapterData)

            if isOpen then
                table.insert(self._UiData.UnlockChapters, chapterData.ChapterIndex or 0)
            end
            index = index + 1
        end
    end
end

--- 计算章节星级进度
---@param chapterId number 章节ID
---@return number, number 总星数, 已获得星数
function XLineArithmetic3Control:_CalcChapterStarProgress(chapterId)
    local stages = self._Model:GetStagesByChapterId(chapterId)
    local totalStar = 0
    local earnedStar = 0

    for _, stageConfig in ipairs(stages) do
        -- 最大星数由配置的 StarCondition 数量决定
        if not XTool.IsTableEmpty(stageConfig.StarCondition) then
            totalStar = totalStar + #stageConfig.StarCondition
        end
        earnedStar = earnedStar + self._Model:GetStageStar(stageConfig.Id)
    end

    return totalStar, earnedStar
end

--- 更新主界面奖励显示
function XLineArithmetic3Control:UpdateReward()
    local rewards = {}
    self._UiData.RewardOnMainUi = rewards

    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig or not XTool.IsNumberValidEx(activityConfig.RewardId) then
        return
    end

    -- 解析奖励显示配置
    local rewardConfig = XRewardManager.GetRewardList(activityConfig.RewardId)
    if rewardConfig then
        for _, reward in ipairs(rewardConfig) do
            table.insert(rewards, reward)
        end
    end
end

--- 更新关卡列表
function XLineArithmetic3Control:UpdateStage()
    local stages = {}
    self._UiData.Stage = stages

    if self._ChapterId == 0 then
        return
    end

    -- 获取章节下的所有关卡
    local stageConfigs = self._Model:GetStagesByChapterId(self._ChapterId)
    if not stageConfigs then
        return
    end

    for i, stageConfig in ipairs(stageConfigs) do
        local isPassed = self._Model:IsStagePassed(stageConfig.Id)
        local star = self._Model:GetStageStar(stageConfig.Id)
        local isUnlock = self._Model:IsStageUnlock(stageConfig.Id)

        ---@class XLineArithmetic3ControlDataStage
        local stageData = {
            Id = stageConfig.Id,
            StageId = stageConfig.Id,
            Name = stageConfig.Name or "",
            Index = i,
            IsPassed = isPassed,
            Star = star,
            StarAmount = star,
            MaxStarAmount = 3, -- 每关最多3星
            IsUnlock = isUnlock,
            IsLock = not isUnlock,
            Icon = stageConfig.Icon or ""
        }
        table.insert(stages, stageData)
    end
end

--- 更新章节标题
function XLineArithmetic3Control:UpdateChapterTitle()
    if self._ChapterId == 0 then
        self._UiData.CurrentChapterName = ""
        self._UiData.CurrentChapterStar = ""
        self._UiData.ChapterBg = ""
        return
    end

    local chapterConfig = self._Model:GetChapterConfig(self._ChapterId)
    if not chapterConfig then
        self._UiData.CurrentChapterName = ""
        self._UiData.CurrentChapterStar = ""
        self._UiData.ChapterBg = ""
        return
    end

    self._UiData.CurrentChapterName = chapterConfig.Name or ""
    self._UiData.ChapterBg = chapterConfig.Bg or "Img01"

    -- 计算章节星数
    local totalStar = 0
    local maxStar = 0
    local stageConfigs = self._Model:GetStagesByChapterId(self._ChapterId)
    if stageConfigs then
        for _, stageConfig in ipairs(stageConfigs) do
            local star = self._Model:GetStageStar(stageConfig.Id)
            totalStar = totalStar + star
            maxStar = maxStar + 3 -- 每关最多3星
        end
    end

    self._UiData.CurrentChapterStar = totalStar .. "/" .. maxStar
end

--- 设置默认选中关卡的脏标记
---@param isDirty boolean 是否脏
function XLineArithmetic3Control:SetDefaultSelectDirty(isDirty)
    self._UiData.IsDefaultSelectDirty = isDirty
end

--- 设置当前章节ID
---@param chapterId number 章节ID
function XLineArithmetic3Control:SetChapterId(chapterId)
    self._ChapterId = chapterId
end

--- 点击章节（打开章节详情界面）
---@param chapterData XLineArithmetic3ControlDataChapter 章节数据
function XLineArithmetic3Control:OnClickChapter(chapterData)
    if not chapterData then
        XLog.Warning("[XLineArithmetic3Control] 章节数据为空")
        return
    end

    -- 检查章节是否解锁
    if not chapterData.IsOpen then
        XLog.Warning("[XLineArithmetic3Control] 章节未解锁，chapterId:", chapterData.Id)
        return
    end

    -- 设置当前章节ID
    self:SetChapterId(chapterData.Id)
    self._UiData.CurrentChapterIndex = chapterData.ChapterIndex

    -- 打开章节详情界面
    XLuaUiManager.Open("UiLineArithmetic3Chapter")
end

--- 重新挑战当前关卡（从结算界面的“再来一次”进入）
function XLineArithmetic3Control:RestartCurrentStage()
    if self._StageId == 0 then
        XLog.Warning("[XLineArithmetic3Control] 无法开始游戏，关卡ID为0")
        return
    end
    -- 标记：本局是通过结算界面的“再来一次”重新挑战
    self._IsRestartFromAgain = true
    -- 请求服务端重新开始（Restart），本地仅初始化，不再发送 Start
    XMVCA.XLineArithmetic3:RequestRestart(self._StageId)
    self:InitGame(self._StageId, true)
end

--- 打开关卡游戏界面
---@param stageId number 关卡ID
function XLineArithmetic3Control:OpenStageUi(stageId)
    if not stageId or stageId == 0 then
        XLog.Warning("[XLineArithmetic3Control] 关卡ID无效")
        return
    end

    -- 检查关卡是否解锁
    if not self._Model:IsStageUnlock(stageId) then
        XLog.Warning("[XLineArithmetic3Control] 关卡未解锁，stageId:", stageId)
        XUiManager.TipText("LineArithmeticStageLock")
        return
    end

    -- 打开游戏界面
    XLuaUiManager.Open("UiLineArithmetic3Game", stageId)
end

--- 挑战下一关
function XLineArithmetic3Control:ChallengeNextStage()
    if self._StageId == 0 then
        XLog.Warning("[XLineArithmetic3Control] 无法挑战下一关，当前关卡ID为0")
        return
    end

    -- 获取下一关ID
    local nextStageId = self._Model:GetNextStageId(self._StageId)
    if not nextStageId or nextStageId == 0 then
        XLog.Warning("[XLineArithmetic3Control] 没有下一关了")
        -- 关闭结算界面，返回章节界面
        XLuaUiManager.CloseAllUpperUi("UiLineArithmetic3Main")
        return
    end

    -- 若下一关所属章节未解锁，则返回章节界面
    local nextStageConfig = self._Model:GetStageConfig(nextStageId)
    if nextStageConfig and not self._Model:IsChapterUnlock(nextStageConfig.ChapterId) then
        XLuaUiManager.CloseAllUpperUi("UiLineArithmetic3Main")
        return
    end

    -- 初始化下一关
    self:InitGame(nextStageId)

    -- 关闭结算界面
    XLuaUiManager.Close("UiLineArithmetic3PopupSettlement")

    -- 触发游戏更新事件
    XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME)
end

--- 请求结算
function XLineArithmetic3Control:RequestSettle()
    if self._StageId == 0 then
        return
    end

    -- 通关保底1星
    local star = math.max(1, self:GetCurrentStar())

    -- 伪造一次operation请求
    XMVCA.XLineArithmetic3:RequestOperation(self._StageId, 1, star, function()
        -- 根据关卡星星条件计算 StarByte（与 XLineArithmetic2 一致：满足则 10^(i-1)）
        local byteCode = 0
        local stageConfig = self._Model:GetStageConfig(self._StageId)
        if stageConfig and stageConfig.StarCondition then
            for i = 1, #stageConfig.StarCondition do
                local conditionId = stageConfig.StarCondition[i]
                if conditionId then
                    local condition = XConditionManager.GetConditionTemplate(conditionId)
                    if condition and self._Game:IsMatchCondition(condition) then
                        byteCode = byteCode + (10 ^ (i - 1))
                    end
                end
            end
            byteCode = math.floor(byteCode)
        end

        -- 已走过的路径转为 Record 格式（一笔连线游戏，仅一条路径，Round=1）
        local path = self._Game:GetTraveledPath()
        local points = {}
        for i = 1, #path do
            local pos = path[i]
            points[#points + 1] = {
                X = math.floor(pos.x),
                Y = math.floor(pos.y),
            }
        end

        -- 埋点数据：来自 Game（关卡耗时、一笔完成、回撤次数、是否使用提示等）
        local analytics = self._Game and self._Game:GetAnalyticsData() or {}

        -- StarState：十进制位码，每一位对应一个目标是否完成（最高位=目标1）
        -- 例：110 表示目标1、2完成，目标3未完成
        local endCode = 0
        local conditions = stageConfig and stageConfig.StarCondition or {}
        local count = math.min(3, #conditions)
        for i = 1, count do
            local conditionId = conditions[i]
            local digit = 0
            if conditionId then
                local condition = XConditionManager.GetConditionTemplate(conditionId)
                if condition and self._Game and self._Game:IsMatchCondition(condition) then
                    digit = 1
                end
            end
            endCode = endCode * 10 + digit
        end
        analytics.StarState = endCode

        ---@class XLineArithmetic3SettleRecord 与 XLineArithmetic2 一致的 GridInfo 结构
        local record = {
            Record = {
                {
                    Round = 1,
                    Points = points,
                    Score = 0,
                },
            },
            StarByte = byteCode,
            -- 以下为埋点相关字段
            -- 是否使用提示
            TipType = analytics.TipType or 0,
            -- 星星目标完成状态（十进制位码，最高位=目标1）
            StarState = analytics.StarState or 0,
            -- 关卡耗时
            Duration = analytics.Duration or 0,
            -- 是否只使用一笔完成
            OnlyOneLine = analytics.OnlyOneLine or 0,
            -- 回撤次数
            UndoCount = analytics.UndoCount or 0,
        }

        local settleType = self._IsRestartFromAgain and 2 or 1
        -- 本局结算完成后，重置标记
        self._IsRestartFromAgain = false

        XMVCA.XLineArithmetic3:RequestSettle(self._StageId, star, record, settleType)
    end)
end

--- 请求放弃关卡
function XLineArithmetic3Control:RequestAbandon()
    if self._StageId == 0 then
        return
    end
    XMVCA.XLineArithmetic3:RequestAbandon(self._StageId)
end

--- 退出游戏界面
function XLineArithmetic3Control:ExitGame()
    self._Model:SetCurrentGameStageId(nil)
end

--- 获取车头可移动的方向列表
---@return table[] 可移动方向列表
function XLineArithmetic3Control:GetMovableDirections()
    if not self._Game then
        return {}
    end
    return self._Game:GetMovableDirections()
end

function XLineArithmetic3Control:OnRelease()
    
end

--region ClientConfig

function XLineArithmetic3Control:GetClientConfigText(key, index)
    return self._Model:GetClientConfigTextByKey(key, index)
end

--endregion

return XLineArithmetic3Control
