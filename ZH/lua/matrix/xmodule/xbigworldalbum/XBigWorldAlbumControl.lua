---@class XBigWorldAlbumControl : XControl
---@field private _Model XBigWorldAlbumModel
local XBigWorldAlbumControl = XClass(XControl, "XBigWorldAlbumControl")

function XBigWorldAlbumControl:OnInit()
    --初始化内部变量
    self._TextureCache = false
    self._SelectPhotoIndex = 0
    self._PrefsAutoSaveKey = XPlayer.Id .. "_PG_AutoSave"
    self._PrefsDefaultFirstPersonKey = XPlayer.Id .. "_PG_DefaultFirstPerson"
end

function XBigWorldAlbumControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldAlbumControl:RemoveAgencyEvent()

end

function XBigWorldAlbumControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
    self:RemoveTextureCache()
end

function XBigWorldAlbumControl:RemoveTextureCache()
    if self._TextureCache then
        CS.UnityEngine.Object.DestroyImmediate(self._TextureCache)
        self._TextureCache = false
    end
end

function XBigWorldAlbumControl:CaptureTextureNow(callback)
    CS.XScreenCapture.ScreenCaptureWithCallBack(XMVCA.XBigWorldGamePlay:GetCamera(), function(tex)
        self:RemoveTextureCache()
        self._TextureCache = tex
        if callback then callback(tex) end
    end)
end

function XBigWorldAlbumControl:CaptureTexture(...)
    XMVCA.XBigWorldUI:Open("UiBigWorldPhotographPopupPhoto", ...)
end

function XBigWorldAlbumControl:GetCaptureTexture()
    return self._TextureCache
end

function XBigWorldAlbumControl:SetRecordData(data)
    self._RecordDataCache = data
end

function XBigWorldAlbumControl:GetRecordData()
    return self._RecordDataCache
end

function XBigWorldAlbumControl:GetPhotoTexture(photoData, isSmall)
    if not photoData then return end
    return CS.XTool.GetPhotoImage(XPlayer.Id, photoData.Id, photoData.CheckSalt, isSmall or false)
end

--region 协议

-- 大世界相册删除相片请求
function XBigWorldAlbumControl:BigWorldAlbumDeletePhotoRequest(PhotoIds, cb)
    XNetwork.Call(
        "BigWorldAlbumDeletePhotoRequest",
        { PhotoIds = PhotoIds, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            CS.XTool.ClearPhotoImageByIds(XPlayer.Id, PhotoIds)
            self._Model:DeletePhotoDatas(PhotoIds)
            -- 刷新数据
            if cb then cb() end
        end
   )
end

-- 大世界相册更新相片请求
function XBigWorldAlbumControl:BigWorldAlbumUpdatePhotoRequest(PhotoId, Remark, cb)
    XNetwork.Call(
        "BigWorldAlbumUpdatePhotoRequest",
        { PhotoId = PhotoId, Remark = Remark, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_SaveSucess"))
            self._Model:UpdatePhotoDatas(PhotoId, Remark)
            -- 刷新数据
            if cb then cb() end
        end
   )
end

--endregion

function XBigWorldAlbumControl:GetPhotoDatas()
    return self._Model:GetPhotoDatas()
end

function XBigWorldAlbumControl:GetPhotoCurrentNum()
    local photoDatas = self._Model:GetPhotoDatas()
    if not photoDatas then return 0 end
    return #photoDatas
end

function XBigWorldAlbumControl:GetPhotoMaxNum()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("AlbumCapacity")
end

function XBigWorldAlbumControl:IsPhotoFull()
    return self:GetPhotoCurrentNum() >= self:GetPhotoMaxNum()
end

function XBigWorldAlbumControl:GetCameraMoveSpeed()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("AlbumCameraMoveSpeed")
end

function XBigWorldAlbumControl:GetAlbumMaxRemarkLength()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("AlbumMaxRemarkLength")
end

function XBigWorldAlbumControl:SetSelectPhotoIndex(photoIndex)
    self._SelectPhotoIndex = photoIndex
end

function XBigWorldAlbumControl:GetSelectPhotoIndex()
    return self._SelectPhotoIndex
end

function XBigWorldAlbumControl:DeletePhoto(PhotoIds, cb)
    if #PhotoIds <= 0 then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_DeleteEmptyTips"))
        return
    end
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("SG_P_RemoveTips"))
    confirmData:InitToggleActive(false)
    confirmData:InitSureClick(nil, function()
        self:BigWorldAlbumDeletePhotoRequest(PhotoIds, cb)
    end)
    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

function XBigWorldAlbumControl:GetAutoSave()
    local isAuto = XSaveTool.GetData(self._PrefsAutoSaveKey)
    if isAuto == nil then return false end
    return isAuto == 1
end

function XBigWorldAlbumControl:SetAutoSave(isSave)
    XSaveTool.SaveData(self._PrefsAutoSaveKey, isSave and 1 or 0)
end

function XBigWorldAlbumControl:GetDefaultFirstPerson()
    local isAuto = XSaveTool.GetData(self._PrefsDefaultFirstPersonKey)
    if isAuto == nil then return false end
    return isAuto == 1
end

function XBigWorldAlbumControl:SetDefaultFirstPerson(isFirstPerson)
    XSaveTool.SaveData(self._PrefsDefaultFirstPersonKey, isFirstPerson and 1 or 0)
end

function XBigWorldAlbumControl:ModifySelectPhotoIndex(index)
    self._SelectPhotoIndex = self._SelectPhotoIndex + index
    if self._SelectPhotoIndex > #self._Model:GetPhotoDatas() then
        self._SelectPhotoIndex = 1
    elseif self._SelectPhotoIndex < 1 then
        self._SelectPhotoIndex = #self._Model:GetPhotoDatas()
    end
end

function XBigWorldAlbumControl:ModifyRemark(newName, cb)
    if string.IsNilOrEmpty(newName) then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_RenameEmpty"))
        return
    end
    local photoIndex = self:GetSelectPhotoIndex()
    local photoDatas = self:GetPhotoDatas()
    local photoData = photoDatas[photoIndex]
    self:BigWorldAlbumUpdatePhotoRequest(photoData.Id, newName, cb)
end

function XBigWorldAlbumControl:GetParamConfigById(envId)
    return self._Model:GetParamConfigById(envId)
end

function XBigWorldAlbumControl:GetFiltersConfig()
    return self._Model:GetFiltersConfig()
end

function XBigWorldAlbumControl:GetCharacterActionsConfig(characterId)
    return self._Model:GetCharacterActionsConfig(characterId)
end

function XBigWorldAlbumControl:ReadUnlock(unlockId, subId, isNew)
    self._Model:ReadUnlock(unlockId, subId, isNew)
end

function XBigWorldAlbumControl:IsShowRedDotContent(unlockId, subId)
    return self._Model:IsShowRedDotContent(unlockId, subId)
end

return XBigWorldAlbumControl