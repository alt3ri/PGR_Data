---@class XUiBigWorldPhotographControl : XLuaUi
local XUiBigWorldPhotographControl = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographControl")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldPhotographControlQuestGrid = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographControlQuestGrid")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

local inputSpeed = 0.02
local PC_OPERATION_KEY = {
    LT = 312,
    RT = 311,
    LB = 282,
    RB = 301,
}

function XUiBigWorldPhotographControl:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPhotographControl:OnStart(paramId, detectionNpcPlaceIdList, detectionSceneObjectPlaceIdList, recordId)
    local defaultConfigId = 0
    self._EnvId = paramId
    self._IsForceOpen = self._EnvId ~= nil
    self._RecordId = recordId
    self._TaskUIs = {}
    self._X3CExit = false

    self._LastNpcActiveStatus = XMVCA.XBigWorldGamePlay:GetCurNpcActive()
    self.PanelPhotographTask.gameObject:SetActive(self._IsForceOpen)

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

    self.ImgBg.gameObject:SetActive(false)
    self._isShowMenu = self.ImgBg.gameObject.activeSelf

    self._SettingConfig = {}
    local hideNpcIndex = false
    self._IsSetNpcActiveExcludePlayerNpc = false
    if not self._ParamConfig.HideNpc then
        hideNpcIndex = #self._SettingConfig + 1
        local configA = {
            Name = XMVCA.XBigWorldService:GetText("SG_P_HideNpc"),
            IsOn = false,
            Callback = function(isOn)
                self._SettingConfig[hideNpcIndex].IsOn = isOn
                self._IsSetNpcActiveExcludePlayerNpc = isOn
                XMVCA.XBigWorldGamePlay:SetNpcActiveExcludePlayerNpc(not isOn)
            end,
        }
        table.insert(self._SettingConfig, configA)
    end

    self._HideCharTag = false
    local hideSelfIndex = false
    if not self._ParamConfig.HideChar then
        hideSelfIndex = #self._SettingConfig + 1
        local configB = {
            Name = XMVCA.XBigWorldService:GetText("SG_P_HideSelf"),
            IsOn = false,
            Callback = function(isOn)
                self._SettingConfig[hideSelfIndex].IsOn = isOn
                XMVCA.XBigWorldGamePlay:SetCurNpcActive(not isOn)
                self._HideCharTag = isOn
                self:ShowPersonButton()
            end,
        }
        table.insert(self._SettingConfig, configB)
    end

    self._IsLookAtCamera = false
    local lookatIndex = #self._SettingConfig + 1
    local configC = {
        Name = XMVCA.XBigWorldService:GetText("SG_P_LookAt"),
        IsOn = false,
        Callback = function(isOn)
            self._SettingConfig[lookatIndex].IsOn = isOn
            self._IsLookAtCamera = isOn
            XMVCA.XBigWorldAlbum:X3CCameraPhotographLookAtCam(isOn)
        end,
    }
    table.insert(self._SettingConfig, configC)
    
    local saveIndex = #self._SettingConfig + 1
    local configD = {
        Name = XMVCA.XBigWorldService:GetText("SG_P_AutoSave"),
        IsOn = self._Control:GetAutoSave(),
        Callback = function(isOn)
            self._SettingConfig[saveIndex].IsOn = isOn
            self._Control:SetAutoSave(isOn)
        end,
    }
    table.insert(self._SettingConfig, configD)

    -- 初始化设置
    if hideSelfIndex then
        self._SettingConfig[hideSelfIndex].Callback(self._ParamConfig.HideChar)
    end
    local isLookAt = self._ParamConfig.InitLookAtCamera
    if isLookAt then
        self._SettingConfig[lookatIndex].Callback(isLookAt)
    end

    if self._ParamConfig.HideCameraMove and self._DisableCameraOperation then
        self.OnPcPressCb = function () end
        self.PanelJoystick.gameObject:SetActive(false)
    else
        self.KeyPressMap = {
            [PC_OPERATION_KEY.LT] = function()
                self.SliderScale.value = self.SliderScale.value - inputSpeed
            end,
            [PC_OPERATION_KEY.RT] = function()
                self.SliderScale.value = self.SliderScale.value + inputSpeed
            end,
            [PC_OPERATION_KEY.LB] = function()
                self.SliderRotate.value = self.SliderRotate.value - inputSpeed
            end,
            [PC_OPERATION_KEY.RB] = function()
                self.SliderRotate.value = self.SliderRotate.value + inputSpeed
            end,
        }
        self.OnPcPressCb = handler(self, self.OnPcPress)
        local XUiCommonJoystick = require("XUi/XUiCommon/XUiCommonJoystick")
        self.UiJoystick = XUiCommonJoystick.New(self.PanelJoystick, self, self.PanelJoystick.gameObject, nil, nil, nil, true)
        self.UiJoystick:SetUpdateMoveDirectionFunc(handler(self, self.UpdateMoveDirectionFunc))
    end

    local XUiBigWorldPhotographPopupAlbumGridSet = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographPopupAlbumGridSet")
    self.DynamicTable = XDynamicTableNormal.New(self.ListSet.gameObject)
    self.DynamicTable:SetProxy(XUiBigWorldPhotographPopupAlbumGridSet, self)
    self.DynamicTable:SetDelegate(self)
    
    XMVCA.XBigWorldAlbum:InitPhotoDatas()
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
    }

    local t = XMVCA.XBigWorldAlbum:X3CCameraPhotographEnter(PhotographArgs, detectionNpcPlaceIdList, detectionSceneObjectPlaceIdList)
    self.MoveSpeedScale = self._Control:GetCameraMoveSpeed()
    self._scaleValue = t.CurScaleRange or 0.5
    self._defaultRotateValue = self._ParamConfig.InitCharRotate
    self._ActorLuaRefDic = t.ActorLuaRefDic
    self._CharPos = t.CurCharacterPos or CS.UnityEngine.Vector3.zero

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

    self:ShowPersonButton()
