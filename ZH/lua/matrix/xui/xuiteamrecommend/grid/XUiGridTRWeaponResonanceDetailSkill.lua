local XUiGridTRWeaponResonanceDetailSkill = XClass(XUiNode, "XUiGridTRWeaponResonanceDetailSkill")

-- 刷新队伍推荐武器共鸣技能展示
function XUiGridTRWeaponResonanceDetailSkill:Update(data)
    local skillInfo = data.SkillInfo
    self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    self.TxtSkillName.text = skillInfo.Name
    self.TxtSkillDes.text = skillInfo.Description

    self.TagTarget.gameObject:SetActiveEx(data.IsTarget)
    self.SelectKuang.gameObject:SetActiveEx(not data.IsTarget)
    self.BtnIsResonanc.gameObject:SetActiveEx(data.IsResonanced)
    self.PanelNotResonance.gameObject:SetActiveEx(data.IsNotResonanceCharacter)
    if data.IsNotResonanceCharacter then
        self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(data.CharacterId))
    end
end

return XUiGridTRWeaponResonanceDetailSkill
