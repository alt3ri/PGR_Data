---@class XUiGridWikiTab : XUiNode
---@field Parent XUiDlcRelinkWiki
---@field _Control XDlcRelinkControl
local XUiGridWikiTab = XClass(XUiNode, "XUiGridWikiTab")

---@param wiki XTableDlcRelinkWiki
function XUiGridWikiTab:UpdateData(wiki)
    self._Wiki = wiki
    self.BtnWiki:SetNameByGroup(0, wiki.Name)
    self:UpdateRedPoint()
end

function XUiGridWikiTab:OnClick()
    self._Control:SetWikiHasBeenViewed(self._Wiki.Id)
    self:UpdateRedPoint()
end

function XUiGridWikiTab:UpdateSelect(curWikiId)
    self.BtnWiki:SetButtonState(curWikiId == self._Wiki.Id and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiGridWikiTab:UpdateRedPoint()
    local isRed = not self._Control:GetHasWikiBeenViewed(self._Wiki.Id)
    self.BtnWiki:ShowReddot(isRed)
end

return XUiGridWikiTab
