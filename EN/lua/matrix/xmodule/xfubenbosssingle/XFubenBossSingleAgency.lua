local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XFubenBossSingleAgency : XFubenSimulationChallengeAgency
---@field private _Model XFubenBossSingleModel
local XFubenBossSingleAgency = XClass(XFubenSimulationChallengeAgency, "XFubenBossSingleAgency")

local METHOD_NAME = {
    GetSelfRank = "BossSingleRankInfoRequest",
    GetRankData = "BossSingleGetRankRequest",
    GetReward = "BossSingleGetRewardRequest",
    GetAllReward = "BossSingleGetAllRewardRequest",
    AutoFight = "BossSingleAutoFightRequest",
    SaveScore = "BossSingleSaveScoreRequest",
    ChooseLevelType = "BossSingleSelectLevelTypeRequest",
    GetChallengeSelfRank = "BossSingleChallengeRankInfoRequest",
    GetChallengeRankData = "BossSingleGetChallengeRankRequest",
    BossSingleResetStageRequest = "BossSingleResetStageRequest",
}

function XFubenBossSingleAgency:OnInit()
    -- 初始化一些变量
    self:RegisterChapterAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.BossSingle)

    self._LastSyncServerRankTimes = {}
    self._LastSyncServerBossRankTimes = {}
    self._LastSyncServerChallengeRankTimes = {}
    self._SyncServerSecond = 20
    self.ExChapterType = self:ExGetChapterType()
    self._IsUiShow = false
    
    -- 普通区编队数据缓存（key: SectionId, value: {SectionId, CharacterIds}）
    self._NormalStageTeamInfos = {}
end

function XFubenBossSingleAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.NotifyFubenBossSingleData = Handler(self, self.OnNotifyFubenBossSingleData)
    XRpc.NotifyBossSingleRankInfo = Handler(self, self.OnNotifyBossSingleRankInfo)
    XRpc.NotifyBossSingleChallengeCount = Handler(self, self.OnNotifyBossSingleChallengeCount)
end

--30302803
function XFubenBossSingleAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()

    -- 监听副本结算奖励事件（参考 XTransfiniteManager）
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettle, self)

    self._OnBehaviorDoExitFightHandler = handler(self, self.OnBehaviorDoExitFight)

    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_BEHAVIOR_DO_EXIT_FIGHT, self._OnBehaviorDoExitFightHandler)
end

function XFubenBossSingleAgency:OnRelease()
    self._LastSyncServerRankTimes = {}
    self._LastSyncServerBossRankTimes = {}
    self._LastSyncServerChallengeRankTimes = {}

    -- 移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettle, self)
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_BEHAVIOR_DO_EXIT_FIGHT, self._OnBehaviorDoExitFightHandler)
end

function XFubenBossSingleAgency:ResetAll()
    self._FightSettleDataCache = nil
end

-- region Getter/Setter

function XFubenBossSingleAgency:IsBossSingleDataEmpty()
    local bossSingleData = self:GetBossSingleData()

    return bossSingleData:IsBossSingleEmpty()
end

function XFubenBossSingleAgency:OnActivityEnd()
    local data = self:GetBossSingleData()

    XUiManager.TipText("BossOnlineOver")
    XLuaUiManager.RunMain()
    data:SetIsNeedReset(false)
end

function XFubenBossSingleAgency:UpdateBossSingleData(data)
    self._Model:UpdateBossSingleData(data.FubenBossSingleData)
    self._Model:UpdateBossSingleChallenge()

    local bossSingleData = self:GetBossSingleData()

    XCountDown.CreateTimer(self._Model:GetResetCountDownName(), bossSingleData:GetBossSingleRemainTime())

    if bossSingleData:GetIsNeedReset() then
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET)
    end

    self._Model:UpdateTrailStageMap()
    if self:IsInLevelTypeChooseAble() then
        XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
    end
end

---@return XBossSingle
function XFubenBossSingleAgency:GetBossSingleData()
    return self._Model:GetBossSingleData()
end

---@return XBossSingleChallenge
function XFubenBossSingleAgency:GetChallengeSingleData()
    return self._Model:GetBossSingleChallengeData()
end

function XFubenBossSingleAgency:GetMaxRankCount()
    return self._Model:GetMaxRankCount()
end

function XFubenBossSingleAgency:GetChallengeCount()
    local levelType = self:GetBossSingleData():GetBossSingleLevelType()
    local levelTypeConfig = self._Model:GetBossSingleGradeConfigByLevelType(levelType)

    if XTool.IsTableEmpty(levelTypeConfig) then
        XLog.ErrorTableDataNotFound("XFubenBossSingleAgency:GetChallengeCount", "levelTypeCfg",
            "Share/Fuben/BossSingle/BossSingleGrade.tab", "levelType", tostring(levelType))
        return 0
    end

    if XTime.CheckWeekend() then
        return levelTypeConfig.WeekChallengeCount
    else
        return levelTypeConfig.ChallengeCount
    end
end

function XFubenBossSingleAgency:GetAllChooseBossList()
    return self:GetBossSingleData():GetAllChooseAbleBossList()
end

function XFubenBossSingleAgency:IsBossSingleStage(stageId)
    return not XTool.IsTableEmpty(self._Model:GetBossSingleStageConfigByStageId(stageId))
end

function XFubenBossSingleAgency:IsBossSingleOpen()
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenChallengeBossSingle)

    return isOpen
end

function XFubenBossSingleAgency:IsBossSingleTrial()
    return self._Model:GetFightStageType() == XEnumConst.BossSingle.StageType.Trial
end

function XFubenBossSingleAgency:IsInLevelTypeChooseAble()
    local bossSingleData = self:GetBossSingleData()

    return bossSingleData:GetBossSingleLevelType() == XEnumConst.BossSingle.LevelType.ChooseAble
end

