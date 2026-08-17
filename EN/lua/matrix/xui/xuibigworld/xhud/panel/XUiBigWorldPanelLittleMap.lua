local XUiBigWorldMapPin = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapPin")
local XUiBigWorldMapAreaPin = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapAreaPin")
local XBWMapAxisConversion = require("XModule/XBigWorldMap/XCommon/XBWMapAxisConversion")
local XBWLittleMapInterface = require("XModule/XBigWorldMap/XInterface/XBWLittleMapInterface")

---@class XUiBigWorldPanelLittleMap : XUiNode
---@field PlayerPos UnityEngine.RectTransform
---@field BtnBigMap XUiComponent.XUiButton
---@field MapPin UnityEngine.RectTransform
---@field MapPath UnityEngine.RectTransform
---@field PinNode UnityEngine.RectTransform
---@field MapLevel UnityEngine.RectTransform
---@field ImgLevelMap UnityEngine.UI.Image
---@field ImgMapBase UnityEngine.UI.Image
---@field ImgView UnityEngine.RectTransform
---@field MapPinTarget UnityEngine.RectTransform
---@field PinTarget UnityEngine.RectTransform
---@field PanelTrack UnityEngine.RectTransform
---@field EmptyMap UnityEngine.RectTransform
---@field LittleMap UnityEngine.RectTransform
---@field Parent XUiBigWorldHud
local XUiBigWorldPanelLittleMap = XClass(XUiNode, "XUiBigWorldPanelLittleMap")

-- region 生命周期

function XUiBigWorldPanelLittleMap:OnStart()
    ---@type XUiBigWorldMapPin[]
    self._PinNodeList = {}
    ---@type table<number, XUiBigWorldMapPin>
    self._PinNodeMap = {}

    ---@type XUiBigWorldMapAreaPin[]
    self._PinAreaList = {}

    ---@type XBWMapAxisConversion
    self._AxisConversion = XBWMapAxisConversion.New(CS.XUiType.Hud)

    self._AreaGroupList = {}
    self._AreaGroupIds = {}
    self._PinIdToTarget = {}
    self._CurrentGroupIndex = 1

    self._Scale = 1
    self._TrackRadius = 0

    self._AutoTransform = nil

    self._IsEmpty = false

    ---@type XBWLittleMapInterface
    self._Interface = XBWLittleMapInterface.New(self)

    self._PathDrawer = self.MapPath.gameObject:AddComponent(typeof(CS.XDrawPathOnMap))

    self:_InitUi()
    self:_InitTrack()
    self:_InitMap(XMVCA.XBigWorldGamePlay:GetCurrentLevelId())
    self:_RegisterButtonClicks()
end

function XUiBigWorldPanelLittleMap:OnEnable()
    self:_RefreshContent()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPanelLittleMap:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldPanelLittleMap:OnDestroy()
end

-- endregion

-- region 按钮事件

function XUiBigWorldPanelLittleMap:OnBtnBigMapClick()
    if XMVCA.XBigWorldMap:CheckBigMapShield() then
        XMVCA.XBigWorldFunction:SuggestFunctionShield()
        return
    end
    self.Parent:RecordLittleMapClick()
    XMVCA.XBigWorldMap:OpenBigWorldMapUi()
end

function XUiBigWorldPanelLittleMap:OnPositionChange(data)
    if self._IsEmpty then
        return
    end
    local pinNode = self._PinNodeMap[data.MapPinId]
    if pinNode then
        local pinData = XMVCA.XBigWorldMap:GetPinDataByLevelIdAndPinId(data.MapPinLevelId, data.MapPinId)
        if pinData then
            pinNode:Open()
            pinNode:_RefreshPosition(pinData)
        end
    else
        self:_RefreshPin()
    end
end

function XUiBigWorldPanelLittleMap:OnPinStateChange()
    if not self._IsEmpty then
        self:_RefreshPin()
    end
end

