local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")
local XBWMapQuestPinData = require("XModule/XBigWorldMap/XData/XBWMapQuestPinData")
local XBWMapVirtualPinData = require("XModule/XBigWorldMap/XData/XBWMapVirtualPinData")
local XBigWorldMapConfigModel = require("XModule/XBigWorldMap/XBigWorldMapConfigModel")

---@class XBigWorldMapModel : XBigWorldMapConfigModel
local XBigWorldMapModel = XClass(XBigWorldMapConfigModel, "XBigWorldMapModel")

function XBigWorldMapModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<number, XBWMapPinData[]>
    self._PinDataMap = {}
    ---@type table<number, XBWMapPinData[]>
    self._QuestPinDataMap = {}
    ---@type table<number, XBWMapPinData[]>
    self._VirtualPinDataMap = {}
    ---@type table<number, XBWMapPinData[]>
    self._BindPinDataMap = {}

    self._CurrentMapPinIdMap = {}
    self._CurrentTrackPins = {}
    self._CurrentAllTrackPins = {}
    self._TrackTemplateQuestIds = {}
    self._CollectionsCountMap = {}
    self._ActivateTeleporterMap = {}
    self._CoincidenceSceneObjectPlaceMap = {}
    self._CoincidenceNpcPlaceMap = {}
    self._CoincidenceReferenceMap = {}

    self._IsShieldBigMap = false

    self._CurrentAreaGroupData = {
        GroupId = 0,
        AreaId = 0,
    }

    self._NearDistance = 0

    self._MapScaleCache = 0

    self._AIMemoryGroups = {}

    --- 如果在小地图打开前获取，则用默认值
    self._LittleMapRadius = 114

    self:_InitTableKey()
end

function XBigWorldMapModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldMapModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._PinDataMap = {}
    self._QuestPinDataMap = {}

    self._CurrentMapPinIdMap = {}
    self._CurrentTrackPins = {}
    self._CollectionsCountMap = {}
    self._ActivateTeleporterMap = {}
    self._CoincidenceSceneObjectPlaceMap = {}
    self._CoincidenceNpcPlaceMap = {}
    self._CoincidenceReferenceMap = {}

    self._IsShieldBigMap = false

    self._MapScaleCache = 0

    self._CurrentAreaGroupData = {
        GroupId = 0,
        AreaId = 0,
    }

    self._AIMemoryGroups = {}
end

function XBigWorldMapModel:UpdateServerTrackMapPin(data)
    if data and XTool.IsNumberValid(data.TrackPinId) then
        self:TrackPins(data.LevelId, {
            [data.TrackPinId] = true,
        })
    end
end

function XBigWorldMapModel:UpdateLittleMapRadius(radius)
    self._LittleMapRadius = radius
end

function XBigWorldMapModel:InitPinData(worldId, levelId)
    local pinDatas = self:GetPinDatasByLevelId(levelId, true)

    if XTool.IsTableEmpty(pinDatas) then
        local maxId = 0
        local pinMap = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_LEVEL_MAP_PIN_CONFIGS, {
            MapPinLevelId = levelId,
        })
        local pinTextConfigs = {}

        pinDatas = {}
        XTool.LoopHashSet(pinMap.MapPinTextConfigs, function(value)
            pinTextConfigs[value.Id] = value
        end)
        XTool.LoopHashSet(pinMap.MapPinConfigs, function(value)
            ---@type XBWMapPinData
            local pinData = XBWMapPinData.New()
            local pinId = value.Id

            maxId = math.max(maxId, pinId)
            pinDatas[pinId] = pinData
            pinData:UpdateData(worldId, levelId, value, pinTextConfigs[value.Id])
        end)

        self._PinDataMap[levelId] = pinDatas
        self._CurrentMapPinIdMap[levelId] = maxId
    end
end

---@return table<number, XBWMapPinData>
function XBigWorldMapModel:GetPinDatasByLevelId(levelId, isNoTip)
    local pinDatas = self._PinDataMap[levelId]

    if XTool.IsTableEmpty(pinDatas) then
        if not isNoTip then
            XLog.Error("获取图钉数据失败! LevelId = " .. levelId)
        end

        return nil
    end

    return pinDatas
end

