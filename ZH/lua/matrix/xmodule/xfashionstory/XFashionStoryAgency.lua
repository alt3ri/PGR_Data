local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XFashionStoryAgency : XFubenActivityAgency
---@field private _Model XFashionStoryModel
local XFashionStoryAgency = XClass(XFubenActivityAgency, "XFashionStoryAgency")

function XFashionStoryAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.FashionStory)

    -- 活动类型
    self.Type = {
        Both = 1, -- 具有章节关与试玩关
        OnlyChapter = 2, -- 只有章节关
        OnlyTrial = 3, -- 只有试玩关
    }

    -- 界面类型
    self.PrefabType = {
        Old = 1, --旧玩法界面
        Group = 2, --新玩法界面
    }

    -- 玩法模式
    self.Mode = {
        Chapter = 1, -- 章节关
        Trial = 2, -- 试玩关
    }

    --跳转功能
    self.FashionStorySkip = {
        SkipToStore = 1,   --跳转到外部商店
    }

    --奖励领取状态
    self.RewardState = {
        None       = 0, --无奖励配置(RewardTaskId 为空或 0)
        Locked     = 1, --奖励活动未到开启时间
        CanReceive = 3, --可领取(任务已达成、未领取)
        Received   = 4, --已领取
        Ended      = 5, --奖励活动已结束
    }

    --关卡未解锁原因
    self.TrialStageUnOpenReason = {
        OutOfTime = 0, --不在开放时间
        PreStageUnPass = 1, --前置关卡未通关
    }

    --关卡组（章节）未解锁原因
    self.GroupUnOpenReason = {
        OutOfTime = 0, --不在开放时间
        PreGroupUnPass = 1, --前置章节未通关
    }

    self.StoryEntranceId = 0

    --一组关卡最大数量（该参数受当期设定影响）
    self.StageCountInGroupUpperLimit = 2
end

function XFashionStoryAgency:InitRpc()
    XRpc.NotifyFashionStoryData = handler(self, self.NotifyFashionStoryData)
end

function XFashionStoryAgency:InitEvent()
end
local currentActivityId = nil
local StageGroupMap = {} --Key:StageId Value: SingleLineId
-------------------------------------------------------副本相关------------------------------------------------------

function XFashionStoryAgency:ShowReward(winData)
    if not winData then
        return
    end
    
    -- 旧的系统通关后没有做通关下发，依靠客户端自行更新，重登后才依赖服务端下推
    local stageId = winData.StageId
    XMVCA.XFuben:SetStagePassed(stageId)

    XLuaUiManager.Open("UiSettleWin", winData)
end
--------------------------------------------------------------------------------------------------------------------


---
--- 获取'id'系列涂装剧情活动的开始时间戳与结束时间戳
---@return number 开始时间戳|结束时间戳
function XFashionStoryAgency:GetActivityTime(id)
    local timeId = self._Model:GetActivityTimeId(id)
    return XFunctionManager.GetTimeByTimeId(timeId)
end

---
--- 获取系列涂装剧情活动
function XFashionStoryAgency:GetActivityChapters(noNeedInTime)
    local chapter = {}
    local currentId = self:GetCurrentActivityId()
    --判断活动类型
    table.insert(chapter, {
        Id = currentId,
        Type = XDataCenter.FubenManager.ChapterType.FashionStory,
    })

    return chapter
end

--- 分线id → 采购按钮是否应显示：按 SingleLine 表配置的 PurchaseTimeId(涂装售卖时间)判断
--- 未配置(nil/0)则视为不显示，避免无涂装售卖的前置分线误显示采购按钮
function XFashionStoryAgency:CheckSingleLinePurchaseInTime(singleLineId)
    local timeId = self._Model:GetSingleLinePurchaseTimeId(singleLineId)
    if not XTool.IsNumberValid(timeId) then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

---
--- 获取'id'活动中处于开放时间的试玩关
function XFashionStoryAgency:GetActiveTrialStage(id)
    local result = {}
    local trialStageList = self._Model:GetTrialStagesList(id)
    if trialStageList then
        for _, trialStage in ipairs(trialStageList) do
            if self:IsTrialStageInTime(trialStage) then
                table.insert(result, trialStage)
            end
        end
    end
    return result
end

