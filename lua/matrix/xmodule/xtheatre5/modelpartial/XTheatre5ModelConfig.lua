local XTheatre5EnumConst = require("XModule/XTheatre5/XTheatre5EnumConst")
local tableInsert = table.insert
local TableNormal = {
    Theatre5Activity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5Rank = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5Config = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },
    Theatre5ClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },
    Theatre5TaskShop = { DirPath = XConfigUtil.DirectoryType.Client },
}

local TablePrivate = {
    Theatre5Character = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5CharacterFashion = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5CharacterLevel = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },

    Theatre5ItemSkill = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5RankMajor = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5Shop = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },


    Theatre5Item = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5ItemTag = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5ItemRuneAttr = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5AttrShow = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5ItemKeyWord = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },

    Theatre5ItemRune = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5PvpRoundRefresh = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'RoundNum' },
    Theatre5ShopRefreshCost = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    Theatre5GridUnlockCost = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'UnlockNum' },
    Theatre5ShopNpc = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre5ShopNpcChat = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre5Currency = {},
    Theatre5ItemBox = {},
    Theatre5Story = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre5StoryGroup = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre5Story = { DirPath = XConfigUtil.DirectoryType.Client },

    Theatre5RelicEffect = { DirPath = XConfigUtil.DirectoryType.Share, },
    Theatre5ItemRelic = { DirPath = XConfigUtil.DirectoryType.Share, },

    Theatre5UiStyle =  { DirPath = XConfigUtil.DirectoryType.Client },
}

local TableMission = {
    Theatre5Mission =  { DirPath = XConfigUtil.DirectoryType.Share },
    Theatre5MissionBounty =  { DirPath = XConfigUtil.DirectoryType.Share },
    Theatre5MissionCondition =  { DirPath = XConfigUtil.DirectoryType.Share },
    Theatre5MissionTriggerCondition =  { DirPath = XConfigUtil.DirectoryType.Share },
    Theatre5TriggerCondition =  { DirPath = XConfigUtil.DirectoryType.Share },
}

local PVETableKey = {
    Theatre5PveEventLevel = {},
    Theatre5PveChapter = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre5PveChapterLevel = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre5PveEvent = {},
    Theatre5PveEventGroup = {},
    Theatre5PveEventOption = {},
    Theatre5PveFight = {},
    Theatre5PveMonster = {},
    Theatre5PveStoryEntrance = {},
    Theatre5PveStoryLine = {},
    Theatre5PveStoryLineContent = {},
    Theatre5PveSceneChat = {},
    Theatre5PveEnding = { DirPath = XConfigUtil.DirectoryType.Client },
    Theatre5PveSceneChatStoryPool = {},
    Theatre5PveSceneChatObjectPool = {},
    Theatre5PveDeduceClue = {},
    Theatre5PveDeduceClueBoard = {},
    Theatre5PveDeduceClueGroup = {},
    Theatre5PveDeduceQuestion = {},
    Theatre5PveDeduceScript = {},
}

--- Model分部类，此处用于注册和处理与配置表直接关联的读取接口
---@type XTheatre5Model
local XTheatre5Model = XClassPartial('XTheatre5Model')

--- 配置表定义注册
function XTheatre5Model:InitConfigs()
    self._StoryLineContentCfgsDic = nil
    self._SceneChatCfgsDic = nil
    self._EventLevelCfgsDic = nil
    self._EventOptionCfgsDic = nil
    self._ChapterLevelCfgsDic = nil
    self._StoryEntranceCfgsDic = nil
    self._CharacterStoryEntranceCfgsDic = nil
    self._ShopNpcChatCfgsDic = nil
    self._SceneChateObjectPoolCfgsDic = nil
    self._ClueGroupCfgsDic = nil
    self._DeduceQuestionCfgsDic = nil
    self._TaskShopCfgsDic = nil
    self._DeduceClueByScriptIdDic = nil
    self._CharacterLevelGroups = nil
    self._ConfigUtil:InitConfigByTableKey('Theatre5', TableNormal, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('Theatre5', TablePrivate, XConfigUtil.CacheType.Private)
    self._ConfigUtil:InitConfigByTableKey('Theatre5/Theatre5Pve', PVETableKey)
    self._ConfigUtil:InitConfigByTableKey('Theatre5/TheatreMission', TableMission)
    
    self._MissionBountyGroups = nil
end

--- 清理与私有配置表有关的缓存
function XTheatre5Model:ReleasePriConfigCache()
    self._AttrType2IdMap = nil
    self._StoryLineContentCfgsDic = nil
    self._SceneChatCfgsDic = nil
    self._EventLevelCfgsDic = nil
    self._EventOptionCfgsDic = nil
    self._ChapterLevelCfgsDic = nil
    self._StoryEntranceCfgsDic = nil
    self._CharacterStoryEntranceCfgsDic = nil
    self._ShopNpcChatCfgsDic = nil
    self._SceneChateObjectPoolCfgsDic = nil
    self._ClueGroupCfgsDic = nil
    self._DeduceQuestionCfgsDic = nil
    self._TaskShopCfgsDic = nil
    self._DeduceClueByScriptIdDic = nil
    self._CharacterLevelGroups = nil
    self._MissionBountyGroups = nil
end

function XTheatre5Model:ReleaseNopriConfigCache()

end

--region Theatre5Activity.tab

---@return XTableTheatre5Activity
function XTheatre5Model:GetTheatre5ActivityCfgById(activityId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5Activity, activityId, notips)
end

function XTheatre5Model:GetTheatre5PVPWorldIdByActivityId(activityId)
    ---@type XTableTheatre5Activity
    local cfg = self:GetTheatre5ActivityCfgById(activityId)

    if cfg then
        return cfg.WorldId
    end
end

function XTheatre5Model:GetTheatre5PVEWorldIdByActivityId()
    local worldId = self:GetTheatre5ConfigValByKey('PveWorldId')
    return worldId or 0
end
--endregion

--region 排行榜、段位相关

function XTheatre5Model:GetTheatre5RankCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.Theatre5Rank)
end

