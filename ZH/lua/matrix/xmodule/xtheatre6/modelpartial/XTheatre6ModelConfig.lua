---Model部分类，此处用于注册和处理与配置表直接关联的读取接口
---@type XTheatre6Model
local XTheatre6Model = XClassPartial('XTheatre6Model')

local TableKey = {
    Theatre6Activity = {},
    Theatre6Attr = {},
    Theatre6AttrPack = {}, --遗物
    Theatre6AttrPackPool = {},
    Theatre6BuildTag = {},
    Theatre6Character = {},
    Theatre6KeyWord = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre6CharacterFashion = {},
    Theatre6Config = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    Theatre6ClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
    Theatre6Monster = {},
    Theatre6Skill = {},
    Theatre6SkillExtend = {},
    Theatre6SkillPool = {},
    Theatre6Stage = {},
    Theatre6StageBuff = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre6StageBuffPool = {},
    Theatre6StageChoose = {},
    Theatre6StageChooseGroup = {},
    Theatre6StageDifficulty = {},
    Theatre6StageDifficultyGroup = {},
    Theatre6StageFloor = {},
    Theatre6StageFight = {},
    Theatre6StageFightGroup = {},
    Theatre6StageGoods = {},
    Theatre6StageRoom = {},
    Theatre6StageSan = {},
    Theatre6StageShop = {},
    Theatre6StageEffect = {},
    Theatre6StageTask = {},
    Theatre6StageTaskGroup = {},
    Theatre6StageTaskQuality = {},
    Theatre6StoryLine = {},
    Theatre6StoryDetail = {},
    Theatre6Talent = {},
    Theatre6Reward = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre6RandomPool = {},
    Theatre6StageBuffPoolShow = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre6StageAnno = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre6StageDifficultyAuto = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "StageId" }, --DifficultyIds已在源表导出时排序
    Theatre6StoryLineAuto = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "CharacterId" },
    Theatre6StageSanAuto = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SanGroupId" },
    Theatre6TagToBuff = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Tag" },
    Theatre6Condition = {},
}

function XTheatre6Model:OnInitConfig()
    self._ConfigUtil:InitConfigByTableKey("Theatre6", TableKey)
end

function XTheatre6Model:ConfigClearPrivate()
    self._TaskShopCfgsDic = nil
end

function XTheatre6Model:ConfigResetAll()

end

function XTheatre6Model:GetStageIds(characterId)
    local storyLineId = self:GetStoryLineId(characterId)
    if XTool.IsNumberValid(storyLineId) then
        return self:GetStoryLineConfig(storyLineId).StageIds
    end
    XLog.Error(string.format("角色的剧情关卡配置不存在：%s", characterId))
    return nil
end

---@return XTableTheatre6Config
function XTheatre6Model:GetConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Config, key)
end

---@return XTableTheatre6ClientConfig
function XTheatre6Model:GetClientConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6ClientConfig, key)
end

---@return XTableTheatre6Character
function XTheatre6Model:GetCharacterConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Character, id)
end

---@return XTableTheatre6Character[]
function XTheatre6Model:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre6Character)
end

---@return XTableTheatre6BuildTag
function XTheatre6Model:GetBuildTagConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6BuildTag, id)
end

---@return XTableTheatre6KeyWord
function XTheatre6Model:GetKeyWordConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6KeyWord, id)
end

---@return XTableTheatre6CharacterFashion
function XTheatre6Model:GetFashionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6CharacterFashion, id)
end

---@return XTableTheatre6StoryLine
function XTheatre6Model:GetStoryLineConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StoryLine, id)
end

---@return XTableTheatre6StoryLine[]
function XTheatre6Model:GetStoryLineConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre6StoryLine)
end

---@return XTableTheatre6StageBuff
function XTheatre6Model:GetBuffConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageBuff, id)
end

---@return XTableTheatre6Attr
function XTheatre6Model:GetAttrConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Attr, id)
end

---@return XTableTheatre6Attr[]
function XTheatre6Model:GetAttrConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre6Attr)
end

---@return XTableTheatre6AttrPack
function XTheatre6Model:GetAttrPackConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6AttrPack, id)
end

---@return number[]
function XTheatre6Model:GetStageDifficultyIds(stageId)
    ---@type XTableTheatre6StageDifficultyAuto
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageDifficultyAuto, stageId)
    return config.DifficultyIds
end

