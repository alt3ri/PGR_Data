local XUiBigWorldMapPin = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapPin")
local XUiBigWorldMapAreaPin = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapAreaPin")
local XUiBigWorldMapSelect = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapSelect")
local XUiBigWorldMapTab = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTab")
local XUiBigWorldMapTitle = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTitle")
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
---@field MapAreaPin UnityEngine.RectTransform
---@field PinArea UnityEngine.RectTransform
---@field PanelChange UnityEngine.RectTransform
---@field ListChangeTab XUiButtonGroup
---@field BtnChangeTab XUiComponent.XUiButtonEx
---@field BtnCharacterPosition XUiComponent.XUiButtonEx
---@field PanelOverview UnityEngine.RectTransform
---@field BtnOverview XUiComponent.XUiButtonEx
---@field PanelSubAreaTitle UnityEngine.RectTransform
---@field MapAreaTitle UnityEngine.RectTransform
---@field MapAreaTargetTitle UnityEngine.RectTransform
---@field TxtMapAreaTitle UnityEngine.UI.Text
---@field TxtMapAreaSubTitle UnityEngine.UI.Text
---@field PanelCharacterPosition UnityEngine.RectTransform
---@field BtnMapSet XUiComponent.XUiButtonEx
---@field ListMapSet UnityEngine.RectTransform
---@field MapAreaTitleTarget UnityEngine.RectTransform
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

    ---@type XUiBigWorldMapAreaPin[]
    self._PinAreaList = {}

    ---@type XUiBigWorldMapTrackPin[]
    self._TrackPinList = {}
    ---@type table<number, XUiBigWorldMapTrackPin>
    self._TrackPinMap = {}

    ---@type XBWMapAxisConversion
    self._AxisConversion = XBWMapAxisConversion.New(CS.XUiType.Normal)

    ---@type XUiBigWorldMapTab[]
    self._MapTabList = {}

    self._AreaGroupList = {}
    self._AreaGroupIds = {}
    self._GroupButtonList = {}
    self._GroupButtonAnimations = {}

    self._ChangeTabList = {}
    self._ChangeIndexMap = {}
    self._CurrentChangeIndex = 0
    self._ChangeTabCount = 0

    self._WorldId = 0
    self._LevelId = 0
    self._CurrentGroupIndex = 0
    self._CurrentGroupId = 0
    self._GroupTabCount = 0

    self._TargetPinId = 0
    self._BindPinId = 0

    self._FocusPosition = false

    self._MaxScale = 0
    self._MinScale = 0

    self._RightPadding = self.Gesture.Padding.right

    self._IsDetailShow = false
    self._IsIgnoreSlider = false
    self._IsOnlyOneFloor = false
    self._IsOverviewShow = false

    ---@type XUiBigWorldMapTitle[]
    self._TitleList = {}
    ---@type XUiBigWorldMapTitle[]
    self._SubTitleList = {}
    ---@type XUiBigWorldMapTitle[]
    self._CurrentTitleList = {}
    self._TitleTargetList = {}

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
        Right = 304,
        Left = 305,
    }
    self._LeftRightGap = 0.3
    self._leftTime = 0
    self._rightTime = 0
    self._PcPressHandle = Handler(self, self.OnPressPCKeyHandle)

    self._PinIdToTarget = {}
    self._IsShowCharactorPos = self._Control:GetShowCharactorPos()

    self._IsSetShow = true

    self._MapSetAnimation = false

    self._WaitChangeMapIndex = false

    self._CurrentPlayAreaAnimation = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMap:OnStart(worldId, levelId, bindPinId, pinId, focusPos, scaleRatio, openAiMemory)
    self._WorldId = worldId
    self._LevelId = levelId
    self._BindPinId = bindPinId or 0
    self._TargetPinId = pinId or 0
    self._FocusPosition = focusPos or false

    if openAiMemory == 1 and self._IsShowCharactorPos == false then
        self._IsShowCharactorPos = true
        self._Control:SetShowCharactorPos(self._IsShowCharactorPos)
    end
    self.BtnCharacterPosition:SetButtonState(self._IsShowCharactorPos and CS.UiButtonState.Select or
        CS.UiButtonState.Normal)

    self._MaxScale = self._Control:GetMapMaxScaleByLevelId(levelId)
    self._MinScale = self._Control:GetMapMinScaleByLevelId(levelId)
    self._Control:InitMapData(worldId, levelId)
    self._AxisConversion:ChangeAxis(levelId)
    self:_InitGesture()
    self:_InitCurrentNpcIcon()
    self:_InitAreaGroup()
    self:_InitChangeList()
    self:_InitTitle(levelId)
    self:_InitAreaList()
    self:_InitScale(scaleRatio)

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_SWITCH, self.OnSwitchMap, self)
end

