--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local DlcRelinkTableKey = {
    DlcRelinkActivity = { CacheType = XConfigUtil.CacheType.Normal },
    DlcRelinkChapter = {
        Identifier = "ChapterId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcRelinkCharacter = {},
    DlcRelinkLevel = {
        Identifier = "LevelId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcRelinkDropGroup = {},
    DlcRelinkRewardGroup = {},
    DlcRelinkPlayerLevel = { Identifier = "Level", },
    DlcRelinkEquip = {},
    DlcRelinkEquipQuality = { Identifier = "Quality", },
    DlcRelinkFactor = {},
    DlcRelinkFactorDesc = {},
    DlcRelinkCompose = {},
    DlcRelinkComposePool = {},
    DlcRelinkBreak = { Identifier = "BreakEquipId", },
    DlcRelinkTextEmoji = {},
    DlcRelinkConfig = {
        ReadFunc = XConfigUtil.ReadType.String,
        Identifier = "Key",
    },
    DlcRelinkBossSkillDesc = { DirPath = XConfigUtil.DirectoryType.Client, },
    DlcRelinkEquipSkillFactor = { DirPath = XConfigUtil.DirectoryType.Client, },
    DlcRelinkWorld = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    DlcRelinkMedalTag = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    DlcRelinkSummaryFactor = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Private,
    },
    DlcRelinkCharacterAttrib = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key",
    },
    DlcRelinkSkillDesc = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    DlcRelinkShopTask = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcRelinkShowLevelDrop = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    DlcRelinkClientConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key",
    },
    DlcRelinkWiki = {},
    DlcRelinkMechanismTeach = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XDlcRelinkModel : XModel
---@field ActivityData XDlcRelinkActivity
local XDlcRelinkModel = XClass(XModel, "XDlcRelinkModel")
function XDlcRelinkModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/DlcRelink", DlcRelinkTableKey)

    -- 通用弹框-本次登录不再提醒 [key] = true/false
    self.CommonTipNoRemindMap = {}

    -- 结算缓存数据
    ---@type XDlcRelinkSettlementCache
    self.SettlementCacheData = nil

    -- 登录wifi提醒 
    self._NeedPopWifiTips = true
    -- 是否开启了全局匹配
    self.GlobalMatchEnabled = false
    -- 点赞信息缓存
    self.LikeInfoCache = nil
end

function XDlcRelinkModel:ClearPrivate()
    --这里执行内部数据清理
    self._EquipFactorDict = nil
    self._ShowChapterIds = nil
    self._TeachingLevelId = nil
    self._TrainingLevelId = nil
end

function XDlcRelinkModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self.CommonTipNoRemindMap = {}
    self.SettlementCacheData = nil

    self._NeedPopWifiTips = true
    self.GlobalMatchEnabled = false
    self.LikeInfoCache = nil
end

--region 服务端信息更新和获取

function XDlcRelinkModel:NotifyActivityData(data)
    if not XTool.IsNumberValid(data.ActivityId) then
        return
    end
    local isFinishedTutorial = false

    if not self.ActivityData then
        self.ActivityData = require("XModule/XDlcRelink/XEntity/XDlcRelinkActivity").New()
    else
        if not self.ActivityData:IsTutorialPassed() and data.FinishedTutorial then
            isFinishedTutorial = true
        end
    end
    self.ActivityData:NotifyActivityData(data)

    --通关教学关
    if isFinishedTutorial then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_TEACHING_LEVEL_PASS)
    end
end

--- 检查关卡是否通关
---@param levelId number 关卡Id
---@return boolean 是否通关
function XDlcRelinkModel:CheckLevelPassed(levelId)
    if not XTool.IsNumberValid(levelId) or not self.ActivityData then
        return false
    end
    if levelId == self:GetTeachingLevelId() then
        return self:IsTutorialPassed()
    end
    return self.ActivityData:IsLevelPassed(levelId)
end

function XDlcRelinkModel:IsTutorialPassed()
    if not self.ActivityData then
        return false
    end
    return self.ActivityData:IsTutorialPassed()
end

--endregion

--region 活动表相关

---@return XTableDlcRelinkActivity
function XDlcRelinkModel:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkActivity, curActivityId)
end

--- 获取活动时间Id
function XDlcRelinkModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

--- 获取活动章节Ids
function XDlcRelinkModel:GetActivityChapterIds()
    if not self._ShowChapterIds then
        self._ShowChapterIds = {}
        local config = self:GetActivityConfig()
        for _, id in ipairs(config.ChapterIds) do
            if not self:GetChapterConfig(id).IsTutorial then --排除教学章节
                table.insert(self._ShowChapterIds, id)
            end
        end
    end
    return self._ShowChapterIds