---@return number
function XTheatre6Model:GetStoryLineId(characterId)
    local ids = self:GetStoryLineIds(characterId)
    return ids[1]
end

---@return number[]
function XTheatre6Model:GetStoryLineIds(characterId)
    ---@type XTableTheatre6StoryLineAuto
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StoryLineAuto, characterId)
    return config.StoryLineId
end

---@return string[]
function XTheatre6Model:GetClientConfigValues(key)
    local config = self:GetClientConfig(key)
    if not config then
        XLog.Error(string.format("客户端配置不存在！key=%s", key))
        return nil
    end
    return config.Values
end

---@return string
function XTheatre6Model:GetClientConfigValue(key, index)
    index = index or 1
    local values = self:GetClientConfigValues(key)
    return values and values[index]
end

---@return number
function XTheatre6Model:GetIntClientConfigValue(key, index)
    local value = self:GetClientConfigValue(key, index)
    if value then
        return tonumber(value)
    end
    return 0
end

---@return string[]
function XTheatre6Model:GetConfigValues(key)
    local config = self:GetConfig(key)
    if not config then
        XLog.Error(string.format("客户端配置不存在！key=%s", key))
        return nil
    end
    return config.Values
end

---@return string
function XTheatre6Model:GetConfigValue(key, index)
    index = index or 1
    local values = self:GetConfigValues(key)
    return values and values[index]
end

---@return number
function XTheatre6Model:GetIntConfigValue(key, index)
    local value = self:GetConfigValue(key, index)
    if value then
        return tonumber(value)
    end
    return 0
end

---@return XTableTheatre6StageDifficultyGroup
function XTheatre6Model:GetDifficultyGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageDifficultyGroup, id)
end

---@return XTableTheatre6StageDifficulty
function XTheatre6Model:GetDifficultyConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageDifficulty, id)
end

---@return XTableTheatre6StageSan
function XTheatre6Model:GetSanConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageSan, id)
end

function XTheatre6Model:GetSanIdsByGroupId(sanGroupId)
    ---@type XTableTheatre6StageSanAuto
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageSanAuto, sanGroupId)
    return config.SanIds
end

function XTheatre6Model:GetSanDeathBuffIdByGroupId(sanGroupId)
    local sanIds = self:GetSanIdsByGroupId(sanGroupId)
    for _, sanId in ipairs(sanIds) do
        local config = self:GetSanConfig(sanId)
        if config.SanType == XEnumConst.Theatre6.SanType.Death then
            return config.BuffIds[1]
        end
    end
    return 0
end

---@return XTableTheatre6StageSan
function XTheatre6Model:GetSanConfigBySanValue(sanGroupId, value)
    local sanIds = self:GetSanIdsByGroupId(sanGroupId)
    for _, sanId in ipairs(sanIds) do
        local config = self:GetSanConfig(sanId)
        if config.MinSan <= value and config.MaxSan >= value then
            return config
        end
    end
    return nil
end

---@return XTableTheatre6StageTask
function XTheatre6Model:GetTaskConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageTask, id)
end

---@return XTableTheatre6Stage
function XTheatre6Model:GetStageConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Stage, id)
end

---@return XTableTheatre6StageFloor
function XTheatre6Model:GetStageFloorConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageFloor, id)
end

---@return XTableTheatre6StageRoom 获取房间关卡配置
function XTheatre6Model:GetStageRoomConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageRoom, id)
end

---@return XTableTheatre6StageAnno
function XTheatre6Model:GetAnnoConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageAnno, id)
end

---@return XTableTheatre6StageFightGroup 获取战斗关卡组配置
function XTheatre6Model:GetStageFightGroupCfgById(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageFightGroup, groupId)
end

---@return XTableTheatre6StageFight 获取战斗关卡配置
function XTheatre6Model:GetStageFightCfgById(fightId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageFight, fightId)
end

---@return XTableTheatre6Monster 获取怪物配置
function XTheatre6Model:GetMonsterCfgById(monsterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Monster, monsterId)
end

---@return XTableTheatre6Skill[] 获取所有技能配置
function XTheatre6Model:GetSkillConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre6Skill)
end
---@return XTableTheatre6Skill 获取技能配置
function XTheatre6Model:GetSkillCfgById(skillId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Skill, skillId)
end

---@return XTableTheatre6Skill 获取技能配置
function XTheatre6Model:GetSkillExtendCfgById(skillId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6SkillExtend, skillId)
end

