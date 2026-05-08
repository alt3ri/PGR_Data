---@class XUiPanelGachaLiv4P5Rule : XUiNode
---@field Parent XUiGachaLiv4P5Log
local XUiPanelGachaLiv4P5Rule = XClass(XUiNode, "XUiPanelGachaLiv4P5Rule")

function XUiPanelGachaLiv4P5Rule:RefreshUiShow(gachaConfig)
    if self._GachaConfig then
        return
    end
    self._GachaConfig = gachaConfig

    local rule = self.OrganizeRule or XGachaConfigs.GetGachaRuleCfgById(self._GachaConfig.Id)
    local baseRules = rule.BaseRules
    local baseRuleTitles = rule.BaseRuleTitles

    self.PanelTxt.gameObject:SetActiveEx(false)
    for k, _ in pairs(baseRules) do
        local go = CS.UnityEngine.Object.Instantiate(self.PanelTxt, self.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.TxtRuleTitle.text = XUiHelper.ReplaceTextNewLine(baseRuleTitles[k])
        tmpObj.TxtRule.text = XUiHelper.ReplaceTextNewLine(baseRules[k])
        tmpObj.GameObject:SetActiveEx(true)
    end
end

return XUiPanelGachaLiv4P5Rule