end

--endregion

--region 章节表相关
---@return XTableDlcRelinkChapter[]
function XDlcRelinkModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkChapter)
end

---@return XTableDlcRelinkChapter
function XDlcRelinkModel:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkChapter, chapterId)
end

function XDlcRelinkModel:GetChapterTimeId(chapterId)
    local config = self:GetChapterConfig(chapterId)
    return config and config.TimeId or 0
end

function XDlcRelinkModel:GetChapterConditionIds(chapterId)
    local config = self:GetChapterConfig(chapterId)
    return config and config.Condition or {}
end

function XDlcRelinkModel:GetChapterLevelIds(chapterId)
    local config = self:GetChapterConfig(chapterId)
    return config and config.LevelIds or {}
end

function XDlcRelinkModel:CheckChapterUnlock(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    local timeId = self:GetChapterTimeId(chapterId)
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end

    local conditionIds = self:GetChapterConditionIds(chapterId)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--endregion

--region 角色表相关

---@return XTableDlcRelinkCharacter[]
function XDlcRelinkModel:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkCharacter)
end

---@return XTableDlcRelinkCharacter
function XDlcRelinkModel:GetCharacterConfig(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkCharacter, id, noTips)
end

--endregion

--region 等级表相关

---@return XTableDlcRelinkLevel[]
function XDlcRelinkModel:GetLevelConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkLevel)
end

---@return XTableDlcRelinkLevel
function XDlcRelinkModel:GetLevelConfig(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkLevel, levelId)
end

function XDlcRelinkModel:GetLevelPreLevelId(levelId)
    local config = self:GetLevelConfig(levelId)
    return config and config.PreLevelId or 0
end

function XDlcRelinkModel:GetLevelTimeId(levelId)
    local config = self:GetLevelConfig(levelId)
    return config and config.TimeId or 0
end

function XDlcRelinkModel:GetLevelConditionIds(levelId)
    local config = self:GetLevelConfig(levelId)
    return config and config.Condition or {}
end

--- 检查等级是否解锁
function XDlcRelinkModel:CheckLevelUnlock(levelId)
    if not XTool.IsNumberValid(levelId) then
        return false
    end

    local preLevelId = self:GetLevelPreLevelId(levelId)
    if preLevelId > 0 and not self:CheckLevelPassed(preLevelId) then
        return false
    end

    local timeId = self:GetLevelTimeId(levelId)
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end

    local conditionIds = self:GetLevelConditionIds(levelId)
    for _, conditionId in ipairs(conditionIds) do
        if conditionId > 0 and not XConditionManager.CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--endregion

--region 掉落组表相关

---@return XTableDlcRelinkDropGroup[]
function XDlcRelinkModel:GetDropGroupConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkDropGroup)
end

---@return XTableDlcRelinkDropGroup
function XDlcRelinkModel:GetDropGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkDropGroup, id)
end

--endregion

--region 奖励组表相关

---@return XTableDlcRelinkRewardGroup[]
function XDlcRelinkModel:GetRewardGroupConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkRewardGroup)
end

---@return XTableDlcRelinkRewardGroup
function XDlcRelinkModel:GetRewardGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkRewardGroup, id)
end

--endregion

--region 玩家等级表相关

---@return XTableDlcRelinkPlayerLevel[]
function XDlcRelinkModel:GetPlayerLevelConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkPlayerLevel)
end

---@return XTableDlcRelinkPlayerLevel
function XDlcRelinkModel:GetPlayerLevelConfig(level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkPlayerLevel, level)
end

--endregion

--region 装备表相关

---@return XTableDlcRelinkEquip[]
function XDlcRelinkModel:GetEquipConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkEquip)
end

---@return XTableDlcRelinkEquip
function XDlcRelinkModel:GetEquipConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkEquip, id)
end

function XDlcRelinkModel:GetMaxQualityEquipByFactor(factor)
    if not self._EquipFactorDict then
        ---@type table<number,XTableDlcRelinkEquip>
        self._EquipFactorDict = {}
        for _, v in pairs(self:GetEquipConfigs()) do
            if XTool.IsNumberValid(v.MainFactorId) then
                local equip = self._EquipFactorDict[v.MainFactorId]
                if not equip or equip.Quality < v.Quality then
                    self._EquipFactorDict[v.MainFactorId] = v
                end
            end
            if XTool.IsNumberValid(v.MainSkillFactorId) then
                local equip = self._EquipFactorDict[v.MainSkillFactorId]
                if not equip or equip.Quality < v.Quality then
                    self._EquipFactorDict[v.MainSkillFactorId] = v
                end
            end
        end
    end
    return self._EquipFactorDict[factor]