function XUiBigWorldMap:OnEnable()
    if self._WaitChangeMapIndex then
        self.ListChangeTab:SelectIndex(self._WaitChangeMapIndex)
        self._WaitChangeMapIndex = false
    else
        self:_RefreshMap()
        self:_RefreshPin()
        self:_RefreshPosition()
        self:_RefreshPlayerTrack()
        self:_RefreshTrackPin()
    end

    self:_PlayAnimation()
    self:_PlayAreaGroupAnimation()
    self:_RefreshCurrentAreaGroupTitles()
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
    XMVCA.XBigWorldUI:Close("UiBigWorldMapDetail")
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_SWITCH, self.OnSwitchMap, self)
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
    self:_RefreshTitle(scale)
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

function XUiBigWorldMap:OnBtnOverviewClick()
    self:_CloseSelectPanel()
    XMVCA.XBigWorldUI:Open("UiBigWorldMapOverview")
end

function XUiBigWorldMap:OnBtnCharacterPositionClick()
    self._IsShowCharactorPos = self.BtnCharacterPosition.ButtonState == CS.UiButtonState.Select
    self._Control:SetShowCharactorPos(self._IsShowCharactorPos)
    self:_RefreshPin()
    self:_CloseSelectPanel()
end

function XUiBigWorldMap:OnBtnMapSetClick()
    self._IsSetShow = not self._IsSetShow

    if self._IsSetShow then
        self.ListMapSet.gameObject:SetActiveEx(true)
    else
        if self._MapSetAnimation then
            self._MapSetAnimation:PlayTimelineAnimation(function()
                self.ListMapSet.gameObject:SetActiveEx(false)
            end)
        else
            self.ListMapSet.gameObject:SetActiveEx(false)
        end
    end
end

function XUiBigWorldMap:OnAreaListClick(index)
    self:_CloseSelectPanel()
    if self._CurrentGroupIndex ~= index then
        self._CurrentGroupIndex = index
        self:_RefreshGroup(index)
        self:_RefreshPinFloor(index)
        self:_RefreshCurrentAreaGroupPins()
        self:_RefreshCurrentAreaGroupTitles()
        if not self._IsAutoSelect then
            self:_RefreshPlayerPosition()
        end
        self._IsAutoSelect = false
    end
    self:_PlayAreaGroupAnimation()
end

function XUiBigWorldMap:OnChangeTabClick(index)
    local levelId = self._ChangeIndexMap[index]

    self._CurrentChangeIndex = index
    if XTool.IsNumberValid(levelId) and levelId ~= self._LevelId then
        self:_ChangeMap(levelId)
    end
end

function XUiBigWorldMap:OnPressPCKeyHandle(inputDeviceType, key, operationType)
    if self._IsDetailShow then
        return
    end
    if key == self._PcKey.RT then
        self:_AddSliderValue(-0.05)
    elseif key == self._PcKey.LT then
        self:_AddSliderValue(0.05)
    elseif key == self._PcKey.Right then
        if self._ChangeTabCount > 0 then
            local currentTime = CS.UnityEngine.Time.realtimeSinceStartup
            if currentTime - self._leftTime < self._LeftRightGap then
                return
            end

            local index = self._CurrentChangeIndex + 1
            if index > self._ChangeTabCount then
                index = 1
            end

            self.ListChangeTab:SelectIndex(index)
            self._leftTime = currentTime
        end
    elseif key == self._PcKey.Left then
        if self._GroupTabCount > 0 then
            local currentTime = CS.UnityEngine.Time.realtimeSinceStartup
            if currentTime - self._rightTime < self._LeftRightGap then
                return
            end

            local index = self._CurrentGroupIndex + 1
            if index > self._GroupTabCount then
                index = 1
            end

            self.AreaList:SelectIndex(index)
            self._rightTime = currentTime
        end
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
    XMVCA.XBigWorldUI:Close("UiBigWorldMapDetail")
    local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    if currentLevelId ~= teleportLevelId then
        self._Control:SendTeleportCommand(levelId, pinId)
    else
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

