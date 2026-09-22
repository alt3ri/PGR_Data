---@class XUiGridPunishaarEnemySkill: XUiNode
---@field protected _Control
---@field Parent
---@field TxtSkillName UnityEngine.UI.Text 技能名（EnemySkill.SkillName）
---@field TxtSkillDesc UnityEngine.UI.Text 技能描述（EnemySkill.SkillDesc）
---@field IconSkill UnityEngine.UI.Image 技能图标（EnemySkill.SkillIcon）
---@field PanelSkill UnityEngine.RectTransform 技能根节点
local XUiGridPunishaarEnemySkill = XClass(XUiNode, "XUiGridPunishaarEnemySkill")

--- 刷新技能：SkillName/SkillDesc/SkillIcon
---@param skillCfg XTablePunishaarEnemySkill
function XUiGridPunishaarEnemySkill:Refresh(skillCfg)
    if not skillCfg then return end
    if self.TxtSkillName then
        self.TxtSkillName.text = skillCfg.SkillName or ""
    end
    if self.TxtSkillDesc then
        -- SkillDesc 配置含字面 \n，转真换行（同 EventSelectionBtnEvent:34 / XPunishaarConfigControl:123 范式）#怪物详情换行
        self.TxtSkillDesc.text = XUiHelper.ReplaceTextNewLine(skillCfg.SkillDesc or "")
    end
    if self.IconSkill and not string.IsNilOrEmpty(skillCfg.SkillIcon) then
        self.IconSkill:SetSprite(skillCfg.SkillIcon)
    end
end

return XUiGridPunishaarEnemySkill