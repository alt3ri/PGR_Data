local XBountyChallengeEnum = require("XModule/XBountyChallenge/XBountyChallengeEnum")
local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XBountyChallengeAgency : XFubenActivityAgency
---@field private _Model XBountyChallengeModel
local XBountyChallengeAgency = XClass(XFubenActivityAgency, "XBountyChallengeAgency")
function XBountyChallengeAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.BountyChallenge)
end

function XBountyChallengeAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyBountyChallengeData = Handler(self, self.NotifyBountyChallengeData)
    XRpc.NotifyBountyChallengeMonsterDifficultyState = Handler(self, self.NotifyBountyChallengeMonsterDifficultyState)
end

function XBountyChallengeAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XBountyChallengeAgency:ExCheckInTime()
    local config = self:ExGetConfig()
    if not config then
        return false
    end
    if config.TimeId then
        if XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            return true
        end
    end
    
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return false
    end
    local isInTime = XFunctionManager.CheckInTimeByTimeId(activityConfig.TimeId)
    return isInTime
end

function XBountyChallengeAgency:ExOnSkip()
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.BountyChallenge) then
        return false
    end

    if not self:ExCheckInTime() then
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
    local functionOpen = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BountyChallenge)
    if not functionOpen then
        return false
    end
    XLuaUiManager.Open("UiBountyChallengeMain")
    return true
end

function XBountyChallengeAgency:NotifyBountyChallengeData(data)
    self._Model:SetActivityData(data)
end

function XBountyChallengeAgency:NotifyBountyChallengeMonsterDifficultyState(data)
    self._Model:SetServerData(data)
end

function XBountyChallengeAgency:ExCheckIsShowRedPoint()
    return self:IsRed()
end

function XBountyChallengeAgency:IsRed()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return false
    end
    local isInTime = XFunctionManager.CheckInTimeByTimeId(activityConfig.TimeId)
    if not isInTime then
        return false
    end
    
    --1、有可领取奖励时
    --玩法主界面对应怪物入口显示蓝点
    --活动界面玩法入口显示蓝点
    local taskConfigs = self._Model:GetTaskConfigs()
    for _, config in pairs(taskConfigs) do
        local taskId = config.TaskId
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end

    --新boss关卡开启时，玩法界面boss入口、玩法入口显示蓝点，点击boss入口后消除蓝点
    for bossId, _ in pairs(self._Model:GetBossConfigs()) do
        if self:IsBossNewRed(bossId) then
            return true
        end
    end

    return false
end

--新boss关卡开启，能挑战，但是还没打过
function XBountyChallengeAgency:IsBossNewRed(bossId)
    local isBossOpen = self._Model:IsBossOpen(bossId)
    if isBossOpen then
        local value = XSaveTool.GetData("BountyChallengeNewBoss" .. XPlayer.Id .. bossId)
        if value == nil then
            return true
        end
    end
    return false
end

function XBountyChallengeAgency:IsBossRed(bossId)
    for i = 1, 99 do
        local boss = self._Model:GetBossConfig(bossId)
        if boss then
            local difficultyGroupId = boss.DifficultyGroupId
            local difficultyConfig = self._Model:GetDifficultyConfig(difficultyGroupId, i)
            if difficultyConfig then
                local taskGroupId = difficultyConfig.TaskGroupId
                local tasks = self._Model:GetTaskList(taskGroupId)
                if tasks then
                    for _, taskId in pairs(tasks) do
                        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                            return true
                        end
                    end
                else
                    XLog.Warning("[XBountyChallengeAgency] 找不到boss对应的任务配置:", bossId)
                    break
                end
            else
                -- 达到难度上限
                break
            end
        else
            -- 找不到boss
            break
        end
    end
    return false
end