---@return XBWMapPinData
function XBigWorldMapModel:GetPinDataByLevelIdAndPinId(levelId, pinId, isNoTip)
    local pinDatas = self:GetPinDatasByLevelId(levelId, isNoTip)

    if not XTool.IsTableEmpty(pinDatas) then
        return pinDatas[pinId]
    end

    return nil
end

---@return table<number, XBWMapQuestPinData>
function XBigWorldMapModel:GetQuestPinDatasByQuestId(questId, isNoTip)
    local pinDatas = self._QuestPinDataMap[questId]

    if XTool.IsTableEmpty(pinDatas) then
        if not isNoTip then
            XLog.Error("获取任务图钉数据失败! QuestId = " .. questId)
        end

        return nil
    end

    return pinDatas
end

---@return table<number, XBWMapVirtualPinData>
function XBigWorldMapModel:GetVirtualPinDatasByReferId(referId, isNoTip)
    local pinDatas = self._VirtualPinDataMap[referId]

    if XTool.IsTableEmpty(pinDatas) then
        if not isNoTip then
            XLog.Error("获取虚拟图钉数据失败! ReferId = " .. referId)
        end

        return nil
    end

    return pinDatas
end

---@return table<number, XBWMapVirtualPinData>
function XBigWorldMapModel:GetVirtualPinDatasByBindId(bindId, isNoTip)
    local pinDatas = self._BindPinDataMap[bindId]

    if XTool.IsTableEmpty(pinDatas) then
        if not isNoTip then
            XLog.Error("获取虚拟图钉数据失败! BindId = " .. bindId)
        end

        return nil
    end

    return pinDatas
end

