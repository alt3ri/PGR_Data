---@class XUiLottoGridRulePanel
local XUiLottoGridRulePanel = XClass(XUiNode, "XUiLottoGridRulePanel")

function XUiLottoGridRulePanel:Refresh(title, text)
    self.TxtRuleTittle.text = XUiHelper.ConvertLineBreakSymbol(title)
    self.TxtRule.text = XUiHelper.ConvertLineBreakSymbol(text)
end

return XUiLottoGridRulePanel
