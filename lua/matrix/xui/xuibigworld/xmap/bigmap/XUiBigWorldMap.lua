local XUiBigWorldMapPin = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapPin")
local XUiBigWorldMapSelect = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapSelect")
local XUiBigWorldMapTrackPin = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTrackPin")
local XUiBigWorldMapTrackPlayer = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTrackPlayer")
local XBWMapAxisConversion = require("XModule/XBigWorldMap/XCommon/XBWMapAxisConversion")
local XBWBigMapInterface = require("XModule/XBigWorldMap/XInterface/XBWBigMapInterface")

---@class XUiBigWorldMap : XBigWorldUi
---@field MapArea UnityEngine.RectTransform
---@field RImgBase UnityEngine.UI.RawImage
---@field MapName UnityEngine.UI.Text
---@field AreaList XUiButtonGroup
---@field BtnArea XUiComponent.XUiButton
---@field Slider UnityEngine.UI.Slider
---@field BtnClose XUiComponent.XUiButton
---@field MapLevel UnityEngine.RectTransform
---@field MapPin UnityEngine.RectTransform
---@field ImgArea UnityEngine.UI.RawImage
---@field ImgPlayer UnityEngine.RectTransform
---@field TrackPin UnityEngine.RectTransform
---@field PanelPointer UnityEngine.RectTransform
---@field BtnAddSelect XUiComponent.XUiButton
---@field BtnMinusSelect XUiComponent.XUiButton
---@field TxtProgress UnityEngine.UI.Text
---@field ImgView UnityEngine.RectTransform
---@field MapPinTarget UnityEngine.RectTransform
---@field PinTarget UnityEngine.RectTransform
---@field PlayerTarget UnityEngine.RectTransform
---@field PanelPlayer UnityEngine.RectTransform
---@field DragArea UnityEngine.RectTransform
---@field PinNode UnityEngine.RectTransform
---@field PanelPreSelect UnityEngine.RectTransform
---@field BtnDetailClose XUiComponent.XUiButton
---@field BtnSelectClose XUiComponent.XUiButton
---@field Gesture XUiComponent.XGesture.XUiGestureFixedAreaScaleDrag
---@field _Control XBigWorldMapControl
local XUiBigWorldMap = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMap")

-- region 生命周期

function XUiBigWorldMap:OnAwake()
    ---@type XUiBigWorldMapPin[]
    self._PinNodeList = {}
    ---@type table<number, XUiBigWorldMapPin>
    self._PinNodeMap = {}
    ---@type XUiBigWorldMapPin
    self._CurrentSelectPin = nil
    ---@type XUiBigWorldMapPin
    self._CurrentSelectTagPin = nil

    ---@type XUiBigWorldMapTrackPin[]
    self._TrackPinList = {}
    ---@type table<number, XUiBigWorldMapTrackPin>
    self._TrackPinMap = {}

    ---@type XBWMapAxisConversion
    self._AxisConversion = XBWMapAxisConversion.New(CS.XUiType.Normal)

    self._AreaGroupList = {}
    self._AreaGroupIds = {}

    self._WorldId = 0
    self._LevelId = 0
    self._CurrentGroupIndex = 0
    self._CurrentGroupId = 0

    self._TargetPinId = 0
    self._BindPinId = 0

    self._FocusPosition = false

    self._MaxScale = 0
    self._MinScale = 0

    self._RightPadding = self.Gesture.Padding.right

    self._IsDetailShow = false
    self._IsIgnoreSlider = false
    self._IsOnlyOneFloor = false

    ---@type XUiBigWorldMapDetail
    self._DetailUi = false

    ---@type XUiBigWorldMapSelect
    self._SelectPanel = XUiBigWorldMapSelect.New(self.PanelPreSelect, self)
    self._SelectPanel:Close()

    ---@type XUiBigWorldMapTrackPlayer
    self._PlayerTrack = false

    ---@type XBWBigMapInterface
    self._Interface = XBWBigMapInterface.New(self)

    self.PanelSlider = self.Slider.transform.parent

    self._PcKey = {
        RT = 312,
        LT = 311,
    }
    self._PcPressHandle = Handler(self, self.OnPressPCKeyHandle)

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMap:OnStart(worldId, levelId, bindPinId, pinId, focusPos, scaleRatio)
    self._WorldId = worldId
    self._LevelId = levelId
    self._BindPinId = bindPinId or 0
    self._TargetPinId = pinId or 0
    self._FocusPosition = focusPos or false

    self._MaxScale = self._Control:GetMapMaxScaleByLevelId(levelId)
    self._MinScale = self._Control:GetMapMinScaleByLevelId(levelId)
    self._Control:InitMapData(worldId, levelId)
    self._AxisConversion:ChangeAxis(levelId)
    self:_InitGesture()
    self:_InitCurrentNpcIcon()
    self:_InitAreaGroup()
    self:_InitAreaList()
    self:_InitScale(scaleRatio)