function XBigWorldMapModel:AddQuestMapPin(data)
    local levelId = data.LevelId
    local pinDatas = self:GetPinDatasByLevelId(levelId, true)
    local pinId = self:_GetGeneratePinIdByLevelId(levelId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(data.QuestId, true)
    ---@type XBWMapQuestPinData
    local pinData = XBWMapQuestPinData.New()

    pinData:UpdateData(pinId, data)
    questPinDatas = questPinDatas or {}
    questPinDatas[pinId] = pinData

    if pinDatas then
        if pinData:IsBindPlace() then
            for bindPinId, bindPinData in pairs(pinDatas) do
                if bindPinData:IsSceneObject() and bindPinData.SceneObjectPlaceId == pinData.TargetSceneObjectPlaceId then
                    self:_AddCoincidenceSceneObjectPlace(levelId, pinData.TargetSceneObjectPlaceId, bindPinId, pinData.PinId)
                    pinData.NearbyPinId = bindPinId
                    break
                end
                if bindPinData:IsNpc() and bindPinData.NpcPlaceId == pinData.TargetNpcPlaceId then
                    self:_AddCoincidenceNpcPlace(levelId, pinData.TargetNpcPlaceId, bindPinId, pinData.PinId)
                    pinData.NearbyPinId = bindPinId
                    break
                end
            end
        end

        pinDatas[pinId] = pinData
    else
        self._PinDataMap[data.LevelId] = {
            [pinId] = pinData,
        }
    end

    self._QuestPinDataMap[data.QuestId] = questPinDatas

    if self._TrackTemplateQuestIds[data.QuestId] then
        self:_TrackQuestMapPins(questPinDatas)
    end

    return pinId
end

function XBigWorldMapModel:ChangeMapPinShowType(levelId, pinId, showType)
    if not levelId or levelId <= 0 then
        return
    end
    if not pinId or pinId <= 0 then
        return
    end
    local pinDatas = self:GetPinDatasByLevelId(levelId)
    if not pinDatas then
        return
    end
    local pinData = pinDatas[pinId]
    if not pinData then
        XLog.Error("获取图钉数据失败! LevelId = " .. levelId .. ", PinId = " .. pinId)
        return
    end
    pinData:SetDisplayType(showType)
end

function XBigWorldMapModel:RemoveQuestMapPin(data)
    local questPinDatas = self:GetQuestPinDatasByQuestId(data.QuestId, true)

    if not XTool.IsTableEmpty(questPinDatas) then
        local pinDatas = self:GetPinDatasByLevelId(data.LevelId)
        local pinData = questPinDatas[data.PinId]

        questPinDatas[data.PinId] = nil
        self:_RemoveCoincidencePlace(pinData)
        self:TryCancelQuestTrackPins(data.LevelId, data.PinId)
        if not XTool.IsTableEmpty(pinDatas) then
            pinDatas[data.PinId] = nil
        end
    end
end

function XBigWorldMapModel:RemoveQuestAllMapPin(questId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(questId, true)

    self._TrackTemplateQuestIds[questId] = nil
    if not XTool.IsTableEmpty(questPinDatas) then
        for _, pinData in pairs(questPinDatas) do
            local pinDatas = self:GetPinDatasByLevelId(pinData.LevelId)

            self:_RemoveCoincidencePlace(pinData)
            self:RemoveVirtualMapPin(pinData.LevelId, pinData.PinId)
            self:TryCancelQuestTrackPins(pinData.LevelId, pinData.PinId)
            if not XTool.IsTableEmpty(pinDatas) then
                pinDatas[pinData.PinId] = nil
            end
        end

        self._QuestPinDataMap[questId] = nil
    end
end

---@return XBWMapVirtualPinData
function XBigWorldMapModel:AddVirtualMapPin(levelId, bindLevelId, bindPinId, referPinId)
    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, referPinId)

    if pinData then
        local pinId = self:_GetGeneratePinIdByLevelId(bindLevelId)
        local pinDatas = self:GetPinDatasByLevelId(bindLevelId, true)
        local virtualPinDatas = self:GetVirtualPinDatasByReferId(referPinId, true)
        local bindVirtualPinDatas = self:GetVirtualPinDatasByBindId(bindPinId, true)
        ---@type XBWMapVirtualPinData
        local virtualPinData = XBWMapVirtualPinData.New()

        virtualPinData:UpdateData(pinId, bindLevelId, bindPinId, pinData)

        if pinDatas then
            pinDatas[pinId] = virtualPinData
        else
            self._PinDataMap[bindLevelId] = {
                [pinId] = virtualPinData,
            }
        end
        if virtualPinDatas then
            virtualPinDatas[pinId] = virtualPinData
        else
            virtualPinDatas = {
                [pinId] = virtualPinData,
            }
            self._VirtualPinDataMap[referPinId] = virtualPinDatas
        end
        if bindVirtualPinDatas then
            bindVirtualPinDatas[pinId] = virtualPinData
        else
            bindVirtualPinDatas = {
                [pinId] = virtualPinData,
            }
            self._BindPinDataMap[bindPinId] = bindVirtualPinDatas
        end

        return virtualPinData
    end

    return nil
end

function XBigWorldMapModel:RemoveVirtualMapPin(levelId, referPinId)
    local virtualPinDatas = self:GetVirtualPinDatasByReferId(referPinId, true)

    if not XTool.IsTableEmpty(virtualPinDatas) then
        local pinDatas = self:GetPinDatasByLevelId(levelId, true)
        local result = {}

        for _, pinData in pairs(virtualPinDatas) do
            if pinData.LevelId == levelId then
                local bindDatas = self:GetVirtualPinDatasByBindId(pinData.BindPinId, true)
                
                if pinDatas then
                    pinDatas[pinData.PinId] = nil
                end
                if bindDatas then
                    bindDatas[pinData.PinId] = nil
                end
            else
                result[pinData.PinId] = pinData
            end
        end
        self._VirtualPinDataMap[referPinId] = result
    end
end

function XBigWorldMapModel:TrackQuestMapPins(questId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(questId, true)

    self._TrackTemplateQuestIds[questId] = true
    if not XTool.IsTableEmpty(questPinDatas) then
        self:_TrackQuestMapPins(questPinDatas)
    end
end

function XBigWorldMapModel:CancelTrackQuestMapPins(questId)
    local questPinDatas = self:GetQuestPinDatasByQuestId(questId, true)

    self._TrackTemplateQuestIds[questId] = nil
    if not XTool.IsTableEmpty(questPinDatas) then
        for _, pinData in pairs(questPinDatas) do
            self:TryCancelQuestTrackPins(pinData.LevelId, pinData.PinId)
        end
    end
end

function XBigWorldMapModel:DisplayMapPin(data)
    local levelId = data.MapPinLevelId
    local mapPinId = data.MapPinId
    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, mapPinId)

    if pinData then
        local virtualPinDatas = self:GetVirtualPinDatasByReferId(mapPinId, true)

        if not XTool.IsTableEmpty(virtualPinDatas) then
            for _, virtualPinData in pairs(virtualPinDatas) do
                if virtualPinData.LevelId == levelId then
                    virtualPinData:UpdateDisplay(data.Visible)
                end
            end
        end

        pinData:UpdateDisplay(data.Visible)
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_MAP_PIN_SHOW_TYPE)
end

