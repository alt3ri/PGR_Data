local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")

---@class XBWCourseTaskProgressEntity : XBWCourseEntityBase
---@field private _ParentEntity XBWCourseContentEntity
local XBWCourseTaskProgressEntity = XClass(XBWCourseEntityBase, "XBWCourseTaskProgressEntity")

function XBWCourseTaskProgressEntity:OnInit(progressId)
    self:SetProgressId(progressId)
end

function XBWCourseTaskProgressEntity:IsNil()
    return not XTool.IsNumberValid(self:GetProgressId())
end

function XBWCourseTaskProgressEntity:IsAcquired()
    if not self:IsNil() then
        return self._Model:CheckTaskProgressRewardAcquired(self:GetVersionId(), self:GetProgressId())
    end

    return true
end

function XBWCourseTaskProgressEntity:IsComplete()
    if not self:IsNil() then
        return self:GetProgress() <=  self._ParentEntity:GetCurrentTaskProgress()
    end

    return false
end

function XBWCourseTaskProgressEntity:IsCompleteStateChange()
    if not self:IsNil() then
        local lastProgress = self._ParentEntity:GetRecordTaskProgress()
        local currentProgress = self._ParentEntity:GetCurrentTaskProgress()
        local progress = self:GetProgress()
        local isLastComplete = progress <= lastProgress
        local isCurrentComplete = self:IsComplete()
        
        return isLastComplete ~= isCurrentComplete
    end

    return false
end

function XBWCourseTaskProgressEntity:IsSpecial()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskProgressRewardIsSpecialById(self:GetProgressId())
    end

    return false
end

function XBWCourseTaskProgressEntity:SetProgressId(taskId)
    self._ProgressId = taskId or 0
end

function XBWCourseTaskProgressEntity:GetProgressId()
    return self._ProgressId
end

function XBWCourseTaskProgressEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseTaskProgressEntity:GetProgressIcon()
    return self._ParentEntity:GetTaskRewardIcon()
end

function XBWCourseTaskProgressEntity:GetProgressIconNoneColor()
    return self._ParentEntity:GetTaskRewardIconNoneColor()
end

function XBWCourseTaskProgressEntity:GetRewardId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskProgressRewardRewardIdById(self:GetProgressId())
    end

    return 0
end

function XBWCourseTaskProgressEntity:GetRewardList(isSort)
    local rewardId = self:GetRewardId()

    if not XTool.IsNumberValid(rewardId) then
        return {}
    end

    return XMVCA.XBigWorldService:GetRewardDataList(rewardId, isSort)
end

function XBWCourseTaskProgressEntity:GetProgress()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskProgressRewardProgressById(self:GetProgressId())
    end

    return 0
end

return XBWCourseTaskProgressEntity
