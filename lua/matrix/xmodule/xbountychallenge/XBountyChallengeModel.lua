local XBountyChallengeEnum = require("XModule/XBountyChallenge/XBountyChallengeEnum")

local TableKey = {
    BountyChallengeActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    BountyChallengeCharacterGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    BountyChallengeDifficultyGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    BountyChallengeMonster = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    BountyChallengeStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    BountyChallengeTask = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    BountyChallengeTrialCharacterGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    BountyChallengeConfig = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", TableDefindName = "XTableBountyChallengeConstVar" },
}

---@class XBountyChallengeModel : XModel
local XBountyChallengeModel = XClass(XModel, "XBountyChallengeModel")

function XBountyChallengeModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/BountyChallenge", TableKey)
    self._ActivityId = 0
    self._ServerData = false

    self._CurrentBossId = false
    self._CurrentDifficulty = false
    
    self._TaskState = false
end

function XBountyChallengeModel:ClearPrivate()
end

function XBountyChallengeModel:ResetAll()
    self._ActivityId = 0
    self._ServerData = false
    self._TaskState = false
end

---@return XTable.XTableBountyChallengeActivity
function XBountyChallengeModel:GetActivityConfig()
    if not self._ActivityId then
        return false
    end
    if self._ActivityId == 0 then
        return false
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BountyChallengeActivity, self._ActivityId, true)
    return config
end

---@return XTable.XTableBountyChallengeMonster
function XBountyChallengeModel:GetBossConfig(bossId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BountyChallengeMonster, bossId, true)
end

function XBountyChallengeModel:GetBossConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BountyChallengeMonster)
end

function XBountyChallengeModel:IsBossOpen(bossId)
    local config = self:GetBossConfig(bossId)
    if not config then
        return false
    end
    local timeId = config.TimeId
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    return isInTime
end

---@return XTable.XTableBountyChallengeMonster[]
function XBountyChallengeModel:GetAllBossConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BountyChallengeMonster)
end

---@return XTable.XTableBountyChallengeDifficultyGroup
function XBountyChallengeModel:GetDifficultyConfig(difficultyGroupId, level)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.BountyChallengeDifficultyGroup)
    for _, config in pairs(configs) do
        if config.DifficultyGroupId == difficultyGroupId and config.Difficulty == level then
            return config
        end
    end
    return false
end

function XBountyChallengeModel:IsBossDifficultyPassed(bossId, difficultyLevel)
    if not self._ServerData then
        return false
    end
    local state = self:GetBossDifficultyState(bossId, difficultyLevel)
    return state == XBountyChallengeEnum.DifficultyState.Passed
end

function XBountyChallengeModel:GetBossDifficultyState(bossId, difficultyLevel)
    -- 如果有数据，就从服务端数据里取
    if self._ServerData then
        local stateDict = self._ServerData.MonsterDifficultyState
        if stateDict then
            local monsterDifficultyInfo = stateDict[bossId]
            if monsterDifficultyInfo then
                local passedDifficulties = monsterDifficultyInfo.PassedDifficulties
                if passedDifficulties then
                    --如果一个难度出现在passed里 那他的状态就是passed
                    for i, v in pairs(passedDifficulties) do
                        if v == difficultyLevel then
                            return XBountyChallengeEnum.DifficultyState.Passed
                        end
                    end
                    --如果没出现在passedDifficulties里，那么难度-1在不在，如果在就是解锁状态
                    for i, v in pairs(passedDifficulties) do
                        if v == difficultyLevel - 1 then
                            return XBountyChallengeEnum.DifficultyState.Unlocked
                        end
                    end
                end
            end
        end 
    end

    -- 由于服务端默认空数据，通关后才写入
    if difficultyLevel <= self:GetDefaultOpenStage() then
        return XBountyChallengeEnum.DifficultyState.Unlocked
    end

    return XBountyChallengeEnum.DifficultyState.Locked
end

function XBountyChallengeModel:SetActivityData(data)
    self._ActivityId = data.ActivityId
end

function XBountyChallengeModel:SetServerData(data)
    if self._ServerData then
        -- 已有就更新
        local stateDict1 = self._ServerData.MonsterDifficultyState
        local stateDict2 = data.MonsterDifficultyState
        for k, v in pairs(stateDict2) do
            stateDict1[k] = v
        end
    else
        -- 没有就全覆盖
        self._ServerData = data
    end
end

function XBountyChallengeModel:GetCharacterGroup(characterGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BountyChallengeCharacterGroup, characterGroupId, true)
end

function XBountyChallengeModel:GetCharacterGroupTrial(characterGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BountyChallengeTrialCharacterGroup, characterGroupId, true)
end

