local XUiGridTheatre5Relic = require("XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Relic")

---@class XUiTheatre5RelicPanel : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5RelicPanel = XClass(XUiNode, "XUiTheatre5RelicPanel")

function XUiTheatre5RelicPanel:OnStart()
    self._RelicGrids = {}
end

function XUiTheatre5RelicPanel:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_RELIC_UPDATE, self.Update, self)
end

function XUiTheatre5RelicPanel:OnDisable()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_RELIC_UPDATE, self.Update, self)
end

function XUiTheatre5RelicPanel:Update()
    local relics = self._Control:GetUiDataRelics()
    XTool.UpdateDynamicItem(self._RelicGrids, relics, self.RelicContainer, XUiGridTheatre5Relic, self)
end

return XUiTheatre5RelicPanel