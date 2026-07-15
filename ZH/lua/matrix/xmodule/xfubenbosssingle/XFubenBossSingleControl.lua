local XBossSingleDifficultyInfo = require("XModule/XFubenBossSingle/XData/XBossSingleDifficultyInfo")
local XTeam = require("XEntity/XTeam/XTeam")

---@class XFubenBossSingleControl : XControl
---@field private _Model XFubenBossSingleModel
local XFubenBossSingleControl = XClass(XControl, "XFubenBossSingleControl")

function XFubenBossSingleControl:OnInit()
    -- 初始化内部变量
end

function XFubenBossSingleControl:UseUiStackOperationRef()
    return true
end

function XFubenBossSingleControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFubenBossSingleControl:RemoveAgencyEvent()

end

function XFubenBossSingleControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

-- region Check

function XFubenBossSingleControl:CheckLevelHasHideBoss()
    local data = self:GetBossSingleData()
    local levelType = data:GetBossSingleLevelType()

    if data:IsNewVersion() then
        return true
    end
    if levelType == XEnumConst.BossSingle.LevelType.ChooseAble then
        return false
    end

    local config = self._Model:GetBossSingleGradeConfigByLevelType(levelType)

    if config and config.HideBossOpen then
        return config.HideBossOpen
    end

    return false
end

function XFubenBossSingleControl:CheckHideBossOpen(bossStage)
    if bossStage.DifficultyType ~= XEnumConst.BossSingle.DifficultyType.Hide then
        return false, nil
    end

    local isOpen, desc = self:CheckBossOpen(bossStage)

    return isOpen, desc
end

function XFubenBossSingleControl:CheckBossOpen(bossStage)
    local isOpen = true
    local desc = ""

    for i = 1, #bossStage.OpenCondition do
        if bossStage.OpenCondition[i] and bossStage.OpenCondition[i] > 0 then
            isOpen, desc = XConditionManager.CheckCondition(bossStage.OpenCondition[i])
        end

        if not isOpen then
            break
        end
    end

    return isOpen, desc
end

function XFubenBossSingleControl:HasStageRecord(stageId)
    local data = self:GetBossSingleData()

    if not data:IsBossSingleEmpty() then
        local historyList = data:GetBossSingleHistoryList()
        if not XTool.IsTableEmpty(historyList) then
            for _, history in pairs(historyList) do
                if history:GetStageId() == stageId then
                    return true
                end
            end
        end
    end
    return false
end

--- 检查自动战斗保存
---@return XBossSingleStageHistory
function XFubenBossSingleControl:CheckAutoFight(stageId)
    local data = self:GetBossSingleData()

    if not data:IsBossSingleEmpty() then
        local historyList = data:GetBossSingleHistoryList()

        if not XTool.IsTableEmpty(historyList) then
            for _, history in pairs(historyList) do
                if history:GetStageId() == stageId then
                    return history
                end
            end
        end
    end

    return nil
end

function XFubenBossSingleControl:CheckHideBossOpenByBossId(bossId)
    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)
    local hideBossCfg = nil
    local closeDesc = ""

    for i = 1, #sectionInfo do
        if sectionInfo[i].DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide then
            hideBossCfg = sectionInfo[i]
            break
        end
    end

    if hideBossCfg == nil then
        return false, closeDesc
    end

    return self:CheckHideBossOpen(hideBossCfg)
end

function XFubenBossSingleControl:CheckStagePassed(sectionId, index)
    local sectionInfo = self:GetBossSectionInfoByBossId(sectionId)
    local stageId = sectionInfo[index].StageId
    local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)

    return stageInfo.Unlock
end

--- 检查奖励是否领取
function XFubenBossSingleControl:CheckRewardGet(rewardId)
    local data = self:GetBossSingleData()
    local rewardIds = data:GetBossSingleRewardIdList()

    for _, id in pairs(rewardIds) do
        if rewardId == id then
            return true
        end
    end

    return false
end

function XFubenBossSingleControl:CheckHasRankData(levelType)
    local gradeType = self._Model:GetBossSingleGradeTypeByLevelType(levelType)
    local isNormal = gradeType ~= XEnumConst.BossSingle.LevelType.Normal
    local isMeduim = gradeType ~= XEnumConst.BossSingle.LevelType.Medium

    return isNormal and isMeduim
end

--- 囚笼体验关卡开启
function XFubenBossSingleControl:CheckTrialStageOpen(stageId)
    local difficultyType = self._Model:GetBossSingleStageDifficultyTypeByStageId(stageId)
    local preStageId = self._Model:GetTrialPreStageId(stageId)
    local data = self:GetBossSingleData()

    if difficultyType == XEnumConst.BossSingle.DifficultyType.Experiment or not preStageId then
        return true
    end

    local preStageInfo = data:GetBossSingleTrialStageInfoByStageId(preStageId)

    --- 隐藏关不加入囚笼体验模式
    if preStageInfo and preStageInfo:GetScore() and difficultyType ~= XEnumConst.BossSingle.DifficultyType.Hide then
        return true
    end
    return false
end

function XFubenBossSingleControl:CheckHasTrialGradeConfigByType(levelType)
    if not levelType then
        return false
    end

    local configs = self._Model:GetBossSingleTrialGradeConfigs()

    return configs[levelType] ~= nil
end