---
--- 获取活动的类型
function XFashionStoryAgency:GetType(id)
    --2.6新表兼容旧逻辑
    local stageCount = 0
    local trialCount = 0

    local singleLineId = self._Model:GetFirstSingleLine(id)
    if singleLineId then
        stageCount = self._Model:GetSingleLineStagesCount(singleLineId)
    end
    trialCount = self._Model:GetFashionStoryTrialStageCount(id)
    if stageCount == 0 then
        return self.Type.OnlyTrial
    elseif trialCount == 0 then
        return self.Type.OnlyChapter
    else
        return self.Type.Both
    end
end

---
--- 获取活动章节关的关卡进度

function XFashionStoryAgency:GetChapterProgress(id)
    if self._Model:GetPrefabType(id) == self.PrefabType.Old then
        --旧版
        local stageIdList = self._Model:GetChapterStagesList(id)
        local passNum = 0
        local totalNum = #stageIdList

        for _, stageId in ipairs(stageIdList) do
            local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)
            if stageInfo.Passed then
                passNum = passNum + 1
            end
        end
        return passNum, totalNum
    else
        --新版
        local singleLineIds = self._Model:GetSingleLines(id)
        local groupPass = 0
        for i, singleLineId in ipairs(singleLineIds) do
            local stages = self._Model:GetSingleLineStages(singleLineId)
            local passNum = self:GetGroupStagesPassCount(stages)
            if passNum >= #stages then
                groupPass = groupPass + 1
            end
        end
        return groupPass, #singleLineIds
    end

end

---
--- 获取活动的剩余时间戳
function XFashionStoryAgency:GetLeftTimeStamp(id)
    local _, endTime = self:GetActivityTime(id)
    return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
end

---
--- 获取试玩关关卡剩余时间戳
function XFashionStoryAgency:GetTrialStageLeftTimeStamp(stageId)
    local timeId = self._Model:GetStageTimeId(stageId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
end

---
--- 获取剧情关入口的剩余时间戳
function XFashionStoryAgency:GetStoryTimeStamp(id)
    local timeId = self._Model:GetStoryTimeId(id)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    return endTime > 0 and endTime - XTime.GetServerNowTimestamp() or 0
end

---
--- 判断试玩关关卡是否处于开放时间，无时间配置默认不开放
function XFashionStoryAgency:IsTrialStageInTime(stageId)
    local stageTimeId = self._Model:GetStageTimeId(stageId)
    return XFunctionManager.CheckInTimeByTimeId(stageTimeId, false)
end

---
--- 打开活动主界面
function XFashionStoryAgency:OpenFashionStoryMain(activityId)
    currentActivityId = activityId
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FashionStory) then
        return
    end
    if self:IsActivityInTime(activityId) then
        if self:CheckIsGroupTypeActivity(activityId) then
            XLuaUiManager.Open("UiFubenFashionStoryNew")
        else
            XLuaUiManager.Open("UiFubenFashionStory", activityId, nil, self._Model:GetFirstSingleLine(activityId))
        end
    else
        XUiManager.TipMsg(CSXTextManagerGetText("FashionStoryActivityEnd"))
    end
end

---
--- 'activityId'是否处于开启时间
function XFashionStoryAgency:IsActivityInTime(activityId)
    local timeId = self._Model:GetActivityTimeId(activityId)
    return XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

---
--- 剧情模式入口是否处于开启时间
function XFashionStoryAgency:IsStoryInTime(activityId)
    --2.6兼容旧版逻辑
    local singleLineId = self._Model:GetFirstSingleLine(activityId)
    local timeId = self._Model:GetSingleLineTimeId(singleLineId)
    return XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

----------------------------------------------限时活动接口------------------------------------------------------------

function XFashionStoryAgency:ExGetProgressTip()
    local activeChapter = self:GetActivityChapters()
    -- 默认取第一个活动的Id
    -- 如果有多个活动同时开启，这里需要处理
    local curActivity = activeChapter[1].Id
    local passNum, totalNum = self:GetChapterProgress(curActivity)
    return XUiHelper.GetText("FashionStoryProcess", passNum, totalNum)
end

--------------------------------------------------------------------------------------------------------------------


--region 2.6 关卡分组的新逻辑

