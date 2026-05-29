
---@type XBigWorldQuestAgency
local XBigWorldQuestAgency = XClassPartial("XBigWorldQuestAgency")

--- 初始化枚举
--------------------------
function XBigWorldQuestAgency:InitEnum()
    self.QuestType = {
        All             = 0,--全部任务
        HeartWhisper    = 1,--心语任务
        Chronicle       = 2,--漫纪任务
        WindWhisper     = 3,--风闻任务
        Eden            = 4,--伊甸任务
        Invitation      = 5,--邀约任务
        Guidance        = 6,--引航任务
    }

    -- C# EQuestState
    self.QuestState = {
        --不活跃/未激活
        InActive = CS.EQuestState.InActive:GetHashCode(),
        --已激活未接取
        Ready = CS.EQuestState.Ready:GetHashCode(),
        --进行中
        InProgress = CS.EQuestState.InProgress:GetHashCode(),
        --已经完成
        Finished = CS.EQuestState.Finished:GetHashCode()
    }

    -- C# EQuestStepState
    self.StepState = {
        --不活跃/未激活
        Inactive = CS.EQuestStepState.InActive:GetHashCode(),
        --进行中
        InProgress = CS.EQuestStepState.InProgress:GetHashCode(),
        --完成
        Finished = CS.EQuestStepState.Finished:GetHashCode(),
    }

    -- C# EQuestObjectiveState
    self.ObjectiveState = {
        --不活跃/未激活
        InActive = 0,
        --内部Enter
        Enter = 1,
        --脚本正在执行进入环节
        ScriptEnter = 2,
        --进行中
        InProgress = 3,
        --内部Exit
        Exit = 4,
        --脚本正在退出进入环节
        ScriptExit = 5,
        --完成
        Finished = 6,
    }

    self.StepExecMode = {
        --线性执行下属objective
        Serial = 1,
        --并行执行下属objective
        Parallel = 2,
    }

    self.QuestOpType = {
        --弹窗展示
        PopupBegin = 1,
        --弹窗关闭
        PopupEnd = 2,
        --任务领取
        QuestReceive = 3,
        --任务追踪
        QuestTrack = 4,
        --任务取消追踪
        QuestUnTrack = 5,
        --任务完成
        QuestFinish = 6,
        --步骤激活
        StepActive = 7,
        --步骤完成
        StepFinish = 8,
        --流程激活
        ObjectiveActive = 9,
        --流程完成
        ObjectiveFinish = 10,
        --刷新流程
        ObjectiveRefresh = 11,
    }

    self.QuestCategory = {
        NormalQuest = 0, --普通任务
        InstLevelStoryQuest = 1, --剧情副本任务
        InstLevelPlayQuest = 2, --玩法副本任务
        LevelPlayQuest = 3, --常规关卡里的小玩法任务
        InviteQuest = 4, --好感度邀约任务(可重复完成、无完成奖励)
    }

    self.QuestShieldState = {
        --进入正常状态
        BackToNormal = 0,
        --进入副本状态
        IntoFuben = 1,
    }

    self.QuestItemType = {
        NormalItem = 1,
        SpineItem = 2,
        PhotoItem = 3,
        TextItem = 4,
    }

    self.ActionType = {
        PlayAnimation = 1,
        Timer = 2,
        Func = 3,
    }

    local CSEQuestObjectiveType = CS.StatusSyncFight.EQuestObjectiveType
    self.EQuestObjectiveType = {
        ReadShortMessageComplete = CSEQuestObjectiveType.ReadShortMessageComplete:GetHashCode(),
        ReachTargetPosition = CSEQuestObjectiveType.ReachTargetPosition:GetHashCode(),
        DeliverItems = CSEQuestObjectiveType.DeliverItems:GetHashCode(),
    }

    local CSEItemsDeliverType = CS.StatusSyncFight.EItemsDeliverType
    self.EItemsDeliverType = {
        --普通交付
        Normal = CSEItemsDeliverType.Normal:GetHashCode(),
        --手动交付
        Manual = CSEItemsDeliverType.Manual:GetHashCode(),
    }

    self.EQuestSkipToByFightState = {
        None = 0,
        NotExistMessage = 1,  -- 不存在目标短信
        ExistMessage = 2,  -- 存在目标短信
        SameAreaGroup = 3,  -- 当前位置与目标位置在相同区域
        DifferentAreaGroupSameLevel = 4, -- 当前位置同关卡不同区域
        DifferentLevel = 5, -- 与追踪目标不同关卡
        NotExistPin = 6,  -- 不存在图钉
        NotExistMap = 7, -- 不存在地图
        LevelInValid = 8, -- 场景无效
    }

    self._TempFinishedObjectiveUpdateData = {
        State = self.ObjectiveState.InActive,
        MaxProgress = 1,
        CurProgress = 1,
        ProgressType = 1,
    }
    
    self.InviteQuestType = {
        Normal = 1, --正常邀约任务
        Single2Multi = 2,  --单邀约选项解锁多结局
    }

    self._ReplaceHandler = function(key)
        local v = self.PatternKeyToValue[key]
        return v and tostring(v) or key
    end