function XFubenBossSingleAgency:IsInLevelTypeExtreme()
    local bossSingleData = self:GetBossSingleData()
    local levelType = bossSingleData:GetBossSingleLevelType()
    local gradeType = self._Model:GetBossSingleGradeTypeByLevelType(levelType)

    return gradeType == XEnumConst.BossSingle.LevelType.Extreme
end

function XFubenBossSingleAgency:GetActivityNo()
    local data = self:GetBossSingleData()

    return data:GetBossSingleActivityNo()
end

function XFubenBossSingleAgency:GetBossNameInfo(bossId, stageId)
    local stageName = ""
    local chapterName = ""
    local sectionInfo = self._Model:GetBossSectionInfoById(bossId)

    for i = 1, #sectionInfo do
        if sectionInfo[i].StageId == stageId then
            local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
            local curBossStageCfg = self._Model:GetBossSingleStageConfigByStageId(sectionInfo[i].StageId)

            stageName = stageCfg.Name
            chapterName = curBossStageCfg.BossName
        end
    end
    return chapterName, stageName
end

function XFubenBossSingleAgency:GetMaxStamina()
    local data = self:GetBossSingleData()
    local levelType = data:GetBossSingleLevelType()
    local staminaCount = self._Model:GetBossSingleGradeStaminaCountByLevelType(levelType)

    if not staminaCount then
        XLog.ErrorTableDataNotFound("XFubenBossSingleAgency:GetMaxStamina", "levelTypeCfg",
            "Share/Fuben/BossSingle/BossSingleGrade.tab", "levelType", tostring(levelType))
        return 0
    end

    return staminaCount
end

function XFubenBossSingleAgency:GetCharacterChallengeCount(characterId)
    local data = self:GetBossSingleData()
    local points = data:GetBossSingleCharacterPointMap()

    return points[characterId] or 0
end

function XFubenBossSingleAgency:GetRankSpecialIcon(number, levelType)
    if not levelType then
        local data = self:GetBossSingleData()

        levelType = data:GetBossSingleLevelType()
    end

    local configs = self:GetRankRewardConfig(levelType)

    if not configs[number] then
        XLog.Error(string.format("表BossSignleReward.tab不存在当前LevelType的RankIcon！索引:%d LevelType:%d",
            number, levelType))
        return
    end

    return configs[number].RankIcon
end

function XFubenBossSingleAgency:GetRankRewardConfig(levelType)
    local data = self:GetBossSingleData()
    local targetId = data:GetBossSingleRewardGroupId()
    local rewardConfig = {}
    local configs = self._Model:GetRankRewardConfigByLevelType(levelType)

    for _, config in pairs(configs) do
        if self:CheckLevelTypeHasRankReward(levelType) then
            if config.RewardGroupId == targetId then
                table.insert(rewardConfig, config)
            end
        else
            table.insert(rewardConfig, config)
        end
    end

    return rewardConfig
end