function XTheatre5Model:GetTheatre5RankCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5Rank, id, notips)
end

function XTheatre5Model:GetTheatre5RankMajorCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5RankMajor)
end

function XTheatre5Model:GetTheatre5RankMajorCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5RankMajor, id, notips)
end

--endregion

--region 角色相关

function XTheatre5Model:GetTheatre5CharacterCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5Character)
end

---@return XTableTheatre5Character
function XTheatre5Model:GetTheatre5CharacterCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5Character, id, notips)
end

---@return XTableTheatre5CharacterFashion
function XTheatre5Model:GetTheatre5CharacterFashionCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5CharacterFashion, id, notips)
end

--endregion

--region 道具相关

---@return XTableTheatre5Item
function XTheatre5Model:GetTheatre5ItemCfgById(itemId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5Item, itemId, notips)
end

---@return XTableTheatre5Item[]
function XTheatre5Model:GetTheatre5ItemCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5Item)
end

function XTheatre5Model:GetTheatre5SkillCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemSkill, id, notips)
end

---@return XTableTheatre5ItemRune
function XTheatre5Model:GetTheatre5RuneCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemRune, id, notips)
end

function XTheatre5Model:GetTheatre5ItemTagCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemTag, id, notips)
end

function XTheatre5Model:GetTheatre5ItemTagCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5ItemTag)
end

function XTheatre5Model:GetTheatre5ItemKeyWordCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemKeyWord, id, notips)
end

function XTheatre5Model:GetTheatre5ItemRuneAttrCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemRuneAttr, id, notips)
end

function XTheatre5Model:GetTheatre5AttrShowCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5AttrShow)
end

function XTheatre5Model:GetTheatre5AttrShowCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5AttrShow, id, notips)
end

function XTheatre5Model:GetTheatre5AttrShowCfgByType(type)
    if self._AttrType2IdMap == nil then
        self._AttrType2IdMap = {}

        --- 属性显示的id用于显示次序，因此需要额外处理key=type的映射
        ---@type XTableTheatre5AttrShow[]
        local cfgs = self:GetTheatre5AttrShowCfgs()

        if cfgs then
            for i, v in pairs(cfgs) do
                self._AttrType2IdMap[v.AttrType] = i
            end
        end
    end

    local id = self._AttrType2IdMap[type]

    if XTool.IsNumberValid(id) then
        return self:GetTheatre5AttrShowCfgById(id)
    end
end

--- 宝珠品质颜色配置
function XTheatre5Model:GetClientConfigGemQualityColor(quality)
    local colorStr = self:GetTheatre5ClientConfigText('GemQualtyColors', quality)

    if not string.IsNilOrEmpty(colorStr) then
        colorStr = string.gsub(colorStr, '#', '')

        return XUiHelper.Hexcolor2Color(colorStr)
    end
end
--endregion

--region 商店相关
function XTheatre5Model:GetTheatre5PvpRoundRefreshCfgByRoundNum(roundNum, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5PvpRoundRefresh, roundNum, notips)
end

function XTheatre5Model:GetTheatre5ShopRefreshCostCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ShopRefreshCost, id, notips)
end

function XTheatre5Model:GetTheatre5GridUnlockCostCfgByUnlockNum(unlockNum, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5GridUnlockCost, unlockNum, notips)
end
--endregion

