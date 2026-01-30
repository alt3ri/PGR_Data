---@class XBigWorldAlbumAgency : XAgency
---@field private _Model XBigWorldAlbumModel
local XBigWorldAlbumAgency = XClass(XAgency, "XBigWorldAlbumAgency")
function XBigWorldAlbumAgency:OnInit()
    --初始化一些变量
end

function XBigWorldAlbumAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    self:AddRpc("NotifyBigWorldPhotographDataUpdate", handler(self, self.NotifyBigWorldPhotographDataUpdate))
    self:AddRpc("NotifyBigWorldAlbumPhotoDataUpdate", handler(self, self.NotifyBigWorldAlbumPhotoDataUpdate))
    self:AddRpc("NotifyBigWorldAlbumUpdate", handler(self, self.NotifyBigWorldAlbumUpdate))
end

function XBigWorldAlbumAgency:NotifyBigWorldPhotographDataUpdate(data)
    self._Model:UpdateBigWorldPhotographData(data.BigWorldPhotographData)
end

function XBigWorldAlbumAgency:NotifyBigWorldAlbumPhotoDataUpdate(data)
    self._Model:UpdatePhotoData(data.PhotoData)
end

function XBigWorldAlbumAgency:NotifyBigWorldAlbumUpdate(data)
    self._Model:SetPhotoDatas(data.AlbumData.PhotoDatas)
    self._Model:SetTaskPhotoDatas(data.AlbumData.TaskHidePhotoData)
end

function XBigWorldAlbumAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

--region X3C定义
---return CurScaleRange : float
function XBigWorldAlbumAgency:X3CCameraPhotographEnter(photographArgs, detectionNpcPlaceIdList, detectionSceneObjectPlaceIdList, playerNpcAnimationDict, levelNpcAnimationDict, photoFilterId, photoAllFiltersId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_ENTER_MODE, {
        PhotographArgs = photographArgs,
        DetectionNpcPlaceIdList = detectionNpcPlaceIdList,
        DetectionSceneObjectPlaceIdList = detectionSceneObjectPlaceIdList,
        PlayerNpcAnimationDict = playerNpcAnimationDict,
        LevelNpcAnimationDict = levelNpcAnimationDict,
        PhotoFilterId = photoFilterId,
        PhotoAllFiltersId = photoAllFiltersId,
    })
end

function XBigWorldAlbumAgency:X3CChangeFilter(filterId, photoFilterId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_FILTER_CHANGED, {
        FilterId = filterId,
        PhotoFilterId = photoFilterId,
    })
end

-- 改变视角
function XBigWorldAlbumAgency:X3CChangePerspective(isThirdPerson)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_CHANGE_PERSPECTIVE, {
        IsThirdPerson = isThirdPerson or false,
    })
end

function XBigWorldAlbumAgency:X3CPlayAnimation(animationName)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_PLAY_ANIMATION, {
        AnimationName = animationName
    })
end

function XBigWorldAlbumAgency:X3CCameraPhotographExit()
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_EXIT_MODE)
end

function XBigWorldAlbumAgency:X3CCameraPhotographSetOffset(X, Y)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_SET_OFFSET, {
        X = X,
        Y = Y,
    })
end

function XBigWorldAlbumAgency:X3CCameraPhotographSetScale(Scale)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_SET_SCALE, {
        Scale = Scale,
    })
end

function XBigWorldAlbumAgency:X3CCameraPhotographSetCharRot(RotationValue)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_SET_CHARACTER_ROTATION, {
        RotationValue = RotationValue,
    })
end

function XBigWorldAlbumAgency:X3CCameraPhotographLookAtCam(IsLookAtCamera)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_LOOK_AT_CAMERA, {
        IsLookAtCamera = IsLookAtCamera,
    })
end

function XBigWorldAlbumAgency:X3CCameraPhotographReset()
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_RESET, {})
end

function XBigWorldAlbumAgency:X3CCameraPhotographSetDof(apply, blurSize)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_SET_DOF, {
        Apply = apply,
        BlurSize = blurSize,
    })
end

-- fake值
function XBigWorldAlbumAgency:IsFakeOn()
    return self._fakeOn or false
end

function XBigWorldAlbumAgency:SetFakeOn(isOn, isInit)
    if self._fakeOn == isOn then return end
    self._fakeOn = isOn
    if not isInit then
        self:X3CCameraPhotographSetDof(self._fakeOn, self._fakeValue)
    end
end

function XBigWorldAlbumAgency:GetFakeValue()
    return self._fakeValue or 0.5
end

function XBigWorldAlbumAgency:SetFakeValue(value, isInit)
    if self._fakeValue == value then return end
    self._fakeValue = value
    if not isInit then
        self:X3CCameraPhotographSetDof(self._fakeOn, self._fakeValue)
    end
end

function XBigWorldAlbumAgency:NotifyCurScaleRange(data)
    if self._NotifyCurScaleRangeCallback then
        self._NotifyCurScaleRangeCallback(data.CurScaleRange)
    end
end

