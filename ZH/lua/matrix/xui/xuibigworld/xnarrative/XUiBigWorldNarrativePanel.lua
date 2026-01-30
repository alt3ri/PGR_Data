local XUiPanelBigWorldNarrative = require("XUi/XUiBigWorld/XNarrative/XUiPanelBigWorldNarrative")

---@class XUiBigWorldNarrativePanel : XUiPanelBigWorldNarrative
local XUiBigWorldNarrativePanel = XClass(XUiPanelBigWorldNarrative, "XUiBigWorldNarrativePanel")


function XUiBigWorldNarrativePanel:Refresh(narrativeId)
    self.TitleText.text = XMVCA.XBigWorldService:GetNarrativeTitle(narrativeId)
    self.ContentText.text = XMVCA.XBigWorldService:GetNarrativeContent(narrativeId)
    self.ContentText.alignment = XMVCA.XBigWorldService:GetNarrativeAlignment(narrativeId)
    local signature = XMVCA.XBigWorldService:GetNarrativeSignature(narrativeId)
    if string.IsNilOrEmpty(signature) then
        self.SignatureText.gameObject:SetActiveEx(false)
    else
        self.SignatureText.gameObject:SetActiveEx(true)
        self.SignatureText.text = signature
    end

    local rawImage = XMVCA.XBigWorldService:GetNarrativeAssetUrl(narrativeId)
    if string.IsNilOrEmpty(rawImage) then
        self.BgRImg.gameObject:SetActiveEx(false)
    else
        self.BgRImg.gameObject:SetActiveEx(true)
        self.BgRImg:SetRawImage(rawImage)
    end
    
    self:Open()
end

return XUiBigWorldNarrativePanel
