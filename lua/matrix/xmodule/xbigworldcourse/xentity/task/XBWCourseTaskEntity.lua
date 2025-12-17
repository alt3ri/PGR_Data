local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")

---@class XBWCourseTaskEntity : XBWCourseEntityBase
local XBWCourseTaskEntity = XClass(XBWCourseEntityBase, "XBWCourseTaskEntity")

function XBWCourseTaskEntity:OnInit(taskId)
    self:SetTaskId(taskId)
end

function XBWCourseTaskEntity:IsNil()
    return not XTool.IsNumberValid(self:GetTaskId())
end

function XBWCourseTaskEntity:IsActive()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:CheckTaskActive(self:GetTaskId())
    end

    return false
end

function XBWCourseTaskEntity:IsAchieved()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:CheckTaskAchieved(self:GetTaskId())
    end

    return false
end

function XBWCourseTaskEntity:IsFinish()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:CheckTaskFinish(self:GetTaskId())
    end

    return false
end

function XBWCourseTaskEntity:IsSkip()
    if not self:IsNil() then
        local conditionId = self:GetConditionId()

        if XTool.IsNumberValid(conditionId) then
            if not XMVCA.XBigWorldService:CheckCondition(conditionId) then
                return false
            end
        end

        local skipId = self:GetSkipId()

        return XTool.IsNumberValid(skipId)
    end

    return false
end

function XBWCourseTaskEntity:IsUnlock()
    if not self:IsNil() then
        return self._Model:CheckTaskUnlock(self:GetTaskId())
    end

    return false
end

function XBWCourseTaskEntity:IsNew()
    if not self:IsNil() then
        return not self._Model:GetTaskRecord(self:GetTaskId())
    end

    return false
end

function XBWCourseTaskEntity:SetTaskId(taskId)
    self._TaskId = taskId or 0
end

function XBWCourseTaskEntity:GetTaskId()
    return self._TaskId
end

function XBWCourseTaskEntity:GetTitle()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskTitleByTaskId(self:GetTaskId())
    end

    return ""
end

function XBWCourseTaskEntity:GetDescription()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:GetTaskDescriptionByTaskId(self:GetTaskId())
    end

    return ""
end

function XBWCourseTaskEntity:GetResult()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:GetTaskResultByTaskId(self:GetTaskId())
    end

    return 0
end

function XBWCourseTaskEntity:GetPriority()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:GetTaskPriorityByTaskId(self:GetTaskId())
    end

    return 0
end

function XBWCourseTaskEntity:GetRewardId()
    if not self:IsNil() then
        return XMVCA.XBigWorldService:GetTaskRewardIdByTaskId(self:GetTaskId())
    end

    return 0
end

function XBWCourseTaskEntity:GetConditionId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskConditionIdByTaskId(self:GetTaskId())
    end

    return 0
end

function XBWCourseTaskEntity:GetSkipId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskSkipIdByTaskId(self:GetTaskId())
    end

    return 0
end

function XBWCourseTaskEntity:GetProgress()
    if not self:IsNil() then
        local taskData = XMVCA.XBigWorldService:GetTaskDataByTaskId(self:GetTaskId())
        
        if taskData then
            local progress = taskData.Schedule

            if progress then
                for key, value in pairs(progress) do
                    return value.Value
                end
            end
        end
    end

    return 0
end

function XBWCourseTaskEntity:GetDisplayRewardData()
    if not self:IsNil() then
        local rewardId = self:GetRewardId()
        local rewardList = XMVCA.XBigWorldService:GetRewardDataList(rewardId)

        if not XTool.IsTableEmpty(rewardList) then
            local rewardData = rewardList[1]
            local templateId = rewardData.TemplateId
            local count = rewardData.Count
            local icon = XMVCA.XBigWorldService:GetGoodsIconByTemplateId(templateId)
            local countText = ""

            if XTool.IsNumberValid(count) then
                countText = tostring(count)
            end

            return {
                Icon = icon,
                Count = countText,
            }
        end
    end

    return nil
end

function XBWCourseTaskEntity:GetProgressText()
    if not self:IsNil() then
        local progress = self:GetProgress()
        local result = self:GetResult()
        
        return tostring(progress) .. "/" .. tostring(result)
    end

    return ""
end

function XBWCourseTaskEntity:GetUnlockText()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseTaskUnlockTextByTaskId(self:GetTaskId())
    end

    return ""
end

function XBWCourseTaskEntity:Record()
    if not self:IsNil() then
        self._Model:SetTaskRecord(self:GetTaskId())
    end
end

return XBWCourseTaskEntity