function XBigWorldAlbumAgency:SetNotifyCurScaleRangeCallback(cb)
    self._NotifyCurScaleRangeCallback = cb
end

function XBigWorldAlbumAgency:NotifyActorChange(data)
    if self._NotifyActorChangeCallback then
        self._NotifyActorChangeCallback(data.DetectedActorIdsDic, data.HasDetectedAllQuestObjTarget, data.DetectedQuestObjectiveDic)
    end
end

function XBigWorldAlbumAgency:SetNotifyActorChangeCallback(cb)
    self._NotifyActorChangeCallback = cb
end

function XBigWorldAlbumAgency:OpenPhotoGraphUi(data)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenPhoto(not data.DontUseSequentialJob, data)
end

function XBigWorldAlbumAgency:TakePhotoSilent(data)
    local cameraGo = CS.UnityEngine.GameObject("SilentCamera")
    local camera = cameraGo:AddComponent(typeof(CS.UnityEngine.Camera))
    camera.transform.position = data.ShotPos or Vector3.zero
    camera.transform.eulerAngles = data.ShotRot or Vector3.zero
    camera.fieldOfView = data.Fov or 45
    camera.farClipPlane = 1500
    CS.UnityEngine.Rendering.Universal.UniversalRenderPipeline.SetupDeferredCamera(camera, true)
    local ratio = 0.68
    local width = math.floor(CS.UnityEngine.Screen.width * ratio)
    local height = math.floor(CS.UnityEngine.Screen.height * ratio)
    -- XLog.Debug("TakePhotoSilent:", width, height, CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height)
    if width <= 0 then
        width = 1280
    end
    if height <= 0 then
        height = 720
    end
    local rt = CS.XRenderTextureManager.GetTemporary(width, height, 0, CS.UnityEngine.RenderTextureFormat.Default, CS.UnityEngine.RenderTextureReadWrite.Default, false)
    camera.targetTexture = rt
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TEMPORARY_SET_FIRST_PERSON_PART_ENABLE, { Enable = true, })
    
    XScheduleManager.ScheduleOnce(function()
        cameraGo:SetActive(false)
        -- camera:Render()
        CS.CameraRenderRequestMangmaner.RenderInCameraRenderingProcess(camera)
        
        CS.UnityEngine.RenderTexture.active = rt
        local tex = XTool.GenTexture2DReleaseManually(width, height, CS.UnityEngine.TextureFormat.RGBA32, false)
        tex:ReadPixels(CS.UnityEngine.Rect(0, 0, width, height), 0, 0)
        tex:Apply()
        CS.UnityEngine.RenderTexture.active = nil

        self:BigWorldAlbumAddPhotoRequest(true, data.ShotId, function(photoData)
            local photoId = 0
            if photoData then
                photoId = photoData.Id or 0
            end

            local descaleTimes = 6
            self:CacheTexture(tex, math.floor(width / descaleTimes), math.floor(height / descaleTimes), photoId, photoData.CheckSalt)
            
            XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_PHOTO_UPLOADED, {
                PhotoId = photoId,
                ShotId = data.ShotId or 0,
            })
            
            XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TEMPORARY_SET_FIRST_PERSON_PART_ENABLE, { Enable = false, })
            CS.XRenderTextureManager.ReleaseTemporary(rt)
            CS.UnityEngine.Object.DestroyImmediate(tex)
            CS.UnityEngine.Object.DestroyImmediate(cameraGo)
        end, function()
            XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TEMPORARY_SET_FIRST_PERSON_PART_ENABLE, { Enable = false, })
            CS.XRenderTextureManager.ReleaseTemporary(rt)
            CS.UnityEngine.Object.DestroyImmediate(tex)
            CS.UnityEngine.Object.DestroyImmediate(cameraGo)
        end)
    end, 120)

    -- data.ShotId
    -- data.ShotPos
    -- data.ShotRot
    -- data.Fov
end

--endregion

-- 获取相册数据
function XBigWorldAlbumAgency:InitPhotoDatas(cb)
    if not XMVCA.XBigWorldFunction:CheckFunctionOpen(XMVCA.XBigWorldFunction.FunctionId.BigWorldAlbum) then
        return
    end
    local datas = self._Model:GetPhotoDatas()
    if datas then
        if cb then cb(datas) end
        return
    end
    XNetwork.Call(
        "BigWorldAlbumDataRequest",
        nil,
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            self._Model:SetPhotoDatas(res.PhotoDatas)
            self._Model:SetTaskPhotoDatas(res.TaskPhotoData)
            local photoIdList = {}
            for _, photoData in pairs(res.PhotoDatas) do
                table.insert(photoIdList, photoData.Id)
            end
            CS.XTool.CheckClearPhotoImageByIds(XPlayer.Id, photoIdList)
            -- 刷新数据
            if cb then cb(self._Model:GetPhotoDatas()) end
        end
    )
end