end

function XUiBigWorldMap:OnEnable()
    self:_RefreshMap()
    self:_RefreshPin()
    self:_RefreshPosition()
    self:_RefreshTrackPin()
    self:_RefreshPlayerTrack()
    self:_RegisterPCEvent()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMap:OnDisable()
    self:_UnregisterPCEvent()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMap:OnDestroy()
end

-- endregion

-- region 按钮事件

function XUiBigWorldMap:OnSliderValueChanged(value)
    local scale = (self._MaxScale - self._MinScale) * value + self._MinScale

    if not self._IsIgnoreSlider then
        self:_RefreshTrackPin()
        self:_RefreshPlayerTrack()
        self.Gesture.Scale = scale
    end

    self._IsIgnoreSlider = false
    self._Control:SetMapScaleCache(scale)
end

function XUiBigWorldMap:OnGestureScaleValueChanged(value)
    self._IsIgnoreSlider = true
    self.Slider.value = (value - self._MinScale) / (self._MaxScale - self._MinScale)
    self:_RefreshTrackPin()
    self:_RefreshPlayerTrack()
end

function XUiBigWorldMap:OnGestureTranslateValueChanged(value)
    if not self._IsDetailShow then
        self:_RefreshTrackPin()
        self:_RefreshPlayerTrack()
    end
end

function XUiBigWorldMap:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldMap:OnBtnAddSelectClick()
    self:_AddSliderValue(0.1)
end

function XUiBigWorldMap:OnBtnMinusSelectClick()
    self:_AddSliderValue(-0.1)
end

function XUiBigWorldMap:OnBtnDetailCloseClick()
    self:_CloseDetail()
end

function XUiBigWorldMap:OnBtnSelectCloseClick()
    self:_CloseSelectPanel()
end

function XUiBigWorldMap:OnAreaListClick(index)
    self:_CloseSelectPanel()
    if self._CurrentGroupIndex ~= index then
        self:_RefreshGroup(index)
        self:_RefreshPinFloor(index)
        self._CurrentGroupIndex = index
        self:_RefreshCurrentAreaGroupPins()
    end
end

function XUiBigWorldMap:OnPressPCKeyHandle(inputDeviceType, key, operationType)
    if key == self._PcKey.RT then
        self:_AddSliderValue(-0.05)
    elseif key == self._PcKey.LT then
        self:_AddSliderValue(0.05)
    end
end

function XUiBigWorldMap:OnPinTrackChange(isTrack)
    self:_RefreshPin()
    self:_RefreshTrackPin()
end

function XUiBigWorldMap:OnPinActive()
    self:_RefreshPin()
end

function XUiBigWorldMap:OnPinBeginTeleport(teleportLevelId, levelId, pinId)
    local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

    if currentLevelId ~= teleportLevelId then
        self._Control:SendTeleportCommand(levelId, pinId)
    else
        self:CloseChildUi("UiBigWorldMapDetail")
        XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
            self._Control:SendTeleportCommand(levelId, pinId)
        end)
    end
end

function XUiBigWorldMap:OnPinEndTeleport()
    XMVCA.XBigWorldUI:Close(self.Name, function()
        XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
    end)
    self:_CloseOther()
end

function XUiBigWorldMap:OnEnterLevel()
    self:_CloseOther()
    self:Close()
end

function XUiBigWorldMap:OnPinDetailClose()
    self:_CloseDetail()