function XUiBigWorldMap:OnSwitchMap(levelId)
    if not XTool.IsTableEmpty(self._ChangeIndexMap) then
        for index, changeLevelId in pairs(self._ChangeIndexMap) do
            if changeLevelId == levelId then
                self._WaitChangeMapIndex = index
                break
            end
        end
    end
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
        self:_SetRightPanelActive(false)
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

function XUiBigWorldMap:GetOrCreateTarget(pinId, prefab, parent)
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

function XUiBigWorldMap:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick, true)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick, true)
    self:RegisterClickEvent(self.BtnDetailClose, self.OnBtnDetailCloseClick, true)
    self:RegisterClickEvent(self.BtnSelectClose, self.OnBtnSelectCloseClick, true)
    self:RegisterClickEvent(self.BtnOverview, self.OnBtnOverviewClick, true)
    self:RegisterClickEvent(self.BtnCharacterPosition, self.OnBtnCharacterPositionClick, true)
    self:RegisterClickEvent(self.BtnMapSet, self.OnBtnMapSetClick, true)
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
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_MAP_PIN_SHOW_TYPE, self.OnPinActive, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
        self.OnPinBeginTeleport, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT, self.OnPinEndTeleport,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL, self.OnEnterLevel, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN,
        self.OnTeleportPopupOpen, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE,
        self.OnTeleportPopupClose, self)
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
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_MAP_PIN_SHOW_TYPE, self.OnPinActive,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_BEGIN_TELEPORT,
        self.OnPinBeginTeleport, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_END_TELEPORT,
        self.OnPinEndTeleport, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL, self.OnEnterLevel, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_OPEN,
        self.OnTeleportPopupOpen, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_TELEPORT_POPUP_CLOSE,
        self.OnTeleportPopupClose, self)
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

function XUiBigWorldMap:_PlayAnimation()
    self:PlayAnimation("Enable")
end

function XUiBigWorldMap:_PlayAreaGroupAnimation()
    local areaGroupType = self._Control:GetMapAreaGroupTypeByLevelId(self._LevelId)
    if areaGroupType ~= XMVCA.XBigWorldMap.AreaGroupType.Vertical then
        local animation = self._GroupButtonAnimations[self._CurrentGroupIndex]
        if animation then
            self._CurrentPlayAreaAnimation = animation
            
            if not self._IsDetailShow then
                animation:PlayTimelineAnimation(function(isFinish)
                    if isFinish then
                        self._CurrentPlayAreaAnimation = false
                    end
                end)
            end
        end
    end
end

function XUiBigWorldMap:_RefreshPin()
    local pinDatas = self._Control:GetMapPinDatasByLevelId(self._LevelId, true)
    local index = 1
    local areaIndex = 1

    self._HasAiMemory = false
    self._PinNodeMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            local isDisplaying = pinData:IsDisplaying()

            if pinData:IsAiMemoryGroup() then
                isDisplaying = self._IsShowCharactorPos and isDisplaying

                if not self._HasAiMemory then
                    self._HasAiMemory = self._LevelId == pinData.LevelId
                end
            end

            if isDisplaying and not pinData:IsVirtual() then
                self:_RefreshPinNode(index, pinData)
                index = index + 1
            end
            if isDisplaying and pinData:IsBigMapRadiusPin() then
                self:_RefreshPinArea(areaIndex, pinData)
                areaIndex = areaIndex + 1
            end
        end
        self:_RefreshPinNodeIndex()
    end
    for i = index, table.nums(self._PinNodeList) do
        self._PinNodeList[i]:Close()
    end
    for i = areaIndex, table.nums(self._PinAreaList) do
        self._PinAreaList[i]:Close()
    end
    self.PanelPlayer.gameObject:SetActiveEx(self:_IsInLevelNotDep())
    self.BtnCharacterPosition.gameObject:SetActive(self._HasAiMemory)
    self.PanelCharacterPosition.gameObject:SetActive(self._HasAiMemory and not self._IsDetailShow)
