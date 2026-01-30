local XUiPanelBigWorldNarrative = require("XUi/XUiBigWorld/XNarrative/XUiPanelBigWorldNarrative")

---@class XUiBigWorldRawImagePanel : XUiPanelBigWorldNarrative
local XUiBigWorldRawImagePanel = XClass(XUiPanelBigWorldNarrative, "XUiBigWorldRawImagePanel")

function XUiBigWorldRawImagePanel:OnInitCb()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.CloseParent))
end

function XUiBigWorldRawImagePanel:Refresh(narrativeId)
    self._narrativeId = narrativeId
    self.RImgPhoto:SetRawImage(XMVCA.XBigWorldService:GetNarrativeAssetUrl(narrativeId))
    self.RImgPhoto.gameObject:SetActiveEx(true)
    self:Open()
end

function XUiBigWorldRawImagePanel:CloseParent()
    self.Parent:OnBtnCloseClick()
end

return XUiBigWorldRawImagePanel
