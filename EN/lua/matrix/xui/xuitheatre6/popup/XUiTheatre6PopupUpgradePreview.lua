---@class XUiTheatre6PopupUpgradePreview : XLuaUi 养成预览弹窗
---@field _Control XTheatre6Control
local XUiTheatre6PopupUpgradePreview = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupUpgradePreview")

function XUiTheatre6PopupUpgradePreview:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))

    self._PanelNow = require("XUi/XUiTheatre6/OutSider/Panel/XUiPanelTheatre6UpgradeNow").New(self.PanelNow, self)
    self._PanelPreview = require("XUi/XUiTheatre6/OutSider/Panel/XUiPanelTheatre6UpgradePreview").New(self.PanelUpgradePreview, self)
end

function XUiTheatre6PopupUpgradePreview:OnStart()
    self:Refresh()
end

function XUiTheatre6PopupUpgradePreview:Refresh()
    local talentConfigs = self._Control:GetTalentConfigs()
    local currentLv = self._Control:GetTalentLv()
    local curExp, _ = self._Control:GetTalentProgress()

    self._PanelNow:Refresh(talentConfigs, currentLv)
    self._PanelPreview:Refresh(talentConfigs, currentLv, curExp)
end

return XUiTheatre6PopupUpgradePreview
