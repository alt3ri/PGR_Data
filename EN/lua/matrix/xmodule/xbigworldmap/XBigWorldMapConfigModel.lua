---@class XBigWorldMapConfigModel : XModel
local XBigWorldMapConfigModel = XClass(XModel, "XBigWorldMapConfigModel")

local MapTableKey = {
    BigWorldMap = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "LevelId",
    },
    BigWorldMapAreaGroup = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "GroupId",
    },
    BigWorldMapArea = {
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "AreaId",
    },
    BigWorldMapPinStyle = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "StyleId",
    },
    BigWorldMapQuestPin = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "QuestType",
    },
    BigWorldMapLink = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "LevelId",
    },
    BigworldAIMemory = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldMapOverview = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Private,
    },
}

function XBigWorldMapConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Map", MapTableKey)
end

---@return XTableBigWorldMap[]
function XBigWorldMapConfigModel:GetBigWorldMapConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMap)
end

---@return XTableBigWorldMap
function XBigWorldMapConfigModel:GetBigWorldMapConfigByLevelId(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMap, levelId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapPosXByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.PosX
end

function XBigWorldMapConfigModel:GetBigWorldMapPosZByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.PosZ
end

function XBigWorldMapConfigModel:GetBigWorldMapPixelRatioByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.PixelRatio
end

function XBigWorldMapConfigModel:GetBigWorldMapWidthByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.Width
end

function XBigWorldMapConfigModel:GetBigWorldMapHeightByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.Height
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupTypeByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.AreaGroupType
end

function XBigWorldMapConfigModel:GetBigWorldMapMapNameByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.MapName
end

function XBigWorldMapConfigModel:GetBigWorldMapBaseImageByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.BaseImage
end

function XBigWorldMapConfigModel:GetBigWorldMapLittleMapScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.LittleMapScale
end

function XBigWorldMapConfigModel:GetBigWorldMapMaxScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.MaxScale
end

function XBigWorldMapConfigModel:GetBigWorldMapMinScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.MinScale
end

function XBigWorldMapConfigModel:GetBigWorldMapDefaultScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.DefaultScale
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewIdByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.OverviewId
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupIdsByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.AreaGroupIds
end

---@return XTableBigWorldMapAreaGroup[]
function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapAreaGroup)
end

---@return XTableBigWorldMapAreaGroup
function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupConfigByGroupId(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapAreaGroup, groupId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupFloorIndexByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    if not config then
        return 0
    end

    return config.FloorIndex
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupGroupNameByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    return config.GroupName
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupIconByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    return config.Icon
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupAreaIdsByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    return config.AreaIds
end

---@return XTableBigWorldMapArea[]
function XBigWorldMapConfigModel:GetBigWorldMapAreaConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapArea)
end

---@return XTableBigWorldMapArea
function XBigWorldMapConfigModel:GetBigWorldMapAreaConfigByAreaId(areaId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapArea, areaId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaPosXByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.PosX
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaPosZByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.PosZ
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaPixelRatioByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.PixelRatio
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaAreaNameByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.AreaName
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaAreaImageByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.AreaImage
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupIdByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.GroupId
end

---@return XTableBigWorldMapPinStyle[]
function XBigWorldMapConfigModel:GetBigWorldMapPinStyleConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapPinStyle)
end

---@return XTableBigWorldMapPinStyle
function XBigWorldMapConfigModel:GetBigWorldMapPinStyleConfigByStyleId(styleId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapPinStyle, styleId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapPinStyleActiveIconByStyleId(styleId)
    local config = self:GetBigWorldMapPinStyleConfigByStyleId(styleId)

    return config.ActiveIcon
end

function XBigWorldMapConfigModel:GetBigWorldMapPinStyleUnActiveIconByStyleId(styleId)
    local config = self:GetBigWorldMapPinStyleConfigByStyleId(styleId)

    return config.UnActiveIcon
end

function XBigWorldMapConfigModel:GetBigWorldMapPinStyleBriefIconByStyleId(styleId)
    local config = self:GetBigWorldMapPinStyleConfigByStyleId(styleId)

    return config.BriefIcon
end

function XBigWorldMapConfigModel:GetBigWorldMapPinStyleAreaColorByStyleId(styleId)
    local config = self:GetBigWorldMapPinStyleConfigByStyleId(styleId)

    return config.AreaColor
end

---@return XTableBigWorldMapQuestPin[]
function XBigWorldMapConfigModel:GetBigWorldMapQuestPinConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapQuestPin)
end

