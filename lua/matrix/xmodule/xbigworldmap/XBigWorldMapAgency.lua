---@class XBigWorldMapAgency : XAgency
---@field private _Model XBigWorldMapModel
local XBigWorldMapAgency = XClass(XAgency, "XBigWorldMapAgency")

function XBigWorldMapAgency:OnInit()
    -- 初始化一些变量
    self:InitConditionCheck()
    self:InitShieldController()
    self:InitEnum()
end

function XBigWorldMapAgency:InitRpc()
    -- 实现服务器事件注册
    self:AddRpc("NotifyBigWorldBoxData", handler(self, self.OnNotifyBigWorldBoxData))
    self:AddRpc("NotifyBigWorldMapData", handler(self, self.OnNotifyBigWorldMapData))
    self:AddRpc("NotifyBigWorldActivateTeleporter", handler(self, self.OnNotifyBigWorldActivateTeleporter))
    self:AddRpc("NotifyBigWorldTrackMapPinIdUpdate", handler(self, self.OnNotifyBigWorldTrackMapPinIdUpdate))
end

function XBigWorldMapAgency:InitEvent()
    -- 实现跨Agency事件注册
end

function XBigWorldMapAgency:OnRelease()
    self:ReleaseConditionCheck()
    self:RemoveShieldController()
end

-- 条件判断初始化
function XBigWorldMapAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10101004, Handler(self, self.CheckTeleporterActiveCondition))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101006, Handler(self, self.CheckHasQuestMapPinCondition))
end

function XBigWorldMapAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end

    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101004)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101006)
end

function XBigWorldMapAgency:InitEnum()
    self.MapPinDisplayType = {
        Point = 1 << 0,
        LittleMapRadius = 1 << 1,
        BigMapRadius = 1 << 2,
    }
end

function XBigWorldMapAgency:InitShieldController()
    XMVCA.XBigWorldFunction:RegisterFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Map, self,
        self.OnShieldControl)
end

function XBigWorldMapAgency:RemoveShieldController()
    XMVCA.XBigWorldFunction:RemoveFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Map, self,
        self.OnShieldControl)
end

function XBigWorldMapAgency:InitMapPinData(worldId)
    if XTool.IsNumberValid(worldId) then
        local levelIds = CS.StatusSyncFight.XFightClient.GetWorldLevelIds(worldId)

        XTool.LoopCollection(levelIds, function(levelId)
            self._Model:InitPinData(worldId, levelId)
        end)
    end
end

function XBigWorldMapAgency:OnAddQuestMapPin(data)
    local pinId = self._Model:AddQuestMapPin(data)
    local bindPin = nil

    if self:CheckLevelLinkOther(data.LevelId) then
        local linkLevelId = self:GetMapLinkLevelIdByLevelId(data.LevelId)
        local bindPinId = self._Model:GetBigWorldMapLinkBindPinIdByLevelId(data.LevelId)
        local virtualPinData = self._Model:AddVirtualMapPin(data.LevelId, linkLevelId, bindPinId, pinId)

        if virtualPinData then
            bindPin = {
                LevelId = virtualPinData.BindLevelId,
                PinId = virtualPinData.BindPinId,
            }
        end
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ADD)

    return {
        PinId = pinId,
        BindPin = bindPin,
    }
end

function XBigWorldMapAgency:OnMapPinShowTypeChange(data)
    if not data then
        return
    end
    self._Model:ChangeMapPinShowType(data.MapPinLevelId, data.MapPinId, data.ShowType)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_MAP_PIN_SHOW_TYPE)
end

function XBigWorldMapAgency:OnRemoveQuestMapPin(data)
    self._Model:RemoveQuestMapPin(data)
    self._Model:RemoveVirtualMapPin(data.LevelId, data.PinId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE)
end

function XBigWorldMapAgency:OnRemoveQuestAllMapPins(data)
    self._Model:RemoveQuestAllMapPin(data.QuestId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE)
end

function XBigWorldMapAgency:OnTrackQuestMapPin(data)
    self._Model:TrackQuestMapPins(data.QuestId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, true)
end

function XBigWorldMapAgency:OnTeleportComplete()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT)
end

