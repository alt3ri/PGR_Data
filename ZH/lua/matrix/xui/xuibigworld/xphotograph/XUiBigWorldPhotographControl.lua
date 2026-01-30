---@class XUiBigWorldPhotographControl : XLuaUi
local XUiBigWorldPhotographControl = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographControl")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldPhotographControlQuestGrid = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographControlQuestGrid")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

local UnlockType = {
    FakeSet = 1,
    Animation = 2,
    Filter = 3,
    FirstPerson = 4,
}
local inputSpeed = 0.02

function XUiBigWorldPhotographControl:OnAwake()
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_UI_OPEN, self.OnNotify, self)
    self:_RegisterButtonClicks()
    self._recordData = {}
end

function XUiBigWorldPhotographControl:OnNotify()
    if self._X3CExit then
        return
    end
    self:X3CCameraPhotographExit()
    self:Close()
end

function XUiBigWorldPhotographControl:OnStart(data)
    self.BtnPhotograph:ShowTag(false)
    local defaultConfigId = 0
    self._data = data
    if self._data then
        self._RecordId = self._data.ObjectiveId
        self._EnvId = self._data.ParamId
        self._detectionSceneObjectPlaceIdList = self._data.DetectionSceneObjectPlaceIdList
        self._detectionNpcPlaceIdList = self._data.DetectionNpcPlaceIdList
        self._PlayerNpcAnimationDict = self._data.PlayerNpcAnimationDict
        self._LevelNpcAnimationDict = self._data.LevelNpcAnimationDict
        self._PhotoFilterId = self._data.PhotoFilterId or 0
        self._IgnoreShelterSceneObjectList = self._data.IgnoreShelterSceneObjectList
    else
        self._RecordId = nil
        self._EnvId = nil
        self._detectionSceneObjectPlaceIdList = nil
        self._detectionNpcPlaceIdList = nil
        self._PlayerNpcAnimationDict = nil
        self._LevelNpcAnimationDict = nil
        self._IgnoreShelterSceneObjectList = nil
        self._PhotoFilterId = 0
    end

    self._IsForceOpen = self._EnvId ~= nil
    self._TaskUIs = {}
    self.Pages = {
        self.ListSet,
        self.PanelAction,
        self.ListFilter,
    }

    self._LastNpcActiveStatus = XMVCA.XBigWorldGamePlay:GetCurNpcActive()
    self.PanelPhotographTask.gameObject:SetActive(self._IsForceOpen)
    self.ListAction.gameObject:SetActive(true)

    if self._IsForceOpen then
        self._ParamConfig = self._Control:GetParamConfigById(self._EnvId)
        XTool.UpdateDynamicItem(self._TaskUIs, nil, self.GridObjective, XUiBigWorldPhotographControlQuestGrid, self)
    end
    if not self._ParamConfig then
        self._ParamConfig = self._Control:GetParamConfigById(defaultConfigId)
    end
    self._FailTimes = self._ParamConfig.FailTimes or 0
    self._DisableCameraOperation = self._ParamConfig.DisableCameraOperation

    local widthDetectionRatio = self._ParamConfig.WidthDetectionRatio
    local heightDetectionRatio = self._ParamConfig.HeightDetectionRatio
    self.ImgCameraLine.transform.sizeDelta = CS.UnityEngine.Vector2(CS.XUiManager.RealScreenWidth * widthDetectionRatio, CS.XUiManager.RealScreenHeight * heightDetectionRatio)

    self.BtnQuit.gameObject:SetActive(not self._ParamConfig.HideClose)
    self.BtnMenu.gameObject:SetActive(not self._ParamConfig.HideMenu)
    self.BtnAlbum.gameObject:SetActive(not self._ParamConfig.HideAlbum)
    self.SliderScale.gameObject:SetActive(not self._DisableCameraOperation)
    self.BtnMinus.gameObject:SetActive(not self._DisableCameraOperation)
    self.BtnAdd.gameObject:SetActive(not self._DisableCameraOperation)
    self.BtnRestore.gameObject:SetActive(not self._ParamConfig.HideReset)
    self._HideSwitchPersonButton = not self._ParamConfig.HidePersonSwitch

    self.ImgBg.gameObject:SetActive(false)
    self._isShowMenu = self.ImgBg.gameObject.activeSelf

    XMVCA.XBigWorldAlbum:InitPhotoDatas()

    self:InitJoystick()
    self:InitBaseSettings()
    self:InitFightConfig(self._detectionNpcPlaceIdList, self._detectionSceneObjectPlaceIdList)
    self:InitSetting()
    self:ShowPersonButton()
end

function XUiBigWorldPhotographControl:SwitchPage(index)
    local lastPage = self.Pages[self.PageIndex]
    if lastPage then
        self:ClosePageInfo()
        lastPage.gameObject:SetActive(false)
    end
    self.PageIndex = index
    self.Pages[self.PageIndex].gameObject:SetActive(true)
    self:OpenPageInfo()
end

