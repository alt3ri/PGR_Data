---@class XUiPanelLackResources : XUiNode
local XUiPanelLackResources = XClass(XUiNode, "XUiPanelLackResources")

function XUiPanelLackResources:OnStart()
    self.BtnDownload:AddEventListener(handler(self, self.OnBtnDownloadClick))
end

function XUiPanelLackResources:SetData(characterId, fashionId)
    self._CharacterId = characterId
    self._FashionId = fashionId
end

function XUiPanelLackResources:OnBtnDownloadClick()
    if XTool.IsNumberValid(self._FashionId) and XTool.IsNumberValid(self._CharacterId) then
        XLuaUiManager.Open("UiDownloadPreviewForTips", self._CharacterId, self._FashionId)
    end
end

return XUiPanelLackResources
