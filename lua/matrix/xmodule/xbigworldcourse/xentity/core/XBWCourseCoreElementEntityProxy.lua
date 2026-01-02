local CoreEntryType = XMVCA.XBigWorldCourse.CoreEntryType

---@class XBWCourseCoreElementEntityProxy : XEntity
---@field _Model XBigWorldCourseModel
---@field _OwnControl XBigWorldCourseControl
---@field _ParentEntity XBWCourseCoreElementEntity
local XBWCourseCoreElementEntityProxy = XClass(XEntity, "XBWCourseCoreElementEntityProxy")

function XBWCourseCoreElementEntityProxy:OnInit(elementId)
    self._ElementId = elementId
end

function XBWCourseCoreElementEntityProxy:IsSkip()
    local skipId = self._ParentEntity:GetCurrentSkipId()
    return XTool.IsNumberValid(skipId)
end

function XBWCourseCoreElementEntityProxy:IsComplete()
    return false
end

function XBWCourseCoreElementEntityProxy:IsLocked()
    local elementId = self._ElementId
    local res, desc = self:CheckCondition(elementId)
    return not res, desc
end

function XBWCourseCoreElementEntityProxy:CheckCondition()
    local elementId = self._ElementId
    if not elementId or elementId <= 0 then
        return true, ""
    end
    local conditionIds = self._Model:GetBigWorldCourseCoreElementLockSkipConditionIdsById(elementId)
    if XTool.IsTableEmpty(conditionIds) then
        return true, ""
    end
    for _, conditionId in pairs(conditionIds) do
        local isSuccess, text = XMVCA.XBigWorldService:CheckCondition(conditionId)

        if not isSuccess then
            return false, text
        end
    end
    return true, ""
end

function XBWCourseCoreElementEntityProxy:GetName()
    return self._Model:GetBigWorldCourseCoreElementNameById(self._ElementId)
end

function XBWCourseCoreElementEntityProxy:GetRewards()
    local rewardId = self._Model:GetBigWorldCourseCoreElementDisplayRewardIdById(self._ElementId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    return XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)
end

function XBWCourseCoreElementEntityProxy:GetProgressTipData()
end

function XBWCourseCoreElementEntityProxy:GetTeachId()
    return self._Model:GetBigWorldCourseCoreElementTeachIdById(self._ElementId)
end

function XBWCourseCoreElementEntityProxy:GetEntryIds()
    local elementId = self._ElementId
    if not elementId or elementId <= 0 then
        return
    end
    return self._Model:GetBigWorldCourseCoreElementEntryIdsById(self._ElementId)
end

function XBWCourseCoreElementEntityProxy:GetExtraItems()
end

function XBWCourseCoreElementEntityProxy:GetSkipBtnName()
    if not self._BtnSkipName then
        self._BtnSkipName = XMVCA.XBigWorldService:GetText("SkipTo")
    end
    return self._BtnSkipName
end

--region 活动代理

---@class XBWCourseCoreElementEntityActivityProxy : XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntityActivityProxy = XMVCA.XBigWorldCourse:AddCoreElementEntityProxy(CoreEntryType.Activity, 
        XBWCourseCoreElementEntityProxy, "XBWCourseCoreElementEntityActivityProxy")

---@return XBigWorldActivityAgency
function XBWCourseCoreElementEntityActivityProxy:GetActivityAgency()
    local entryIds = self:GetEntryIds()
    if XTool.IsTableEmpty(entryIds) then
        return
    end
    local activityId = entryIds[1]
    return XMVCA.XBigWorldGamePlay:GetActivityAgencyById(activityId)
end

function XBWCourseCoreElementEntityActivityProxy:IsComplete()
    local agency = self:GetActivityAgency()
    if not agency then
        return false
    end
    return agency:IsComplete()
end

