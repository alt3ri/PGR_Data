---Control部分类，此处用于注册和处理与配置表直接关联的读取接口
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')

function XTheatre6Control:GetIntConfigValue(key, index)
    return self._Model:GetIntConfigValue(key, index)
end

---@return XTableTheatre6StageDifficultyGroup
function XTheatre6Control:GetDifficultyGroupConfig(id)
    return self._Model:GetDifficultyGroupConfig(id)
end

---@return XTableTheatre6StageDifficulty
function XTheatre6Control:GetDifficultyConfig(id)
    return self._Model:GetDifficultyConfig(id)
end

---天赋树代币
function XTheatre6Control:GetTalentCoinId()
    return self._Model:GetConsumeId()
end

---故事线代币
function XTheatre6Control:GetTheatre6Coin()
    return self:GetIntConfigValue("Theatre6Coin")
end

---局外商店代币
function XTheatre6Control:GetRewardShopCoin()
    return self:GetIntClientConfigValue("ConsumeId")
end

function XTheatre6Control:GetIntClientConfigValue(key, index)
    return self._Model:GetIntClientConfigValue(key, index)
end

---@return XTableTheatre6BuildTag
function XTheatre6Control:GetBuildTagConfig(id)
    return self._Model:GetBuildTagConfig(id)
end

---@return XTableTheatre6KeyWord
function XTheatre6Control:GetKeyWordConfig(id)
    return self._Model:GetKeyWordConfig(id)
end

function XTheatre6Control:GetStoryLineId(characterId)
    return self._Model:GetStoryLineId(characterId)
end

function XTheatre6Control:GetCommonStoryLineIds()
    return self._Model:GetStoryLineIds(0)
end

---@return XTableTheatre6StoryLine
function XTheatre6Control:GetStoryLineConfig(id)
    return self._Model:GetStoryLineConfig(id)
end

---@return XTableTheatre6Character
function XTheatre6Control:GetCharacterConfig(id)
    return self._Model:GetCharacterConfig(id)
end

---@return XTableTheatre6Character[]
function XTheatre6Control:GetCharacterConfigs()
    return self._Model:GetCharacterConfigs()
end

---@return XTableTheatre6CharacterFashion
function XTheatre6Control:GetFashionConfig(id)
    return self._Model:GetFashionConfig(id)
end

---@return XTableTheatre6StageBuff
function XTheatre6Control:GetBuffConfig(id)
    return self._Model:GetBuffConfig(id)
end

---@return XTableTheatre6StageEffect
function XTheatre6Control:GetStageEffectConfig(id)
    return self._Model:GetStageEffectConfig(id)
end

---@return XTableTheatre6StageAnno
function XTheatre6Control:GetAnnoConfig(id)
    return self._Model:GetAnnoConfig(id)
end

---@return XTableTheatre6AttrPack
function XTheatre6Control:GetAttrPackCfgById(attrPackId)
    return self._Model:GetAttrPackConfig(attrPackId)
end

---@return XTableTheatre6Talent
function XTheatre6Control:GetTalentConfig(id)
    return self._Model:GetTalentConfig(id)
end

---@return XTableTheatre6Talent[]
function XTheatre6Control:GetTalentConfigs()
    return self._Model:GetTalentConfigs()
end

---@return XTableTheatre6Attr
function XTheatre6Control:GetAttrConfig(id)
    return self._Model:GetAttrConfig(id)
end

---@return XTableTheatre6Attr[]
function XTheatre6Control:GetAttrConfigs()
    return self._Model:GetAttrConfigs()
end

---获取按等级排序的等级配置列表
---@return XTableTheatre6Talent[]
function XTheatre6Control:GetSortedTalentConfigs()
    local configs = self:GetTalentConfigs()
    local list = {}
    for _, cfg in pairs(configs) do
        table.insert(list, cfg)
    end
    table.sort(list, function(a, b)
        return a.Level < b.Level
    end)
    return list
end

---@return XTableTheatre6StageRoom
function XTheatre6Control:GetStageRoomConfig(id)
    return self._Model:GetStageRoomConfig(id)
end

---@return XTableTheatre6Monster
function XTheatre6Control:GetMonsterCfgById(monsterId)
    return self._Model:GetMonsterCfgById(monsterId)
end

---获取怪物配置（别名）
---@return XTableTheatre6Monster
function XTheatre6Control:GetMonsterConfig(monsterId)
    return self._Model:GetMonsterCfgById(monsterId)
end

---获取难度文本
---@param difficultyType number 难度类型
---@return string
function XTheatre6Control:GetDifficultyText(difficultyType)
    local config = self:GetDifficultyConfig(difficultyType)
    return config and config.Name or ""
end

---@return XTableTheatre6StageFloor
function XTheatre6Control:GetStageFloorConfig(id)
    return self._Model:GetStageFloorConfig(id)
