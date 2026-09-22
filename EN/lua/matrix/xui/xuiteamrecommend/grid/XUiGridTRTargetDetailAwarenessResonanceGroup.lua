-- 引用LuaUi：UiTeamRecommendRoleTargetDetail
---@class XUiGridTRTargetDetailAwarenessResonanceGroup : XUiNode
local XUiGridTRTargetDetailAwarenessResonanceGroup = XClass(XUiNode, "XUiGridTRTargetDetailAwarenessResonanceGroup")

function XUiGridTRTargetDetailAwarenessResonanceGroup:OnStart()
    self.SkillGridList = {}
    self.GridResonanceSkill = self.Parent.AwarenessUiObj.GridResonanceSkill
end

-- 刷新单个意识位的目标配置、穿戴状态和共鸣状态
function XUiGridTRTargetDetailAwarenessResonanceGroup:Refresh(targetSlotData, wearingEquipId, characterId)
    if not targetSlotData or not XTool.IsNumberValid(targetSlotData.EquipTemplateId) then
        self:Close()
        return
    end

    self.TargetSlotData = targetSlotData
    self:Open()
    self:RefreshSkillList(targetSlotData, wearingEquipId, characterId)
end

function XUiGridTRTargetDetailAwarenessResonanceGroup:RefreshSkillList(targetSlotData, wearingEquipId, characterId)
    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        local grid = self.SkillGridList[pos]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridResonanceSkill.gameObject, self.Transform:GetChild(0))
            local XUiGridTRAwarenessResonanceSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRAwarenessResonanceSkill")
            grid = XUiGridTRAwarenessResonanceSkill.New(go, self)
            self.SkillGridList[pos] = grid
        end

        local resonanceData = targetSlotData.ResonanceList and targetSlotData.ResonanceList[pos]
        local targetState = XMVCA.XEquip:GetAwarenessResonanceTargetState(wearingEquipId, pos, resonanceData, characterId)
        grid:Open()
        grid:Refresh({
            ResonanceData = resonanceData,
            Site = targetSlotData.Site,
            Pos = pos,
            WearingEquipId = wearingEquipId,
            TargetState = targetState,
        })
        grid:SetSelected(false)
        grid:SetEnableClick(targetState.HasTarget)
    end
end

-- 打开指定意识共鸣槽详情
function XUiGridTRTargetDetailAwarenessResonanceGroup:OnResonanceSkillClick(pos)
    self.Parent:OnAwarenessResonanceSkillClick(self.TargetSlotData.Site, pos)
end

return XUiGridTRTargetDetailAwarenessResonanceGroup
