---@class XUiSoloReformChapterDifficultyItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterDifficultyItem = XClass(XUiNode, 'XUiSoloReformChapterDifficultyItem')

function XUiSoloReformChapterDifficultyItem:OnStart()
    self._StageId = nil
    self._IsUnlock = nil
    self._IsSelect = false
    self._StarCellList = {}
    XUiHelper.RegisterClickEvent(self, self.BtnBoss, self.OnClickDiff,true)
end

function XUiSoloReformChapterDifficultyItem:Update(stageId, index)
    self._StageId = stageId
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    local chapterId = self.Parent:GetChapterId()
    self._IsUnlock = self._Control:IsStageUnlock(chapterId, stageCfg.Difficulty)
    --self.ImgArrow.gameObject:SetActiveEx(index ~= 1)
    self.BtnBoss:SetRawImage(stageCfg.Icon)
    self.BtnBoss:SetDisable(not self._IsUnlock)
    local starStateList = self._Control:GetStageStarStateByStageId(stageCfg.Id)
    self._StarCellList = XUiHelper.RefreshUiObjectList(self._StarCellList, self.GridStar.parent, self.GridStar, stageCfg.StarNum, function(index, grid)
        grid.ImgStarOff.gameObject:SetActiveEx(not starStateList[index])
        grid.ImgStarOn.gameObject:SetActiveEx(starStateList[index])
    end)
end

function XUiSoloReformChapterDifficultyItem:SetSelect(stageId)
    if not self._IsUnlock then
        return
    end
    self._IsSelect = self._StageId == stageId 
    self.BtnBoss.enabled = not self._IsSelect  
    self.BtnBoss:SetButtonState(self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)    
end

function XUiSoloReformChapterDifficultyItem:OnClickDiff()
    if not self._IsUnlock then
        XUiManager.TipText("SoloReformLastHardCompleted")
        return
    end
    if self._IsSelect then
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