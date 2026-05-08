
local XUiFubenBossSingleTrialDetailV4P5 =
    require("XUi/XUiFubenBossSingleTrial/XUiFubenBossSingleTrialDetailV4P5")

---@class XUiFubenBossSingleBestiaryDetailV4P5 : XUiFubenBossSingleTrialDetailV4P5
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleBestiaryDetailV4P5 =
    XLuaUiManager.Register(
        XUiFubenBossSingleTrialDetailV4P5,
        "UiFubenBossSingleBestiaryDetailV4P5")

function XUiFubenBossSingleBestiaryDetailV4P5:StartManuallyFight()
    local stageId = self._SelectedBossStageConf.StageId

    self._Control:OnEnterBestiaryFight()

    XLuaUiManager.Open(
        "UiBattleRoleRoom",
        stageId,
        XDataCenter.TeamManager.GetXTeamByTypeId(
            CS.XGame.Config:GetInt("TypeIdBossSingle")))
end

function XUiFubenBossSingleBestiaryDetailV4P5:_GetBossCurScore(bossId)
    return self._Control:GetBestiraryTotalScoreById(bossId)
end

function XUiFubenBossSingleBestiaryDetailV4P5:_GetCurBossIndex(bossId)
    local sectionConf = self._Control:GetBossSectionConfigByBossId(bossId)
    local selection = #sectionConf.StageId

    for i = #sectionConf.StageId, 1, -1 do
        local stageId = sectionConf.StageId[i]
        if self:_GetStageCurrentScore(stageId) > 0 then return selection end
        selection = i
    end

    return 1
end

function XUiFubenBossSingleBestiaryDetailV4P5:_GetStageCurrentScore(stageId)
    local data = self:GetBossSingleData()
    local stageData = data:GetBossSingleBestiraryStageInfoByStageId(stageId)
    return stageData and stageData:GetScore() or 0
end


return XUiFubenBossSingleBestiaryDetailV4P5
