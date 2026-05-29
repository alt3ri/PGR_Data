---@class XUiGridTheatre6BossRewardSkill : XUiNode Boss奖励Grid - 技能
---@field _Control XTheatre6Control
local XUiGridTheatre6BossRewardSkill = XClass(XUiNode, "XUiGridTheatre6BossRewardSkill")

function XUiGridTheatre6BossRewardSkill:OnStart()

end

---@param skillId number 技能Id (Theatre6Skill表)
function XUiGridTheatre6BossRewardSkill:Refresh(skillId)
    self._SkillId = skillId
    local skillConfig = self._Control:GetSkillCfgById(skillId)
    self.RImgIcon:SetRawImage(skillConfig.Icon)

    -- TODO: 根据技能类型显示不同背景 (Type: 1=主动, 2=拼刀技, 3=超算技, 4=插入技)
    -- local isActive = skillConfig.Type == 1
    -- if self.PanelBase then
    --     self.PanelBase:GetObject("ImgBgActive").gameObject:SetActiveEx(isActive)
    --     self.PanelBase:GetObject("ImgBgPassive").gameObject:SetActiveEx(not isActive)
    -- end

    -- TODO: 设置标签列表 ListTag

    -- TODO: 设置新标记 PanelNew

    -- TODO: 设置核心标记 PanelCore
end

return XUiGridTheatre6BossRewardSkill
