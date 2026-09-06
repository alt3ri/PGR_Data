-- 共鸣技能选择弹窗 - 武器当前已共鸣技能格（UiEquipGridResonanceSkillItem2）
---@class XUiGridWeaponResonanceCurrentItem : XUiNode
---@field Parent XUiGridChooseWeaponResonanceSkill
---@field BgComplete UnityEngine.RectTransform
---@field RImgResonanceSkill UnityEngine.UI.RawImage
---@field TxtSkillName UnityEngine.UI.Text
---@field TxtSkillDes UnityEngine.UI.Text
---@field PanelNone UnityEngine.RectTransform
---@field PanelNot UnityEngine.RectTransform
---@field RImgHead UnityEngine.UI.RawImage
local XUiGridWeaponResonanceCurrentItem = XClass(XUiNode, "XUiGridWeaponResonanceCurrentItem")

--- @param data table { Pos, SkillId, ResonanceType, BindCharacterId, CurCharacterId } —— SkillId 为空表示该栏位未共鸣
function XUiGridWeaponResonanceCurrentItem:Update(data)
    self.Data = data
    local hasSkill = XTool.IsNumberValid(data.SkillId)
    
    self.PanelNone.gameObject:SetActiveEx(not hasSkill)
    self.BgComplete.gameObject:SetActiveEx(hasSkill)
    self.RImgResonanceSkill.gameObject:SetActiveEx(hasSkill)
    if not hasSkill then
        self.PanelNot.gameObject:SetActiveEx(false)
        return
    end

    local skillInfo = XMVCA.XEquip:CreateResonanceSkillInfo(data.ResonanceType, data.SkillId)
    if skillInfo then
        self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
        self.TxtSkillName.text = skillInfo.Name
        self.TxtSkillDes.text = skillInfo.Description
    else
        self.TxtSkillName.text = ""
        self.TxtSkillDes.text = ""
    end

    -- 绑定角色非当前装备角色：显示 PanelNot + 绑定角色头像
    local bindCharacterId = data.BindCharacterId or 0
    local notBind = XTool.IsNumberValid(bindCharacterId) and bindCharacterId ~= data.CurCharacterId
    self.PanelNot.gameObject:SetActiveEx(notBind)
    if notBind then
        self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(bindCharacterId))
    end
end

return XUiGridWeaponResonanceCurrentItem