end

--region Condition

-- 条件判断初始化
function XBigWorldQuestAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10101001, handler(self, self.ConditionCheckQuestFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101005, handler(self, self.ConditionCheckQuestInProgressAndReady))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101002, handler(self, self.ConditionCheckStepFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101003, handler(self, self.ConditionCheckObjectiveFinish))
    XMVCA.XBigWorldService:RegisterConditionFunc(10101007, handler(self, self.ConditionCheckInviteResultFinish))
end

function XBigWorldQuestAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101001)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101005)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101002)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101003)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101007)
end

--- 检查任务是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckQuestFinish(template)
    local params = template.Params
    local questId = params[1]
    return self:CheckQuestFinish(questId), template.Desc
end

--- 检查任务是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckQuestInProgressAndReady(template)
    local params = template.Params
    local questId = params[1]
    local isSuccess = self:CheckQuestInProgress(questId) or self:CheckQuestReady(questId)

    return isSuccess, template.Desc
end

--- 检查任务步骤是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckStepFinish(template)
    local params = template.Params
    local stepId = params[1]
    return self:CheckStepFinish(stepId), template.Desc
end

--- 检查到任务目标是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckObjectiveFinish(template)
    local params = template.Params
    local objectiveId = params[1]
    local questId = self._Model:GetQuestIdByObjectiveId(objectiveId)
    if not questId or questId <= 0 then
        XLog.Warning(string.format("此任务目标配置了无效QuestId, ObjectiveId = %s", objectiveId))
        return false, template.Desc
    end
    return self:CheckObjectiveFinish(questId, objectiveId), template.Desc
end

--- 检查到任务目标是否完成
---@param template XTableCondition
---@return boolean, string
function XBigWorldQuestAgency:ConditionCheckInviteResultFinish(template)
    local count = template.Params[1]
    local index = 2
    local sum = 0
    while true do
        local resultId = template.Params[index]
        if not resultId or resultId <= 0 then
            break
        end
        if self:CheckInviteResultFinish(resultId) then
            sum = sum + 1
        end
        index = index + 1
    end
    
    return sum >= count, template.Desc
end

function XBigWorldQuestAgency:CheckNormalQuestFinish(questId)
    return self._Model:CheckNormalQuestFinish(questId)
end

function XBigWorldQuestAgency:CheckInviteQuestNotInProgress(questId)
    return self._Model:CheckInviteQuestNotInProgress(questId)
end

function XBigWorldQuestAgency:CheckQuestFinish(questId)
    return self._Model:CheckQuestFinish(questId)
end

function XBigWorldQuestAgency:CheckQuestInProgress(questId)
    return self._Model:CheckQuestInProgress(questId)
end

function XBigWorldQuestAgency:CheckQuestReady(questId)
    return self._Model:CheckQuestReady(questId)
end

function XBigWorldQuestAgency:CheckStepFinish(stepId)
    local questId = self:GetQuestIdByStepId(stepId)
    if questId <= 0 then
        return false
    end

    if self._Model:CheckQuestFinish(questId) then
        return true
    end

    local questData = self:GetQuestData(questId)
    if not questData then
        return false
    end
    --任务已经完成
    if questData:IsFinish() then
        return true
    end
    local state = questData:GetState()
    --任务刚激活，还未领取
    if state == self.QuestState.Ready then
        return false
    end
    local stepData = questData:GetStep(stepId)
    if not stepData then
        return false
    end
    return stepData:IsFinish()
end

function XBigWorldQuestAgency:CheckObjectiveFinish(questId, objectiveId)
    if self._Model:CheckQuestFinish(questId) then
        return true
    end
    return self:CheckObjectiveFinishOnlyObjective(questId, objectiveId)
end

function XBigWorldQuestAgency:CheckObjectiveFinishOnlyObjective(questId, objectiveId)
    local questData = self:GetQuestData(questId)
    if not questData then
        return false
    end
    if questData:CheckObjectiveFinish(objectiveId) then
        return true
    end
    local objective = questData:GetObjective(objectiveId)
    return objective and objective:IsFinish() or false
end

--endregion Condition