---@class XUiTheatre6PVPSettlement : XLuaUi pvp战斗结算
---@field _Control XTheatre6Control
local XUiTheatre6PVPSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre6PVPSettlement")

local BattlePhase = XEnumConst.Theatre6.Pvp.BattlePhase

function XUiTheatre6PVPSettlement:OnAwake()
    self.BtnExit:AddEventListener(handler(self, self.Close))
    ---@type XUiGridTheatre6PvpRank
    self._GridRank = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRank").New(self.GridRank, self)
    ---@type XUiPanelTheatre6PvpEnergy
    self._PanelEnergy = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpEnergy").New(self.PanelPVPEnergy, self)
end

---@param fightResult XTheatre6PvpFightResultProtocol
function XUiTheatre6PVPSettlement:OnStart(fightResult)
    self._FightResult = fightResult
    self._BattleState = self._Control:GetPvpTinyBattleState()

    if not self._FightResult or not self._BattleState then
        XLog.Error("Pvp战斗结算数据不存在.")
        return
    end

    self._PanelEnergy:Open()
    self._PanelEnergy:Refresh()
    self:ShowResult()
    self:ShowBattleResult()
    self:ShowRankChange()
end

function XUiTheatre6PVPSettlement:ShowResult()
    self.TxtName.text = XUiHelper.GetText(self._FightResult.IsFinalWin and "Theatre6PvpFightSuccsee" or "Theatre6PvpFightFail")
end

function XUiTheatre6PVPSettlement:ShowBattleResult()
    local isLosingStreak = not self._BattleState.RoundResults[1] and not self._BattleState.RoundResults[2] --两连败
    local showCount = isLosingStreak and 2 or 3
    for i = 1, showCount do
        local isSuccess = self._BattleState.RoundResults[i]
        local myGo = i == 1 and self.GridMyRole or XUiHelper.Instantiate(self.GridMyRole, self.GridMyRole.parent)
        ---@type XUiGridTheatre6PvpRole
        local myGrid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole").New(myGo, self)
        myGrid:Refresh(self._BattleState.MyLineups[i])
        myGrid:SetBattleResult(isSuccess)

        local enemyGo = i == 1 and self.GridEnemyRole or XUiHelper.Instantiate(self.GridEnemyRole, self.GridEnemyRole.parent)
        ---@type XUiGridTheatre6PvpRole
        local enemyGrid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole").New(enemyGo, self)
        local fileDatas = self._Control:GetEnemySaveFiles(self._BattleState.EnemyData)
        enemyGrid:Refresh(fileDatas[i])
        enemyGrid:SetBattleResult(not isSuccess)
    end
end

function XUiTheatre6PVPSettlement:ShowRankChange()
    local rankId = self._FightResult.RankId
    local oldScore = self._FightResult.OldScore
    local curScore = self._FightResult.NewScore

    local rankConfig = self._Control:GetPvpRankConfig(rankId)
    self._GridRank:SetData(rankId)
    self.PanelTag.gameObject:SetActiveEx(self._FightResult.IsNewHistory)

    self:StopScoreTween()
    local oldFill = oldScore / rankConfig.MaxScore
    local curFill = curScore / rankConfig.MaxScore
    self.ImgBar.fillAmount = oldFill
    self.TxtNum.text = oldScore
    self._ScoreTweenTimer = XUiHelper.Tween(1, function(t)
        self.ImgBar.fillAmount = CS.UnityEngine.Mathf.Lerp(oldFill, curFill, t)
        self.TxtNum.text = math.floor(CS.UnityEngine.Mathf.Lerp(oldScore, curScore, t))
    end, function()
        self.ImgBar.fillAmount = curFill
        self.TxtNum.text = curScore
    end)

    self:RefreshTips()
end

