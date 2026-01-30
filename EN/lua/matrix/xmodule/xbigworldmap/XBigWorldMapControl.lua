---@class XBigWorldMapControl : XControl
---@field private _Model XBigWorldMapModel
local XBigWorldMapControl = XClass(XControl, "XBigWorldMapControl")

function XBigWorldMapControl:OnInit()
    -- 初始化内部变量
end

function XBigWorldMapControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldMapControl:RemoveAgencyEvent()

end

function XBigWorldMapControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

function XBigWorldMapControl:InitMapData(worldId, levelId)
    if XTool.IsNumberValid(levelId) and XTool.IsNumberValid(worldId) then
        self._Model:InitPinData(worldId, levelId)
    end
end

function XBigWorldMapControl:GetCurrentCameraTransform()
    local camera = XMVCA.XBigWorldGamePlay:GetCamera()

    if not camera then
        return nil
    end

    return camera.transform
end

function XBigWorldMapControl:GetCurrentAreaGroupId()
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetCurrentAreaGroupId()
end

---@return XBWMapPinData[]
function XBigWorldMapControl:GetMapPinDatasByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapPinDatasByLevelId(levelId)
end

---@return XBWMapPinData[]
function XBigWorldMapControl:GetMapPinDatasByLevelIdAndGroupId(levelId, groupId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapPinDatasByLevelIdAndGroupId(levelId, groupId)
end

---@return XBWMapPinData
function XBigWorldMapControl:GetPinDataByLevelIdAndPinId(levelId, pinId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetPinDataByLevelIdAndPinId(levelId, pinId)
end

---@return table<number, XBWMapPinData>
function XBigWorldMapControl:GetPinDatasByBindId(bindId, isNoTip)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetPinDatasByBindId(bindId, isNoTip)
end

function XBigWorldMapControl:GetMapPosXByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapPosXByLevelId(levelId)
end

function XBigWorldMapControl:GetMapPosZByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapPosZByLevelId(levelId)
end

function XBigWorldMapControl:GetMapPixelRatioByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapPixelRatioByLevelId(levelId)
end

function XBigWorldMapControl:GetMapNameByLevelId(levelId)
    return self._Model:GetBigWorldMapMapNameByLevelId(levelId)
end

function XBigWorldMapControl:GetMapImageByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapImageByLevelId(levelId)
end

function XBigWorldMapControl:GetMapMaxScaleByLevelId(levelId)
    return self._Model:GetBigWorldMapMaxScaleByLevelId(levelId)
end

function XBigWorldMapControl:GetMapMinScaleByLevelId(levelId)
    return self._Model:GetBigWorldMapMinScaleByLevelId(levelId)
end

function XBigWorldMapControl:GetLittleMapScaleByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetLittleMapScaleByLevelId(levelId)
end

function XBigWorldMapControl:GetMapWidthByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapWidthByLevelId(levelId)
end

function XBigWorldMapControl:GetMapHeightByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapHeightByLevelId(levelId)
end

function XBigWorldMapControl:GetMapGroupIdsByLevelId(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetMapGroupIdsByLevelId(levelId)
end

function XBigWorldMapControl:GetPinGroupIdByLevelIdAndPinId(levelId, pinId)
    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        return pinData:GetAreaGroupId()
    end

    return self:GetCurrentAreaGroupId()
end

function XBigWorldMapControl:GetFloorIndexByGroupId(groupId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetFloorIndexByGroupId(groupId)
end

function XBigWorldMapControl:GetAreaIdsByGroupId(groupId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetAreaIdsByGroupId(groupId)
end

function XBigWorldMapControl:GetMapAreaGroupNameByGroupId(groupId)
    return self._Model:GetBigWorldMapAreaGroupGroupNameByGroupId(groupId)
end

function XBigWorldMapControl:GetAreaNameByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaAreaNameByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaImageByAreaId(areaId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetAreaImageByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaPosXByAreaId(areaId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetAreaPosXByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaPosZByAreaId(areaId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetAreaPosZByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaPixelRatioByAreaId(areaId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetAreaPixelRatioByAreaId(areaId)
end

function XBigWorldMapControl:GetPinActiveIconByStyleId(styleId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetPinActiveIconByStyleId(styleId)
end

function XBigWorldMapControl:GetPinUnActiveIconByStyleId(styleId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetPinUnActiveIconByStyleId(styleId)
end

function XBigWorldMapControl:GetPinIconByStyleId(styleId, isActive)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetPinIconByStyleId(styleId, isActive)
end

function XBigWorldMapControl:GetPinBriefIconByStyleId(styleId)
    return self._Model:GetBigWorldMapPinStyleBriefIconByStyleId(styleId)
end

function XBigWorldMapControl:GetCollectableCount(levelId)
    return CS.StatusSyncFight.XLevelConfig.GetLevelCollectableSceneObjectCount(levelId)
end

function XBigWorldMapControl:GetCollectedCount(levelId)
    return self._Model:GetCollectionsCountByLevelId(levelId)
end

function XBigWorldMapControl:GetCollectableText(levelId)
    local collectableCount = self:GetCollectableCount(levelId)
    local totalCount = self:GetCollectedCount(levelId)

    return string.format("%d/%d", totalCount, collectableCount)
end

function XBigWorldMapControl:GetCurrentTrackPins(levelId)
    return self._Model:GetAllTrackPinsByLevelId(levelId)
end

function XBigWorldMapControl:GetTrackPinDatas(levelId, result)
    local trackIds = self:GetCurrentTrackPins(levelId)
    result = result or {}
    for k, _ in pairs(result) do
        result[k] = nil
    end
    if not XTool.IsTableEmpty(trackIds) then
        for pinId, _ in pairs(trackIds) do
            local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)

            if pinData then
                result[pinId] = pinData
            end
        end
    end

    return result
end

function XBigWorldMapControl:GetNearDistance()
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:GetNearDistance()
end

function XBigWorldMapControl:GetLevelName(levelId)
    return self._Model:GetLevelName(levelId)
end

function XBigWorldMapControl:GetMapDefaultScale(levelId)
    return self._Model:GetBigWorldMapDefaultScaleByLevelId(levelId) or 0
end

function XBigWorldMapControl:GetTeleportLevelText(levelId)
    local levelName = self:GetLevelName(levelId)

    return self:GetTeleportText(levelName)
end

function XBigWorldMapControl:GetTeleportText(text)
    return XMVCA.XBigWorldService:GetText("MapTeleportLevelDesc", text)
end

function XBigWorldMapControl:GetTeleportLevelTips(levelId)
    local levelName = self:GetLevelName(levelId)

    return XMVCA.XBigWorldService:GetText("MapTeleportLevelTips", levelName)
end

---@param targetPinData XBWMapPinData
function XBigWorldMapControl:GetQuickGoingPinData(targetPinData)
    local result = nil

    if targetPinData and not targetPinData:IsCouldTeleport() and targetPinData:IsTracking() then
        local minDistance = math.maxinteger
        local targetPosition = targetPinData.WorldPosition
        local pinDatas = self:GetMapPinDatasByLevelId(targetPinData.LevelId)
        
        if not XTool.IsTableEmpty(pinDatas) then
            for pinId, pinData in pairs(pinDatas) do
                if pinData:IsTeleportInLevel() and pinData.MapAreaGroupId == targetPinData.MapAreaGroupId then
                    if not result then
                        local position = pinData.WorldPosition

                        result = pinData
                        minDistance = math.pow((position.x - targetPosition.x), 2) + math.pow((position.z - targetPosition.z), 2)
                    else
                        local position = pinData.WorldPosition
                        local distance = math.pow((position.x - targetPosition.x), 2) + math.pow((position.z - targetPosition.z), 2)

                        if distance < minDistance then
                            result = pinData
                            minDistance = distance
                        end
                    end
                end
            end
        end
    end

    return result
end

function XBigWorldMapControl:GetMapScaleCache(defaultValue)
    return self._Model:GetMapScaleCache(defaultValue)
end

function XBigWorldMapControl:SetMapScaleCache(value)
    self._Model:SetMapScaleCache(value)
end

function XBigWorldMapControl:RefreshMapAreaGroup(groupList, currentIndex)
    if not XTool.IsTableEmpty(groupList) then
        for i, imageList in pairs(groupList) do
            if not XTool.IsTableEmpty(imageList) then
                local aplha = 1

                if math.abs(i - currentIndex) == 1 then
                    aplha = 0.3
                elseif math.abs(i - currentIndex) > 1 then
                    aplha = 0
                end

                for _, image in pairs(imageList) do
                    image.color = CS.UnityEngine.Color(1, 1, 1, aplha)

                    if currentIndex == i then
                        image.transform:SetAsLastSibling()
                    end
                end
            end
        end
    end
end

function XBigWorldMapControl:CheckLevelHasMap(levelId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:CheckLevelHasMap(levelId)
end

function XBigWorldMapControl:CheckQuestPin(levelId, pinId)
    if not XTool.IsNumberValid(pinId) or not XTool.IsNumberValid(levelId) then
        return false
    end

    local pinData = self:GetPinDataByLevelIdAndPinId(levelId, pinId)

    return pinData and pinData:IsQuest() or false
end

---@param pinData XBWMapPinData
function XBigWorldMapControl:CheckPinCoincidence(pinData)
    if not pinData:IsQuest() then
        if not self:CheckPinCoincidenceReferenceDisplay(pinData.LevelId, pinData.PinId) then
            return false
        end

        if pinData:IsSceneObject() then
            local coincidenceMap = self._Model:GetCoincidenceSceneObjectPlaceMap(pinData.LevelId)

            return coincidenceMap[pinData.SceneObjectPlaceId] or false
        end
        if pinData:IsNpc() then
            local coincidenceMap = self._Model:GetCoincidenceNpcPlaceMap(pinData.LevelId)

            return coincidenceMap[pinData.NpcPlaceId] or false
        end
    end

    return false
end

---@param pinData XBWMapPinData
function XBigWorldMapControl:CheckPinCoincidenceReferenceDisplay(levelId, pinId)
    local referMap = self._Model:GetCoincidenceReferenceMapByPinId(levelId, pinId)

    if not XTool.IsTableEmpty(referMap) then
        for targetPinId, _ in pairs(referMap) do
            local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, targetPinId)

            if pinData then
                if pinData:IsDisplaying() then
                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldMapControl:CheckCurrentTrackPin(levelId, pinId)
    ---@type XBigWorldMapAgency
    local agency = self:GetAgency()

    return agency:CheckPinTracking(levelId, pinId)
end

function XBigWorldMapControl:CheckHasTrackPin(levelId)
    return not XTool.IsTableEmpty(self:GetCurrentTrackPins(levelId))
end

function XBigWorldMapControl:CheckHasArea(areaId)
    local configs = self._Model:GetBigWorldMapAreaConfigs()

    return configs and configs[areaId]
end

function XBigWorldMapControl:TrackPin(levelId, pinId)
    local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        if pinData:IsQuest() then
            if not self:CheckCurrentTrackPin(levelId, pinId) then
                XMVCA.XBigWorldQuest:TrackQuest(pinData.QuestId)
            end
        else
            if self:SendCheckEnableTrackCommand(levelId, pinId) then
                self:RequestTrackMapPin(levelId, pinId, true)
            else
                XMVCA.XBigWorldUI:TipText("MapTrackFailDesc")
            end
        end
    end
end

function XBigWorldMapControl:CancelTrackPin(levelId, pinId)
    local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        if pinData:IsQuest() then
            if self:CheckCurrentTrackPin(levelId, pinId) then
                XMVCA.XBigWorldQuest:UnTrackQuest(pinData.QuestId)
                XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_DETAIL_CLOSE)
            end
        else
            self:RequestTrackMapPin(levelId, pinId, false)
        end
    end
end

function XBigWorldMapControl:SendTeleportCommand(levelId, pinId)
    XMVCA.XBigWorldMap:SendTeleportCommandByMapPin(levelId, pinId)
end

function XBigWorldMapControl:SendCheckEnableTrackCommand(levelId, pinId)
    local result = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CHECK_TRACK_MAP_PIN_ENABLE, {
        MapPinLevelId = levelId,
        MapPinId = pinId,
    })

    return result and result.Enable or false
end

function XBigWorldMapControl:SendTrackCommand(levelId, pinId)
    if not self:CheckCurrentTrackPin(levelId, pinId) then
        self:SendCancelAllTrackCommand(levelId)
        self._Model:TrackPins(levelId, {
            [pinId] = true,
        })
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_START_TRACK_MAP_PIN, {
            MapPinLevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapControl:SendCancelTrackCommand(levelId, pinId)
    if self:CheckCurrentTrackPin(levelId, pinId) then
        self._Model:CancelTrackPins(levelId)
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_STOP_TRACK_MAP_PIN, {
            MapPinLevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapControl:SendCancelAllTrackCommand(levelId)
    local trackPins = self._Model:GetTrackPinsByLevelIdAndType(levelId)

    if not XTool.IsTableEmpty(trackPins) then
        for pinId, _ in pairs(trackPins) do
            self:SendCancelTrackCommand(levelId, pinId)
        end
    end
end

function XBigWorldMapControl:RequestTrackMapPin(levelId, pinId, isTrack)
    local operatorType = XEnumConst.BWMap.TrackOperator.Cancel

    if isTrack and XTool.IsNumberValid(pinId) then
        operatorType = XEnumConst.BWMap.TrackOperator.Begin
    end

    XNetwork.Call("BigWorldSetTrackMapPinIdRequest", {
        MapTrackPinData = {
            WorldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId(),
            LevelId = levelId,
            TrackPinId = isTrack and pinId or 0,
        },
        Opt = operatorType,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if XTool.IsNumberValid(pinId) and isTrack then
            self:SendTrackCommand(levelId, pinId)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, true)
        else
            self:SendCancelTrackCommand(levelId, pinId)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
        end
    end)
end

return XBigWorldMapControl