--初始化关卡-关卡组映射
function XFashionStoryAgency:InitStageGroupMap()
    if not XTool.IsTableEmpty(StageGroupMap) then
        return
    end
    --获取所有组
    local allSingleLines = self._Model:GetSingleLines(self:GetCurrentActivityId())
    for i, singleLineId in ipairs(allSingleLines) do
        local ChapterStages = self._Model:GetSingleLineStages(singleLineId)
        --遍历每个组的关卡
        for j, stage in ipairs(ChapterStages) do
            StageGroupMap[stage] = singleLineId
        end
    end
end

--确定当前活动是否是分组类型（不是则是原类型）
function XFashionStoryAgency:CheckIsGroupTypeActivity(activityId)
    local type = self._Model:GetPrefabType(activityId)
    return type == self.PrefabType.Group
end

--获取当期活动的Id
function XFashionStoryAgency:GetCurrentActivityId()
    if currentActivityId then
        return currentActivityId
    else
        local id = self._Model:GetActivityIdOpened()
        return id
    end
end

--获取传入的关卡组中完成的关卡的数量
function XFashionStoryAgency:GetGroupStagesPassCount(stages)
    local count = 0
    for i, stage in ipairs(stages) do
        if XMVCA.XFuben:CheckStageIsPass(stage) then
            count = count + 1
        end
    end
    return count
end

--判断当前关卡组是否在解锁时间内
function XFashionStoryAgency:CheckSingleLineIsInTime(singleLineId)
    local storyTimeId = self._Model:GetSingleLineTimeId(singleLineId)
    return XFunctionManager.CheckInTimeByTimeId(storyTimeId, false)
end

--判断指定关卡组是否可以解锁：关卡组本身解锁&第一关解锁
function XFashionStoryAgency:CheckGroupIsCanOpen(singleLineId)
    local lockReason = nil
    local firstStageOpen = false
    local firstStageUnOpenReason = nil

    local firstStageId = self._Model:GetSingleLineFirstStage(singleLineId)
    if firstStageId then
        firstStageOpen, firstStageUnOpenReason = self:CheckFashionStoryStageIsOpen(firstStageId)
    end

    local selfIsInTime = self:CheckSingleLineIsInTime(singleLineId)

    if not selfIsInTime then
        lockReason = self.GroupUnOpenReason.OutOfTime
    elseif firstStageOpen == false then
        if firstStageUnOpenReason == self.TrialStageUnOpenReason.OutOfTime then
            lockReason = self.GroupUnOpenReason.OutOfTime
        elseif firstStageUnOpenReason == self.TrialStageUnOpenReason.PreStageUnPass then
            lockReason = self.GroupUnOpenReason.PreGroupUnPass
        end
    end

    return selfIsInTime and firstStageOpen, lockReason
end

--获取当期活动的所有任务
function XFashionStoryAgency:GetCurrentAllTask(activityId)
    local taskLimitId = self._Model:GetTaskLimitId(activityId)
    local taskCfg = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
    local taskList = { }
    for _, taskId in ipairs(taskCfg.TaskId) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData then
            table.insert(taskList, taskData)
        end
    end

    XDataCenter.TaskManager.CommonTaskDataSort(taskList)
    return taskList
end

--获取当期活动的所有试玩关
--function XFashionStoryAgency:GetCurrentAllTrialStageData()
--    local idList = self._Model:GetFashionStoryTrialStages(self:GetCurrentActivityId())
--    -- ????
--end

--判断指定试玩关是否解锁
function XFashionStoryAgency:CheckFashionStoryStageIsOpen(trialId)
    local timeId = self._Model:GetStageTimeId(trialId)
    if timeId == 0 or XFunctionManager.CheckInTimeByTimeId(timeId, false) then
        local preStage = self._Model:GetPreStageId(trialId)
        if preStage == 0 or XDataCenter.FubenManager.CheckStageIsPass(preStage) then
            return true
        else
            return false, self.TrialStageUnOpenReason.PreStageUnPass
        end
    else
        return false, self.TrialStageUnOpenReason.OutOfTime
    end
end

--检查指定关卡组是否已查看过
function XFashionStoryAgency:CheckGroupHadAccess(singleLineId)
    local fullKey = self._Model:GetGroupNewFullKey(singleLineId)
    if XSaveTool.GetData(fullKey) then
        return true
    else
        return false
    end
