-- 武器共鸣目标技能槽 Grid
---@class XUiGridWeaponResonanceSlot:XUiNode
---@field Parent XUiEquipOneClickCultureDetailMain
---@field GridEquipResonance XUiComponent.XUiButton
---@field RImgResonanceSkill UnityEngine.UI.RawImage
---@field TxtNumber UnityEngine.UI.Text
---@field BlackMask UnityEngine.RectTransform
local XUiGridWeaponResonanceSlot = XClass(XUiNode, "XUiGridWeaponResonanceSlot")

function XUiGridWeaponResonanceSlot:OnStart()
    self.GridEquipResonance:AddEventListener(handler(self, self.OnBtnClick))
end

--- 刷新一个共鸣槽（供 XTool.UpdateDynamicItemByUiCache 回调，签名固定为 data, index）
---@param resonanceData table 目标共鸣数据 { SkillId, IsComplete }
---@param index number 槽位序号（1-based）
function XUiGridWeaponResonanceSlot:Update(resonanceData, index)
    self.Pos = index
    self.SkillId = resonanceData and resonanceData.SkillId
    local templateId = self.Parent.ViewData and self.Parent.ViewData.TemplateId

    local isConfigured = resonanceData and XTool.IsNumberValid(resonanceData.SkillId)
    self.GridEquipResonance:SetDisable(not isConfigured)
    self.BlackMask.gameObject:SetActiveEx(isConfigured and not resonanceData.IsComplete)

    self.TxtNumber.text = string.format("%02d", index)
    self.TxtNumber.gameObject:SetActiveEx(true)

    if isConfigured then
        local resonanceType = XMVCA.XEquip:GuessResonanceType(resonanceData.SkillId, templateId)
        local skillInfo = XMVCA.XEquip:CreateResonanceSkillInfo(resonanceType, resonanceData.SkillId)
        self.GridEquipResonance:SetRawImage(skillInfo and skillInfo.Icon)
    end
end

function XUiGridWeaponResonanceSlot:OnBtnClick()
    -- 未配置目标技能的槽不可点（按钮已 SetDisable）
    if not XTool.IsNumberValid(self.SkillId) then
        return
    end
    local viewData = self.Parent.ViewData
    if not viewData then
        return
    end
    -- 三槽目标技能（按槽序）
    local targetSkillIds = {}
    local targetResonanceTypes = {}
    local targetList = self.Parent.TargetData and self.Parent.TargetData.WeaponResonanceList
    for i, item in ipairs(viewData.ResonanceList or table.empty) do
        targetSkillIds[i] = item.SkillId or 0
        local t = targetList and targetList[i]
        targetResonanceTypes[i] = t and t.ResonanceType or 0
    end
    XLuaUiManager.Open("UiEquipGridWeaponResonanceDetailPopup", {
        EquipId = viewData.EquipId,
        TemplateId = viewData.TemplateId,
        CharacterId = viewData.CharacterId,
        TargetSkillIds = targetSkillIds,
        TargetResonanceTypes = targetResonanceTypes,
        InitSlot = self.Pos,
    })
end

return XUiGridWeaponResonanceSlot
