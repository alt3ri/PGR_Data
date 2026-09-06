-- 引用LuaUi：UiTeamRecommendResonanceSkillPopup
---@class XUiGridTRResonancePopupTargetGroup : XUiNode
local XUiGridTRResonancePopupTargetGroup = XClass(XUiNode, "XUiGridTRResonancePopupTargetGroup")

function XUiGridTRResonancePopupTargetGroup:OnStart()
    self.SkillGridList = {}
end

-- 刷新单个意识位的共鸣目标及选中状态
function XUiGridTRResonancePopupTargetGroup:RefreshLeftGroup(targetSlotData, wearingEquipId, characterId, selectAwarenessSite, selectResonanceSlot)
    self.TargetSlotData = targetSlotData

    if not targetSlotData or not XTool.IsNumberValid(targetSlotData.EquipTemplateId) then
        self:Close()
        return
    end
    if self.TxtPos then
        self.TxtPos.text = string.format("%02d", targetSlotData.Site or 0)
    end
    self:Open()
    for resonanceSlot = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        local grid = self:GetLeftSkillGrid(resonanceSlot)
        local resonanceData = targetSlotData.ResonanceList and targetSlotData.ResonanceList[resonanceSlot]
        local targetState = XMVCA.XEquip:GetAwarenessResonanceTargetState(wearingEquipId, resonanceSlot, resonanceData, characterId)
        grid:Open()
        grid:Refresh({
            ResonanceData = resonanceData,
            Site = targetSlotData.Site,
            Pos = resonanceSlot,
            WearingEquipId = wearingEquipId,
            TargetState = targetState,
        })
        grid:SetSelected(targetSlotData.Site == selectAwarenessSite and resonanceSlot == selectResonanceSlot)
        grid:SetEnableClick(targetState.HasTarget)
        grid:SetActiveImgPos(false)
    end
end

function XUiGridTRResonancePopupTargetGroup:GetLeftSkillGrid(resonanceSlot)
    local grid = self.SkillGridList[resonanceSlot]
    if grid then
        return grid
    end

    local gridGo = self["GridResonanceSkill" .. tostring(resonanceSlot)]
    local XUiGridTRAwarenessResonanceSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRAwarenessResonanceSkill")
    grid = XUiGridTRAwarenessResonanceSkill.New(gridGo, self)
    self.SkillGridList[resonanceSlot] = grid

    return grid
end

function XUiGridTRResonancePopupTargetGroup:OnResonanceSkillClick(resonanceSlot)
    local targetSlotData = self.TargetSlotData
    if targetSlotData and self.Parent then
        self.Parent:OnSelectTargetResonance(targetSlotData.Site, resonanceSlot)
    end
end

return XUiGridTRResonancePopupTargetGroup
