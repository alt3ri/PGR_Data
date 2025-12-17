-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey =
{
    RpgMakerGameActivity = { CacheType = XConfigUtil.CacheType.Normal },
    RpgMakerGameChapter = { CacheType = XConfigUtil.CacheType.Normal },
    RpgMakerGameChapterGroup = { CacheType = XConfigUtil.CacheType.Normal },
    RpgMakerGameStage = { CacheType = XConfigUtil.CacheType.Normal },
    RpgMakerGameStarCondition = { CacheType = XConfigUtil.CacheType.Normal },
    RpgMakerGameRole = {},
    RpgMakerGameMap = {},
    RpgMakerGameMonster = {},
    RpgMakerGameTrigger = {},
    RpgMakerGameMixBlock = {},
    RpgMakerGameSkillType = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SkillType" },
    RpgMakerGameHintIcon = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    RpgMakerGameRandomDialogBox = { DirPath = XConfigUtil.DirectoryType.Client },
    RpgMakerGameHintDialogBox = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "StageId" },
    RpgMakerGameModel = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    RpgMakerGameAnimation = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "ModelName", ReadFunc = XConfigUtil.ReadType.String },
    RpgMakerGamePlayMainDownHint = { DirPath = XConfigUtil.DirectoryType.Client },
    RpgMakerGameHintLine = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "MapId" },
    RpgMakerGameDeathTitle = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type" },
}

local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs

-- 玩法配置表读取
---@class XRpgMakerGameConfig
local XRpgMakerGameConfig = XClass(nil, "XRpgMakerGameConfig")

function XRpgMakerGameConfig:Ctor(configUtil)
    self._ConfigUtil = configUtil
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/RpgMakerGame", TableKey)
end

function XRpgMakerGameConfig:OnInit()
    
end

-- 退出玩法清理内部数据
function XRpgMakerGameConfig:ClearPrivate()
    
end

-- 重登清理数据
function XRpgMakerGameConfig:ResetAll()
    self.ChapterGroupIdList = nil
    self.ChapterGroupToChapterIdList = nil
    self.DefaultChapterGroupId = nil

    self.MixBlockInMapDic = nil
    self.MixBlockTypeMapDic = nil
end

--region RpgMakerGameActivity
function XRpgMakerGameConfig:GetConfigActivity(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameActivity, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameActivity)
    end
end

function XRpgMakerGameConfig:GetDefaultActivityId()
    local defaultActivityId = 1
    local configs = self:GetConfigActivity()
    for activityId, config in pairs(configs) do
        if XTool.IsNumberValid(config.ActivityTimeId) then
            DefaultActivityId = activityId
            break
        end
        defaultActivityId = activityId
    end
    return defaultActivityId
end

function XRpgMakerGameConfig:GetActivityTaskTimeLimitId(id)
    local config = self:GetConfigActivity(id)
    return config.TaskTimeLimitId
end

function XRpgMakerGameConfig:GetActivityTimeId(id)
    local config = self:GetConfigActivity(id)
    return config.TimeId
end

function XRpgMakerGameConfig:GetActivityName(id)
    local config = self:GetConfigActivity(id)
    return config.Name
end

function XRpgMakerGameConfig:GetActivityBannerBg(id)
    local config = self:GetConfigActivity(id)
    return config.BannerBg
end

function XRpgMakerGameConfig:GetActivityCollectionIcon(id)
    local config = self:GetConfigActivity(id)
    return config.CollectionIcon
end

function XRpgMakerGameConfig:GetActivityGuideMoveDirection(id)
    id = id or self:GetDefaultActivityId()
    local config = self:GetConfigActivity(id)
    return config.GuideMoveDirection
end
--endregion

--region RpgMakerGameChapter
function XRpgMakerGameConfig:GetConfigChapter(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameChapter, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameChapter)
    end
end

function XRpgMakerGameConfig:GetChapterOpenTimeId(id)
    local config = self:GetConfigChapter(id)
    return config.OpenTimeId
end

function XRpgMakerGameConfig:GetChapterName(id)
    local config = self:GetConfigChapter(id)
    return config.Name
end

function XRpgMakerGameConfig:GetChapterTagBtnBG(id)
    local config = self:GetConfigChapter(id)
    return config.TagBtnBG
end

function XRpgMakerGameConfig:GetChapterPreChapterId(id)
    local config = self:GetConfigChapter(id)
    return config.PreChapterId
end

