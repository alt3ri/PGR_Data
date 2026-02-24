local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XTeam = require("XEntity/XTeam/XTeam")

---@class XSoloReformAgency : XFubenActivityAgency
---@field private _Model XSoloReformModel
local XSoloReformAgency = XClass(XFubenActivityAgency, "XSoloReformAgency")
local MainReddot = { XRedPointConditions.Types.CONDITION_SOLO_REFORM_MAIN }
function XSoloReformAgency:OnInit()
    self._CurEnterChapterId = nil
    self._RecodeCurBattleData = nil --用于再次挑战
    self._TeamDic = {}
    self.EventId = require('XModule/XSoloReform/XSoloReformEventId')
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.SoloReform)
end

function XSoloReformAgency:InitRpc()
    XRpc.NotifySoloReformData = handler(self, self.OnNotifySoloReformData)
end

function XSoloReformAgency:InitEvent()

end

function XSoloReformAgency:RemoveEvent()

end

--- 通用跳转接口（SkipId）
---@param skipDatas XTable.XTableSkipFunctional
function XSoloReformAgency:ExOnSkip(skipDatas)
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SoloReform, true)
        and self:InActivityTime() then
        XLuaUiManager.Open('UiSoloReformMain')
        return true
    else
        XUiManager.TipText('WorldBossIsNotOpen')
    end
    return false
end

function XSoloReformAgency:InActivityTime()
    local activityId = self._Model:GetActivityId()
    if not XTool.IsNumberValid(activityId) then
        return false
    end
    local activityCfg = self._Model:GetSoloReformCfg(activityId)
    return XFunctionManager.CheckInTimeByTimeId(activityCfg.OpenTime)
end

function XSoloReformAgency:OnNotifySoloReformData(data)
    self._Model:UpdateSoloReformData(data)
end

function XSoloReformAgency:GetTeam(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    local team = self._TeamDic[chapterId]

    if not team then
        team = XTeam.New(self._Model:GetStageTeamKey(chapterId))
        self._TeamDic[chapterId] = team
    end

    return team
end

function XSoloReformAgency:SettleFight(result)
    if XMVCA.XFuben:GetFubenSettling() then
        --有副本正在结算中
        XLog.Warning("XSoloReformAgency:SettleFight Warning, fuben is settling!")
        return
    end
    XMVCA.XFuben:StatisticsFightResultDps(result)
    XMVCA.XFuben:SetFubenSettling(true) --正在结算
    local fightResBytes = result:GetFightsResultsBytes()
    XMVCA.XFuben:SetCurFightResult(result:GetFightResult())
    local settleData = result and result.Data
    if settleData then
        local stageId = settleData.StageId
        local stageType = self._Model:GetSoloReformStageCfg(stageId).StageType
        if stageType == 0 or not settleData.IsWin then
            XMVCA.XFuben:SettleFight(result)
            return
        end

        XNetwork.Call("FightSettleRequest", fightResBytes, function(res)
            local soloReformSettleResult = res.Settle.SoloReformSettleResult
            local passTime = soloReformSettleResult and soloReformSettleResult.PassTime or 0
            local isNew = soloReformSettleResult and soloReformSettleResult.IsNewRecord or true
            local score = soloReformSettleResult and soloReformSettleResult.Score or 0
            local scoreDetail = soloReformSettleResult and soloReformSettleResult.ScoreDetail or {}
            local scoreparams = {
                Score = score,
                ScoreDetail = scoreDetail
            }
            XLuaUiManager.Open("UiSoloReformKillSettlement", stageId, passTime, isNew, scoreparams, function()
                --战斗结算清除数据的判断依据
                XMVCA.XFuben:SetFubenSettleResult(res)
                XMVCA.XFuben:UpdateStageEventInfo()
                XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, res.Settle, res)
            end)
        end, true)
    end
end

--- 开始战斗前获取数据
function XSoloReformAgency:PreFight(stage, teamId, isAssist, challengeCount)
    self._RecodeCurBattleData = {
        StageId = stage.StageId,
        TeamId = teamId,
        IsAssist = isAssist,
        ChallengeCount = challengeCount
    }

    self.FightStageId = stage.StageId
    local preFight = {}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    preFight.CardIds = { 0, 0, 0 }
    preFight.RobotIds = { 0, 0, 0 }

    --强制机器人
    if not XTool.IsTableEmpty(stage.RobotId) then
        for index, id in pairs(stage.RobotId) do
            preFight.RobotIds[index] = id
        end
        preFight.CaptainPos = 1
        preFight.FirstFightPos = 1
        return preFight
    end

    --本地编队
    local team = self:GetTeam(self._CurEnterChapterId)
    preFight.CaptainPos = team:GetCaptainPos()
    preFight.FirstFightPos = team:GetFirstFightPos()

    for i, sourceId in pairs(team:GetEntityIds()) do
        if sourceId > 0 then
            if XRobotManager.CheckIsRobotId(sourceId) then
                preFight.RobotIds[i] = sourceId
            else
                preFight.CardIds[i] = sourceId
            end
        end
    end

    -- 效应
    if team.GetCurGeneralSkill then
        preFight.GeneralSkill = team:GetCurGeneralSkill()
    end
    return preFight
end