end

--- 刷新单个Pin节点
---@param index number
---@param pinData XBWMapPinData
function XUiBigWorldMap:_RefreshPinNode(index, pinData)
    if not self.MapPinTarget.gameObject.activeInHierarchy then
        return
    end
    local pinNode = self._PinNodeList[index]

    if not pinNode then
        local node = XUiHelper.Instantiate(self.PinNode, self.MapPin)

        pinNode = XUiBigWorldMapPin.New(node, self, self.PinTarget, self.MapPinTarget)
        self._PinNodeList[index] = pinNode
    end

    self._PinNodeMap[pinData.PinId] = pinNode
    pinNode:Open()
    pinNode:Refresh(self._LevelId, pinData, self._Interface)
    pinNode:SetPlayerTagActive(pinData.PinId == self._BindPinId and self:_CheckCurrentLevel())
    self:_RefreshCurrentAreaGroupPinNode(pinNode, self:GetCurrentSelectGroupId(), pinData)
end

function XUiBigWorldMap:_RefreshPinArea(areaIndex, pinData)
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

function XUiBigWorldMap:_RefreshCurrentAreaGroupTitles()
    local groupId = self:GetCurrentSelectGroupId()

    if XTool.IsNumberValid(groupId) then
        for _, title in pairs(self._CurrentTitleList) do
            title:ChangeActive(groupId, self.Gesture.Scale)
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

    self.PanelPlayer.gameObject:SetActiveEx(self:_IsInLevelNotDep())
end

function XUiBigWorldMap:_RefreshPlayerTrack()
    if self._PlayerTrack then
        if XMVCA.XBigWorldGamePlay:GetCurrentLevelId() ~= self._LevelId then
            self._PlayerTrack:Close()
        else
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
end