function XBWCourseCoreElementEntityActivityProxy:IsLocked()
    local lock, desc =  XBWCourseCoreElementEntityProxy.IsLocked(self)
    if lock then
        return lock, desc
    end
    local agency = self:GetActivityAgency()
    if agency and not agency:CheckInTime() then
        return true, agency:GetLockedTip()
    end
    return false, ""
end

function XBWCourseCoreElementEntityActivityProxy:GetName()
    local name = XBWCourseCoreElementEntityProxy.GetName(self)
    if not string.IsNilOrEmpty(name) then
        return name
    end
    local agency = self:GetActivityAgency()
    if not agency then
        return "unknown"
    end
    return agency:GetName()
end

function XBWCourseCoreElementEntityActivityProxy:GetRewards()
    local rewards = XBWCourseCoreElementEntityProxy.GetRewards(self)
    if rewards then
        return rewards
    end
    local agency = self:GetActivityAgency()
    if not agency then
        return
    end
    return agency:GetRewards()
end

function XBWCourseCoreElementEntityActivityProxy:GetProgressTipData()
    local agency = self:GetActivityAgency()
    if not agency then
        return
    end
    return agency:GetProgressTipData()
end

function XBWCourseCoreElementEntityActivityProxy:GetTeachId()
    local teachId = XBWCourseCoreElementEntityProxy.GetTeachId(self)
    if teachId and teachId > 0 then
        return teachId
    end
    local agency = self:GetActivityAgency()
    if not agency then
        return 0
    end
    return agency:GetTeachId()
end

--endregion 活动代理

--region 好感任务代理

---@class XBWCourseCoreElementEntityFavorQuestProxy : XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntityFavorQuestProxy = XMVCA.XBigWorldCourse:AddCoreElementEntityProxy(CoreEntryType.FavorQuest,
        XBWCourseCoreElementEntityProxy, "XBWCourseCoreElementEntityFavorQuestProxy")

function XBWCourseCoreElementEntityFavorQuestProxy:OnInit(elementId)
    XBWCourseCoreElementEntityProxy.OnInit(self, elementId)
    local entryIds = self:GetEntryIds()
    self._QuestId = entryIds and entryIds[1] or 0
end

function XBWCourseCoreElementEntityFavorQuestProxy:IsSkip()
    return not self:IsComplete() and XBWCourseCoreElementEntityProxy.IsSkip(self)
end

function XBWCourseCoreElementEntityFavorQuestProxy:IsComplete()
    if self._QuestId and self._QuestId > 0 then
        return XMVCA.XBigWorldQuest:CheckQuestFinish(self._QuestId)
    end
    return false
end
function XBWCourseCoreElementEntityFavorQuestProxy:GetRewards()
    local rewards = XBWCourseCoreElementEntityProxy.GetRewards(self)
    if rewards then
        return rewards
    end
    if not self._QuestId or self._QuestId <= 0 then
        return 
    end
    return XMVCA.XBigWorldService:GetRewardDataList(XMVCA.XBigWorldQuest:GetQuestRewardId(self._QuestId))
end

function XBWCourseCoreElementEntityFavorQuestProxy:GetProgressTipData()
    if not self._QuestId or self._QuestId <= 0 then
        return
    end
    local title = XMVCA.XBigWorldService:GetText("BigWorldCourseCoreProgressTitle")
    local questText = XMVCA.XBigWorldQuest:GetQuestText(self._QuestId)
    local progress = XMVCA.XBigWorldService:GetText("BigWorldCourseCoreQuestProgress", questText)

    return {
        [1] = {
            Title = title,
            Progress = progress,
            IsComplete = self:IsComplete(),
        },
    }
end

--endregion 好感任务代理

--region 多任务代理

---@class XBWCourseCoreElementEntityMultiQuestProxy : XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntityMultiQuestProxy = XMVCA.XBigWorldCourse:AddCoreElementEntityProxy(CoreEntryType.CommonMultiQuest,
        XBWCourseCoreElementEntityProxy, "XBWCourseCoreElementEntityMultiQuestProxy")