--region Theatre5Config.tab

function XTheatre5Model:GetTheatre5ConfigValByKey(key, index, notips)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5Config, key, notips)

    if cfg then
        index = index or 1

        local str = cfg.Values[index]

        if not string.IsNilOrEmpty(str) and string.IsFloatNumber(str) then
            return tonumber(str)
        end
    end

    return 0
end

function XTheatre5Model:GetTheatre5ConfigValListByKey(key, notips)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5Config, key, notips)
    if cfg then
        local valList = {}
        for _, value in ipairs(cfg.Values) do
            if not string.IsNilOrEmpty(value) and string.IsFloatNumber(value) then
                tableInsert(valList, tonumber(value))
            end
        end
        return valList
    end
end

--endregion

--region Theatre5ClientConfig.tab
function XTheatre5Model:GetTheatre5ClientConfigText(key, index, notips)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5ClientConfig, key, notips)

    if cfg then
        index = index or 1
        return cfg.Values[index] or ''
    end

    return ''
end

function XTheatre5Model:GetTheatre5ClientConfigNum(key, index, notips)
    local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5ClientConfig, key, notips)

    if cfg then
        index = index or 1

        local str = cfg.Values[index]

        if not string.IsNilOrEmpty(str) and string.IsFloatNumber(str) then
            return tonumber(str)
        end
    end

    return 0
end

--endregion

--region Theatre5Shop.tab

function XTheatre5Model:GetTheatre5ShopCfgById(shopId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5Shop, shopId, notips)
end

--endregion

---@return XTableTheatre5UiStyle[]
function XTheatre5Model:GetTheatre5UiStyleCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5UiStyle)
end

function XTheatre5Model:GetTheatre5ShopNpcCfg(shopNpcId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ShopNpc, shopNpcId, notips)
end

function XTheatre5Model:GetTheatre5ShopChatCfgs(shopChatGroupId)
    if not XTool.IsNumberValid(shopChatGroupId) then
        return
    end
    if not self._ShopNpcChatCfgsDic then
        self._ShopNpcChatCfgsDic = {}
    end
    if not self._ShopNpcChatCfgsDic[shopChatGroupId] then
        self._ShopNpcChatCfgsDic[shopChatGroupId] = {}
        local idPreix = shopChatGroupId * XTheatre5EnumConst.ShopNpcChatPreix
        for i = 1, XTheatre5EnumConst.ShopNpcChatPreix - 1 do
            local id = idPreix + i
            local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ShopNpcChat, id, true)
            if cfg then
                tableInsert(self._ShopNpcChatCfgsDic[shopChatGroupId], cfg)
            end
        end
    end
    return self._ShopNpcChatCfgsDic[shopChatGroupId]
end

function XTheatre5Model:GetRouge5CurrencyCfg(currencyId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5Currency, currencyId)
end

--region pve rouge

--故事线的所有content配置
function XTheatre5Model:GetContentCfgs(storyLineId)
    if not XTool.IsNumberValid(storyLineId) then
        return
    end
    if not self._StoryLineContentCfgsDic then
        self._StoryLineContentCfgsDic = {}
        local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveStoryLineContent)
        for _, cfg in pairs(allCfgs) do
            if not self._StoryLineContentCfgsDic[cfg.StoryLineId] then
                self._StoryLineContentCfgsDic[cfg.StoryLineId] = {}
            end
            tableInsert(self._StoryLineContentCfgsDic[cfg.StoryLineId], cfg)
        end
    end
    return self._StoryLineContentCfgsDic[storyLineId]
end

function XTheatre5Model:GetStoryLineContentCfg(storyLineContentId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveStoryLineContent, storyLineContentId, notips)
end

--获取一条故事线开始的contentId
function XTheatre5Model:GetFirstConentId(storyLineId)
    local contentCfgs = self:GetContentCfgs(storyLineId)
    if XTool.IsTableEmpty(contentCfgs) then
        return
    end
    return contentCfgs[1].ContentId
end

function XTheatre5Model:GetStoryLineCfg(storyLineId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveStoryLine, storyLineId, notips)
end

function XTheatre5Model:GetStoryLineCfgs()
    return self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveStoryLine)
end

function XTheatre5Model:GetPveChapterCfg(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveChapter, chapterId)
end

function XTheatre5Model:GetPveChapterLevelCfg(chapterLevelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveChapterLevel, chapterLevelId)
end

function XTheatre5Model:GetChapterLevelCfg(levelGroupId, level)
    local chapterLevelCfgs = self:GetPveChapterLevelCfgs(levelGroupId)
    if XTool.IsTableEmpty(chapterLevelCfgs) then
        return
    end
    for k, cfg in pairs(chapterLevelCfgs) do
        if cfg.Level == level then
            return cfg
        end
    end