end

function XUiBigWorldMap:OnTeleportPopupClose()
    self.Gesture.WheelSensitivity = 0.1
end

function XUiBigWorldMap:OnTeleportPopupOpen()
    self.Gesture.WheelSensitivity = 0
end

function XUiBigWorldMap:OnAnchorAndSelectPin(pinIdStr)
    local pinId = tonumber(pinIdStr)

    self:_AnchorAndSelectPin(self._LevelId, pinId)
end

-- endregion

---@param pinData XBWMapPinData
function XUiBigWorldMap:OpenPinDetail(selectPin, levelId, pinData)
    if selectPin ~= self._CurrentSelectPin then
        self:_CancelSelectPin()
        self:_CancelSelectTagPin()
        self:_CloseSelectPanel(true)
        self:_ActiveTrack(false)
        self._CurrentSelectPin = selectPin
        self.BtnDetailClose.gameObject:SetActiveEx(true)
        self:_RefreshSelectGroup(pinData)
        self:_RefreshDeatil(levelId, pinData)
    end
end

---@param pinData XBWMapPinData
---@param bindPin XUiBigWorldMapPin
function XUiBigWorldMap:OpenTagPinDetail(bindPin, levelId, pinData)
    if bindPin ~= self._CurrentSelectTagPin then
        self:_CancelSelectPin()
        self:_CancelSelectTagPin()
        self:_CloseSelectPanel(true)
        self:_ActiveTrack(false)
        self._CurrentSelectTagPin = bindPin
        self.BtnDetailClose.gameObject:SetActiveEx(true)
        self:_RefreshSelectGroup(bindPin:GetPinData())
        self:_RefreshDeatil(levelId, pinData)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMap:OpenSelectPinDetail(levelId, pinData)
    self:_CloseSelectPanel()

    if pinData:IsVirtual() then
        local pinNode = self._PinNodeMap[pinData.BindPinId]

        if pinNode then
            pinNode:AnchorToAndSelectTag(pinData)
        end
    else
        local pinNode = self._PinNodeMap[pinData.PinId]

        if pinNode then
            pinNode:AnchorToAndSelect()
        end
    end
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMap:OpenPinSelectList(pinDatas, transform)
    if self._IsDetailShow then
        self:_CloseDetail()
    end
    if not XTool.IsTableEmpty(pinDatas) and table.nums(pinDatas) > 1 then
        self._SelectPanel:Open()
        self._SelectPanel:Refresh(self._LevelId, pinDatas, transform)
        self:_ActiveSlider(false)
        self.BtnSelectClose.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldMap:AnchorToPin(pinId)
    local pinNode = self._PinNodeMap[pinId]

    self:_CloseSelectPanel()
    if pinNode then
        pinNode:AnchorTo(true)
    end
end

function XUiBigWorldMap:AnchorToPosition(x, y, isCenter, isIgnoreTween)
    self:_CloseSelectPanel()
    if not XTool.UObjIsNil(self.Gesture) then
        if isIgnoreTween then
            if isCenter then
                self.Gesture:WorldPositionAnchorToSceneCenter(x, y)
            else
                self.Gesture:WorldPositionAnchorToScenePercentage(x, y, 0.35, 0.5)
            end
        else
            if isCenter then
                self.Gesture:WorldPositionAnchorToSceneCenter(x, y, 0.5, CS.DG.Tweening.Ease.InOutQuart)
            else
                self.Gesture:WorldPositionAnchorToScenePercentage(x, y, 0.35, 0.5, 0.5, CS.DG.Tweening.Ease.InOutQuart)
            end
        end
    end
end

function XUiBigWorldMap:GetCurrentFloorIndex()
    if XTool.IsNumberValid(self._CurrentGroupId) then
        return self._Control:GetFloorIndexByGroupId(self._CurrentGroupId)
    end

    return 0
end

function XUiBigWorldMap:GetCurrentSelectFloorIndex()
    local currentGroupId = self:GetCurrentSelectGroupId()

    return self._Control:GetFloorIndexByGroupId(currentGroupId)
end

function XUiBigWorldMap:GetCurrentSelectGroupId()
    return self._AreaGroupIds[self._CurrentGroupIndex] or 0