end

--endregion

--region 装备品质表相关

---@return XTableDlcRelinkEquipQuality[]
function XDlcRelinkModel:GetEquipQualityConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkEquipQuality)
end

---@return XTableDlcRelinkEquipQuality
function XDlcRelinkModel:GetEquipQualityConfig(quality)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkEquipQuality, quality)
end

--endregion

--region 词条表相关

---@return XTableDlcRelinkFactor[]
function XDlcRelinkModel:GetFactorConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkFactor)
end

---@return XTableDlcRelinkFactor
function XDlcRelinkModel:GetFactorConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkFactor, id)
end

--endregion

--region 词条描述表相关

---@return XTableDlcRelinkFactorDesc[]
function XDlcRelinkModel:GetFactorDescConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkFactorDesc)
end

---@return XTableDlcRelinkFactorDesc
function XDlcRelinkModel:GetFactorDescConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkFactorDesc, id)
end

--endregion

--region 合成表相关

---@return XTableDlcRelinkCompose[]
function XDlcRelinkModel:GetComposeConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkCompose)
end

---@return XTableDlcRelinkCompose
function XDlcRelinkModel:GetComposeConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkCompose, id)
end

--endregion

--region 合成池表相关

---@return XTableDlcRelinkComposePool[]
function XDlcRelinkModel:GetComposePoolConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkComposePool)
end

---@return XTableDlcRelinkComposePool
function XDlcRelinkModel:GetComposePoolConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkComposePool, id)
end

--endregion

--region 分解表相关

---@return XTableDlcRelinkBreak[]
function XDlcRelinkModel:GetBreakConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkBreak)
end

---@return XTableDlcRelinkBreak
function XDlcRelinkModel:GetBreakConfig(breakEquipId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkBreak, breakEquipId)
end

--endregion

--region 表情表相关

---@return XTableDlcRelinkTextEmoji[]
function XDlcRelinkModel:GetTextEmojiConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkTextEmoji)
end

---@return XTableDlcRelinkTextEmoji
function XDlcRelinkModel:GetTextEmojiConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkTextEmoji, id)
end

--endregion

--region Boss技能描述表相关

---@return XTableDlcRelinkBossSkillDesc[]
function XDlcRelinkModel:GetBossSkillDescConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkBossSkillDesc)
end

---@return XTableDlcRelinkBossSkillDesc
function XDlcRelinkModel:GetBossSkillDescConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkBossSkillDesc, id)
end

--endregion

--region 装备技能词条表相关

---@return XTableDlcRelinkEquipSkillFactor[]
function XDlcRelinkModel:GetEquipSkillFactorConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkEquipSkillFactor)
end

---@return XTableDlcRelinkEquipSkillFactor
function XDlcRelinkModel:GetEquipSkillFactorConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkEquipSkillFactor, id)
end

--endregion

--region World表相关

---@return XTableDlcRelinkWorld[]
function XDlcRelinkModel:GetWorldConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkWorld)
end

---@return XTableDlcRelinkWorld
function XDlcRelinkModel:GetWorldConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkWorld, id)
end

function XDlcRelinkModel:GetWorldIcon(id)
    local config = self:GetWorldConfig(id)
    return config and config.Icon or ""
end

function XDlcRelinkModel:GetWorldSceneUrl(id)
    local config = self:GetWorldConfig(id)
    return config and config.SceneUrl or ""
end

function XDlcRelinkModel:GetWorldSceneModelUrl(id)
    local config = self:GetWorldConfig(id)
    return config and config.SceneModelUrl or ""
end

function XDlcRelinkModel:GetWorldLoadingBackground(id)
    local config = self:GetWorldConfig(id)
    return config and config.LoadingBackground or ""
end

function XDlcRelinkModel:GetWorldArtName(id)
    local config = self:GetWorldConfig(id)
    return config and config.ArtName or ""
end

function XDlcRelinkModel:GetWorldMaskLoadingType(id)
    local config = self:GetWorldConfig(id)
    return config and config.MaskLoadingType or ""
end

function XDlcRelinkModel:GetWorldSettlementUiName(id)
    local config = self:GetWorldConfig(id)
    return config and config.SettlementUiName or ""
end

--endregion

--region 勋章标签表相关