---@return XTableBigWorldMapQuestPin
function XBigWorldMapConfigModel:GetBigWorldMapQuestPinConfigByQuestType(questType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapQuestPin, questType, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapQuestPinStyleIdByQuestType(questType)
    local config = self:GetBigWorldMapQuestPinConfigByQuestType(questType)

    if not config then
        XLog.Error("XBigWorldMapConfigModel:GetBigWorldMapQuestPinStyleIdByQuestType questType = " .. questType ..
            " not found!")

        return 0
    end

    return config.StyleId
end

function XBigWorldMapConfigModel:GetBigWorldMapQuestPinSecondStyleIdByQuestType(questType)
    local config = self:GetBigWorldMapQuestPinConfigByQuestType(questType)

    if not config then
        XLog.Error("XBigWorldMapConfigModel:GetBigWorldMapQuestPinSecondStyleIdByQuestType questType = " ..
        questType .. " not found!")
        return 0
    end

    if config.SecondStyleId == 0 then
        XLog.Error("XBigWorldMapConfigModel:GetBigWorldMapQuestPinSecondStyleIdByQuestType questType = " ..
        questType .. ", SecondStyleId = 0 !")
    end

    return config.SecondStyleId
end

function XBigWorldMapConfigModel:GetBigWorldMapQuestPinReadyStyleIdByQuestType(questType)
    local config = self:GetBigWorldMapQuestPinConfigByQuestType(questType)

    if not config then
        XLog.Error("XBigWorldMapConfigModel:GetBigWorldMapQuestPinSecondStyleIdByQuestType questType = " ..
        questType .. " not found!")
        return 0
    end

    if config.ReadyStyleId == 0 then
        XLog.Error("XBigWorldMapConfigModel:GetBigWorldMapQuestPinSecondStyleIdByQuestType questType = " ..
        questType .. ", ReadyStyleId = 0 !")
    end

    return config.ReadyStyleId
end

---@return XTableBigWorldMapLink[]
function XBigWorldMapConfigModel:GetBigWorldMapLinkConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapLink)
end

---@return XTableBigWorldMapLink
function XBigWorldMapConfigModel:GetBigWorldMapLinkConfigByLevelId(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapLink, levelId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapLinkLinkLevelIdByLevelId(levelId)
    local config = self:GetBigWorldMapLinkConfigByLevelId(levelId)

    return config.LinkLevelId
end

function XBigWorldMapConfigModel:GetBigWorldMapLinkLinkWorldIdByLevelId(levelId)
    local config = self:GetBigWorldMapLinkConfigByLevelId(levelId)

    return config.LinkWorldId
end

function XBigWorldMapConfigModel:GetBigWorldMapLinkBindPinIdByLevelId(levelId)
    local config = self:GetBigWorldMapLinkConfigByLevelId(levelId)

    return config.BindPinId
end

---@return XTableBigworldAIMemory[]
function XBigWorldMapConfigModel:GetBigworldAIMemoryConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigworldAIMemory)
end

---@return XTableBigworldAIMemory
function XBigWorldMapConfigModel:GetBigworldAIMemoryConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigworldAIMemory, id, false)
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryGroupIdById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.GroupId
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryIndexById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.Index
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryConditionById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.Condition
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryLockedTitleById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.LockedTitle
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryLockedDescById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.LockedDesc
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryUnlockedTitleById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.UnlockedTitle
end

function XBigWorldMapConfigModel:GetBigworldAIMemoryUnlockedDescById(id)
    local config = self:GetBigworldAIMemoryConfigById(id)

    return config.UnlockedDesc
end

function XBigWorldMapConfigModel:GetBigworldAIMemorysByGroupId(groupId)
    if not self._AIMemoryGroupCache then
        self._AIMemoryGroupCache = {}
        for _, config in pairs(self:GetBigworldAIMemoryConfigs()) do
            if not self._AIMemoryGroupCache[config.GroupId] then
                self._AIMemoryGroupCache[config.GroupId] = {}
            end
            table.insert(self._AIMemoryGroupCache[config.GroupId], config)
        end
        for groupId, configs in pairs(self._AIMemoryGroupCache) do
            table.sort(configs, function(a, b) return a.Index < b.Index end)
        end
    end
    return self._AIMemoryGroupCache[groupId]
end

---@return XTableBigWorldMapOverview[]
function XBigWorldMapConfigModel:GetBigWorldMapOverviewConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapOverview)
end

---@return XTableBigWorldMapOverview
function XBigWorldMapConfigModel:GetBigWorldMapOverviewConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapOverview, id, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewNameById(id)
    local config = self:GetBigWorldMapOverviewConfigById(id)

    return config.Name
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewIconById(id)
    local config = self:GetBigWorldMapOverviewConfigById(id)

    return config.Icon
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewPosXById(id)
    local config = self:GetBigWorldMapOverviewConfigById(id)

    return config.PosX
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewPosYById(id)
    local config = self:GetBigWorldMapOverviewConfigById(id)

    return config.PosY
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewPrefabById(id)
    local config = self:GetBigWorldMapOverviewConfigById(id)

    return config.Prefab
end

function XBigWorldMapConfigModel:GetBigWorldMapOverviewBackgroundById(id)
    local config = self:GetBigWorldMapOverviewConfigById(id)

    return config.Background
end

return XBigWorldMapConfigModel
