---@class XUiPanelTransfiniteTowerTraitTips : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field TxtTraitName UnityEngine.UI.Text
---@field ImgTrait1 UnityEngine.UI.Image
---@field TxtFormationTips UnityEngine.UI.Text
local XUiPanelTransfiniteTowerTraitTips = XClass(XUiNode, "XUiPanelTransfiniteTowerTraitTips")

---刷新词缀详情
---@param traitData table { Icon, Name, Desc }
function XUiPanelTransfiniteTowerTraitTips:Refresh(traitData)
    self.ImgTrait1:SetRawImage(traitData.Icon)
    self.TxtTraitName.text = traitData.Name
    self.TxtFormationTips.text = XUiHelper.ReplaceTextNewLine(traitData.Desc)
end

return XUiPanelTransfiniteTowerTraitTips
