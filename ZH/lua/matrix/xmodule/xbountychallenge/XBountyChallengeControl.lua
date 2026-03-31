local XBountyChallengeEnum = require("XModule/XBountyChallenge/XBountyChallengeEnum")

---@class XBountyChallengeControl : XControl
---@field private _Model XBountyChallengeModel
local XBountyChallengeControl = XClass(XControl, "XBountyChallengeControl")

function XBountyChallengeControl:OnInit()
    self._Main = {
        ---@type XUiBountyChallengeMainGridData[]
        BossList = {},
        IsInit = false,
    }
    self._ChapterDetail = {
        Name = "",
        DifficultyLevel = 0,
        Characters = false,
        BossId = 0,
        TaskList = false,
        Icon = "",
        Difficulties = {},
        IsPlayAnimationSync = false,
    }
    self._BossDetail = {
        ---@type XUiBountyChallengeBossDetailData[]
        List = {},
        Names = {},
        Index = 1,
        BossId = 0,
    }
    self._SelectedBossId = 0
    self._DifficultyLevel = 0
end

function XBountyChallengeControl:AddAgencyEvent()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, 0)
    end
end

function XBountyChallengeControl:RemoveAgencyEvent()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XBountyChallengeControl:OnRelease()
end

function XBountyChallengeControl:UpdateTime()
    if not XMVCA.XBountyChallenge:ExCheckInTime() then
        XUiManager.TipText("ActivityAlreadyOver")
        XLuaUiManager.SafeClose("UiBountyChallengeMain")
        XLuaUiManager.SafeClose("UiBountyChallengeChapterDetail")
        XLuaUiManager.SafeClose("UiBountyChallengePopupBossDetail")
        return
    end
end

function XBountyChallengeControl:IsBossOpen(bossId)
    return self._Model:IsBossOpen(bossId)
end

function XBountyChallengeControl:IsDifficultyOpen(bossId, level)
    -- 完全依赖服务端的解锁状态
    --if level == 1 then
    --    return true
    --end

    --优化: 移除原来的通关一个难度其他boss难度同时解锁的规则
    local state = self._Model:GetBossDifficultyState(bossId, level)
    if state == XBountyChallengeEnum.DifficultyState.Locked then
        return false
    end
    return true
end

function XBountyChallengeControl:GetCharacterAmount(bossId, level)
    --（4）每个难度限定玩家上阵角色数量
    --①难度表增加“上阵角色数量”字段
    --        >配置为当前难度限定上阵的角色数量
    local boss = self._Model:GetBossConfig(bossId)
    if not boss then
        return false
    end
    local difficultyGroupId = boss.DifficultyGroupId
    local config = self._Model:GetDifficultyConfig(difficultyGroupId, level)
    if not config then
        return false
    end
    return config.CharacterMaximumNum
end

function XBountyChallengeControl:IsBossClear(bossId)
    local taskList = self._Model:GetBossAllTask(bossId)
    for i = 1, #taskList do
        if not XDataCenter.TaskManager.CheckTaskFinished(taskList[i]) then
            return false
        end
    end
    return true
end