function XUiBigWorldMap:_RefreshTrackPin()
    self._TrackPinDataMap = self._Control:GetTrackPinDatas(self._LevelId, self._TrackPinDataMap)

    local index = 1
    local trackPinIds = self._AxisConversion:FilterOutScreenPinsPosition(self._TrackPinDataMap, self:GetMapObject(),
        self.TrackPin)

    for k, _ in pairs(self._TrackPinMap) do
        self._TrackPinMap[k] = nil
    end

    if not XTool.IsTableEmpty(trackPinIds) then
        local trackPinNodes = {}

        if self:_CheckCurrentLevel() and self._PlayerTrack and self._PlayerTrack:IsNodeShow() then
            local screenRect = self._AxisConversion:GetScreenUIRect(self:GetMapObject())
            local centerPos = screenRect.center

            local posX, posY, _ = self.PlayerTarget:GetPosition()
            table.insert(trackPinNodes, {
                PinId = 0,
                Node = self._PlayerTrack,
                Priority = math.pow(posX - centerPos.x, 2) + math.pow(posY - centerPos.y, 2),
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

-- 如果在地图上，移动到角色位置
function XUiBigWorldMap:_RefreshPlayerPosition()
    if not self:_CheckCurrentGroup() then return end
    local positionX, positionY, _ = self.PlayerTarget:GetPosition()
    self:AnchorToPosition(positionX, positionY, true, true)
    return true
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
                if pinData then
                    local pinNode = self._PinNodeMap[pinData.PinId]
                    if pinNode then
                        pinNode:AnchorTo(true, true)
                    end
                end
            else
                self:_RefreshPlayerPosition()
            end
        end
    else
        if not self._FirstSelectTarget then
            self._FirstSelectTarget = true
            self:_AnchorTargetPin()
        else
            self:_RefreshPlayerPosition()
        end
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

function XUiBigWorldMap:_RefreshTitle(scale, isIgnoreAnimation)
    if not XTool.IsTableEmpty(self._CurrentTitleList) then
        for _, title in pairs(self._CurrentTitleList) do
            if isIgnoreAnimation then
                title:SetShow(scale)
            else
                title:ChangeScale(scale)
            end
        end
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMap:_RefreshSelectGroup(pinData)
    if pinData then
        local groupId = pinData:GetAreaGroupId()

        for index, areaGroupId in pairs(self._AreaGroupIds) do
            if areaGroupId == groupId then
                self._IsAutoSelect = true
                self.AreaList:SelectIndex(index)
                self._IsAutoSelect = false
                break
            end
        end
    end
end

function XUiBigWorldMap:_RefreshDeatil(levelId, pinData)
    self._IsDetailShow = true
    if XMVCA.XBigWorldUI:IsUiLoad("UiBigWorldMapDetail") then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_DETAIL_CHANGE, levelId, pinData)
    else
        XMVCA.XBigWorldUI:Open("UiBigWorldMapDetail", levelId, pinData)
    end
    self:_RefreshPinRangeSelectable(false)
    self.Gesture.Padding.right = self._RightPadding + 200
    self:_ActiveSlider(false)

    local pinNode = self._PinNodeMap[pinData.PinId]
    if pinNode then
        pinNode.Transform:SetAsLastSibling()
    end
    self:_SetRightPanelActive(false)
    self.AreaList.gameObject:SetActiveEx(false)
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
    self:_SetRightPanelActive(true)

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
    XMVCA.XBigWorldUI:Close("UiBigWorldMapDetail")
    self._IsDetailShow = false
    self:_CancelSelectPin()
    self:_CancelSelectTagPin()
    self:_ActiveSlider(true)
    self:_ActiveTrack(true)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self:_RefreshPinRangeSelectable(true)
    self.Gesture.Padding.right = self._RightPadding
    self:_SetRightPanelActive(true)
    self.AreaList.gameObject:SetActiveEx(not self._IsOnlyOneFloor)

    if self._CurrentPlayAreaAnimation then
        self._CurrentPlayAreaAnimation:PlayTimelineAnimation(function(isFinish)
            if isFinish then
                self._CurrentPlayAreaAnimation = false
            end
        end)
    end
end

function XUiBigWorldMap:_CloseOther()
    XMVCA.XBigWorldUI:RunMain()
end

function XUiBigWorldMap:_SetRightPanelActive(isActive)
    self.PanelOverview.gameObject:SetActiveEx(self._IsOverviewShow and isActive)
    self.PanelCharacterPosition.gameObject:SetActiveEx(self._HasAiMemory and isActive and not self._IsDetailShow)

    if isActive and self._IsOverviewShow then
        self.PanelChange.gameObject:SetActiveEx(true)

        for _, tab in pairs(self._MapTabList) do
            tab:Open()
        end
    else
        for _, tab in pairs(self._MapTabList) do
            tab:Close()
        end

        self.PanelChange.gameObject:SetActiveEx(false)
    end
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

function XUiBigWorldMap:_IsInLevelNotDep()
    return XMVCA.XBigWorldGamePlay:GetCurrentLevelId() == self._LevelId
end

function XUiBigWorldMap:_CheckCurrentLevel()
    return self:_GetCurrentLevelId() == self._LevelId
end

-- 角色是否在地图层上
function XUiBigWorldMap:_CheckCurrentGroup()
    return self._AreaGroupIds[self._CurrentGroupIndex] == self._Control:GetCurrentAreaGroupId()
end

function XUiBigWorldMap:_GetCurrentLevelId()
    local currentLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

    if self._Control:CheckLevelLinkOther(currentLevelId) then
        local mapLinkLevelId = self._Control:GetMapLinkLevelIdByLevelId(currentLevelId)

        if XTool.IsNumberValid(mapLinkLevelId) then
            currentLevelId = mapLinkLevelId
        end
    end

    return currentLevelId
end

function XUiBigWorldMap:_ChangeMap(levelId)
    local currentScale = self.Gesture.Scale
    local scaleRatio = (currentScale - self._MinScale) / (self._MaxScale - self._MinScale) * 100

    self._LevelId = levelId
    self._MaxScale = self._Control:GetMapMaxScaleByLevelId(levelId)
    self._MinScale = self._Control:GetMapMinScaleByLevelId(levelId)
    self._Control:InitMapData(self._WorldId, levelId)
    self._AxisConversion:ChangeAxis(levelId)
    self:_InitGesture(true)
    self:_InitCurrentNpcIcon()
    self:_InitAreaGroup()
    self:_InitTitle(levelId)
    self:_InitAreaList()
    self:_InitScale(scaleRatio)

    self:_RefreshMap()
    self:_RefreshPin()
    self:_RefreshPosition()
    self:_RefreshPlayerTrack()
    self:_RefreshTrackPin()
end

function XUiBigWorldMap:_InitAreaList()
    local groupIds = self._Control:GetMapGroupIdsByLevelId(self._LevelId)
    local areaGroupType = self._Control:GetMapAreaGroupTypeByLevelId(self._LevelId)

    self._AreaGroupIds = {}
    self._GroupButtonAnimations = {}
    if not XTool.IsTableEmpty(groupIds) then
        local playerGroupId = 0
        local currentGroupId = 0
        local currentIndex = 1
        local buttonList = {}

        self._CurrentGroupIndex = 0

        if self:_CheckCurrentLevel() then
            if XTool.IsNumberValid(self._BindPinId) then
                playerGroupId = self._Control:GetPinGroupIdByLevelIdAndPinId(self._LevelId, self._BindPinId)
            else
                playerGroupId = self._Control:GetCurrentAreaGroupId()
            end
        end
        if XTool.IsNumberValid(self._TargetPinId) then
            currentGroupId = self._Control:GetPinGroupIdByLevelIdAndPinId(self._LevelId, self._TargetPinId)
        else
            currentGroupId = playerGroupId
        end

        for index, groupId in pairs(groupIds) do
            local button = self._GroupButtonList[index]

            if not button then
                button = XUiHelper.Instantiate(self.BtnArea, self.AreaList.transform)

                self._GroupButtonList[index] = button
            end

            self._GroupButtonAnimations[index] = button.transform:FindTransform("Enable")
            button.gameObject:SetActiveEx(true)
            button:ShowTag(XTool.IsNumberValid(playerGroupId) and playerGroupId == groupId)
            button:SetNameByGroup(0, self._Control:GetMapAreaGroupNameByGroupId(groupId))

            local componentGroup = button.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))

            if componentGroup then
                componentGroup:SetImageWithGroup(0, self._Control:GetMapAreaGroupIcon(groupId))
            end

            if areaGroupType == XMVCA.XBigWorldMap.AreaGroupType.Vertical then
                button:SetSpriteVisible(true)
                button:ShowReddot(false)
            else
                button:SetSpriteVisible(false)
                button:ShowReddot(true)
            end
            self._AreaGroupIds[index] = groupId
            buttonList[index] = button

            if currentGroupId == groupId then
                currentIndex = index
                self._CurrentGroupId = groupId
            end
        end

        self._GroupTabCount = #buttonList

        for i = self._GroupTabCount + 1, #self._GroupButtonList do
            self._GroupButtonList[i].gameObject:SetActiveEx(false)
        end

        self.BtnArea.gameObject:SetActiveEx(false)
        self.MapLevel.gameObject:SetActiveEx(true)
        self.AreaList.gameObject:SetActiveEx(true)

        self._IsOnlyOneFloor = table.nums(groupIds) == 1
        self.AreaList:Init(buttonList, Handler(self, self.OnAreaListClick))
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

    if not XTool.IsTableEmpty(self._AreaGroupList) then
        for _, imageList in pairs(self._AreaGroupList) do
            if not XTool.IsTableEmpty(imageList) then
                for _, image in pairs(imageList) do
                    image.gameObject:SetActiveEx(false)
                end
            end
        end
    else
        self._AreaGroupList = {}
    end

    if not XTool.IsTableEmpty(groupIds) then
        for i, groupId in pairs(groupIds) do
            local areaIds = self._Control:GetAreaIdsByGroupId(groupId)
            local imageList = self._AreaGroupList[i] or {}

            if not XTool.IsTableEmpty(areaIds) then
                for index, areaId in pairs(areaIds) do
                    local areaImage = imageList[index]

                    if not areaImage then
                        areaImage = XUiHelper.Instantiate(self.ImgArea, self.MapLevel)
                        imageList[index] = areaImage
                    end

                    local rectTransform = areaImage.transform

                    if not XTool.UObjIsNil(rectTransform) then
                        local posX = self._Control:GetAreaPosXByAreaId(areaId)
                        local posZ = self._Control:GetAreaPosZByAreaId(areaId)
                        local pixelRatio = self._Control:GetAreaPixelRatioByAreaId(areaId)

                        local xOffset, yOffset = self._AxisConversion:WorldToMapPosition2D(posX, posZ, pixelRatio)
                        rectTransform:SetAnchoredPosition(xOffset, yOffset)
                    end

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
    if not self:_CheckCurrentLevel() then
        return
    end

    if not XTool.IsNumberValid(self._BindPinId) then
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
    local animationNode = self.ListMapSet.transform:FindTransform("Animation")

    self.TrackPin.gameObject:SetActiveEx(true)
    self.PinNode.gameObject:SetActiveEx(false)
    self.PinArea.gameObject:SetActiveEx(false)
    self.ImgArea.gameObject:SetActiveEx(false)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self.BtnSelectClose.gameObject:SetActiveEx(false)
    self.PanelPointer.gameObject:SetActiveEx(false)
    self.BtnChangeTab.gameObject:SetActiveEx(false)
    self.TxtMapAreaTitle.gameObject:SetActiveEx(false)
    self.TxtMapAreaSubTitle.gameObject:SetActiveEx(false)
    self.MapAreaTitleTarget.gameObject:SetActiveEx(false)
    self.ListMapSet.gameObject:SetActiveEx(self._IsSetShow)
    self.PanelSubAreaTitle.gameObject:SetActiveEx(false)

    if animationNode then
        self._MapSetAnimation = animationNode:FindTransform("Disable")
    end
