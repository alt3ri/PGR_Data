local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")

---@class XBWCourseCoreElementEntity : XBWCourseEntityBase
---@field private _ParentEntity XBWCourseCoreEntity
local XBWCourseCoreElementEntity = XClass(XBWCourseEntityBase, "XBWCourseCoreElementEntity")

function XBWCourseCoreElementEntity:OnInit(elementId)
    self:SetElementId(elementId)
end

function XBWCourseCoreElementEntity:IsNil()
    return not XTool.IsNumberValid(self:GetElementId())
end

function XBWCourseCoreElementEntity:IsActivity()
    if not self:IsNil() then
        return self._ParentEntity:IsActivity()
    end

    return false
end

function XBWCourseCoreElementEntity:IsQuest()
    if not self:IsNil() then
        return self._ParentEntity:IsQuest()
    end

    return false
end

function XBWCourseCoreElementEntity:IsNew()
    if not self:IsNil() then
        return not self._Model:CheckCoreElementBrowsed(self:GetVersionId(), self:GetElementId())
    end

    return false
end

function XBWCourseCoreElementEntity:IsComplete()
    if not self:IsNil() then
        if self:IsActivity() then
            local agency = self:GetActivityAgency()

            if agency then
                return agency:IsComplete()
            end
        elseif self:IsQuest() then
            local questId = self:GetEntryId()

            if XTool.IsNumberValid(questId) then
                return XMVCA.XBigWorldQuest:CheckQuestFinish(questId)
            end
        end
    end

    return false
end

function XBWCourseCoreElementEntity:IsSkip()
    if self:IsQuest() then
        return not self:IsComplete() and XTool.IsNumberValid(self:GetCurrentSkipId())
    end

    return XTool.IsNumberValid(self:GetCurrentSkipId())
end

function XBWCourseCoreElementEntity:IsHaveTeach()
    local teachId = self:GetTeachId()

    return XTool.IsNumberValid(teachId) and XMVCA.XBigWorldTeach:CheckTeachUnlock(teachId)
end

function XBWCourseCoreElementEntity:IsLocked()
    if not self:IsNil() then
        local conditionIds = self._Model:GetBigWorldCourseCoreElementLockSkipConditionIdsById(self:GetElementId())

        if not XTool.IsTableEmpty(conditionIds) then
            for _, conditionId in pairs(conditionIds) do
                local isSuccess, text = XMVCA.XBigWorldService:CheckCondition(conditionId)

                if not isSuccess then
                    return true, text
                end
            end
        end

        if self:IsActivity() then
            local agency = self:GetActivityAgency()

            if agency and not agency:CheckInTime() then
                return true, agency:GetLockedTip()
            end
        end

        return false, ""
    end

    return true, ""
end

function XBWCourseCoreElementEntity:IsSkipStateChange()
    if not self:IsNil() then
        return (not self:IsLocked()) and self:IsSkip() and not self._Model:GetCoreElementRecord(self:GetElementId())
    end

    return false
end

function XBWCourseCoreElementEntity:SetElementId(elementId)
    self._ElementId = elementId or 0
end

function XBWCourseCoreElementEntity:GetElementId()
    return self._ElementId
end

function XBWCourseCoreElementEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseCoreElementEntity:GetName()
    if not self:IsNil() then
        if self:IsActivity() then
            local name = self._Model:GetBigWorldCourseCoreElementNameById(self:GetElementId())

            if not string.IsNilOrEmpty(name) then
                return name
            end

            local agency = self:GetActivityAgency()

            name = agency and agency:GetName() or nil
            if not string.IsNilOrEmpty(name) then
                return name
            end
        elseif self:IsQuest() then
            return self._Model:GetBigWorldCourseCoreElementNameById(self:GetElementId()) or ""
        end
    end

    return ""
end

