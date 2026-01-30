---@class XBigWorldAlbumAgency : XAgency
---@field private _Model XBigWorldAlbumModel
local XBigWorldAlbumAgency = XClass(XAgency, "XBigWorldAlbumAgency")
function XBigWorldAlbumAgency:OnInit()
    --初始化一些变量
end

function XBigWorldAlbumAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XBigWorldAlbumAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

--region X3C定义
---return CurScaleRange : float
function XBigWorldAlbumAgency:X3CCameraPhotographEnter(photographArgs, detectionNpcPlaceIdList, detectionSceneObjectPlaceIdList)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_ENTER_MODE, {
        PhotographArgs = photographArgs,
        DetectionNpcPlaceIdList = detectionNpcPlaceIdList or {},
        DetectionSceneObjectPlaceIdList = detectionSceneObjectPlaceIdList or {},
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
    if data.DontUseSequentialJob ~= nil then
        XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenPhoto(not data.DontUseSequentialJob, data.ParamId, data.DetectionNpcPlaceIdList, data.DetectionSceneObjectPlaceIdList, data.ObjectiveId)
    else
        XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenPhoto(true, data.ParamId, data.DetectionNpcPlaceIdList, data.DetectionSceneObjectPlaceIdList, data.ObjectiveId)
    end
end

--endregion

-- 获取相册数据
function XBigWorldAlbumAgency:InitPhotoDatas(cb)
    if not XMVCA.XBigWorldFunction:CheckFunctionOpen(XMVCA.XBigWorldFunction.FunctionId.BigWorldAlbum) then
        return
    end
    if self._Model:GetPhotoDatas() then
        if cb then cb(self._Model:GetPhotoDatas()) end
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

function XBigWorldAlbumAgency:GetPhotoDatas()
    return self._Model:GetPhotoDatas()
end

function XBigWorldAlbumAgency:GetPhotoTexture(photoData, isSmall)
    return CS.XTool.GetPhotoImage(XPlayer.Id, photoData.Id, photoData.CheckSalt, isSmall or false)
end

----------public end----------

----------private start----------


----------private end----------

return XBigWorldAlbumAgency