function XFubenBossSingleAgency:GetScoreRewardConfig(levelType)
    local scoreReward = {}
    local configs = self._Model:GetScoreRewardConfigByLevelType(levelType)
    local data = self:GetBossSingleData()

    if configs then
        for i, config in pairs(configs) do
            if config.RewardGroupId == data:GetBossSingleRewardGroupId() then
                scoreReward[#scoreReward + 1] = config
            end
        end
    end

    return scoreReward
end

function XFubenBossSingleAgency:GetResetCountDownName()
    return self._Model:GetResetCountDownName()
end

function XFubenBossSingleAgency:GetFeatureIdsByFeatureGroupId(groupId)
    return self._Model:GetBossSingleChallengeFeatureGroupFeatureIdsById(groupId)
end

function XFubenBossSingleAgency:GetFeatureConfigById(id)
    return self._Model:GetBossSingleChallengeFeatureConfigById(id)
end

function XFubenBossSingleAgency:GetBossSingleChallengeFeatureGroupConfigByFeatureId(featureId)
    return self._Model:GetBossSingleChallengeFeatureGroupConfigByFeatureId(featureId)
end

function XFubenBossSingleAgency:GetBossSingleChallengeBuffGroupIdByFeatureId(featureGroupId, featureId)
    return self._Model:GetBossSingleChallengeBuffGroupIdByFeatureId(featureGroupId, featureId)
end

function XFubenBossSingleAgency:GetBossSingleChallengeFeatureGroupBuffGroupIdsById(id)
    return self._Model:GetBossSingleChallengeFeatureGroupBuffGroupIdsById(id)
end

---@deprecated
function XFubenBossSingleAgency:GetBossSingleChallengeBuffGroupBuffById(id)
    XLog.Error("XFubenBossSingleAgency:GetBossSingleChallengeBuffGroupBuffById is deprecated, use GetBossSingleChallengeBuffGroupConfigByBuffGroupId instead.")
    return self._Model:GetBossSingleChallengeBuffGroupBuffById(id)
end

function XFubenBossSingleAgency:TryGetBossSingleChallengeBuffGroupConfigByBuffGroupId(
    buffGroupId)

    local succ, r = self._Model:TryGetBossSingleChallengeBuffGroupConfigByBuffGroupId(buffGroupId)
    return succ, r
end

function XFubenBossSingleAgency:GetBossSingleChallengeBuffGroupConfigByBuffGroupId(
    buffGroupId)

    return self._Model:GetBossSingleChallengeBuffGroupConfigByBuffGroupId(buffGroupId)
end

function XFubenBossSingleAgency:GetStageTotalScoreByStageId(stageId)
    return self._Model:GetBossSingleStageScoreByStageId(stageId)
end

function XFubenBossSingleAgency:GetStageIdsBySectionId(sectionId)
    local id = self._Model:GetBossSectionConfigIdBySectionId(sectionId)

    return self._Model:GetBossSingleSectionStageIdById(id)
end

function XFubenBossSingleAgency:GetStageIdsById(id)
    return self._Model:GetBossSingleSectionStageIdById(id)
end

function XFubenBossSingleAgency:GetSectionIdById(id)
    if not XTool.IsNumberValid(id) then
        return 0
    end

    return self._Model:GetBossSingleSectionSectionIdById(id)
end

function XFubenBossSingleAgency:GetModelIdByStageId(stageId)
    return self._Model:GetBossSingleStageModelIdByStageId(stageId)
end

function XFubenBossSingleAgency:GetLevelTypeByGradeType(gradeType)
    local configs = self._Model:GetBossSingleGradeConfigs()
    local bossSingle = self:GetBossSingleData()

    for levelType, config in pairs(configs) do
        if bossSingle:IsCurrentConfig(config) and gradeType == config.GradeType then
            return levelType
        end
    end

    return 0
end

function XFubenBossSingleAgency:GetAllStageCount()
    local count = 0

    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local bossList = data:GetBossSingleBossList()

        for k, bossId in pairs(bossList) do
            local sectionInfo = self._Model:GetBossSectionInfoById(bossId)

            if sectionInfo then
                count = count + #sectionInfo
            end
        end
    end

    return count
end

function XFubenBossSingleAgency:GetNotPassStageCount()
    local count = 0

    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local bossList = data:GetBossSingleBossList()

        for k, bossId in pairs(bossList) do
            count = count + self:GetBossNotPassStageCount(bossId)
        end
    end

    return count
end

function XFubenBossSingleAgency:GetBossNotPassStageCount(bossId)
    local sectionInfo = self._Model:GetBossSectionInfoById(bossId)
    local count = 0

    if sectionInfo then
        for i = 1, #sectionInfo do
            local stageInfo = XMVCA.XFuben:GetStageInfo(sectionInfo[i].StageId)

            --- 检查boss全部完成时不检查隐藏关
            if not stageInfo.Passed then
                count = count + 1
            end
        end
    end

    return count
end

function XFubenBossSingleAgency:GetFreatureIdByStageId(targetStageId)
    local challengeData = self:GetChallengeSingleData()

    if challengeData:GetIsEmpty() then
        return 0
    end

    local feature = challengeData:GetFeatureByStageId(targetStageId)

    if feature then
        return feature:GetFeatureId()
    else
        return 0
    end
end

function XFubenBossSingleAgency:GetShowRecommendIds(featureId)
    return self._Model:GetBossSingleChallengeFeatureShowRecommendIdsById(featureId)
end

function XFubenBossSingleAgency:GetRelieveTeamAstrict()
    return self._Model:GetRelieveTeamAstrict() == 1
end

function XFubenBossSingleAgency:GetCurrentFeatureId()
    return self._Model:GetCurrentFeatureId()
end

-- endregion

-- region Check

function XFubenBossSingleAgency:CheckLevelTypeHasRankReward(levelType)
    local bossSingle = self:GetBossSingleData()

    if bossSingle:IsNewVersion() then
        return levelType == XEnumConst.BossSingle.LevelType.Challenge
    end

    return true
end

function XFubenBossSingleAgency:CheckBossAllPassed(bossId)
    local sectionInfo = self._Model:GetBossSectionInfoById(bossId)

    if sectionInfo then
        for i = 1, #sectionInfo do
            local stageInfo = XMVCA.XFuben:GetStageInfo(sectionInfo[i].StageId)
            local bossStageInfo = self._Model:GetBossSingleStageConfigByStageId(sectionInfo[i].StageId)

            --- 检查boss全部完成时不检查隐藏关
            if not stageInfo.Passed and bossStageInfo.DifficultyType ~= XEnumConst.BossSingle.DifficultyType.Hide then
                return false
            end
        end
    end

    return true
end

--- 检查凹分区是否有两个及以上计分
function XFubenBossSingleAgency:CheckChallengeFinished()
    local challengeData = self:GetChallengeSingleData()

    if challengeData:GetIsEmpty() then
        return true
    end

    return challengeData:GetRecordFeatureCount() >= 2
end

function XFubenBossSingleAgency:CheckAllPassed()
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local bossList = data:GetBossSingleBossList()

        for k, bossId in pairs(bossList) do
            if not self:CheckBossAllPassed(bossId) then
                return false
            end
        end

        return true
    end

    return false
end

--- 检查奖励是否还有奖励需要领取
function XFubenBossSingleAgency:CheckRewardRedHint()
    local data = self:GetBossSingleData()
    local index = data:GetBossSingleLevelType()
    local configs = self:GetScoreRewardConfig(index)

    if (not configs) or #configs == 0 then
        return -1
    end

    local totalScore = data:GetBossSingleTotalScore()
    local rewardIds = data:GetBossSingleRewardIdList()

    for _, v in pairs(configs) do
        local canGet = totalScore >= v.Score
        local got = false

        if canGet then
            for _, id in pairs(rewardIds) do
                if id == v.Id then
                    got = true
                    break
                end
            end

            if not got then
                return 1
            end
        end
    end

    return -1
end

function XFubenBossSingleAgency:CheckChallengeRedPoint()
    local isFinished = self:CheckChallengeFinished()

    return not isFinished
end

function XFubenBossSingleAgency:CheckAcitvityEnd(stageId)
    local data = self:GetBossSingleData()

    local stageType = XMVCA.XFuben:GetStageType(stageId)
    return stageType == XEnumConst.FuBen.StageType.BossSingle and data:GetIsNeedReset()
end

function XFubenBossSingleAgency:CheckShowRecommend(featureId)
    local recommendIds = self._Model:GetBossSingleChallengeFeatureShowRecommendIdsById(featureId)

    return not XTool.IsTableEmpty(recommendIds)
end

function XFubenBossSingleAgency:CheckCanChallengeRecord()
    local bossSingle = self:GetBossSingleData()
    local recordTime = bossSingle:GetBossSingleChallengeDeleteRecordTime()

    if XTool.IsNumberValid(recordTime) then
        local nowTime = XTime.GetServerNowTimestamp()
        local endTime = recordTime + self._Model:GetChallengeRecordCD()

        return endTime <= nowTime
    end

    return true
end

-- endregion

-- region OpenUi

function XFubenBossSingleAgency:OpenBossSingleView(skipId)
    if not self:IsBossSingleDataEmpty() then
        local levelType = self:GetBossSingleData():GetBossSingleLevelType()

        if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.FubenChallengeBossSingle, levelType) then
            return false
        end

        -- 获取异步跳转结果Id
        local skipResultId = XFunctionManager.GetNewResultId()

        self:RequestSelfRank(function()
            self:OpenMainUi(skipId, skipResultId)
        end)

        return skipResultId
    end

    return false