function XBWCourseCoreElementEntityMultiQuestProxy:OnInit(elementId)
    XBWCourseCoreElementEntityProxy.OnInit(self, elementId)
    local entryIds = self:GetEntryIds()
    self._QuestIds = entryIds
end

function XBWCourseCoreElementEntityMultiQuestProxy:IsSkip()
    return not self:IsComplete() and XBWCourseCoreElementEntityProxy.IsSkip(self)
end

function XBWCourseCoreElementEntityMultiQuestProxy:IsComplete()
    if XTool.IsTableEmpty(self._QuestIds) then
        return true
    end
    for _, questId in ipairs(self._QuestIds) do
        if not XMVCA.XBigWorldQuest:CheckQuestFinish(questId) then
            return false
        end
    end
    return true
end

function XBWCourseCoreElementEntityMultiQuestProxy:GetProgressTipData()
    local cur, sum = 0, 0
    if not XTool.IsTableEmpty(self._QuestIds) then
        for _, questId in ipairs(self._QuestIds) do
            if XMVCA.XBigWorldQuest:CheckQuestFinish(questId) then
                cur = cur + 1
            end
            sum = sum + 1
        end
    end
    return {
        [1] = {
            Title = XMVCA.XBigWorldService:GetText("CourseCoreQuestProgressText", self:GetName()),
            Progress = string.format("%s/%s", cur, sum),
            IsComplete = self:IsComplete(),
        }
    }
end

--endregion 多任务代理

--region 单任务代理

---@class XBWCourseCoreElementEntitySingleQuestProxy : XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntitySingleQuestProxy = XMVCA.XBigWorldCourse:AddCoreElementEntityProxy(CoreEntryType.CommonSingleQuest,
        XBWCourseCoreElementEntityProxy, "XBWCourseCoreElementEntitySingleQuestProxy")

function XBWCourseCoreElementEntitySingleQuestProxy:OnInit(elementId)
    XBWCourseCoreElementEntityProxy.OnInit(self, elementId)
    local entryIds = self:GetEntryIds()
    self._QuestId = entryIds and entryIds[1] or 0
end

function XBWCourseCoreElementEntitySingleQuestProxy:IsSkip()
    return not self:IsComplete() and XBWCourseCoreElementEntityProxy.IsSkip(self)
end

function XBWCourseCoreElementEntitySingleQuestProxy:IsComplete()
    if self._QuestId and self._QuestId > 0 then
        return XMVCA.XBigWorldQuest:CheckQuestFinish(self._QuestId)
    end
    return false
end

function XBWCourseCoreElementEntitySingleQuestProxy:GetRewards()
    local rewards = XBWCourseCoreElementEntityProxy.GetRewards(self)
    if rewards then
        return rewards
    end
    if not self._QuestId or self._QuestId <= 0 then
        return
    end
    return XMVCA.XBigWorldService:GetRewardDataList(XMVCA.XBigWorldQuest:GetQuestRewardId(self._QuestId))
end

function XBWCourseCoreElementEntitySingleQuestProxy:GetProgressTipData()
    local complete = self:IsComplete()
    local cur, sum = complete and 1 or 0, 1
    return {
        [1] = {
            Title = XMVCA.XBigWorldService:GetText("CourseCoreQuestProgressText", self:GetName()),
            Progress = string.format("%s/%s", cur, sum),
            IsComplete = complete,
        }
    }
end

--endregion 单任务代理

--region 邀约任务代理

---@class XBWCourseCoreElementEntityInviteQuestProxy : XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntityInviteQuestProxy = XMVCA.XBigWorldCourse:AddCoreElementEntityProxy(CoreEntryType.InviteQuest,
        XBWCourseCoreElementEntityProxy, "XBWCourseCoreElementEntityInviteQuestProxy")

