---@class XUiSoloReformChapterStrengthItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterStrengthItem = XClass(XUiNode, 'XUiSoloReformChapterStrengthItem')

function XUiSoloReformChapterStrengthItem:OnStart()
    self._FightEventId = nil
    self._IsUnlock = nil
    XUiHelper.RegisterClickEvent(self, self.BtnGridReform, self.OnClickStrength,true)
end

function XUiSoloReformChapterStrengthItem:Update(fightEventId)
    self._FightEventId = fightEventId
    local fightEventCfg = self._Control:GetSoloReformUnlockFightEvent(fightEventId)
    local chapterId = self.Parent:GetChapterId()
    local passDifficulty = self._Control:GetChapterPassDifficulty(chapterId)
    self._IsUnlock = fightEventCfg.UnlockDiff <= passDifficulty
    self.PanelOn.gameObject:SetActiveEx(self._IsUnlock)
    self.PanelOff.gameObject:SetActiveEx(not self._IsUnlock)
    self.BtnGridReform:SetName(XUiHelper.ReplaceTextNewLine(fightEventCfg.Name))
    self._StrengthReddotId = self:AddRedPointEvent(self.BtnGridReform, self.OnStrengthReddotEvent, self, 
        { XRedPointConditions.Types.CONDITION_SOLO_REFORM_STRENGTH }, {fightEventId, self._IsUnlock}, true)
    self.BtnGridReform.NormalObj = self._IsUnlock and self.NormalOn.gameObject or self.NormalOff.gameObject
    if self.PressOn and self.PressOff then
        self.BtnGridReform.PressObj = self._IsUnlock and self.PressOn.gameObject or self.PressOff.gameObject
    end    
end

function XUiSoloReformChapterStrengthItem:OnStrengthReddotEvent(count)
    self.BtnGridReform:ShowReddot(count >= 0)
end

function XUiSoloReformChapterStrengthItem:SetSelect(fightEventId)
    local isSelect = self._FightEventId == fightEventId
    self.NormalOn.gameObject:SetActiveEx(self._IsUnlock and not isSelect)
    self.SelectOn.gameObject:SetActiveEx(self._IsUnlock and isSelect)
    self.NormalOff.gameObject:SetActiveEx(not self._IsUnlock and not isSelect)
    self.SelectOff.gameObject:SetActiveEx(not self._IsUnlock and isSelect)    
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