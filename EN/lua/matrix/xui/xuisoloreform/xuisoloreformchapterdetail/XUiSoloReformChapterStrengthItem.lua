---@class XUiSoloReformChapterStrengthItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterStrengthItem = XClass(XUiNode, 'XUiSoloReformChapterStrengthItem')

function XUiSoloReformChapterStrengthItem:OnStart()
    self._FightEventId = nil
    self._IsUnlock = nil
end

function XUiSoloReformChapterStrengthItem:Update(fightEventId, isSelect)

    self._FightEventId = fightEventId
    local fightEventCfg = self._Control:GetSoloReformUnlockFightEvent(fightEventId)
    local chapterId = self.Parent:GetChapterId()
    local passDifficulty = self._Control:GetChapterPassDifficulty(chapterId)
    self._IsUnlock = fightEventCfg.UnlockDiff <= passDifficulty
    self.BtnGridReform:SetName(XUiHelper.ReplaceTextNewLine(fightEventCfg.Name))
    self._StrengthReddotId = self:AddRedPointEvent(
        self.BtnGridReform, self.OnStrengthReddotEvent, self,
        { XRedPointConditions.Types.CONDITION_SOLO_REFORM_STRENGTH }, { fightEventId, self._IsUnlock }, true
    )
    self.BtnGridReform:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSoloReformChapterStrengthItem:OnStrengthReddotEvent(count)
    self.BtnGridReform:ShowReddot(count >= 0)
end

function XUiSoloReformChapterStrengthItem:OnClickStrength()
    if self._IsUnlock then
        self._Control:MarkLocalStrengthReddot(self._FightEventId)
    end
    self._Control:DispatchEvent(XMVCA.XSoloReform.EventId.EVENT_CLICK_FIGHT_EVENT_TAG, self._FightEventId)
    XRedPointManager.Check(self._StrengthReddotId)
end

function XUiSoloReformChapterStrengthItem:OnDestroy()
    self._FightEventId = nil
    self._isUnlock = nil
end

return XUiSoloReformChapterStrengthItem