end

---@return XBWMapAxisConversion
function XUiBigWorldMap:GetAxisConversion()
    return self._AxisConversion
end

function XUiBigWorldMap:GetMapObject()
    return self.RImgBase.transform
end

---@type table<number, XUiBigWorldMapPin>
function XUiBigWorldMap:GetPinNodeMap()
    return self._PinNodeMap
end

-- region 私有方法

function XUiBigWorldMap:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick, true)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick, true)
    self:RegisterClickEvent(self.BtnDetailClose, self.OnBtnDetailCloseClick, true)
    self:RegisterClickEvent(self.BtnSelectClose, self.OnBtnSelectCloseClick, true)
    self.Slider.onValueChanged:AddListener(Handler(self, self.OnSliderValueChanged))
end

function XUiBigWorldMap:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMap:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMap:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, self.OnPinTrackChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, self.OnPinActive, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
        self.OnPinBeginTeleport, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT, self.OnPinEndTeleport,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL, self.OnEnterLevel, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN, self.OnTeleportPopupOpen, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE, self.OnTeleportPopupClose, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_DETAIL_CLOSE, self.OnPinDetailClose,
        self)
    XEventManager.AddEventListener("EVENT_BIGWORLD_MAP_FOCUS", self.OnAnchorAndSelectPin, self)
end

function XUiBigWorldMap:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE,
        self.OnPinTrackChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SCENE_OBJECT_ACTIVATE, self.OnPinActive,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
        self.OnPinBeginTeleport, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT,
        self.OnPinEndTeleport, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL, self.OnEnterLevel, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN, self.OnTeleportPopupOpen, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE, self.OnTeleportPopupClose, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_DETAIL_CLOSE,
        self.OnPinDetailClose, self)
    XEventManager.RemoveEventListener("EVENT_BIGWORLD_MAP_FOCUS", self.OnAnchorAndSelectPin, self)
end

function XUiBigWorldMap:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMap:_RegisterPCEvent()
    CS.XInputManager.RegisterOnPress(CS.XInputManager.XOperationType.System, self._PcPressHandle)
end

function XUiBigWorldMap:_UnregisterPCEvent()
    CS.XInputManager.UnregisterOnPress(CS.XInputManager.XOperationType.System, self._PcPressHandle)
end

function XUiBigWorldMap:_RefreshPin()
    local pinDatas = self._Control:GetMapPinDatasByLevelId(self._LevelId)
    local index = 1

    self._PinNodeMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            if pinData:IsDisplaying() and not pinData:IsVirtual() then
                local pinNode = self._PinNodeList[index]

                if not pinNode then
                    local node = XUiHelper.Instantiate(self.PinNode, self.MapPin)

                    pinNode = XUiBigWorldMapPin.New(node, self, self.PinTarget, self.MapPinTarget)
                    self._PinNodeList[index] = pinNode
                end

                index = index + 1
                self._PinNodeMap[pinData.PinId] = pinNode
                pinNode:Open()
                pinNode:Refresh(self._LevelId, pinData, self._Interface)
                pinNode:SetPlayerTagActive(pinData.PinId == self._BindPinId)
                self:_RefreshCurrentAreaGroupPinNode(pinNode, self:GetCurrentSelectGroupId(), pinData)
            end
        end
        self:_RefreshPinNodeIndex()
    end
    for i = index, table.nums(self._PinNodeList) do
        self._PinNodeList[i]:Close()
    end
end

function XUiBigWorldMap:_RefreshPinNodeIndex()
    if not XTool.IsTableEmpty(self._PinNodeMap) then
        for _, pinNode in pairs(self._PinNodeMap) do
            local pinData = pinNode:GetPinData()

            if pinData:IsQuest() then
                pinNode.Transform:SetAsLastSibling()
            end
        end
    end
end

function XUiBigWorldMap:_RefreshCurrentAreaGroupPins()
    local groupId = self:GetCurrentSelectGroupId()

    if XTool.IsNumberValid(groupId) then
        local pinNodeMap = self:GetPinNodeMap()

        if not XTool.IsTableEmpty(pinNodeMap) then
            for _, pinNode in pairs(pinNodeMap) do
                local pinData = pinNode:GetPinData()

                self:_RefreshCurrentAreaGroupPinNode(pinNode, groupId, pinData)
            end
        end
    end
