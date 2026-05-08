local XUiPanelBigWorldNarrative = require("XUi/XUiBigWorld/XNarrative/XUiPanelBigWorldNarrative")

---@class XUiBigWorldSpinePanel : XUiPanelBigWorldNarrative
local XUiBigWorldSpinePanel = XClass(XUiPanelBigWorldNarrative, "XUiBigWorldSpinePanel")

function XUiBigWorldSpinePanel:OnInitCb()
    self.BtnClose:AddEventListener(handler(self, self.CloseParent))
end

function XUiBigWorldSpinePanel:Refresh(narrativeId)
    local title = XMVCA.XBigWorldService:GetNarrativeTitle(narrativeId)
    self.TxtTitle.text = XUiHelper.ReplaceWithPlayerName(title, "【kuroname】")
    local assetUrl = XMVCA.XBigWorldService:GetNarrativeAssetUrl(narrativeId)
    if not string.IsNilOrEmpty(assetUrl) then
        self.SpineRoot:LoadPrefab(assetUrl)
    end
    self:Open()
end

function XUiBigWorldSpinePanel:CloseParent()
    self.Parent:OnBtnCloseClick()
end

return XUiBigWorldSpinePanel
