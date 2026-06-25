local XUiSkillDetailsParentV2P6 = XLuaUiManager.Register(XLuaUi, "UiSkillDetailsParentV2P6")

function XUiSkillDetailsParentV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.SkillGridIndex = 1

    self:InitEffect()
end

function XUiSkillDetailsParentV2P6:InitEffect()
    local root = self.UiModelGo
    self.EffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.EffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.EffectHuanren.gameObject:SetActiveEx(false)
    self.EffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiSkillDetailsParentV2P6:SetSkillPos(pos)
    local maxSkillPos = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS
    local isShowEnhanceSkill = self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId)
    local isShowWeaponOverrunSkill = self:IsShowWeaponOverrunSkill()
    if not isShowEnhanceSkill and not isShowWeaponOverrunSkill then
        self.SkillGridIndex = pos
        return
    end

    if self.SkillGridIndex > maxSkillPos and pos <= maxSkillPos then
        local skills = XMVCA.XCharacter:GetCharacterSkills(self.CharacterId)
        if self.ChildUiSkillDetails then
            self.ChildUiSkillDetails:RefreshDataByChangePage(self.CharacterId, skills, pos)
        end
        self:OpenChildUi("UiSkillDetails", self.CharacterId, skills, pos)
    elseif pos == maxSkillPos + 1 then
        if not isShowEnhanceSkill then
            return
        end
        self:OpenChildUi("UiSkillDetailsForEnhanceV2P6", self.CharacterId)
    elseif pos == maxSkillPos + 2 then
        if not isShowWeaponOverrunSkill then
            return
        end
        self:OpenChildUi("UiWeaponOverrunSkillDetails", self.CharacterId)
    end

    self.SkillGridIndex = pos
end

function XUiSkillDetailsParentV2P6:SwitchToNextSkillDetails()
    local maxSkillPos = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS
    if self.SkillGridIndex <= maxSkillPos and self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId) then
        self:SetSkillPos(maxSkillPos + 1)
    elseif self.SkillGridIndex <= maxSkillPos + 1 and self:IsShowWeaponOverrunSkill() then
        self:SetSkillPos(maxSkillPos + 2)
    else
        self:SetSkillPos(1)
        if self.ChildUiSkillDetails then
            self.ChildUiSkillDetails:GotoSkill(1)
        end
    end
end

function XUiSkillDetailsParentV2P6:SwitchToLastSkillDetails()
    local maxSkillPos = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS
    if self.SkillGridIndex <= maxSkillPos then
        if self:IsShowWeaponOverrunSkill() then
            self:SetSkillPos(maxSkillPos + 2)
        elseif self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId) then
            self:SetSkillPos(maxSkillPos + 1)
        else
            self:SetSkillPos(maxSkillPos)
            if self.ChildUiSkillDetails then
                self.ChildUiSkillDetails:GotoSkill(maxSkillPos)
            end
        end
    elseif self.SkillGridIndex == maxSkillPos + 2 and self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId) then
        self:SetSkillPos(maxSkillPos + 1)
    else
        self:SetSkillPos(maxSkillPos)
    end
end

function XUiSkillDetailsParentV2P6:OpenChildUi(uiName, ...)
    if uiName == self.CurChildUiName then
        return
    end

    self:OpenOneChildUi(uiName, ...)
    self.CurChildUiName = uiName
end

function XUiSkillDetailsParentV2P6:OnStart(characterId, type, pos, gridIndex)
    self.CharacterId = characterId
    if not type then
        return
    end

    if type == XEnumConst.CHARACTER.SkillDetailsType.Normal then
        local skills = XMVCA.XCharacter:GetCharacterSkills(characterId)
        self:OpenChildUi("UiSkillDetails", self.CharacterId, skills, pos, gridIndex)
        self:SetSkillPos(pos)
    elseif type == XEnumConst.CHARACTER.SkillDetailsType.Enhance then
        self:OpenChildUi("UiSkillDetailsForEnhanceV2P6", self.CharacterId, gridIndex)
        self:SetSkillPos(XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 1)
    elseif type == XEnumConst.CHARACTER.SkillDetailsType.WeaponOverrun then
        self:SetSkillPos(XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 2)
    end
end

function XUiSkillDetailsParentV2P6:IsShowWeaponOverrunSkill()
    local characterConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId, true)
    local exclusiveEquipId = characterConfig and characterConfig.ExclusiveEquipId
    if not XTool.IsNumberValid(exclusiveEquipId) then
        return false
    end

    return XMVCA.XEquip:GetWeaponOverrunAttrCfgByTemplateId(exclusiveEquipId, self.CharacterId) ~= nil
end

function XUiSkillDetailsParentV2P6:OnDisable()
    XMVCA.XFavorability:StopCv()
end

return XUiSkillDetailsParentV2P6