end

function XTheatre5Model:GetChapterLevelDic()

end

function XTheatre5Model:GetPVEEventCfg(eventId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveEvent, eventId)
end

--一个聊天组中所有的配置
function XTheatre5Model:GetPveSceneChatCfgs(chatGroupId)
    if not XTool.IsNumberValid(chatGroupId) then
        return
    end
    if not self._SceneChatCfgsDic then
        self._SceneChatCfgsDic = {}
    end
    if not self._SceneChatCfgsDic[chatGroupId] then
        self._SceneChatCfgsDic[chatGroupId] = {}
        local idPreix = chatGroupId * XTheatre5EnumConst.PveSceneChatPreix
        for i = 1, XTheatre5EnumConst.PveSceneChatPreix - 1 do
            local id = idPreix + i
            local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveSceneChat, id, true)
            if cfg then
                tableInsert(self._SceneChatCfgsDic[chatGroupId], cfg)
            end
        end
    end
    return self._SceneChatCfgsDic[chatGroupId]
end

function XTheatre5Model:GetPveEndingCfg(endingId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveEnding, endingId)
end

--一个事件等级组中所有的配置
function XTheatre5Model:GetPveEventLevelCfgs(eventLevelGroupId)
    if not XTool.IsNumberValid(eventLevelGroupId) then
        return
    end
    if not self._EventLevelCfgsDic then
        self._EventLevelCfgsDic = {}
    end
    if not self._EventLevelCfgsDic[eventLevelGroupId] then
        self._EventLevelCfgsDic[eventLevelGroupId] = {}
        local idPreix = eventLevelGroupId * XTheatre5EnumConst.PveEventLevelPreix
        for i = 1, XTheatre5EnumConst.PveEventLevelPreix - 1 do
            local id = idPreix + i
            local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveEventLevel, id, true)
            if cfg then
                tableInsert(self._EventLevelCfgsDic[eventLevelGroupId], cfg)
            end
        end
    end
    return self._EventLevelCfgsDic[eventLevelGroupId]
end

--一个事件选项组中所有的配置
function XTheatre5Model:GetPveEventOptionCfgs(eventOptionGroupId)
    if not XTool.IsNumberValid(eventOptionGroupId) then
        return
    end
    if not self._EventOptionCfgsDic then
        self._EventOptionCfgsDic = {}
    end
    if not self._EventOptionCfgsDic[eventOptionGroupId] then
        self._EventOptionCfgsDic[eventOptionGroupId] = {}
        local idPreix = eventOptionGroupId * XTheatre5EnumConst.PveEventOptionPreix
        for i = 1, XTheatre5EnumConst.PveEventOptionPreix - 1 do
            local id = idPreix + i
            local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveEventOption, id, true)
            if cfg then
                tableInsert(self._EventOptionCfgsDic[eventOptionGroupId], cfg)
            end
        end
    end
    return self._EventOptionCfgsDic[eventOptionGroupId]
end

--一个章节中所有的关卡配置
function XTheatre5Model:GetPveChapterLevelCfgs(levelGroupId)
    if not XTool.IsNumberValid(levelGroupId) then
        return
    end
    if not self._ChapterLevelCfgsDic then
        self._ChapterLevelCfgsDic = {}
    end
    if not self._ChapterLevelCfgsDic[levelGroupId] then
        self._ChapterLevelCfgsDic[levelGroupId] = {}
        local idPreix = levelGroupId * XTheatre5EnumConst.PveChapterLevelPreix
        for i = 1, XTheatre5EnumConst.PveChapterLevelPreix - 1 do
            local id = idPreix + i
            local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveChapterLevel, id, true)
            if cfg then
                tableInsert(self._ChapterLevelCfgsDic[levelGroupId], cfg)
            end
        end
    end
    return self._ChapterLevelCfgsDic[levelGroupId]
end

--得到章节最大关卡的配置
function XTheatre5Model:GetMaxChapterLevelCfg(chapterId)
    local chapterCfg = self:GetPveChapterCfg(chapterId)
    if not chapterCfg then
        return
    end
    local chapterLevelCfgs = self:GetPveChapterLevelCfgs(chapterCfg.LevelGroup)
    if XTool.IsTableEmpty(chapterLevelCfgs) then
        return
    end
    local maxLevel = 0
    local maxChapterLevelCfg = nil
    for _, cfg in pairs(chapterLevelCfgs) do
        if cfg.Level > maxLevel then
            maxChapterLevelCfg = cfg
            maxLevel = cfg.Level
        end
    end
    return maxChapterLevelCfg
end

function XTheatre5Model:GetPveEventOptionCfg(eventOptionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveEventOption, eventOptionId)
end