end

---@param pinData XBWMapPinData
---@param pinNode XUiBigWorldMapPin
function XUiBigWorldMap:_RefreshCurrentAreaGroupPinNode(pinNode, groupId, pinData)
    if self._AxisConversion:CheckUnimportantPin(pinData, groupId) or self._Control:CheckPinCoincidence(pinData) then
        pinNode:SetShow(false)
    else
        pinNode:SetShow(true)
    end
end

function XUiBigWorldMap:_RefreshPinFloor(index)
    if XTool.IsTableEmpty(self._PinNodeMap) then
        return
    end

    local groupId = self._AreaGroupIds[index]

    if XTool.IsNumberValid(groupId) then
        for _, pinNode in pairs(self._PinNodeMap) do
            pinNode:RefreshFloor(pinNode:GetPinData(), index)
        end
    end
end

function XUiBigWorldMap:_RefreshPlayerTrack()
    if self._PlayerTrack then
        local trackPos = self._AxisConversion:FilterOutScreenPlayerPosition(self:GetMapObject(), self.TrackPin)

        if trackPos then
            local posX, posY, _ = self.PlayerTarget:GetPosition()
            self._PlayerTrack:Open()
            self._PlayerTrack:Refresh(posX, posY)
            self._PlayerTrack:SetPosition(trackPos.Position, trackPos.Direction, trackPos.Angle, self.TrackPin.rect)
        else
            self._PlayerTrack:Close()
        end
    end
end

function XUiBigWorldMap:_RefreshTrackPin()
    local index = 1
    self._TrackPinDataMap = self._Control:GetTrackPinDatas(self._LevelId, self._TrackPinDataMap)
    local trackPinIds = self._AxisConversion:FilterOutScreenPinsPosition(self._TrackPinDataMap, self:GetMapObject(),
        self.TrackPin)

    for k, _ in pairs(self._TrackPinMap) do
        self._TrackPinMap[k] = nil
    end
   
    if not XTool.IsTableEmpty(trackPinIds) then
        local trackPinNodes = {}

        if self._PlayerTrack and self._PlayerTrack:IsNodeShow() then
            local screenRect = self._AxisConversion:GetScreenUIRect(self:GetMapObject())
            local centerPos = screenRect.center

            local posX, posY, _ = self.PlayerTarget:GetPosition()
            table.insert(trackPinNodes, {
                PinId = 0,
                Node = self._PlayerTrack,
                Priority = math.pow(posX - centerPos.x, 2) +
                    math.pow(posY - centerPos.y, 2),
            })
        end

        for pinId, pinPos in pairs(trackPinIds) do
            local trackPin = self._TrackPinList[index]

            if not trackPin then
                local trackNode = XUiHelper.Instantiate(self.PanelPointer, self.TrackPin)

                trackPin = XUiBigWorldMapTrackPin.New(trackNode, self)
                self._TrackPinList[index] = trackPin
            end

            index = index + 1
            trackPin:Open()
            trackPin:Refresh(self._LevelId, pinId)
            trackPin:SetPosition(pinPos.Position, pinPos.Direction, pinPos.Angle, self.TrackPin.rect)
            self._TrackPinMap[pinId] = trackPin
            table.insert(trackPinNodes, {
                PinId = pinId,
                Node = trackPin,
                Priority = pinPos.Priority,
            })
        end
        table.sort(trackPinNodes, function(pinA, pinB)
            local isQuestA = self._Control:CheckQuestPin(self._LevelId, pinA.PinId)
            local isQuestB = self._Control:CheckQuestPin(self._LevelId, pinB.PinId)

            if isQuestA ~= isQuestB then
                return not isQuestA
            end

            return pinA.Priority > pinB.Priority
        end)
        for i, trackPinNode in pairs(trackPinNodes) do
            trackPinNode.Node:SetSiblingIndex(i)
        end
    end
    for i = index, table.nums(self._TrackPinList) do
        self._TrackPinList[i]:Close()
    end
