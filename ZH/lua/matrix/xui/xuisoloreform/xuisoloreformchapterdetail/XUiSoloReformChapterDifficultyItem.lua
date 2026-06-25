---@class XUiSoloReformChapterDifficultyItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterDifficultyItem = XClass(XUiNode, 'XUiSoloReformChapterDifficultyItem')

function XUiSoloReformChapterDifficultyItem:OnStart(isSelect)
    self._StageId = nil
    self._IsUnlock = nil
    self._IsSelect = isSelect
    self._StarCellList = {}
    XUiHelper.RegisterClickEvent(self, self.BtnBoss, self.OnClickDiff, true)
end

function XUiSoloReformChapterDifficultyItem:Update(stageId, index)
    self._StageId = stageId
    self._Index = index
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    local chapterId = self.Parent:GetChapterId()
    self._IsUnlock = self._Control:IsStageUnlock(chapterId, stageCfg.Difficulty)
    self:RefreshView()
end

function XUiSoloReformChapterDifficultyItem:RefreshView()
    if not XTool.IsNumberValid(self._StageId) then
        return
    end
    local stageCfg = self._Control:GetSoloReformStageCfg(self._StageId)
    self.BtnBoss:SetName(self._Index)
    self.BtnBoss:SetRawImage(stageCfg.Icon)
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(not self._IsUnlock)
    end
    self.BtnBoss.enabled = not self._IsSelect
    self.BtnBoss:SetButtonState(self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    local starStateList = self._Control:GetStageStarStateByStageId(self._StageId)
    self._StarCellList = XUiHelper.RefreshUiObjectList(self._StarCellList, self.GridStar.parent, self.GridStar, stageCfg.StarNum, function(i, grid)
        grid.ImgStarOff.gameObject:SetActiveEx(not starStateList[i])
        grid.ImgStarOn.gameObject:SetActiveEx(starStateList[i])
    end)
end

function XUiSoloReformChapterDifficultyItem:OnClickDiff()
    if not self._IsUnlock then
        XUiManager.TipText("SoloReformLastHardCompleted")
        return
    end
    self._Control:DispatchEvent(XMVCA.XSoloReform.EventId.EVENT_CLICK_DIFFICULTY_TAG, self._StageId)
end

function XUiSoloReformChapterDifficultyItem:OnDestroy()
    self._StageId = nil
    self._IsUnlock = nil
    self._StarCellList = nil
end

return XUiSoloReformChapterDifficultyItem
