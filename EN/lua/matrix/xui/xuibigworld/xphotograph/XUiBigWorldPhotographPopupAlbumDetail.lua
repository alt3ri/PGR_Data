
---@class XUiBigWorldPhotographPopupAlbumDetail : XLuaUi
local XUiBigWorldPhotographPopupAlbumDetail = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographPopupAlbumDetail")

function XUiBigWorldPhotographPopupAlbumDetail:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPhotographPopupAlbumDetail:OnEnable()
    self:Refresh()
end

function XUiBigWorldPhotographPopupAlbumDetail:OnDestroy()
    self:_DestroyTempTexCache()
    self:_DestroyTexCache()
end

function XUiBigWorldPhotographPopupAlbumDetail:_DestroyTexCache()
    if self._photoTexCache then
        CS.UnityEngine.Object.DestroyImmediate(self._photoTexCache)
        self._photoTexCache = false
    end
end

function XUiBigWorldPhotographPopupAlbumDetail:_DestroyTempTexCache()
    if self._tempTexCache then
        CS.UnityEngine.Object.DestroyImmediate(self._tempTexCache)
        self._tempTexCache = false
    end
end

function XUiBigWorldPhotographPopupAlbumDetail:Refresh()
    local index = self._Control:GetSelectPhotoIndex()
    local photoData = self._Control:GetPhotoDatas()[index]
    if not photoData then
        self:Close()
        return
    end
    
    if self._lastIndex ~= index and self._PhotoData then
        local moveTime = 0.25
        self._isMoving = true
        self.RImgPhotoDefault2.gameObject:SetActive(true)
        local rect = self.RImgPhotoDefault2.transform.rect
        local lPos = self.RImgPhotoDefault2.transform.localPosition
        local dir
        if index == self._Control:GetPhotoCurrentNum() and self._lastIndex == 1 then
            dir = -1
        elseif self._lastIndex == self._Control:GetPhotoCurrentNum() and index == 1 then
            dir = 1
        else
            dir = self._lastIndex > index and -1 or 1
        end
        local moveW = rect.width * dir
        lPos.x = lPos.x + moveW
        self.RImgPhotoDefault2.transform.localPosition = lPos
        self._tempTexCache = self._Control:GetPhotoTexture(photoData, false)
        if self._tempTexCache then
            self.RImgPhoto2.texture = self._tempTexCache
            self.RImgPhoto2.gameObject:SetActive(true)
        else
            self.RImgPhoto2.gameObject:SetActive(false)
        end
        
        XUiHelper.DoMove(self.RImgPhotoDefault.transform, CS.UnityEngine.Vector3(-moveW, 0, 0), moveTime, nil, function()
            self:_DestroyTexCache()
            self._photoTexCache = self._tempTexCache
            self._tempTexCache = nil
            self.RImgPhoto2.texture = nil
            if self._photoTexCache then
                self.RImgPhoto.texture = self._photoTexCache
                self.RImgPhoto.gameObject:SetActive(true)
            else
                self.RImgPhoto.gameObject:SetActive(false)
            end
            self.RImgPhotoDefault2.gameObject:SetActive(false)
            self.RImgPhotoDefault.transform.localPosition = CS.UnityEngine.Vector3.zero
            self._isMoving = false
        end)
        XUiHelper.DoMove(self.RImgPhotoDefault2.transform, CS.UnityEngine.Vector3.zero, moveTime)
        self._PhotoData = photoData
    else
        self._PhotoData = photoData
        self:_DestroyTexCache()
        self._photoTexCache = self._Control:GetPhotoTexture(self._PhotoData, false)
        if self._photoTexCache then
            self.RImgPhoto.texture = self._photoTexCache
            self.RImgPhoto.gameObject:SetActive(true)
        else
            self.RImgPhoto.gameObject:SetActive(false)
        end
    end

    self.TxtNum.text = index .. "/" .. self._Control:GetPhotoCurrentNum()
    self.TxtName.text = self._PhotoData.Remark or XTime.TimestampToGameDateTimeString(self._PhotoData.CreateTime, "yyMMddHHmmss")
    self._lastIndex = index

    if self._Control:GetPhotoCurrentNum() == 1 then
        self.BtnLeft.gameObject:SetActive(false)
        self.BtnRight.gameObject:SetActive(false)
    end
    -- self.BtnLeft.gameObject:SetActive(index ~= 1)
    -- self.BtnRight.gameObject:SetActive(index ~= self._Control:GetPhotoCurrentNum())
end

function XUiBigWorldPhotographPopupAlbumDetail:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiBigWorldPhotographPopupAlbumDetail:_OnBtnSave()
    local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
    CS.XTool.SavePhotoAlbumImg(photoName, self.RImgPhoto.texture, function(errorCode)
        if errorCode > 0 then
            XUiManager.TipText("PremissionDesc") -- ios granted总是true, 权限未开通code返回1
            XLog.Debug("照片保存失败 Code：" .. errorCode)
            return
        end
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_SaveSucess"))
    end)
end

function XUiBigWorldPhotographPopupAlbumDetail:OnBtnSaveClick()
    XPermissionManager.GetCameraPermissionToCallback(function()
        self:_OnBtnSave()
    end)
end

function XUiBigWorldPhotographPopupAlbumDetail:OnBtnDeteleClick()
    self._Control:DeletePhoto({self._PhotoData.Id}, function()
        self:OnBtnLeftClick()
    end)
end

function XUiBigWorldPhotographPopupAlbumDetail:OnBtnNameClick()
    XMVCA.XBigWorldUI:Open("UiBigWorldPhotographPopupPhotoReName")
end

function XUiBigWorldPhotographPopupAlbumDetail:OnBtnLeftClick()
    if self._isMoving then return end
    self._Control:ModifySelectPhotoIndex(-1)
    self:Refresh()
end

function XUiBigWorldPhotographPopupAlbumDetail:OnBtnRightClick()
    if self._isMoving then return end
    self._Control:ModifySelectPhotoIndex(1)
    self:Refresh()
end

function XUiBigWorldPhotographPopupAlbumDetail:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    self.BtnDetele:AddEventListener(handler(self, self.OnBtnDeteleClick))
    self.BtnName:AddEventListener(handler(self, self.OnBtnNameClick))
    self.BtnLeft:AddEventListener(handler(self, self.OnBtnLeftClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
end

return XUiBigWorldPhotographPopupAlbumDetail