---@param rankData XBossSingleRankData
function XFubenBossSingleControl:CheckCurrentRank(levelType, config, rankData)
    if not config or not rankData then
        return false
    end

    local rankNumber = rankData:GetRankNumber()
    local totalCount = rankData:GetTotalCount()

    if not levelType or not rankNumber or not totalCount then
        return false
    end
    if levelType ~= config.LevelType then
        return false
    end
    if rankNumber >= 1 and totalCount > 0 then
        rankNumber = rankNumber / totalCount
    end

    return rankNumber > config.MinRank and rankNumber <= config.MaxRank
end

function XFubenBossSingleControl:CheckChallengeOpen()
    local singleData = self:GetBossSingleData()

    if not singleData:CheckHasChallengeData() then
        return false
    end

    local levelType = singleData:GetBossSingleLevelType()
    local needScore = self:GetChallengeNeedScore()
    local gradeType = self._Model:GetBossSingleGradeTypeByLevelType(levelType)

    return gradeType == XEnumConst.BossSingle.LevelType.Extreme and singleData:GetTotalScoreBestRecord() >= needScore
            and singleData:IsNewVersion()
end

function XFubenBossSingleControl:CheckChallengeRedPoint()
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:CheckChallengeRedPoint()
end

-- endregion

function XFubenBossSingleControl:SetEnterBossInfo(
    bossId,
    bossLevel,
    featureId,
    bossSingleChallengeBuffGroup)
    self._Model:SetEnterBossInfo(bossId, bossLevel)
    self._Model:SetCurrentFeatureId(featureId or 0)
    self._Model:SetBossSingleChallengeBuffGroup(bossSingleChallengeBuffGroup)
end

function XFubenBossSingleControl:GetCurrentFeatureId()
    return self._Model:GetCurrentFeatureId()
end

function XFubenBossSingleControl:SetFightStageType(value)
    self._Model:SetFightStageType(value)
end

function XFubenBossSingleControl:OnEnterNormalFight()
    self:SetFightStageType(XEnumConst.BossSingle.StageType.Normal)
    self._Model:SetBossSingleChallengeBuffGroup(nil)
end

function XFubenBossSingleControl:OnEnterTrialFight()
    self:SetFightStageType(XEnumConst.BossSingle.StageType.Trial)
    self._Model:SetBossSingleChallengeBuffGroup(nil)
end

function XFubenBossSingleControl:OnEnterBestiaryFight()
    self:SetFightStageType(XEnumConst.BossSingle.StageType.Bestiary)
    self._Model:SetBossSingleChallengeBuffGroup(nil)
end


function XFubenBossSingleControl:OnEnterChallengeFight()
    self:SetFightStageType(XEnumConst.BossSingle.StageType.Challenge)
end

function XFubenBossSingleControl:GetFightStageType()
    return self._Model:GetFightStageType()
end

---@return XBossSingle
function XFubenBossSingleControl:GetBossSingleData()
    return self._Model:GetBossSingleData()
end

function XFubenBossSingleControl:GetMaxTeamCharacterMember()
    return self._Model:GetMaxTeamCharacterMember()
end

---@return XBossSingleChallenge
function XFubenBossSingleControl:GetBossSingleChallengeData()
    return self._Model:GetBossSingleChallengeData()
end

function XFubenBossSingleControl:GetTrialTotalScoreInfoById(sectionId)
    return self._Model:GetTrialTotalScore(sectionId)
end

function XFubenBossSingleControl:GetBestiraryTotalScoreById(sectionId)
    local totalScore = 0
    local sectionConf = self:GetBossSectionConfigByBossId(sectionId)
    local data = self:GetBossSingleData()

    for _, stageId in pairs(sectionConf.StageId) do
        local stageData = data:GetBossSingleBestiraryStageInfoByStageId(stageId)
        totalScore = totalScore + (stageData and stageData:GetScore() or 0)
    end

    return totalScore
end

function XFubenBossSingleControl:OnActivityEnd()
    local data = self:GetBossSingleData()

    if not data:GetIsNeedReset() then
        return
    end
    if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
        return
    end
    XUiManager.TipText("BossOnlineOver")
    XLuaUiManager.RunMain()

    data:SetIsNeedReset(false)
end

function XFubenBossSingleControl:IsInLevelTypeHigh()
    local bossSingleData = self:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    local gradeType = self._Model:GetBossSingleGradeTypeByLevelType(levelType)

    return gradeType == XEnumConst.BossSingle.LevelType.High
end

function XFubenBossSingleControl:IsInLevelTypeExtreme()
    local bossSingleData = self:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    local gradeType = self._Model:GetBossSingleGradeTypeByLevelType(levelType)

    return gradeType == XEnumConst.BossSingle.LevelType.Extreme
end

function XFubenBossSingleControl:IsBossSingleTrial()
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:IsBossSingleTrial()
end

function XFubenBossSingleControl:IsBossSingleNormal()
    return self:GetFightStageType() == XEnumConst.BossSingle.StageType.Normal
end

function XFubenBossSingleControl:IsBossSingleChallenge()
    return self:GetFightStageType() == XEnumConst.BossSingle.StageType.Challenge
end

