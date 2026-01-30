
---@class XUiBigWorldPhotographPopupPhoto : XLuaUi
local XUiBigWorldPhotographPopupPhoto = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographPopupPhoto")

function XUiBigWorldPhotographPopupPhoto:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPhotographPopupPhoto:OnStart(isHideOtherBtn, hasDetectedAllEnvTarget, needCloseControl)
    self.hasDetectedAllEnvTarget = hasDetectedAllEnvTarget
    if needCloseControl then
        XMVCA.XBigWorldUI:SafeClose("UiBigWorldPhotographControl")
    end
    if isHideOtherBtn then
        self.Hide2.gameObject:SetActive(false)
    end
    self.CameraCupture.gameObject:SetActive(false)
    self.TxtUserName.text = XPlayer.Name
    self.TxtUserName2.text = XPlayer.Name
    self.TxtID.text = string.format("ID: %s", XPlayer.Id)
    self.TxtID2.text = string.format("ID: %s", XPlayer.Id)
    self.RawImage.texture = self._Control:GetCaptureTexture()
    self.RawImage2.texture = self.RawImage.texture
    self._hasUpload = false

    if self._Control:GetAutoSave() then
        if not self._Control:IsPhotoFull() then
            self._hasUpload = true
            self.BtnUpload.gameObject:SetActive(self._hasUpload)
        end
        self._DelayTimerId = XScheduleManager.ScheduleOnce(function()
            self:OnBtnUploadClick()
            self:_RemoveDelayTimer()
        end, 600)
    else
        self:OnTipMsgEnqueue()
    end
end

function XUiBigWorldPhotographPopupPhoto:OnTipMsgEnqueue()
    if self.hasDetectedAllEnvTarget then
        XUiManager.TipMsgEnqueue(XMVCA.XBigWorldService:GetText("SG_P_TakePicTaskFinish"))
    end
end

function XUiBigWorldPhotographPopupPhoto:OnEnable()
    self:Refresh()
end

function XUiBigWorldPhotographPopupPhoto:OnDestroy()
    self.CopyRoot.transform:SetParent(self.Transform)
    self:_RemoveDelayTimer()
end

function XUiBigWorldPhotographPopupPhoto:_RemoveDelayTimer()
    if self._DelayTimerId then
        XScheduleManager.UnSchedule(self._DelayTimerId)
        self._DelayTimerId = nil
    end
end

function XUiBigWorldPhotographPopupPhoto:Refresh()
    self.BtnAlbum:ShowReddot(self._Control:IsPhotoFull())
    self.BtnUpload.gameObject:SetActive(not self._hasUpload)
    local isFull = self._Control:IsPhotoFull()
    self.BtnUpload:SetButtonState(isFull and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiBigWorldPhotographPopupPhoto:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiBigWorldPhotographPopupPhoto:_OnBtnSave()
    -- local pos = self.ImgPicture.transform.localPosition
    -- local sizeDelta = self.ImgPicture.transform.sizeDelta
    -- local anchorMin = self.ImgPicture.transform.anchorMin
    -- local anchorMax = self.ImgPicture.transform.anchorMax
    -- self.ImgPicture.transform.anchorMin = Vector2.zero
    -- self.ImgPicture.transform.anchorMax = Vector2.one
    -- self.ImgPicture.transform.localPosition = Vector3.zero
    -- self.ImgPicture.transform.sizeDelta = Vector2.zero-- CS.UnityEngine.Vector2(self.PanelLogoCamera.rect.width, self.PanelLogoCamera.rect.height)
    -- self.CameraCupture.gameObject:SetActive(true)
    -- self.Hide.gameObject:SetActive(false)
    -- -- 截图后操作
    -- CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCupture)
    -- CS.XScreenCapture.ScreenCaptureWithCallBack(self.CameraCupture, function(texture)
    --     local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
    --     CS.XTool.SavePhotoAlbumImg(photoName, texture, function(errorCode)
    --         if errorCode > 0 then
    --             XUiManager.TipText("PremissionDesc") -- ios granted总是true, 权限未开通code返回1
    --             XLog.Debug("照片保存失败 Code：" .. errorCode)
    --             return
    --         end
    --         XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_SaveSucess"))
    --     end)
    --     CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
    --     self.Hide.gameObject:SetActive(true)
    --     self.CameraCupture.gameObject:SetActive(false)
    --     self.ImgPicture.transform.anchorMin = anchorMin
    --     self.ImgPicture.transform.anchorMax = anchorMax
    --     self.ImgPicture.transform.sizeDelta = sizeDelta
    --     self.ImgPicture.transform.localPosition = pos
    -- end)
    self.CopyRoot.gameObject:SetActive(true)
    self.CopyRoot.transform:SetParent(nil)
    self.CameraCupture.gameObject:SetActive(true)
    CS.XScreenCapture.ScreenCaptureWithCallBack(self.CameraCupture, function(texture)
        local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
        CS.XTool.SavePhotoAlbumImg(photoName, texture, function(errorCode)
            if errorCode > 0 then
                XUiManager.TipText("PremissionDesc") -- ios granted总是true, 权限未开通code返回1
                XLog.Debug("照片保存失败 Code：" .. errorCode)
                return
            end
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_SaveSucess"))
        end)
        self.CopyRoot.gameObject:SetActive(false)
        self.CopyRoot.transform:SetParent(self.Transform)
    end)
end

function XUiBigWorldPhotographPopupPhoto:OnBtnSaveClick()
    XPermissionManager.GetCameraPermissionToCallback(function()
        self:_OnBtnSave()
    end)
end

function XUiBigWorldPhotographPopupPhoto:OnBtnUploadClick()
    if self._Control:IsPhotoFull() then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_UploadFull"))
        return
    end
    local descaleTimes = 6
    self._Control:UploadTexture(self.RawImage.texture, function()
        self._hasUpload = true
        self:Refresh()
        self:OnTipMsgEnqueue()
    end, math.floor(self.RawImage.texture.width / descaleTimes), math.floor(self.RawImage.texture.height / descaleTimes))
end

function XUiBigWorldPhotographPopupPhoto:OnBtnAlbumClick()
    XMVCA.XBigWorldUI:Open("UiBigWorldPhotographPopupAlbum")
end

function XUiBigWorldPhotographPopupPhoto:OnBtnLogoCheckBoxClick()
    local isShow = not self.ImgLogo.gameObject.activeSelf
    self.ImgLogo.gameObject:SetActive(isShow)
    self.ImgLogo2.gameObject:SetActive(isShow)
end

function XUiBigWorldPhotographPopupPhoto:OnBtnDetailCheckBoxClick()
    local isShow = not self.PanelName.gameObject.activeSelf
    self.PanelName.gameObject:SetActive(isShow)
    self.PanelName2.gameObject:SetActive(isShow)
end

function XUiBigWorldPhotographPopupPhoto:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    self.BtnUpload:AddEventListener(handler(self, self.OnBtnUploadClick))
    self.BtnAlbum:AddEventListener(handler(self, self.OnBtnAlbumClick))
    self.BtnLogoCheckBox:AddEventListener(handler(self, self.OnBtnLogoCheckBoxClick))
    self.BtnDetailCheckBox:AddEventListener(handler(self, self.OnBtnDetailCheckBoxClick))
end

return XUiBigWorldPhotographPopupPhoto