end

function XFubenBossSingleAgency:OpenMainUi(skipId, skipResultId)
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()

        data:SetIsNeedReset(false)
        XLuaUiManager.Open("UiFubenBossSingle", data:GetBossSingleBossList())

        XFunctionManager.AcceptResult(skipResultId, true)
    else
        XFunctionManager.AcceptResult(skipResultId, false)
    end
end

function XFubenBossSingleAgency:OpenTrialUi()
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()

        data:SetIsNeedReset(false)
        XLuaUiManager.Open("UiFubenBossSingleTrial")
    end
end

function XFubenBossSingleAgency:OpenChooseUi()
    local highBossList, extremeBossList = self:GetAllChooseBossList()

    if not highBossList or not extremeBossList then
        return false
    end

    XLuaUiManager.Open("UiFubenBossSingleChooseLevelType", highBossList, extremeBossList)
    return true
end

-- endregion

-- region 副本入口相关

function XFubenBossSingleAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.BossSingle
end

function XFubenBossSingleAgency:ExGetProgressTip()
    local progress = ""
    local data = self:GetBossSingleData()

    if not self:ExGetIsLocked() then
        if data:IsNewVersion() then
            if self:IsInLevelTypeChooseAble() then
                progress = XUiHelper.GetText("BossSingleProgressChooseable")
            elseif not data:CheckHasChallengeData() then
                local stageCount = self:GetNotPassStageCount()
                local allStageCount = self:GetAllStageCount()

                progress = XUiHelper.GetText("BossSingleProgress", allStageCount - stageCount, allStageCount)
            else
                local challengeData = self:GetChallengeSingleData()
                local count = challengeData:GetRecordingFeatureCount()

                progress = XUiHelper.GetText("BossSingleProgress", count, 2)
            end
        else
            if self:IsInLevelTypeChooseAble() then
                progress = XUiHelper.GetText("BossSingleProgressChooseable")
            else
                local allCount = self:GetChallengeCount()
                local bossSingleData = self:GetBossSingleData()
                local challengeCount = bossSingleData:GetBossSingleChallengeCount()

                progress = XUiHelper.GetText("BossSingleProgress", challengeCount, allCount)
            end
        end
    end

    return progress
end

function XFubenBossSingleAgency:ExGetRunningTimeStr()
    if not self:IsBossSingleDataEmpty() then
        local data = self:GetBossSingleData()
        local remainTime = data:GetBossSingleEndTime() - XTime.GetServerNowTimestamp()
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)

        return XUiHelper.GetText("BossSingleLeftTimeIcon", timeText)
    end

    return ""
end

function XFubenBossSingleAgency:ExCheckIsFinished(cb)
    local result = true
    local data = self:GetBossSingleData()
    local isLocked = self:ExGetIsLocked()

    if isLocked then
        result = false
    else
        if self:IsInLevelTypeChooseAble() then
            ---未选区状态
            result = false
        elseif self:IsInLevelTypeExtreme() then
            local conditions = {
                "CONDITION_BOSS_SINGLE_REWARD",
            }
            local isCouldChallenge = data:GetBossSingleChallengeCount() < self:GetChallengeCount()
            local isAllPass = self:CheckAllPassed()
            local isChallengeLevelFinished = self:CheckChallengeFinished()
            local isHasReward = XRedPointManager.CheckConditions(conditions)

            if data:CheckHasChallengeData() then
                ---终极区解锁凹分区(挑战次数用尽 or 所有关卡通关) 并且所有奖励已经领取， 且凹分区有两个计分关卡
                if (isCouldChallenge and not isAllPass) or isHasReward or not isChallengeLevelFinished then
                    result = false
                end
            else
                ---终极区未解锁凹分区(挑战次数用尽 or 所有关卡通关) 并且所有奖励已经领取
                if (isCouldChallenge and not isAllPass) or isHasReward then
                    result = false
                end
            end
        else
            local conditions = {
                "CONDITION_BOSS_SINGLE_REWARD",
            }
            local isCouldChallenge = data:GetBossSingleChallengeCount() < self:GetChallengeCount()
            local isAllPass = self:CheckAllPassed()
            local isHasReward = XRedPointManager.CheckConditions(conditions)

            ---非终极区(挑战次数用尽 or 所有关卡通关) 并且所有奖励已经领取
            if (isCouldChallenge and not isAllPass) or isHasReward then
                result = false
            end
        end
    end

    if cb then
        cb(false)
    end

    self.IsClear = result

    return result
end

function XFubenBossSingleAgency:ExOpenMainUi()
    local exCfg = self:ExGetConfig()

    if not exCfg or not XTool.IsNumberValid(exCfg.SkipId) then
        if XMain.IsEditorDebug then
            XLog.Error('幻痛囚笼入口配置SkipId为空，不通过通用跳转进入')
        end

        if XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
            if self:IsInLevelTypeChooseAble() then
                self:OpenChooseUi()
                return
            end

            self:OpenBossSingleView()
        end
    else
        XFubenSimulationChallengeAgency.ExOpenMainUi(self)
    end