function XFubenBossSingleControl:IsInBossSectionTime(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
    local switchTimeId = self._Model:GetBossSingleSectionSwitchTimeIdById(sectionId)

    local openTime = XFunctionManager.GetStartTimeByTimeId(switchTimeId)

    if not openTime or openTime <= 0 then
        return true
    end

    local closeTime = XFunctionManager.GetEndTimeByTimeId(switchTimeId)

    if not closeTime or closeTime <= 0 then
        return true
    end

    local nowTime = XTime.GetServerNowTimestamp()

    return openTime <= nowTime and nowTime < closeTime
end

function XFubenBossSingleControl:IsChooseLevelTypeConditionOk()
    if not self:IsInLevelTypeHigh() then
        return false
    end

    local needScore = self:GetChooseLevelTypeNeedScore()
    local data = self:GetBossSingleData()

    if needScore > 0 and data:GetBossSingleMaxScore() >= needScore then
        return true
    end

    return XPlayer.IsMedalUnlock(XMedalConfigs.MedalId.BossSingle)
end

function XFubenBossSingleControl:GetBossSingleTrialGradeConfigByType(levelType)
    return self._Model:GetBossSingleTrialGradeConfigByLevelType(levelType)
end

function XFubenBossSingleControl:GetMaxSpecialNumber()
    return self._Model:GetMaxSpecialNumber()
end

function XFubenBossSingleControl:GetChallengeNeedScore()
    local challengeLevelType = self:GetBossSingleData():GetBossSingleChallengeLevelType()

    return self._Model:GetBossSingleChallengeGradeNeedScoreByLevelType(challengeLevelType)
end

function XFubenBossSingleControl:GetBossSingleChallengeGradeNeedScoreByLevelType(levelId)
    return self._Model:GetBossSingleChallengeGradeNeedScoreByLevelType(levelId)
end

--- 检查是否需要播放终极区解锁动画
---@return boolean 是否需要播放动画
function XFubenBossSingleControl:CheckNeedPlayExtremeUnlockAnimation()
    -- 检查是否在终极区
    if not self:IsInLevelTypeExtreme() then
        return false
    end
    
    -- 检查是否已经播放过动画
    if self._Model:GetExtremeUnlockAnimationPlayed() then
        return false
    end
    
    -- 检查分数是否达到解锁要求
    local needScore = self:GetChooseLevelTypeNeedScore()
    local data = self:GetBossSingleData()
    
    if needScore > 0 and data:GetBossSingleMaxScore() >= needScore then
        -- 标记已播放，避免重复播放
        self._Model:SetExtremeUnlockAnimationPlayed(true)
        return true
    end
    
    return false
end

function XFubenBossSingleControl:GetBossSectionLeftTime(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
    local switchTimeId = self._Model:GetBossSingleSectionSwitchTimeIdById(sectionId)
    local closeTime = XFunctionManager.GetEndTimeByTimeId(switchTimeId)

    if not closeTime or closeTime <= 0 then
        return 0
    end

    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = closeTime - nowTime

    return leftTime
end

function XFubenBossSingleControl:GetChooseLevelTypeNeedScore()
    local data = self:GetBossSingleData()
    local levelType = data:GetBossSingleLevelType() + 1
    -- +1不一定就等于下一关, 要根据配置表判断, 但是读入一个配置太浪费了, 所以单纯noTips, 没有配置, 保持原状就好
    local noTips = true
    local bossSingleGradeCfg = self._Model:GetBossSingleGradeConfigByLevelType(levelType, noTips)

    if bossSingleGradeCfg and bossSingleGradeCfg.NeedScore then
        return bossSingleGradeCfg.NeedScore
    end

    return 0
end

function XFubenBossSingleControl:GetChallengeRecordCD()
    return self._Model:GetChallengeRecordCD()
end

function XFubenBossSingleControl:GetRankIsOpenByType(levelType)
    local timeId = self._Model:GetBossSingleGradeRankTimeIdByLevelType(levelType)

    return XFunctionManager.CheckInTimeByTimeId(timeId, true)
end

function XFubenBossSingleControl:GetRankLevelConfigByType(levelType)
    return self._Model:GetBossSingleGradeConfigByLevelType(levelType)
end

function XFubenBossSingleControl:GetBossSectionTeamBuffId(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)

    return self._Model:GetBossSingleSectionTeamBuffIdById(sectionId)
end

function XFubenBossSingleControl:GetBossSectionInfoByBossId(bossId)
    return self._Model:GetBossSectionInfoById(bossId)
end

function XFubenBossSingleControl:GetBossStageConfig(bossStageId)
    return self._Model:GetBossSingleStageConfigByStageId(bossStageId)
end

function XFubenBossSingleControl:GetBossStageScoreByStageId(stageId)
    return self._Model:GetBossSingleStageScoreByStageId(stageId)
end

function XFubenBossSingleControl:GetBossSectionConfigByBossId(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)

    return self._Model:GetBossSingleSectionConfigById(sectionId)
end

function XFubenBossSingleControl:GetBossGradeConfigs()
    local result = {}
    local configs = self._Model:GetBossSingleGradeConfigs()
    local data = self:GetBossSingleData()

    for _, config in pairs(configs) do
        if data:IsCurrentConfig(config) then
            table.insert(result, config)
        end
    end

    return result
end

function XFubenBossSingleControl:GetBossSingleGroupById(id)
    return self._Model:GetBossSingleGroupConfigById(id)
end

function XFubenBossSingleControl:GetRankLevelNameByType(levelType)
    return self._Model:GetBossSingleGradeLevelNameByLevelType(levelType)
end

function XFubenBossSingleControl:GetChallengeRankLevelNameByType(levelType)
    return self._Model:GetBossSingleChallengeGradeLevelNameByLevelType(levelType)
end

function XFubenBossSingleControl:GetChallengeRankLevelIconByType(levelType)
    return self._Model:GetBossSingleChallengeGradeLevelIconByLevelType(levelType)
end

function XFubenBossSingleControl:GetRankLevelRangeDescByType(levelType)
    local minLevel = self._Model:GetBossSingleGradeMinPlayerLevelByLevelType(levelType)
    local maxLevel = self._Model:GetBossSingleGradeMaxPlayerLevelByLevelType(levelType)

    return XUiHelper.GetText("BossSingleRankDesc", minLevel, maxLevel)
end

function XFubenBossSingleControl:GetRankLevelIconByType(levelType)
    return self._Model:GetBossSingleGradeIconByLevelType(levelType)
end

function XFubenBossSingleControl:GetProposedLevel(stageId)
    local data = self:GetBossSingleData()
    local levelType = data:GetBossSingleLevelType()
    local maxPlayerLevel = self._Model:GetBossSingleGradeMaxPlayerLevelByLevelType(levelType)

    return XMVCA.XFuben:GetStageProposedLevel(stageId, maxPlayerLevel)
end

function XFubenBossSingleControl:GetMaxStamina()
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetMaxStamina()
end

function XFubenBossSingleControl:GetChallengeCount()
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetChallengeCount()
end

function XFubenBossSingleControl:GetCharacterChallengeCount(characterId)
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetCharacterChallengeCount(characterId)
end

function XFubenBossSingleControl:GetRankSpecialIcon(number, levelType)
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetRankSpecialIcon(number, levelType)
end

function XFubenBossSingleControl:GetRankRewardConfig(levelType)
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetRankRewardConfig(levelType)
end

function XFubenBossSingleControl:GetPreFullScore(stageId)
    local data = self:GetBossSingleData()
    local levelType = data:GetBossSingleLevelType()
    local config = self:GetBossStageConfig(stageId)

    if not config then
        return 0
    end

    local fullScore = config.PreFullScore[levelType]

    if not fullScore then
        return 0
    end

    return fullScore
end

--- 获取某个Boss当前讨伐值
function XFubenBossSingleControl:GetBossCurScore(bossId)
    local score = 0
    local stageList = self:GetBossStageList(bossId)

    if not XTool.IsTableEmpty(stageList) then
        for _, stageId in ipairs(stageList) do
            score = score + self:GetBossStageScore(stageId)
        end
    end

    return score
end

--- 获取某个Boss当前讨伐值
function XFubenBossSingleControl:GetBossScoreBestRecord(bossId)
    local score = 0
    local stageList = self:GetBossStageList(bossId)

    if not XTool.IsTableEmpty(stageList) then
        for _, stageId in ipairs(stageList) do
            local stageData = XMVCA.XFuben:GetStageData(stageId)
            score = score + (stageData and stageData.Score or 0)
        end
    end

    return score
end

--- 获取某个Boss的所有stageId配置
function XFubenBossSingleControl:GetBossStageList(bossId)
    if not bossId then
        return {}
    end
    local config = self:GetBossSectionConfigByBossId(bossId)

    return config.StageId or {}
end

--- 获取某关当次讨伐值
function XFubenBossSingleControl:GetBossStageScore(stageId)
    if self._Model:IsResetOpen() then
        local newRecord = self._Model:GetRecordCurrentByStageId(stageId)
        if newRecord then
            return newRecord.Score
        end
    end
    local stageData = XMVCA.XFuben:GetStageData(stageId)
    return stageData and stageData.Score or 0
    --return self:GetStageCurrentScore(stageId)
end

--- 获取当次结算当前Boss的讨伐值
function XFubenBossSingleControl:GetBossCurSettleScore(settleStageId, settleScore)
    local score = 0
    local bossId = self:GetBossIdByStageId(settleStageId)

    if not bossId then
        return score
    end

    local stageType = self:GetFightStageType()

    -- 如果是鏖战点（挑战模式），只计算讨伐值最高的前2个关卡
    if stageType == XEnumConst.BossSingle.StageType.Challenge then
        local challengeData = self:GetBossSingleChallengeData()
        if challengeData and not challengeData:GetIsEmpty() then
            -- 按照 __InitFeatureRecordTag 的逻辑：收集所有有记录的关卡，排序后取前2个
            local stageScoreList = {}
            local featureCount = challengeData:GetFeatureCount()
            
            -- 遍历所有挑战关卡（鏖战点的关卡）
            for i = 1, featureCount do
                local feature = challengeData:GetFeatureByIndex(i)
                if feature then
                    local stageId = feature:GetStageId()
                    local stageScore = 0

                    if stageId == settleStageId then
                        -- 当前结算的关卡：只有当结算分数比原本的记录高时，才使用结算分数
                        local savedScore = feature:GetScore()
                        if settleScore > savedScore then
                            stageScore = settleScore
                        else
                            stageScore = savedScore
                        end
                    else
                        -- 其他关卡使用已保存的分数
                        stageScore = feature:GetScore()
                    end

                    -- 只统计有记录的关卡（有角色或分数大于0）
                    -- 当前结算关卡总是参与计算（即使还没有保存记录）
                    if feature:GetIsRecord() or stageId == settleStageId then
                        table.insert(stageScoreList, {
                            StageId = stageId,
                            Score = stageScore
                        })
                    end
                end
            end
            
            -- 如果计分关卡数量 <= 2，直接累加
            if #stageScoreList <= 2 then
                for _, item in ipairs(stageScoreList) do
                    score = score + item.Score
                end
            else
                -- 按讨伐值从高到低排序（与 __InitFeatureRecordTag 的逻辑一致）
                table.sort(stageScoreList, function(itemA, itemB)
                    return itemA.Score > itemB.Score
                end)
                
                -- 只取前2个最高讨伐值
                for i = 1, math.min(2, #stageScoreList) do
                    score = score + stageScoreList[i].Score
                end
            end
        else
            -- 如果没有挑战数据，使用当前结算分数
            score = settleScore
        end
    elseif stageType == XEnumConst.BossSingle.StageType.Bestiary then
        local totalScore = settleScore
        local sectionConf = self:GetBossSectionConfigByBossId(bossId)
        local data = self:GetBossSingleData()

        for _, stageId in pairs(sectionConf.StageId) do
            if stageId ~= settleStageId then
                local stageData = data:GetBossSingleBestiraryStageInfoByStageId(stageId)
                totalScore = totalScore + (stageData and stageData:GetScore() or 0)
            end
        end

        score = totalScore
    elseif stageType == XEnumConst.BossSingle.StageType.Trial then
        local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
        local sectionConfig = self._Model:GetBossSingleSectionConfigById(sectionId)
        local totalScore = settleScore
        local bossSingleData = self._Model:GetBossSingleData()

        for _, stageId in pairs(sectionConfig.StageId) do
            if stageId ~= settleStageId then
                local info = bossSingleData:GetBossSingleTrialStageInfoByStageId(stageId)
                if info then totalScore = totalScore + info:GetScore() end
            end
        end

        score = totalScore
    elseif stageType == XEnumConst.BossSingle.StageType.Normal then
        -- 普通模式：累加所有关卡的讨伐值
        local stageList = self:GetBossStageList(bossId)

        for _, stageId in ipairs(stageList) do
            if stageId == settleStageId then
                score = score + settleScore
            else
                score = score + self:GetBossStageScore(stageId)
            end
        end
    else
        score = 0
        XLog.Error("Unknown stage type: " .. stageType)
    end

    return score
end

--- 通过stageId获取Boss讨伐值上限
function XFubenBossSingleControl:GetBossMaxScoreByStageId(stageId)
    local bossId = self:GetBossIdByStageId(stageId)

    return self:GetBossMaxScore(bossId)
end

--- 获取某个Boss讨伐值上限
function XFubenBossSingleControl:GetBossMaxScore(bossId)
    local score = 0
    local stageList = self:GetBossStageList(bossId)

    for _, stageId in ipairs(stageList) do
        local config = self:GetBossStageConfig(stageId)

        if config.DifficultyType ~= XEnumConst.BossSingle.DifficultyType.Hide then
            score = score + config.Score + self:GetBaseScoreByStageId(stageId)
        end
    end
    return score
end

--- 根据stageId获取bossId
function XFubenBossSingleControl:GetBossIdByStageId(targetStageId)
    local configs = self._Model:GetBossSingleSectionConfigs()
    local singleData = self:GetBossSingleData()

    for bossId, config in pairs(configs) do
        if singleData:IsCurrentConfig(config) then
            local stageList = self:GetBossStageList(config.SectionId)

            for _, stageId in ipairs(stageList) do
                if stageId == targetStageId then
                    return config.SectionId
                end
            end
        end
    end
end

function XFubenBossSingleControl:GetBossIcon(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
    local sectionConfig = self._Model:GetBossSingleSectionConfigById(sectionId)

    return sectionConfig.BossHeadIcon or ""
end

function XFubenBossSingleControl:GetBossUnlockChallengeBannerImage(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
    local sectionConfig = self._Model:GetBossSingleSectionConfigById(sectionId)

    return sectionConfig.UnlockChallengeBannerImage or ""
end

function XFubenBossSingleControl:GetBossRankIcon(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
    local sectionConfig = self._Model:GetBossSingleSectionConfigById(sectionId)

    return sectionConfig.BossRankIcon or ""
end

function XFubenBossSingleControl:GetBossName(bossId)
    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)
    local hasHideBoss = self:CheckLevelHasHideBoss()
    local count = hasHideBoss and #sectionInfo or #sectionInfo - 1
    local curBossConfig = sectionInfo[count]

    return curBossConfig.BossName or ""
end

function XFubenBossSingleControl:GetCurTrialBossIndex(bossId)
    local index = 0
    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)

    for key, value in pairs(sectionInfo) do
        local stageId = value.StageId

        if self:CheckTrialStageOpen(stageId) then
            index = index + 1
        end
    end

    return index
end

function XFubenBossSingleControl:GetCurBossIndex(bossId)
    if self._Model:GetIsUseSelectIndex() then
        local selectIndex = self._Model:GetCurrentSelectIndex()

        if XTool.IsNumberValid(selectIndex) then
            return selectIndex
        end
    end

    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)
    local hasHideBoss = self:CheckLevelHasHideBoss()
    local count = hasHideBoss and #sectionInfo or #sectionInfo - 1
    local difference = 0

    if sectionInfo[1] then
        difference = sectionInfo[1].DifficultyType - 1
    end
    for i = 1, count do
        local stageInfo = XMVCA.XFuben:GetStageInfo(sectionInfo[i].StageId)

        if not stageInfo.Passed then
            count = sectionInfo[i].DifficultyType - difference
            break
        end
    end

    -- 打到隐藏Boss 但是没有达到开启条件处理
    if sectionInfo[count].DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide then
        local hideBossOpen, _ = self:CheckHideBossOpen(sectionInfo[count])

        if not hideBossOpen then
            count = sectionInfo[#sectionInfo - 1].DifficultyType
        end
    end

    return count
end

function XFubenBossSingleControl:GetScoreRewardConfig(levelType)
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetScoreRewardConfig(levelType)
end

function XFubenBossSingleControl:GetCurScoreRewardConfig()
    local data = self:GetBossSingleData()
    local curScore = data:GetBossSingleTotalScore()
    local levelType = data:GetBossSingleLevelType()
    local scoreReward = self:GetScoreRewardConfig(levelType)

    for i = 1, #scoreReward do
        if curScore < scoreReward[i].Score then
            return scoreReward[i]
        end
    end
end

function XFubenBossSingleControl:GetAutoFightRebate()
    return self._Model:GetAutoFightRebate()
end

function XFubenBossSingleControl:GetAutoFightCount()
    if self:GetBossSingleData():IsNewVersion() then
        return self._Model:GetAutoFightNewCount()
    else
        return self._Model:GetAutoFightCount()
    end
end

function XFubenBossSingleControl:GetMaxRankCount()
    return self._Model:GetMaxRankCount()
end

function XFubenBossSingleControl:GetTeamIdByBossId(bossId)
    return "Fuben_Boss_Single_" .. bossId
end

function XFubenBossSingleControl:GetTeamByBossId(bossId)
    local teamId = self:GetTeamIdByBossId(bossId)
    ---@type XTeam
    local resultTeam = XDataCenter.TeamManager.GetXTeam(teamId)

    if not resultTeam then
        local teamData = nil
        
        -- 如果是普通区，优先使用服务端编队数据
        if self:IsBossSingleNormal() then
            local serverTeamInfo = XMVCA.XFubenBossSingle:GetNormalStageTeamInfo(bossId)
            if serverTeamInfo and serverTeamInfo.CharacterIds and #serverTeamInfo.CharacterIds > 0 then
                -- 使用服务端编队数据
                ---@type XTeam
                local serverTeam = XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdBossSingle"))
                local baseTeamData = serverTeam:SwithToOldTeamData()
                -- 优先使用 per-boss 本地缓存，避免三个 boss 共用 serverTeam 导致 FirstFightPos 互相污染
                local localTeam = XSaveTool.GetData(teamId .. XPlayer.Id)

                -- 构造编队数据
                teamData = {
                    FirstFightPos = (localTeam and localTeam.FirstFightPos) or baseTeamData.FirstFightPos or 0,
                    CaptainPos = (localTeam and localTeam.CaptainPos) or baseTeamData.CaptainPos or 0,
                    TeamData = {},
                    TeamName = "",
                    SelectedGeneralSkill = (localTeam and localTeam.SelectedGeneralSkill) or baseTeamData.SelectedGeneralSkill,
                    EnterCgIndex = (localTeam and localTeam.EnterCgIndex) or baseTeamData.EnterCgIndex,
                    SettleCgIndex = (localTeam and localTeam.SettleCgIndex) or baseTeamData.SettleCgIndex,
                }
                
                -- 填充角色ID列表
                for i = 1, 3 do
                    if serverTeamInfo.CharacterIds[i] then
                        teamData.TeamData[i] = serverTeamInfo.CharacterIds[i]
                    else
                        teamData.TeamData[i] = 0
                    end
                end
            end
        end
        
        -- 如果没有服务端数据，使用本地数据或默认数据
        if not teamData then
            local localTeam = XSaveTool.GetData(teamId .. XPlayer.Id)
            ---@type XTeam
            local serverTeam = XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdBossSingle"))

            resultTeam = XTeam.New(teamId)
            if not localTeam then
                resultTeam:UpdateFromTeamData(serverTeam:SwithToOldTeamData())
            else
                teamData = {
                    FirstFightPos = localTeam.FirstFightPos,
                    CaptainPos = localTeam.CaptainPos,
                    TeamData = localTeam.EntitiyIds,
                    TeamName = "",
                    SelectedGeneralSkill = localTeam.SelectedGeneralSkill,
                    EnterCgIndex = localTeam.EnterCgIndex,
                    SettleCgIndex = localTeam.SettleCgIndex,
                }

                resultTeam:UpdateFromTeamData(teamData)
            end
        else
            -- 使用服务端数据创建编队
            resultTeam = XTeam.New(teamId)
            resultTeam:UpdateFromTeamData(teamData)
        end

        resultTeam:UpdateSaveCallback(function(inTeam)
            local serverTeam = XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdBossSingle"))
            serverTeam:UpdateFromTeamData(inTeam:SwithToOldTeamData())
        end)
        XDataCenter.TeamManager.SetXTeam(resultTeam)
    end

    return resultTeam
end

function XFubenBossSingleControl:GetBossStageInfo(stageId)
    local bossId = XMVCA.XFubenBossSingle:GetBossSectionId(stageId)
    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)

    for i = 1, #sectionInfo do
        if sectionInfo[i].StageId == stageId then
            return sectionInfo[i]
        end
    end

    return nil
end

function XFubenBossSingleControl:GetBossDifficultName(stageId)
    local name = ""
    local bossId = XMVCA.XFubenBossSingle:GetBossSectionId(stageId)
    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)

    for i = 1, #sectionInfo do
        if sectionInfo[i].StageId == stageId then
            name = sectionInfo[i].DifficultyDesc
        end
    end

    return name
end

---@return XBossSingleDifficultyInfo
function XFubenBossSingleControl:GetBossCurDifficultyInfo(bossId, index)
    local sectionInfo = self:GetBossSectionInfoByBossId(bossId)
    local sectionId = self._Model:GetBossSectionConfigIdBySectionId(bossId)
    local sectionConfig = self._Model:GetBossSingleSectionConfigById(sectionId)
    local hasHideBoss = self:CheckLevelHasHideBoss()
    local count = hasHideBoss and #sectionInfo or #sectionInfo - 1
    local curBossConfig = sectionInfo[count]

    for i = 1, count do
        local stageInfo = XMVCA.XFuben:GetStageInfo(sectionInfo[i].StageId)

        if not stageInfo.Passed then
            curBossConfig = sectionInfo[i]
            break
        end
    end

    local data = self:GetBossSingleData()
    local now = XTime.GetServerNowTimestamp()
    local tagIcon = nil

    for i = 1, #sectionConfig.ActivityTimeId do
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(sectionConfig.ActivityTimeId[i])

        if startTime and endTime and now >= startTime and now < endTime then
            tagIcon = sectionConfig.ActivityTag[i]
            break
        end
    end

    local groupTempId = nil
    local groupTempName = nil
    local groupTempIcon = nil
    local hideBossOpen = false
    local levelTypeConfig = self._Model:GetBossSingleGradeConfigByLevelType(data:GetBossSingleLevelType())

    if levelTypeConfig and levelTypeConfig.GroupId and levelTypeConfig.GroupId[index] then
        groupTempId = levelTypeConfig.GroupId[index]

        local groupInfo = self._Model:GetBossSingleGroupConfigById(groupTempId)

        groupTempName = groupInfo.GroupName
        groupTempIcon = groupInfo.GroupIcon
        hideBossOpen = levelTypeConfig.HideBossOpen
    end
    if hideBossOpen then
        hideBossOpen = self:CheckHideBossOpen(curBossConfig)
    end

    -- 打到隐藏Boss 但是没有达到开启条件处理
    if not hideBossOpen and curBossConfig.DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide then
        curBossConfig = sectionInfo[#sectionInfo - 1]
    end

    ---@type XBossSingleDifficultyInfo
    local info = XBossSingleDifficultyInfo.New()

    info:SetBossName(curBossConfig.BossName)
    info:SetBossIcon(sectionConfig.BossHeadIcon)
    info:SetBossDifficultyName(curBossConfig.DifficultyDesc)
    info:SetTagIcon(tagIcon)
    info:SetGroupId(groupTempId)
    info:SetGroupName(groupTempName)
    info:SetGroupIcon(groupTempIcon)
    info:SetIsHideBoss(hideBossOpen)

    return info
end

---@return XBossSingleFeature
function XFubenBossSingleControl:GetCurrentChallengeFeatureById(featureId)
    local challengeData = self:GetBossSingleChallengeData()

    return challengeData:GetFeatureById(featureId)
end

function XFubenBossSingleControl:GetGradeTypeByLevelType(levelType)
    return self._Model:GetBossSingleGradeTypeByLevelType(levelType)
end

function XFubenBossSingleControl:GetLevelTypeByGradeType(gradeType)
    ---@type XFubenBossSingleAgency
    local agency = self:GetAgency()

    return agency:GetLevelTypeByGradeType(gradeType)
end

function XFubenBossSingleControl:GetBossSingleGroupIdsByLevelType(levelType)
    return self._Model:GetBossSingleGradeGroupIdByLevelType(levelType)
end

function XFubenBossSingleControl:GetBaseScoreByStageId(stageId)
    local data = self:GetBossSingleData()

    if not data:IsNewVersion() then
        return 0
    end

    return self._Model:GetBossSingleScoreRuleBaseScoreById(stageId) or 0
end

function XFubenBossSingleControl:SetIsUseSelectIndex(value)
    self._Model:SetIsUseSelectIndex(value)
end

function XFubenBossSingleControl:SetCurrentSelectIndex(value)
    self._Model:SetCurrentSelectIndex(value)
end

-- v4.2 新增：添加选中的可选词缀ID（跟随buff）
---@param buffFeatureId number buff的featureId
---@param selectableFeatureId number 可选词缀的featureId
function XFubenBossSingleControl:AddSelectedSelectableFeatureId(buffFeatureId, selectableFeatureId)
    self._Model:AddSelectedSelectableFeatureId(buffFeatureId, selectableFeatureId)
end

-- v4.2 新增：移除选中的可选词缀ID（跟随buff）
---@param buffFeatureId number buff的featureId
---@param selectableFeatureId number 可选词缀的featureId
function XFubenBossSingleControl:RemoveSelectedSelectableFeatureId(buffFeatureId, selectableFeatureId)
    self._Model:RemoveSelectedSelectableFeatureId(buffFeatureId, selectableFeatureId)
end

-- v4.2 新增：获取指定buff的选中可选词缀ID列表
---@param buffFeatureId number buff的featureId
---@return number[]
function XFubenBossSingleControl:GetSelectedSelectableFeatureIds(buffFeatureId)
    return self._Model:GetSelectedSelectableFeatureIds(buffFeatureId)
end

-- v4.2 新增：设置选中的可选词缀ID列表
---@param featureIds table<number, number[]>
function XFubenBossSingleControl:SetSelectedSelectableFeatureIds(featureIds)
    self._Model:SetSelectedSelectableFeatureIds(featureIds)
end

-- region OpenUi

function XFubenBossSingleControl:OpenChallengeBossViewUi(levelType)
    if levelType then
        local groupId = self._Model:GetBossSingleChallengeGradeBossGroupIdByLevelType(levelType)
        local sectionIds = self._Model:GetBossSingleGroupSectionIdById(groupId)

        if not XTool.IsTableEmpty(sectionIds) then
            XLuaUiManager.Open("UiFubenBossSingleModeBossDetail", sectionIds)
        end
    end
end

function XFubenBossSingleControl:OpenChallengeUi()
    self:GetAgency():RequestChallengeSelfRank(function()
        XLuaUiManager.Open("UiFubenBossSingleModeDetail")
    end)
end

function XFubenBossSingleControl:OpenRankUi(levelType, bossId, isForce)
    if not self:CheckHasRankData(levelType) then
        return
    end
    if bossId then
        self:GetAgency():RequestBossRankData(function(rankData)
            XLuaUiManager.Open("UiFubenBossSingleRank", rankData, bossId)
        end, levelType, bossId, isForce)
        if isForce then
            self:GetAgency():RequestRankData(nil, levelType, isForce)
        end
    else
        self:GetAgency():RequestRankData(function(rankData)
            XLuaUiManager.Open("UiFubenBossSingleRank", rankData)
        end, levelType, isForce)
    end
end

function XFubenBossSingleControl:OpenChallengeSaveDialog(...)
    XLuaUiManager.Open("UiFubenBossSingleModeSaveDialog", ...)
end

function XFubenBossSingleControl:OpenChallengeRankUi()
    self:GetAgency():RequestChallengeRankData(function(rankData)
        XLuaUiManager.Open("UiFubenBossSingleChallengeRank", rankData)
    end)
end

function XFubenBossSingleControl:OpenChallengeRankRewardUi()
    XMVCA.XFubenBossSingle:RequestChallengeRankData(function(rankData)
        if not rankData then
            return
        end

        XLuaUiManager.Open("UiFubenBossSingleChallengeRankReward", rankData:GetRankNumber(), rankData:GetTotalCount())
    end)
end

-- endregion

function XFubenBossSingleControl:IsResetBtnVisible(stageId)
    if self._Model:IsResetOpen() then
        if XMVCA.XFuben:CheckStageIsPass(stageId) then
            return true
        end
    end
    return false
end

function XFubenBossSingleControl:IsResetOpen()
    return self._Model:IsResetOpen()
end

-- 重置功能开启，但是呈灰色
function XFubenBossSingleControl:IsResetBtnEnable(stageId)
    --if XMain.IsZLBDebug then
    --    return true
    --end
    
    --local stageData = XMVCA.XFuben:GetStageData(stageId)
    --local curScore = stageData and stageData.Score or 0
    local curScore = self:GetStageCurrentScore(stageId)
    if curScore > 0 then
        -- 本期挑战记录
        local history = self._Model:GetRecordCurrentByStageId(stageId)
        if history and history.Score > 0 then
            return true
        end
    end
    return false
end

function XFubenBossSingleControl:GetRecordCurrentByStageId(stageId)
    return self._Model:GetRecordCurrentByStageId(stageId)
end

function XFubenBossSingleControl:GetStageCurrentScore(stageId)
    if self._Model:IsResetOpen() then
        return self:GetBossStageScore(stageId)
    else
        local stageData = XMVCA.XFuben:GetStageData(stageId)
        return stageData and stageData.Score
    end
    return 0
end

function XFubenBossSingleControl:GetCharacterListInRecord(stageId)
    local autoFightData = self:CheckAutoFight(stageId)
    return autoFightData and autoFightData:GetCharacterList() or {}
end

function XFubenBossSingleControl:GetStageScoreBestRecord(stageId)
    local datas = self._Model:GetHistoryBestRecord()
    if not datas then
        return 0
    end
    for i, data in pairs(datas) do
        if data.StageId == stageId then
            return data.Score
        end
    end
    return 0
end

function XFubenBossSingleControl:GetTotalScoreBestRecord()
    return self._Model:GetTotalScoreBestRecord()
end

function XFubenBossSingleControl:IsResetCoolDown()
    local timestamp = self._Model:GetTimeStampResetCooldown()
    if not timestamp then
        return false
    end
    return XTime.GetServerNowTimestamp() < timestamp
end

function XFubenBossSingleControl:StartResetCoolDown()
    self._Model:SetTimeStampResetCooldown(XTime.GetServerNowTimestamp() + 60)
end

function XFubenBossSingleControl:GetResetCoolDownRemainTime()
    local timestamp = self._Model:GetTimeStampResetCooldown()
    if not timestamp then
        return 0
    end
    return timestamp > 0 and timestamp - XTime.GetServerNowTimestamp() or 0
end

return XFubenBossSingleControl