function XBigWorldMapModel:TrackPins(levelId, pinIdMap, trackType)
    trackType = trackType or XEnumConst.BWMap.TrackType.Normal

    if not self._CurrentTrackPins[levelId] then
        self._CurrentTrackPins[levelId] = {}
    end

    self._CurrentTrackPins[levelId][trackType] = pinIdMap
    self:_SyncAllTrackPins(levelId, self._CurrentTrackPins[levelId])
end

function XBigWorldMapModel:CancelTrackPins(levelId, trackType)
    local trackPins = self:GetTrackPinsByLevelIdAndType(levelId, trackType)

    if not XTool.IsTableEmpty(trackPins) then
        for pinId, _ in pairs(trackPins) do
            self:ClearMapPinAssistedTrack(levelId, pinId)
        end
    end

    self:TrackPins(levelId, nil, trackType)
end

function XBigWorldMapModel:CancelTrackPinByPinId(targetLevelId, targetPinId)
    if not XTool.IsTableEmpty(self._CurrentTrackPins) then
        for levelId, trackData in pairs(self._CurrentTrackPins) do
            if levelId == targetLevelId then
                if not XTool.IsTableEmpty(trackData) then
                    for trackType, pinIdMap in pairs(trackData) do
                        if not XTool.IsTableEmpty(pinIdMap) then
                            for pinId, _ in pairs(pinIdMap) do
                                if pinId == targetPinId then
                                    self:CancelTrackSinglePin(targetLevelId, trackType, targetPinId)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function XBigWorldMapModel:CancelTrackSinglePin(levelId, trackType, pinId)
    local currrentPinIds = self:GetTrackPinsByLevelIdAndType(levelId, trackType)

    if not XTool.IsTableEmpty(currrentPinIds) then
        self:ClearMapPinAssistedTrack(levelId, pinId)
        currrentPinIds[pinId] = nil
        self:_SyncAllTrackPins(levelId, self._CurrentTrackPins[levelId])
    end
end

function XBigWorldMapModel:UpdateAssistedTrack(levelId, pinId, position, areaGroupId)
    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        pinData:UpdateTrackPosition(position, areaGroupId)
    end
end

function XBigWorldMapModel:UpdatePinPosition(levelId, pinId, position)
    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        pinData:UpdateWorldPosition(position)
    end
end

function XBigWorldMapModel:ClearMapPinAssistedTrack(levelId, pinId)
    self:UpdateAssistedTrack(levelId, pinId, nil)
end

function XBigWorldMapModel:TryCancelQuestTrackPins(levelId, pinId)
    self:CancelTrackSinglePin(levelId, XEnumConst.BWMap.TrackType.Quest, pinId)
end

function XBigWorldMapModel:GetAllTrackPinsByLevelId(levelId)
    return self._CurrentAllTrackPins[levelId]
end

function XBigWorldMapModel:GetTrackLevelPins()
    return self._CurrentTrackPins
end

function XBigWorldMapModel:GetTrackPinsByLevelIdAndType(levelId, trackType)
    trackType = trackType or XEnumConst.BWMap.TrackType.Normal

    if self._CurrentTrackPins[levelId] then
        return self._CurrentTrackPins[levelId][trackType]
    end

    return nil
end

function XBigWorldMapModel:SetCurrentAreaGroupData(groupId, areaId)
    self._CurrentAreaGroupData.GroupId = groupId
    self._CurrentAreaGroupData.AreaId = areaId
end

function XBigWorldMapModel:GetCurrentAreaGroupId()
    return self._CurrentAreaGroupData.GroupId or 0
end

function XBigWorldMapModel:GetCurrentAreaId()
    return self._CurrentAreaGroupData.AreaId or 0
end

function XBigWorldMapModel:ClearCurrentAreaGroupData()
    self._CurrentAreaGroupData.GroupId = 0
    self._CurrentAreaGroupData.AreaId = 0
end

function XBigWorldMapModel:GetIsShieldBigMap()
    return self._IsShieldBigMap
