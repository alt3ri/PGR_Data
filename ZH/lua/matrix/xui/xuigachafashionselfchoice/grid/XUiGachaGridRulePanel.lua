---@class XUiGachaGridRulePanel
local XUiGachaGridRulePanel = XClass(XUiNode, "XUiGachaGridRulePanel")

function XUiGachaGridRulePanel:Refresh(title, text)
    self.TxtRuleTittle.text = XUiHelper.ConvertLineBreakSymbol(title)
    self.TxtRule.text = XUiHelper.ConvertLineBreakSymbol(text)
end

return XUiGachaGridRulePanel