function XRpgMakerGameConfig:GetChapterPrefab(id)
    local config = self:GetConfigChapter(id)
    return config.Prefab
end
--endregion

--region RpgMakerGameStage
function XRpgMakerGameConfig:GetConfigStage(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameStage, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameStage)
    end
end

function XRpgMakerGameConfig:GetStageChapterId(id)
    local config = self:GetConfigStage(id)
    return config.ChapterId
end

function XRpgMakerGameConfig:GetStagePreStage(id)
    local config = self:GetConfigStage(id)
    return config.PreStage
end

function XRpgMakerGameConfig:GetStageBG(id)
    local config = self:GetConfigStage(id)
    return config.BG
end

function XRpgMakerGameConfig:GetStagePrefab(id)
    local config = self:GetConfigStage(id)
    return config.Prefab
end

function XRpgMakerGameConfig:GetStageName(id)
    local config = self:GetConfigStage(id)
    return config.Name or ""
end

function XRpgMakerGameConfig:GetStageStageHint(id)
    local config = self:GetConfigStage(id)
    return config.StageHint or ""
end

function XRpgMakerGameConfig:GetStageLoseHint(id)
    local config = self:GetConfigStage(id)
    return config.LoseHint or ""
end

function XRpgMakerGameConfig:GetStageNumberName(id)
    local config = self:GetConfigStage(id)
    return config.NumberName or ""
end

function XRpgMakerGameConfig:GetStageHintCost(id)
    local config = self:GetConfigStage(id)
    return config.HintCost
end

function XRpgMakerGameConfig:GetStageAnswerCost(id)
    local config = self:GetConfigStage(id)
    return config.AnswerCost
end

function XRpgMakerGameConfig:GetStageMapId(id)
    local config = self:GetConfigStage(id)
    return config.MapId
end

function XRpgMakerGameConfig:GetStageUseRoleId(id)
    local config = self:GetConfigStage(id)
    return config.UseRoleId
end

function XRpgMakerGameConfig:GetStageShadowId(id)
    local config = self:GetConfigStage(id)
    return config.ShadowId
end

function XRpgMakerGameConfig:GetAllStageIds()
    local stageIds = {}
    local stageConfigs = self:GetConfigStage()
    for _, stageConfig in pairs(stageConfigs) do
        tableInsert(stageIds, stageConfig.Id)
    end
    return stageIds
end

-- 获取章节关卡列表
function XRpgMakerGameConfig:GetChapterStageIds(chapterId)
    local stageIds = {}
    local stageConfigs = self:GetConfigStage()
    for _, stageCfg in pairs(stageConfigs) do
        if stageCfg.ChapterId == chapterId then
            tableInsert(stageIds, stageCfg.Id)
        end
    end
    tableSort(stageIds, function(a, b)
        return a < b
    end)
    return stageIds
end

---@return number 下一关的StageId
---@return boolean 是否是跨章节
function XRpgMakerGameConfig:GetRpgMakerGameNextStageId(currStageId)
    local chapterId = self:GetStageChapterId(currStageId)
    local stageIdList = self:GetChapterStageIds(chapterId)
    for i, stageId in ipairs(stageIdList) do
        if stageId == currStageId and stageIdList[i + 1] then
            return stageIdList[i + 1]
        end
    end

    local nextChapterId = self:GetNextChapterId(chapterId)
    if nextChapterId then
        local nextStageIdList = self:GetChapterStageIds(nextChapterId)
        return nextStageIdList[1], true
    end
end
--endregion

--region RpgMakerGameStarCondition
function XRpgMakerGameConfig:GetConfigStarCondition(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameStarCondition, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameStarCondition)
    end
end

function XRpgMakerGameConfig:GetStarConditionStar(id)
    local config = self:GetConfigStarCondition(id)
    return config.Star
end

function XRpgMakerGameConfig:GetStarConditionStepCount(id)
    local config = self:GetConfigStarCondition(id)
    return config.StepCount
end

function XRpgMakerGameConfig:GetStarConditionMonsterCount(id)
    local config = self:GetConfigStarCondition(id)
    return config.MonsterCount
end

function XRpgMakerGameConfig:GetStarConditionMonsterBossCount(id)
    local config = self:GetConfigStarCondition(id)
    return config.MonsterBossCount or 0
end

function XRpgMakerGameConfig:GetStarConditionDesc(id)
    local config = self:GetConfigStarCondition(id)
    return config.ConditionDesc
