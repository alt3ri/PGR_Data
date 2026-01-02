---@class XBigWorldCourseConfigModel : XModel
local XBigWorldCourseConfigModel = XClass(XModel, "XBigWorldCourseConfigModel")

local CourseTableKey = {
    BigWorldCourseTask = {
        Identifier = "TaskId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseTaskProgressReward = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseContent = {
        Identifier = "ContentId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseVersion = {
        Identifier = "VersionId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseExplore = {
        Identifier = "ExploreId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseExplorePoi = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseCore = {
        Identifier = "CoreId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldCourseCoreElement = {},
    BigWorldCourseCoreGroup = {
        Identifier = "GroupId",
    },
}

function XBigWorldCourseConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Course", CourseTableKey)
end

---@return XTableBigWorldCourseTask[]
function XBigWorldCourseConfigModel:GetBigWorldCourseTaskConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseTask) or {}
end

---@return XTableBigWorldCourseTask
function XBigWorldCourseConfigModel:GetBigWorldCourseTaskConfigByTaskId(taskId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseTask, taskId, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskContentIdByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.ContentId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskUnlockTypeByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.UnlockType
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskUnlockParamsByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.UnlockParams
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskConditionIdByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.ConditionId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskTitleByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.Title
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskUnlockTextByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.UnlockText
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskSkipIdByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.SkipId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskTimeIdByTaskId(taskId)
    local config = self:GetBigWorldCourseTaskConfigByTaskId(taskId)

    return config.TimeId
end

---@return XTableBigWorldCourseTaskProgressReward[]
function XBigWorldCourseConfigModel:GetBigWorldCourseTaskProgressRewardConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseTaskProgressReward) or {}
end

---@return XTableBigWorldCourseTaskProgressReward
function XBigWorldCourseConfigModel:GetBigWorldCourseTaskProgressRewardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseTaskProgressReward, id, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskProgressRewardContentIdById(id)
    local config = self:GetBigWorldCourseTaskProgressRewardConfigById(id)

    return config.ContentId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskProgressRewardProgressById(id)
    local config = self:GetBigWorldCourseTaskProgressRewardConfigById(id)

    return config.Progress
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskProgressRewardIsSpecialById(id)
    local config = self:GetBigWorldCourseTaskProgressRewardConfigById(id)

    return config.IsSpecial
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTaskProgressRewardRewardIdById(id)
    local config = self:GetBigWorldCourseTaskProgressRewardConfigById(id)

    return config.RewardId
end

---@return XTableBigWorldCourseContent[]
function XBigWorldCourseConfigModel:GetBigWorldCourseContentConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseContent) or {}
end

---@return XTableBigWorldCourseContent
function XBigWorldCourseConfigModel:GetBigWorldCourseContentConfigByContentId(contentId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseContent, contentId, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentNameByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.Name
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentPriorityByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.Priority
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentTypeByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.ContentType
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentTaskProgressItemIdByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.TaskProgressItemId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentTaskProgressItemIconByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.TaskProgressItemIcon
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentBannerBgByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.BannerBg
end

function XBigWorldCourseConfigModel:GetBigWorldCourseContentExploreRewardIdByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.ExploreRewardId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseTypeConditionIdsByContentId(contentId)
    local config = self:GetBigWorldCourseContentConfigByContentId(contentId)

    return config.ConditionIds
end

---@return XTableBigWorldCourseVersion[]
function XBigWorldCourseConfigModel:GetBigWorldCourseVersionConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseVersion) or {}
end

---@return XTableBigWorldCourseVersion
function XBigWorldCourseConfigModel:GetBigWorldCourseVersionConfigByVersionId(versionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseVersion, versionId, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseVersionNameByVersionId(versionId)
    local config = self:GetBigWorldCourseVersionConfigByVersionId(versionId)

    return config.Name
end

function XBigWorldCourseConfigModel:GetBigWorldCourseVersionContentIdsByVersionId(versionId)
    local config = self:GetBigWorldCourseVersionConfigByVersionId(versionId)

    return config.ContentIds
end

function XBigWorldCourseConfigModel:GetBigWorldCourseVersionTimeIdByVersionId(versionId)
    local config = self:GetBigWorldCourseVersionConfigByVersionId(versionId)

    return config.TimeId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseVersionConditionIdByVersionId(versionId)
    local config = self:GetBigWorldCourseVersionConfigByVersionId(versionId)

    return config.ConditionId
end

---@return XTableBigWorldCourseExplore[]
function XBigWorldCourseConfigModel:GetBigWorldCourseExploreConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseExplore) or {}
end

