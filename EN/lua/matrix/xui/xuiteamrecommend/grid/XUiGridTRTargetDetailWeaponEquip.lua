-- 引用LuaUi：UiTeamRecommendRoleTargetDetail
---@class XUiGridTRTargetDetailWeaponEquip : XUiNode
local XUiGridTRTargetDetailWeaponEquip = XClass(XUiNode, "XUiGridTRTargetDetailWeaponEquip")

function XUiGridTRTargetDetailWeaponEquip:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridTRTargetDetailWeaponEquip:Refresh(templateId, resonanceCount, equipId)
    self.TemplateId = templateId or 0
    self.EquipId = equipId

    if not XTool.IsNumberValid(self.TemplateId) then
        self:Close()
        return
    end

    self:Open()
    self:RefreshEquipInfo()
    self:RefreshResonanceIcon(resonanceCount)
end

function XUiGridTRTargetDetailWeaponEquip:RefreshEquipInfo()
    local equip = XTool.IsNumberValid(self.EquipId) and XMVCA.XEquip:GetEquip(self.EquipId) or nil
    self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(self.TemplateId))
    local qualityPath = equip and equip:GetEquipQualityPath() or XMVCA.XEquip:GetEquipQualityPath(self.TemplateId)
    self.Parent:SetUiSprite(self.ImgQuality, qualityPath)
    if self.ImgQualityEffect then
        local effectPath = equip and equip:GetEquipQualityEffectPath() or nil
        self.ImgQualityEffect.gameObject:SetActiveEx(effectPath ~= nil)
        if effectPath then
            self.ImgQualityEffect.gameObject:LoadUiEffect(effectPath)
        end
    end
    self.TxtName.text = XMVCA.XEquip:GetEquipName(self.TemplateId)
    self.ImgBreakthrough.gameObject:SetActiveEx(false)
    self.ImgMedalIconlock.gameObject:SetActiveEx(false)
end

function XUiGridTRTargetDetailWeaponEquip:RefreshResonanceIcon(resonanceCount)
    resonanceCount = resonanceCount or 0
    self.PanelResonance.gameObject:SetActiveEx(resonanceCount > 0)

    local iconPath = XMVCA.XEquip:GetResoanceIconPath(false)
    for index = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local img = self["ImgResonance" .. index]
        self.Parent:SetUiSprite(img, iconPath)
        img.gameObject:SetActiveEx(index <= resonanceCount)
    end
end

function XUiGridTRTargetDetailWeaponEquip:OnBtnClick()
    self.Parent:OnWeaponEquipGridClick(self.TemplateId)
end

return XUiGridTRTargetDetailWeaponEquip