end

function XBigWorldMapModel:SetIsShieldBigMap(isShield)
    self._IsShieldBigMap = isShield or false
end

function XBigWorldMapModel:GetNearDistance()
    if XMain.IsEditorDebug then
        return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("MapPinNearDistance")
    end
    if not XTool.IsNumberValid(self._NearDistance) then
        self._NearDistance = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("MapPinNearDistance")
    end

    return self._NearDistance
end

function XBigWorldMapModel:GetMapScaleCache(defaultValue)
    if XTool.IsNumberValid(self._MapScaleCache) then
        return self._MapScaleCache
    end

    return defaultValue or 0
end

function XBigWorldMapModel:SetMapScaleCache(value)
    self._MapScaleCache = value
end

function XBigWorldMapModel:GetLevelName(levelId)
    return CS.StatusSyncFight.XLevelConfig.GetLevelName(levelId)
end

function XBigWorldMapModel:GetCollectionsCountByLevelId(levelId)
    return self._CollectionsCountMap[levelId] or 0
end

function XBigWorldMapModel:UpdateCollectionsCount(levelId, count)
    self._CollectionsCountMap[levelId] = count
end

function XBigWorldMapModel:UpdateAllCollectionsCount(collectionData)
    self._CollectionsCountMap = {}

    if not XTool.IsTableEmpty(collectionData) then
        for levelId, count in pairs(collectionData) do
            self:UpdateCollectionsCount(levelId, count)
        end
    end
end

function XBigWorldMapModel:GetActivateTeleportersByLevelId(levelId)
    return self._ActivateTeleporterMap[levelId]
end

function XBigWorldMapModel:UpdateActivateTeleporter(levelId, placeId)
    self._ActivateTeleporterMap[levelId] = self._ActivateTeleporterMap[levelId] or {}
    self._ActivateTeleporterMap[levelId][placeId] = true
end

function XBigWorldMapModel:UpdateAllActivateTeleporter(teleporterData)
    self._ActivateTeleporterMap = {}

    if not XTool.IsTableEmpty(teleporterData) then
        for levelId, teleporterIds in pairs(teleporterData) do
            for _, placeId in pairs(teleporterIds) do
                self:UpdateActivateTeleporter(levelId, placeId)
            end
        end
    end
end

function XBigWorldMapModel:GetCoincidenceSceneObjectPlaceMap(levelId)
    return self._CoincidenceSceneObjectPlaceMap[levelId]
end

function XBigWorldMapModel:GetCoincidenceNpcPlaceMap(levelId)
    return self._CoincidenceNpcPlaceMap[levelId]
end

function XBigWorldMapModel:GetCoincidenceReferenceMapByPinId(levelId, pinId)
    if not self._CoincidenceReferenceMap[levelId] then
        return nil
    end

    return self._CoincidenceReferenceMap[levelId][pinId]
end

function XBigWorldMapModel:GetAIMemoryIdsByGroupId(groupId)
    if not self._AIMemoryGroups[groupId] then
        local memoryGroup = {}
        local memoryConfigs = self:GetBigworldAIMemoryConfigs(groupId)

        if not XTool.IsTableEmpty(memoryConfigs) then
            for _, config in pairs(memoryConfigs) do
                if config.GroupId == groupId then
                    memoryGroup[config.Index] = config.Id
                end
            end
        end

        self._AIMemoryGroups[groupId] = memoryGroup
    end

    return self._AIMemoryGroups[groupId]
end

function XBigWorldMapModel:GetLittleMapRadius()
    return self._LittleMapRadius
end

function XBigWorldMapModel:_GetGeneratePinIdByLevelId(levelId)
    local pinId = self._CurrentMapPinIdMap[levelId] or 0

    pinId = pinId + 1
    self._CurrentMapPinIdMap[levelId] = pinId

    return pinId
end

---@param pinData XBWMapPinData
function XBigWorldMapModel:_RemoveCoincidencePlace(pinData)
    self:_RemoveCoincidenceSceneObjectPlace(pinData.LevelId, pinData.TargetSceneObjectPlaceId)
    self:_RemoveCoincidenceNpcPlace(pinData.LevelId, pinData.TargetNpcPlaceId)

    if XTool.IsNumberValid(pinData.TargetSceneObjectPlaceId) or XTool.IsNumberValid(pinData.TargetNpcPlaceId) then
        self:_RemoveCoincidenceReference(pinData.LevelId, pinData.PinId)
    end
