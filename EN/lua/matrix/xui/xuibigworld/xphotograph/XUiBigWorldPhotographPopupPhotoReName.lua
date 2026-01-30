
---@class XUiBigWorldPhotographPopupPhotoReName : XLuaUi
local XUiBigWorldPhotographPopupPhotoReName = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographPopupPhotoReName")

function XUiBigWorldPhotographPopupPhotoReName:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPhotographPopupPhotoReName:OnStart(...)
    local photoIndex = self._Control:GetSelectPhotoIndex()
    local photoDatas = self._Control:GetPhotoDatas()
    local photoData = photoDatas[photoIndex]
    self.InFSigm.text = photoData.Remark
    local num = self._Control:GetAlbumMaxRemarkLength()
    self.InFSigm.characterLimit = num
    if self.TextNum then
        self.TextNum.text = XMVCA.XBigWorldService:GetText("SG_P_RenameLimitText", num)
    end
end

function XUiBigWorldPhotographPopupPhotoReName:OnBtnCloseClick()
    self:Close()
end

function XUiBigWorldPhotographPopupPhotoReName:OnBtnNameCancelClick()
    self:Close()
end

function XUiBigWorldPhotographPopupPhotoReName:OnBtnNameSureClick()
    self._Control:ModifyRemark(self.InFSigm.text, function()
        self:Close()
    end)
end

function XUiBigWorldPhotographPopupPhotoReName:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiBigWorldPhotographPopupPhotoReName:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnNameCancel:AddEventListener(handler(self, self.OnBtnNameCancelClick))
    self.BtnNameSure:AddEventListener(handler(self, self.OnBtnNameSureClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
end

return XUiBigWorldPhotographPopupPhotoReName