end

function XUiBigWorldPhotographControl:_AddUpdateTimerLoop()
    if self._TimerId then return end
    self._TimerId = XScheduleManager.ScheduleForever(function() self:_UpdateFollowUi() end, 500)
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
        grid:ResetData(self._SettingConfig[index], index)
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
    if self._IsLookAtCamera then
        XMVCA.XBigWorldAlbum:X3CCameraPhotographLookAtCam(false)
    end
    if not self._X3CExit then
        XMVCA.XBigWorldAlbum:X3CCameraPhotographExit()
        self._X3CExit = true
    end
    if self._IsSetNpcActiveExcludePlayerNpc then
        XMVCA.XBigWorldGamePlay:SetNpcActiveExcludePlayerNpc(true)
    end
    XMVCA.XBigWorldGamePlay:SetCurNpcActive(self._LastNpcActiveStatus)
    XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
end

function XUiBigWorldPhotographControl:OnBtnMenuClick()
    self._isShowMenu = not self._isShowMenu
    if self._isShowMenu and not self.ImgBg.gameObject.activeSelf then
        self.ImgBg.gameObject:SetActive(true)
    end

    if self._isShowMenu then
        self.DynamicTable:SetDataSource(self._SettingConfig)
        self.DynamicTable:ReloadDataSync()
        if self.SidePanelEnable then
            self.SidePanelEnable.gameObject:PlayTimelineAnimation(function()
                self.ImgBg.gameObject:SetActive(self._isShowMenu)
            end, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        else
            self.ImgBg.gameObject:SetActive(self._isShowMenu)
        end
    else
        self.DynamicTable:SetDataSource({})
        self.DynamicTable:ReloadDataSync()
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
        needCloseControl = self._HasDetectedAllEnvTarget or self._FailTimes < 1
        if needCloseControl then
            self._ActorLuaRefDic = nil
        end
    end
    self._Control:CaptureTexture(false, self._HasDetectedAllEnvTarget, needCloseControl)
    
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
        self.Enable.gameObject:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
    else
        self.Disable.gameObject:PlayTimelineAnimation(function()
            self.HideNode.gameObject:SetActive(isShow)
            if self.ShowHide then
                self.ShowHide.gameObject:SetActive(not isShow)
            end
        end, nil, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
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

function XUiBigWorldPhotographControl:OnBtnQuitClick()
    -- 黑屏
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading(function()
        if not self._X3CExit then
            XMVCA.XBigWorldAlbum:X3CCameraPhotographExit()
            self._X3CExit = true
        end
    end)
        self:Close()
end

function XUiBigWorldPhotographControl:ShowPersonButton()
    local isShowCharCtrl = not self._ParamConfig.HideCharRotate and not self._HideCharTag
    self.SliderRotate.gameObject:SetActive(isShowCharCtrl)
    self.BtnL.gameObject:SetActive(isShowCharCtrl)
    self.BtnR.gameObject:SetActive(isShowCharCtrl)
end

function XUiBigWorldPhotographControl:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnMenuClick))
    self.BtnMenu:AddEventListener(handler(self, self.OnBtnMenuClick))
    self.BtnAlbum:AddEventListener(handler(self, self.OnBtnAlbumClick))
    self.BtnPhotograph:AddEventListener(handler(self, self.OnBtnPhotographClick))
    self.BtnHide:AddEventListener(handler(self, self.OnBtnHideClick))
    if self.ShowHide then
        self.ShowHide:AddEventListener(handler(self, self.OnBtnHideClick))
    end
    self.BtnRestore:AddEventListener(handler(self, self.OnBtnRestoreClick))
    self.BtnQuit:AddEventListener(handler(self, self.OnBtnQuitClick))

    self.SliderScale.onValueChanged:AddListener(function(value)
        XMVCA.XBigWorldAlbum:X3CCameraPhotographSetScale(1 - value)
    end)
    self.SliderRotate.onValueChanged:AddListener(function(value)
        XMVCA.XBigWorldAlbum:X3CCameraPhotographSetCharRot(value)
    end)

    XUiButtonLongClick.New(self.BtnMinus, 10, self, nil, function()
        self.SliderScale.value = self.SliderScale.value - inputSpeed
    end, nil, true)
    XUiButtonLongClick.New(self.BtnAdd, 10, self, nil, function()
        self.SliderScale.value = self.SliderScale.value + inputSpeed
    end, nil, true)
    XUiButtonLongClick.New(self.BtnL, 10, self, nil, function()
        self.SliderRotate.value = self.SliderRotate.value - inputSpeed
    end, nil, true)
    XUiButtonLongClick.New(self.BtnR, 10, self, nil, function()
        self.SliderRotate.value = self.SliderRotate.value + inputSpeed
    end, nil, true)
