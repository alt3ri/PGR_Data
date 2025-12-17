local XUiPanelBigWorldNarrative = require("XUi/XUiBigWorld/XNarrative/XUiPanelBigWorldNarrative")

---@class XUiBigWorldNarrativePhotoPanel : XUiPanelBigWorldNarrative
---@field TxtTitle UnityEngine.UI.Text
---@field TxtContent UnityEngine.UI.Text
---@field RImgPhoto UnityEngine.UI.RawImage
---@field BtnPhoto XUiComponent.XUiButton
---@field TranPhoto UnityEngine.RectTransform
local XUiBigWorldNarrativePhotoPanel = XClass(XUiPanelBigWorldNarrative, "XUiBigWorldNarrativePhotoPanel")

function XUiBigWorldNarrativePhotoPanel:OnInitCb()
    self._IsFullScreenPhoto = false
    self.BtnPhoto:AddEventListener(handler(self, self.OpenPhoto))
    self.BtnClose:AddEventListener(handler(self, self.ClosePhoto))
end

function XUiBigWorldNarrativePhotoPanel:Refresh(narrativeId)
    self._narrativeId = narrativeId
    self._IsFullScreenPhoto = false
    self.TxtTitle.text = XMVCA.XBigWorldService:GetNarrativeTitle(narrativeId)
    self.TxtContent.text = XMVCA.XBigWorldService:GetNarrativeContent(narrativeId)
    self.RImgPhoto:SetRawImage(XMVCA.XBigWorldService:GetNarrativeAssetUrl(narrativeId))
    self.RImgPhoto.gameObject:SetActiveEx(true)
    self.PanelBig.gameObject:SetActiveEx(false)
    self:Open()
end

function XUiBigWorldNarrativePhotoPanel:OpenPhoto()
    if self._IsFullScreenPhoto then
        return
    end
    self._IsFullScreenPhoto = true
    self.RImgPhotoBig:SetRawImage(XMVCA.XBigWorldService:GetNarrativeAssetUrl(self._narrativeId))
    self.RImgPhoto.gameObject:SetActiveEx(false)
    self.PanelBig.gameObject:SetActiveEx(true)
end

function XUiBigWorldNarrativePhotoPanel:ClosePhoto()
    if not self._IsFullScreenPhoto then
        return
    end
    self._IsFullScreenPhoto = false
    self.RImgPhoto.gameObject:SetActiveEx(true)
    self.PanelBig.gameObject:SetActiveEx(false)
end

return XUiBigWorldNarrativePhotoPanel