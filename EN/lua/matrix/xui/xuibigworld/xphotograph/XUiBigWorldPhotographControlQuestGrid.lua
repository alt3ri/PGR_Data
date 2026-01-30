---@class XUiBigWorldPhotographControlQuestGrid : XUiNode
local XUiBigWorldPhotographControlQuestGrid = XClass(XUiNode, "XUiBigWorldPhotographControlQuestGrid")

function XUiBigWorldPhotographControlQuestGrid:Update(data)
    if not self._ActorName then
        self._ActorUid = data.Uid
        self._ActorName = data.Ref:GetName()

        local desc = XMVCA.XBigWorldService:GetText("SG_P_TakePicDesc", self._ActorName)
        self.TxtTitle1.text = desc
        self.TxtTitle2.text = desc
    end
    
    if not self.Parent or not self.Parent.IsTargetIdFinish then return end
    local isFinish = self.Parent:IsTargetIdFinish(self._ActorUid)
    self.PanelOn.gameObject:SetActive(isFinish)
    self.PanelOff.gameObject:SetActive(not isFinish)
end

return XUiBigWorldPhotographControlQuestGrid
