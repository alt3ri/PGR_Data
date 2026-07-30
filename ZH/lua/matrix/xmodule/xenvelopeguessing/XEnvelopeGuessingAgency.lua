local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XEnvelopeGuessingAgency : XFubenActivityAgency
---@field private _Model XEnvelopeGuessingModel

local XEnvelopeGuessingAgency = XClass(XFubenActivityAgency, "XEnvelopeGuessingAgency")

XTool.ExportMemberMethods(XEnvelopeGuessingAgency, "_Model", {
    "HasDailyReward"
})

local TableKey = {
    EnvelopeActivity = {
        DirPath = XConfigUtil.DirectoryType.Share,
        CacheType= XConfigUtil.CacheType.Temp
    }
}

XEnvelopeGuessingAgency.TaskType = {
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

XEnvelopeGuessingAgency.EventIds = {
    EVENT_ON_NOTIFY_ENVELOPE = "EVENT_ON_NOTIFY_ENVELOPE"
}

function XEnvelopeGuessingAgency:OnInit()
    self:RegisterActivityAgency()
    self:InitConfigByTabKey("MiniActivity/Envelope", TableKey)
end

function XEnvelopeGuessingAgency:InitRpc()
    XRpc.NotifyEnvelope = function(data)
        self._Model:OnNotifyEnvelope(data)
        self:DispatchEvent(self.EventIds.EVENT_ON_NOTIFY_ENVELOPE, data)
    end
end

function XEnvelopeGuessingAgency:_ReleaseCache()
    self._ActivityConfigCache = nil
end

function XEnvelopeGuessingAgency:ResetAll()
    self:_ReleaseCache()
end

function XEnvelopeGuessingAgency:OnRelease()
    self:_ReleaseCache()
end

-- 返回nil表示没有开启活动
function XEnvelopeGuessingAgency:GetCurrentActivity()
    local activityId = self._Model:GetActivityId()

    if activityId == 0 then
        self:_ReleaseCache()
        return nil
    end

    local conf = self._ActivityConfigCache
    if conf and conf.Id == activityId then return conf end

    conf = self:GetConfigByTabKeyAndIdKey(TableKey.EnvelopeActivity, activityId)
    assert(conf)
    self._ActivityConfigCache = conf

    return conf
end

function XEnvelopeGuessingAgency:MarkCharacterStoryHasWatched(characterId, cbOnSuccess)
    if self._Model:IsCharacterStoryWatched(characterId) then
        if cbOnSuccess then
            cbOnSuccess()
        end
        return
    end
    XNetwork.Call("EnvelopeRecordAvgRequest", { CharacterId = characterId }, function(data)
        if data.Code ~= XCode.Success then
            XUiManager.TipCode(data.Code)
            return
        end

        self._Model:OnCharacterStoryWatched(characterId)
        if cbOnSuccess then
            cbOnSuccess()
        end
    end)
end

function XEnvelopeGuessingAgency:GetTaskIds(taskType)
    local activityConf = self:GetCurrentActivity()
    local taskGroupId = activityConf[taskType.TaskGroupKey]
    return XTaskConfig.GetTaskIdsByGroupId(taskGroupId)
end

function XEnvelopeGuessingAgency:HasAnyAchievedTask()
    for _, taskType in pairs(self.TaskType) do
        for _, taskId in pairs(self:GetTaskIds(taskType)) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end

    return false
end

return XEnvelopeGuessingAgency
