---星级信息
---@class XUiSoloReformChapterStarInfo: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterStarInfo = XClass(XUiNode, 'XUiSoloReformChapterStarInfo')

function XUiSoloReformChapterStarInfo:OnStart()
    self._StrengthCellList = {}
    self._IsInit = true
end

function XUiSoloReformChapterStarInfo:OnEnable()
    
end

function XUiSoloReformChapterStarInfo:OnDisable()
    
end

function XUiSoloReformChapterStarInfo:Update(stageId)
    local chapterId = self.Parent:GetChapterId()
    local maxDifficultyStageId = self._Control:GetMaxDifficultyStageId(chapterId)
    if not XTool.IsNumberValid(maxDifficultyStageId) then
        return
    end
    if not self.Parent.IsKillMode then
        self.Title.gameObject:SetActiveEx(true)
        self.Time.gameObject:SetActiveEx(maxDifficultyStageId == stageId)
    end
    
    if self.TxtNum then
        self.TxtNum.text = XUiHelper.GetText("SoloReformTimeShowNoPass")
        local minPassTime = self._Control:GetChapterStageMinPassTime(chapterId)
        if not string.IsNilOrEmpty(minPassTime) then
            self.TxtNum.text = minPassTime
        end
    end
    self:RefreshStarDesc(stageId)
    self._IsInit = false    
end

function XUiSoloReformChapterStarInfo:RefreshStarDesc(stageId)
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    local starStates = self._Control:GetStageStarStateByStageId(stageId)

    self._StarDescCellList = XUiHelper.RefreshUiObjectList(self._StarDescCellList, self.GridTarget.parent, self.GridTarget, #starStates, function(index, grid)
     
        local state = starStates[index]
        grid.PanelOn.gameObject:SetActiveEx(state)
        grid.PanelOff.gameObject:SetActiveEx(not state)
        grid.TxtTargetOn.text = stageCfg.StarTalks[index]
        grid.TxtTargetOff.text = stageCfg.StarTalks[index]
        grid.GameObject:SetActiveEx(false)
        XScheduleManager.ScheduleNextFrame(function() --等待一帧，触发动画
            if XTool.UObjIsNil(grid.GameObject) then return end
            grid.GameObject:SetActiveEx(true)
        end)
    end)

end

function XUiSoloReformChapterStarInfo:OnDestroy()
    self._StrengthCellList = nil
    self._IsInit = nil
end

return XUiSoloReformChapterStarInfo