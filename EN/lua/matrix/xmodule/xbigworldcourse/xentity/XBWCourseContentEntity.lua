local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")
local XBWCourseTaskEntity = require("XModule/XBigWorldCourse/XEntity/Task/XBWCourseTaskEntity")
local XBWCourseTaskProgressEntity = require("XModule/XBigWorldCourse/XEntity/Task/XBWCourseTaskProgressEntity")
local XBWCourseExploreEntity = require("XModule/XBigWorldCourse/XEntity/Explore/XBWCourseExploreEntity")
local XBWCourseCoreEntity = require("XModule/XBigWorldCourse/XEntity/Core/XBWCourseCoreEntity")

---@class XBWCourseContentEntity : XBWCourseEntityBase
---@field private _ParentEntity XBWCourseVersionEntity
local XBWCourseContentEntity = XClass(XBWCourseEntityBase, "XBWCourseContentEntity")

function XBWCourseContentEntity:OnInit(contentId)
    ---@type XBWCourseTaskEntity[]
    self._TaskEntitys = false
    ---@type XBWCourseTaskProgressEntity[]
    self._TaskProgressEntitys = false
    ---@type XBWCourseExploreEntity[]
    self._ExploreEntitys = false
    ---@type XBWCourseCoreEntity[]
    self._CoreEntitys = false

    self:SetContentId(contentId)
end

function XBWCourseContentEntity:IsNil()
    return not XTool.IsNumberValid(self:GetContentId())
end

function XBWCourseContentEntity:IsTask()
    return self:GetContentType() == XEnumConst.BWCourse.ContentType.Task
end

function XBWCourseContentEntity:IsExplore()
    return self:GetContentType() == XEnumConst.BWCourse.ContentType.Explore
end

function XBWCourseContentEntity:IsCore()
    return self:GetContentType() == XEnumConst.BWCourse.ContentType.Core
end

function XBWCourseContentEntity:IsAchieved()
    if self:IsTask() then
        return self:IsComplete()
    elseif self:IsExplore() then
        return not self:IsComplete() and self:GetExploreCurrentProgress() >= self:GetExploreTotalProgress()
    elseif self:IsCore() then
        return false
    end

    return false
end

function XBWCourseContentEntity:IsComplete()
    if self:IsTask() then
        return self:GetCurrentTaskProgress() >= self:GetMaxTaskProgress()
    elseif self:IsExplore() then
        return self._Model:CheckExploreContentRewardComplete(self:GetVersionId())
    elseif self:IsCore() then
        return true
    end

    return false
end

function XBWCourseContentEntity:IsUnlock()
    if self:IsTask() then
        return true
    elseif self:IsExplore() then
        return true
    elseif self:IsCore() then
        if self._CoreEntitys then
            return self._OwnControl:CheckCoreEntitysUnlock(self._CoreEntitys)
        end
    end

    return false
end

function XBWCourseContentEntity:SetContentId(contentId)
    self._ContentId = contentId or 0
    self:_Init()
end

function XBWCourseContentEntity:GetContentId()
    return self._ContentId
end

function XBWCourseContentEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseContentEntity:GetContentType()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseContentTypeByContentId(self:GetContentId())
    end

    return XEnumConst.BWCourse.ContentType.None
end

function XBWCourseContentEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseContentNameByContentId(self:GetContentId())
    end

    return ""
end

function XBWCourseContentEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseContentPriorityByContentId(self:GetContentId())
    end

    return 0
end

---@return XBWCourseTaskEntity[]
function XBWCourseContentEntity:GetTaskEntitys()
    return self._TaskEntitys or {}
end

---@return XBWCourseTaskEntity[]
function XBWCourseContentEntity:GetUnlockTaskEntitys()
    local taskEntitys = self:GetTaskEntitys()
    local result = {}

    if not XTool.IsTableEmpty(taskEntitys) then
        for _, taskEntity in pairs(taskEntitys) do
            if taskEntity:IsUnlock() then
                table.insert(result, taskEntity)
            end
        end

        table.sort(result, Handler(self, self._SortTaskEntity))
    end

    return result
end

---@return XBWCourseTaskProgressEntity[]
function XBWCourseContentEntity:GetTaskProgressEntitys()
    return self._TaskProgressEntitys or {}
end

function XBWCourseContentEntity:GetCurrentTaskProgress()
    if not self:IsNil() then
        return self._Model:GetCurrentTaskProgress(self._ParentEntity:GetVersionId())
    end

    return 0
end

function XBWCourseContentEntity:GetRecordTaskProgress()
    if not self:IsNil() then
        return self._OwnControl:GetCurrentRecordTaskProgress(self._ParentEntity:GetVersionId())
    end

    return 0
end

