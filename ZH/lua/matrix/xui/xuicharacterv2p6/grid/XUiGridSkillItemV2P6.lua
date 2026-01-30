local XUiGridSkillItemV2P6 = XClass(XUiNode, "XUiGridSkillItemV2P6")

function XUiGridSkillItemV2P6:UpdateEnhanceSkillInfo(characterId, skillInfo)
    self.Btn:SetNameByGroup(0, skillInfo.Name)
    self.Btn:SetRawImage(skillInfo.Icon)
    local isShowRed = XRedPointManager.CheckConditions({ XRedPointConditions.Types.CONDITION_CHARACTER_ENHANCESKILL, XRedPointConditions.Types.CONDITION_CHARACTER_NEW_ENHANCESKILL_TIPS }, characterId)
    self.Btn:ShowReddot(isShowRed)

    -- 生命树
    local xCharacter = XMVCA.XCharacter:GetCharacter(characterId)
    local enhanceSkillList = xCharacter:GetEnhanceSkillIdList()
    local powerIds = XMVCA.XCharacter:GetCharacterPowerEnhanceSkillIds(characterId)
    local isShowTreeIcon = nil
    for k, skillId in pairs(enhanceSkillList) do
        isShowTreeIcon = (not XTool.IsTableEmpty(powerIds)) and table.contains(powerIds, skillId)
        if isShowTreeIcon then
            break
        end
    end
    local isShowTreeControl = XTool.IsNumberValid(CS.XGame.ClientConfig:GetInt("CharacterPowerIconSkill2Visible"))
    self.ImgTreeIcon.gameObject:SetActiveEx(isShowTreeIcon and isShowTreeControl)
    if isShowTreeIcon then
        local powerConfig = XMVCA.XCharacter:GetCharacterPowerConfig(characterId)
        if powerConfig then
            self.ImgTreeIcon:SetSprite(powerConfig.IconSkill2)
        end
    end
end

function XUiGridSkillItemV2P6:UpdateNormalSkillInfo(characterId, skill)
    self.Btn:SetNameByGroup(0, skill.Name)
    self.Btn:SetRawImage(skill.Icon)

    local canUpdate = false
    for _, subSkill in ipairs(skill.subSkills) do
        if (XMVCA.XCharacter:CheckCanUpdateSkill(characterId, subSkill.SubSkillId, subSkill.Level)) then
            canUpdate = true
            break
        end
    end
    self.Btn:ShowReddot(canUpdate)

    -- 生命树
    local powerIds = XMVCA.XCharacter:GetCharacterPowerSkillIds(characterId)
    local isShowTreeIcon = nil
    for k, skillId in pairs(skill.SkillIdList) do
        isShowTreeIcon = (not XTool.IsTableEmpty(powerIds)) and table.contains(powerIds, skillId)
        if isShowTreeIcon then
            break
        end
    end
    local isShowTreeControl = XTool.IsNumberValid(CS.XGame.ClientConfig:GetInt("CharacterPowerIconSkill2Visible"))
    self.ImgTreeIcon.gameObject:SetActiveEx(isShowTreeIcon and isShowTreeControl)
    if isShowTreeIcon then
        local powerConfig = XMVCA.XCharacter:GetCharacterPowerConfig(characterId)
        if powerConfig then
            self.ImgTreeIcon:SetSprite(powerConfig.IconSkill2)
        end
    end
end

function XUiGridSkillItemV2P6:SetClickCb(cb)
    if not cb then
        return
    end
    XUiHelper.RegisterClickEvent(self, self.Btn, function ()
        cb()
    end)
end

return XUiGridSkillItemV2P6
