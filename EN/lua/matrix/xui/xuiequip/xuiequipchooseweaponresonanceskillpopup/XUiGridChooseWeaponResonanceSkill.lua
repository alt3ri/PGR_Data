-- 共鸣技能选择弹窗 - 一列（一个共鸣槽位）：上目标技能 Item1 + 下当前已共鸣技能 Item2
---@class XUiGridChooseWeaponResonanceSkill : XUiNode
---@field Parent XUiEquipChooseWeaponResonanceSkillPopup
---@field UiEquipGridResonanceSkillItem1 UnityEngine.RectTransform
---@field UiEquipGridResonanceSkillItem2 UnityEngine.RectTransform
local XUiGridChooseWeaponResonanceSkill = XClass(XUiNode, "XUiGridChooseWeaponResonanceSkill")

local XUiGridWeaponResonanceTargetItem = require("XUi/XUiEquip/XUiEquipChooseWeaponResonanceSkillPopup/XUiGridWeaponResonanceTargetItem")
local XUiGridWeaponResonanceCurrentItem = require("XUi/XUiEquip/XUiEquipChooseWeaponResonanceSkillPopup/XUiGridWeaponResonanceCurrentItem")

function XUiGridChooseWeaponResonanceSkill:OnStart()
    self.TargetItem = XUiGridWeaponResonanceTargetItem.New(self.UiEquipGridResonanceSkillItem1, self)
    self.TargetItem:Open()
    self.CurrentItem = XUiGridWeaponResonanceCurrentItem.New(self.UiEquipGridResonanceSkillItem2, self)
    self.CurrentItem:Open()
end

--- @param data table { Pos, Target={...}, Current={...}, IsDisplayCurrent }
function XUiGridChooseWeaponResonanceSkill:Update(data, index)
    self.Data = data
    self.TargetItem:Update(data.Target)

    if data.IsDisplayCurrent then
        self.CurrentItem:Open()
        self.CurrentItem:Update(data.Current)
    else
        self.CurrentItem:Close()
    end
end

--- 该槽位是否已被选中（转发主弹窗）
function XUiGridChooseWeaponResonanceSkill:IsSelected(pos)
    return self.Parent:IsSlotSelected(pos)
end

--- 目标技能点击（转发主弹窗切换选中）
function XUiGridChooseWeaponResonanceSkill:OnTargetItemClick(pos)
    self.Parent:OnTargetSkillClick(pos)
end

return XUiGridChooseWeaponResonanceSkill
