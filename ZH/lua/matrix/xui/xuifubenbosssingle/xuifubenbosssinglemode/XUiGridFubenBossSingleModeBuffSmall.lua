---@class XUiGridFubenBossSingleModeBuffSmall : XUiNode
local XUiGridFubenBossSingleModeBuffSmall =
    XClass(XUiNode, "XUiGridFubenBossSingleModeBuffSmall")

function XUiGridFubenBossSingleModeBuffSmall:OnStart()
    self.GameObject:GetComponent("XUiButton").CallBack = handler(self, self.OnClick)
end

function XUiGridFubenBossSingleModeBuffSmall:SetData(feature, buffGroups, index)

    self.TxtBuffName.text = feature:GetName()
    self.PanelScoring.gameObject:SetActiveEx(feature:GetIsRecording())
    self.TxtValue.text = feature:GetScore()
    self.TxtMax.text = feature:GetTotalScore()
    self.RImgIcon:SetRawImage(feature:GetIcon())
    self._Index = index
    self.Feature = feature
end

function XUiGridFubenBossSingleModeBuffSmall:PlayExtendAnimation()
    self:PlayAnimation("Small")
end

function XUiGridFubenBossSingleModeBuffSmall:OnClick()
    self.Parent:Select(self._Index)
end

return XUiGridFubenBossSingleModeBuffSmall
