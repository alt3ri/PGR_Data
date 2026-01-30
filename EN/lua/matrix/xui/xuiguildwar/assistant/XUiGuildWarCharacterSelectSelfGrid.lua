local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")

---@class XUiGuildWarCharacterSelectSelfGrid:XUiBattleRoomRoleGrid
---@field _Control XGuildWarControl
local XUiGuildWarCharacterSelectSelfGrid = XClass(XUiBattleRoomRoleGrid, "XUiGuildWarCharacterSelectSelfGrid")

function XUiGuildWarCharacterSelectSelfGrid:Ctor(ui)
    --self.PanelUP = XUiHelper.TryGetComponent(self.Transform, "PanelUP", "RectTransform")
    --self.RImgUpIcon = XUiHelper.TryGetComponent(self.PanelUP.transform, "PanelUP/UpTag/Icon", "RawImage")
    self:SetSelect(false)
end

function XUiGuildWarCharacterSelectSelfGrid:Refresh(characterId)
    self.CharacterId = characterId

    self:UpdateCharacter()
end

function XUiGuildWarCharacterSelectSelfGrid:UpdateCharacter()
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    
    self:SetData(character)

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(true)
        local ability = XMVCA.XCharacter:GetCharacterAbilityById(characterId)
        self.TxtFight.text = math.floor(ability)
    end

     --特攻角色
    local isSpecialRole = XMVCA.XGuildWar.SpecialRoleAgency:CheckIsSpecialRole(characterId)
    self.PanelHighPriority.gameObject:SetActiveEx(isSpecialRole)

     --特攻图标
    if isSpecialRole then
        local icon = XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleIcon(characterId)
        if icon then
            self.RImgGuildWarUP:SetRawImage(icon)
        end
        
        local iconBg = XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleIconBgByRoleId(characterId)

        if not string.IsNilOrEmpty(iconBg) then
            if self.GuildWarUpTagBg then
                self.GuildWarUpTagBg:SetRawImage(iconBg)
            end
        end
    end
    
    -- 驻扎图标
    local isStationed = self._Control.RoleStationControl:CheckCharacterIsStationedAnyNode(characterId)

    if self.PanelStaying then
        self.PanelStaying.gameObject:SetActiveEx(isStationed)
    end
end

function XUiGuildWarCharacterSelectSelfGrid:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

function XUiGuildWarCharacterSelectSelfGrid:SetInTeam(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
end 

return XUiGuildWarCharacterSelectSelfGrid
