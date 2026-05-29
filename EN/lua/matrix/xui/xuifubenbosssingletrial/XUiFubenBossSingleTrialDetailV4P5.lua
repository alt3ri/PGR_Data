
local XUiFubenBossSingleDetailV4P5 = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailV4P5")

---@class XUiFubenBossSingleTrialDetailV4P5 : XUiFubenBossSingleDetailV4P5

local XUiFubenBossSingleTrialDetailV4P5 =
    XLuaUiManager.Register(
        XUiFubenBossSingleDetailV4P5,
        "UiFubenBossSingleTrialDetailV4P5")

function XUiFubenBossSingleTrialDetailV4P5:StartManuallyFight()
    local stageId = self._SelectedBossStageConf.StageId

    self._Control:OnEnterTrialFight()

    XLuaUiManager.Open(
        "UiBattleRoleRoom",
        stageId,
        XDataCenter.TeamManager.GetXTeamByTypeId(
            CS.XGame.Config:GetInt("TypeIdBossSingle")))
end

function XUiFubenBossSingleTrialDetailV4P5:_RefreshBtnStartAndAuto()
    self.BtnAuto.gameObject:SetActiveEx(false)
    self.BtnStart.gameObject:SetActiveEx(true)
end

function XUiFubenBossSingleTrialDetailV4P5:_RefreshBtnReset()
    self.BtnReset.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleTrialDetailV4P5:_ShowHistoryTeam()
    return false
end

function XUiFubenBossSingleTrialDetailV4P5:_GetHistoryTeam()
    -- Boss图鉴不支持历史队伍
    XLog.Error("Impossible to get history team in Boss Single Trial.")
    return nil
end

function XUiFubenBossSingleTrialDetailV4P5:_GetBossCurScore(bossId)
    return self._Control:GetTrialTotalScoreInfoById(bossId)
end

function XUiFubenBossSingleTrialDetailV4P5:_GetCurBossIndex(bossId)
    return self._Control:GetCurTrialBossIndex(bossId)
end

function XUiFubenBossSingleTrialDetailV4P5:_GetStageCurrentScore(stageId)
    local data = self:GetBossSingleData()
    local stageData = data:GetBossSingleTrialStageInfoByStageId(stageId)
    return stageData and stageData:GetScore() or 0
end

return XUiFubenBossSingleTrialDetailV4P5
