---@class XUiGridGuildWarRoleUp: XUiNode
local XUiGridGuildWarRoleUp = XClass(XUiNode, "XUiGridGuildWarRoleUp")

function XUiGridGuildWarRoleUp:SetData(roleId)
    local hasRole = roleId ~= nil and roleId > 0
    
    if not hasRole then
        return
    end
    
    self.RImgRoleIcon:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(roleId))
    self.UpTag:SetRawImage(XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleIconBgByRoleId(roleId))
    self.Icon:SetRawImage(XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleIcon(roleId))
    
    local buffData = XMVCA.XGuildWar.SpecialRoleAgency:GetSpecialRoleBuff(roleId)
    
    if buffData == nil then
        if self.PanelBuff then
            self.PanelBuff.gameObject:SetActiveEx(false)
        end
        return
    end
    
    self.TxtSkillDesc.text = buffData.Desc
    

end

return XUiGridGuildWarRoleUp