function XBountyChallengeModel:GetTaskConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BountyChallengeTask)
end

function XBountyChallengeModel:GetTaskList(taskGroupId)
    local taskConfigs = self._ConfigUtil:GetByTableKey(TableKey.BountyChallengeTask)
    local tasks = {}
    for _, config in pairs(taskConfigs) do
        if config.TaskGroupId == taskGroupId then
            tasks[#tasks + 1] = config.TaskId
        end
    end
    return tasks
end

function XBountyChallengeModel:GetBossAllTask(bossId)
    local tasks = {}
    local bossConfig = self:GetBossConfig(bossId)
    if bossConfig then
        local difficultyGroupId = bossConfig.DifficultyGroupId
        for level = 1, 99 do
            local difficultyConfig = self:GetDifficultyConfig(difficultyGroupId, level)
            if difficultyConfig then
                local taskList = self:GetTaskList(difficultyConfig.TaskGroupId)
                for _, taskId in pairs(taskList) do
                    tasks[#tasks + 1] = taskId
                end
            else
                break
            end
        end
    end
    return tasks
end

-- 服务端的数据从0还是从1开始呢?
function XBountyChallengeModel:GetBossPassedDifficulty(bossId)
    if not self._ServerData then
        return 0
    end
    for i = 1, 99 do
        local state = self:GetBossDifficultyState(bossId, i)
        if state == XBountyChallengeEnum.DifficultyState.Passed then
            return i
        end
    end
    return 0
end

function XBountyChallengeModel:GetBossMaxDifficultyLevel(bossId)
    local boss = self:GetBossConfig(bossId)
    local max = 1
    if boss then
        local difficultyGroupId = boss.DifficultyGroupId
        for i = 1, 99 do
            local difficultyConfig = self:GetDifficultyConfig(difficultyGroupId, i)
            if difficultyConfig then
                max = i
            else
                break
            end
        end
    end
    return max
end

---@return XTable.XTableBountyChallengeDifficultyGroup[]
function XBountyChallengeModel:GetAllDifficultyConfigs(bossId)
    local difficulties = {}
    local boss = self:GetBossConfig(bossId)
    if boss then
        local difficultyGroupId = boss.DifficultyGroupId
        for i = 1, 99 do
            local difficultyConfig = self:GetDifficultyConfig(difficultyGroupId, i)
            if difficultyConfig then
                difficulties[#difficulties + 1] = difficultyConfig
            else
                break
            end
        end
    end
    return difficulties
end

---@return XTable.XTableBountyChallengeStage
function XBountyChallengeModel:GetStageDescConfig(stageDescId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BountyChallengeStage, stageDescId, true)
    return config
end

function XBountyChallengeModel:SetCurrentBossIdAndDifficulty(bossId, difficulty)
    self._CurrentBossId = bossId
    self._CurrentDifficulty = difficulty
end

function XBountyChallengeModel:GetCurrentBossIdAndDifficulty()
    return self._CurrentBossId, self._CurrentDifficulty
end

-- 返回false代表可使用全部,返回table代表使用的角色有限制
function XBountyChallengeModel:GetCharacters(bossId, level)
    --（3）每个难度限定玩家选择角色
    --
    --①难度表增加怪物当前难度可使用的角色组id
    --        >配置为0时，可使用所有角色
    --        >配置为对应角色组id时，则只能使用对应id角色组进行挑战
    --
    --②增加角色组表
    --        >配置每个角色组对应可使用的Characterid
    --        >角色id字段需支持数组字段，可配置多个角色id
    local boss = self:GetBossConfig(bossId)
    if not boss then
        return false
    end
    local difficultyGroupId = boss.DifficultyGroupId
    local config = self:GetDifficultyConfig(difficultyGroupId, level)
    if not config then
        return false
    end

    local characterGroupId = config.SelectableCharacterGroupId
    if characterGroupId == 0 then
        return false
    end

    local characterGroupConfig = self:GetCharacterGroup(characterGroupId)
    return characterGroupConfig.CharacterIdList
end

function XBountyChallengeModel:GetDefaultOpenStage()
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BountyChallengeConfig, "InitUnlockDifficulty", true)
    if not config then
        return 1
    end
    return tonumber(config.Values[1]) or 1
end

function XBountyChallengeModel:SetTaskState(taskId, taskState)
    self._TaskState = self._TaskState or {}
    self._TaskState[taskId] = taskState
end

function XBountyChallengeModel:GetTaskState(taskId)
    if not self._TaskState then
        return nil
    end
    return self._TaskState[taskId]
end

return XBountyChallengeModel