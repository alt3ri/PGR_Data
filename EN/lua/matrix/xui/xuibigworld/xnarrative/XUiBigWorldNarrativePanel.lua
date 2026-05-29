local XUiPanelBigWorldNarrative = require("XUi/XUiBigWorld/XNarrative/XUiPanelBigWorldNarrative")

---@class XUiBigWorldNarrativePanel : XUiPanelBigWorldNarrative
local XUiBigWorldNarrativePanel = XClass(XUiPanelBigWorldNarrative, "XUiBigWorldNarrativePanel")


function XUiBigWorldNarrativePanel:Refresh(narrativeId)
    local title = XMVCA.XBigWorldService:GetNarrativeTitle(narrativeId)
    local content = XMVCA.XBigWorldService:GetNarrativeContent(narrativeId)
    self.TitleText.text = XUiHelper.ReplaceWithPlayerName(title, "【kuroname】")
    self.ContentText.text = XUiHelper.ReplaceWithPlayerName(content, "【kuroname】")
    self.ContentText.alignment = XMVCA.XBigWorldService:GetNarrativeAlignment(narrativeId)
    local signature = XMVCA.XBigWorldService:GetNarrativeSignature(narrativeId)
    if string.IsNilOrEmpty(signature) then
        self.SignatureText.gameObject:SetActiveEx(false)
    else
        self.SignatureText.gameObject:SetActiveEx(true)
        self.SignatureText.text = XUiHelper.ReplaceWithPlayerName(signature, "【kuroname】")
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