function XBountyChallengeControl:GetUiMain()
    local data = self._Main
    if not data.IsInit then
        data.IsInit = true
        local activityCfg = self._Model:GetActivityConfig()

        if activityCfg then
            for _, monsterId in ipairs(activityCfg.MonsterIdList) do
                local config = self._Model:GetBossConfig(monsterId)
                local bossId = config.Id
                local name = config.Name
                ---@class XUiBountyChallengeMainGridData
                local boss = {
                    BossId = bossId,
                    Name = name,
                    IsClear = false,
                    IsMaxLevel = false,
                    IsLock4Time = false,
                    TimeId = config.TimeId,
                    Progress = 0,
                    ProgressMax = 0,
                    DifficultyLevel = 0,
                    Red = false,
                    DifficultyName = "",
                    Icon = false,
                }
                data.BossList[#data.BossList + 1] = boss
            end
        end
    end

    for i = 1, #data.BossList do
        local bossId = data.BossList[i].BossId
        local bossConfig = self._Model:GetBossConfig(bossId)
        local maxLevel = self._Model:GetBossMaxDifficultyLevel(bossId)
        
        --获得可以挑战的最高难度
        local levelCanChallenge = 1
        for j = 1, maxLevel do
            local state = self._Model:GetBossDifficultyState(bossId, j)
            if state == XBountyChallengeEnum.DifficultyState.Unlocked
                    or state == XBountyChallengeEnum.DifficultyState.Passed
            then
                levelCanChallenge = j
            end
        end

        local boss = data.BossList[i]
        boss.IsLock4Time = not self:IsBossOpen(bossId)
        boss.IsClear = self:IsBossClear(bossId)

        local taskList = self._Model:GetBossAllTask(bossId)
        local progress = 0
        for i = 1, #taskList do
            local taskId = taskList[i]
            if XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                progress = progress + 1
            end
        end
        boss.Progress = progress
        boss.ProgressMax = #taskList
        boss.DifficultyLevel = levelCanChallenge
        boss.IsMaxLevel = levelCanChallenge >= maxLevel

        boss.Red = XMVCA.XBountyChallenge:IsBossRed(bossId)
                or XMVCA.XBountyChallenge:IsBossNewRed(bossId)
        if boss.IsMaxLevel then
            boss.Icon = bossConfig.Icon2
        else
            boss.Icon = bossConfig.Icon1
        end
        local difficultyConfig = self._Model:GetDifficultyConfig(bossConfig.DifficultyGroupId, levelCanChallenge)
        boss.DifficultyName = difficultyConfig.Name
    end

    return data
end

function XBountyChallengeControl:AutoFinishTask(callback)
    local difficulties = self._Model:GetAllDifficultyConfigs(self._SelectedBossId)
    local tasksToAchieve
    for i = 1, #difficulties do
        local difficulty = difficulties[i]
        local taskGroupId = difficulty.TaskGroupId
        local tasks = self._Model:GetTaskList(taskGroupId)
        for i = 1, #tasks do
            local taskId = tasks[i]
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                tasksToAchieve = tasksToAchieve or {}
                tasksToAchieve[#tasksToAchieve + 1] = taskId
            end
        end
    end
    if tasksToAchieve then
        XDataCenter.TaskManager.FinishMultiTaskRequest(tasksToAchieve, function(goodsList)
            if callback then
                callback()
            end
            XUiManager.OpenUiObtain(goodsList)
        end, true, true)
    end
end

function XBountyChallengeControl:IsPlayAnimationSync()
    return self._ChapterDetail.IsPlayAnimationSync
end

function XBountyChallengeControl:SetPlayAnimationSync()
    self._ChapterDetail.IsPlayAnimationSync = true
end

function XBountyChallengeControl:GetCurStageIsRobot()
    return self._ChapterDetail.IsRobot
end

function XBountyChallengeControl:GetBossIndexInTable(bossId)
    local bossList = self._Main.BossList
    if #bossList == 0 then
        self:GetUiMain()
        bossList = self._Main.BossList
    end
    for i = 1, #bossList do
        if bossList[i].BossId == bossId then
            return i
        end
    end
    return -1
end

function XBountyChallengeControl:GetUiChapterDetail()
    local data = self._ChapterDetail
    local bossConfig = self._Model:GetBossConfig(self._SelectedBossId)
    if not bossConfig then
        XLog.Error("[XBountyChallengeControl] 找不到对应的boss:" .. tostring(self._SelectedBossId))
        return
    end
    data.BossId = self._SelectedBossId
    data.Name = bossConfig.Name

    -- 可上阵角色
    data.Characters = {}
    local characters, isRobot = self._Model:GetCharacters(self._SelectedBossId, self._DifficultyLevel)
    if characters then
        for i = 1, #characters do
            local characterId = characters[i]
            local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
            ---@class XUiBountyChallengeChapterDetailCharacterData
            local character = {
                Icon = icon,
                IsRobot = isRobot,
            }
            data.Characters[#data.Characters + 1] = character
        end
        --else
        -- 没有限制角色
    end

    data.IsRobot = isRobot or false

    -- 难度
    data.Difficulties = {}
    local difficulties = self._Model:GetAllDifficultyConfigs(self._SelectedBossId)
    for i = 1, #difficulties do
        local difficulty = difficulties[i]
        local lockReason
        local isOpen = self:IsDifficultyOpen(self._SelectedBossId, difficulty.Difficulty)
        if not isOpen then
            local preDifficulty = difficulties[i - 1]
            if preDifficulty then
                lockReason = XUiHelper.GetText("StageUnlockCondition", preDifficulty.Name)
            else
                XLog.Error("[XBountyChallengeControl] 难度没有解锁，但是找不到前置难度")
            end
        end

        local taskProgress = 0
        local taskProgressMax = 0
        local taskGroupId = difficulty.TaskGroupId
        local tasks = self._Model:GetTaskList(taskGroupId)
        if tasks and #tasks > 0 then
            taskProgressMax = #tasks
            for i = 1, #tasks do
                local taskId = tasks[i]
                if XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                    taskProgress = taskProgress + 1
                end
            end
        end

        --clear标签需要再当前难度任务全部完成后才显示
        local isClear = taskProgress >= taskProgressMax

        ---@class XUiBountyChallengeChapterDetailDifficultyData
        local difficultyData = {
            Level = difficulty.Difficulty,
            Name = difficulty.Name,
            IsOpen = isOpen,
            IsClear = isClear,
            IsMaxLevel = i == #difficulties,
            LockReason = lockReason,
            TaskProgress = taskProgress,
            TaskProgressMax = taskProgressMax,
            IsSelected = self._DifficultyLevel == difficulty.Difficulty,
        }
        data.Difficulties[#data.Difficulties + 1] = difficultyData
    end

    -- 任务
    local oldTaskList = data.TaskList
    data.TaskList = {}
    
    for i, difficulty in pairs(difficulties) do
        if not XTool.IsTableEmpty(difficulty) then
            local taskList = self._Model:GetTaskCfgList(difficulty.TaskGroupId)
            for i = 1, #taskList do
                ---@type XTableBountyChallengeTask
                local cfg = taskList[i]
                local taskId = cfg.TaskId
                local config = XDataCenter.TaskManager.GetTaskTemplate(taskId)
                local rewards = XRewardManager.GetRewardList(config.RewardId)
                ---@class XUiBountyChallengeChapterDetailTaskData
                local task = {
                    Id = taskId,
                    Name = config.Title,
                    Desc = config.Desc,
                    IsClear = XDataCenter.TaskManager.CheckTaskFinished(taskId),
                    IsCanFinish = XDataCenter.TaskManager.CheckTaskAchieved(taskId),
                    Rewards = rewards,
                    IsPlayAnimation = false,
                    Priority = cfg.Priority,
                    Config = cfg,
                    Difficulty = cfg.Difficulty
                }
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
                if taskData then
                    local state = taskData.State
                    if state == XDataCenter.TaskManager.TaskState.Achieved then
                        local oldState = self._Model:GetTaskState(taskId)
                        if oldState then
                            if oldState ~= state then
                                task.IsPlayAnimation = true
                            end
                        end
                    end
                end
                self._Model:SetTaskState(taskId, taskData.State)
                data.TaskList[#data.TaskList + 1] = task
            end
        end
    end
    
    --任务排序
    table.sort(data.TaskList, function(a, b)
        if a.IsClear ~= b.IsClear then
            -- 已领取奖励的置底
            return not a.IsClear
        end

        if a.IsCanFinish ~= b.IsCanFinish then
            --可领取奖励的置顶
            return a.IsCanFinish
        end
        
        -- 按优先级大小升序
        return a.Priority > b.Priority
    end)
    

    return data
end

function XBountyChallengeControl:SetSelectedBoss(bossId, defaultLevel)
    self._SelectedBossId = bossId
    local level = XSaveTool.GetData("BountyChallengeLevel" .. XPlayer.Id .. bossId)
    if level and level > 0 and self:IsDifficultyOpen(bossId, level) then
        --self:SetDifficultyLevel(level)
        self._DifficultyLevel = level
    else
        --self:SetDifficultyLevel(defaultLevel)
        self._DifficultyLevel = defaultLevel
    end
end

function XBountyChallengeControl:SetDefaultDifficultyLevel()
    local level = XSaveTool.GetData("BountyChallengeLevel" .. XPlayer.Id .. self._SelectedBossId)
    if level and level > 0 and self:IsDifficultyOpen(self._SelectedBossId, level) then
        self._DifficultyLevel = level
    end
    return self._DifficultyLevel
end

function XBountyChallengeControl:SetDifficultyLevel(level)
    self._DifficultyLevel = level
    XSaveTool.SaveData("BountyChallengeLevel" .. XPlayer.Id .. self._SelectedBossId, level)
end

function XBountyChallengeControl:GetRemainTime()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        -- 让玩家看不到0的那一刻
        return 1
    end
    local timeId = activityConfig.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime - currentTime
    -- 让玩家看不到0的那一刻
    return math.max(1, remainTime)
end

function XBountyChallengeControl:GetUiBossDetail()
    local bossConfig = self._Model:GetBossConfig(self._SelectedBossId)
    if not bossConfig then
        XLog.Error("[XBountyChallengeControl] 找不到对应的boss:" .. tostring(self._SelectedBossId))
        return
    end
    local difficultyGroupId = bossConfig.DifficultyGroupId
    local difficultyConfig = self._Model:GetDifficultyConfig(difficultyGroupId, self._DifficultyLevel)
    local stageDescId = difficultyConfig.StageDescId
    local stageDescConfig = self._Model:GetStageDescConfig(stageDescId)
    if not stageDescConfig then
        XLog.Error("[XBountyChallengeControl] 找不到对应的stage描述", stageDescId)
        return
    end
    local data = self._BossDetail
    if data.BossId == self._SelectedBossId then
        return data
    end
    data.BossId = self._SelectedBossId
    data.List = {}
    for i = 1, #stageDescConfig.GameplayDescription do
        local videoConfigId
        if stageDescConfig.VideoConfigId then
            videoConfigId = stageDescConfig.VideoConfigId[i]
        end
        ---@class XUiBountyChallengeBossDetailData
        local desc = {
            VideoConfigId = videoConfigId,
            Desc = stageDescConfig.GameplayDescription[i],
        }
        data.List[#data.List + 1] = desc
    end
    data.Names = stageDescConfig.StageDescriptions
    return data
end

function XBountyChallengeControl:GetUiBossDetailByDescId(descId)
    local stageDescConfig = self._Model:GetStageDescConfig(descId)
    if not stageDescConfig then
        XLog.Error("[XBountyChallengeControl] 找不到对应的stage描述", descId)
        return
    end
    
    local data = {}
    data.BossId = self._SelectedBossId
    data.List = {}
    for i = 1, #stageDescConfig.GameplayDescription do
        local videoConfigId
        if stageDescConfig.VideoConfigId then
            videoConfigId = stageDescConfig.VideoConfigId[i]
        end
        ---@type XUiBountyChallengeBossDetailData
        local desc = {
            VideoConfigId = videoConfigId,
            Desc = stageDescConfig.GameplayDescription[i],
        }
        data.List[#data.List + 1] = desc
    end
    data.Names = stageDescConfig.StageDescriptions
    return data
end

function XBountyChallengeControl:GetCurrentStageId()
    local bossConfig = self._Model:GetBossConfig(self._SelectedBossId)
    return bossConfig.StageId
end

function XBountyChallengeControl:OpenRoom()
    XMVCA.XBountyChallenge:BountyChallengeSelectDifficultyMonsterRequest(self._SelectedBossId, self._DifficultyLevel, function()
        self._Model:SetCurrentBossIdAndDifficulty(self._SelectedBossId, self._DifficultyLevel)
        local stageId = self:GetCurrentStageId()
        local battleRoom = require("XUi/XUiBountyChallenge/XUiBountyChallengeBattleRoleRoom")
        local team = XDataCenter.TeamManager.GetXTeamByTypeId(XEnumConst.TeamTypeId.BountyChallenge)
        
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, battleRoom)
    end)
end

--- 一键领取章节下所有任务奖励
function XBountyChallengeControl:ReceiveAllTask(cb)
    local data = self._ChapterDetail

    if not XTool.IsTableEmpty(data.TaskList) then
        local canFinishTaskList = {}

        for i, v in pairs(data.TaskList) do
            if v.IsCanFinish then
                table.insert(canFinishTaskList, v.Id)
            end
        end

        if not XTool.IsTableEmpty(canFinishTaskList) then
            XDataCenter.TaskManager.FinishMultiTaskRequest(canFinishTaskList, cb)
        end
    end
end

function XBountyChallengeControl:GetConfigStr(key, index)
    return self._Model:GetConfigStr(key, index)
end

function XBountyChallengeControl:GetConfigNum(key, index)
    local numStr = self._Model:GetConfigStr(key, index)

    if string.IsFloatNumber(numStr) then
        return tonumber(numStr)
    end
    
    return 0
end

function XBountyChallengeControl:GetCurrentBossIdAndDifficulty()
    return self._Model:GetCurrentBossIdAndDifficulty()
end

function XBountyChallengeControl:GetDifficultyConfigByBossAndLevel(bossId, level)
    return self._Model:GetDifficultyConfigByBossAndLevel(bossId, level)
end

return XBountyChallengeControl