end

function XFashionStoryAgency:MarkGroupAsHadAccess(singleLineId)
    local fullKey = self._Model:GetGroupNewFullKey(singleLineId)
    if not XSaveTool.GetData(fullKey) then
        XSaveTool.SaveData(fullKey, true)
    end
end

--检查是否存在关卡组未查看过
function XFashionStoryAgency:CheckIfAnyGroupUnAccess()
    local singleLines = self._Model:GetSingleLines(self:GetCurrentActivityId())
    if not XTool.IsTableEmpty(singleLines) then
        for i, singleLine in ipairs(singleLines) do
            --解锁&未查看过
            if XMVCA.XFashionStory:CheckGroupIsCanOpen(singleLine) and not self:CheckGroupHadAccess(singleLine) then
                return true
            end
        end
    end
    return false
end

function XFashionStoryAgency:GetPreSingleLineId(singleLineId)
    --获取第一个关卡
    local firstStage = self._Model:GetSingleLineFirstStage(singleLineId)
    --获取该关卡的前置关卡
    local preStage = self._Model:GetPreStageId(firstStage)

    if preStage then
        --读取组Id
        self:InitStageGroupMap()
        return StageGroupMap[preStage]
    end
end

--获取奖励活动入口的解锁 timeId
function XFashionStoryAgency:GetRewardActivityTimeId(activityId)
    return self._Model:GetRewardActivityTimeId(activityId)
end

--判断奖励活动入口是否已解锁
--@param timeId 可选，调用方已取到 timeId 时传入以复用，避免重复查表
function XFashionStoryAgency:IsRewardActivityUnlock(activityId, timeId)
    timeId = timeId or self:GetRewardActivityTimeId(activityId)
    return timeId and timeId > 0 and XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