function XBigWorldMapAgency:OnCancelTrackQuestMapPin(data)
    self._Model:CancelTrackQuestMapPins(data.QuestId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
end

function XBigWorldMapAgency:OnDisplayMapPins(data)
    self._Model:DisplayMapPin(data)
end

function XBigWorldMapAgency:OnCancelTrackMapPin(data)
    local levelId = data.MapPinLevelId

    if self:CheckLevelPinsTracking(levelId) then
        self:RequestCancelTrackMapPin(levelId, function()
            self._Model:CancelTrackPins(levelId)
        end)
    end
end

function XBigWorldMapAgency:OnPlayerEnterArea(data)
    local groupId = data.GroupId or 0
    local areaId = data.RegionId or 0

    self._Model:SetCurrentAreaGroupData(groupId, areaId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, groupId, areaId)
end

function XBigWorldMapAgency:OnPlayerExitArea(data)
    local groupId = data.GroupId or 0
    local areaId = data.RegionId or 0
    local currentAreaId = self._Model:GetCurrentAreaId()

    if currentAreaId == areaId then
        self:ClearCurrentAreaGroupData()
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_EXIT_AREA, groupId, areaId)
end

function XBigWorldMapAgency:OnAssistedTrackMapPin(data)
    self._Model:UpdateAssistedTrack(data.MapPinLevelId, data.MapPinId, data.Position, data.PlayerGroupId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ASSISTED_TRACK_UPDATE)
end

function XBigWorldMapAgency:OnUpdateMapPinPosition(data)
    self._Model:UpdatePinOutStatus(data.MapPinLevelId, data.MapPinId, false)
    self._Model:UpdatePinPosition(data.MapPinLevelId, data.MapPinId, data.Position)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_POSITION_UPDATE, data)
end

function XBigWorldMapAgency:OnGetLittleMapRadius(data)
    local levelId = data.LevelId

    if not XTool.IsNumberValid(levelId) or not self:CheckLevelHasMap(levelId) then
        return {
            Radius = 0,
        }
    end

    local scale = self:GetLittleMapScaleByLevelId(levelId)
    local pixelRatio = self:GetMapPixelRatioByLevelId(levelId)
    local radius = self._Model:GetLittleMapRadius()

    if not XTool.IsNumberValid(pixelRatio) then
        pixelRatio = 1
    end

    return {
        Radius = (radius / scale) / pixelRatio
    }
end

function XBigWorldMapAgency:OnOpenBigMap(data)
    self:OpenBigWorldMapUiWithPinId(data.WorldId, data.LevelId, data.PinId)
end

function XBigWorldMapAgency:OnLittleMapPinRemove(data)
    self._Model:UpdatePinOutStatus(data.MapPinLevelId, data.MapPinId, true)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_LITTLE_MAP_PIN_HIDE, data.MapPinLevelId, data.MapPinId)
end

---@param controlData XBWFunctionControlData
function XBigWorldMapAgency:OnShieldControl(controlData)
    if controlData and not controlData:IsEmpty() then
        self._Model:SetIsShieldBigMap(controlData:GetArgByIndex(1))
    end
end

function XBigWorldMapAgency:ClearCurrentAreaGroupData()
    self._Model:ClearCurrentAreaGroupData()
end

