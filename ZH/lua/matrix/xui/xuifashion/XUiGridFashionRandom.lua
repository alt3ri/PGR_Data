local XUiGridFashionRandom = XClass(XUiNode, "XUiGridFashionRandom")
function XUiGridFashionRandom:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponRandom, self.OnBtnWeaponRandomClick)
end

function XUiGridFashionRandom:Refresh(fashionId, index)
    self.FashionId = fashionId
    self.Index = index
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.Fashion:SetRawImage(template.Icon)

    local characterId = self.Parent.CharacterId
    local weaponFashionId = self.Parent.BindWeaponFashionDic[fashionId] or 0
    local icon = nil
    -- 武器的icon
    if XWeaponFashionConfigs.IsDefaultId(weaponFashionId) then
        local equipId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
        local templateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
        icon = XMVCA.XEquip:GetEquipBigIconPath(templateId)
    else
        icon = XWeaponFashionConfigs.GetFashionBigIcon(weaponFashionId)
    end
    self.Weapon:SetRawImage(icon)
    self.PanelWearing.gameObject:SetActiveEx(self.Parent.RandomFashionListReadyToRequset[fashionId])
    self:SetBtnWeaponRandomActive(self.FashionId == self.Parent.CurSelectFashionId)
    self:RefreshDot()
end

function XUiGridFashionRandom:SetBtnWeaponRandomActive(flag)
    self.BtnWeaponRandom.gameObject:SetActiveEx(flag)
end

function XUiGridFashionRandom:OnBtnWeaponRandomClick()
    if self.FashionId ~= self.Parent.CurSelectFashionId then
        return
    end

    XLuaUiManager.Open("UiFashionWeaponRandomSelect", self.Parent.CharacterId, self.FashionId,
        self.Parent.BindWeaponFashionDic, function(curSelectWeaponFashionId)
            self.Parent:OnBindWeaponFashionChange(self.FashionId, curSelectWeaponFashionId, self.Index)
        end)
end

function XUiGridFashionRandom:NormalClick()
    self.Parent:SetSwitchNormal(true)
    self.Parent:RefreshModel(self.FashionId)
end

function XUiGridFashionRandom:RefreshDot()

    local template = XDataCenter.FashionManager.GetFashionTemplate(self.FashionId)
    self.ColorTag.gameObject:SetActiveEx(template.FashionColorIds and #template.FashionColorIds > 0)

    local colorId = XDataCenter.FashionManager.GetOwnFashionDataById(self.FashionId).ColorId
    self.ImgColour.transform.parent.gameObject:SetActiveEx(colorId ~= 0)
    if colorId ~= 0 then
        local colorHex = XMVCA.XFashion:GetFashionColorHex(colorId)
        self.ImgColour.color = XUiHelper.Hexcolor2Color(string.sub(colorHex, 2, #colorHex))     --去#号
    end
end

return XUiGridFashionRandom