-- 退出战斗场景，战斗胜利，弹结算界面，占位不弹通用胜利
function XSoloReformAgency:ShowReward(data)
    local settleData = data and data.SettleData
    if settleData then
        local stageId = settleData.StageId
        local passTime = settleData.SoloReformSettleResult and settleData.SoloReformSettleResult.PassTime
        local isNew = settleData.SoloReformSettleResult and settleData.SoloReformSettleResult.IsNewRecord
        --local starNum = settleData.SoloReformSettleResult and settleData.SoloReformSettleResult.StarNum
        --self._Model:UpdateSoloStarState(stageId, starNum)
        --self._Model:UpdateChapterData(curChapterId, stageId, passTime)
        if data.SettleData.IsWin then
            local stageType = self._Model:GetSoloReformStageCfg(stageId).StageType
            if stageType == 0 then
                XLuaUiManager.Open("UiSoloReformSettlement", stageId, passTime, isNew)
            else
                CS.XFight.ExitForClient(true) --胜利结算退出战斗
            end
        else
            XMVCA.XFuben:ExitFight()
        end
    end
end

function XSoloReformAgency:SetEnterChapterId(chapterId)
    self._CurEnterChapterId = chapterId
end

function XSoloReformAgency:GetEnterChapterId()
    return self._CurEnterChapterId
end

function XSoloReformAgency:GetCurBattleData()
    return self._RecodeCurBattleData
end

function XSoloReformAgency:GetSoloReformChapterCfg(chapterId, notips)
    return self._Model:GetSoloReformChapterCfg(chapterId, notips)
end

function XSoloReformAgency:ExGetProgressTip()
    local curProcess, totalProcess = self._Model:GetCompletedTaskCountAndTotal()
    return XUiHelper.GetText("ActivityBossSingleProcess", curProcess, totalProcess)
end

function XSoloReformAgency:ExCheckIsShowRedPoint()
    return self:CheckMainReddot()
end

function XSoloReformAgency:GetAllShowChapterCfgs()
    return self._Model:GetAllShowChapterCfgs()
end

--region 蓝点

function XSoloReformAgency:CheckChapterReddot(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end
    local chapterCfg = self._Model:GetSoloReformChapterCfg(chapterId)
    local isUnlock = XFunctionManager.CheckInTimeByTimeId(chapterCfg.OpenTime, true)
    if not isUnlock then
        return false
    end
    return self._Model:CheckLocalChapterReddot(chapterId)
end

function XSoloReformAgency:CheckTaskReddot()
    local activityId = self._Model:GetActivityId()
    if not XTool.IsNumberValid(activityId) then
        return false
    end
    local soloReformCfg = self._Model:GetSoloReformCfg(activityId)
    if not soloReformCfg or XTool.IsTableEmpty(soloReformCfg.TaskIds) then
        return false
    end
    local taskDatas = XDataCenter.TaskManager.GetTaskIdListData(soloReformCfg.TaskIds, true)
    if XTool.IsTableEmpty(taskDatas) then
        return false
    end
    for _, taskData in pairs(taskDatas) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then --未领取标记蓝点
            return true
        end
    end
    return false
end

function XSoloReformAgency:CheckChallengeTaskReddot()
    local activityId = self._Model:GetActivityId()
    if not XTool.IsNumberValid(activityId) then
        return false
    end
    local soloReformCfg = self._Model:GetSoloReformCfg(activityId)
    if not soloReformCfg or XTool.IsTableEmpty(soloReformCfg.TaskGroupIds) then
        return false
    end
    for _, groupId in ipairs(soloReformCfg.TaskGroupIds) do
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, true)
        if XTool.IsTableEmpty(taskDataList) then
            return false
        end
        for _, taskData in pairs(taskDataList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then --未领取标记蓝点
                return true
            end
        end
    end

    return false
end

--独立蓝点，不影响上层
function XSoloReformAgency:CheckStrengthReddot(fightEventId, isUnlock)
    if not isUnlock then
        return false
    end

    return self._Model:CheckLocalStrengthReddot(fightEventId)
end

function XSoloReformAgency:CheckMainReddot()
    return XRedPointManager.CheckConditions(MainReddot)
end

--endregion
function XSoloReformAgency:IsKillStageUnlock(chapterId, stageId)
    local stageCfg = self._Model:GetSoloReformStageCfg(stageId)
    if not XTool.IsNumberValid(stageCfg.TitleUnlock) then
        return true
    end
    return self._Model:GetKillStageScore(chapterId, stageCfg.TitleUnlock)
end

function XSoloReformAgency:IsStageUnlock(chapterId, stageId)
    local curStageCfg = self._Model:GetSoloReformStageCfg(stageId)
    local difficulty = curStageCfg.Difficulty
    if not XTool.IsNumberValid(difficulty) then
        return false
    end
    if difficulty == 1 then
        return true
    end

    local stageData = self._Model:GetChapterStageData(chapterId)
    if not stageData or not XTool.IsNumberValid(stageData.PassStageId) then
        return false
    end
    local stageCfg = self._Model:GetSoloReformStageCfg(stageData.PassStageId)
    return difficulty <= stageCfg.Difficulty + 1
end

function XSoloReformAgency:GetSoloReformRankUpCastOnMission(stageId)
    return self._Model:GetSoloReformRankUpCfg(stageId).CastOnMission
end

function XSoloReformAgency:OnRelease()
    self._CurEnterChapterId = nil
    self._TeamDic = nil
end

return XSoloReformAgency