end

function XUiBigWorldMap:_RefreshPosition()
    if not XTool.IsNumberValid(self._TargetPinId) then
        if self._FocusPosition then
            local posX, posY = self._AxisConversion:WorldToMapUIWorldPosition2D(self:GetMapObject(),
                self._FocusPosition.x, self._FocusPosition.y)

            self:AnchorToPosition(posX, posY, true, true)
        else
            if XTool.IsNumberValid(self._BindPinId) then
                local pinData = self._Control:GetPinDataByLevelIdAndPinId(self._LevelId, self._BindPinId)

                local pinNode = self._PinNodeMap[pinData.PinId]

                if pinNode then
                    pinNode:AnchorTo(true, true)
                end
            else
                local positionX, positionY, _ = self.PlayerTarget:GetPosition()
                self:AnchorToPosition(positionX, positionY, true, true)
            end
        end
    else
        self:_AnchorTargetPin()
    end
end

function XUiBigWorldMap:_RefreshMap()
    local rectTransform = self.RImgBase.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))

    self.TxtProgress.text = self._Control:GetCollectableText(self._LevelId)
    self.MapName.text = self._Control:GetMapNameByLevelId(self._LevelId)
    self.RImgBase:SetRawImage(self._Control:GetMapImageByLevelId(self._LevelId))

    if not XTool.UObjIsNil(rectTransform) then
        local width = self._Control:GetMapWidthByLevelId(self._LevelId)
        local height = self._Control:GetMapHeightByLevelId(self._LevelId)

        rectTransform.sizeDelta = Vector2(width, height)
    end
end

function XUiBigWorldMap:_RefreshGroup(index)
    self._Control:RefreshMapAreaGroup(self._AreaGroupList, index)
end

---@param pinData XBWMapPinData
function XUiBigWorldMap:_RefreshSelectGroup(pinData)
    if pinData then
        local groupId = pinData:GetAreaGroupId()

        for index, areaGroupId in pairs(self._AreaGroupIds) do
            if areaGroupId == groupId then
                self.AreaList:SelectIndex(index)
                break
            end
        end
    end
end

function XUiBigWorldMap:_RefreshDeatil(levelId, pinData)
    self._IsDetailShow = true
    self:OpenChildUi("UiBigWorldMapDetail")
    self:_InitDetailUi()
    self:_RefreshPinRangeSelectable(false)
    self.Gesture.Padding.right = self._RightPadding + 200
    self._DetailUi:Refresh(levelId, pinData)
    self:_ActiveSlider(false)
end

function XUiBigWorldMap:_RefreshPinRangeSelectable(isSelect)
    if not XTool.IsTableEmpty(self._PinNodeList) then
        for _, pinNode in pairs(self._PinNodeList) do
            pinNode:SetRangeSelectable(isSelect)
        end
    end
end

function XUiBigWorldMap:_AddSliderValue(value)
    self.Slider.value = self.Slider.value + value
end

function XUiBigWorldMap:_CancelSelectPin()
    if self._CurrentSelectPin then
        self._CurrentSelectPin:SetSelect(false)
        self._CurrentSelectPin = false
    end
end

function XUiBigWorldMap:_CancelSelectTagPin()
    if self._CurrentSelectTagPin then
        self._CurrentSelectTagPin:CancelSelectTag()
        self._CurrentSelectTagPin = false
    end
end

function XUiBigWorldMap:_CloseSelectPanel(isIgnoreSlider)
    self._SelectPanel:Close()
    self.BtnSelectClose.gameObject:SetActiveEx(false)

    if not isIgnoreSlider then
        self:_ActiveSlider(not self._IsDetailShow)
    end
end

function XUiBigWorldMap:_AnchorAndSelectPin(levelId, pinId, isIgnoreTween)
    if not XTool.IsNumberValid(levelId) or not XTool.IsNumberValid(pinId) then
        return
    end

    local pinData = self._Control:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        if pinData:IsVirtual() then
            local pinNode = self._PinNodeMap[pinData.BindPinId]

            if pinNode then
                pinNode:AnchorToAndSelectTag(pinData, isIgnoreTween)
            end
        else
            local pinNode = self._PinNodeMap[pinId]

            if pinNode then
                pinNode:AnchorToAndSelect(isIgnoreTween)
            end
        end
    end