---@return XTableTheatre6AttrPackPool 获取属性包（遗物）池配置
function XTheatre6Model:GetAttrPackPoolCfgByPoolId(poolId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6AttrPackPool, poolId)
end

---@return XTableTheatre6SkillPool 获取技能池配置
function XTheatre6Model:GetSkillPoolCfgByPoolId(poolId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6SkillPool, poolId)
end

---@return XTableTheatre6StageBuffPool 获取关卡Buff池配置
function XTheatre6Model:GetStageBuffPoolCfgByPoolId(poolId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageBuffPool, poolId)
end

---@return XTableTheatre6Talent 获取等级配置
function XTheatre6Model:GetTalentConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Talent, id)
end

---@return XTableTheatre6Talent[] 获取所有等级配置
function XTheatre6Model:GetTalentConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.Theatre6Talent)
end

---@return XTableTheatre6Reward[]
function XTheatre6Model:GetTaskOrShopCfgs(taskShopType)
    if not self._TaskShopCfgsDic then
        self._TaskShopCfgsDic = {}
        local TaskShopType = XEnumConst.Theatre6.TaskShopType
        local allCfgs = self._ConfigUtil:GetByTableKey(TableKey.Theatre6Reward)
        for _, cfg in pairs(allCfgs) do
            local cfgType
            if XTool.IsNumberValid(cfg.ShopId) then
                cfgType = TaskShopType.Shop
            elseif XTool.IsNumberValid(cfg.TaskTimeLimitId) then
                cfgType = TaskShopType.Task
            end
            if cfgType then
                if not self._TaskShopCfgsDic[cfgType] then
                    self._TaskShopCfgsDic[cfgType] = {}
                end
                table.insert(self._TaskShopCfgsDic[cfgType], cfg)
            end
        end
        for _, cfgs in pairs(self._TaskShopCfgsDic) do
            table.sort(cfgs, function(a, b)
                if a.Priority ~= b.Priority then
                    return a.Priority < b.Priority
                else
                    return a.Id < b.Id
                end
            end)
        end
    end
    return self._TaskShopCfgsDic[taskShopType]
end

---@return XTableTheatre6StageGoods
function XTheatre6Model:GetStageGoodsConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageGoods, id)
end

---@return XTableTheatre6StageChooseGroup
function XTheatre6Model:GetStageChooseGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageChooseGroup, id)
end

---@return XTableTheatre6StageChoose
function XTheatre6Model:GetStageChooseConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageChoose, id)
end

---@return XTableTheatre6StageBuffPoolShow
function XTheatre6Model:GetStageBuffPoolShow(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageBuffPoolShow, id)
end

---@return XTableTheatre6RandomPool
function XTheatre6Model:GetRandomPoolConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6RandomPool, id)
end

---@return XTableTheatre6StoryDetail
function XTheatre6Model:GetStoryDetailConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StoryDetail, id)
end

---@return XTableTheatre6StageTaskGroup
function XTheatre6Model:GetStageTaskGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageTaskGroup, id)
end

---@return XTableTheatre6StageShop
function XTheatre6Model:GetStageShopConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageShop, id)
end

---@return XTableTheatre6StageEffect
function XTheatre6Model:GetStageEffectConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6StageEffect, id)
end

---@return XTableTheatre6Activity
function XTheatre6Model:GetActivityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Activity, id)
end

---@return XTableTheatre6TagToBuff
function XTheatre6Model:GetTagToBuffConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6TagToBuff, id)
end

function XTheatre6Model:GetStoryFirstGuideId()
    return self:GetIntClientConfigValue("StoryFirstGuideId")
end

function XTheatre6Model:GetStoryRepeatGuideId()
    return self:GetIntClientConfigValue("StoryRepeatGuideId")
end

function XTheatre6Model:GetStoryAvgId()
    return self:GetIntConfigValue("StoryAvgId")
end

--一期没有天赋组，下期需要做源表
function XTheatre6Model:GetMaxTalentLv()
    if not self._TalentMaxLv then
        self._TalentMaxLv = 1
        for _, v in pairs(self:GetTalentConfigs()) do
            self._TalentMaxLv = math.max(self._TalentMaxLv, v.Level)
        end
    end
    return self._TalentMaxLv
end

---@return XTableTheatre6Condition
function XTheatre6Model:GetConditionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Theatre6Condition, id)
end

return XTheatre6Model