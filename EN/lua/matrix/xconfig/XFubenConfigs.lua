local CSXGameClientConfig = CS.XGame.ClientConfig

XFubenConfigs = {}
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============

--对应Stage表的StageType，注意和FubenManager的StageType区分
XFubenConfigs.STAGETYPE_COMMON = 0
XFubenConfigs.STAGETYPE_FIGHT = 1
XFubenConfigs.STAGETYPE_STORY = 2
XFubenConfigs.STAGETYPE_STORYEGG = 3
XFubenConfigs.STAGETYPE_FIGHTEGG = 4

XFubenConfigs.FUBENTYPE_NORMAL = 0
XFubenConfigs.FUBENTYPE_PREQUEL = 1

XFubenConfigs.ROOM_MAX_WORLD = CSXGameClientConfig:GetInt("MultiplayerRoomRowMaxWorld")
XFubenConfigs.ROOM_WORLD_TIME = CSXGameClientConfig:GetInt("MultiplayerRoomWorldTime")

XFubenConfigs.CharacterLimitType = {
    All = 0, --构造体/感染体
    Normal = 1, --构造体
    Isomer = 2, --感染体
    IsomerDebuff = 3, --构造体/感染体(Debuff) [AKA:低浓度区]
    NormalDebuff = 4, --构造体(Debuff)/感染体 [AKA:重灾区]
}

XFubenConfigs.MainLineMoveOpenTime = 0.3
XFubenConfigs.MainLineMoveCloseTime = 0.7
XFubenConfigs.MainLineWaitTime = 500
XFubenConfigs.ExtralLineMoveOpenTime = 0.3
XFubenConfigs.ExtralLineMoveCloseTime = 0.5
XFubenConfigs.ExtralLineWaitTime = 650
XFubenConfigs.DebugOpenOldMainUi = false

XFubenConfigs.AISuggestType = {
    All = 0, -- 无
    Robot = 1, -- 推荐使用角色
}

XFubenConfigs.StepSkipType = {
    SettleLose = 1, -- 失败结算
}

-- Stage表StageGridStyle枚举
XFubenConfigs.StageGridStyle = {
    Square = "Square",
    SquareEx = "SquareEx",
    FwSquare = "FwSquare",
    FwSquareEx = "FwSquareEx",
}

function XFubenConfigs.Init()
end

--function XFubenConfigs.GetAllConfigs()
--    return XMVCA.XFuben:GetStageCfgs()
--end

function XFubenConfigs.GetBuffDes(buffId)
    return XMVCA.XFuben:GetBuffDes(buffId)
end

function XFubenConfigs.GetStageLevelControlCfg()
    return XMVCA.XFuben:GetStageLevelControlCfg()
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfg()
    return XMVCA.XFuben:GetStageMultiplayerLevelControlCfg()
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
    return XMVCA.XFuben:GetStageMultiplayerLevelControlCfgById(id)
end

function XFubenConfigs.GetStageTransformCfg()
    return XMVCA.XFuben:GetStageTransformCfg()
end

function XFubenConfigs.GetFlopRewardTemplates()
    return XMVCA.XFuben:GetFlopRewardTemplates()
end

function XFubenConfigs.GetActivitySortRules()
    return XMVCA.XFuben:GetActivitySortRules()
end

function XFubenConfigs.GetFeaturesById(id)
    return XMVCA.XFuben:GetFeaturesById(id)
end

function XFubenConfigs.GetActivityPriorityByActivityIdAndType(activityId, type)
    return XMVCA.XFuben:GetActivityPriorityByActivityIdAndType(activityId, type)
end

function XFubenConfigs.GetStageFightControl(id)
    return XMVCA.XFuben:GetStageFightControl(id)
end

function XFubenConfigs.IsKeepPlayingStory(stageId)
    return XMVCA.XFuben:IsKeepPlayingStory(stageId)
end

function XFubenConfigs.GetChapterBannerByType(bannerType)
    return XMVCA.XFuben:GetChapterBannerByType(bannerType)
end