function XBWCourseCoreElementEntity:GetRewards()
    if not self:IsNil() then
        local rewardId = self._Model:GetBigWorldCourseCoreElementDisplayRewardIdById(self:GetElementId())

        if XTool.IsNumberValid(rewardId) then
            return XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)
        end

        if self:IsActivity() then
            local agency = self:GetActivityAgency()
            local rewards = agency and agency:GetRewards() or nil

            if not XTool.IsTableEmpty(rewards) then
                return rewards
            end
        elseif self:IsQuest() then
            local questId = self:GetEntryId()

            if XTool.IsNumberValid(rewardId) then
                local rewardId = XMVCA.XBigWorldQuest:GetQuestRewardId(questId)

                if XTool.IsNumberValid(rewardId) then
                    return XMVCA.XBigWorldService:GetRewardDataList(rewardId)
                end
            end
        end
    end

    return nil
end

---@return table<string, string>
function XBWCourseCoreElementEntity:GetProgressTipData()
    if not self:IsNil() then
        if self:IsActivity() then
            local agency = self:GetActivityAgency()

            if agency then
                return agency:GetProgressTipData()
            end
        elseif self:IsQuest() then
            local questId = self:GetEntryId()

            if XTool.IsNumberValid(questId) then
                local title = XMVCA.XBigWorldService:GetText("BigWorldCourseCoreProgressTitle")
                local questText = XMVCA.XBigWorldQuest:GetQuestText(questId)
                local progress = XMVCA.XBigWorldService:GetText("BigWorldCourseCoreQuestProgress", questText)

                return {
                    [1] = {
                        Title = title,
                        Progress = progress,
                        IsComplete = self:IsComplete(),
                    },
                }
            end
        end
    end

    return nil
end

function XBWCourseCoreElementEntity:GetTeachId()
    if not self:IsNil() then
        if self:IsActivity() then
            local teachId = self._Model:GetBigWorldCourseCoreElementTeachIdById(self:GetElementId())

            if XTool.IsNumberValid(teachId) then
                return teachId
            end

            local agency = self:GetActivityAgency()

            if agency then
                return agency:GetTeachId() or 0
            end
        end
    end

    return 0
end

function XBWCourseCoreElementEntity:GetSkipId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementSkipIdById(self:GetElementId())
    end

    return 0
end

function XBWCourseCoreElementEntity:GetCurrentSkipId()
    if not self:IsNil() then
        local conditionIds = self:GetLockSkipConditionIds()
        local lockSkipIds = self:GetLockSkipIds()

        if not XTool.IsTableEmpty(conditionIds) then
            for i, conditionId in pairs(conditionIds) do
                if not XMVCA.XBigWorldService:CheckCondition(conditionId) then
                    return lockSkipIds[i] or 0
                end
            end
        end

        return self:GetSkipId()
    end

    return 0
end

function XBWCourseCoreElementEntity:GetLockSkipIds()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementLockSkipIdsById(self:GetElementId())
    end

    return 0
end

function XBWCourseCoreElementEntity:GetUnableSkipTip()
    if not self:IsNil() and self:IsLocked() then
        local conditionIds = self:GetLockSkipConditionIds()

        if not XTool.IsTableEmpty(conditionIds) then
            for _, conditionId in pairs(conditionIds) do
                local isSuccess, text = XMVCA.XBigWorldService:CheckCondition(conditionId)

                if not isSuccess and not string.IsNilOrEmpty(text) then
                    return text
                end
            end
        end
    end

    return XMVCA.XBigWorldService:GetText("BigWorldCourseCoreSkipUnableTip")
end

function XBWCourseCoreElementEntity:GetLockSkipConditionIds()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementLockSkipConditionIdsById(self:GetElementId())
    end

    return 0
end

function XBWCourseCoreElementEntity:GetBackground()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementBackgroundById(self:GetElementId())
    end

    return ""
end

function XBWCourseCoreElementEntity:GetEntryId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementEntryIdById(self:GetElementId())
    end

    return 0
end

---@return XBigWorldActivityAgency
function XBWCourseCoreElementEntity:GetActivityAgency()
    if self:IsActivity() then
        local entryId = self:GetEntryId()

        if XTool.IsNumberValid(entryId) then
            return XMVCA.XBigWorldGamePlay:GetActivityAgencyById(entryId)
        end
    end

    return nil
end

function XBWCourseCoreElementEntity:RecordSkipState()
    if not self:IsNil() then
        if self:IsSkip() then
            self._Model:SetCoreElementRecord(self:GetElementId())
        end
    end
end

return XBWCourseCoreElementEntity
