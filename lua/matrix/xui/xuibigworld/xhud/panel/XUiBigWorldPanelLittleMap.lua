local XUiBigWorldMapPin = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapPin")
local XBWMapAxisConversion = require("XModule/XBigWorldMap/XCommon/XBWMapAxisConversion")
local XBWLittleMapInterface = require("XModule/XBigWorldMap/XInterface/XBWLittleMapInterface")

---@class XUiBigWorldPanelLittleMap : XUiNode
---@field PlayerPos UnityEngine.RectTransform
---@field BtnBigMap XUiComponent.XUiButton
---@field MapPin UnityEngine.RectTransform
---@field PinNode UnityEngine.RectTransform
---@field MapLevel UnityEngine.RectTransform
---@field ImgLevelMap UnityEngine.UI.Image
---@field ImgMapBase UnityEngine.UI.Image
---@field ImgView UnityEngine.RectTransform
---@field MapPinTarget UnityEngine.RectTransform
---@field PinTarget UnityEngine.RectTransform
---@field PanelTrack UnityEngine.RectTransform
---@field Parent XUiBigWorldHud
local XUiBigWorldPanelLittleMap = XClass(XUiNode, "XUiBigWorldPanelLittleMap")

-- region 生命周期

function XUiBigWorldPanelLittleMap:OnStart()
    ---@type XUiBigWorldMapPin[]
    self._PinNodeList = {}
    ---@type table<number, XUiBigWorldMapPin>
    self._PinNodeMap = {}

    ---@type XBWMapAxisConversion
    self._AxisConversion = XBWMapAxisConversion.New(CS.XUiType.Hud)

    self._AreaGroupList = {}
    self._AreaGroupIds = {}
    self._CurrentGroupIndex = 1

    self._Scale = 1
    self._TrackRadius = 0

    self._AutoTransform = nil

    self._IsEmpty = false

    ---@type XBWLittleMapInterface
    self._Interface = XBWLittleMapInterface.New(self)

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

function XUiBigWorldPanelLittleMap:OnPinStateChange()
    if not self._IsEmpty then
        self:_RefreshPin()
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
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_POSITION_UPDATE,
        self.OnPinStateChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, self.OnPinStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.OnLevelUpdate,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, self.OnPlayerEnterArea,
        self)
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
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_POSITION_UPDATE,
        self.OnPinStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, self.OnPinStateChange,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE,
        self.OnLevelUpdate, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAYER_ENTER_AREA, self.OnPlayerEnterArea,
        self)
end

function XUiBigWorldPanelLittleMap:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPanelLittleMap:_InitUi()
    self.PinNode.gameObject:SetActiveEx(false)
    self.ImgLevelMap.gameObject:SetActiveEx(false)
end

function XUiBigWorldPanelLittleMap:_InitTrack()
    self._TrackRadius = self.PanelTrack.rect.width / 2
end

function XUiBigWorldPanelLittleMap:_InitMap(levelId)
    self._LevelId = levelId
    self._IsEmpty = not XMVCA.XBigWorldMap:CheckLevelHasMap(levelId)
    self._AutoTransform = self.GameObject:GetComponent(typeof(CS.XLittleMapAutoTransform))

    if XTool.UObjIsNil(self._AutoTransform) then
        self._AutoTransform = self.GameObject:AddComponent(typeof(CS.XLittleMapAutoTransform))
    end
    if not self._IsEmpty then
        self._AxisConversion:ChangeAxis(levelId)
        self._Scale = XMVCA.XBigWorldMap:GetLittleMapScaleByLevelId(levelId)
        self:_InitAreaImage(levelId)
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

                    local xOffset, yOffset =  self._AxisConversion:WorldToMapPosition2D(posX, posZ, pixelRatio)
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

    self.ImgMapBase:SetSprite(XMVCA.XBigWorldMap:GetMapImageByLevelId(self._LevelId))
    self.ImgMapBase.gameObject:SetActiveEx(true)
    if not XTool.UObjIsNil(rectTransform) then
        local width = XMVCA.XBigWorldMap:GetMapWidthByLevelId(self._LevelId)
        local height = XMVCA.XBigWorldMap:GetMapHeightByLevelId(self._LevelId)

        rectTransform.sizeDelta = Vector2(width, height)
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
    self.ImgMapBase.gameObject:SetActiveEx(false)

    if not XTool.UObjIsNil(self._AutoTransform) then
        self._AutoTransform:SetTarget(self.ImgMapBase.transform, 0, 0, 0, 1)
        self._AutoTransform:SetCursor(self.PlayerPos.transform, self.ImgView.transform)
    end
end

function XUiBigWorldPanelLittleMap:_RefreshPin()
    local groupId = XMVCA.XBigWorldMap:GetCurrentAreaGroupId()

    if not XTool.IsNumberValid(groupId) then
        return
    end

    local pinDatas = XMVCA.XBigWorldMap:GetMapPinDatasByLevelIdAndGroupId(self._LevelId, groupId)

    self._PinNodeMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        local index = 1

        for _, pinData in pairs(pinDatas) do
            if pinData:IsDisplaying() and not pinData:IsVirtual() then
                local pinNode = self._PinNodeList[index]

                if not pinNode then
                    local node = XUiHelper.Instantiate(self.PinNode, self.MapPin)

                    pinNode =
                        XUiBigWorldMapPin.New(node, self, self.PinTarget, self.MapPinTarget, true)
                    self._PinNodeList[index] = pinNode
                end

                index = index + 1
                pinNode:Open()
                pinNode:Refresh(self._LevelId, pinData, self._Interface)
                pinNode:SetPlayerTagActive(false)
                self._PinNodeMap[pinData.PinId] = pinNode
            end
            self:_RefreshPinNodeIndex()
        end
        for i = index, table.nums(self._PinNodeList) do
            self._PinNodeList[i]:Close()
        end
    end
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