function XTheatre5Model:GetPVEEndingCfg(pveEndingId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveEnding, pveEndingId)
end

function XTheatre5Model:GetPveSceneChatStoryPoolCfg(chatStoryPoolId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveSceneChatStoryPool, chatStoryPoolId)
end

function XTheatre5Model:GetItemBoxCfg(itemBoxId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemBox, itemBoxId)
end

function XTheatre5Model:GetStoryById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5Story, id, true)
end

function XTheatre5Model:GetStoryGroup()
    return self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5StoryGroup)
end

function XTheatre5Model:GetPveStoryEntranceCfg(entranceName)
    -- 4.1 开始，优先进入共通线
    local commonCfg = self:_TryGetPveCommonStoryEntranceCfg()

    if commonCfg then
        return commonCfg, true
    end

    -- 从3.8开始，同一个入口根据角色进度不同，实现不同的功能
    local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveStoryEntrance)
    local isValid = false
    for _, cfg in pairs(allCfgs) do
        if cfg.SceneObject == entranceName then
            isValid = true
            local isOpen = true
            if cfg.BtnOpenCondition ~= 0 then
                isOpen = XConditionManager.CheckCondition(cfg.BtnOpenCondition)
            end
            if isOpen then
                if cfg.BtnCloseCondition ~= 0 then
                    if XConditionManager.CheckCondition(cfg.BtnCloseCondition) then
                        isOpen = false
                    end
                end
            end
            if isOpen then
                return cfg, isValid
            end
        end
    end
    -- 如果找不到可以开启的
    return false, isValid
    --if not self._StoryEntranceCfgsDic then
    --    self._StoryEntranceCfgsDic = {}
    --    local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveStoryEntrance)
    --    for _, cfg in pairs(allCfgs) do
    --        if cfg.SceneObject then
    --            self._StoryEntranceCfgsDic[cfg.SceneObject] = cfg
    --        end
    --    end
    --end
    --return self._StoryEntranceCfgsDic[entranceName]
end

function XTheatre5Model:_TryGetPveCommonStoryEntranceCfg()
    local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveStoryEntrance)

    local selectCfg = nil

    for _, cfg in pairs(allCfgs) do
        -- 获取对应故事线配置
        if XTool.IsNumberValidEx(cfg.StoryLine) then
            ---@type XTableTheatre5PveStoryLine
            local storyLineCfg = self:GetStoryLineCfg(cfg.StoryLine)

            -- 如果对应故事线是共通线
            if storyLineCfg and storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Together then
                local isOpen = true

                if XTool.IsNumberValidEx(cfg.BtnOpenCondition) then
                    isOpen = XConditionManager.CheckCondition(cfg.BtnOpenCondition)
                end

                if isOpen then
                    if XTool.IsNumberValidEx(cfg.BtnCloseCondition) then
                        if XConditionManager.CheckCondition(cfg.BtnCloseCondition) then
                            isOpen = false
                        end
                    end
                end

                if isOpen then
                    selectCfg = cfg
                    break
                end
            end
        end
    end

    -- 如果有解锁的共通线，判断是否结束
    if selectCfg then
        local storyLines = self.PVERougeData:GetPveStoryLines()
        if not XTool.IsTableEmpty(storyLines) then
            for _, storyLineData in pairs(storyLines) do
                if storyLineData.StoryLineId == selectCfg.StoryLine then
                    if not XTool.IsNumberValid(storyLineData.CurContentId) then
                        selectCfg = nil
                    end
                end
            end
        end
    end

    return selectCfg
end

--获取角色自己的故事线
function XTheatre5Model:GetCharacterPveStoryEntranceCfg(characterId)
    if not self._CharacterStoryEntranceCfgsDic then
        self._CharacterStoryEntranceCfgsDic = {}
        local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveStoryEntrance)
        for _, cfg in pairs(allCfgs) do
            local storyLineCfg = self:GetStoryLineCfg(cfg.StoryLine, true)
            if storyLineCfg and storyLineCfg.StoryLineType == XTheatre5EnumConst.PVEStoryLineType.Normal
                    and not XTool.IsTableEmpty(storyLineCfg.StoryLineCharacter) then
                self._CharacterStoryEntranceCfgsDic[storyLineCfg.StoryLineCharacter[1]] = cfg
            end
        end
    end
    return self._CharacterStoryEntranceCfgsDic[characterId]
end

--获得故事线配置的第一个角色，用于非共通线
function XTheatre5Model:GetFirstCharacterId(storyLineId)
    local storyLineCfg = self:GetStoryLineCfg(storyLineId)
    if storyLineCfg and not XTool.IsTableEmpty(storyLineCfg.StoryLineCharacter) then
        return storyLineCfg.StoryLineCharacter[1]
    end