-- 大世界相册增加相片请求
function XBigWorldAlbumAgency:BigWorldAlbumAddPhotoRequest(isHide, uniqueId, cb, failCb)
    if isHide == nil then
        isHide = true
    end
    XNetwork.Call(
        "BigWorldAlbumAddPhotoRequest",
        {
            IsTaskHidePhoto = isHide,
            TaskHideUniqueId = uniqueId or 0,
        },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if failCb then failCb() end
                return
            end
            if not isHide then
                XUiManager.TipMsgEnqueue(XMVCA.XBigWorldService:GetText("SG_P_UploadSucess"))
            end
            if isHide then
                self._Model:AddTaskPhotoData(res.PhotoData)
            else
                self._Model:AddPhotoData(res.PhotoData)
            end
            -- 刷新数据
            if cb then cb(res.PhotoData) end
        end
   )
end

function XBigWorldAlbumAgency:UploadTakeTexture(isHide, objId, texture, cb, width, height)
    self:BigWorldAlbumAddPhotoRequest(isHide, objId, function(photoData)
        self:CacheTexture(texture, width, height, photoData.Id, photoData.CheckSalt)
        if cb then cb(photoData) end
    end)
end

function XBigWorldAlbumAgency:CacheTexture(texture, width, height, photoDataId, photoDataSalt)
    CS.XTool.SavePhotoImage(XPlayer.Id, photoDataId or 0, photoDataSalt or 0, texture)
    local smallTexture = CS.XTool.ResizeTexture(width or 308, height or 174, texture)
    CS.XTool.SavePhotoImage(XPlayer.Id, photoDataId or 0, photoDataSalt or 0, smallTexture, true)
    CS.UnityEngine.Object.DestroyImmediate(smallTexture)
end

function XBigWorldAlbumAgency:UpdateBigWorldPhotographData(bigWorldPhotographData, isInit)
    self._Model:UpdateBigWorldPhotographData(bigWorldPhotographData, isInit)
end

function XBigWorldAlbumAgency:GetPhotoDatas()
    return self._Model:GetPhotoDatas()
end

function XBigWorldAlbumAgency:GetPhotoTexture(photoData, isSmall)
    if not photoData then return end
    return CS.XTool.GetPhotoImage(XPlayer.Id, photoData.Id, photoData.CheckSalt, isSmall or false)
end

function XBigWorldAlbumAgency:GetPhotoTextureByMessageRefId(msgRefId, isSmall)
    local photoData = self._Model:GetPhotoDataByMessageRefId(msgRefId)
    if not photoData then
        photoData = self._Model:GetTaskPhotoDataByMessageRefId(msgRefId)
    end
    return self:GetPhotoTexture(photoData, isSmall)
end

function XBigWorldAlbumAgency:GetAnimationConfigById(id)
    return self._Model:GetAnimationConfigById(id)
end

function XBigWorldAlbumAgency:GetFilterConfigById(id)
    return self._Model:GetFilterConfigById(id)
end

function XBigWorldAlbumAgency:GeAnimParams(templateId)
    local t = self._Model:GetAnimationConfigById(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Anim,
        TemplateId = templateId,
        Icon = t.SmallIcon,
        -- Quality = 1,
        Name = t.Name,
        WorldDesc = t.WorldDesc,
        Description = t.Desc
    }
end

function XBigWorldAlbumAgency:GetFilterParams(templateId)
    local t = self._Model:GetFilterConfigById(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Filter,
        TemplateId = templateId,
        Icon = t.SmallIcon,
        -- Quality = 1,
        Name = t.Name,
        WorldDesc = t.WorldDesc,
        Description = t.Desc
    }
end


function XBigWorldAlbumAgency:IsUnlockFilterId(_filterId)
    local cfg = self._Model:GetFilterConfigById(_filterId)
    if cfg.ObtainType == 1 then
        for _, conditionId in pairs(cfg.ConditionIds) do
            local isUnlock, desc = XMVCA.XBigWorldService:CheckCondition(conditionId)
            if not isUnlock then
                return isUnlock, desc
            end
        end
        return true
    end

    if cfg.ObtainType == 0 then
        local unlockedFilters = self._Model:GetUnlockedCameraFilters()
        if not unlockedFilters then return false, cfg.LockDesc end
        for _, filterId in pairs(unlockedFilters) do
            if filterId == _filterId then
                return true
            end
        end
        return false, cfg.LockDesc
    end
    return true
end

function XBigWorldAlbumAgency:IsUnlockCharacterActionId(_actionId)
    local cfg = self._Model:GetAnimationConfigById(_actionId)
    if cfg.ObtainType == 1 then
        for _, conditionId in pairs(cfg.ConditionIds) do
            local isUnlock, desc = XMVCA.XBigWorldService:CheckCondition(conditionId)
            if not isUnlock then
                return isUnlock, desc
            end
        end
        return true
    end

    if cfg.ObtainType == 0 then
        local unlockedCharacterActions = self._Model:GetUnlockedCharacterActions()
        if not unlockedCharacterActions then return false, cfg.LockDesc end
        for _, actionId in pairs(unlockedCharacterActions) do
            if actionId == _actionId then
                return true
            end
        end
        return false, cfg.LockDesc
    end
    return true
end

----------public end----------

----------private start----------


----------private end----------

return XBigWorldAlbumAgency