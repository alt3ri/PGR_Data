---星级信息
---@class XUiSoloReformChapterStarInfo: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterStarInfo = XClass(XUiNode, 'XUiSoloReformChapterStarInfo')

function XUiSoloReformChapterStarInfo:OnStart()
    self._StrengthCellList = {}
    self._StarAnimTimerId = nil
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
        self.Time.gameObject:SetActiveEx(true)
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
    local showGrids = {}
    self._StarDescCellList = XUiHelper.RefreshUiObjectList(self._StarDescCellList, self.GridTarget.parent, self.GridTarget, #starStates, function(index, grid)
        table.insert(showGrids, grid.GameObject)    
        local state = starStates[index]
        grid.PanelOn.gameObject:SetActiveEx(state)
        grid.PanelOff.gameObject:SetActiveEx(not state)
        grid.TxtTargetOn.text = stageCfg.StarTalks[index]
        grid.TxtTargetOff.text = stageCfg.StarTalks[index]
        grid.GameObject:SetActiveEx(false)
    end)
    self:StopStarAnimTimer()
    local delay = self._IsInit and 1000 or 100
    local interval = 100
    local times = 0
    self._StarAnimTimerId = XScheduleManager.Schedule(function()
        times = times + 1
        if times > #showGrids then
            self:StopStarAnimTimer()
            return
        end
        showGrids[times]:SetActiveEx(true)    
     end, interval, #showGrids, delay)
end

function XUiSoloReformChapterStarInfo:StopStarAnimTimer()
    if self._StarAnimTimerId then
        XScheduleManager.UnSchedule(self._StarAnimTimerId)
        self._StarAnimTimerId = nil
    end    
end

function XUiSoloReformChapterStarInfo:OnDestroy()
    self:StopStarAnimTimer()
    self._StrengthCellList = nil
    self._IsInit = nil
end

return XUiSoloReformChapterStarInfo