function XBWCourseContentEntity:GetMaxTaskProgress()
    local maxProgress = 0

    if not self:IsNil() then
        local progressEntitys = self:GetTaskProgressEntitys()

        if not XTool.IsTableEmpty(progressEntitys) then
            maxProgress = progressEntitys[#progressEntitys]:GetProgress()
        end
    end

    return maxProgress
end

function XBWCourseContentEntity:GetTaskRewardIcon()
    if not self:IsNil() then
        return self._OwnControl:GetTaskRewardItemIcon(self:GetContentId())
    end

    return ""
end

function XBWCourseContentEntity:GetTaskRewardIconNoneColor()
    if not self:IsNil() then
        return self._OwnControl:GetTaskRewardItemIconNoneColor(self:GetContentId())
    end

    return ""
end

function XBWCourseContentEntity:GetTaskPercentageProgress()
    local taskEntities = self:GetTaskEntitys()

    if not XTool.IsTableEmpty(taskEntities) then
        local finishCount = 0

        for _, taskEntity in pairs(taskEntities) do
            if taskEntity:IsAchieved() or taskEntity:IsFinish() then
                finishCount = finishCount + 1
            end
        end

        return (finishCount / #taskEntities) * 100
    end

    return 100
end

function XBWCourseContentEntity:GetBigWorldCourseContentBannerBg()
    if not self:IsNil() then
        return self._OwnControl:GetBigWorldCourseContentBannerBg(self:GetContentId())
    end

    return ""
end

function XBWCourseContentEntity:GetBigWorldCourseContentTip()
    if XTool.IsNumberValid(self:GetExploreRewardId()) then
        return self._OwnControl:GetBigWorldCourseContentTip(self:GetContentId())
    end

    return ""
end

---@return XBWCourseExploreEntity[]
function XBWCourseContentEntity:GetExploreEntitys()
    return self._ExploreEntitys or {}
end

function XBWCourseContentEntity:GetExploreEntitysWithSorting()
    local exploreEntitys = self:GetExploreEntitys()

    table.sort(exploreEntitys, Handler(self, self._SortExploreEntity))

    return exploreEntitys
end

function XBWCourseContentEntity:GetExploreTotalProgress()
    if not self:IsNil() then
        return self._OwnControl:GetExploreTotalProgress(self:GetContentId())
    end

    return 0
end

function XBWCourseContentEntity:GetExploreCurrentProgress()
    if not self:IsNil() then
        return self._OwnControl:GetExploreCurrentProgress(self:GetVersionId(), self:GetContentId())
    end

    return 0
end

function XBWCourseContentEntity:GetExploreProgressText()
    if not self:IsNil() then
        local currentProgress = self:GetExploreCurrentProgress()
        local totalProgress = self:GetExploreTotalProgress()

        return XMVCA.XBigWorldService:GetText("BigWorldCourseExploreProgress", currentProgress, totalProgress)
    end

    return ""
end

function XBWCourseContentEntity:GetExploreTitle()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseContentExploreTitleByContentId(self:GetContentId())
    end

    return 0
end

function XBWCourseContentEntity:GetExploreRewardId()
    if not self:IsNil() then
        return self._OwnControl:GetExploreRewardId(self:GetContentId())
    end

    return 0
end

function XBWCourseContentEntity:GetExploreRewardList()
    if not self:IsNil() then
        return self._OwnControl:GetExploreRewardList(self:GetContentId())
    end

    return 0
end

function XBWCourseContentEntity:GetExploreRewardIcon()
    if not self:IsNil() then
        return self._OwnControl:GetExploreRewardIcon(self:GetContentId())
    end

    return ""
end

---@return XBWCourseCoreEntity[]
function XBWCourseContentEntity:GetGetCoreEntitys()
    return self._CoreEntitys or {}
end

---@return table<number, XBWCourseCoreEntity[]>
function XBWCourseContentEntity:GetCoreEntitysGroupMap()
    local result = {}
    local coreEntitys = self:GetGetCoreEntitys()

    if not XTool.IsTableEmpty(coreEntitys) then
        for _, coreEntity in pairs(coreEntitys) do
            local groupId = coreEntity:GetGroupId()

            if not result[groupId] then
                result[groupId] = {}
            end

            table.insert(result[groupId], coreEntity)
        end
        for _, coreEntitys in pairs(result) do
            table.sort(coreEntitys, Handler(self, self._SortCoreEntity))
        end
    end

    return result
end

---@return table<number, XBWCourseCoreEntity[]>
function XBWCourseContentEntity:GetCoreEntitysGroupList()
    local result = {}
    local coreEntityGroupMap = self:GetCoreEntitysGroupMap()

    if not XTool.IsTableEmpty(coreEntityGroupMap) then
        for _, coreEntitys in pairs(coreEntityGroupMap) do
            table.insert(result, coreEntitys)
        end
        table.sort(result, Handler(self, self._SortCoresEntity))
    end

    return result
end

function XBWCourseContentEntity:_Init()
    if self:IsTask() then
        self:_InitTask()
    elseif self:IsExplore() then
        self:_InitExplore()
    elseif self:IsCore() then
        self:_InitCore()
    end
end

function XBWCourseContentEntity:_InitTask()
    self._TaskEntitys = {}
    self._TaskProgressEntitys = {}

    if not self:IsNil() then
        local contentId = self:GetContentId()
        local taskIds = self._OwnControl:GetTaskIdsByContentId(contentId)
        local progressIds = self._OwnControl:GetTaskProgressIdsByContentId(contentId)

        if not XTool.IsTableEmpty(taskIds) then
            for _, taskId in pairs(taskIds) do
                self:_AddTaskEntity(taskId)
            end
        end
        if not XTool.IsTableEmpty(progressIds) then
            for _, progressId in pairs(progressIds) do
                self:_AddTaskProgressEntity(progressId)
            end
        end
    end
end

function XBWCourseContentEntity:_InitExplore()
    self._ExploreEntitys = {}

    if not self:IsNil() then
        local contentId = self:GetContentId()
        local exploreIds = self._OwnControl:GetExploreIdsByContentId(contentId)

        if not XTool.IsTableEmpty(exploreIds) then
            for _, exploreId in pairs(exploreIds) do
                self:_AddExploreEntity(exploreId)
            end
        end
    end
end

function XBWCourseContentEntity:_InitCore()
    self._CoreEntitys = {}

    if not self:IsNil() then
        local contentId = self:GetContentId()
        local coreIds = self._OwnControl:GetCoreIdsByContentId(contentId)

        if not XTool.IsTableEmpty(coreIds) then
            for _, coreId in pairs(coreIds) do
                self:_AddCoreEntity(coreId)
            end
        end
    end
end

function XBWCourseContentEntity:_AddTaskEntity(taskId)
    table.insert(self._TaskEntitys, self:AddChildEntity(XBWCourseTaskEntity, taskId))
end

function XBWCourseContentEntity:_AddTaskProgressEntity(progressId)
    table.insert(self._TaskProgressEntitys, self:AddChildEntity(XBWCourseTaskProgressEntity, progressId))
end

function XBWCourseContentEntity:_AddExploreEntity(exploreId)
    table.insert(self._ExploreEntitys, self:AddChildEntity(XBWCourseExploreEntity, exploreId))
end

function XBWCourseContentEntity:_AddCoreEntity(coreId)
    table.insert(self._CoreEntitys, self:AddChildEntity(XBWCourseCoreEntity, coreId))
end

---@param taskA XBWCourseTaskEntity
---@param taskB XBWCourseTaskEntity
function XBWCourseContentEntity:_SortTaskEntity(taskA, taskB)
    local isTaskAchieveA = XMVCA.XBigWorldService:CheckTaskAchieved(taskA:GetTaskId())
    local isTaskAchieveB = XMVCA.XBigWorldService:CheckTaskAchieved(taskB:GetTaskId())

    if isTaskAchieveA ~= isTaskAchieveB then
        return isTaskAchieveA
    end

    local isTaskFinishA = XMVCA.XBigWorldService:CheckTaskFinish(taskA:GetTaskId())
    local isTaskFinishB = XMVCA.XBigWorldService:CheckTaskFinish(taskB:GetTaskId())

    if isTaskFinishA ~= isTaskFinishB then
        return not isTaskFinishA
    end

    return taskA:GetPriority() > taskB:GetPriority()
end

---@param exploreA XBWCourseExploreEntity
---@param exploreB XBWCourseExploreEntity
function XBWCourseContentEntity:_SortExploreEntity(exploreA, exploreB)
    local isAchieveA = exploreA:IsAchieved()
    local isAchieveB = exploreB:IsAchieved()

    if isAchieveA ~= isAchieveB then
        return isAchieveA
    end

    local isCompleteA = exploreA:IsComplete()
    local isCompleteB = exploreB:IsComplete()

    if isCompleteA ~= isCompleteB then
        return not isCompleteA
    end

    local priorityA = exploreA:GetPriority()
    local priorityB = exploreB:GetPriority()

    if priorityA ~= priorityB then
        return priorityA > priorityB
    end

    return exploreA:GetExploreId() > exploreB:GetExploreId()
end

---@param coreA XBWCourseCoreEntity
---@param coreB XBWCourseCoreEntity
function XBWCourseContentEntity:_SortCoreEntity(coreA, coreB)
    return coreA:GetPriority() > coreB:GetPriority()
end

---@param coresA XBWCourseCoreEntity[]
---@param coresB XBWCourseCoreEntity[]
function XBWCourseContentEntity:_SortCoresEntity(coresA, coresB)
    local isEmptyA = XTool.IsTableEmpty(coresA)
    local isEmptyB = XTool.IsTableEmpty(coresB)

    if isEmptyA and isEmptyB then
        local coreA = coresA[1]
        local coreB = coresB[1]

        return coreA:GetGroupPriority() > coreB:GetGroupPriority()
    end

    return isEmptyA
end

return XBWCourseContentEntity