end

function XRpgMakerGameConfig:GetStarConditionDropType(id)
    local config = self:GetConfigStarCondition(id)
    return config.DropType
end

function XRpgMakerGameConfig:GetStarConditionDropCount(id)
    local config = self:GetConfigStarCondition(id)
    return config.DropCount
end

function XRpgMakerGameConfig:GetStarConditionReward(id)
    local config = self:GetConfigStarCondition(id)
    return config.Reward
end

function XRpgMakerGameConfig:GetStageStarConditionIds(stageId)
    local ids = {}
    local starConfigs = self:GetConfigStarCondition()
    for _, starCfg in pairs(starConfigs) do
        if stageId == starCfg.StageId then
            tableInsert(ids, starCfg.Id)
        end
    end
    tableSort(ids, function(a, b)
        return a < b
    end)
    return ids
end

function XRpgMakerGameConfig:GetChapterTotalStar(chapterId)
    local stageIdList = self:GetChapterStageIds(chapterId)
    local starConditionIdList
    local totalStarCount = 0
    for _, stageId in ipairs(stageIdList) do
        starConditionIdList = self:GetStageStarConditionIds(stageId)
        for _, starConditionId in ipairs(starConditionIdList) do
            totalStarCount = totalStarCount + self:GetStarConditionStar(starConditionId)
        end
    end
    return totalStarCount
end

function XRpgMakerGameConfig:GetStageTotalStar(stageId)
    local starConditionIdList = self:GetStageStarConditionIds(stageId)
    local totalCount = 0
    for _, starConditionId in ipairs(starConditionIdList) do
        totalCount = totalCount + self:GetStarConditionStar(starConditionId)
    end
    return totalCount
end
--endregion

--region RpgMakerGameRole
function XRpgMakerGameConfig:GetConfigRole(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameRole, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameRole)
    end
end

function XRpgMakerGameConfig:GetRoleUnlockChapterId(id)
    local config = self:GetConfigRole(id)
    return config.UnlockChapterId
end

function XRpgMakerGameConfig:GetRoleName(id)
    local config = self:GetConfigRole(id)
    return config.Name or ""
end

function XRpgMakerGameConfig:GetRoleStyle(id)
    local config = self:GetConfigRole(id)
    return config.Style or ""
end

-- 获取第一个SkillType
function XRpgMakerGameConfig:GetRoleSkillType(id)
    local skillTypes = self:GetRoleSkillTypes(id)
    return skillTypes and skillTypes[1] or nil
end

-- 获取初始SkillTypes
function XRpgMakerGameConfig:GetRoleInitSkillTypes(id)
    local skillTypes = self:GetRoleSkillTypes(id)
    return skillTypes and { skillTypes[1] } or {}
end

function XRpgMakerGameConfig:GetRoleSkillTypes(id)
    local config = self:GetConfigRole(id)
    return config.SkillTypes
end

function XRpgMakerGameConfig:GetRoleModelAssetPath(id)
    local config = self:GetConfigRole(id)
    return config.ModelAssetPath
end

function XRpgMakerGameConfig:GetRoleInfoName(id)
    local config = self:GetConfigRole(id)
    return config.InfoName or ""
end

function XRpgMakerGameConfig:GetRoleInfo(id)
    local config = self:GetConfigRole(id)
    return config.Info or ""
end

function XRpgMakerGameConfig:GetRoleType(id)
    local config = self:GetConfigRole(id)
    return config.RoleType or 0
end

function XRpgMakerGameConfig:GetRoleHeadPath(id)
    local config = self:GetConfigRole(id)
    return config.HeadPath
end

function XRpgMakerGameConfig:GetRoleLockTipsDesc(id)
    local config = self:GetConfigRole(id)
    return config.LockTipsDesc or ""
end

function XRpgMakerGameConfig:GetRoleSkillTypeDesc(id, index)
    local config = self:GetConfigRole(id)
    return config.SkillTypeDescs and config.SkillTypeDescs[index]
end

function XRpgMakerGameConfig:GetRoleSkillTypeIconBefore(id, index)
    local config = self:GetConfigRole(id)
    return config.SkillTypeIconBefores and config.SkillTypeIconBefores[index]
end

function XRpgMakerGameConfig:GetRoleSkillTypeIconAfter(id, index)
    local config = self:GetConfigRole(id)
    return config.SkillTypeIconAfters and config.SkillTypeIconAfters[index]
end