end

--点击物品的对话池
function XTheatre5Model:GetPveSceneChatObjectPoolCfgs(sceneObject)
    if not self._SceneChateObjectPoolCfgsDic then
        self._SceneChateObjectPoolCfgsDic = {}
        local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveSceneChatObjectPool)
        for _, cfg in pairs(allCfgs) do
            if not self._SceneChateObjectPoolCfgsDic[cfg.SceneObject] then
                self._SceneChateObjectPoolCfgsDic[cfg.SceneObject] = {}
            end
            tableInsert(self._SceneChateObjectPoolCfgsDic[cfg.SceneObject], cfg)
        end
    end
    return self._SceneChateObjectPoolCfgsDic[sceneObject]

end

function XTheatre5Model:GetDeduceClueCfg(deduceClueId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveDeduceClue, deduceClueId)
end

function XTheatre5Model:GetDeduceClueCfgByScriptId(deduceScriptId)
    if not self._DeduceClueByScriptIdDic then
        self._DeduceClueByScriptIdDic = {}
        local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveDeduceClue)
        for _, cfg in pairs(allCfgs) do
            if XTool.IsNumberValid(cfg.ScriptId) then
                self._DeduceClueByScriptIdDic[cfg.ScriptId] = cfg
            end
        end
    end
    return self._DeduceClueByScriptIdDic[deduceScriptId]
end

function XTheatre5Model:GetDeduceScriptCfg(deduceScriptId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveDeduceScript, deduceScriptId)
end

function XTheatre5Model:GetDeduceClueBoardCfgs()
    local allCfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveDeduceClueBoard)
    local allCfgList = XTool.ToArray(allCfgs)
    table.sort(allCfgList, function(a, b)
        if a.Sort ~= b.Sort then
            return a.Sort < b.Sort
        end
        return a.Id < b.Id
    end)
    return allCfgList
end

function XTheatre5Model:GetDeduceClueBoardCfg(deduceClueBoardId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveDeduceClueBoard, deduceClueBoardId)
end

function XTheatre5Model:GetDeduceClueGroupCfgs(clueGroupId)
    if not XTool.IsNumberValid(clueGroupId) then
        return
    end
    if not self._ClueGroupCfgsDic then
        self._ClueGroupCfgsDic = {}
        local cfgs = self._ConfigUtil:GetByTableKey(PVETableKey.Theatre5PveDeduceClueGroup)
        for _, cfg in pairs(cfgs) do
            if not self._ClueGroupCfgsDic[cfg.GroupId] then
                self._ClueGroupCfgsDic[cfg.GroupId] = {}
            end
            tableInsert(self._ClueGroupCfgsDic[cfg.GroupId], cfg)
        end
    end
    return self._ClueGroupCfgsDic[clueGroupId]
end

--推演问题组所有的问题
function XTheatre5Model:GetPveDeduceQuestionCfgs(questionGroupId)
    if not XTool.IsNumberValid(questionGroupId) then
        return
    end
    if not self._DeduceQuestionCfgsDic then
        self._DeduceQuestionCfgsDic = {}
    end
    if not self._DeduceQuestionCfgsDic[questionGroupId] then
        self._DeduceQuestionCfgsDic[questionGroupId] = {}
        local idPreix = questionGroupId * XTheatre5EnumConst.DeduceQuestionPreix
        for i = 1, XTheatre5EnumConst.DeduceQuestionPreix - 1 do
            local id = idPreix + i
            local cfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(PVETableKey.Theatre5PveDeduceQuestion, id, true)
            if cfg then
                tableInsert(self._DeduceQuestionCfgsDic[questionGroupId], cfg)
            end
        end
        for _, cfgs in pairs(self._DeduceQuestionCfgsDic) do
            table.sort(cfgs, function(a, b)
                if a.Step ~= b.Step then
                    return a.Step < b.Step
                else
                    return a.Id < b.Id
                end
            end)
        end
    end
    return self._DeduceQuestionCfgsDic[questionGroupId]
end

--得到商店或任务页签的配置
function XTheatre5Model:GetTaskOrShopCfgs(taskShopType)
    if not self._TaskShopCfgsDic then
        self._TaskShopCfgsDic = {}
        local allCfgs = self._ConfigUtil:GetByTableKey(TableNormal.Theatre5TaskShop)
        for _, cfg in pairs(allCfgs) do
            if not self._TaskShopCfgsDic[cfg.Type] then
                self._TaskShopCfgsDic[cfg.Type] = {}
            end
            tableInsert(self._TaskShopCfgsDic[cfg.Type], cfg)
        end
        for _, cfgs in pairs(self._TaskShopCfgsDic) do
            table.sort(cfgs, function(a, b)
                if a.Sort ~= b.Sort then
                    return a.Sort < b.Sort
                else
                    return a.Id < b.Id
                end
            end)
        end
    end
    return self._TaskShopCfgsDic[taskShopType]