function XUiBigWorldPanelLittleMap:OnPinHide(levelId, pinId)
    local pinNode = self._PinNodeMap[pinId]
    if pinNode then
        local pinData = XMVCA.XBigWorldMap:GetPinDataByLevelIdAndPinId(levelId, pinId)
        if pinData then
            if pinData:IsLittleMapRadiusPin() then
                for _, areaPinNode in pairs(self._PinAreaList) do
                    if areaPinNode._LevelId == levelId and areaPinNode._PinData.PinId == pinId then
                        areaPinNode:Close()
                    end
                end
            end

            pinNode:Close()
        end
    end
end

function XUiBigWorldPanelLittleMap:OnLevelUpdate(levelId)
    self:_InitMap(levelId)
    self:_RefreshContent()
end

function XUiBigWorldPanelLittleMap:OnPlayerEnterArea(groupId, areaId)
    if self._IsEmpty or not XTool.IsNumberValid(groupId) then
        return
    end

    self:_RefreshCurrentGroup(groupId)
    self:OnPinStateChange()
end

-- endregion

function XUiBigWorldPanelLittleMap:GetCurrentFloorIndex()
    local currentGroupId = XMVCA.XBigWorldMap:GetCurrentAreaGroupId()

    if XTool.IsNumberValid(currentGroupId) then
        return XMVCA.XBigWorldMap:GetFloorIndexByGroupId(currentGroupId)
    end

    return 0
end

function XUiBigWorldPanelLittleMap:GetAxisConversion()
    return self._AxisConversion
end

function XUiBigWorldPanelLittleMap:GetOrCreateTarget(pinId, prefab, parent)
    if self._PinIdToTarget[pinId] then
        return self._PinIdToTarget[pinId]
    end
    local target = XUiHelper.Instantiate(prefab, parent)
    if target then
        self._PinIdToTarget[pinId] = target
    end
    return target
end

-- region 私有方法

function XUiBigWorldPanelLittleMap:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBigMap:AddEventListener(handler(self, self.OnBtnBigMapClick))
end

function XUiBigWorldPanelLittleMap:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPanelLittleMap:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPanelLittleMap:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ADD, self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE, self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ASSISTED_TRACK_UPDATE,
        self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_STYLE_UPDATE,
        self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_POSITION_UPDATE,
        self.OnPositionChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnLevelUpdate,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, self.OnPlayerEnterArea,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_MAP_PIN_SHOW_TYPE, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_AI_MEMORY_DISPLAY_CHANGE, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_LITTLE_MAP_PIN_HIDE, self.OnPinHide, self)
end

function XUiBigWorldPanelLittleMap:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ADD, self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_REMOVE, self.OnPinStateChange,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_ASSISTED_TRACK_UPDATE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_STYLE_UPDATE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_POSITION_UPDATE,
        self.OnPositionChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE,
        self.OnLevelUpdate, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, self.OnPlayerEnterArea,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_MAP_PIN_SHOW_TYPE,
        self.OnPinStateChange,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_AI_MEMORY_DISPLAY_CHANGE,
        self.OnPinStateChange,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_LITTLE_MAP_PIN_HIDE, self.OnPinHide, self)
end

function XUiBigWorldPanelLittleMap:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPanelLittleMap:_InitUi()
    self.PinNode.gameObject:SetActiveEx(false)
    self.PinArea.gameObject:SetActiveEx(false)
    self.ImgLevelMap.gameObject:SetActiveEx(false)
end

function XUiBigWorldPanelLittleMap:_InitTrack()
    self._TrackRadius = self.PanelTrack.rect.width / 2
    XMVCA.XBigWorldMap:UpdateLittleMapRadius(self._TrackRadius)
end

function XUiBigWorldPanelLittleMap:_InitMapPath(levelId)
    local binder = self.MapPath.gameObject:GetOrAddComponent(typeof(CS.XTransformBind))
    local originX = XMVCA.XBigWorldMap:GetMapPosXByLevelId(levelId) or 0
    local originY = XMVCA.XBigWorldMap:GetMapPosZByLevelId(levelId) or 0
    local pixelRatio = XMVCA.XBigWorldMap:GetMapPixelRatioByLevelId(levelId) or 1

    binder:SetTarget(self.ImgMapBase.transform)
    self._PathDrawer.OriginX = originX
    self._PathDrawer.OriginY = originY
    self._PathDrawer.PixelRatio = pixelRatio
    self._PathDrawer.Scale = self._Scale