---@param questId number
---@param isIgnoreSameAreaGroup boolean 是否忽略同区域组(为True时在同AreaGroup内的不会打开地图)
function XBigWorldMapAgency:OpenBigWorldMapUiAnchorQuest(questId, isIgnoreSameAreaGroup, isIgnoreTips)
    if not XTool.IsNumberValid(questId) then
        return false
    end

    local questPinDatas = self._Model:GetQuestPinDatasByQuestId(questId, true)

    if not XTool.IsTableEmpty(questPinDatas) then
        local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
        local currentAreaGroupId = self:GetCurrentAreaGroupId()
        local pinId = 0

        for _, questPinData in pairs(questPinDatas) do
            if questPinData:IsDisplaying() then
                if questPinData.LevelId == currentLevelId then
                    local areaGroupId = questPinData:GetAreaGroupId()

                    if XTool.IsNumberValid(areaGroupId) and XTool.IsNumberValid(currentAreaGroupId) then
                        if isIgnoreSameAreaGroup and areaGroupId == currentAreaGroupId then
                            return false
                        else
                            pinId = questPinData.PinId
                        end
                    else
                        return false
                    end
                else
                    if self:CheckLevelLinkOther(questPinData.LevelId) then
                        local linkLevelId = self:GetMapLinkLevelIdByLevelId(questPinData.LevelId)
                        local virtualPinDatas = self._Model:GetVirtualPinDatasByReferId(questPinData.PinId, true)

                        if not XTool.IsTableEmpty(virtualPinDatas) then
                            for _, virtualPinData in pairs(virtualPinDatas) do
                                if virtualPinData.BindLevelId == linkLevelId then
                                    pinId = virtualPinData.PinId
                                end
                            end
                        end
                    else
                        pinId = questPinData.PinId
                    end
                end
            end
        end

        if XTool.IsNumberValid(pinId) then
            local worldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId()

            return self:TryOpenBigWorldMapUi(worldId, currentLevelId, pinId)
        end
    else
        if not isIgnoreTips then
            XMVCA.XBigWorldUI:TipMsg(XMVCA.XBigWorldService:GetText("MapAnchorQuestTip"))
        end
    end

    return false
end

function XBigWorldMapAgency:OpenBigWorldMapUi()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local worldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId()

    return self:TryOpenBigWorldMapUi(worldId, levelId)
end

function XBigWorldMapAgency:OpenBigWorldMapUiWithPosition(worldId, levelId, posX, posY, scaleRatio)
    if not XTool.IsNumberValid(levelId) or not XTool.IsNumberValid(worldId) then
        return false
    end

    return self:TryOpenBigWorldMapUi(worldId, levelId, 0, {
        x = posX,
        y = posY,
    }, scaleRatio)
end

function XBigWorldMapAgency:OpenBigWorldMapUiWithPinId(worldId, levelId, pinId, openAiMemory)
    if not XTool.IsNumberValid(levelId) or not XTool.IsNumberValid(worldId) then
        return false
    end

    return self:TryOpenBigWorldMapUi(worldId, levelId, pinId, nil, nil, openAiMemory)
end

function XBigWorldMapAgency:TryOpenBigWorldMapUi(worldId, levelId, targetPinId, focusPos, scaleRatio, openAiMemory)
    if self:CheckLevelLinkOther(levelId) then
        local linkLevelId = self:GetMapLinkLevelIdByLevelId(levelId)
        local linkWorldId = self._Model:GetBigWorldMapLinkLinkWorldIdByLevelId(levelId)
        local bindPinId = self._Model:GetBigWorldMapLinkBindPinIdByLevelId(levelId)

        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_BIG_MAP_OPENED_NOTIFY)
        XMVCA.XBigWorldUI:Open("UiBigWorldMap", linkWorldId, linkLevelId, bindPinId, targetPinId, focusPos, scaleRatio, openAiMemory)
        return true
    elseif self:CheckLevelHasMap(levelId) then
        local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
        local bindPinId = 0
        if self:CheckLevelLinkOther(currentLevelId) then
            local linkLevelId = self:GetMapLinkLevelIdByLevelId(currentLevelId)
            if linkLevelId == levelId then
                bindPinId = self._Model:GetBigWorldMapLinkBindPinIdByLevelId(currentLevelId)
            end
        end
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_BIG_MAP_OPENED_NOTIFY)
        XMVCA.XBigWorldUI:Open("UiBigWorldMap", worldId, levelId, bindPinId, targetPinId, focusPos, scaleRatio, openAiMemory)
        return true
    end

    return false
end