end

function XUiBigWorldMap:_InitGesture(isWithoutListener)
    if not XTool.UObjIsNil(self.Gesture) then
        self.Gesture.MaxScale = self._MaxScale
        self.Gesture.MinScale = self._MinScale

        if not isWithoutListener then
            self.Gesture:AddScaleValueChangedListener(Handler(self, self.OnGestureScaleValueChanged))
            self.Gesture:AddTranslateValueChangedListener(Handler(self, self.OnGestureTranslateValueChanged))
        end
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
    self:_RefreshTitle(scale, true)
end

function XUiBigWorldMap:_InitTitle(levelId)
    local index = 1
    local subIndex = 1
    local totalIndex = 1
    local titleInfos = self._Control:GetMapTitleInfos(levelId)

    self._CurrentTitleList = {}
    self.MapAreaTitle.gameObject:SetActiveEx(true)
    if not XTool.IsTableEmpty(titleInfos) then
        for _, titleInfo in pairs(titleInfos) do
            local isSub = titleInfo.Info.ShowType == XMVCA.XBigWorldMap.SceneObjectShowType.SubTitle
            local target = self._TitleTargetList[totalIndex]
            ---@type XUiBigWorldMapTitle?
            local title = nil

            if not target then
                target = XUiHelper.Instantiate(self.MapAreaTitleTarget, self.MapAreaTargetTitle)

                self._TitleTargetList[totalIndex] = target
            end
            if isSub then
                title = self._SubTitleList[subIndex]

                if not title then
                    local titleUi = XUiHelper.Instantiate(self.TxtMapAreaSubTitle, self.MapAreaTitle)

                    title = XUiBigWorldMapTitle.New(titleUi, self)
                    self._SubTitleList[subIndex] = title
                end

                self._CurrentTitleList[totalIndex] = title
                subIndex = subIndex + 1
            else
                title = self._TitleList[index]

                if not title then
                    local titleUi = XUiHelper.Instantiate(self.TxtMapAreaTitle, self.MapAreaTitle)

                    title = XUiBigWorldMapTitle.New(titleUi, self)
                    self._TitleList[index] = title
                end

                self._CurrentTitleList[totalIndex] = title
                index = index + 1
            end

            local axisConversion = self:GetAxisConversion()
            local x, y = axisConversion:WorldToMapPosition2D(titleInfo.Position.x, titleInfo.Position.z)
            local minScale = (self._MaxScale - self._MinScale) * titleInfo.Info.MinScale / 100 + self._MinScale
            local maxScale = (self._MaxScale - self._MinScale) * titleInfo.Info.MaxScale / 100 + self._MinScale

            target:SetAnchoredPosition(x, y)
            title:Open()
            title:SetTarget(target)
            title:SetScaleRange(minScale, maxScale)
            title:SetGroup(titleInfo.Info.GroupIdList)
            title:Refresh(titleInfo.Info.Name)
            totalIndex = totalIndex + 1
        end
    end

    for i = totalIndex, table.nums(self._TitleTargetList) do
        self._TitleTargetList[i].gameObject:SetActiveEx(false)
    end
    for i = index, table.nums(self._TitleList) do
        self._TitleList[i]:Close()
    end
    for i = subIndex, table.nums(self._SubTitleList) do
        self._SubTitleList[i]:Close()
    end