---@return XTableBigWorldCourseExplore
function XBigWorldCourseConfigModel:GetBigWorldCourseExploreConfigByExploreId(exploreId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseExplore, exploreId, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreContentIdByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.ContentId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreTitleByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.Title
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreTeachIdByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.TeachId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreBannerByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.Banner
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreIconByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.Icon
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePriorityByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.Priority
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreGuideIdByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.GuideId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreTypeByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.Type
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreRewardIdByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.RewardId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExploreTimeIdByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.TimeId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIIdsByExploreId(exploreId)
    local config = self:GetBigWorldCourseExploreConfigByExploreId(exploreId)

    return config.PoiIds
end

---@return XTableBigWorldCourseExplorePoi[]
function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseExplorePoi) or {}
end

---@return XTableBigWorldCourseExplorePoi
function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseExplorePoi, id, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOINameById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.Name
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIIconById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.Icon
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOITotalProgressById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.TotalProgress
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIPriorityById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.Priority
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOISkipIdById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.SkipId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOICollectionLevelIdById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.CollectionLevelId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIComputeParamsById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.ComputeParams
end

function XBigWorldCourseConfigModel:GetBigWorldCourseExplorePOIConditionIdsById(id)
    local config = self:GetBigWorldCourseExplorePOIConfigById(id)

    return config.ConditionIds
end

---@return XTableBigWorldCourseCore[]
function XBigWorldCourseConfigModel:GetBigWorldCourseCoreConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseCore) or {}
end

---@return XTableBigWorldCourseCore
function XBigWorldCourseConfigModel:GetBigWorldCourseCoreConfigByCoreId(coreId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseCore, coreId, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreContentIdByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.ContentId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupIdByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.GroupId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCorePriorityByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.Priority
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreNameByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.Name
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreLabelImageByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.LabelImage
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreBannerByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.Banner
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreSpineBannerByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.SpineBanner
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreConditionIdByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.ConditionId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementIdsByCoreId(coreId)
    local config = self:GetBigWorldCourseCoreConfigByCoreId(coreId)

    return config.ElementIds
end

---@return XTableBigWorldCourseCoreElement[]
function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseCoreElement) or {}
end

---@return XTableBigWorldCourseCoreElement
function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseCoreElement, id, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementNameById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.Name
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementBackgroundById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.Background
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementTeachIdById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.TeachId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementDisplayRewardIdById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.DisplayRewardId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementEntryIdsById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.EntryIds
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementSkipIdById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.SkipId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementLockSkipIdsById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.LockSkipIds
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementLockSkipConditionIdsById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.LockSkipConditionIds
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementEarlyAccessSkipIdsById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.EarlyAccessSkipIds
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementCustomParamIdById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.CustomParamId
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreElementEntryTypeById(id)
    local config = self:GetBigWorldCourseCoreElementConfigById(id)

    return config.EntryType
end

---@return XTableBigWorldCourseCoreGroup[]
function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupConfigs()
    return self._ConfigUtil:GetByTableKey(CourseTableKey.BigWorldCourseCoreGroup) or {}
end

---@return XTableBigWorldCourseCoreGroup
function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupConfigByGroupId(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(CourseTableKey.BigWorldCourseCoreGroup, groupId, false) or {}
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupTypeByGroupId(groupId)
    local config = self:GetBigWorldCourseCoreGroupConfigByGroupId(groupId)

    return config.Type
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupPriorityByGroupId(groupId)
    local config = self:GetBigWorldCourseCoreGroupConfigByGroupId(groupId)

    return config.Priority
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupNameByGroupId(groupId)
    local config = self:GetBigWorldCourseCoreGroupConfigByGroupId(groupId)

    return config.Name
end

function XBigWorldCourseConfigModel:GetBigWorldCourseCoreGroupLabelImageByGroupId(groupId)
    local config = self:GetBigWorldCourseCoreGroupConfigByGroupId(groupId)

    return config.LabelImage
end

return XBigWorldCourseConfigModel
