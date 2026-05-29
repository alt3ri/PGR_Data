--- 肉鸽6Boss预览
---@field _Control XTheatre6Control
---@field _PanelBossDetail XUiPanelTheatre6BossDetail Boss详情面板
---@class XUiTheatre6BossPreview: XLuaUi
local XUiTheatre6BossPreview = XLuaUiManager.Register(XLuaUi, 'UiTheatre6BossPreview')

function XUiTheatre6BossPreview:OnAwake()
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6BossPreview:OnStart(roomId, figthId)
    self._PanelBossDetail = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossDetail").New(self.UiTheatre6PanelBossDetail, self)
    self._PanelBossDetail:SetData(roomId, figthId)
end

return XUiTheatre6BossPreview
