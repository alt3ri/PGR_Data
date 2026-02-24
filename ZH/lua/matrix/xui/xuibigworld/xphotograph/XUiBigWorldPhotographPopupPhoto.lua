
---@class XUiBigWorldPhotographPopupPhoto : XLuaUi
local XUiBigWorldPhotographPopupPhoto = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographPopupPhoto")

function XUiBigWorldPhotographPopupPhoto:OnAwake()
    self:PlayAnimation("MAnimStart")
    self:_RegisterButtonClicks()
end

function XUiBigWorldPhotographPopupPhoto:OnStart(isHideOtherBtn, needCloseControl)
    if isHideOtherBtn then
        self.Hide2.gameObject:SetActive(false)
    end
    self.CameraCupture.gameObject:SetActive(false)
    self.TxtUserName.text = XPlayer.Name
    self.TxtUserName2.text = XPlayer.Name
    self.TxtID.text = string.format("ID: %s", XPlayer.Id)
    self.TxtID2.text = string.format("ID: %s", XPlayer.Id)

    self._hasUpload = false

    local t = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_DO_TAKE_PHOTO)
    self._IsFinishTask = false
    self._isNeedUpload = false
    self._objectiveId = 0

    local finishTask = {}
    if t and t.CompletedObjectiveIds and table.nums(t.CompletedObjectiveIds) > 0 then
        local isNeedUpload, objectiveId = XMVCA.XBigWorldQuest:CheckPhotoQuestNeedUpload()
        self._isNeedUpload = isNeedUpload
        self._objectiveId = objectiveId
        self._IsFinishTask = true
        finishTask = t.CompletedObjectiveIds
    end

    local dict = self._Control:GetRecordData(self._recordData)
    dict.taskIds = finishTask
    dict.save_cnt = self._Control:GetPhotoCurrentNum()
    CS.XRecord.Record(dict, "1000015", "BigWorldTakePhotoRecordFinish")

    self._NeedCloseFirst = needCloseControl or self._IsFinishTask
    self._DelayTimerId = XScheduleManager.ScheduleOnce(function()
        if not XLoginManager.IsLogin() then return end
        self._Control:CaptureTextureNow(function()
            if not XLoginManager.IsLogin() then return end
            self.RawImage.texture = self._Control:GetCaptureTexture()
            self.RawImage2.texture = self.RawImage.texture

            if self._Control:GetAutoSave() or self._isNeedUpload then
                if not self._Control:IsPhotoFull() then
                    self.BtnUpload.gameObject:SetActive(true)
                end
                self:_RemoveDelayTimer()
                self._DelayTimerId = XScheduleManager.ScheduleOnce(function()
                    self:OnBtnUploadClick()
                    self:_RemoveDelayTimer()
                end, 600)
            else
                self:OnTipMsgEnqueue()
                self:QuestFinishToFight()
            end
            -- self:PlayAnimation("Complete")
        end)
    end, 150)
end

function XUiBigWorldPhotographPopupPhoto:QuestFinishToFight(photoId, shotId)
    if not self._IsFinishTask or self._IsSendFinish then return end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_PHOTO_UPLOADED, {
        PhotoId = photoId or 0,
        ShotId = shotId or 0,
    })
    self._IsSendFinish = true
    self._IsFinishTask = false
end

function XUiBigWorldPhotographPopupPhoto:OnTipMsgEnqueue()
    if self._IsFinishTask then
        XUiManager.TipMsgEnqueue(XMVCA.XBigWorldService:GetText("SG_P_TakePicTaskFinish"))
    end
end

function XUiBigWorldPhotographPopupPhoto:OnEnable()
    self:PlayAnimation("MAnimEnable")
    self:Refresh()
end

function XUiBigWorldPhotographPopupPhoto:OnDestroy()
    if self._NeedCloseFirst then
        XMVCA.XBigWorldUI:Remove("UiBigWorldPhotographControl")
    end
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
            XUiHelper.Destroy(texture)
            if errorCode > 0 then
                XUiManager.TipText("PremissionDesc") -- ios granted总是true, 权限未开通code返回1
                XLog.Debug("照片保存失败 Code：" .. errorCode)
                return
            end
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("BigWorldPhotoSaveSuccessTip", CS.XTool.GetPhotoAlbumPath()))
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
    local isFull = self._Control:IsPhotoFull()
    if isFull and not self._isNeedUpload then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_UploadFull"))
        self:QuestFinishToFight()
        return
    end
    local saveDouble = self._isNeedUpload and not isFull and self._Control:GetAutoSave()
    local descaleTimes = 6
    XMVCA.XBigWorldAlbum:UploadTakeTexture(saveDouble, self._isNeedUpload, self._objectiveId, self.RawImage.texture, function(photoData)
        if not self._isNeedUpload then
            self._hasUpload = true
        end
        self._isNeedUpload = false
        self:Refresh()
        self:OnTipMsgEnqueue()
        self:QuestFinishToFight(photoData.Id)
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