function XRpgMakerGameConfig:GetRoleIds()
    local roleIds = {}
    local roleConfigs = self:GetConfigRole()
    for _, roleConfig in pairs(roleConfigs) do
        tableInsert(roleIds, roleConfig.Id)
    end
    tableSort(roleIds, function(a, b)
        if roleConfigs[a].RoleOrder ~= roleConfigs[b].RoleOrder then
            return roleConfigs[a].RoleOrder < roleConfigs[b].RoleOrder
        end
        return a < b
    end)
    return roleIds
end
--endregion

--region RpgMakerGameMap
function XRpgMakerGameConfig:GetConfigMap(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameMap, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameMap)
    end
end

function XRpgMakerGameConfig:GetMapPrefab(id)
    local config = self:GetConfigMap(id)
    return config.Prefab
end

function XRpgMakerGameConfig:GetMapMaxRound(id)
    local config = self:GetConfigMap(id)
    return config.MaxRound
end

function XRpgMakerGameConfig:GetMapStartPointId(id)
    local config = self:GetConfigMap(id)
    return config.StartPointId
end

function XRpgMakerGameConfig:GetMapEndPointId(id)
    local config = self:GetConfigMap(id)
    return config.EndPointId
end

--行
function XRpgMakerGameConfig:GetMapRow(id)
    local config = self:GetConfigMap(id)
    return config.Row
end

--列
function XRpgMakerGameConfig:GetMapCol(id)
    local config = self:GetConfigMap(id)
    return config.Col
end
--endregion

--region RpgMakerGameMonster
function XRpgMakerGameConfig:GetConfigMonster(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameMonster, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameMonster)
    end
end

function XRpgMakerGameConfig:GetMonsterType(id)
    local config = self:GetConfigMonster(id)
    return config.Type
end

function XRpgMakerGameConfig:GetMonsterSkillType(id)
    local config = self:GetConfigMonster(id)
    return config.SkillType
end

function XRpgMakerGameConfig:GetMonsterInitSkillTypes(id)
    local skillType = self:GetMonsterSkillType(id)
    return XTool.IsNumberValid(skillType) and { skillType } or {}
end

function XRpgMakerGameConfig:GetMonsterX(id)
    local config = self:GetConfigMonster(id)
    return config.X
end

function XRpgMakerGameConfig:GetMonsterY(id)
    local config = self:GetConfigMonster(id)
    return config.Y
end

function XRpgMakerGameConfig:GetMonsterDirection(id)
    local config = self:GetConfigMonster(id)
    return config.Direction
end

function XRpgMakerGameConfig:GetMonsterViewFront(id)
    local config = self:GetConfigMonster(id)
    return config.ViewFront
end

function XRpgMakerGameConfig:GetMonsterViewBack(id)
    local config = self:GetConfigMonster(id)
    return config.ViewBack
end

function XRpgMakerGameConfig:GetMonsterViewLeft(id)
    local config = self:GetConfigMonster(id)
    return config.ViewLeft
end

function XRpgMakerGameConfig:GetMonsterViewRight(id)
    local config = self:GetConfigMonster(id)
    return config.ViewRight
end

function XRpgMakerGameConfig:GetMonsterSentryFront(id)
    local config = self:GetConfigMonster(id)
    return config.SentryFront
end

function XRpgMakerGameConfig:GetMonsterSentryBack(id)
    local config = self:GetConfigMonster(id)
    return config.SentryBack
end

function XRpgMakerGameConfig:GetMonsterSentryLeft(id)
    local config = self:GetConfigMonster(id)
    return config.SentryLeft
end

function XRpgMakerGameConfig:GetMonsterSentryRight(id)
    local config = self:GetConfigMonster(id)
    return config.SentryRight
end

function XRpgMakerGameConfig:GetMonsterSentryStopRound(id)
    local config = self:GetConfigMonster(id)
    return config.SentryStopRound
end

function XRpgMakerGameConfig:GetMonsterPrefab(id)
    local config = self:GetConfigMonster(id)
    return config.Prefab
end

function XRpgMakerGameConfig:GetMonsterPatrolIdList(id)
    local config = self:GetConfigMonster(id)
    return config.PatrolId
end

function XRpgMakerGameConfig:GetMonsterModelKey(id)
    local config = self:GetConfigMonster(id)
    return config.ModelKey
end

function XRpgMakerGameConfig:IsMonsterTriggerEnd(id)
    local config = self:GetConfigMonster(id)
    return XTool.IsNumberValid(config.TriggerEnd)
