local XUiPanelTheatre6PvpLoadingDetail = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpLoadingDetail")

---@class XUiTheatre6PVPLoading : XLuaUi pvploading
---@field _Control XTheatre6Control
local XUiTheatre6PVPLoading = XLuaUiManager.Register(XLuaUi, "UiTheatre6PVPLoading")

function XUiTheatre6PVPLoading:OnStart(lineupMode, isContinue)
    local battleData = self._Control:GetPvpTinyBattleState()

    ---@type XUiPanelTheatre6PvpLoadingDetail
    local leftDetail = XUiPanelTheatre6PvpLoadingDetail.New(self.PanelLeft, self)
    leftDetail:SetSelfData(lineupMode)

    ---@type XUiPanelTheatre6PvpLoadingDetail
    local rightDetail = XUiPanelTheatre6PvpLoadingDetail.New(self.PanelRight, self)
    rightDetail:SetEnemyData(battleData.EnemyData)

    --LevelId暂时没用到
    local worldId = self._Control:GetIntPvpConfigValue("DlcFightWorldId")
    XMVCA.XTheatre6.Battle:RequestDlcSingleEnterFight(worldId, 0, true, isContinue, function()
        self:Close()
    end)
end

return XUiTheatre6PVPLoading