end

function XBigWorldMapModel:_RemoveCoincidenceReference(levelId, targetPinId)
    if not XTool.IsNumberValid(targetPinId) then
        return
    end

    local referenceMap = self._CoincidenceReferenceMap[levelId]

    if not XTool.IsTableEmpty(referenceMap) then
        for pinId, pinIdMap in pairs(referenceMap) do
            if not XTool.IsTableEmpty(pinIdMap) then
                if pinIdMap[targetPinId] then
                    self._CoincidenceReferenceMap[levelId][pinId][targetPinId] = nil
                end
            end
        end
    end
end

function XBigWorldMapModel:_AddCoincidenceReference(levelId, bindPinId, pinId)
    if not self._CoincidenceReferenceMap[levelId] then
        self._CoincidenceReferenceMap[levelId] = {}
    end
    if not self._CoincidenceReferenceMap[levelId][bindPinId] then
        self._CoincidenceReferenceMap[levelId][bindPinId] = {}
    end
    self._CoincidenceReferenceMap[levelId][bindPinId][pinId] = true
end

function XBigWorldMapModel:_RemoveCoincidenceSceneObjectPlace(levelId, placeId)
    if XTool.IsNumberValid(placeId) then
        if self._CoincidenceSceneObjectPlaceMap[levelId] then
            self._CoincidenceSceneObjectPlaceMap[levelId][placeId] = nil
        end
    end
end

function XBigWorldMapModel:_AddCoincidenceSceneObjectPlace(levelId, placeId, bindPinId, pinId)
    if not self._CoincidenceSceneObjectPlaceMap[levelId] then
        self._CoincidenceSceneObjectPlaceMap[levelId] = {}
    end

    self._CoincidenceSceneObjectPlaceMap[levelId][placeId] = true
    self:_AddCoincidenceReference(levelId, bindPinId, pinId)
end

function XBigWorldMapModel:_RemoveCoincidenceNpcPlace(levelId, placeId)
    if XTool.IsNumberValid(placeId) then
        if self._CoincidenceNpcPlaceMap[levelId] then
            self._CoincidenceNpcPlaceMap[levelId][placeId] = nil
        end
    end
end

function XBigWorldMapModel:_AddCoincidenceNpcPlace(levelId, placeId, bindPinId, pinId)
    if not self._CoincidenceNpcPlaceMap[levelId] then
        self._CoincidenceNpcPlaceMap[levelId] = {}
    end

    self._CoincidenceNpcPlaceMap[levelId][placeId] = true
    self:_AddCoincidenceReference(levelId, bindPinId, pinId)
end

function XBigWorldMapModel:_SyncAllTrackPins(levelId, trackPinMap)
    self._CurrentAllTrackPins[levelId] = {}
    if not XTool.IsTableEmpty(trackPinMap) then
        for _, pinMap in pairs(trackPinMap) do
            if not XTool.IsTableEmpty(pinMap) then
                for pinId, _ in pairs(pinMap) do
                    self._CurrentAllTrackPins[levelId][pinId] = true
                end
            end
        end
    end
end

function XBigWorldMapModel:_TrackQuestMapPins(questPinDatas)
    if not XTool.IsTableEmpty(questPinDatas) then
        local trackPinIdMap = {}

        for _, pinData in pairs(questPinDatas) do
            local virtualDatas = self:GetVirtualPinDatasByReferId(pinData.PinId, true)

            if not XTool.IsTableEmpty(virtualDatas) then
                for _, virtualData in pairs(virtualDatas) do
                    trackPinIdMap[virtualData.LevelId] = trackPinIdMap[virtualData.LevelId] or {}
                    trackPinIdMap[virtualData.LevelId][virtualData.PinId] = true
                end
            end

            trackPinIdMap[pinData.LevelId] = trackPinIdMap[pinData.LevelId] or {}
            trackPinIdMap[pinData.LevelId][pinData.PinId] = true
        end

        for levelId, pinIdMap in pairs(trackPinIdMap) do
            self:TrackPins(levelId, pinIdMap, XEnumConst.BWMap.TrackType.Quest)
        end
    end
end

return XBigWorldMapModel