end

function XRpgMakerGameConfig:IsMapHaveMonster(mapId, monsterType)
    local monsterIdList = self:GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Monster)
    local isHaveNormalIcon, isHaveCrystalIcon, isHaveFlameIcon, isHaveRaidenIcon, isHaveDarkIcon
    local typeCfg
    local skillCfg
    local monsterId
    for _, data in ipairs(monsterIdList) do
        monsterId = data:GetParams()[1]
        typeCfg = self:GetMonsterType(monsterId)
        skillCfg = self:GetMonsterSkillType(monsterId)
        if typeCfg == monsterType then
            if monsterType == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameMonsterType.Human then
                return true
            elseif skillCfg then
                if skillCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Crystal then isHaveCrystalIcon = true
                elseif skillCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Flame then isHaveFlameIcon = true
                elseif skillCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Thunder then isHaveRaidenIcon = true
                elseif skillCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameRoleSkillType.Dark then isHaveDarkIcon = true
                else isHaveNormalIcon = true end
            else
                isHaveNormalIcon = true
            end
        end
        if isHaveNormalIcon and isHaveCrystalIcon and isHaveFlameIcon and isHaveRaidenIcon and isHaveDarkIcon then
            break
        end
    end
    return isHaveNormalIcon, isHaveCrystalIcon, isHaveFlameIcon, isHaveRaidenIcon, isHaveDarkIcon
end
--endregion

--region RpgMakerGameTrigger
function XRpgMakerGameConfig:GetConfigTrigger(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameTrigger, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameTrigger)
    end
end

function XRpgMakerGameConfig:GetTriggerX(id)
    local config = self:GetConfigTrigger(id)
    return config.X
end

function XRpgMakerGameConfig:GetTriggerY(id)
    local config = self:GetConfigTrigger(id)
    return config.Y
end

function XRpgMakerGameConfig:GetTriggerDefaultBlock(id)
    local config = self:GetConfigTrigger(id)
    return config.DefaultBlock
end

function XRpgMakerGameConfig:GetTriggerType(id)
    local config = self:GetConfigTrigger(id)
    return config.Type
end

function XRpgMakerGameConfig:IsMapHaveTrigger(mapId)
    local isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger, isHaveElectricFencTrigger
    local triggerIdList = self:GetMixBlockDataListByType(mapId, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trigger)
    local typeCfg
    local triggerId
    for _, data in ipairs(triggerIdList) do
        triggerId = data:GetParams()[1]
        typeCfg = self:GetTriggerType(triggerId)
        if typeCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger1 then
            isHaveType1Trigger = true
        elseif typeCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger2 then
            isHaveType2Trigger = true
        elseif typeCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.Trigger3 then
            isHaveType3Trigger = true
        elseif typeCfg == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameTriggerType.TriggerElectricFence then
            isHaveElectricFencTrigger = true
        end

        if isHaveType1Trigger and isHaveType2Trigger and isHaveType3Trigger and isHaveElectricFencTrigger then
            break
        end
    end
    return isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger, isHaveElectricFencTrigger
end
--endregion

--region RpgMakerGameChapterGroup
function XRpgMakerGameConfig:GetConfigChapterGroup(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameChapterGroup, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameChapterGroup)
    end
end

function XRpgMakerGameConfig:GetChapterGroupName(id)
    local config = self:GetConfigChapterGroup(id)
    return config.Name
end

function XRpgMakerGameConfig:GetChapterGroupOpenTimeId(id)
    local config = self:GetConfigChapterGroup(id)
    return config.OpenTimeId
end

function XRpgMakerGameConfig:GetChapterGroupActivityIcon(id)
    local config = self:GetConfigChapterGroup(id)
    return config.ActivityIcon
end

function XRpgMakerGameConfig:GetChapterGroupBg(id)
    local config = self:GetConfigChapterGroup(id)
    return config.Bg
end

function XRpgMakerGameConfig:GetChapterGroupIsShowTask(id)
    local config = self:GetConfigChapterGroup(id)
    return config.IsShowTask
end

function XRpgMakerGameConfig:GetChapterGroupIsFirstShow(id)
    local config = self:GetConfigChapterGroup(id)
    return config.IsFirstShow
end

function XRpgMakerGameConfig:GetChapterGroupTitlePrefab(id)
    local config = self:GetConfigChapterGroup(id)
    return config.TitlePrefab