end

function XUiBigWorldMap:_AnchorTargetPin()
    if XTool.IsNumberValid(self._TargetPinId) then
        self:_AnchorAndSelectPin(self._LevelId, self._TargetPinId, true)
    end
end

function XUiBigWorldMap:_CloseDetail()
    self:CloseChildUi("UiBigWorldMapDetail")
    self._IsDetailShow = false
    self:_CancelSelectPin()
    self:_CancelSelectTagPin()
    self:_ActiveSlider(true)
    self:_ActiveTrack(true)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self:_RefreshPinRangeSelectable(true)
    self.Gesture.Padding.right = self._RightPadding
end

function XUiBigWorldMap:_CloseOther()
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldMenu")
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldTaskMain")
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldMessage")
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldPopupMessage")
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldPopupMessageSingle")
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldProcess")
end

function XUiBigWorldMap:_ActiveSlider(isActive)
    self.PanelSlider.gameObject:SetActiveEx(isActive)
    self.Gesture.WheelSensitivity = isActive and 0.1 or 0
end

function XUiBigWorldMap:_ActiveTrack(isActive)
    if self._PlayerTrack then
        if isActive then
            self:_RefreshPlayerTrack()
        else
            self._PlayerTrack:Close()
        end
    end
    if isActive then
        self:_RefreshTrackPin()
    else
        if not XTool.IsTableEmpty(self._TrackPinMap) then
            for _, trackPin in pairs(self._TrackPinMap) do
                trackPin:Close()
            end
        end
    end
end

function XUiBigWorldMap:_InitDetailUi()
    if not self._DetailUi then
        self._DetailUi = self:FindChildUiObj("UiBigWorldMapDetail")
    end
end

function XUiBigWorldMap:_InitAreaList()
    local groupIds = self._Control:GetMapGroupIdsByLevelId(self._LevelId)

    self._AreaGroupIds = {}
    if not XTool.IsTableEmpty(groupIds) then
        local playerGroupId = self._Control:GetCurrentAreaGroupId()
        local currentGroupId = playerGroupId
        local currentIndex = 1
        local groupButtonList = {}

        self._CurrentGroupIndex = 0

        if XTool.IsNumberValid(self._TargetPinId) then
            currentGroupId = self._Control:GetPinGroupIdByLevelIdAndPinId(self._LevelId, self._TargetPinId)
        elseif XTool.IsNumberValid(self._BindPinId) then
            currentGroupId = self._Control:GetPinGroupIdByLevelIdAndPinId(self._LevelId, self._BindPinId)
        end
        if XTool.IsNumberValid(self._BindPinId) then
            playerGroupId = self._Control:GetPinGroupIdByLevelIdAndPinId(self._LevelId, self._BindPinId)
        end

        for index, groupId in pairs(groupIds) do
            local button = XUiHelper.Instantiate(self.BtnArea, self.AreaList.transform)

            button:ShowTag(playerGroupId == groupId)
            button:SetNameByGroup(0, self._Control:GetMapAreaGroupNameByGroupId(groupId))
            groupButtonList[index] = button
            self._AreaGroupIds[index] = groupId

            if currentGroupId == groupId then
                currentIndex = index
                self._CurrentGroupId = groupId
            end
        end

        self._IsOnlyOneFloor = table.nums(groupIds) == 1
        self.BtnArea.gameObject:SetActiveEx(false)
        self.AreaList:Init(groupButtonList, Handler(self, self.OnAreaListClick))
        self.AreaList:SelectIndex(currentIndex)
        self.AreaList.gameObject:SetActiveEx(not self._IsOnlyOneFloor)
    else
        self.BtnArea.gameObject:SetActiveEx(false)
        self.MapLevel.gameObject:SetActiveEx(false)
        self.AreaList.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMap:_InitAreaGroup()
    local groupIds = self._Control:GetMapGroupIdsByLevelId(self._LevelId)

    self._AreaGroupList = {}
    if not XTool.IsTableEmpty(groupIds) then
        for i, groupId in pairs(groupIds) do
            local areaIds = self._Control:GetAreaIdsByGroupId(groupId)
            local imageList = {}

            if not XTool.IsTableEmpty(areaIds) then
                for index, areaId in pairs(areaIds) do
                    local areaImage = XUiHelper.Instantiate(self.ImgArea, self.MapLevel)
                    local rectTransform = areaImage.transform

                    if not XTool.UObjIsNil(rectTransform) then
                        local posX = self._Control:GetAreaPosXByAreaId(areaId)
                        local posZ = self._Control:GetAreaPosZByAreaId(areaId)
                        local pixelRatio = self._Control:GetAreaPixelRatioByAreaId(areaId)

                        local xOffset, yOffset = self._AxisConversion:WorldToMapPosition2D(posX, posZ, pixelRatio)
                        rectTransform:SetAnchoredPosition(xOffset, yOffset)
                    end

                    imageList[index] = areaImage
                    areaImage.gameObject:SetActiveEx(true)
                    areaImage:SetRawImage(self._Control:GetAreaImageByAreaId(areaId), function()
                        areaImage:SetNativeSize()
                    end)
                end
            end

            self._AreaGroupList[i] = imageList
        end
    end