function XFubenConfigs.InitNewChallengeConfigs()
    return XMVCA.XFuben:InitNewChallengeConfigs()
end

function XFubenConfigs.GetNewChallengeConfigs()
    -- 获取新挑战玩法数据
    return XMVCA.XFuben:GetNewChallengeConfigs()
end

function XFubenConfigs.GetNewChallengeConfigById(id)
    -- 根据Id取得FubenChallengeBanner配置
    return XMVCA.XFuben:GetNewChallengeConfigById(id)
end

function XFubenConfigs.GetNewChallengeConfigsLength()
    -- 获取新活动数量
    return XMVCA.XFuben:GetNewChallengeConfigsLength()
end

function XFubenConfigs.GetNewChallengeFunctionId(index)
    return XMVCA.XFuben:GetNewChallengeFunctionId(index)
end

function XFubenConfigs.GetNewChallengeId(index)
    -- 根据索引获取新挑战活动的Id
    return XMVCA.XFuben:GetNewChallengeId(index)
end

function XFubenConfigs.GetNewChallengeStartTimeStamp(index)
    return XMVCA.XFuben:GetNewChallengeStartTimeStamp(index)
end

function XFubenConfigs.GetNewChallengeEndTimeStamp(index)
    return XMVCA.XFuben:GetNewChallengeEndTimeStamp(index)
end

function XFubenConfigs.IsNewChallengeStartByIndex(index)
    -- 根据索引获取新挑战时段是否已经开始
    return XMVCA.XFuben:IsNewChallengeStartByIndex(index)
end

function XFubenConfigs.IsNewChallengeStartById(id)
    -- 根据挑战活动Id获取新挑战时段是否已经开始
    return XMVCA.XFuben:IsNewChallengeStartById(id)
end

function XFubenConfigs.GetMultiChallengeStageConfigs()
    return XMVCA.XFuben:GetMultiChallengeStageConfigs()
end

function XFubenConfigs.GetTableStagePath()
    return XMVCA.XFuben:GetTableStagePath()
end

function XFubenConfigs.GetStageCharacterLimitType(stageId)
    return XMVCA.XFuben:GetStageCharacterLimitType(stageId)
end

function XFubenConfigs.GetStageCareerSuggestTypes(stageId)
    return XMVCA.XFuben:GetStageCareerSuggestTypes(stageId)
end

function XFubenConfigs.GetStageAISuggestType(stageId)
    return XMVCA.XFuben:GetStageAISuggestType(stageId)
end

function XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    return XMVCA.XFuben:GetStageCharacterLimitBuffId(stageId)
end

function XFubenConfigs.GetLimitShowBuffId(limitBuffId)
    return XMVCA.XFuben:GetLimitShowBuffId(limitBuffId)
end

function XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType)
    return XMVCA.XFuben:IsStageCharacterLimitConfigExist(characterLimitType)
end

function XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    return XMVCA.XFuben:GetStageCharacterLimitImageTeamEdit(characterLimitType)
end

function XFubenConfigs.GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
    return XMVCA.XFuben:GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
end

function XFubenConfigs.GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
    return XMVCA.XFuben:GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
end

function XFubenConfigs.GetStageCharacterLimitImageSelectCharacter(characterLimitType)
    return XMVCA.XFuben:GetStageCharacterLimitImageSelectCharacter(characterLimitType)
end

function XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
    return XMVCA.XFuben:GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
end

function XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
    return XMVCA.XFuben:GetStageCharacterLimitName(characterLimitType)
end

function XFubenConfigs.GetChapterCharacterLimitText(characterLimitType, buffId)
    return XMVCA.XFuben:GetChapterCharacterLimitText(characterLimitType, buffId)
end

function XFubenConfigs.IsCharacterFitTeamBuff(teamBuffId, characterId)
    return XMVCA.XFuben:IsCharacterFitTeamBuff(teamBuffId, characterId)
end

function XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    return XMVCA.XFuben:GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
end