function XBountyChallengeAgency:BountyChallengeSelectDifficultyMonsterRequest(bossId, difficultyLevel, callback)
    XNetwork.Call("BountyChallengeSelectDifficultyMonsterRequest", {
        MonsterId = bossId,
        Difficulty = difficultyLevel,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback()
        end
    end)
end

function XBountyChallengeAgency:HasCharactersLimit()
    local bossId, difficulty = self._Model:GetCurrentBossIdAndDifficulty()
    local characterList = self._Model:GetCharacters(bossId, difficulty)
    if not characterList then
        return false
    end
    if #characterList > 0 then
        return true
    end
    return false
end

function XBountyChallengeAgency:HasRobotsLimit()
    local bossId, difficulty = self._Model:GetCurrentBossIdAndDifficulty()
    local characterList, isRobot = self._Model:GetCharacters(bossId, difficulty)
    if not characterList then
        return false
    end
    if #characterList > 0 then
        return isRobot
    end
    return false
end


-- 返回false代表可使用全部,返回table代表可试用的角色
function XBountyChallengeAgency:GetCharactersTrial(bossId, level)
    --3、试玩角色规则
    --
    --（1）不同难度需支持配置对应的试玩角色组
    --①难度表增加试玩角色组字段，配置 对应的试玩角色组id
    --
    --（1）增加试玩角色表配置
    --②增加试玩角色表，配置“试玩角色组”对应的“试玩角色id”
    --试玩角色id需支持数组配置多个id
    local boss = self._Model:GetBossConfig(bossId)
    if not boss then
        return false
    end
    local difficultyGroupId = boss.DifficultyGroupId
    local config = self._Model:GetDifficultyConfig(difficultyGroupId, level)
    if not config then
        return false
    end

    local characterGroupId = config.TrialCharacterGroupId
    if characterGroupId == 0 then
        return false
    end

    local characterGroupConfig = self._Model:GetCharacterGroupTrial(characterGroupId)
    return characterGroupConfig.RobotIdList
end

function XBountyChallengeAgency:GetCharacters()
    local bossId, difficulty = self._Model:GetCurrentBossIdAndDifficulty()
    local characters = self._Model:GetCharacters(bossId, difficulty)
    local characterList = {}
    if not characters or #characters == 0 then
        characterList = XMVCA.XCharacter:GetOwnCharacterList()
    else
        for _, characterId in pairs(characters) do
            local character = XMVCA.XCharacter:GetCharacter(characterId)
            if character then
                characterList[#characterList + 1] = character
            end
        end
    end

    local trialCharacterList = self:GetCharactersTrial(bossId, difficulty)
    if trialCharacterList then
        for _, robotId in pairs(trialCharacterList) do
            local XRobot = require("XEntity/XRobot/XRobot")
            local robot = XRobot.New(robotId)
            characterList[#characterList + 1] = robot
        end
    end

    return characterList
end

function XBountyChallengeAgency:GetCharacterIds()
    local bossId, difficulty = self._Model:GetCurrentBossIdAndDifficulty()
    local characters = self._Model:GetCharacters(bossId, difficulty)
    
    return characters
end

function XBountyChallengeAgency:GetCharacterCanSelectAmount()
    local bossId, difficulty = self._Model:GetCurrentBossIdAndDifficulty()
    local difficultyConfig = self._Model:GetDifficultyConfig(bossId, difficulty)
    if not difficultyConfig then
        return 3
    end
    return difficultyConfig.CharacterMaximumNum
end

-- 因为“自动选择下一关，和手动领取奖励”有冲突，所以去掉自动选择下一关
--function XBountyChallengeAgency:ShowReward(winData)
--    local bossId, level = self._Model:GetCurrentBossIdAndDifficulty()
--    if bossId and level then
--        local nextLevel = level + 1
--        local config = self._Model:GetDifficultyConfig(bossId, nextLevel)
--        if config and self._Model:GetBossDifficultyState(bossId, nextLevel) == XBountyChallengeEnum.DifficultyState.Passed then
--            XSaveTool.SaveData("BountyChallengeLevel" .. XPlayer.Id .. bossId, nextLevel)
--        end
--    end
--en

function XBountyChallengeAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    local xteam = XDataCenter.TeamManager.GetXTeam(teamId) or XDataCenter.TeamManager.GetTempTeam(teamId)
    local preFight = {}
    preFight.CardIds = {}
    preFight.StageId = stage.StageId
    preFight.CaptainPos = xteam.CaptainPos
    preFight.FirstFightPos = xteam.FirstFightPos
    preFight.RobotIds = {}
    for _, v in pairs(xteam.EntitiyIds or {}) do
        if not XRobotManager.CheckIsRobotId(v) then
            table.insert(preFight.CardIds, v)
            table.insert(preFight.RobotIds, 0)
        else
            table.insert(preFight.CardIds, 0)
            table.insert(preFight.RobotIds, v)
        end
    end
    if xteam and xteam.GetCurGeneralSkill then
        preFight.GeneralSkill = xteam:GetCurGeneralSkill()
    end
    if xteam then
        if xteam.GetEnterCgIndex then
            preFight.EnterCgIndex = xteam:GetEnterCgIndex()
        end
        if xteam.GetSettleCgIndex then
            preFight.SettleCgIndex = xteam:GetSettleCgIndex()
        end
    end
    return preFight
end

return XBountyChallengeAgency