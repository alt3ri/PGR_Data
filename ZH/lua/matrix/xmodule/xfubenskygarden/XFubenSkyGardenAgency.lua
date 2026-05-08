local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")

---@class XFubenSkyGardenAgency : XFubenSimulationChallengeAgency
---@field private _Model XFubenSkyGardenModel
local XFubenSkyGardenAgency = XClass(XFubenSimulationChallengeAgency, "XFubenSkyGardenAgency")
function XFubenSkyGardenAgency:OnInit()
    self:RegisterChapterAgency()

    self.ExChapterType = self:ExGetChapterType()
end

function XFubenSkyGardenAgency:ResetAll()
    self:ClearProgressTip()
end

function XFubenSkyGardenAgency:OnRelease()
    self:ClearProgressTip()
end

function XFubenSkyGardenAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.SkyGarden
end

function XFubenSkyGardenAgency:ExGetRunningTimeStr()
    local timeId = self:GetTimeId()
    if self:ExGetIsLocked() or not timeId or timeId <= 0 then
        return ""
    end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if endTime <= 0 then
        return ""
    end

    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetText("ActivityEndLeftText",
        XUiHelper.GetTime(math.max(0, endTime - nowTime), XUiHelper.TimeFormatType.ACTIVITY))
end

function XFubenSkyGardenAgency:ExCheckInTime()
    local timeId = self:GetTimeId()
    if not timeId or timeId <= 0 then
        return true
    end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()

    return endTime <= 0 or endTime > nowTime
end

function XFubenSkyGardenAgency:ExGetIsLocked()
    local timeId = self:GetTimeId()
    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.SkyGarden) then
        return true
    end
    if not XFunctionManager.CheckInTimeByTimeId(timeId, true) then
        return true
    end
    return false
end

function XFubenSkyGardenAgency:ExGetLockTip()
    local timeId = self:GetTimeId()
    if timeId and timeId > 0 then
        local beginTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local nowTime = XTime.GetServerNowTimestamp()
        if beginTime > nowTime then
            return XUiHelper.GetText("ScheOpenCountdown",
                XUiHelper.GetTime(math.max(0, beginTime - nowTime), XUiHelper.TimeFormatType.ACTIVITY))
        end
    end

    if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.SkyGarden) then
        return XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.SkyGarden)
    end

    return ""
end

function XFubenSkyGardenAgency:ExCheckIsFinished(cb)
    local functionId = XFunctionManager.FunctionName.SkyGarden
    if not XFunctionManager.JudgeOpen(functionId) then
        if cb then cb(false) end
        return false
    end
    if cb then cb(true) end
    return true
end

function XFubenSkyGardenAgency:ExGetProgressTip()
    if not self._ProgressTip then
        local cur, total = XMVCA.XBigWorldCourse:GetCourseTotalTaskProgress()
        local progress = math.floor(cur / total * 100)
        self._ProgressTip = XUiHelper.GetText("SkyGardenProgressText", progress)
    end
    return self._ProgressTip
end

function XFubenSkyGardenAgency:GetTimeId()
    return XFunctionManager.GetFunctionTimeId(XFunctionManager.FunctionName.SkyGarden)
end

function XFubenSkyGardenAgency:ClearProgressTip()
    self._ProgressTip = false
end

function XFubenSkyGardenAgency:ExGetTimerShowStr()
    if not self:ExCheckInTimerShow() then
        return nil
    end

    local label = XMVCA.XFunction:GetEntryFunctionalLabel(XFunctionManager.FunctionName.SkyGarden)
    local taskIds = XMVCA.XFunction:GetEntryFunctionalTaskId(XFunctionManager.FunctionName.SkyGarden)

    if not XTool.IsTableEmpty(taskIds) then
        for i, taskId in pairs(taskIds) do
            if XTool.IsNumberValid(taskId) then
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

                if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved
                    or taskData.State == XDataCenter.TaskManager.TaskState.Accepted
                    or taskData.State == XDataCenter.TaskManager.TaskState.Active then
                    return label[i]
                end
            else
                return label[i]
            end
        end
    else
        return label[1]
    end

    return nil
end

function XFubenSkyGardenAgency:ExGetTimerShowIcon()
    if not self:ExCheckInTimerShow() then
        return nil
    end

    local icon = XMVCA.XFunction:GetEntryFunctionalIcon(XFunctionManager.FunctionName.SkyGarden)
    local taskIds = XMVCA.XFunction:GetEntryFunctionalTaskId(XFunctionManager.FunctionName.SkyGarden)

    if not XTool.IsTableEmpty(taskIds) then
        for i, taskId in pairs(taskIds) do
            if XTool.IsNumberValid(taskId) then
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

                if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved
                    or taskData.State == XDataCenter.TaskManager.TaskState.Accepted
                    or taskData.State == XDataCenter.TaskManager.TaskState.Active then
                    return icon[i]
                end
            else
                return icon[i]
            end
        end
    else
        return icon[1]
    end

    return nil
end

function XFubenSkyGardenAgency:ExCheckInTimerShow()
    local timeId = XMVCA.XFunction:GetEntryFunctionalLabelTimeId(XFunctionManager.FunctionName.SkyGarden)
    if not timeId or timeId <= 0 then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

return XFubenSkyGardenAgency
