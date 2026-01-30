--- 特攻角色组
---@class XUiPanelGuildWarUpTeam: XUiNode
---@field _Control XGuildWarControl
local XUiPanelGuildWarUpTeam = XClass(XUiNode, 'XUiPanelGuildWarUpTeam')
local XUiGridGuildWarRoleUp = require('XUi/XUiGuildWar/UiGuildWarUpTeam/XUiGridGuildWarRoleUp')

function XUiPanelGuildWarUpTeam:OnStart()
    
end

---@param cfg XTableGuildWarSpecialRoleTeam
function XUiPanelGuildWarUpTeam:Refresh(cfg)
    -- 特攻角色列表
    local roleIds = cfg.CharacterIds

    if self._RoleGrids == nil then
        self._RoleGrids = {}
    else
        for i, v in pairs(self._RoleGrids) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.GridCharacter.transform.parent, self.GridCharacter, roleIds and #roleIds or 0, function(index, go)
        ---@type XUiGridGuildWarRoleUp
        local grid = self._RoleGrids[go]

        if not grid then
            grid = XUiGridGuildWarRoleUp.New(go, self)
            self._RoleGrids[go] = grid
        end
        
        grid:Open()
        grid:SetData(roleIds[index])
    end)
    -- 队伍技能
    if not string.IsNilOrEmpty(cfg.BuffIcon) then
        self.RImgBuffIcon:SetRawImage(cfg.BuffIcon)
    end
    self.TxtDetail.text = cfg.BuffDesc
    self.TxtTitle.text = cfg.BuffName
    self.UpTag:SetRawImage(XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleIconBgBySpecialTeamId(cfg.Id))
    self.Icon:SetRawImage(XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleIconBySpecialTeamId(cfg.Id))
    
    -- 队伍名称
    if self.TitleText then
        self.TitleText.text = self._Control.SpecialRoleControl:GetSpecialRoleTeamNameBySpecialTeamId(cfg.Id)
    end
end

return XUiPanelGuildWarUpTeam