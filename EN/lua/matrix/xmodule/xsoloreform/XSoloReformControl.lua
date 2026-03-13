---@class XSoloReformControl : XControl
---@field private _Model XSoloReformModel
local XSoloReformControl = XClass(XControl, "XSoloReformControl")

function XSoloReformControl:OnInit()
    self._ActivityEndCheckTimeId = nil
    self._ActivityTimeId = nil
end

function XSoloReformControl:AddAgencyEvent()
    
end

function XSoloReformControl:RemoveAgencyEvent()

end
function XSoloReformControl:GetSoloReformChapterCfg(chapterId, notips)
    return self._Model:GetSoloReformChapterCfg(chapterId, notips)
end

function XSoloReformControl:GetSoloReformStageCfg(stageId, notips)
    return self._Model:GetSoloReformStageCfg(stageId, notips)
end

function XSoloReformControl:GetSoloReformUnlockFightEvent(fightEventId, notips)
    return self._Model:GetSoloReformUnlockFightEvent(fightEventId, notips)
end

function XSoloReformControl:GetActivityCfg()
    local activityId = self._Model:GetActivityId()
    return self._Model:GetSoloReformCfg(activityId)
end

function XSoloReformControl:GetHelpString()
    local activityCfg = self:GetActivityCfg()
    return activityCfg.HelpName
end

--所有需要显示的关卡
function XSoloReformControl:GetAllShowChapterCfgs()
    return self._Model:GetAllShowChapterCfgs()
end

function XSoloReformControl:GetCompletedTaskCountAndTotal()
    return self._Model:GetCompletedTaskCountAndTotal()
end

--return 完成任务数，总任务数
function XSoloReformControl:GetChapterCompletedTaskCountAndTotal(chapterId)
   return self._Model:GetChapterCompletedTaskCountAndTotal(chapterId)
end

--stage星级任务的状态，0101 = false,true，false,true
function XSoloReformControl:GetStageStarStateByStageId(stageId)
    return self._Model:GetStageStarStateByStageId(stageId)    
end

function XSoloReformControl:GetChapterStageMinPassTimeStamp(chapterId)
    local stageData = self._Model:GetChapterStageData(chapterId)
    return stageData and stageData.MinPassTime
end

--最快通关时间
function XSoloReformControl:GetChapterStageMinPassTime(chapterId)
    local stageData = self._Model:GetChapterStageData(chapterId)
    if stageData and stageData.MinPassTime and stageData.MinPassTime > 0 then
        return XUiHelper.GetTime(stageData.MinPassTime)
    end       
end

function XSoloReformControl:GetChapterPassDifficulty(chapterId)
    local stageData = self._Model:GetChapterStageData(chapterId)
    if not stageData or not XTool.IsNumberValid(stageData.PassStageId) then
        return 0
    end
    local stageCfg = self._Model:GetSoloReformStageCfg(stageData.PassStageId)
    return stageCfg.Difficulty
end

function XSoloReformControl:IsStageUnlock(chapterId, difficulty)
    if difficulty == 1 then
        return true
    end    
    local passDifficulty = self:GetChapterPassDifficulty(chapterId)
    if not XTool.IsNumberValid(difficulty) then
        return false
    end    
    return difficulty <= passDifficulty + 1
end

function XSoloReformControl:GetShowRewardDatas()
    local activityCfg = self:GetActivityCfg()
    local rewardDatas = {}
    for _,itemId in ipairs(activityCfg.ShowRewardItemIds) do
        table.insert(rewardDatas, XRewardManager.CreateRewardGoods(itemId, 1))
    end
    return rewardDatas
end

function XSoloReformControl:GetChapterCharacterId(chapterId)
    local chapterCfg = self._Model:GetSoloReformChapterCfg(chapterId)
    if XTool.IsTableEmpty(chapterCfg.UseChara) then
        return
    end
    return chapterCfg.UseChara[1]  --默认取第一个
end

function XSoloReformControl:GetChapterRobotId(chapterId)
    local chapterCfg = self._Model:GetSoloReformChapterCfg(chapterId)
    if XTool.IsTableEmpty(chapterCfg.RobotData) then
        return
    end
    return chapterCfg.RobotData[1]  --默认取第一个
end

function XSoloReformControl:GetMaxDifficultyStageId(chapterId)
   return self._Model:GetMaxDifficultyStageId(chapterId)
end

function XSoloReformControl:GetSoloReformUnlockFightEventCfgs(chapterId)
    return self._Model:GetSoloReformUnlockFightEventCfgs(chapterId)
end

function XSoloReformControl:GetTaskDatas()
    local taskDatas = {}
    local activityCfg = self:GetActivityCfg()
    if not activityCfg or XTool.IsTableEmpty(activityCfg.TaskIds) then
        return taskDatas
    end    
    self._TaskDatas = XDataCenter.TaskManager.GetTaskIdListData(activityCfg.TaskIds, true)
    if XTool.IsTableEmpty(self._TaskDatas) then
        return taskDatas
    end
    
    for _, data in pairs(self._TaskDatas) do
        local taskData = {
            Id = data.Id,
            State = data.State,
            CurProcess = 0,
            TotalProcess = 0,
        }
        if not XTool.IsTableEmpty(data.Schedule) then
            taskData.CurProcess = data.Schedule[1].Value
            local conditionCfg = XTaskConfig.GetTaskCondition(data.Schedule[1].Id)
            taskData.TotalProcess = conditionCfg.Params[2]
            taskData.CurProcess = math.min(taskData.CurProcess, taskData.TotalProcess)
        end    
        --taskData.TotalProcess = XTaskConfig.GetProgress(data.Id)
        local rewardId = XTaskConfig.GetTaskRewardId(data.Id)
        taskData.RewardsList = XRewardManager.GetRewardList(rewardId)
        table.insert(taskDatas, taskData)
    end
    return taskDatas
