local XUiGachaFashionSelfChoiceDescribe = XLuaUiManager.Register(XLuaUi, "UiGachaFashionSelfChoiceDescribe")

function XUiGachaFashionSelfChoiceDescribe:OnAwake()
    self:InitButton()
end

function XUiGachaFashionSelfChoiceDescribe:InitButton()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiGachaFashionSelfChoiceDescribe:OnBtnCloseClick()
    self:Close()
end

function XUiGachaFashionSelfChoiceDescribe:OnStart(groupId)
    local config = XDataCenter.GachaManager.GetGroupConfig(groupId)
    if not config then
        XLog.Error("XUiGachaFashionSelfChoiceDescribe: invalid groupId: " .. tostring(groupId))
        self:Close()
        return
    end
    self.GroupConfig = config

    local XUiGachaGridRulePanel = require("XUi/XUiGachaFashionSelfChoice/Grid/XUiGachaGridRulePanel")
    for k, title in pairs(config.RuleTitle) do
        local go = k == 1 and self.GridRulePanel or XUiHelper.Instantiate(self.GridRulePanel, self.GridRulePanel.parent)
        local grid = XUiGachaGridRulePanel.New(go, self)
        grid:Refresh(title, config.RuleText[k])
    end
end