end

function XTheatre5Model:GetTaskOrShopCfg(taskShopId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.Theatre5TaskShop, taskShopId, notips)
end

function XTheatre5Model:SaveData(key, value)
    self._SaveUtil:SaveData(key, value)
end

function XTheatre5Model:GetData(key)
    return self._SaveUtil:GetData(key)
end

--endregion

--region 升级、饰品

---@param adventureData XTheatre5PVEAdventureData|XTheatre5PVPAdventureData
function XTheatre5Model:GetCharacterLevelConfig(adventureData, level)
    local group = self:GetCharacterLevelGroupConfig(adventureData)
    if group then
        level = level or adventureData:GetCharacterLevel()
        return group[level]
    end
end

function XTheatre5Model:GetMaxLevel()
    local group = self:GetCharacterLevelGroupConfig(self.CurAdventureData)
    local level = 0
    for i, v in pairs(group) do
        if level <= v.Level then
            level = v.Level
        end
    end
    return level
end

-- region character level and exp
---@param adventureData XTheatre5PVEAdventureData|XTheatre5PVPAdventureData
---@return XTableTheatre5CharacterLevel[]
function XTheatre5Model:GetCharacterLevelGroupConfig(adventureData)
    if not adventureData then
        XLog.Error("[XTheatre5Model] GetCharacterLevelConfig adventureData为空喔有问题")
        return {}
    end
    local gameMode = adventureData:GetGameMode()
    local groupId
    if gameMode == XTheatre5EnumConst.GameMode.PVP then
        groupId = self:GetTheatre5ConfigValByKey("PvpLevelGroup")
    elseif gameMode == XTheatre5EnumConst.GameMode.PVE then
        local chapterId = adventureData:GetChapterId()
        if chapterId == 0 then
            -- 结算时，获取不到chapterId
            chapterId = adventureData:GetChapterIdCompleted()
            if chapterId == 0 then
                XLog.Error("[XTheatre5Model] 找不到对应的等级配置, Theatre5PveChapter:" .. tostring(chapterId))
                return {}
            end
        end
        local chapter = self:GetPveChapterCfg(chapterId)
        if chapter then
            groupId = chapter.LevelGroup
        else
            XLog.Error("[XTheatre5Model] 找不到对应的等级配置, Theatre5PveChapter:" .. tostring(chapterId))
        end
    else
        XLog.Error("[XTheatre5Model] 找不到对应的等级配置:" .. tostring(gameMode))
    end

    if groupId then
        if not self._CharacterLevelGroups then
            self._CharacterLevelGroups = {}
        end
        if not self._CharacterLevelGroups[groupId] then
            ---@type XTableTheatre5CharacterLevel[]
            local configs = self._ConfigUtil:GetByTableKey(TablePrivate.Theatre5CharacterLevel)
            local group = {}
            for i, config in pairs(configs) do
                if config.GroupId == groupId then
                    group[config.Level] = config
                end
            end
            self._CharacterLevelGroups[groupId] = group
        end
        return self._CharacterLevelGroups[groupId]
    else
        XLog.Error("[XTheatre5Model] 找不到对应的等级配置, Theatre5CharacterLevel")
    end
end

function XTheatre5Model:GetCharacterLevelAttr(characterId, level, attribs)
    attribs = attribs or {}

    -- 怪物等级是0，不参与属性计算
    if level < 1 then
        return attribs
    end
    
    local characterConfig = self:GetTheatre5CharacterCfgById(characterId)
    if not characterConfig then
        XLog.Error("[XTheatre5CharacterControl] 获取角色配置失败")
        return attribs
    end

    if characterConfig.PromotedAttrId and characterConfig.PromotedAttrId ~= 0 then
        ---@type XTableAttribBase
        local attrCfg = XMVCA.XDlcWorld:GetAttributeConfigById(characterConfig.PromotedAttrId)
        if attrCfg and next(attrCfg) then
            local DlcWorldAttribMultyBase = 1000 -- 基础属性配置值乘法基数
            for k, v in pairs(attrCfg) do
                local attribType = XDlcNpcAttribType[k]
                if type(attribType) == 'number' and type(v) == 'number' then
                    local add
                    if XTheatre5EnumConst.EnlargedAttribs[attribType] then
                        add = XMath.ToMinInt(v * (level - 1) * DlcWorldAttribMultyBase)
                    else
                        add = v * (level - 1)
                    end
                    local key = XDlcNpcAttribType[k]
                    attribs[key] = attribs[key] or 0
                    attribs[key] = attribs[key] + add
                end
            end
            return attribs
        end
    end
    XLog.Error("[XTheatre5CharacterControl] 获取角色等级属性失败" .. tostring(characterId))
    return attribs