end

function XUiBigWorldPanelLittleMap:_InitMap(levelId)
    self._LevelId = levelId
    self._IsEmpty = not XMVCA.XBigWorldMap:CheckLevelHasMap(levelId)
    self._AutoTransform = self.GameObject:GetOrAddComponent(typeof(CS.XLittleMapAutoTransform))
    self._PathDrawer:ClearPath()
    self._PathDrawer:SetActiveWithoutRefresh(not self._IsEmpty)

    if not self._IsEmpty then
        self._AxisConversion:ChangeAxis(levelId)
        self._Scale = XMVCA.XBigWorldMap:GetLittleMapScaleByLevelId(levelId)
        self:_InitAreaImage(levelId)
        self:_InitMapPath(levelId)
    end
end

function XUiBigWorldPanelLittleMap:_InitAreaImage(levelId)
    if self._IsEmpty then
        return
    end

    local groudIds = XMVCA.XBigWorldMap:GetMapGroupIdsByLevelId(levelId)
    local currentGroupId = XMVCA.XBigWorldMap:GetCurrentAreaGroupId()

    self._AreaGroupIds = {}
    if not XTool.IsTableEmpty(groudIds) then
        for i, groupId in pairs(groudIds) do
            local areaIds = XMVCA.XBigWorldMap:GetAreaIdsByGroupId(groupId)
            local imageList = self._AreaGroupList[i] or {}

            if not XTool.IsTableEmpty(areaIds) then
                for index, areaId in pairs(areaIds) do
                    local areaImage = imageList[index]
                    local posX = XMVCA.XBigWorldMap:GetAreaPosXByAreaId(areaId)
                    local posZ = XMVCA.XBigWorldMap:GetAreaPosZByAreaId(areaId)
                    local pixelRatio = XMVCA.XBigWorldMap:GetAreaPixelRatioByAreaId(areaId)

                    if not areaImage then
                        areaImage = XUiHelper.Instantiate(self.ImgLevelMap, self.MapLevel)
                        imageList[index] = areaImage
                    end

                    local xOffset, yOffset = self._AxisConversion:WorldToMapPosition2D(posX, posZ, pixelRatio)
                    areaImage.transform:SetAnchoredPosition(xOffset, yOffset)
                    areaImage.gameObject:SetActiveEx(true)
                    areaImage:SetImage(XMVCA.XBigWorldMap:GetAreaImageByAreaId(areaId), function()
                        areaImage:SetNativeSize()
                    end)

                    if currentGroupId == groupId then
                        self._CurrentGroupIndex = i
                    end
                end
                for index = #areaIds + 1, #imageList do
                    imageList[index].gameObject:SetActiveEx(false)
                end
            else
                for index = 1, #imageList do
                    imageList[index].gameObject:SetActiveEx(false)
                end
            end

            self._AreaGroupIds[i] = groupId
            self._AreaGroupList[i] = imageList
        end
        for i = #groudIds + 1, #self._AreaGroupList do
            if not XTool.IsTableEmpty(self._AreaGroupList[i]) then
                for index = 1, #self._AreaGroupList[i] do
                    self._AreaGroupList[i][index].gameObject:SetActiveEx(false)
                end
            end
        end
    else
        if not XTool.IsTableEmpty(self._AreaGroupList) then
            for i = 1, #self._AreaGroupList do
                if not XTool.IsTableEmpty(self._AreaGroupList[i]) then
                    for index = 1, #self._AreaGroupList[i] do
                        self._AreaGroupList[i][index].gameObject:SetActiveEx(false)
                    end
                end
            end
        end
    end
end

function XUiBigWorldPanelLittleMap:_RefreshContent()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

    if self._LevelId ~= levelId then
        self:_InitMap(levelId)
    end
    if self._IsEmpty then
        self:_RefreshEmptyMap()
    else
        self:_RefreshMap()
        self:_RefreshPin()
        self:_RefreshCurrentGroup(XMVCA.XBigWorldMap:GetCurrentAreaGroupId(), true)

        --- 重新初始化下遮罩
        if self.MaskMap then
            self.MaskMap:RecollectComponent()
        end
    end
end