---@return XTableDlcRelinkMedalTag[]
function XDlcRelinkModel:GetMedalTagConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkMedalTag)
end

---@return XTableDlcRelinkMedalTag
function XDlcRelinkModel:GetMedalTagConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkMedalTag, id)
end

---@return XTableDlcRelinkSummaryFactor
function XDlcRelinkModel:GetDlcRelinkSummaryFactorConfig(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkSummaryFactor, id, notips)
end

--endregion

--region 角色属性表相关

---@return XTableDlcRelinkCharacterAttrib[]
function XDlcRelinkModel:GetCharacterAttribConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkCharacterAttrib)
end

---@return XTableDlcRelinkCharacterAttrib
function XDlcRelinkModel:GetCharacterAttribConfig(key, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkCharacterAttrib, key, noTips)
end

--endregion

--region 技能描述表相关

---@return XTableDlcRelinkSkillDesc[]
function XDlcRelinkModel:GetSkillDescConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkSkillDesc)
end

---@return XTableDlcRelinkSkillDesc
function XDlcRelinkModel:GetSkillDescConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkSkillDesc, id)
end

--endregion

--region 商店任务表相关

---@return XTableDlcRelinkShopTask[]
function XDlcRelinkModel:GetShopTaskConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkShopTask)
end

---@return XTableDlcRelinkShopTask
function XDlcRelinkModel:GetShopTaskConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkShopTask, id)
end

--endregion

--region 展示关卡掉落表相关

---@return XTableDlcRelinkShowLevelDrop[]
function XDlcRelinkModel:GetShowLevelDropConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkShowLevelDrop)
end

---@return XTableDlcRelinkShowLevelDrop
function XDlcRelinkModel:GetShowLevelDropConfig(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkShowLevelDrop, id, noTips)
end

--endregion

--region 配置表相关

function XDlcRelinkModel:GetConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkConfig, key)
    if not config then
        return nil
    end
    return config.Param and config.Param[index]
end

function XDlcRelinkModel:GetConfigParams(key)
    ---@type XTableDlcRelinkConfig
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkConfig, key)
    if not config then
        return nil
    end
    return config.Param
end

--endregion

--region 客户端配置表相关

function XDlcRelinkModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return nil
    end
    return config.Params and config.Params[index] or ""
end

function XDlcRelinkModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return nil
    end
    return config.Params
end

function XDlcRelinkModel:GetClientConfigVal(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return 0
    end

    index = index or 1

    local param = config.Params and config.Params[index] or ""

    if not string.IsNilOrEmpty(param) and string.IsFloatNumber(param) then
        return tonumber(param)
    end
end

function XDlcRelinkModel:GetTeachingLevelId()
    if not self._TeachingLevelId then
        self._TeachingLevelId = tonumber(self:GetClientConfig("TeachingLevelId", 1))
    end
    return self._TeachingLevelId
end

function XDlcRelinkModel:GetTrainingLevelId()
    if not self._TrainingLevelId then
        self._TrainingLevelId = tonumber(self:GetClientConfig("TrainingLevelId", 1))
    end
    return self._TrainingLevelId
end

function XDlcRelinkModel:GetClientConfigBattleSettleShowTitleMaxCount()
    return self:GetClientConfigVal('BattleSettleShowTitleMaxCount')
end
--endregion

--region 结算相关

--- 记录研发等级和研发经验
---@param level number 当前等级
---@param exp number 当前经验
function XDlcRelinkModel:RecordSettlementLevelAndExp(level, exp)
    self.SettlementCacheData = self.SettlementCacheData or {}
    self.SettlementCacheData.CurLevel = level or 0
    self.SettlementCacheData.CurExp = exp or 0
    self.SettlementCacheData.LastLevel = self.ActivityData:GetLevel()
    self.SettlementCacheData.LastExp = self.ActivityData:GetExp()
end

--endregion

--region 百科全书相关

---@return XTableDlcRelinkWiki
function XDlcRelinkModel:GetWikiConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkWiki, id)
end

---@return XTableDlcRelinkWiki[]
function XDlcRelinkModel:GetWikiConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkWiki)
end

function XDlcRelinkModel:GetHasWikiBeenViewed(wikiId)
    return XSaveTool.GetData(string.format("DlcRelink_Wiki_%s_%s", XPlayer.Id, wikiId)) == 1
end

function XDlcRelinkModel:SetWikiHasBeenViewed(wikiId)
    XSaveTool.SaveData(string.format("DlcRelink_Wiki_%s_%s", XPlayer.Id, wikiId), 1)