function XBigWorldMapAgency:TryOpenBigWorldMapUiAnchorPin(worldId, levelId, targetPinId, scaleRatio)
    if self:CheckLevelLinkOther(levelId) then
        local linkLevelId = self:GetMapLinkLevelIdByLevelId(levelId)
        local linkWorldId = self._Model:GetBigWorldMapLinkLinkWorldIdByLevelId(levelId)
        local virtualPinDatas = self._Model:GetVirtualPinDatasByReferId(targetPinId, true)

        targetPinId = 0
        if not XTool.IsTableEmpty(virtualPinDatas) then
            for _, virtualPinData in pairs(virtualPinDatas) do
                if virtualPinData.BindLevelId == linkLevelId then
                    targetPinId = virtualPinData.PinId
                end
            end
        end

        if XTool.IsNumberValid(targetPinId) and self:CheckHasPin(linkLevelId, targetPinId) then
            return self:TryOpenBigWorldMapUi(linkWorldId, linkLevelId, targetPinId, nil, scaleRatio)
        end

        return false
    end

    if self:CheckHasPin(levelId, targetPinId) then
        return self:TryOpenBigWorldMapUi(worldId, levelId, targetPinId, nil, scaleRatio)
    end

    return false
end

function XBigWorldMapAgency:GetQuestPinStyleIdByQuestId(questId)
    return self._Model:GetBigWorldMapQuestPinStyleIdByQuestId(questId)
end

function XBigWorldMapAgency:GetOptionalQuestPinStyleIdByQuestId(questId)
    return self._Model:GetBigWorldMapQuestPinSecondStyleIdByQuestId(questId)
end

---@param questId number
---@param isIncludeCurrentLevel boolean 是否包含当前关卡(为True时会返回在当前关卡内目标图钉的名称)
---@return string
function XBigWorldMapAgency:GetQuestPinTargetLevelName(questId, isIncludeCurrentLevel)
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local questPinDatas = self._Model:GetQuestPinDatasByQuestId(questId, true)

    if not XTool.IsTableEmpty(questPinDatas) then
        for _, questPinData in pairs(questPinDatas) do
            if questPinData:IsDisplaying() then
                if questPinData.LevelId ~= levelId then
                    return self._Model:GetLevelName(questPinData.LevelId)
                elseif isIncludeCurrentLevel then
                    return self._Model:GetLevelName(levelId)
                else
                    return ""
                end
            end
        end
    end

    return ""
end

function XBigWorldMapAgency:GetLevelName(levelId)
    return CS.StatusSyncFight.XLevelConfig.GetLevelName(levelId)
end

function XBigWorldMapAgency:UpdateTrackMapPin(data)
    self._Model:UpdateServerTrackMapPin(data)
end

function XBigWorldMapAgency:UpdateAllActivateTeleporter(data)
    self._Model:UpdateAllActivateTeleporter(data)
end

function XBigWorldMapAgency:UpdateLittleMapRadius(radius)
    self._Model:UpdateLittleMapRadius(radius)
end

function XBigWorldMapAgency:SendCurrentTrackCommand()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local pinIds = self._Model:GetTrackPinsByLevelIdAndType(levelId, XEnumConst.BWMap.TrackType.Normal)
    local pinId = 0

    if not XTool.IsTableEmpty(pinIds) then
        for id, _ in pairs(pinIds) do
            pinId = id
        end
    end
    if XTool.IsNumberValid(pinId) then
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_START_TRACK_MAP_PIN, {
            MapPinLevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapAgency:CheckLevelHasMap(levelId)
    local configs = self._Model:GetBigWorldMapConfigs()

    return configs[levelId] ~= nil
end

function XBigWorldMapAgency:CheckLevelLinkOther(levelId)
    local configs = self._Model:GetBigWorldMapLinkConfigs()

    return configs[levelId] ~= nil
end

function XBigWorldMapAgency:CheckHasPin(levelId, pinId)
    local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId, true)

    return pinData ~= nil
end

function XBigWorldMapAgency:CheckCurrentSameAreaGroup(targetAreaGroupId)
    local currentGroupId = self:GetCurrentAreaGroupId()

    return currentGroupId == targetAreaGroupId
end

function XBigWorldMapAgency:CheckPinCurrentSameAreaGroup(levelId, pinId)
    local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId, true)

    if pinData then
        return self:CheckCurrentSameAreaGroup(pinData.MapAreaGroupId)
    end

    return false
end