end

function XUiBigWorldMap:_InitCurrentNpcIcon()
    if XTool.IsNumberValid(self._BindPinId) then
        self.PanelPlayer.gameObject:SetActiveEx(false)
    else
        local npcTransform = self._AxisConversion:GetCurrentNpcTransform()
        local rotation = npcTransform.eulerAngles
        local positionX, _, positionZ = npcTransform:GetPosition()
        local cameraTransform = self._Control:GetCurrentCameraTransform()
        local transformBind = self.PanelPlayer.gameObject:GetComponent(typeof(CS.XTransformBind))

        if XTool.UObjIsNil(transformBind) then
            transformBind = self.PanelPlayer.gameObject:AddComponent(typeof(CS.XTransformBind))
        end

        local xOffset, yOffset = self._AxisConversion:WorldToMapPosition2D(positionX, positionZ)
        self.PlayerTarget:SetAnchoredPosition(xOffset, yOffset) 
        
        self.ImgPlayer.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, -rotation.y)

        transformBind:SetTarget(self.PlayerTarget)
        if cameraTransform then
            rotation = cameraTransform.eulerAngles

            self.ImgView.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, -rotation.y)
        else
            self.ImgView.gameObject:SetActiveEx(false)
        end

        self._PlayerTrack = XUiBigWorldMapTrackPlayer.New(self.PanelPointer, self)
        self._PlayerTrack:Close()
    end
end

function XUiBigWorldMap:_InitUi()
    self.TrackPin.gameObject:SetActiveEx(true)
    self.PinNode.gameObject:SetActiveEx(false)
    self.ImgArea.gameObject:SetActiveEx(false)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self.BtnSelectClose.gameObject:SetActiveEx(false)
    self.PanelPointer.gameObject:SetActiveEx(false)
end

function XUiBigWorldMap:_InitGesture()
    if not XTool.UObjIsNil(self.Gesture) then
        self.Gesture.MaxScale = self._MaxScale
        self.Gesture.MinScale = self._MinScale
        self.Gesture:AddScaleValueChangedListener(Handler(self, self.OnGestureScaleValueChanged))
        self.Gesture:AddTranslateValueChangedListener(Handler(self, self.OnGestureTranslateValueChanged))
    end
end

function XUiBigWorldMap:_InitScale(scaleRatio)
    local defaultScale = self._Control:GetMapDefaultScale(self._LevelId)
    local scale = self._Control:GetMapScaleCache(defaultScale)

    if XTool.IsNumberValid(scaleRatio) then
        scale = self._MinScale + (self._MaxScale - self._MinScale) * (scaleRatio / 100)
    end

    scale = XMath.Clamp(scale, self._MinScale, self._MaxScale)
    self.Gesture.Scale = scale
    self.Slider:SetValueWithoutNotify((scale - self._MinScale) / (self._MaxScale - self._MinScale))
end

-- endregion

return XUiBigWorldMap