end

function XRpgMakerGameConfig:GetChapterGroupGroundPrefab(id)
    local config = self:GetConfigChapterGroup(id)
    return config.GroundPrefab
end

function XRpgMakerGameConfig:GetChapterGroupBlockPrefab(id)
    local config = self:GetConfigChapterGroup(id)
    return config.BlockPrefab
end

function XRpgMakerGameConfig:GetChapterGroupHelpKey(id)
    local config = self:GetConfigChapterGroup(id)
    return config.HelpKey
end

function XRpgMakerGameConfig:InitChapterGroup()
    if self.ChapterGroupToChapterIdList then return end

    self.ChapterGroupToChapterIdList = {}
    self.ChapterGroupIdList = {}
    
    local chapterConfigs = self:GetConfigChapter()
    for id, v in pairs(chapterConfigs) do
        local groupId = v.GroupId
        if not self.ChapterGroupToChapterIdList[groupId] then
            self.ChapterGroupToChapterIdList[groupId] = {}
        end
        tableInsert(self.ChapterGroupToChapterIdList[groupId], id)
    end

    for _, chapterIdList in pairs(self.ChapterGroupToChapterIdList) do
        tableSort(chapterIdList, function(chapterIdA, chapterIdB)
            return chapterIdA < chapterIdB
        end)
    end

    local groupConfigs = self:GetConfigChapterGroup()
    for id, v in pairs(groupConfigs) do
        tableInsert(self.ChapterGroupIdList, id)

        if v.IsFirstShow then
            self.DefaultChapterGroupId = id
        end
    end
    tableSort(self.ChapterGroupIdList, function(groupIdA, groupIdB)
        return groupIdA < groupIdB
    end)
end

function XRpgMakerGameConfig:GetChapterGroupIdList()
    self:InitChapterGroup()
    return self.ChapterGroupIdList
end

function XRpgMakerGameConfig:GetChapterIdList(groupId)
    self:InitChapterGroup()
    return self.ChapterGroupToChapterIdList[groupId] or {}
end

function XRpgMakerGameConfig:GetNextChapterId(chapterId)
    local groupId = self:GetDefaultChapterGroupId()
    local chapterIds = self:GetChapterIdList(groupId)
    for i, cId in ipairs(chapterIds) do
        if cId == chapterId then
            return chapterIds[i+1]
        end
    end
end

function XRpgMakerGameConfig:GetDefaultChapterGroupId()
    self:InitChapterGroup()
    return self.DefaultChapterGroupId
end
--endregion

--region RpgMakerGameMixBlock
function XRpgMakerGameConfig:GetConfigMixBlock(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameMixBlock, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameMixBlock)
    end
end

-- 解析地图对象表
function XRpgMakerGameConfig:InitMapIdToMixBlockIdList()
    if self.MixBlockInMapDic then return end

    local XMapObjectData = require("XModule/XRpgMakerGame/XEntity/XRpgMakerGameMapObjectData")
    ---地图对象字典 key1:MapId,key2:x,key3:y
    ---@type table<number, table<number, table<number, XMapObjectData>>>
    self.MixBlockInMapDic = {}
    ---地图对象字典 key1:MapId,key2:XRpgMakeBlockMetaType
    ---@type table<number, table<number, XMapObjectData>>
    self.MixBlockTypeMapDic = {}
    
    local createDir = function (mapId, x, y, type)
        if not self.MixBlockTypeMapDic[mapId] then self.MixBlockTypeMapDic[mapId] = {} end
        if XTool.IsNumberValid(type) and XTool.IsTableEmpty(self.MixBlockTypeMapDic[mapId][type]) then
            self.MixBlockTypeMapDic[mapId][type] = {}
        end
        if not self.MixBlockInMapDic[mapId] then self.MixBlockInMapDic[mapId] = {} end
        if XTool.IsTableEmpty(self.MixBlockInMapDic[mapId][x]) then
            self.MixBlockInMapDic[mapId][x] = {}
        end
        if XTool.IsTableEmpty(self.MixBlockInMapDic[mapId][x][y]) then
            self.MixBlockInMapDic[mapId][x][y] = {}
        end
    end
    local configs = self:GetConfigMixBlock()
    for _, config in ipairs(configs) do
        local mapId = config.MapId
        for index, value in ipairs(config.Col) do
            local row = config.Row
            local col = index
            local x = col
            local y = row
            if not string.IsNilOrEmpty(value) then
                local data = string.Split(value, "|")
                local blockType = tonumber(data[1])
                if XTool.IsNumberValid(blockType) then
                    local objectData = XMapObjectData.New(row, col, data[1])
                    createDir(mapId, x, y, objectData:GetType())
                    tableInsert(self.MixBlockTypeMapDic[mapId][objectData:GetType()], objectData)
                    tableInsert(self.MixBlockInMapDic[mapId][x][y], objectData)
                else
                    if #data == 1 then
                        createDir(mapId, x, y)
                    else
                        for i = 2, #data, 1 do
                            local objectData = XMapObjectData.New(row, col, data[i])
                            createDir(mapId, x, y, objectData:GetType())
                            tableInsert(self.MixBlockTypeMapDic[mapId][objectData:GetType()], objectData)
                            tableInsert(self.MixBlockInMapDic[mapId][x][y], objectData)
                        end
                    end
                end
            else
                createDir(mapId, x, y)
            end
        end
    end
