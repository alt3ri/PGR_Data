---@class XUiSoloReformSettlement: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformSettlement = XLuaUiManager.Register(XLuaUi, 'UiSoloReformSettlement')

function XUiSoloReformSettlement:OnAwake()
    self._StageId = nil
    self._StarDescCellList = nil
    self._StarAnimTimerId = nil
    self:RegisterClickEvent(self.BtnLeave, self.Close, true)
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnAgain, self.OnAgain, true)
end

function XUiSoloReformSettlement:OnStart(stageId, passTime, isNew)
    self._StageId = stageId
    self:RefreshPassTime(stageId, passTime, isNew)
    self:RefreshStageInfo(stageId)
end

function XUiSoloReformSettlement:OnEnable()

end

function XUiSoloReformSettlement:OnDisable()

end

function XUiSoloReformSettlement:RefreshPassTime(stageId, passTime, isNew)
    local chapterId = XMVCA.XSoloReform:GetEnterChapterId()
    local maxDifficultyStageId = self._Control:GetMaxDifficultyStageId(chapterId)
    self.PanelTime.gameObject:SetActiveEx(maxDifficultyStageId == stageId)
    if maxDifficultyStageId == stageId then
        self.TxtTime.text = XUiHelper.GetTime(passTime)
        self.TxtNew.gameObject:SetActiveEx(isNew)
    end            
end

function XUiSoloReformSettlement:RefreshStageInfo(stageId)
    local battleStageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    self.TxtStageName.text = battleStageCfg.Name
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    local starStates = self._Control:GetStageStarStateByStageId(stageId)
    local showGrids = {}
    self._StarDescCellList = XUiHelper.RefreshUiObjectList(self._StarDescCellList, self.GridTarget.parent, self.GridTarget, #starStates, function(index, grid)
        local state = starStates[index]
        grid.PanelOn.gameObject:SetActiveEx(state)
        grid.PanelOff.gameObject:SetActiveEx(not state)
        grid.TxtOnName.text = stageCfg.StarTalks[index]
        grid.TxtOffName.text = stageCfg.StarTalks[index]
        table.insert(showGrids, grid.GameObject)
        grid.GameObject:SetActiveEx(false)    
    end)

    self:StopStarAnimTimer()
    local delay = 600
    local interval = 200
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

function XUiSoloReformSettlement:StopStarAnimTimer()
    if self._StarAnimTimerId then
        XScheduleManager.UnSchedule(self._StarAnimTimerId)
        self._StarAnimTimerId = nil
    end    
end

function XUiSoloReformSettlement:OnAgain()
      ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local curBattleData = XMVCA.XSoloReform:GetCurBattleData()
    if XTool.IsTableEmpty(curBattleData) then
        return
    end
    self:Close()    
    fubenAgency:EnterFightByStageId(curBattleData.StageId, curBattleData.TeamId, curBattleData.IsAssist, curBattleData.ChallengeCount)
end

function XUiSoloReformSettlement:OnDestroy()
    self:StopStarAnimTimer()
    self._StarDescCellList = nil
end

return XUiSoloReformSettlement