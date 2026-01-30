---@class XUiGuildWarUpTeam: XLuaUi
---@field _Control XGuildWarControl
local XUiGuildWarUpTeam = XLuaUiManager.Register(XLuaUi, "UiGuildWarUpTeam")
local XUiPanelGuildWarUpTeam = require('XUi/XUiGuildWar/UiGuildWarUpTeam/XUiPanelGuildWarUpTeam')

-- 特公角色界面
function XUiGuildWarUpTeam:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self:RegisterUiEvents()
end

function XUiGuildWarUpTeam:OnStart()
    local cfgs = self._Control.RoleStationControl:GetGuildWarSpecialRoleTeamCfgs()
    
    XUiHelper.RefreshCustomizedList(self.PanelTeam.transform.parent, self.PanelTeam, cfgs and #cfgs or 0, function(index, go)
        local grid = XUiPanelGuildWarUpTeam.New(go, self)
        grid:Open()
        grid:Refresh(cfgs[index])
    end)
end

function XUiGuildWarUpTeam:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose1, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnClose2, self.Close)
end

return XUiGuildWarUpTeam