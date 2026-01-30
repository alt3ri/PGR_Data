
---@class XUiAccumulateExpendShopLog : XLuaUi
local XUiAccumulateExpendShopLog = XLuaUiManager.Register(XLuaUi, "UiAccumulateExpendShopLog")

function XUiAccumulateExpendShopLog:OnAwake()
    self:InitComponents()
end

function XUiAccumulateExpendShopLog:InitComponents()
    -- Button
    self.BtnTanchuangClose:AddEventListener(function() self:Close() end)
    self.BtnClose:AddEventListener(function() self:Close() end)

    self.PanelTxt.gameObject:SetActiveEx(false)

end

function XUiAccumulateExpendShopLog:OnStart(...)
    self:Update()
end

function XUiAccumulateExpendShopLog:OnEnable()
end

function XUiAccumulateExpendShopLog:OnDisable()
end

function XUiAccumulateExpendShopLog:OnDestroy()
end

function XUiAccumulateExpendShopLog:Update()
    local ruleTitles = self._Control:GetAccumulateExpendShopModel():GetActivityConfigs().BaseRuleTitles
    local rules = self._Control:GetAccumulateExpendShopModel():GetActivityConfigs().BaseRules
    for index, title in ipairs(ruleTitles) do
        local tmpObj = {}
        local ui = XUiHelper.Instantiate(self.PanelTxt, self.PanelContent)
        XTool.InitUiObjectByUi(tmpObj,ui)
        tmpObj.TxtRuleTitle.text = title
        tmpObj.TxtRule.text = rules[index]
        tmpObj.GameObject:SetActiveEx(true)
    end

end



return XUiAccumulateExpendShopLog
