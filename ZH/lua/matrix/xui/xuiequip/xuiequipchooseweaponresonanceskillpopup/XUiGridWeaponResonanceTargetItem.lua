-- 共鸣技能选择弹窗 - 目标共鸣技能格（UiEquipGridResonanceSkillItem1）
---@class XUiGridWeaponResonanceTargetItem : XUiNode
---@field Parent XUiGridChooseWeaponResonanceSkill
---@field BtnClick XUiComponent.XUiButton
---@field BgNormal UnityEngine.RectTransform
---@field BgComplete UnityEngine.RectTransform
---@field RImgResonanceSkill UnityEngine.UI.RawImage
---@field RImgEmpty UnityEngine.RectTransform
---@field TextCurPos UnityEngine.UI.Text
---@field TxtSkillName UnityEngine.UI.Text
---@field TxtSkillDes UnityEngine.UI.Text
---@field Select UnityEngine.RectTransform
local XUiGridWeaponResonanceTargetItem = XClass(XUiNode, "XUiGridWeaponResonanceTargetItem")

function XUiGridWeaponResonanceTargetItem:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

--- @param data table { Pos, SkillId, ResonanceType, IsComplete }
function XUiGridWeaponResonanceTargetItem:Update(data)
    self.Data = data
    local skillInfo = XMVCA.XEquip:CreateResonanceSkillInfo(data.ResonanceType, data.SkillId)
    if skillInfo then
        self.RImgResonanceSkill.gameObject:SetActiveEx(true)
        self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
        self.RImgEmpty.gameObject:SetActiveEx(false)
        self.TxtSkillName.text = skillInfo.Name
        self.TxtSkillDes.text = skillInfo.Description
    else
        self.RImgResonanceSkill.gameObject:SetActiveEx(false)
        self.RImgEmpty.gameObject:SetActiveEx(true)
        self.TxtSkillName.text = ""
        self.TxtSkillDes.text = ""
    end
    self.TextCurPos.text = string.format("%02d", data.Pos)
    
    self.BgNormal.gameObject:SetActiveEx(not data.IsComplete)
    self.BgComplete.gameObject:SetActiveEx(data.IsComplete == true)
    self.BgCompleteKuang.gameObject:SetActiveEx(data.IsComplete == true)

    self:RefreshSelected()
end

function XUiGridWeaponResonanceTargetItem:RefreshSelected()
    local isSelected = self.Parent:IsSelected(self.Data.Pos)
    self.Select.gameObject:SetActiveEx(isSelected)
end

function XUiGridWeaponResonanceTargetItem:OnBtnClick()
    self.Parent:OnTargetItemClick(self.Data.Pos)
end

return XUiGridWeaponResonanceTargetItem