end

---@param mapId number
---@param type number
---@return table<number, XMapObjectData>
function XRpgMakerGameConfig:GetMixBlockDataListByType(mapId, type)
    self:InitMapIdToMixBlockIdList()
    local data = self.MixBlockTypeMapDic[mapId]
    return data and data[type] or {}
end

---@param mapId number
---@param row number
---@param col number
---@return table<number, XMapObjectData>
function XRpgMakerGameConfig:GetMixBlockDataListByPosition(mapId, x, y)
    self:InitMapIdToMixBlockIdList()
    local data = self.MixBlockInMapDic[mapId]
    return data and data[x] and data[x][y] or {}
end

function XRpgMakerGameConfig:GetMixBlockDataList(mapId)
    self:InitMapIdToMixBlockIdList()
    return self.MixBlockInMapDic[mapId]
end

--endregion

--region RpgMakerGameSkillType
function XRpgMakerGameConfig:GetConfigSkillType(skillType)
    if skillType then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameSkillType, skillType)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameSkillType)
    end
end

function XRpgMakerGameConfig:GetSkillTypeIcon(skillType)
    local config = self:GetConfigSkillType(skillType)
    return config.Icon
end

function XRpgMakerGameConfig:GetSkillTypeName(skillType)
    local config = self:GetConfigSkillType(skillType)
    return config.Name
end
--endregion

--region RpgMakerGameHintIcon
function XRpgMakerGameConfig:GetConfigHintIcon(key)
    if key then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameHintIcon, key)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameHintIcon)
    end
end

function XRpgMakerGameConfig:GetHintIcon(key)
    local config = self:GetConfigHintIcon(key)
    return config.Icon
end

function XRpgMakerGameConfig:GetHintLayer(key)
    local config = self:GetConfigHintIcon(key)
    return config.Layer
end

function XRpgMakerGameConfig:GetHintName(key)
    local config = self:GetConfigHintIcon(key)
    return config.Name
end

function XRpgMakerGameConfig:GetConfigRandomDialogBox(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameRandomDialogBox, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameRandomDialogBox)
    end
end

function XRpgMakerGameConfig:GetRandomDialogBoxPreStage(id)
    local config = self:GetConfigRandomDialogBox(id)
    return config.PreStage
end

function XRpgMakerGameConfig:GetRandomDialogBoxText(id)
    local config = self:GetConfigRandomDialogBox(id)
    return config.Text or ""
end

function XRpgMakerGameConfig:GetRandomDialogBoxWeight(id)
    local config = self:GetConfigRandomDialogBox(id)
    return config.Weight
end

function XRpgMakerGameConfig:GetRandomDialogBoxDuration(id)
    local config = self:GetConfigRandomDialogBox(id)
    return config.Duration
end

function XRpgMakerGameConfig:GetRandomDialogBoxIds()
    local ids = {}
    local configs = self:GetConfigRandomDialogBox()
    for _, v in pairs(configs) do
        tableInsert(ids, v.Id)
    end
    tableSort(ids, function(a, b)
        return a < b
    end)
    return ids
end
--endregion

function XRpgMakerGameConfig:GetConfigHintDialogBox(stageId)
    if stageId then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameHintDialogBox, stageId)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameHintDialogBox)
    end
end

--region RpgMakerGameModel
function XRpgMakerGameConfig:GetConfigModel(key)
    if key then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameModel, key)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameModel)
    end
end