function XFubenConfigs.GetTeamBuffMaxBuffCount(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffMaxBuffCount(teamBuffId)
end

function XFubenConfigs.GetTeamBuffOnIcon(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffOnIcon(teamBuffId)
end

function XFubenConfigs.GetTeamBuffOffIcon(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffOffIcon(teamBuffId)
end

function XFubenConfigs.GetTeamBuffTitle(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffTitle(teamBuffId)
end

function XFubenConfigs.GetTeamBuffDesc(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffDesc(teamBuffId)
end

function XFubenConfigs.GetTeamBuffShowBuffId(teamBuffId, characterIds)
    return XMVCA.XFuben:GetTeamBuffShowBuffId(teamBuffId, characterIds)
end

function XFubenConfigs.GetStageFightEventByStageId(stageId)
    return XMVCA.XFuben:GetStageFightEventByStageId(stageId)
end

function XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
    return XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(eventId)
end

function XFubenConfigs.GetTipDescList(settleLoseTipId)
    return XMVCA.XFuben:GetTipDescList(settleLoseTipId)
end

function XFubenConfigs.GetSkipIdList(settleLoseTipId)
    return XMVCA.XFuben:GetSkipIdList(settleLoseTipId)
end

function XFubenConfigs.GetStageRecommendCharacterType(stageId)
    return XMVCA.XFuben:GetStageRecommendCharacterType(stageId)
end

function XFubenConfigs.GetStageRecommendCharacterElement(stageId)
    return XMVCA.XFuben:GetStageRecommendCharacterElement(stageId)
end

function XFubenConfigs.IsStageRecommendCharacterType(stageId, id)
    return XMVCA.XFuben:IsStageRecommendCharacterType(stageId, id)
end

function XFubenConfigs.GetStageName(stageId, ignoreError)
    return XMVCA.XFuben:GetStageName(stageId, ignoreError)
end

function XFubenConfigs.GetStageDescription(stageId, ignoreError)
    return XMVCA.XFuben:GetStageDescription(stageId, ignoreError)
end

function XFubenConfigs.GetStageMainlineType(stageId)
    return XMVCA.XFuben:GetStageMainlineType(stageId)
end

function XFubenConfigs.GetStageIcon(stageId)
    return XMVCA.XFuben:GetStageIcon(stageId)
end

function XFubenConfigs.GetStarDesc(stageId)
    return XMVCA.XFuben:GetStarDesc(stageId)
end

function XFubenConfigs.GetFirstRewardShow(stageId)
    return XMVCA.XFuben:GetFirstRewardShow(stageId)
end

function XFubenConfigs.GetFinishRewardShow(stageId)
    return XMVCA.XFuben:GetFinishRewardShow(stageId)
end

function XFubenConfigs.GetBeginStoryId(stageId)
    return XMVCA.XFuben:GetBeginStoryId(stageId)
end

function XFubenConfigs.GetEndStoryId(stageId)
    return XMVCA.XFuben:GetEndStoryId(stageId)
end

function XFubenConfigs.GetPreStageId(stageId)
    return XMVCA.XFuben:GetPreStageId(stageId)
end

function XFubenConfigs.GetStageTypeCfg(stageId)
    return XMVCA.XFuben:GetStageTypeCfg(stageId)
end

function XFubenConfigs.GetStageTypeRobot(stageType)
    return XMVCA.XFuben:GetStageTypeRobot(stageType)
end

function XFubenConfigs.GetStageRobotIdList(stageId, ignoreError)
    return XMVCA.XFuben:GetStageRobotIdList(stageId, ignoreError)
end

function XFubenConfigs.IsAllowRepeatChar(stageType)
    return XMVCA.XFuben:IsAllowRepeatChar(stageType)
end

function XFubenConfigs.GetCharacterLimitBuffDic(limitType)
    return XMVCA.XFuben:GetCharacterLimitBuffDic(limitType)
end

function XFubenConfigs.GetStepSkipListByStageId(stageId)
    return XMVCA.XFuben:GetStepSkipListByStageId(stageId)
end

function XFubenConfigs.CheckStepIsSkip(stageId, stepSkipType)
    return XMVCA.XFuben:CheckStepIsSkip(stageId, stepSkipType)
end

function XFubenConfigs.HasStageGamePlayDesc(stageType)
    return XMVCA.XFuben:HasStageGamePlayDesc(stageType)
end

function XFubenConfigs.GetStageGamePlayBtnVisible(stageType)
    return XMVCA.XFuben:GetStageGamePlayBtnVisible(stageType)
end

function XFubenConfigs.GetStageGamePlayTitle(stageType)
    return XMVCA.XFuben:GetStageGamePlayTitle(stageType)
end

function XFubenConfigs.GetStageGamePlayDescDataSource(stageType)
    return XMVCA.XFuben:GetStageGamePlayDescDataSource(stageType)
end

function XFubenConfigs.GetFubenActivityConfigByManagerName(managerName)
    return XMVCA.XFuben:GetFubenActivityConfigByManagerName(managerName)
end

---@return XTableFubenSecondTag[]
function XFubenConfigs.GetSecondTagConfigsByFirstTagId(firstTagId)
    return XMVCA.XFuben:GetSecondTagConfigsByFirstTagId(firstTagId)
end

function XFubenConfigs.GetSecondTagConfigById(id)
    return XMVCA.XFuben:GetSecondTagConfigById(id)
end

function XFubenConfigs.GetCollegeChapterBannerByType(chapterType)
    return XMVCA.XFuben:GetCollegeChapterBannerByType(chapterType)
end

function XFubenConfigs.GetActivityPanelPrefabPath()
    return XMVCA.XFuben:GetActivityPanelPrefabPath()
end

function XFubenConfigs.GetMainPanelTimeId()
    return XMVCA.XFuben:GetMainPanelTimeId()
end

function XFubenConfigs.GetMainFestivalBg()
    -- 覆盖其他二级标签的活动背景图
    return XMVCA.XFuben:GetMainFestivalBg()
end

function XFubenConfigs.GetMainPanelItemId()
    return XMVCA.XFuben:GetMainPanelItemId()
end

function XFubenConfigs.GetMainPanelName()
    return XMVCA.XFuben:GetMainPanelName()
end

function XFubenConfigs.GetMain3DBgPrefab()
    return XMVCA.XFuben:GetMain3DBgPrefab()
end

function XFubenConfigs.GetMain3DCameraPrefab()
    return XMVCA.XFuben:GetMain3DCameraPrefab()
end

function XFubenConfigs.GetMainVideoBgUrl()
    return XMVCA.XFuben:GetMainVideoBgUrl()
end

function XFubenConfigs.GetStageSettleWinSoundId()
    return XMVCA.XFuben:GetStageSettleWinSoundId()
end

function XFubenConfigs.GetStageSettleLoseSoundId()
    return XMVCA.XFuben:GetStageSettleLoseSoundId()
end

function XFubenConfigs.GetQxmsTryIcon()
    return XMVCA.XFuben:GetQxmsTryIcon()
end

function XFubenConfigs.GetQxmsUseIcon()
    return XMVCA.XFuben:GetQxmsUseIcon()
end

function XFubenConfigs.GetChallengeShowGridCount()
    return XMVCA.XFuben:GetChallengeShowGridCount()
end

function XFubenConfigs.GetChallengeShowGridList()
    return XMVCA.XFuben:GetChallengeShowGridList()
end

function XFubenConfigs.GetChallengeGridShowConditionList()
    return XMVCA.XFuben:GetChallengeGridShowConditionList()
end

function XFubenConfigs.GetIsMainHave3DBg()
    return XMVCA.XFuben:GetIsMainHave3DBg()
end

function XFubenConfigs.GetIsMainHaveVideoBg()
    return XMVCA.XFuben:GetIsMainHaveVideoBg()
end

function XFubenConfigs.GetSettleSpecialSoundCfgByStageId(stageId)
    return XMVCA.XFuben:GetSettleSpecialSoundCfgByStageId(stageId)
end
-- abandon ~~~~~~~~~~~~~~~~~
-- 此文件即将被抛弃