end

---@return XTableTheatre6Stage
function XTheatre6Control:GetStageConfig(id)
    return self._Model:GetStageConfig(id)
end

---@return string
function XTheatre6Control:GetClientConfigValue(key, index)
    return self._Model:GetClientConfigValue(key, index)
end

---@return XTableTheatre6StageGoods
function XTheatre6Control:GetStageGoodsConfig(id)
    return self._Model:GetStageGoodsConfig(id)
end

---@return XTableTheatre6StageChooseGroup
function XTheatre6Control:GetStageChooseGroupConfig(id)
    return self._Model:GetStageChooseGroupConfig(id)
end

---@return XTableTheatre6StageChoose
function XTheatre6Control:GetStageChooseConfig(id)
    return self._Model:GetStageChooseConfig(id)
end

---@return XTableTheatre6StageBuffPoolShow
function XTheatre6Control:GetStageBuffPoolShow(id)
    return self._Model:GetStageBuffPoolShow(id)
end

---@return XTableTheatre6RandomPool
function XTheatre6Control:GetRandomPoolConfig(id)
    return self._Model:GetRandomPoolConfig(id)
end

---@return XTableTheatre6StoryDetail
function XTheatre6Control:GetStoryDetailConfig(id)
    return self._Model:GetStoryDetailConfig(id)
end

---@return XTableTheatre6StageTaskGroup
function XTheatre6Control:GetStageTaskGroupConfig(id)
    return self._Model:GetStageTaskGroupConfig(id)
end

---@return XTableTheatre6StageTask
function XTheatre6Control:GetTaskConfig(id)
    return self._Model:GetTaskConfig(id)
end

---@return XTableTheatre6TagToBuff
function XTheatre6Control:GetTagToBuffConfig(id)
    return self._Model:GetTagToBuffConfig(id)
end

function XTheatre6Control:GetStoryFirstGuideId()
    return self._Model:GetStoryFirstGuideId()
end

function XTheatre6Control:GetStoryRepeatGuideId()
    return self._Model:GetStoryRepeatGuideId()
end

function XTheatre6Control:GetStoryAvgId()
    return self._Model:GetStoryAvgId()
end

---@return XTableTheatre6Condition
function XTheatre6Control:GetConditionConfig(id)
    return self._Model:GetConditionConfig(id)
end

---@return XTableTheatre6StageFight
function XTheatre6Control:GetStageFightCfgById(id)
    return self._Model:GetStageFightCfgById(id)
end

---替换 {Attr:属性Id} 占位符为角色当前属性值
---@param desc string
---@return string
function XTheatre6Control:ReplaceAttrPlaceholder(desc)
    if not desc or not string.find(desc, "{Attr:", 1, true) then
        return desc
    end
    local modelData = self:GetCurPlayModeData()
    return string.gsub(desc, "{Attr:(%d+)}", function(idStr)
        local attrId = tonumber(idStr)
        local attrData = modelData and modelData.Attrs[attrId]
        return tostring(attrData and attrData.Value or 0)
    end)
end

---获取技能描述
---@param skillId number 技能Id
---@param isShort boolean 是否获取短描述
function XTheatre6Control:GetSkillDesc(skillId, isShort)
    local config = self:GetSkillCfgById(skillId)
    local desc = isShort and config.ShortDesc or config.Desc
    if not desc then
        return nil
    end
    desc = self:ReplaceAttrPlaceholder(desc)
    desc = XUiHelper.ReplaceTextNewLine(desc)
    return CS.XTextManager.FormatString(desc, table.unpack(config.DescParams))
end

---获取遗物描述
---@param attrPackId number 遗物Id
---@param isShort boolean 是否获取短描述
function XTheatre6Control:GetAttrPackDesc(attrPackId, isShort)
    local config = self:GetAttrPackCfgById(attrPackId)
    local desc = isShort and config.ShortDesc or config.Desc
    if not desc then
        return nil
    end
    desc = XUiHelper.ReplaceTextNewLine(desc)
    return CS.XTextManager.FormatString(desc, table.unpack(config.DescParams))
end

---获取Buff描述
---@param buffId number BuffId
function XTheatre6Control:GetBuffDesc(buffId)
    local config = self:GetBuffConfig(buffId)
    if not config.Desc then
        return nil
    end
    local desc = XUiHelper.ReplaceTextNewLine(config.Desc)
    return CS.XTextManager.FormatString(desc, table.unpack(config.DescParams))
end

---根据房间类型获取房间图标
function XTheatre6Control:GetRoomIcon(roomType)
    local values = self._Model:GetClientConfigValues("RoomIcon")
    for i = 1, #values, 2 do
        if tonumber(values[i]) == roomType then
            return values[i + 1]
        end
    end
    return nil
end

return XTheatre6Control