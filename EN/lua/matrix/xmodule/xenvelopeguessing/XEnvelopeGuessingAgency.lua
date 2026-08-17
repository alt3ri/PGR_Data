local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XEnvelopeGuessingAgency : XFubenActivityAgency
---@field private _Model XEnvelopeGuessingModel
local XEnvelopeGuessingAgency = XClass(XFubenActivityAgency, "XEnvelopeGuessingAgency")

local TableKey = {
    EnvelopeActivity = {},
}

function XEnvelopeGuessingAgency:OnInit()
    self:RegisterActivityAgency()
    self:InitConfigByTabKey("MiniActivity/Envelope", TableKey)

    self.TaskType = {
        Daily = {
            TitleText = "EnvelopeGuessingDailyTaskTitle",
            TaskGroupKey = "TaskDailyGroup",
            SubTitleText = "EnvelopeGuessingDailyTaskSubTitle",
            TaskButtonArchivedText = "EnvelopeGuessingTaskButtonTomorrowRefresh",
            Priority = 1
        },

        Normal = {
            TitleText = "EnvelopeGuessingNormalTaskTitle",
            TaskGroupKey = "TaskGroup",
            TaskButtonArchivedText = "EnvelopeGuessingTaskButtonArchived",
            Priority = 2
        }
    }
end

function XEnvelopeGuessingAgency:InitRpc()
    XRpc.NotifyEnvelope = handler(self, self.NotifyEnvelope)
end

--region 服务端信息更新
function XEnvelopeGuessingAgency:NotifyEnvelope(data)
    if not data then
        return
    end
    self._Model:OnNotifyEnvelope(data)
    XEventManager.DispatchEvent(XEventId.EVENT_ENVELOPE_UPDATE_DATA)
end
--endregion

--region 服务端请求
function XEnvelopeGuessingAgency:EnvelopeEnterRequest(cb)
    XNetwork.Call("EnvelopeEnterRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:OnEnvelopeEnterRequest(res)
        if cb then cb(res) end
    end)
end

function XEnvelopeGuessingAgency:EnvelopeRecordAvgRequest(characterId, cb)
    if self._Model:IsCharacterStoryWatched(characterId) then
        if cb then
            cb()
        end
        return
    end

    local request = {
        CharacterId = characterId,
    }
    XNetwork.Call("EnvelopeRecordAvgRequest", request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:OnCharacterStoryWatched(characterId)
        if cb then
            cb()
        end
    end)
end
--endregion

--region 通用
function XEnvelopeGuessingAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Envelope, false, noTips) then
        return false
    end
    if not self._Model:IsActivityOpen() or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XEnvelopeGuessingAgency:OpenMainUi()
    if not self:GetIsOpen() then
        return false
    end
    self:EnvelopeEnterRequest(function(res)
        XLuaUiManager.Open("UiEnvelopeGuessingMain", res.RewardGoodsList, res.TaskRewardGoodsList)
    end)
    return true
end
--endregion

--region 副本扩展入口
function XEnvelopeGuessingAgency:ExCheckInTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end
--endregion

--region 活动表相关
---@return XTableEnvelopeActivity
function XEnvelopeGuessingAgency:GetActivityConfig()
    if not self._Model:IsActivityOpen() then
        return nil
    end
    local activityId = self._Model:GetActivityId()
    return self:GetConfigByTabKeyAndIdKey(TableKey.EnvelopeActivity, activityId)
end

function XEnvelopeGuessingAgency:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

function XEnvelopeGuessingAgency:GetActivityEndTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XEnvelopeGuessingAgency:GetActivityTaskIds(taskType)
    local config = self:GetActivityConfig()
    if not config then
        return {}
    end
    local taskGroupId = config[taskType.TaskGroupKey]
    return XTaskConfig.GetTaskIdsByGroupId(taskGroupId)
end
--endregion

--region 红点相关
function XEnvelopeGuessingAgency:HasDailyReward()
    return self._Model:HasDailyReward()
end

function XEnvelopeGuessingAgency:HasAnyAchievedTask()
    -- 已获得的开包券总量（已开启信封数+持有券数）达上限时，不再由每日任务产生蓝点
    local skipDailyTask = self:IsTicketItemReachLimit()

    for _, taskType in pairs(self.TaskType) do
        if not (skipDailyTask and taskType == self.TaskType.Daily) then
            local taskIds = self:GetActivityTaskIds(taskType)
            for _, taskId in pairs(taskIds) do
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
                if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
            end
        end
    end
    return false
end

-- 检查已开启信封数与持有开包券数之和是否达到每日任务蓝点的屏蔽上限
function XEnvelopeGuessingAgency:IsTicketItemReachLimit()
    local limit = CS.XGame.ClientConfig:GetInt("EnvelopeGuessingDailyTaskTicketLimit")
    if not XTool.IsNumberValid(limit) then
        return false
    end

    local config = self:GetActivityConfig()
    if not config then
        return false
    end

    local openedCount = self._Model:GetOpenedCharacterCount()
    local ticketCount = XDataCenter.ItemManager.GetCount(config.TicketItemId)
    return openedCount + ticketCount >= limit
end
--endregion

--region 条件相关
-- 检查已开启的信封数量是否达到目标数量
function XEnvelopeGuessingAgency:CheckOpenEnvelopeCount(targetCount)
    if not self._Model:IsActivityOpen() then
        return false
    end
    local openCount = self._Model:GetOpenedCharacterCount()
    return openCount >= targetCount
end
--endregion

return XEnvelopeGuessingAgency