end

function XUiBigWorldPhotographControl:IsTargetIdFinish(targetId)
    local com = self._DetectedActorList[targetId]
    if com then return com.gameObject.activeSelf end
    return false
end

function XUiBigWorldPhotographControl:UpdateTargetDetection(detectedActorIdsDic, hasDetectedAllQuestObjTarget, detectedQuestObjectiveDic)
    if not self._DetectedActorList then self._DetectedActorList = {} end
    
    for uid, ui in pairs(self._DetectedActorList) do
        if not detectedActorIdsDic[uid] then
            ui.gameObject:SetActive(false)
        end
    end

    for uid, isDetected in pairs(detectedActorIdsDic) do
        if not self._DetectedActorList[uid] then
            local go = CS.UnityEngine.Object.Instantiate(self.ImgViewLine.gameObject, self.ImgViewLine.transform.parent)
            local followCom = XUiHelper.TryAddComponent(go, typeof(CS.SetUiFollowTarget))
            local actorRef = self._ActorLuaRefDic[uid]
            local pos = actorRef:GetPosition()
            pos.y = pos.y + actorRef:GetCameraDetectionHeight()
            followCom:StartFollowByPos(XMVCA.XBigWorldGamePlay:GetCamera(), pos, CS.UnityEngine.Vector3.zero, CS.UnityEngine.Vector2(0.5, 0.5))
            self._DetectedActorList[uid] = followCom
        end
        self._DetectedActorList[uid].gameObject:SetActive(isDetected)
    end

    if self._EnvId then
        XTool.UpdateDynamicItem(self._TaskUIs, self._TargetShowDatas, self.GridObjective, XUiBigWorldPhotographControlQuestGrid, self)
    end
    self.BtnPhotograph:ShowTag(hasDetectedAllQuestObjTarget)

    self._HasDetectedAllEnvTarget = hasDetectedAllQuestObjTarget
    self._DetectedQuestObjectiveDic = detectedQuestObjectiveDic
end

function XUiBigWorldPhotographControl:_UpdateFollowUi()
    if self._IsTakePhotograph or not self._ActorLuaRefDic then return end
    for uid, actorRef in pairs(self._ActorLuaRefDic) do
        local followCom = self._DetectedActorList[uid]
        if followCom and followCom.gameObject.activeSelf then
            local pos = actorRef:GetPosition()
            pos.y = pos.y + actorRef:GetCameraDetectionHeight()
            self._DetectedActorList[uid]:UpdateFollowPos(pos)
        end
    end
end

return XUiBigWorldPhotographControl