end

--- 获取倒计时(周历专用)
function XFubenBossSingleAgency:ExGetCalendarRemainingTime()
    local data = self:GetBossSingleData()
    local endTime = data:GetBossSingleEndTime()

    if not XTool.IsNumberValid(endTime) then
        return ""
    end

    local remainTime = endTime - XTime.GetServerNowTimestamp()

    if remainTime < 0 then
        remainTime = 0
    end

    local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)

    return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
end

--- 获取解锁时间(周历专用)
function XFubenBossSingleAgency:ExGetCalendarEndTime()
    local data = self:GetBossSingleData()
    local endTime = data:GetBossSingleEndTime()

    if not XTool.IsNumberValid(endTime) then
        return 0
    end

    return endTime
end

--- 是否在周历里显示
function XFubenBossSingleAgency:ExCheckShowInCalendar()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenChallengeBossSingle, nil, true) then
        return false
    end

    local data = self:GetBossSingleData()
    local endTime = data:GetBossSingleEndTime()

    if not XTool.IsNumberValid(endTime) then
        return false
    end
    if endTime - XTime.GetServerNowTimestamp() <= 0 then
        return false
    end
    if XTool.IsNumberValid(data:GetBossSingleActivityNo()) then
        return true
    end

    return false
end

--- 是否显示提示信息(周历专用)
function XFubenBossSingleAgency:ExCheckWeekIsShowTips()
    if self:IsInLevelTypeChooseAble() then
        return true
    end

    return false
end

-- endregion

-- region 战斗接口

--function XFubenBossSingleAgency:InitStageInfo()
--    local sectionConfigs = self._Model:GetBossSingleSectionConfigs()
--
--    for _, sectionCfg in pairs(sectionConfigs) do
--        for i = 1, #sectionCfg.StageId do
--            local bossStageCfg = self._Model:GetBossSingleStageConfigByStageId(sectionCfg.StageId[i])
--            local stageInfo = XMVCA.XFuben:GetStageInfo(bossStageCfg.StageId)
--
--            stageInfo.BossSectionId = sectionCfg.SectionId
--            stageInfo.Type = XEnumConst.FuBen.StageType.BossSingle
--        end
--    end
--end

function XFubenBossSingleAgency:GetBossSectionId(stageId)
    local sectionConfigs = self._Model:GetBossSingleSectionConfigs()

    for _, sectionCfg in pairs(sectionConfigs) do
        for i = 1, #sectionCfg.StageId do
            local bossStageCfg = self._Model:GetBossSingleStageConfigByStageId(sectionCfg.StageId[i])
            if bossStageCfg.StageId == stageId then
                return sectionCfg.SectionId
            end
        end
    end
end

function XFubenBossSingleAgency:CheckPreFight(stage)
    if self._Model:GetFightStageType() == XEnumConst.BossSingle.StageType.Challenge then
        return true
    end

    -- 重置后，不限挑战次数
    local stageId = stage.StageId
    if self._Model:IsResetOpen() then
        if XMVCA.XFuben:CheckStageIsPass(stageId) then
            return true
        end
    end

    local curCount = self:GetBossSingleData():GetBossSingleChallengeCount()
    local allCount = self:GetChallengeCount()

    if allCount - curCount <= 0 and not self:IsBossSingleTrial() then
        local msg = CS.XTextManager.GetText("FubenChallengeCountNotEnough")

        XUiManager.TipMsg(msg)

        return false
    end

    return true
end

function XFubenBossSingleAgency:PreFight(stage, teamId, isAssist, challengeCount, challengeId)
    -- v4.2 获取当前buff对应的选中可选词缀ID列表
    local selectedFeatureIds = {}
    -- v4.5 可选词缀组
    local buffGroup = nil
    if self._Model then
        local currentBuffFeatureId = self._Model:GetCurrentFeatureId()
        if currentBuffFeatureId and currentBuffFeatureId > 0 then
            selectedFeatureIds = self._Model:GetSelectedSelectableFeatureIds(currentBuffFeatureId) or {}
        end

        buffGroup = self._Model:GetBossSingleChallengeBuffGroup()
    end

    local preFight = {
        CardIds = {},
        StageId = stage.StageId,
        IsHasAssist = isAssist and true or false,
        ChallengeCount = challengeCount or 1,
        BossSingleStageType = self._Model:GetFightStageType(),
        -- v4.2 新增可选词缀：传入选中的可选词缀ID列表
        -- BossSingleChallengeBuffIds = selectedFeatureIds,
        -- v4.5 可选词缀组
        BossSingleChallengeBuffGroup = buffGroup
    }

    -- 如果有试玩角色，则不读取玩家队伍信息
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for _, v in pairs(teamData) do
            table.insert(preFight.CardIds, v)
        end
        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        
        -- 如果是普通区，保存编队到服务端
        local bossSingleStageType = self._Model:GetFightStageType()
        if bossSingleStageType == XEnumConst.BossSingle.StageType.Normal then
            local bossId = self:GetBossSectionId(stage.StageId)
            if bossId then
                -- 提取角色ID列表（排除0和机器人）
                local characterIds = {}
                for _, entityId in ipairs(teamData) do
                    if entityId ~= 0 and not XRobotManager.CheckIsRobotId(entityId) then
                        table.insert(characterIds, entityId)
                    end
                end
                
                if #characterIds > 0 then
                    self:SaveNormalStageTeamInfo(bossId, characterIds)
                end
            end
        end
    end

    return preFight
end

--- 战斗结束处理（参考 XFubenAgency:FinishFight 和 XTransfiniteManager 流程）
---@param settle table 结算数据
function XFubenBossSingleAgency:FinishFight(settle)
    if settle.IsWin then
        self:ChallengeWin(settle)
    else
        self:ChallengeLose(settle)
    end