end

--endregion

--region 机制教学相关

function XDlcRelinkModel:GetMechanismTeachById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkMechanismTeach, id)
end

function XDlcRelinkModel:GetMechanismTeachByLevelId(levelId)
    ---@type XTableDlcRelinkMechanismTeach[]
    local configs = self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkMechanismTeach)
    for k, v in pairs(configs) do
        if table.contains(v.LevelId, levelId) then
            if XSaveTool.GetData(string.format("DlcRelink_Mechanism_Teach_%s_%s", XPlayer.Id, v.Id)) ~= 1 then
                return v
            end
        end
    end
    return nil
end

function XDlcRelinkModel:SetMechanismTeachHasBeenViewed(id)
    XSaveTool.SaveData(string.format("DlcRelink_Mechanism_Teach_%s_%s", XPlayer.Id, id), 1)
end

--endregion

--region 本地信息相关

--- 获取关卡查看状态的存储Key
function XDlcRelinkModel:GetLevelViewedKey(levelId)
    local activityId = self.ActivityData and self.ActivityData:GetActivityId() or 0
    return string.format("DlcRelinkLevelViewed_%s_%s_%s", XPlayer.Id, activityId, levelId)
end

--- 检查关卡是否已查看
function XDlcRelinkModel:CheckLevelViewed(levelId)
    if not XTool.IsNumberValid(levelId) then
        return true
    end
    local key = self:GetLevelViewedKey(levelId)
    return XSaveTool.GetData(key) or false
end

--- 记录关卡为已查看
function XDlcRelinkModel:RecordLevelViewed(levelId)
    if not XTool.IsNumberValid(levelId) then
        return
    end
    if not self:CheckLevelUnlock(levelId) then
        return
    end
    local key = self:GetLevelViewedKey(levelId)
    if not XSaveTool.GetData(key) then
        XSaveTool.SaveData(key, true)
    end
end

--- 获取技能描述是否为详细
function XDlcRelinkModel:GetSkillDescIsDetail()
    return self._SaveUtil:GetData('IsSkillDescIsDetail') or false
end

--- 设置技能描述是否为详细
function XDlcRelinkModel:SetSkillDescIsDetail(isDetail)
    self._SaveUtil:SaveData('IsSkillDescIsDetail', isDetail)
end

--- 获取装备描述是否为详细
function XDlcRelinkModel:GetEquipAttrDescIsDetail()
    local result = self._SaveUtil:GetData('IsEquipAttrDescIsDetail')

    if result == nil then
        return true
    end
    
    return result
end

--- 设置装备描述是否为详细
function XDlcRelinkModel:SetEquipAttrDescIsDetail(isDetail)
    self._SaveUtil:SaveData('IsEquipAttrDescIsDetail', isDetail)
end

--endregion

--region 红点相关

--- 检查关卡是否有新解锁的红点
function XDlcRelinkModel:CheckLevelHasNewUnlock(levelId)
    if not XTool.IsNumberValid(levelId) then
        return false
    end
    -- 如果关卡未解锁，不显示红点
    if not self:CheckLevelUnlock(levelId) then
        return false
    end
    -- 如果关卡已查看过，不显示红点
    if self:CheckLevelViewed(levelId) then
        return false
    end
    return true
end

--- 检查章节下是否有任何新解锁的关卡
function XDlcRelinkModel:CheckChapterHasAnyNewLevel(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    -- 检查章节是否解锁
    if not self:CheckChapterUnlock(chapterId) then
        return false
    end

    -- 检查章节下的关卡是否有新解锁
    local levelIds = self:GetChapterLevelIds(chapterId)
    for _, levelId in ipairs(levelIds) do
        if self:CheckLevelHasNewUnlock(levelId) then
            return true
        end
    end
    return false
end

--endregion

--region wifi切换提示相关

function XDlcRelinkModel:CheckNeedPopWifiTips()
    return self._NeedPopWifiTips or false
end

function XDlcRelinkModel:ClearWifiTipsPopMark()
    self._NeedPopWifiTips = false
end

--endregion

--region 点赞信息相关

--- 添加点赞信息缓存
function XDlcRelinkModel:AddLikeInfoCache(fromPlayerId, targetPlayerId)
    self.LikeInfoCache = self.LikeInfoCache or {}
    self.LikeInfoCache[fromPlayerId] = self.LikeInfoCache[fromPlayerId] or {}
    self.LikeInfoCache[fromPlayerId][targetPlayerId] = true
end

--endregion

return XDlcRelinkModel