function XRpgMakerGameConfig:GetModelPath(key)
    local config = self:GetConfigModel(key)
    return config.ModelPath or ""
end

function XRpgMakerGameConfig:GetModelName(key)
    local config = self:GetConfigModel(key)
    return config.Name or ""
end

function XRpgMakerGameConfig:GetModelDesc(key)
    local config = self:GetConfigModel(key)
    return config.Desc or ""
end

function XRpgMakerGameConfig:GetModelIcon(key)
    local config = self:GetConfigModel(key)
    return config.Icon or ""
end

function XRpgMakerGameConfig:GetModelSize(key)
    local config = self:GetConfigModel(key)
    local size = config.Size
    local sizeList = string.Split(size, "|")
    return {x = tonumber(sizeList[1]) or 0, y = tonumber(sizeList[2]) or 0, z = tonumber(sizeList[3] or 0)}
end

function XRpgMakerGameConfig:GetModelScale(key)
    local config = self:GetConfigModel(key)
    local scale = config.Scale
    return XLuaVector3.New(scale[1] or 1, scale[2] or 1, scale[3] or 1)
end
--endregion

--region RpgMakerGameAnimation
function XRpgMakerGameConfig:GetConfigAnimation(modelName)
    if modelName then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameAnimation, modelName)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameAnimation)
    end
end

function XRpgMakerGameConfig:GetAnimationStandAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.StandAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationRunAnimaName(modelName, direction)
    local config = self:GetConfigAnimation(modelName)
    if config.RunAnimaNames[direction] then
        return config.RunAnimaNames[direction]
    end
    return config.RunAnimaNames[1]
end

function XRpgMakerGameConfig:GetAnimationFlyAnimaName(modelName, direction)
    local config = self:GetConfigAnimation(modelName)
    if config.FlyAnimNames[direction] then
        return config.FlyAnimNames[direction]
    end
    return config.FlyAnimNames[1]
end

function XRpgMakerGameConfig:GetAnimationAtkAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.AtkAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationElectricFenceAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.ElectricFenceAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationAlarmAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.AlarmAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationDrownAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.DrownAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationAdsorbAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.AdsorbAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationTransferAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.TransferAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationTransferDisAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.TransferDisAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationBubblePushAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.BubblePushAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationDropPickAnimaName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.DropPickAnimaName or ""
end

function XRpgMakerGameConfig:GetAnimationEffectRoot(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.EffectRoot or ""
end

function XRpgMakerGameConfig:GetAnimationSentrySignYOffset(modelName)
    local config = self:GetConfigAnimation(modelName)
    local yOffset = config and config.SentrySignYOffset
    return yOffset and yOffset / 1000 or 0
end

function XRpgMakerGameConfig:GetAnimationXOffSet(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.XOffSet or 0
end

function XRpgMakerGameConfig:GetAnimationYOffSet(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.YOffSet or 0
end

function XRpgMakerGameConfig:GetAnimationZOffSet(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.ZOffSet or 0
end

function XRpgMakerGameConfig:GetAnimationName(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.Name or ""
end

function XRpgMakerGameConfig:GetAnimationDesc(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.Desc or ""
end

function XRpgMakerGameConfig:GetAnimationIcon(modelName)
    local config = self:GetConfigAnimation(modelName)
    return config.Icon or ""
end
--endregion

--region RpgMakerGamePlayMainDownHint
function XRpgMakerGameConfig:GetConfigPlayMainDownHint(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGamePlayMainDownHint, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGamePlayMainDownHint)
    end
end

function XRpgMakerGameConfig:GetPlayMainDownHintConfigMaxCount()
    return #self:GetConfigPlayMainDownHint()
end

function XRpgMakerGameConfig:GetPlayMainDownHintText(id)
    local config = self:GetConfigPlayMainDownHint(id)
    return config.Text or ""
end
--endregion

function XRpgMakerGameConfig:GetConfigHintLine(mapId)
    if mapId then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameHintLine, mapId)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameHintLine)
    end
end

--region RpgMakerGameDeathTitle
function XRpgMakerGameConfig:GetConfigDeathTitle(type)
    if type then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RpgMakerGameDeathTitle, type)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.RpgMakerGameDeathTitle)
    end
end

function XRpgMakerGameConfig:GetDeathTitleName(type)
    local config = self:GetConfigDeathTitle(type)
    return config and config.Name or ""
end
--endregion

return XRpgMakerGameConfig