function XBigWorldMapAgency:CheckTeleporterActiveCondition(template)
    if template then
        local levelId = template.Params[1]
        local placeId = template.Params[2]

        return self:CheckTeleporterActive(levelId, placeId)
    end

    return false
end

function XBigWorldMapAgency:CheckHasQuestMapPinCondition(template)
    if template then
        local questId = template.Params[1]
        local questDatas = self._Model:GetQuestPinDatasByQuestId(questId, true)

        return not XTool.IsTableEmpty(questDatas)
    end

    return false
end

function XBigWorldMapAgency:CheckTeleporterActive(levelId, placeId)
    if not XTool.IsNumberValid(levelId) or not XTool.IsNumberValid(placeId) then
        return false
    end

    if self:SendGetSceneObjectMapPinDefaultActive(levelId, placeId) then
        return true
    end

    local teleporterIds = self._Model:GetActivateTeleportersByLevelId(levelId)

    if not XTool.IsTableEmpty(teleporterIds) then
        return teleporterIds[placeId] or false
    end

    return false
end

function XBigWorldMapAgency:CheckNpcMapPinDefalutDisplay(levelId, npcPlaceId)
    return self:SendGetNpcMapPinDefaultVisible(levelId, npcPlaceId)
end

function XBigWorldMapAgency:CheckSceneObjectMapPinDefalutDisplay(levelId, sceneObjectPlaceId)
    return self:SendGetSceneObjectMapPinDefaultVisible(levelId, sceneObjectPlaceId)
end

function XBigWorldMapAgency:CheckBigMapShield()
    return self._Model:GetIsShieldBigMap()
end

function XBigWorldMapAgency:CheckPinTracking(levelId, pinId)
    local currentPinIds = self._Model:GetAllTrackPinsByLevelId(levelId)

    return currentPinIds and currentPinIds[pinId]
end

function XBigWorldMapAgency:CheckLevelPinsTracking(levelId, trackType)
    local currentPinIds = self._Model:GetTrackPinsByLevelIdAndType(levelId, trackType)

    return not XTool.IsTableEmpty(currentPinIds)
end

function XBigWorldMapAgency:OnNotifyBigWorldBoxData(data)
    self._Model:UpdateCollectionsCount(data.LevelId, data.BoxRewardedCnt)
    XEventManager.DispatchEvent(XEventId.EVENT_BOX_DATA_UPDATE)
end

function XBigWorldMapAgency:OnNotifyBigWorldMapData(data)
    self._Model:UpdateAllCollectionsCount(data.BoxRewardedCntData)
end

function XBigWorldMapAgency:OnNotifyBigWorldActivateTeleporter(data)
    self._Model:UpdateActivateTeleporter(data.LevelId, data.PlaceId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE)
end

function XBigWorldMapAgency:OnNotifyBigWorldTrackMapPinIdUpdate(data)
    if data and data.MapTrackPinData then
        local levelId = data.MapTrackPinData.LevelId
        local pinId = data.MapTrackPinData.TrackPinId

        self._Model:CancelTrackPinByPinId(levelId, pinId)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_STOP_TRACK_MAP_PIN, {
            MapPinLevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapAgency:RequestCancelTrackMapPin(levelId, callback)
    XNetwork.Call("BigWorldSetTrackMapPinIdRequest", {
        MapTrackPinData = {
            WorldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId(),
            LevelId = levelId,
            TrackPinId = 0,
        },
        Opt = XEnumConst.BWMap.TrackOperator.Finish,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if callback then
            callback()
        end

        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
    end)
end

function XBigWorldMapAgency:SendGetNpcMapPinDefaultVisible(levelId, npcPlaceId)
    local value = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_MAP_PIN_DEFAULT_VISIBLE_BY_NPC, {
        MapPinLevelId = levelId,
        NpcPlaceId = npcPlaceId,
    })

    return value and value.Visible or false
end

function XBigWorldMapAgency:SendGetSceneObjectMapPinDefaultActive(levelId, placeId)
    local value = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_MAP_PIN_DEFAULT_ACTIVE_BY_SCENE_OBJECT, {
        MapPinLevelId = levelId,
        SceneObjectPlaceId = placeId,
    })

    return value and value.Active or false