end

--- 战斗胜利处理（参考 XFubenAgency:ChallengeWin）
---@param settleData table 结算数据
function XFubenBossSingleAgency:ChallengeWin(settleData)
    local beginData = XMVCA.XFuben:GetFightBeginData()
    local winData = XMVCA.XFuben:GetChallengeWinData(beginData, settleData)
    local stage = XMVCA.XFuben:GetStageCfg(settleData.StageId)
    local endStoryId = XMVCA.XFuben:GetEndStoryId(settleData.StageId)
    local isKeepPlayingStory = stage and XMVCA.XFuben:IsKeepPlayingStory(stage.StageId)
    local isNotPass = stage and beginData and not beginData.LastPassed

    if endStoryId and (isKeepPlayingStory or isNotPass) then
        -- 播放剧情
        CsXUiManager.Instance:SetRevertAndReleaseLock(true)
        XDataCenter.MovieManager.PlayMovie(endStoryId, function()
            -- 弹出结算
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
            XLuaAudioManager.StopCurrentBGM()
            -- self:ShowReward(winData, true)
        end, nil, nil, nil, nil, nil, settleData.StageId)
    else
        -- 弹出结算
        -- self:ShowReward(winData, false)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
end

--- 战斗失败处理（参考 XFubenAgency:ChallengeLose）
---@param settleData table 结算数据
function XFubenBossSingleAgency:ChallengeLose(settleData)
    XMVCA.XFuben:ChallengeLose(settleData)
end

--- 显示结算界面（私有函数，参考 XTransfiniteManager._ShowReward）
---@param winData table 胜利数据
function XFubenBossSingleAgency:_ShowReward(winData)
    -- 检查强制退出（参考 XTransfiniteManager.ShowResult）
    if self:CheckForceExit(true) then
        return
    end

    if XMain.IsEditorDebug then
        self._DebugWinData = winData
    end

    self._FightSettleDataCache = winData
end

function XFubenBossSingleAgency:OnBehaviorDoExitFight(event, args)
    if not args or args.Length <= 0 then
        return
    end

    -- C#数组，从0开始
    local stageId = args[0]


    -- 检查是否是 BossSingle 的关卡
    if not self:IsBossSingleStage(stageId) then
        return
    end

    self:_OpenRewardUi(self._FightSettleDataCache)
    self._FightSettleDataCache = nil
end

function XFubenBossSingleAgency:_OpenRewardUi(winData)
    XMVCA.XFuben:SetMouseVisible()
    
    if XMVCA.XFuben:CheckHasFlopReward(winData) then
        XLuaUiManager.Open("UiFubenFlopReward", function()
            XLuaUiManager.PopThenOpen("UiFubenBossSingleSettlement", winData)
        end, winData)
    else
        XLuaUiManager.Open("UiFubenBossSingleSettlement", winData)
    end
end

--- 为独立判断普通囚笼和体验囚笼的Stage解锁增加的Handler（参考 XTransfiniteManager，对应 ProcessFunc.CheckUnlockByStageId）
function XFubenBossSingleAgency:CheckUnlockByStageId(stageId)
    if self:IsBossSingleTrial() then
        return true
    end
    -- 普通模式返回 nil，使用默认逻辑
    return nil
end

--- 检查是否自动退出战斗（参考 XTransfiniteManager.CheckAutoExitFight，对应 ProcessFunc.CheckAutoExitFight）
---@param stageId number 关卡ID
---@return boolean 是否自动退出
function XFubenBossSingleAgency:CheckAutoExitFight(stageId)
    -- BossSingle 不需要自动退出战斗
    return false
end

-- endregion

-- region Notify

function XFubenBossSingleAgency:OnNotifyFubenBossSingleData(data)
    self:UpdateBossSingleData(data)
    self._Model:SetChooseAbleBossListMap(data.BossListDict)
    
    -- 初始化普通区编队数据
    if data.FubenBossSingleData and data.FubenBossSingleData.NormalStageTeamInfos then
        self:InitNormalStageTeamInfos(data.FubenBossSingleData.NormalStageTeamInfos)
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC)
    -- 检查强制退出（参考 XTransfiniteManager.InitFromServerData）
    self:CheckForceExit()
end

function XFubenBossSingleAgency:OnNotifyBossSingleRankInfo(data)
    if data.RankType == XEnumConst.BossSingle.RankType.Normal then
        self._Model:UpdateBossSingleSelfRankInfo(data)
    else
        self._Model:UpdateChallengeSelfRankInfo(data)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC)
end

function XFubenBossSingleAgency:OnNotifyBossSingleChallengeCount(data)
    local bossSingleData = self:GetBossSingleData()

    bossSingleData:SetChallengeCount(data.ChallengeCount)
end

---初始化普通区编队数据
---@param normalStageTeamInfos table 服务端返回的编队数据 {{SectionId = int, CharacterIds = {int}}}
function XFubenBossSingleAgency:InitNormalStageTeamInfos(normalStageTeamInfos)
    self._NormalStageTeamInfos = {}
    
    if not normalStageTeamInfos then
        return
    end
    
    for _, teamInfo in ipairs(normalStageTeamInfos) do
        if teamInfo.SectionId and teamInfo.CharacterIds then
            self._NormalStageTeamInfos[teamInfo.SectionId] = {
                SectionId = teamInfo.SectionId,
                CharacterIds = teamInfo.CharacterIds
            }
        end
    end
end

---获取普通区编队数据
---@param sectionId int BOSS章节ID
---@return table|nil 编队数据 {SectionId = int, CharacterIds = {int}}
function XFubenBossSingleAgency:GetNormalStageTeamInfo(sectionId)
    return self._NormalStageTeamInfos[sectionId]
end