function XUiBigWorldPanelLittleMap:_RefreshPinNodeIndex()
    if not XTool.IsTableEmpty(self._PinNodeMap) then
        for _, pinNode in pairs(self._PinNodeMap) do
            local pinData = pinNode:GetPinData()

            if pinData:IsQuest() then
                pinNode.Transform:SetAsLastSibling()
            end
        end
    end
end

function XUiBigWorldPanelLittleMap:_RefreshMap()
    local rectTransform = self.ImgMapBase.transform

    self.LittleMap.gameObject:SetActiveEx(true)
    self.EmptyMap.gameObject:SetActiveEx(false)
    self.ImgMapBase:SetSprite(XMVCA.XBigWorldMap:GetMapImageByLevelId(self._LevelId))
    self.ImgMapBase.gameObject:SetActiveEx(true)
    if not XTool.UObjIsNil(rectTransform) then
        local width = XMVCA.XBigWorldMap:GetMapWidthByLevelId(self._LevelId)
        local height = XMVCA.XBigWorldMap:GetMapHeightByLevelId(self._LevelId)

        rectTransform.sizeDelta = Vector2(width, height)
        self.MapPath.sizeDelta = Vector2(width, height)
    end

    if not XTool.UObjIsNil(self._AutoTransform) then
        local posX = XMVCA.XBigWorldMap:GetMapPosXByLevelId(self._LevelId)
        local posZ = XMVCA.XBigWorldMap:GetMapPosZByLevelId(self._LevelId)
        local pixelRatio = XMVCA.XBigWorldMap:GetMapPixelRatioByLevelId(self._LevelId)

        self._AutoTransform:SetTarget(self.ImgMapBase.transform, posX, posZ, pixelRatio, self._Scale)
        self._AutoTransform:SetCursor(self.PlayerPos.transform, self.ImgView.transform)
        self._AutoTransform:SetRefreshTrackHandle(Handler(self, self._RefreshTrackPin))
    end
end

function XUiBigWorldPanelLittleMap:_RefreshEmptyMap()
    local isLinkOther = XMVCA.XBigWorldMap:CheckLevelLinkOther(self._LevelId)

    self.ImgMapBase.gameObject:SetActiveEx(false)

    if not XTool.UObjIsNil(self._AutoTransform) then
        self._AutoTransform:SetTarget(self.ImgMapBase.transform, 0, 0, 0, 1)
        self._AutoTransform:SetCursor(self.PlayerPos.transform, self.ImgView.transform)
    end
    if self._PinNodeList then
        for _, v in pairs(self._PinNodeList) do
            v:Close()
        end
    end
    if self._PinAreaList then
        for _, v in pairs(self._PinAreaList) do
            v:Close()
        end
    end
    self.LittleMap.gameObject:SetActiveEx(isLinkOther)
    self.EmptyMap.gameObject:SetActiveEx(not isLinkOther)
end

function XUiBigWorldPanelLittleMap:_RefreshPin()
    local groupId = XMVCA.XBigWorldMap:GetCurrentAreaGroupId()

    if not XTool.IsNumberValid(groupId) then
        return
    end

    local index = 1
    local areaIndex = 1
    local pinDatas = XMVCA.XBigWorldMap:GetMapPinDatasByLevelIdAndGroupId(self._LevelId, groupId)

    self._PinNodeMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            local isDisplay = pinData:IsDisplaying()
            local isOut = pinData:IsOut()
            if isDisplay and pinData:IsPointPin() and not pinData:IsVirtual() and not isOut then
                local pinNode = self._PinNodeList[index]

                if not pinNode then
                    local node = XUiHelper.Instantiate(self.PinNode, self.MapPin)

                    pinNode = XUiBigWorldMapPin.New(node, self, self.PinTarget, self.MapPinTarget, true)
                    self._PinNodeList[index] = pinNode
                end

                index = index + 1
                pinNode:Open()
                pinNode:Refresh(self._LevelId, pinData, self._Interface)
                pinNode:SetPlayerTagActive(false)
                self._PinNodeMap[pinData.PinId] = pinNode
            end
            if isDisplay and pinData:IsLittleMapRadiusPin() and not isOut then
                self:_RefreshPinArea(areaIndex, pinData)
                areaIndex = areaIndex + 1
            end
        end
        self:_RefreshPinNodeIndex()
    end
    for i = index, #self._PinNodeList do
        self._PinNodeList[i]:Close()
    end
    for i = areaIndex, #self._PinAreaList do
        self._PinAreaList[i]:Close()
    end