function XUiBigWorldPhotographControl:OnAnimSetClick(index)
    local lastIndex = self._AnimationIndex
    self._AnimationIndex = index
    local curCfg = self._CharacterConfigs[self._AnimationIndex]
    local grid = self.DynamicTableAnimation:GetGridByIndex(self._AnimationIndex)
    if not grid then return end

    grid:ResetData(curCfg, self._AnimationIndex)
    if lastIndex ~= index then
        local lastGrid = self.DynamicTableAnimation:GetGridByIndex(lastIndex)
        lastGrid:ResetData(self._CharacterConfigs[lastIndex], lastIndex)
    end
    -- 触发效果
    XMVCA.XBigWorldAlbum:X3CPlayAnimation(curCfg.AnimationName)
    self._recordData["animId"] = curCfg.Id
end

function XUiBigWorldPhotographControl:GetAnimationSelectIndex()
    return self._AnimationIndex
end

function XUiBigWorldPhotographControl:OnFilterSetClick(index)
    local lastIndex = self._FilterIndex
    self._FilterIndex = index
    local grid = self.DynamicTableFilter:GetGridByIndex(self._FilterIndex)
    local curCfg = self._FilterConfigs[self._FilterIndex]
    grid:ResetData(curCfg, self._FilterIndex)
    if lastIndex ~= index then
        local lastGrid = self.DynamicTableFilter:GetGridByIndex(lastIndex)
        lastGrid:ResetData(self._FilterConfigs[lastIndex], lastIndex)
    end
    -- 触发效果
    XMVCA.XBigWorldAlbum:X3CChangeFilter(curCfg.FilterId, curCfg.Id)
    self._recordData["filterId"] = curCfg.FilterId
end

function XUiBigWorldPhotographControl:GetFilterSelectIndex()
    return self._FilterIndex
end

function XUiBigWorldPhotographControl.ConfigSort(a, b)
    if a.Unlock ~= b.Unlock then
        return a.Unlock > b.Unlock
    end
    if a.Priority ~= b.Priority then
        return a.Priority < b.Priority
    end
    return a.Id < b.Id
end

function XUiBigWorldPhotographControl:InitBaseSettings()
    self._FilterIndex = 1

    self._UnlockedFilterIds = {}
    local filterConfigs = self._Control:GetFiltersConfig()
    self._FilterConfigs = {}
    for i = 1, #filterConfigs do
        local cfg = filterConfigs[i]
        local isUnlock = XMVCA.XBigWorldAlbum:IsUnlockFilterId(cfg.Id)
        if cfg.IsPreview or isUnlock then
            table.insert(self._FilterConfigs, {
                Id = cfg.Id,
                Name = cfg.Name,
                Icon = cfg.Icon,
                FilterId = cfg.FilterId,
                Priority = cfg.Priority,
                Unlock = isUnlock and 1 or 0,
            })
        end
        if not self._UnlockedFilterIds[cfg.Id] and cfg.FilterId ~= 0 then
            self._UnlockedFilterIds[cfg.Id] = cfg.FilterId
        end
    end
    table.sort(self._FilterConfigs, XUiBigWorldPhotographControl.ConfigSort)
end