---保存普通区编队到本地缓存
---@param sectionId int BOSS章节ID
---@param characterIds table 角色ID列表
---注意：服务端会在 PreFight 时自动保存编队数据，这里只需要更新本地缓存
function XFubenBossSingleAgency:SaveNormalStageTeamInfo(sectionId, characterIds)
    if not sectionId or not characterIds then
        return
    end
    
    -- 更新本地缓存
    self._NormalStageTeamInfos[sectionId] = {
        SectionId = sectionId,
        CharacterIds = characterIds
    }
end

-- endregion

-- region 协议

function XFubenBossSingleAgency:RequestSelfRank(callback, sectionId)
    XNetwork.Call(METHOD_NAME.GetSelfRank, {
        SectionId = sectionId or 0,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateBossSingleSelfRankInfo(res)

        if callback then
            callback()
        end
    end)
end

function XFubenBossSingleAgency:RequestChallengeSelfRank(callback, stageId)
    XNetwork.Call(METHOD_NAME.GetChallengeSelfRank, {
        StageId = stageId or 0,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateChallengeSelfRankInfo(res)

        if callback then
            callback()
        end
    end)
end

-- 自动战斗
function XFubenBossSingleAgency:RequestAutoFight(stagedId, cb)
    local req = {
        StageId = stagedId,
    }

    XNetwork.Call(METHOD_NAME.AutoFight, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.Supply > 0)
        end
    end)
end

function XFubenBossSingleAgency:RequestChooseLevelType(levelType)
    if not levelType then
        return
    end

    local req = {
        LevelId = levelType,
    }
    XNetwork.Call(METHOD_NAME.ChooseLevelType, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:UpdateBossSingleData(res)
        self:OpenBossSingleView()
    end)
end

function XFubenBossSingleAgency:RequestGetRankReward(rewardId, cb)
    local req = {
        Id = rewardId,
    }
    XNetwork.Call(METHOD_NAME.GetReward, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local data = self:GetBossSingleData()

        data:AddBossSingleRewardId(rewardId)

        if cb then
            cb(res.RewardGoodsList)
        end
    end)
end

function XFubenBossSingleAgency:RequestGetAllRankReward(cb)
    XNetwork.Call(METHOD_NAME.GetAllReward, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.RewardGoodsList)
        end
    end)
end

function XFubenBossSingleAgency:RequestRankData(callback, levelType, isForce)
    local now = XTime.GetServerNowTimestamp()

    if not isForce then
        if self._LastSyncServerRankTimes[levelType] and self._LastSyncServerRankTimes[levelType] + self._SyncServerSecond
            > now then
            local rankData = self._Model:GetRankDataCacheByLevelType(levelType)

            if callback then
                if rankData then
                    callback(rankData)
                    return
                end
            else
                return
            end
        end
    end

    local req = {
        Level = levelType,
        SectionId = 0,
    }
    XNetwork.Call(METHOD_NAME.GetRankData, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._LastSyncServerRankTimes[levelType] = now
        self._Model:UpdateRankDataCache(levelType, response)
        if callback then
            callback(self._Model:GetRankDataCacheByLevelType(levelType))
        end
    end)
end

function XFubenBossSingleAgency:RequestBossRankData(callback, levelType, bossId, isForce)
    local now = XTime.GetServerNowTimestamp()

    if not isForce then
        if self._LastSyncServerBossRankTimes[levelType] and self._LastSyncServerBossRankTimes[levelType][bossId]
            and self._LastSyncServerBossRankTimes[levelType][bossId] + self._SyncServerSecond > now then
            local rankData = self._Model:GetBossRankDataCacheByTypeAndBossId(levelType, bossId)

            if callback then
                if rankData then
                    callback(rankData)
                    return
                end
            else
                return
            end
        end
    end

    local req = {
        Level = levelType,
        SectionId = bossId,
    }
    XNetwork.Call(METHOD_NAME.GetRankData, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._LastSyncServerBossRankTimes[levelType] = self._LastSyncServerBossRankTimes[levelType] or {}
        self._LastSyncServerBossRankTimes[levelType][bossId] = now
        self._Model:UpdateBossRankDataCache(levelType, bossId, response)
        if callback then
            callback(self._Model:GetBossRankDataCacheByTypeAndBossId(levelType, bossId))
        end
    end)
end

function XFubenBossSingleAgency:RequestChallengeRankData(callback, stageId)
    local now = XTime.GetServerNowTimestamp()

    stageId = stageId or 0
    if self._LastSyncServerChallengeRankTimes[stageId] and self._LastSyncServerChallengeRankTimes[stageId]
        + self._SyncServerSecond > now then
        local rankData = self._Model:GetChallengeRankDataCacheByStageId(stageId)

        if callback then
            if rankData then
                callback(rankData)
                return
            end
        else
            return
        end
    end

    local req = {
        StageId = stageId,
    }
    XNetwork.Call(METHOD_NAME.GetChallengeRankData, req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end

        self._LastSyncServerChallengeRankTimes[stageId] = now
        self._Model:UpdateChallengeRankDataCache(stageId, response)
        if callback then
            callback(self._Model:GetChallengeRankDataCacheByStageId(stageId))
        end
    end)
end

-- 保存战斗数据
function XFubenBossSingleAgency:RequestSaveScore(stagedId, cb)
    local req = {
        StageId = stagedId,
    }
    XNetwork.Call(METHOD_NAME.SaveScore, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb(res.Supply > 0)
        end
    end)
end

-- endregion

