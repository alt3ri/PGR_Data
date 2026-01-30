---@class XUiTeamPrefabPartnerGridRoleTeam
local XUiTeamPrefabPartnerGridRoleTeam = XClass(nil, "XUiTeamPrefabPartnerGridRoleTeam")

function XUiTeamPrefabPartnerGridRoleTeam:Ctor(ui, index, selectCb)
    XTool.InitUiObjectByUi(self, ui)
    
    self.Index = index
    self.BtnClick.CallBack = function()
        if not XTool.IsNumberValid(self.RoleId) then 
            XUiManager.TipText("PartnerTeamPrefabNotCharacter")
            return 
        end
        if selectCb then
            selectCb(index)
        end
    end
end

--==============================
 ---@desc 刷新显示
 ---@roleId 角色id 
 ---@partnerId 宠物id, 非TemplateId 
--==============================
function XUiTeamPrefabPartnerGridRoleTeam:Refresh(roleId, partnerId)
    self.RoleId = roleId
    self.PartnerId = partnerId
    local hasRole = XTool.IsNumberValid(roleId)
    self.ImgLeftSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(self.Index)
    self.ImgRightSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(self.Index)
    self.DiagonalLeft.color = XDataCenter.TeamManager.GetTeamMemberDiagonalColor(self.Index)
    self.DiagonalRight.color = XDataCenter.TeamManager.GetTeamMemberDiagonalColor(self.Index)
    self.PanelNull.gameObject:SetActiveEx(not hasRole)
    self.PanelHave.gameObject:SetActiveEx(hasRole)
    self.RImgPartnerIcon.gameObject:SetActiveEx(hasRole)
    self.PanelPartnerNone.gameObject:SetActiveEx(not hasRole)

    if hasRole then
        self:SetHave(roleId)
    end
end

function XUiTeamPrefabPartnerGridRoleTeam:SetHave(roleId)
    if not roleId then
        self.ImgIcon.gameObject:SetActiveEx(false)
        return
    end
    self.ImgIcon.gameObject:SetActiveEx(true)
    local character = XMVCA.XCharacter:GetCharacter(roleId)
    if not character then return end

    self.ImgIcon:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(roleId))
    self.ImgQuality:SetSprite(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))

    local hasPartner = XTool.IsNumberValid(self.PartnerId)
    self.RImgPartnerIcon.gameObject:SetActiveEx(hasPartner)
    self.PanelPartnerNone.gameObject:SetActiveEx(not hasPartner)
    if hasPartner then
        local partner = XDataCenter.PartnerManager.GetPartnerEntityById(self.PartnerId)
        self.RImgPartnerIcon:SetRawImage(partner:GetIcon())
    end
end

function XUiTeamPrefabPartnerGridRoleTeam:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self.ImgSelect.color = XDataCenter.TeamManager.GetTeamMemberSelectColor(self.Index)
    end
end

return XUiTeamPrefabPartnerGridRoleTeam