end

function XUiBigWorldMap:_InitChangeList()
    local index = 1
    local isShow = false
    local overviewIndex = 1
    local overviewMapConfigs = self._Control:GetUnlockOverviewMapConfigs()

    self._ChangeIndexMap = {}
    if not XTool.IsTableEmpty(overviewMapConfigs) then
        local totalConditionId = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("BigWorldMapOverviewOpenCondition")

        isShow = table.nums(overviewMapConfigs) >= 1

        if totalConditionId ~= 0 and not XMVCA.XBigWorldService:CheckCondition(totalConditionId) then
            isShow = false
        end

        self._IsOverviewShow = isShow
        if isShow then
            local buttons = {}
            local currentIndex = 1

            for overviewId, mapConfigList in pairs(overviewMapConfigs) do
                local mapTab = self._MapTabList[overviewIndex]

                if not mapTab then
                    local tabUi = XUiHelper.Instantiate(self.PanelSubAreaTitle, self.ListChangeTab.transform)

                    mapTab = XUiBigWorldMapTab.New(tabUi, self)
                    self._MapTabList[overviewIndex] = mapTab
                end

                mapTab:Open()
                mapTab:Refresh(overviewId)
                overviewIndex = overviewIndex + 1

                for _, mapConfig in pairs(mapConfigList) do
                    self._ChangeIndexMap[index] = mapConfig.LevelId

                    local levelId = mapConfig.LevelId
                    local tab = self._ChangeTabList[index]

                    if not tab then
                        tab = XUiHelper.Instantiate(self.BtnChangeTab, self.ListChangeTab.transform)

                        self._ChangeTabList[index] = tab
                    end

                    self._ChangeIndexMap[index] = levelId

                    if levelId == self._LevelId then
                        self._CurrentChangeIndex = index
                        currentIndex = index
                    end

                    index = index + 1
                    tab.gameObject:SetActiveEx(true)
                    tab:ShowTag(self:_GetCurrentLevelId() == levelId)
                    tab:SetNameByGroup(0, mapConfig.MapName)

                    local trackPinDataMap = XMVCA.XBigWorldMap:GetCurrentTrackPinsIncludeVirtual(levelId, {})
                    local styleId = 0

                    if not XTool.IsTableEmpty(trackPinDataMap) then
                        for pinId, _ in pairs(trackPinDataMap) do
                            local pinData = XMVCA.XBigWorldMap:GetPinDataByLevelIdAndPinId(levelId, pinId)

                            if pinData and pinData.QuestObjectiveId > 0 then
                                styleId = pinData.StyleId
                                break
                            end
                        end
                    end

                    if XTool.IsNumberValid(styleId) then
                        tab:SetSpriteVisible(true)
                        tab:SetRawImageVisible(false)
                        tab:SetSprite(self._Control:GetPinActiveIconByStyleId(styleId))
                    else
                        tab:SetSpriteVisible(false)
                        tab:SetRawImageVisible(true)
                        tab:SetRawImage(self._Control:GetOverviewIcon(overviewId))
                    end

                    table.insert(buttons, tab)
                end
            end
            self._ChangeTabCount = index - 1
            self.ListChangeTab:Init(buttons, Handler(self, self.OnChangeTabClick))
            self.ListChangeTab:SelectIndex(currentIndex)
        end
    end
    for i = index, #self._ChangeTabList do
        self._ChangeTabList[i].gameObject:SetActiveEx(false)
    end
    for i = overviewIndex, #self._MapTabList do
        self._MapTabList[i]:Close()
    end

    self.PanelOverview.gameObject:SetActiveEx(isShow)
    self.PanelChange.gameObject:SetActiveEx(isShow)
end

-- endregion

return XUiBigWorldMap
