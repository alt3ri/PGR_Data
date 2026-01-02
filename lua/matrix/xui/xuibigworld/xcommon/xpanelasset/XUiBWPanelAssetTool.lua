---@class XUiBWPanelAssetTool : XUiNode
---@field RImgTool UnityEngine.UI.RawImage
---@field TxtTool UnityEngine.UI.Text
---@field BtnBuyJump XUiComponent.XUiButton
local XUiBWPanelAssetTool = XClass(XUiNode, "XUiBWPanelAssetTool")

function XUiBWPanelAssetTool:OnStart()
    self._ItemId = 0

    self:_RegisterButtonClicks()
end

function XUiBWPanelAssetTool:OnBtnBuyJumpClick()
    if not XTool.IsNumberValid(self._ItemId) then
        return
    end

    XMVCA.XBigWorldUI:OpenGoodsInfo(self._ItemId)
end

function XUiBWPanelAssetTool:Refresh(itemId)
    if XTool.IsNumberValid(itemId) then
        self._ItemId = itemId

        self.RImgTool:SetImage(XMVCA.XBigWorldService:GetItemIcon(itemId))
        self.TxtTool.text = XMVCA.XBigWorldService:GetItemCount(itemId)
    end
end

function XUiBWPanelAssetTool:_RegisterButtonClicks()
    self.BtnBuyJump:AddEventListener(Handler(self, self.OnBtnBuyJumpClick))
end

return XUiBWPanelAssetTool