function XFashionStoryAgency:GetLockTextByTimeId(timeId, beforeStartTextKey, afterEndTextKey)
    afterEndTextKey = afterEndTextKey or 'FashionStoryActivityEnd'
    local now = XTime.GetServerNowTimestamp()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    if now < startTime then
        local timeStr = XUiHelper.GetTime(startTime - now, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        return XUiHelper.GetText(beforeStartTextKey, timeStr)
    end
    return XUiHelper.GetText(afterEndTextKey)
end

function XFashionStoryAgency:GetTimeLockText(timeId)
    return self:GetLockTextByTimeId(timeId, 'FashionStoryUnlockAfterTime')
end

function XFashionStoryAgency:GetRewardActivityLockText(timeId)
    return self:GetLockTextByTimeId(timeId, 'FashionStoryRewardLock', 'FashionStoryRewardActivityEnd')
end

--获取奖励 RewardTaskId(0 表示该条目未配置奖励)
function XFashionStoryAgency:GetRewardTaskId(activityId)
    return self._Model:GetRewardTaskId(activityId) or 0
end

--获取奖励活动跳转 SkipId
function XFashionStoryAgency:GetRewardSkipId(activityId)
    return self._Model:GetRewardSkipId(activityId)
end

--判断奖励是否已领取
function XFashionStoryAgency:IsRewardReceived(activityId)
    local taskId = self:GetRewardTaskId(activityId)
    if taskId == 0 then return false end
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    return taskData and taskData.State == XDataCenter.TaskManager.TaskState.Finish
end

--获取奖励领取状态(供 UI 按钮、红点统一使用)
function XFashionStoryAgency:GetRewardClaimState(activityId)
    local taskId = self:GetRewardTaskId(activityId)
    local timeId = self:GetRewardActivityTimeId(activityId)
    if not self:IsRewardActivityUnlock(activityId, timeId) then
        -- 不在开放时间内需进一步区分"未开始"与"已结束"：
        -- CheckInTimeByTimeId 只判区间内外、不分方向，故此处用结束时间兜底判断
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        if timeId and timeId > 0 and endTime > 0 and XTime.GetServerNowTimestamp() >= endTime then
            return self.RewardState.Ended
        end
        return self.RewardState.Locked
    end
    if taskId == 0 then
        return self.RewardState.None
    end
    if self:IsRewardReceived(activityId) then
        return self.RewardState.Received
    end
    return self.RewardState.CanReceive
end

function XFashionStoryAgency:EnterPaintingGroupPanel(singleLineId, isOpen, lockReason, callback)
    if singleLineId then
        if isOpen then
            if callback then
                callback()
            else
                XLuaUiManager.Open("UiFubenFashionPaintingNew", singleLineId)
                XMVCA.XFashionStory:MarkGroupAsHadAccess(singleLineId)
            end
        else
            if lockReason == self.GroupUnOpenReason.OutOfTime then
                local timeId = self._Model:GetSingleLineTimeId(singleLineId)
                XUiManager.TipMsg(self:GetTimeLockText(timeId))
            elseif lockReason == self.GroupUnOpenReason.PreGroupUnPass then
                local preGroupId = XMVCA.XFashionStory:GetPreSingleLineId(singleLineId)
                if preGroupId then
                    XUiManager.TipText("FashionStoryGroupPassTip", nil, nil, self._Model:GetSingleLineName(preGroupId))
                end
            end
        end
    end
end
--endregion

function XFashionStoryAgency:NotifyFashionStoryData(stageList)
    if stageList and stageList.FinishStageList then
        for i, stageId in pairs(stageList.FinishStageList) do
            XMVCA.XFuben:SetStagePassed(stageId)
        end
    end
end

-- 下面是垃圾代码

function XFashionStoryAgency:GetAllFashionStoryId()
    return self._Model:GetAllFashionStoryId()
end

function XFashionStoryAgency:GetActivityTimeId(id)
    return self._Model:GetActivityTimeId(id)
end

function XFashionStoryAgency:GetTrialBg(id)
    return self._Model:GetTrialBg(id)
end

function XFashionStoryAgency:GetSkipIdList(id)
    return self._Model:GetSkipIdList(id)
end

function XFashionStoryAgency:GetTrialStagesList(id)
    return self._Model:GetTrialStagesList(id)
end

function XFashionStoryAgency:GetPrefabType(id)
    return self._Model:GetPrefabType(id)
end

function XFashionStoryAgency:GetSingleLines(id)
    return self._Model:GetSingleLines(id)
end

--获取singleline表中读取到的首个有效singlelineId：用于兼容旧玩法
function XFashionStoryAgency:GetFirstSingleLine(id)
    return self._Model:GetFirstSingleLine(id)
end

function XFashionStoryAgency:GetTaskLimitId(id)
    return self._Model:GetTaskLimitId(id)
end

function XFashionStoryAgency:GetFashionStorySkipId(activityId, id)
    return self._Model:GetFashionStorySkipId(activityId, id)
end

function XFashionStoryAgency:GetFashionStoryTrialStages(id)
    return self._Model:GetFashionStoryTrialStages(id)
end

function XFashionStoryAgency:GetFashionStoryTrialStageCount(id)
    return self._Model:GetFashionStoryTrialStageCount(id)
end

function XFashionStoryAgency:GetAllStoryStages(id)
    return self._Model:GetAllStoryStages(id)
end

function XFashionStoryAgency:GetAllStageId(id)
    return self._Model:GetAllStageId(id)
end
------------------------------------------------SingleLine.tab----------------------------------------------------------
function XFashionStoryAgency:GetSingleLineName(id)
    return self._Model:GetSingleLineName(id)
end

function XFashionStoryAgency:GetSingleLineFirstStage(id)
    return self._Model:GetSingleLineFirstStage(id)
end

function XFashionStoryAgency:GetSingleLineStages(id)
    return self._Model:GetSingleLineStages(id)
end

function XFashionStoryAgency:GetSingleLineStagesCount(id)
    return self._Model:GetSingleLineStagesCount(id)
end

function XFashionStoryAgency:GetSingleLineTimeId(id)
    return self._Model:GetSingleLineTimeId(id)
end

function XFashionStoryAgency:GetChapterPrefab(id)
    return self._Model:GetChapterPrefab(id)
end

function XFashionStoryAgency:GetChapterStoryStagePrefab(id)
    return self._Model:GetChapterStoryStagePrefab(id)
end

function XFashionStoryAgency:GetChapterFightStagePrefab(id)
    return self._Model:GetChapterFightStagePrefab(id)
end

function XFashionStoryAgency:GetStoryEntranceBg(id)
    return self._Model:GetStoryEntranceBg(id)
end

function XFashionStoryAgency:GetStoryEntranceFinishTag(id)
    return self._Model:GetStoryEntranceFinishTag(id)
end

function XFashionStoryAgency:GetSingleLineAsGroupStoryIcon(id)
    return self._Model:GetSingleLineAsGroupStoryIcon(id)
end

function XFashionStoryAgency:GetStoryDecorateIcon(id)
    return self._Model:GetStoryDecorateIcon(id)
end

function XFashionStoryAgency:GetSingleLineSummerFashionTitleImg(id)
    return self._Model:GetSingleLineSummerFashionTitleImg(id)
end

function XFashionStoryAgency:GetSingleLineChapterBg(id) 
    return self._Model:GetSingleLineChapterBg(id)
end

function XFashionStoryAgency:GetActivityBannerIcon(id)
    return self._Model:GetActivityBannerIcon(id)
end
------------------------------------------------FashionStoryStage.tab----------------------------------------------------------

function XFashionStoryAgency:GetStageTimeId(stageId)
    return self._Model:GetStageTimeId(stageId)
end

function XFashionStoryAgency:GetPreStageId(stageId)
    return self._Model:GetPreStageId(stageId)
end

function XFashionStoryAgency:GetStoryStageDetailBg(id)
    return self._Model:GetStoryStageDetailBg(id)
end

function XFashionStoryAgency:GetStoryStageDetailIcon(id)
    return self._Model:GetStoryStageDetailIcon(id)
end

function XFashionStoryAgency:GetTrialDetailBg(id)
    return self._Model:GetTrialDetailBg(id)
end

function XFashionStoryAgency:GetTrialDetailSpine(id)
    return self._Model:GetTrialDetailSpine(id)
end

function XFashionStoryAgency:GetTrialDetailHeadIcon(id)
    return self._Model:GetTrialDetailHeadIcon(id)
end

function XFashionStoryAgency:GetTrialDetailRecommendLevel(id)
    return self._Model:GetTrialDetailRecommendLevel(id)
end

function XFashionStoryAgency:GetTrialDetailDesc(id)
    return self._Model:GetTrialDetailDesc(id)
end

function XFashionStoryAgency:GetTrialFinishTag(id)
    return self._Model:GetTrialFinishTag(id)
end

function XFashionStoryAgency:GetStoryStageFace(id)
    return self._Model:GetStoryStageFace(id)
end

function XFashionStoryAgency:GetTrialFace(id)
    return self._Model:GetTrialFace(id)
end

function XFashionStoryAgency:GetTrialLockIcon(id)
    return self._Model:GetTrialLockIcon(id)
end

function XFashionStoryAgency:GetTrialImgName(id)
    return self._Model:GetTrialImgName(id)
end

----------------------------------------------FashionStoryTrialEntry.tab 入口表透传----------------------------------------------------------

function XFashionStoryAgency:GetAllTrialEntryStageIds()
    return self._Model:GetAllTrialEntryStageIds()
end

--判断试玩关是否解锁(基于 ExperimentLevel.tab 的 TimeId)
function XFashionStoryAgency:CheckTrialStageIsOpenByTimeId(stageId)
    local timeId = self:GetTrialStageTimeId(stageId)
    if not timeId or timeId == 0 or XFunctionManager.CheckInTimeByTimeId(timeId, false) then
        return true
    end
    return false, self.TrialStageUnOpenReason.OutOfTime
end

function XFashionStoryAgency:GetTrialStageTimeId(stageId)
    local trialLevel = XDataCenter.FubenExperimentManager.GetTrialLevelByStageId(stageId)
    return trialLevel and trialLevel.TimeId
end

function XFashionStoryAgency:GetEntryTrialFace(stageId)
    return self._Model:GetEntryTrialFace(stageId)
end

function XFashionStoryAgency:GetEntryTrialFinishTag(stageId)
    return self._Model:GetEntryTrialFinishTag(stageId)
end

function XFashionStoryAgency:GetEntryTrialLockIcon(stageId)
    return self._Model:GetEntryTrialLockIcon(stageId)
end

function XFashionStoryAgency:GetEntryTrialImgName(stageId)
    return self._Model:GetEntryTrialImgName(stageId)
end

return XFashionStoryAgency