end

function XSoloReformControl:GetChallengeTaskDatas()
    local taskDatas = {}
    local activityCfg = self:GetActivityCfg()
    if not activityCfg or XTool.IsTableEmpty(activityCfg.TaskGroupIds) then
        return taskDatas
    end
    for _, groupId in ipairs(activityCfg.TaskGroupIds) do
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, true)
        for _, data in pairs(taskDataList) do
            local taskData = {
                Id = data.Id,
                State = data.State,
                CurProcess = 0,
                TotalProcess = 0,
            }
            if not XTool.IsTableEmpty(data.Schedule) then
                taskData.CurProcess = data.Schedule[1].Value
                local conditionCfg = XTaskConfig.GetTaskCondition(data.Schedule[1].Id)
                taskData.TotalProcess = conditionCfg.Params[2]
                taskData.CurProcess = math.min(taskData.CurProcess, taskData.TotalProcess)
            end
            local rewardId = XTaskConfig.GetTaskRewardId(data.Id)
            taskData.RewardsList = XRewardManager.GetRewardList(rewardId)
            table.insert(taskDatas, taskData)
        end
    end

    return taskDatas
end

function XSoloReformControl:MarkLocalChapterReddot(chapterId)
    self._Model:MarkLocalChapterReddot(chapterId)
end

function XSoloReformControl:MarkLocalStrengthReddot(fightEventId)
    self._Model:MarkLocalStrengthReddot(fightEventId)
end

function XSoloReformControl:StartActivityEndCheckTimer()
    self:StopActivityEndCheckTimer()
    local activityCfg = self:GetActivityCfg()

    --活动关闭
    if not activityCfg then
        self:ActivityEnd()
        return
    end  
    self._ActivityTimeId = activityCfg.OpenTime

    --不在开启时间  
    if not XFunctionManager.CheckInTimeByTimeId(self._ActivityTimeId, true) then
        self:ActivityEnd()
        self._ActivityTimeId = nil
        return
    end
    
    --常驻
    local endTime = XFunctionManager.GetEndTimeByTimeId(self._ActivityTimeId)
    if endTime <= 0 then
        self._ActivityTimeId = nil
        return
    end    
    self._ActivityEndCheckTimeId = XScheduleManager.ScheduleForever(handler(self, self.UpdateActivityEndCheckTimer), XScheduleManager.SECOND)
end

function XSoloReformControl:UpdateActivityEndCheckTimer()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self._ActivityTimeId)
    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    if leftTime <= 0 then
        self:StopActivityEndCheckTimer()
        self:ActivityEnd()
    end
end

function XSoloReformControl:ActivityEnd()
    XLuaUiManager.RunMain()
end

function XSoloReformControl:StopActivityEndCheckTimer()
    if self._ActivityEndCheckTimeId then
        XScheduleManager.UnSchedule(self._ActivityEndCheckTimeId)
        self._ActivityEndCheckTimeId = nil
    end    
end

function XSoloReformControl:GetChapterStageStageType(stageId)
    local stageData = self._Model:GetSoloReformStageCfg(stageId)
    return stageData.StageType       
end


function XSoloReformControl:GetChapterByStageId(stageId)
    for _, chapterCfg in self._Model:GetAllSoloReformChapterCfgs() do
        if table.contains(chapterCfg.ChapterStageIds, stageId) then
            return chapterCfg
        end 
    end
    return nil
end

function XSoloReformControl:GetChapterPassStageId(chapterId)
    local stageData = self._Model:GetChapterStageData(chapterId)
    if not stageData or not XTool.IsNumberValid(stageData.PassStageId) then
        return 0
    end
    return stageData.PassStageId
end

function XSoloReformControl:GetKillStageScore(chapterId,stageId)
    return self._Model:GetKillStageScore(chapterId,stageId)
end

function XSoloReformControl:GetKillChapterMaxScore(chapterId)
    local chapterCfg = self:GetSoloReformChapterCfg(chapterId)
    local maxScore = nil
    for index, stageId in pairs(chapterCfg.ChapterStageIds) do
        local stageScore = self._Model:GetKillStageScore(chapterId, stageId)
        if stageScore and (not maxScore or stageScore > maxScore) then
            maxScore = stageScore
        end
    end
    return maxScore
end


function XSoloReformControl:GetScoreLevelIcon(score,difficulty)
    local cfg = self._Model:GetScoreLevelCfg(score,difficulty)
    if cfg then
        return cfg.LevelIcon
    end
    return nil
end

function XSoloReformControl:GetScoreDetail(id)
    local cfg = self._Model:GetSoloReformScoreCfg(id)
    return cfg and cfg.Desc or ""
end

function XSoloReformControl:OnRelease()
    self:StopActivityEndCheckTimer()
    self._ActivityEndCheckTimeId = nil
    self._ActivityTimeId = nil
end

return XSoloReformControl