end

function XUiBigWorldPanelLittleMap:_RefreshPinArea(areaIndex, pinData)
    if not self.PinArea then
        return
    end
    local pinNode = self._PinAreaList[areaIndex]
    if not pinNode then
        local node = XUiHelper.Instantiate(self.PinArea, self.MapAreaPin)

        pinNode = XUiBigWorldMapAreaPin.New(node, self, self.PinTarget, self.MapPinTarget)
        self._PinAreaList[areaIndex] = pinNode
    end
    pinNode:Open()
    pinNode:Refresh(self._LevelId, pinData, self._Interface)
end

function XUiBigWorldPanelLittleMap:_RefreshCurrentGroup(groupId, isForce)
    if self._AreaGroupIds[self._CurrentGroupIndex] ~= groupId then
        for i, id in pairs(self._AreaGroupIds) do
            if id == groupId then
                self._CurrentGroupIndex = i
                break
            end
        end
        self:_RefreshGroup()
    elseif isForce then
        self:_RefreshGroup()
    end
end

function XUiBigWorldPanelLittleMap:_RefreshGroup()
    self._AxisConversion:ConversionAreaGroupColor(self._AreaGroupList, self._CurrentGroupIndex)
end

function XUiBigWorldPanelLittleMap:_RefreshTrackPin(posX, posY)
    if not XMVCA.XBigWorldMap:CheckHasTrackPinIncludeVirtual(self._LevelId) then
        return
    end

    if not XMVCA.XBigWorldMap:CheckLevelHasMap(self._LevelId) then
        return
    end

    self._TrackPinIdDict = XMVCA.XBigWorldMap:GetCurrentTrackPinsIncludeVirtual(self._LevelId, self._TrackPinIdDict)

    if not XTool.IsTableEmpty(self._TrackPinIdDict) then
        local radius = self._TrackRadius
        local pixelRatio = XMVCA.XBigWorldMap:GetMapPixelRatioByLevelId(self._LevelId)

        for pinId, _ in pairs(self._TrackPinIdDict) do
            local pinData = XMVCA.XBigWorldMap:GetPinDataByLevelIdAndPinId(self._LevelId, pinId)

            if pinData then
                ---@type XUiBigWorldMapPin
                local pinNode = nil
                local worldPosition = pinData:GetAssistedPosition()

                if pinData:IsVirtual() then
                    local bindPinData = XMVCA.XBigWorldMap:GetPinDataByLevelIdAndPinId(pinData.BindLevelId,
                        pinData.BindPinId)

                    pinNode = self._PinNodeMap[pinData.BindPinId]

                    if bindPinData then
                        worldPosition = bindPinData:GetAssistedPosition()
                    end
                else
                    pinNode = self._PinNodeMap[pinId]
                end

                if pinNode then
                    local offsetX = (worldPosition.x - posX) * pixelRatio * self._Scale
                    local offsetY = (worldPosition.z - posY) * pixelRatio * self._Scale
                    local length = math.sqrt(offsetX * offsetX + offsetY * offsetY)

                    if length > radius then
                        local ratio = radius / length
                        local x = (offsetX * ratio) / self._Scale / pixelRatio + posX
                        local y = (offsetY * ratio) / self._Scale / pixelRatio + posY

                        if pinData:IsVirtual() then
                            pinNode:RefreshStyle(pinData)
                            pinNode:RefreshEmptyTag()
                        end
                        local xOffset, yOffset = self._AxisConversion:WorldToMapPosition2D(x, y)
                        pinNode:RefreshPosition(xOffset, yOffset)
                    else
                        pinNode:RefreshOriginalPosition()

                        if pinData:IsVirtual() then
                            pinNode:RefreshOriginalStyle()
                        end
                    end
                end
            end
        end
    end
end

-- endregion

return XUiBigWorldPanelLittleMap