end

function XBigWorldMapAgency:SendGetSceneObjectMapPinDefaultVisible(levelId, sceneObjectPlaceId)
    local value = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_MAP_PIN_DEFAULT_VISIBLE_BY_SCENE_OBJECT, {
        MapPinLevelId = levelId,
        SceneObjectPlaceId = sceneObjectPlaceId,
    })

    return value and value.Visible or false
end

function XBigWorldMapAgency:SendTeleportCommand(levelId, posX, posY, posZ, eulerAngleY)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TELEPORT_PLAYER, {
        LevelId = levelId,
        PositionX = posX,
        PositionY = posY,
        PositionZ = posZ,
        EulerAngleX = 0,
        EulerAngleY = eulerAngleY or 0,
        EulerAngleZ = 0,
    })
end

function XBigWorldMapAgency:SendTeleportCommandByMapPin(mapPinLevelId, pinId)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TELEPORT_PLAYER_BY_MAP_PIN, {
        MapPinLevelId = mapPinLevelId,
        MapPinId = pinId,
    })
end

--- region 小地图

function XBigWorldMapAgency:GetCurrentAreaGroupId()
    return self._Model:GetCurrentAreaGroupId() or 0
end

function XBigWorldMapAgency:GetFloorIndexByGroupId(groupId)
    if not XTool.IsNumberValid(groupId) then
        return 0
    end

    return self._Model:GetBigWorldMapAreaGroupFloorIndexByGroupId(groupId)
end

function XBigWorldMapAgency:GetLittleMapScaleByLevelId(levelId)
    local scale = self._Model:GetBigWorldMapLittleMapScaleByLevelId(levelId)

    if not XTool.IsNumberValid(scale) then
        scale = 1
    end

    return scale
end

function XBigWorldMapAgency:GetMapGroupIdsByLevelId(levelId)
    local groupIds = self._Model:GetBigWorldMapAreaGroupIdsByLevelId(levelId)
    local result = {}

    if not XTool.IsTableEmpty(groupIds) then
        for _, groupId in pairs(groupIds) do
            table.insert(result, groupId)
        end

        table.sort(result, function(groupIdA, groupIdB)
            local floorIndexA = self:GetFloorIndexByGroupId(groupIdA)
            local floorIndexB = self:GetFloorIndexByGroupId(groupIdB)

            return floorIndexA < floorIndexB
        end)
    end

    return result
end

function XBigWorldMapAgency:GetBigWorldMapConditionIdByLevelId(levelId)
    return self._Model:GetBigWorldMapConditionIdByLevelId(levelId)
end

function XBigWorldMapAgency:GetAreaIdsByGroupId(groupId)
    return self._Model:GetBigWorldMapAreaGroupAreaIdsByGroupId(groupId)
end

function XBigWorldMapAgency:GetAreaPosXByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaPosXByAreaId(areaId)
end

function XBigWorldMapAgency:GetAreaPosZByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaPosZByAreaId(areaId)
end

function XBigWorldMapAgency:GetAreaPixelRatioByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaPixelRatioByAreaId(areaId)
end

function XBigWorldMapAgency:GetMapPosXByLevelId(levelId)
    return self._Model:GetBigWorldMapPosXByLevelId(levelId)
end

function XBigWorldMapAgency:GetMapPosZByLevelId(levelId)
    return self._Model:GetBigWorldMapPosZByLevelId(levelId)
end

function XBigWorldMapAgency:GetMapPixelRatioByLevelId(levelId)
    return self._Model:GetBigWorldMapPixelRatioByLevelId(levelId)
end

function XBigWorldMapAgency:GetMapLinkLevelIdByLevelId(levelId)
    if not XTool.IsNumberValid(levelId) or not self:CheckLevelLinkOther(levelId) then
        return 0
    end

    return self._Model:GetBigWorldMapLinkLinkLevelIdByLevelId(levelId)
end

function XBigWorldMapAgency:GetMapValidLevelId(levelId)
    if self:CheckLevelLinkOther(levelId) then
        return self:GetMapLinkLevelIdByLevelId(levelId)
    end
    if self:CheckLevelHasMap(levelId) then
        return levelId
    end

    return 0
