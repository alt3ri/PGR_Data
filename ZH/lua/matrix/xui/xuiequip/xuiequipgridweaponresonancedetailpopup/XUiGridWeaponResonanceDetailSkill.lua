---@class XUiGridWeaponResonanceDetailSkill : XUiNode
---@field Parent XUiEquipGridWeaponResonanceDetailPopup
local XUiGridWeaponResonanceDetailSkill = XClass(XUiNode, "XUiGridWeaponResonanceDetailSkill")

--- data = {
---   SkillInfo = XSkillInfoObj,          -- 技能信息
---   IsTarget = boolean,                 -- 是否方案目标技能
---   IsResonanced = boolean,             -- 当前武器该槽已共鸣且绑定角色==方案角色
---   IsNotResonanceCharacter = boolean,  -- 非当前角色共鸣的技能（末尾卡片）
---   CharacterId = number,               -- 非当前角色共鸣时，该共鸣绑定的角色Id（用于头像）
--- }
function XUiGridWeaponResonanceDetailSkill:Update(data)
    self.Data = data
    local skillInfo = data.SkillInfo
    self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    self.TxtSkillName.text = skillInfo.Name
    self.TxtSkillDes.text = skillInfo.Description

    -- 养成目标标签
    self.TagTarget.gameObject:SetActiveEx(data.IsTarget)

    -- 压黑遮罩：非目标技能 或 非当前角色共鸣技能；已共鸣（当前角色）的不压黑避免与 BtnIsResonanc 形成双层遮罩
    local isDark = (not data.IsTarget or data.IsNotResonanceCharacter) and not data.IsTarget
    self.SelectKuang.gameObject:SetActiveEx(isDark)

    -- 已共鸣标记（仅当前角色共鸣的技能）
    self.BtnIsResonanc.gameObject:SetActiveEx(data.IsResonanced)

    -- 非当前角色共鸣：不共鸣标签 + 绑定角色头像
    self.PanelNotResonance.gameObject:SetActiveEx(data.IsNotResonanceCharacter)
    if data.IsNotResonanceCharacter then
        self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(data.CharacterId))
    end
end

return XUiGridWeaponResonanceDetailSkill