function XUiBigWorldPhotographControl:InitSetting()
    self._AnimationIndex = 1
    local characterConfigs = self._Control:GetCharacterActionsConfig(self._CharId)
    self._CharacterConfigs = {}
    for i = 1, #characterConfigs do
        local cfg = characterConfigs[i]
        local isUnlock = XMVCA.XBigWorldAlbum:IsUnlockCharacterActionId(cfg.Id)
        if cfg.IsPreview or isUnlock then
            table.insert(self._CharacterConfigs, {
                Id = cfg.Id,
                Name = cfg.Name,
                AnimationName = cfg.AnimationName,
                Priority = cfg.Priority,
                Unlock = isUnlock and 1 or 0,
            })
        end
    end
    table.sort(self._CharacterConfigs, XUiBigWorldPhotographControl.ConfigSort)

    self._SettingConfig = {}
    if not self._ParamConfig.HideNpc then
        local configA = {}
        configA.Name = XMVCA.XBigWorldService:GetText("SG_P_HideNpc")
        configA.IsOn = false
        self._recordData["is_hide_npc"] = configA.IsOn and 1 or 0
        configA.Callback = function(isOn)
            self._NpcAciveIsOn = isOn
            configA.IsOn = isOn
            self._recordData["is_hide_npc"] = configA.IsOn and 1 or 0
            XMVCA.XBigWorldGamePlay:SetNpcActiveExcludePlayerNpc(not self._NpcAciveIsOn)
        end
        table.insert(self._SettingConfig, configA)
    end

    self._HideCharTag = false
    local configB
    if not self._ParamConfig.HideChar then
        configB = {}
        configB.Name = XMVCA.XBigWorldService:GetText("SG_P_HideSelf")
        configB.IsOn = false
        self._recordData["is_hide_char"] = configB.IsOn and 1 or 0
        configB.IsThirdPersonOnly = true
        configB.Callback = function(isOn)
            configB.IsOn = isOn
            self._recordData["is_hide_char"] = configB.IsOn and 1 or 0
            XMVCA.XBigWorldGamePlay:SetCurNpcActive(not isOn)
            self._HideCharTag = isOn
            self:ShowPersonButton()
        end
        table.insert(self._SettingConfig, configB)
    end

    local configC = {}
    configC.Name = XMVCA.XBigWorldService:GetText("SG_P_LookAt")
    configC.IsOn = false
    self._recordData["is_look_at"] = configC.IsOn and 1 or 0
    configC.IsThirdPersonOnly = true
    configC.Callback = function(isOn)
        configC.IsOn = isOn
        self._recordData["is_look_at"] = configC.IsOn and 1 or 0
        XMVCA.XBigWorldAlbum:X3CCameraPhotographLookAtCam(isOn)
    end
    table.insert(self._SettingConfig, configC)

    local configD = {}
    configD.Name = XMVCA.XBigWorldService:GetText("SG_P_AutoSave")
    configD.IsOn = self._Control:GetAutoSave()
    configD.Callback = function(isOn)
        configD.IsOn = isOn
        self._Control:SetAutoSave(isOn)
    end
    configD.IsRecommend = true
    table.insert(self._SettingConfig, configD)

    local isUnlock = self._Control:IsShowRedDotContent(UnlockType.FirstPerson)
    if isUnlock then
        local configE = {}
        configE.Name = XMVCA.XBigWorldService:GetText("SG_P_DefaultFirstPersonSet")
        configE.IsOn = self._Control:GetDefaultFirstPerson()
        configE.Callback = function(isOn)
            configE.IsOn = isOn
            self._Control:SetDefaultFirstPerson(isOn)
        end
        table.insert(self._SettingConfig, configE)
    end

    local isUnlock, isShowRedDot = self._Control:IsShowRedDotContent(UnlockType.FakeSet)
    if isUnlock then
        XMVCA.XBigWorldAlbum:SetFakeOn(false, true)
        XMVCA.XBigWorldAlbum:SetFakeValue(0.5, true)

        self._PersonSwitchFake = false
        local configF = {}
        configF.Name = XMVCA.XBigWorldService:GetText("SG_P_FakeSet")
        configF.IsOn = XMVCA.XBigWorldAlbum:IsFakeOn()
        self._recordData["is_fade"] = configF.IsOn and 1 or 0
        configF.Callback = function(isOn, target)
            configF.IsOn = isOn
            self._recordData["is_fade"] = configF.IsOn and 1 or 0
            configF.BaseValue = XMVCA.XBigWorldAlbum:GetFakeValue()
            if target then
                target:ShowSlider(configF.BaseValue, isOn)
            end
            self._Control:ReadUnlock(UnlockType.FakeSet)
            XMVCA.XBigWorldAlbum:SetFakeOn(isOn)
        end
        configF.SilderCallback = function(value)
            configF.BaseValue = value
            XMVCA.XBigWorldAlbum:SetFakeValue(value)
        end
        configF.IsThirdPersonOnly = true
        configF.BaseValue = XMVCA.XBigWorldAlbum:GetFakeValue()
        configF.IsSlider = true
        configF.IsRedDot = isShowRedDot
        table.insert(self._SettingConfig, configF)
    end

    -- 初始化设置
    if configB and self._ThirdPersonMode then
        configB.Callback(self._ParamConfig.HideChar)
    end
    local isLookAt = self._ParamConfig.InitLookAtCamera
    if isLookAt and self._ThirdPersonMode then
        configC.Callback(isLookAt)
    end

    self._SettingConfigShow = {}
    for i = 1, #self._SettingConfig do
        local cfg = self._SettingConfig[i]
        if not cfg.IsThirdPersonOnly then
            table.insert(self._SettingConfigShow, cfg)
        end
    end

    local XUiBigWorldPhotographPopupAlbumGridSet = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographPopupAlbumGridSet")
    self.DynamicTable = XDynamicTableNormal.New(self.ListSet.gameObject)
    self.DynamicTable:SetProxy(XUiBigWorldPhotographPopupAlbumGridSet, self)
    self.DynamicTable:SetDelegate(self)

    local XUiBigWorldPhotographPopupAlbumGridAnimation = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographPopupAlbumGridAnimation")
    self.DynamicTableAnimation = XDynamicTableNormal.New(self.ListAction.gameObject)
    self.DynamicTableAnimation:SetProxy(XUiBigWorldPhotographPopupAlbumGridAnimation, self)
    self.DynamicTableAnimation:SetDelegate(self)

    local XUiBigWorldPhotographPopupAlbumGridFilter = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographPopupAlbumGridFilter")
    self.DynamicTableFilter = XDynamicTableNormal.New(self.ListFilter.gameObject)
    self.DynamicTableFilter:SetProxy(XUiBigWorldPhotographPopupAlbumGridFilter, self)
    self.DynamicTableFilter:SetDelegate(self)

    self.BtnTabList = {
        self.BtnTab,
        self.BtnTab1,
        self.BtnTab2,
    }
    for i = 1, #self.BtnTabList do
        local isUnlock, isShowRedDot = true, false
        if i ~= 1 then
            isUnlock, isShowRedDot = self._Control:IsShowRedDotContent(i)
        end
        self.BtnTabList[i]:SetButtonState(isUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        self.BtnTabList[i]:ShowReddot(isUnlock and isShowRedDot)
    end

    self.ListTab:InitBtns(self.BtnTabList, function(index)
        if index ~= 1 then
            local isUnlock = self._Control:IsShowRedDotContent(index)
            if not isUnlock then return end

            self._Control:ReadUnlock(index)
            self.BtnTabList[index]:ShowReddot(false)
        end
        if self.PageIndex ~= index then
            self:PlayAnimation("SidePanelMenuSwitch")
        end
        self:SwitchPage(index)
    end)
    self.ListTab:SelectIndex(1)
end

function XUiBigWorldPhotographControl:InitJoystick()
    if self._ParamConfig.HideCameraMove then
        self.OnPcPressCb = function () end
        self.PanelJoystick.gameObject:SetActive(false)
    else
        local PC_OPERATION_KEY = {
            LT = 312,
            RT = 311,
            LB = 282,
            RB = 301,
        }
        self.KeyPressMap = {
            [PC_OPERATION_KEY.LT] = function()
                if not self.BtnMinus.gameObject.activeInHierarchy then return end
                self.SliderScale.value = self.SliderScale.value - inputSpeed
            end,
            [PC_OPERATION_KEY.RT] = function()
                if not self.BtnAdd.gameObject.activeInHierarchy then return end
                self.SliderScale.value = self.SliderScale.value + inputSpeed
            end,
            [PC_OPERATION_KEY.LB] = function()
                if not self.BtnL.gameObject.activeInHierarchy then return end
                self.SliderRotate.value = self.SliderRotate.value - inputSpeed
            end,
            [PC_OPERATION_KEY.RB] = function()
                if not self.BtnR.gameObject.activeInHierarchy then return end
                self.SliderRotate.value = self.SliderRotate.value + inputSpeed
            end,
        }
        self.OnPcPressCb = handler(self, self.OnPcPress)
        local XUiCommonJoystick = require("XUi/XUiCommon/XUiCommonJoystick")
        self.UiJoystick = XUiCommonJoystick.New(self.PanelJoystick, self, self.PanelJoystick.gameObject, nil, nil, nil, true)
        self.UiJoystick:SetUpdateMoveDirectionFunc(handler(self, self.UpdateMoveDirectionFunc))
    end
end

function XUiBigWorldPhotographControl:InitFightConfig(detectionNpcPlaceIdList, detectionSceneObjectPlaceIdList)
    self._ThirdPersonMode = not self._Control:GetDefaultFirstPerson()
    if self._ParamConfig.ThirdPersonMode ~= 0 then
        self._ThirdPersonMode = self._ParamConfig.ThirdPersonMode == 2
    end
    self._recordData["is_first_person"] = self._ThirdPersonMode and 0 or 1

    local widthDetectionRatio = self._ParamConfig.WidthDetectionRatio
    local heightDetectionRatio = self._ParamConfig.HeightDetectionRatio
    self._moveVec2 = CS.UnityEngine.Vector2.zero
    local PhotographArgs = {
        WidthDetectionRatio = widthDetectionRatio,
        HeightDetectionRatio = heightDetectionRatio,
        InitCharRotate = self._ParamConfig.InitCharRotate,
        UseInitCameraZoom = self._ParamConfig.UseInitCameraZoom,
        InitCameraZoom = self._ParamConfig.InitCameraZoom,
        MinDistance = self._ParamConfig.MinDistance,
        MaxDistance = self._ParamConfig.MaxDistance,
        UseInitCameraMove = self._ParamConfig.UseInitCameraMove,
        InitCameraMoveX = self._ParamConfig.InitCameraMoveX,
        InitCameraMoveY = self._ParamConfig.InitCameraMoveY,
        ResetCameraHeight = self._ParamConfig.ResetCameraHeight,
        UseInitCameraY = self._ParamConfig.UseInitCameraY,
        InitCameraY = self._ParamConfig.InitCameraY,
        MinFov = self._ParamConfig.MinFov,
        MaxFov = self._ParamConfig.MaxFov,
        MoveSpeed = self._ParamConfig.MoveSpeed,
        ThirdPersonMode = self._ThirdPersonMode,
        MinBlurSize = self._ParamConfig.MinBlurSize,
        MaxBlurSize = self._ParamConfig.MaxBlurSize,
        DofId = self._ParamConfig.DofId,
        IgnoreShelterSceneObjectList = self._IgnoreShelterSceneObjectList
        -- PlayerNpcAnimationDict = self._PlayerNpcAnimationDict,
        -- LevelNpcAnimationDict = self._LevelNpcAnimationDict,
        -- PhotoFilterId = self._PhotoFilterId,
    }

    local t = XMVCA.XBigWorldAlbum:X3CCameraPhotographEnter(PhotographArgs, detectionNpcPlaceIdList, detectionSceneObjectPlaceIdList,
            self._PlayerNpcAnimationDict, self._LevelNpcAnimationDict,
            self._PhotoFilterId, self._UnlockedFilterIds)
    self.MoveSpeedScale = self._Control:GetCameraMoveSpeed()
    self._scaleValue = t.CurScaleRange or 0.5
    self._defaultRotateValue = self._ParamConfig.InitCharRotate
    self._ActorLuaRefDic = t.ActorLuaRefDic
    self._CharPos = t.CurCharacterPos or CS.UnityEngine.Vector3.zero
    self._CharId = t.CharacterId or 2011001

    if self._ActorLuaRefDic then
        self._TargetShowDatas = {}
        for uid, ref in pairs(self._ActorLuaRefDic) do
            table.insert(self._TargetShowDatas, {
                Uid = uid,
                Ref = ref,
            })
        end
        -- 需要更新的对象id列表
        self.PanelPhotographCameraLine.gameObject:SetActive(#self._TargetShowDatas > 0)
    end

    self:SetScaleValue(self._scaleValue, true)
    self.SliderRotate:SetValueWithoutNotify(self._defaultRotateValue)
end

function XUiBigWorldPhotographControl:_AddUpdateTimerLoop()
    if self._TimerId then return end
    self._TimerId = XScheduleManager.ScheduleForever(function() self:_UpdateFollowUi() end, 30)
end

function XUiBigWorldPhotographControl:_RemoveUpdateTimerLoop()
    if not self._TimerId then return end
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = nil
end

function XUiBigWorldPhotographControl:_AddTickTimerLoop()
    if self._TickTimer then return end
    self._TickTimer = XScheduleManager.ScheduleForever(handler(self, self._UpdateHandler), 10)
end

function XUiBigWorldPhotographControl:_RemoveTickTimerLoop()
    if XTool.IsNumberValid(self._TickTimer) then
        XScheduleManager.UnSchedule(self._TickTimer)
        self._TickTimer = nil
    end
end

function XUiBigWorldPhotographControl:UpdateMoveDirectionFunc(vec2)
    self._moveVec2 = vec2 * self.MoveSpeedScale
    self._IsUpdateMoveDirectionFunc = true
end

function XUiBigWorldPhotographControl:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.PageIndex == 1 then
            if self._ThirdPersonMode then
                grid:ResetData(self._SettingConfig[index], index)
            else
                grid:ResetData(self._SettingConfigShow[index], index)
            end
        elseif self.PageIndex == 2 then
            grid:ResetData(self._CharacterConfigs[index], index)
        else
            grid:ResetData(self._FilterConfigs[index], index)
        end
    end
end

function XUiBigWorldPhotographControl:OnPcPress(inputDeviceType, operationKey, operationType)
    if operationType ~= CS.XInputManager.XOperationType.System or XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local func = self.KeyPressMap[operationKey]
    if func then func() end
end

function XUiBigWorldPhotographControl:OnEnable()
    CS.XInputManager.RegisterOnPress(CS.XInputManager.XOperationType.System, self.OnPcPressCb)
    XMVCA.XBigWorldAlbum:SetNotifyCurScaleRangeCallback(function(value)
        self:SetScaleValue(value, true)
    end)
    XMVCA.XBigWorldAlbum:SetNotifyActorChangeCallback(function(...)
        self:UpdateTargetDetection(...)
    end)
    self.BtnAlbum:ShowReddot(self._Control:IsPhotoFull())
    self:_AddTickTimerLoop()
    self:_AddUpdateTimerLoop()
    self._IsTakePhotograph = false
    if self._DisableCameraOperation then
        XFightUtil.SetCameraOpEnabled(false)
    end
end

function XUiBigWorldPhotographControl:_UpdateHandler()
    if not self._moveVec2 then return end
    if not self._IsUpdateMoveDirectionFunc and self._moveVec2 == CS.UnityEngine.Vector2.zero then return end
    XMVCA.XBigWorldAlbum:X3CCameraPhotographSetOffset(self._moveVec2.x, self._moveVec2.y)
    self._IsUpdateMoveDirectionFunc = false
end

function XUiBigWorldPhotographControl:OnDisable()
    if self._DisableCameraOperation then
        XFightUtil.SetCameraOpEnabled(true)
    end
    CS.XInputManager.UnregisterOnPress(CS.XInputManager.XOperationType.System, self.OnPcPressCb)
    XMVCA.XBigWorldAlbum:SetNotifyCurScaleRangeCallback()
    XMVCA.XBigWorldAlbum:SetNotifyActorChangeCallback()
    self:_RemoveTickTimerLoop()
    self:_RemoveUpdateTimerLoop()
    -- self.Disable.gameObject:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
end

function XUiBigWorldPhotographControl:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_UI_OPEN, self.OnNotify, self)
    self:RemoveAnimTimer()
    if not XLoginManager.IsLogin() then return end
    XMVCA.XBigWorldAlbum:X3CCameraPhotographLookAtCam(false)
    self:X3CCameraPhotographExit()
    if self._NpcAciveIsOn then
        XMVCA.XBigWorldGamePlay:SetNpcActiveExcludePlayerNpc(self._NpcAciveIsOn)
    end
    XMVCA.XBigWorldGamePlay:SetCurNpcActive(self._LastNpcActiveStatus)
    -- XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
end

function XUiBigWorldPhotographControl:OpenPageInfo()
    if self.PageIndex == 1 then
        if self._ThirdPersonMode then
            self.DynamicTable:SetDataSource(self._SettingConfig)
        else
            self.DynamicTable:SetDataSource(self._SettingConfigShow)
        end
        self.DynamicTable:ReloadDataSync()
    elseif self.PageIndex == 2 then
        local isShowList = not self._HideCharTag and self._ThirdPersonMode
        self.ListAction.gameObject:SetActive(isShowList)
        self.PanelActionDisable.gameObject:SetActive(not isShowList)
        if isShowList then
            self.DynamicTableAnimation:SetDataSource(self._CharacterConfigs)
            self.DynamicTableAnimation:ReloadDataSync()
        else
            self.DynamicTableAnimation:SetDataSource({})
            self.DynamicTableAnimation:ReloadDataSync()
        end
    elseif self.PageIndex == 3 then
        self.DynamicTableFilter:SetDataSource(self._FilterConfigs)
        self.DynamicTableFilter:ReloadDataSync()
    end
end

function XUiBigWorldPhotographControl:ClosePageInfo()
    if self.PageIndex == 1 then
        self.DynamicTable:SetDataSource({})
        self.DynamicTable:ReloadDataSync()
    elseif self.PageIndex == 2 then
        self.DynamicTableAnimation:SetDataSource({})
        self.DynamicTableAnimation:ReloadDataSync()
    elseif self.PageIndex == 3 then
        self.DynamicTableFilter:SetDataSource({})
        self.DynamicTableFilter:ReloadDataSync()
    end
end

function XUiBigWorldPhotographControl:OnBtnMenuClick()
    self._isShowMenu = not self._isShowMenu
    if self._isShowMenu and not self.ImgBg.gameObject.activeSelf then
        self.ImgBg.gameObject:SetActive(true)
    end

    if self._isShowMenu then
        self:OpenPageInfo()
        if self.SidePanelEnable then
            self.SidePanelEnable.gameObject:PlayTimelineAnimation(function()
                self.ImgBg.gameObject:SetActive(self._isShowMenu)
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        else
            self.ImgBg.gameObject:SetActive(self._isShowMenu)
        end
        self:PlayAnimation("SidePanelMenuSwitch")
    else
        self:ClosePageInfo()
        if self.SidePanelEnable then
            self.SidePanelDisable.gameObject:PlayTimelineAnimation(function()
                self.ImgBg.gameObject:SetActive(self._isShowMenu)
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        else
            self.ImgBg.gameObject:SetActive(self._isShowMenu)
        end
    end
    self:SwitchControlTips(self.ImgBg.name, self._isShowMenu)
end

function XUiBigWorldPhotographControl:OnBtnAlbumClick()
    XMVCA.XBigWorldUI:Open("UiBigWorldPhotographPopupAlbum")
end

function XUiBigWorldPhotographControl:OnBtnPhotographClick()
    self._IsTakePhotograph = true
    local needCloseControl = false
    if self._IsForceOpen then
        self._FailTimes = self._FailTimes - 1
        needCloseControl = self._FailTimes < 1
        if needCloseControl then
            self._ActorLuaRefDic = nil
        end
    end
    self._Control:SetRecordData(self._recordData)
    self._Control:CaptureTexture(false, needCloseControl)

    local dict = {}
    dict.auto_upload_set = self._Control:GetAutoSave() and 1 or 0
    dict.role_id = XPlayer.Id
    dict.open_type = self._IsForceOpen and 1 or 2
    dict.pos = {x = self._CharPos.x, y = self._CharPos.y, z = self._CharPos.z,}
    dict.auto_close = needCloseControl and 1 or 0
    dict.finish_id = {}
    if self._RecordId then
        dict.finish_id[tostring(self._RecordId)] = self._HasDetectedAllEnvTarget and 1 or 0
    else
        if self._DetectedQuestObjectiveDic then
            for id, isFinish in pairs(self._DetectedQuestObjectiveDic) do
                dict.finish_id[tostring(id)] = isFinish and 1 or 0
            end
        end
    end
    -- dict.auto_upload = 
    CS.XRecord.Record(dict, "1100001", "BigWorldTakePhotoRecord")
end

function XUiBigWorldPhotographControl:OnBtnHideClick()
    local isShow = not self.HideNode.gameObject.activeSelf

    if isShow then
        self.HideNode.gameObject:SetActive(isShow)
        if self.ShowHide then
            self.ShowHide.gameObject:SetActive(not isShow)
        end
        self:PlayAnimation("Show")
        -- self.Enable.gameObject:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
    else
        self:PlayAnimation("Hide", function()
            self.HideNode.gameObject:SetActive(isShow)
            if self.ShowHide then
                self.ShowHide.gameObject:SetActive(not isShow)
            end
        end)
        -- self.Disable.gameObject:PlayTimelineAnimation(function()
        --     self.HideNode.gameObject:SetActive(isShow)
        --     if self.ShowHide then
        --         self.ShowHide.gameObject:SetActive(not isShow)
        --     end
        -- end, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
    end
end

function XUiBigWorldPhotographControl:SetScaleValue(value, isWithoutNotify)
    if isWithoutNotify then
        self.SliderScale:SetValueWithoutNotify(1 - value)
    else
        self.SliderScale.value = 1 - value
    end
end

function XUiBigWorldPhotographControl:OnBtnRestoreClick()
    self:SetScaleValue(self._scaleValue)
    self.SliderRotate.value = self._defaultRotateValue
    XMVCA.XBigWorldAlbum:X3CCameraPhotographReset()
end

function XUiBigWorldPhotographControl:X3CCameraPhotographExit()
    if not self._X3CExit then
        XMVCA.XBigWorldAlbum:X3CCameraPhotographExit()
        self._X3CExit = true
    end
end

function XUiBigWorldPhotographControl:OnBtnQuitClick()
    if self._isQuit or self._X3CExit then return end
    self._isQuit = true
    self:PlayAnimation("Disable")
    self:RemoveAnimTimer()
    XScheduleManager.ScheduleOnce(function()
        self:X3CCameraPhotographExit()
    end, 200)
    self._AnimTimerId = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, 330)
end

function XUiBigWorldPhotographControl:ShowPersonButton(isInit)
    local isUnlock, isShowRedDot = self._Control:IsShowRedDotContent(UnlockType.FirstPerson)
    self.BtnFirstPerson.gameObject:SetActive(not self._ThirdPersonMode and isUnlock and self._HideSwitchPersonButton)
    self.BtnThirdPerson.gameObject:SetActive(self._ThirdPersonMode and isUnlock and self._HideSwitchPersonButton)
    self.BtnFirstPerson:ShowReddot(isShowRedDot)
    self.BtnThirdPerson:ShowReddot(isShowRedDot)

    local isShowCharCtrl = not self._ParamConfig.HideCharRotate and self._ThirdPersonMode and not self._HideCharTag
    self.SliderRotate.gameObject:SetActive(isShowCharCtrl)
    self.BtnL.gameObject:SetActive(isShowCharCtrl)
    self.BtnR.gameObject:SetActive(isShowCharCtrl)
    self:OpenPageInfo()
    if isInit then
        self:OnAnimSetClick(1)
    end
end

function XUiBigWorldPhotographControl:RemoveAnimTimer()
    if not self._AnimTimerId then return end
    XScheduleManager.UnSchedule(self._AnimTimerId)
    self._AnimTimerId = nil
end

function XUiBigWorldPhotographControl:OnBtnFirstPersonClick()
    self:PlayAnimation("PersonSwitch")
    self:RemoveAnimTimer()
    self._AnimTimerId = XScheduleManager.ScheduleOnce(function()
        if self._PersonSwitchFake then
            local config = self._SettingConfig[#self._SettingConfig]
            config.Callback(true)
            self._PersonSwitchFake = false
        end
        self._ThirdPersonMode = true
        self._recordData["is_first_person"] = self._ThirdPersonMode and 0 or 1
        self._Control:ReadUnlock(UnlockType.FirstPerson)
        local t = XMVCA.XBigWorldAlbum:X3CChangePerspective(self._ThirdPersonMode)
        if t and t.InitZoom then
            self:SetScaleValue(t.InitZoom, true)
        end
        if self._HideCharTag then
            XMVCA.XBigWorldGamePlay:SetCurNpcActive(not self._HideCharTag)
        end
        self.SliderRotate.value = self._defaultRotateValue
        self:ShowPersonButton(true)
        self:RemoveAnimTimer()
    end, 200)
end

function XUiBigWorldPhotographControl:OnBtnThirdPersonClick()
    self:PlayAnimation("PersonSwitch")
    self:RemoveAnimTimer()
    self._AnimTimerId = XScheduleManager.ScheduleOnce(function()
        local config = self._SettingConfig[#self._SettingConfig]
        if config.IsOn then
            self._PersonSwitchFake = true
            config.Callback(false)
        end

        self._ThirdPersonMode = false
        self._recordData["is_first_person"] = self._ThirdPersonMode and 0 or 1
        self._Control:ReadUnlock(UnlockType.FirstPerson)
        self:ShowPersonButton()
        local t = XMVCA.XBigWorldAlbum:X3CChangePerspective(self._ThirdPersonMode)
        if t and t.InitZoom then
            self:SetScaleValue(t.InitZoom, true)
        end
        self:RemoveAnimTimer()
    end, 200)
end

function XUiBigWorldPhotographControl:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose.CallBack = Handler(self, self.OnBtnMenuClick)
    self.BtnMenu.CallBack = Handler(self, self.OnBtnMenuClick)
    self.BtnAlbum.CallBack = Handler(self, self.OnBtnAlbumClick)
    self.BtnPhotograph.CallBack = Handler(self, self.OnBtnPhotographClick)
    self.BtnHide.CallBack = Handler(self, self.OnBtnHideClick)
    if self.ShowHide then
        self.ShowHide.CallBack = Handler(self, self.OnBtnHideClick)
    end
    self.BtnRestore.CallBack = Handler(self, self.OnBtnRestoreClick)
    self.BtnQuit.CallBack = Handler(self, self.OnBtnQuitClick)
    self.BtnFirstPerson.CallBack = Handler(self, self.OnBtnFirstPersonClick)
    self.BtnThirdPerson.CallBack = Handler(self, self.OnBtnThirdPersonClick)

    self.SliderScale.onValueChanged:AddListener(function(value)
        XMVCA.XBigWorldAlbum:X3CCameraPhotographSetScale(1 - value)
    end)
    self.SliderRotate.onValueChanged:AddListener(function(value)
        XMVCA.XBigWorldAlbum:X3CCameraPhotographSetCharRot(value)
    end)

    XUiButtonLongClick.New(self.BtnMinus, 10, self, nil, function()
        if not self.BtnMinus.gameObject.activeInHierarchy then return end
        self.SliderScale.value = self.SliderScale.value - inputSpeed
    end, nil, true)
    XUiButtonLongClick.New(self.BtnAdd, 10, self, nil, function()
        if not self.BtnAdd.gameObject.activeInHierarchy then return end
        self.SliderScale.value = self.SliderScale.value + inputSpeed
    end, nil, true)
    XUiButtonLongClick.New(self.BtnL, 10, self, nil, function()
        if not self.BtnL.gameObject.activeInHierarchy then return end
        self.SliderRotate.value = self.SliderRotate.value - inputSpeed
    end, nil, true)
    XUiButtonLongClick.New(self.BtnR, 10, self, nil, function()
        if not self.BtnR.gameObject.activeInHierarchy then return end
        self.SliderRotate.value = self.SliderRotate.value + inputSpeed
    end, nil, true)
end

function XUiBigWorldPhotographControl:IsTargetIdFinish(targetId)
    if not self._DetectedActorList then return false end
    local com = self._DetectedActorList[targetId]
    if com then return com.gameObject.activeSelf end
    return false
end

function XUiBigWorldPhotographControl:UpdateTargetDetection(detectedActorIdsDic, hasDetectedAllQuestObjTarget, detectedQuestObjectiveDic)
    if not self._DetectedActorList then self._DetectedActorList = {} end

    for uid, ui in pairs(self._DetectedActorList) do
        if not detectedActorIdsDic[uid] then
            local baseGo = ui.gameObject
            -- if baseGo.activeSelf then
            --     baseGo:SetActive(true)
            --     local disableImgAnimTr = baseGo.transform:Find("Animation/ImgViewLineDisable").transform
            --     disableImgAnimTr:PlayTimelineAnimation(function()
            --         baseGo:SetActive(false)
            --     end, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
            -- else
            --     baseGo:SetActive(false)
            -- end
            baseGo:SetActive(false)
        end
    end

    local halfVec2 = CS.UnityEngine.Vector2(0.5, 0.5)
    for uid, detectedType in pairs(detectedActorIdsDic) do
        local actorRef = self._ActorLuaRefDic[uid]
        if not self._DetectedActorList[uid] then
            local go = CS.UnityEngine.Object.Instantiate(self.ImgViewLine.gameObject, self.ImgViewLine.transform.parent)
            local followCom = XUiHelper.TryAddComponent(go, typeof(CS.SetUiFollowTarget))
            local pos = actorRef:GetPhotographCameraDetectionPosition()
            followCom:StartFollowByPos(XMVCA.XBigWorldGamePlay:GetCamera(), pos, CS.UnityEngine.Vector3.zero, halfVec2)
            self._DetectedActorList[uid] = followCom
        end

        if detectedType > 0 then
            local go = self._DetectedActorList[uid].gameObject
            local viewTxt = go.transform:Find("ViewTxt").gameObject:GetComponent(typeof(CS.UnityEngine.UI.Text))
            if detectedType == 1 then
                viewTxt.text = actorRef:GetName()
            elseif detectedType == 2 then
                viewTxt.text = XMVCA.XBigWorldService:GetText("SG_P_QuestionTarget")
            end
        end

        local baseGo = self._DetectedActorList[uid].gameObject
        if detectedType > 0 then
            baseGo:SetActive(true)
            local enableImgAnimGo = baseGo.transform:Find("Animation/ImgViewLineEnable").gameObject
            enableImgAnimGo:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        else
            baseGo:SetActive(false)
        end
    end

    if self._EnvId then
        XTool.UpdateDynamicItem(self._TaskUIs, self._TargetShowDatas, self.GridObjective, XUiBigWorldPhotographControlQuestGrid, self)
    end
    self.BtnPhotograph:ShowTag(hasDetectedAllQuestObjTarget)

    self._HasDetectedAllEnvTarget = hasDetectedAllQuestObjTarget
    self._DetectedQuestObjectiveDic = detectedQuestObjectiveDic
end

function XUiBigWorldPhotographControl:_UpdateFollowUi()
    if self._IsTakePhotograph or not self._ActorLuaRefDic or not self._DetectedActorList then return end
    for uid, actorRef in pairs(self._ActorLuaRefDic) do
        local followCom = self._DetectedActorList[uid]
        if followCom and followCom.gameObject.activeSelf then
            local pos = actorRef:GetPhotographCameraDetectionPosition()
            self._DetectedActorList[uid]:UpdateFollowPos(pos)
        end
    end
end

return XUiBigWorldPhotographControl