end

function XBigWorldMapAgency:GetAreaImageByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaAreaImageByAreaId(areaId)
end

function XBigWorldMapAgency:GetMapImageByLevelId(levelId)
    return self._Model:GetBigWorldMapBaseImageByLevelId(levelId)
end

function XBigWorldMapAgency:GetMapWidthByLevelId(levelId)
    return self._Model:GetBigWorldMapWidthByLevelId(levelId)
end

function XBigWorldMapAgency:GetMapHeightByLevelId(levelId)
    return self._Model:GetBigWorldMapHeightByLevelId(levelId)
end

---@return XBWMapPinData[]
function XBigWorldMapAgency:GetMapPinDatasByLevelIdAndGroupId(levelId, groupId)
    local result = {}
    local pinDatas = self:GetMapPinDatasByLevelId(levelId)

    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            if pinData:GetAreaGroupId(true) == groupId then
                table.insert(result, pinData)
            end
        end
    end

    return result
end

---@return XBWMapPinData[]
function XBigWorldMapAgency:GetMapPinDatasByLevelId(levelId, isNoTip)
    return self._Model:GetPinDatasByLevelId(levelId, isNoTip)
end

---@return XBWMapPinData
function XBigWorldMapAgency:GetPinDataByLevelIdAndPinId(levelId, pinId)
    return self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)
end

function XBigWorldMapAgency:GetCurrentTrackPinsIncludeVirtual(targetLevelId, result)
    result = result or {}
    for k, _ in pairs(result) do
        result[k] = nil
    end
    
    if not self:CheckLevelHasMap(targetLevelId) then
        return result
    end

    local pinDatas = self:GetMapPinDatasByLevelId(targetLevelId)

    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            if pinData:IsVirtual() then
                if self:CheckPinTracking(pinData.LevelId, pinData.ReferPinId) then
                    result[pinData.PinId] = true
                end
            else
                if self:CheckPinTracking(pinData.LevelId, pinData.PinId) then
                    result[pinData.PinId] = true
                end
            end
        end
    end

    return result
end

function XBigWorldMapAgency:CheckHasTrackPinIncludeVirtual(levelId)
    local result = false
    
    if not self:CheckLevelHasMap(levelId) then
        return result
    end
    local pinDatas = self:GetMapPinDatasByLevelId(levelId)

    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            if pinData:IsVirtual() then
                if self:CheckPinTracking(pinData.LevelId, pinData.ReferPinId) then
                    result = true
                    break
                end
            else
                if self:CheckPinTracking(pinData.LevelId, pinData.PinId) then
                    result = true
                    break
                end
            end
        end
    end
    return result
end

function XBigWorldMapAgency:GetPinActiveIconByStyleId(styleId)
    return self._Model:GetBigWorldMapPinStyleActiveIconByStyleId(styleId)
end

function XBigWorldMapAgency:GetPinUnActiveIconByStyleId(styleId)
    return self._Model:GetBigWorldMapPinStyleUnActiveIconByStyleId(styleId)
end

function XBigWorldMapAgency:GetPinIconByStyleId(styleId, isActive)
    if XTool.IsNumberValid(styleId) then
        if isActive then
            return self:GetPinActiveIconByStyleId(styleId)
        end

        return self:GetPinUnActiveIconByStyleId(styleId)
    end

    XLog.Error("XBigWorldMapControl:GetPinIconByStyleId styleId is INVALID! 请检查关卡图钉配置表! " .. styleId)

    return ""
end

function XBigWorldMapAgency:GetBigWorldMapPinStyleAreaColorByStyleId(styleId)
    return self._Model:GetBigWorldMapPinStyleAreaColorByStyleId(styleId)
end

---@return table<number, XBWMapPinData>
function XBigWorldMapAgency:GetPinDatasByBindId(bindId, isNoTip)
    return self._Model:GetVirtualPinDatasByBindId(bindId, isNoTip)
end

function XBigWorldMapAgency:GetNearDistance()
    return self._Model:GetNearDistance()
end

--- endregion

return XBigWorldMapAgency