end
--

-- 获取强化锤的实例id
function XTheatre5Model:GetHammerInstanceId()
    if not self.CurAdventureData then
        XLog.Error("[XTheatre5Model] 获取锤子道具实例id失败, CurAdventureData为空")
        return
    end
    if not self.CurAdventureData.BagData then
        XLog.Error("[XTheatre5Model] 获取锤子道具实例id失败, CurAdventureData.BagData为空")
        return
    end
    local bagData = self.CurAdventureData.BagData
    if bagData.BagItemDict then
        local bagItemDict = bagData.BagItemDict
        for _, item in pairs(bagItemDict) do
            local itemId = item.ItemId
            local itemConfig = self:GetTheatre5ItemCfgById(itemId)
            if itemConfig then
                if itemConfig.Type == XTheatre5EnumConst.ItemType.Hammer then
                    return item.InstanceId
                end
            end
        end
    else
        XLog.Error("[XTheatre5Model] 获取锤子道具实例id失败, bagData.BagItemDict or bagData.TempItemDict为空")
    end
    local tempItemDict = bagData.TempItemDict
    if tempItemDict then
        for _, item in pairs(tempItemDict) do
            local itemId = item.ItemId
            local itemConfig = self:GetTheatre5ItemCfgById(itemId)
            if itemConfig then
                if itemConfig.Type == XTheatre5EnumConst.ItemType.Hammer then
                    return item.InstanceId
                end
            end
        end
    else
        XLog.Error("[XTheatre5Model] 获取锤子道具实例id失败, bagData.TempItemDict为空")
    end
    XLog.Warning("[XTheatre5Model] 找不到锤子道具")
end

function XTheatre5Model:GetTheatre5RelicCfgById(relicId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5ItemRelic, relicId)
end

function XTheatre5Model:GetTheatre5RelicEffectCfgById(effectId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.Theatre5RelicEffect, effectId)
end

function XTheatre5Model:GetRelicEffectConfigs(relicId)
    local relicConfig = self:GetTheatre5RelicCfgById(relicId)
    if relicConfig then
        local effectConfigs = {}
        local effects = relicConfig.Effect
        for i = 1, #effects do
            local effectId = effects[i]
            local effectConfig = self:GetTheatre5RelicEffectCfgById(effectId)
            if effectConfig then
                table.insert(effectConfigs, {
                    EffectConfig = effectConfig,
                    Condition = relicConfig.Condition[i],
                })
            else
                XLog.Error("[XTheatre5Model] 找不到对应的饰品效果配置:" .. tostring(effectId))
            end
        end
        return effectConfigs
    else
        XLog.Error("[XTheatre5Model] 找不到对应的饰品配置:" .. tostring(relicId))
    end
end

--endregion

--region 任务

function XTheatre5Model:GetMissionBountyComboId(bountyId, level)
    return bountyId * 10 + level
end

---@return XTableTheatre5Mission
function XTheatre5Model:GetTableMissionCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableMission.Theatre5Mission, id, notips)
end

---@return XTableTheatre5Mission[]
function XTheatre5Model:GetTheatre5MissionCfgs()
    return self._ConfigUtil:GetByTableKey(TableMission.Theatre5Mission)
end

---@return XTableTheatre5MissionCondition
function XTheatre5Model:GetTableMissionConditionCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableMission.Theatre5MissionCondition, id, notips)
end

---@return XTableTheatre5MissionBounty
function XTheatre5Model:GetTheatre5MissionBountyCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableMission.Theatre5MissionBounty, id, notips)
end

---@return XTableTheatre5MissionBounty[]
function XTheatre5Model:GetTheatre5MissionBountyGroupByBountyId(bountyId)
    if self._MissionBountyGroups == nil then
        ---@type table<number, XTableTheatre5MissionBounty[]>
        self._MissionBountyGroups = {}
    end
    
    local group = self._MissionBountyGroups[bountyId]

    if not group then
        group = {}
        
        local cfgs = self._ConfigUtil:GetByTableKey(TableMission.Theatre5MissionBounty)
        
        -- id规则为 bounty * 10 + level
        for i = 1, 9 do
            local id = bountyId * 10 + i
            local cfg = cfgs[id]

            if cfg then
                table.insert(group, cfg)
            else
                break    
            end
        end

        self._MissionBountyGroups[bountyId] = group
    end
    
    return group
end
--endregion


return XTheatre5Model