-- 重置
function XFubenBossSingleAgency:BossSingleResetStageRequest(stageId, cb)
    XNetwork.Call(METHOD_NAME.BossSingleResetStageRequest, {
        StageId = stageId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 设置数据
        --XLuaUiManager.Close("UiFubenBossSingleDetail")
        --res.StageRecord
        self:ClearRankData()
    end)
end

--- 检查自动战斗保存
---@return XBossSingleStageHistory
function XFubenBossSingleAgency:CheckAutoFight(stageId)
    local data = self._Model:GetBossSingleData()

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

function XFubenBossSingleAgency:IsInRecordTeam(stageId, characterId)
    local characterList = self:GetCharacterListInRecord(stageId)
    if not characterList then
        return false
    end
    for _, characterIdToFind in pairs(characterList) do
        if characterIdToFind == characterId then
            return true
        end
    end
    return false
end

function XFubenBossSingleAgency:GetCharacterListInRecord(stageId)
    local datas = self._Model:GetRecordCurrent()
    if not datas then
        return
    end
    for i, data in pairs(datas) do
        if data.StageId == stageId then
            return data.Characters
        end
    end
    return
end

--- 获取有效的角色ID列表（过滤掉0值并排序）
---@param ids number[] 角色ID数组
---@return number[] 排序后的有效角色ID数组
function XFubenBossSingleAgency:GetValidCharacterIds(ids)
    local validIds = {}
    for _, id in ipairs(ids) do
        if id and id > 0 then
            table.insert(validIds, id)
        end
    end
    table.sort(validIds)
    return validIds
end

function XFubenBossSingleAgency:CheckTeamDifferentWithRecord(stageId, team)
    if not self._Model:IsResetOpen() then
        return false
    end
    if not team then
        XLog.Error("[XFubenBossSingleAgency] 判断队伍是否发生修改时, 队伍数据为空")
        return false
    end
    local entityIds = team:GetEntityIds()
    local record = self._Model:GetRecordCurrentByStageId(stageId)
    if not record then
        return false
    end
    local characterIdsInRecord = record.Characters --self:GetCharacterListInRecord(stageId)
    if not characterIdsInRecord or #characterIdsInRecord == 0 then
        return false
    end
    
    -- 位置无关的比较：过滤掉0值，排序后比较集合是否相同
    local currentIds = self:GetValidCharacterIds(entityIds)
    local recordIds = self:GetValidCharacterIds(characterIdsInRecord)
    
    -- 比较两个数组的长度
    if #currentIds ~= #recordIds then
        return true
    end
    
    -- 逐个比较排序后的ID
    for i = 1, #currentIds do
        if currentIds[i] ~= recordIds[i] then
            return true
        end
    end
    
    return false
end

function XFubenBossSingleAgency:IsCharacterHasRecord(stageId, characterId)
    local stageRecord = self._Model:GetRecordCurrentByStageId(stageId)
    if stageRecord then
        for _, recordCharacterId in pairs(stageRecord.Characters) do
            if recordCharacterId == characterId then
                return true
            end
        end
    end
    return false
end

function XFubenBossSingleAgency:ClearRankData()
    -- 在重置之后,需要清空排行榜数据
    self._LastSyncServerRankTimes = {}
    self._LastSyncServerBossRankTimes = {}
    self._LastSyncServerChallengeRankTimes = {}
end

function XFubenBossSingleAgency:GetDebugWinData()
    return self._DebugWinData
end

--- 设置UI显示状态（参考 XTransfiniteManager.SetUiShowed）
---@param value boolean
function XFubenBossSingleAgency:SetUiShowed(value)
    self._IsUiShow = value
end

--- 获取UI显示状态（参考 XTransfiniteManager.IsUiShowed）
---@return boolean
function XFubenBossSingleAgency:IsUiShowed()
    return self._IsUiShow
end

--- 退出战斗（参考 XTransfiniteManager.ExitFight）
function XFubenBossSingleAgency:ExitFight()
    CS.XFight.ExitForClient(true)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_HIDE_SETTLE)
end

--- 检查强制退出（参考 XTransfiniteManager.CheckForceExit）
---@param isResult boolean 是否在结算界面
---@return boolean 是否已强制退出
function XFubenBossSingleAgency:CheckForceExit(isResult)
    local bossSingleData = self:GetBossSingleData()
    if not bossSingleData or not bossSingleData:IsForceExit() then
        return false
    end

    if XFightUtil.IsFighting() then
        -- 因为结算时, 使用了战斗结算动作, 作为背景, 所以战斗仍未退出
        if isResult or XLuaUiManager.IsUiShow("UiFubenBossSingleSettlement") then
            self:ExitFight()
        else
            return false
        end
    end

    bossSingleData:ClearForceExit()
    if self:IsUiShowed() then
        XLuaUiManager.RunMain()
        XUiManager.TipText("ActivityMainLineEnd")
    end

    return true
end

--- 处理战斗结算奖励事件（参考 XTransfiniteManager 的 EVENT_FUBEN_SETTLE_REWARD 处理）
---@param settleData table 结算数据
function XFubenBossSingleAgency:OnFightSettle(settleData, res)
    -- 其他副本的战斗也会进这里, 所以需要检查是否是 BossSingle 的关卡
    if not res then
        return
    end

    if not settleData then
        return
    end

    local stageId = settleData.StageId
    if not stageId then
        return
    end

    -- 检查是否是 BossSingle 的关卡
    if not self:IsBossSingleStage(stageId) then
        return
    end
    
    if res.Code ~= XCode.Success then
        XLog.Error("[XFubenBossSingleAgency] 结算结果失败: ", res.Code)
        CS.XFight.ExitForClient(true)
        return
    end

    if settleData.IsWin then
        -- 胜利：显示结算界面（参考 XTransfiniteManager 的实现）
        local beginData = XMVCA.XFuben:GetFightBeginData()
        local winData = XMVCA.XFuben:GetChallengeWinData(beginData, settleData)
        self:_ShowReward(winData)
    else
        -- 失败：退出战斗（使用默认的失败处理）
        -- 注意：这里不直接调用 ChallengeLose，因为 FinishFight 已经处理了失败逻辑
    end
end

return XFubenBossSingleAgency
