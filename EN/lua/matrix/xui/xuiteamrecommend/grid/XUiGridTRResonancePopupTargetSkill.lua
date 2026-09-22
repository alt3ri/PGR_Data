-- 引用LuaUi：UiTeamRecommendResonanceSkillPopup

---@class XUiGridTRResonancePopupTargetSkill : XUiNode
local XUiGridTRResonancePopupTargetSkill = XClass(XUiNode, "XUiGridTRResonancePopupTargetSkill")

---@class XUiGridTRResonancePopupTargetSkillData
---@field SkillInfo table 共鸣技能信息
---@field IsTarget boolean 父界面按一键养成共鸣方案计算的目标态
---@field ActualSkillInfo table|nil 当前实际共鸣技能信息
---@field Pos number 共鸣槽位
---@param data XUiGridTRResonancePopupTargetSkillData
function XUiGridTRResonancePopupTargetSkill:Refresh(data)
    self.Data = data

    local skillInfo = data and data.SkillInfo
    if not skillInfo then
        self:Close()
        return
    end

    self:Open()
    self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    self.TxtSkillName.text = skillInfo.Name or ""
    self.TxtSkillDes.text = skillInfo.Description or ""
    local isTarget = data.IsTarget
    local isResonance = skillInfo:IsSame(data.ActualSkillInfo)
    self:RefreshTargetState(isTarget)
    self:RefreshResonanceState(isResonance, data)
end

-- 目标业务判断由父界面统一完成，本 Grid 仅刷新目标标签表现。
---@param isTarget boolean
function XUiGridTRResonancePopupTargetSkill:RefreshTargetState(isTarget)
    self.SelectNode.gameObject:SetActiveEx(not isTarget)
    self.TagTarget.gameObject:SetActiveEx(isTarget)
    self.TxtSelect.gameObject:SetActiveEx(false)
end

---@param isResonance boolean
---@param data XUiGridTRResonancePopupTargetSkillData
function XUiGridTRResonancePopupTargetSkill:RefreshResonanceState(isResonance, data)
    if self.BtnIsResonance then
        self.BtnIsResonance.gameObject:SetActiveEx(isResonance)
    end
    if isResonance then
        self.TxtSelectName.text = XUiHelper.GetText("EquipResonanceIsExist", data.Pos or 0)
    end
end

return XUiGridTRResonancePopupTargetSkill