function XBWCourseCoreElementEntityInviteQuestProxy:OnInit(elementId)
    XBWCourseCoreElementEntityProxy.OnInit(self, elementId)
    self._QuestIds = self:GetEntryIds()
end

function XBWCourseCoreElementEntityInviteQuestProxy:IsComplete()
    local inviteIds = self._QuestIds
    if XTool.IsTableEmpty(inviteIds) then
        return true
    end
    for _, inviteId in ipairs(inviteIds) do
        if not XMVCA.XBigWorldQuest:CheckInviteFinish(inviteId) then
            return false
        end
    end
    return true
end

function XBWCourseCoreElementEntityInviteQuestProxy:GetAllInviteProgress()
    local inviteIds = self._QuestIds
    if XTool.IsTableEmpty(inviteIds) then
        return 0, 0
    end
    local finish, sum = 0, 0
    for _, inviteId in ipairs(inviteIds) do
        local resFinish, resSum = XMVCA.XBigWorldQuest:GetInviteProgress(inviteId)
        finish = finish + resFinish
        sum = sum + resSum
    end
    return finish, sum
end

function XBWCourseCoreElementEntityInviteQuestProxy:GetProgressTipData()
    local complete = self:IsComplete()
    local cur, sum = self:GetAllInviteProgress()
    return {
        [1] = {
            Title = XMVCA.XBigWorldService:GetText("InviteQuestFinishTotalText"),
            Progress = string.format("%s/%s", cur, sum),
            IsComplete = complete,
        }
    }
end

function XBWCourseCoreElementEntityInviteQuestProxy:GetExtraItems()
    return self:GetEntryIds()
end

--endregion 邀约任务代理

--region 环境任务代理

---@class XBWCourseCoreElementEntityEnvironmentQuestProxy : XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntityEnvironmentQuestProxy = XMVCA.XBigWorldCourse:AddCoreElementEntityProxy(CoreEntryType.EnvironmentQuest,
        XBWCourseCoreElementEntityProxy, "XBWCourseCoreElementEntityEnvironmentQuestProxy")

function XBWCourseCoreElementEntityEnvironmentQuestProxy:OnInit(elementId)
    XBWCourseCoreElementEntityProxy.OnInit(self, elementId)
    self._EnvironmentIds = self:GetEntryIds()
end

function XBWCourseCoreElementEntityEnvironmentQuestProxy:IsSkip()
    return true
end

function XBWCourseCoreElementEntityEnvironmentQuestProxy:IsComplete()
    local environmentIds = self._EnvironmentIds
    if XTool.IsTableEmpty(environmentIds) then
        return true
    end
    for _, id in ipairs(environmentIds) do
        if not XMVCA.XBigWorldQuest:CheckEnvironmentFinish(id) then
            return false
        end
    end
    return true
end

function XBWCourseCoreElementEntityEnvironmentQuestProxy:GetAllEnvironmentProgress()
    local environmentIds = self._EnvironmentIds
    if XTool.IsTableEmpty(environmentIds) then
        return 0, 0
    end
    local finish, sum = 0, 0
    for _, id in ipairs(environmentIds) do
        local resFinish, resSum = XMVCA.XBigWorldQuest:GetEnvironmentProgress(id)
        finish = finish + resFinish
        sum = sum + resSum
    end
    return finish, sum
end

function XBWCourseCoreElementEntityEnvironmentQuestProxy:GetProgressTipData()
    local cur, sum = self:GetAllEnvironmentProgress()
    return {
        [1] = {
            Title = XMVCA.XBigWorldService:GetText("EnvironmentQuestFinishTotalText"),
            Progress = string.format("%s/%s", cur, sum),
            IsComplete = cur == sum,
        }
    }
end

function XBWCourseCoreElementEntityEnvironmentQuestProxy:GetSkipBtnName()
    return XMVCA.XBigWorldService:GetText("ViewDetails")
end

--endregion 环境任务代理