function XUiTheatre6PVPSettlement:RefreshTips()
    self._Tips = {}

    local battlePhase = self._FightResult.BattlePhase
    local isFinalWin = self._FightResult.IsFinalWin
    local isAdvanceBattleWin = self._FightResult.IsAdvanceBattleWin

    local isNormal = battlePhase == 0 and not isAdvanceBattleWin
    local isAdvancedSucc = battlePhase == 0 and isFinalWin and isAdvanceBattleWin
    local isAdvancedFail = battlePhase ~= 0 and not isFinalWin and not isAdvanceBattleWin
    local isNextAdvanced = battlePhase ~= 0 and isFinalWin and not isAdvanceBattleWin
    local isLockSucc = battlePhase == BattlePhase.AdvanceBattleLocked and isFinalWin
    local isLockFail = battlePhase == BattlePhase.AdvanceBattleLocked and not isFinalWin

    if isNormal or isNextAdvanced then
        self:ShowNormalBattleTip()
    elseif isAdvancedSucc then
        self:ShowAdvancedBattleSuccessTip()
    elseif isAdvancedFail or isLockFail then
        self:ShowAdvancedBattleFailTip()
    elseif isLockSucc then
        self:ShowAdvancedLockSuccessTip()
    else
        XLog.Error(string.format("【未知的Pvp段位状态】battlePhase=%s,isFinalWin=%s,isAdvanceBattleWin=%s", battlePhase, tostring(isFinalWin), tostring(isAdvanceBattleWin)))
    end

    if isAdvancedSucc or isAdvancedFail then
        self._PanelEnergy:HideEnergyChange() --进阶战斗不扣体力
    else
        local changeValue = self._Control:GetIntPvpConfigValue("ActionPointPerCost")
        self._PanelEnergy:ShowEnergyChange(-changeValue)
    end

    if #self._Tips == 0 then
        self.TxtDetail.gameObject:SetActiveEx(false)
    else
        for i = 1, math.min(2, #self._Tips) do
            local txtDetail = i == 1 and self.TxtDetail or XUiHelper.Instantiate(self.TxtDetail, self.TxtDetail.transform.parent)
            txtDetail.text = self._Tips[i]
        end
    end
    self.PanelScoreMax.gameObject:SetActiveEx(isNextAdvanced)

    --动效
    if isAdvancedSucc then
        local rankId = self._Control:GetPvpCurRankId()
        local anim = string.format("Rank%sTo%s", rankId - 1, rankId)
        self:PlayAnimationWithMask(anim)
    else
        self:PlayAnimationWithMask("Enable")
    end
end

function XUiTheatre6PVPSettlement:ShowNormalBattleTip()
    local scoreDetail = self._FightResult.ScoreDetail
    local baseScore = math.abs(scoreDetail.BaseWinScore + scoreDetail.EloScore)

    if self._FightResult.IsFinalWin then
        --挑战成功
        table.insert(self._Tips, XUiHelper.GetText("Theatre6PvpScoreDetailDesc1", baseScore))
        --三场全胜
        if XTool.IsNumberValid(scoreDetail.AllWinScore) then
            table.insert(self._Tips, XUiHelper.GetText("Theatre6PvpScoreDetailDesc2", scoreDetail.AllWinScore))
        end
    else
        --挑战失败
        --如果当前1002分 失败扣了5分 应该显示-1 而不是-5
        table.insert(self._Tips, XUiHelper.GetText("Theatre6PvpScoreDetailDesc3", math.abs(self._FightResult.NewScore - self._FightResult.OldScore)))
    end
end

function XUiTheatre6PVPSettlement:ShowAdvancedBattleSuccessTip()
    --段位升阶成功
    table.insert(self._Tips, XUiHelper.GetText("Theatre6PvpScoreDetailDesc4"))
end

function XUiTheatre6PVPSettlement:ShowAdvancedBattleFailTip()
    --分数已锁定，失败不扣分
    table.insert(self._Tips, XUiHelper.GetText("Theatre6PvpScoreDetailDesc5"))
end

function XUiTheatre6PVPSettlement:ShowAdvancedLockSuccessTip()
    --分数已锁定，胜利不加分
    table.insert(self._Tips, XUiHelper.GetText("Theatre6PvpScoreDetailDesc6"))
end

function XUiTheatre6PVPSettlement:OnDestroy()
    self._Control:ClearPvpTinyBattleState()
    self:StopScoreTween()
    CS.StatusSyncFight.XFightClient.RequestExitFight()
end

function XUiTheatre6PVPSettlement:StopScoreTween()
    if self._ScoreTweenTimer then
        XScheduleManager.UnSchedule(self._ScoreTweenTimer)
        self._ScoreTweenTimer = nil
    end
end

return XUiTheatre6PVPSettlement
