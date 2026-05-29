local XBWCourseVersionEntity = require("XModule/XBigWorldCourse/XEntity/XBWCourseVersionEntity")

---@class XBigWorldCourseControl : XEntityControl
---@field private _Model XBigWorldCourseModel
local XBigWorldCourseControl = XClass(XEntityControl, "XBigWorldCourseControl")

function XBigWorldCourseControl:OnInit()
    -- 初始化内部变量
    ---@type XBWCourseVersionEntity[]
    self._VersionEntitys = false

    self._CurrentTaskProgress = {}

    self:_InitCurrentTaskProgress()
end

function XBigWorldCourseControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldCourseControl:RemoveAgencyEvent()
end

function XBigWorldCourseControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
    self._CurrentTaskProgress = {}
end

---@return XBWCourseVersionEntity[]
function XBigWorldCourseControl:GetVersionEntitys()
    if not self._VersionEntitys then
        local versionDataMap = self._Model:GetVersionDataMap()

        self._VersionEntitys = {}
        if not XTool.IsTableEmpty(versionDataMap) then
            for versionId, _ in pairs(versionDataMap) do
                local entity = self:AddEntity(XBWCourseVersionEntity, versionId)

                if entity then
                    table.insert(self._VersionEntitys, entity)
                end
            end
        end
    end

    table.sort(self._VersionEntitys, function(versionA, versionB)
        local isValidA = versionA:IsValid()
        local isValidB = versionB:IsValid()

        if isValidA ~= isValidB then
            return isValidA
        end

        local isCompleteA = versionA:IsComplete()
        local isCompleteB = versionB:IsComplete()

        if isCompleteA ~= isCompleteB then
            return not isCompleteA
        end

        local priorityA = versionA:GetPriority()
        local priorityB = versionB:GetPriority()

        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        return versionA:GetVersionId() > versionB:GetVersionId()
    end)

    return self._VersionEntitys
end

function XBigWorldCourseControl:GetValidVersionEntitys()
    local versionEntitys = self:GetVersionEntitys()
    local result = {}

    if not XTool.IsTableEmpty(versionEntitys) then
        for _, versionEntity in pairs(versionEntitys) do
            if versionEntity:IsValid() then
                table.insert(result, versionEntity)
            end
        end
    end

    return result
end

function XBigWorldCourseControl:GetEnableCourseContentIdByVersionId(versionId)
    local contentIds = self._Model:GetBigWorldCourseVersionContentIdsByVersionId(versionId)
    local result = {}

    if not XTool.IsTableEmpty(contentIds) then
        for _, contentId in pairs(contentIds) do
            local conditionIds = self._Model:GetBigWorldCourseTypeConditionIdsByContentId(contentId)
            local isEnable = true

            if not XTool.IsTableEmpty(conditionIds) then
                for _, conditionId in pairs(conditionIds) do
                    local isSuccess = XMVCA.XBigWorldService:CheckCondition(conditionId)

                    if not isSuccess then
                        isEnable = false
                        break
                    end
                end
            end

            if isEnable then
                table.insert(result, contentId)
            end
        end
    end

    return result
end

function XBigWorldCourseControl:TryOpenRewardTips(rewardId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end

    local rewardList = XMVCA.XBigWorldService:GetRewardDataList(rewardId)

    if XTool.IsTableEmpty(rewardList) then
        return
    end

    if #rewardList == 1 then
        local reward = rewardList[1]
        local goodParams = XMVCA.XBigWorldService:GetGoodsShowParamsByTemplateId(reward.TemplateId)

        XMVCA.XBigWorldUI:OpenGoodsInfo(goodParams)
    else
        XMVCA.XBigWorldUI:OpenBigWorldObtain(rewardList, XMVCA.XBigWorldService:GetText("TipReward"), nil, true, false)
    end
end

function XBigWorldCourseControl:SetSelectVersion(version)
    self._Model:SetSelectVersion(version)
end

function XBigWorldCourseControl:GetSelectVersion()
    local version = self._Model:GetSelectVersion()

    if not XTool.IsNumberValid(version) then
        version = 1
    end

    return version
end

---@return XBWCourseVersionEntity
function XBigWorldCourseControl:GetSelectVersionEntity(targetId)
    local versionId = targetId or self:GetSelectVersion()
    local versionEntities = self:GetVersionEntitys()

    for _, versionEntity in pairs(versionEntities) do
        if versionEntity:GetVersionId() == versionId and versionEntity:IsValid() then
            return versionEntity
        end
    end

    return versionEntities[1]
end

--- region 历程任务

function XBigWorldCourseControl:GetCurrentTaskProgress(versionId)
    return self._Model:GetCurrentTaskProgress(versionId)
end

function XBigWorldCourseControl:GetTaskRewardItemId(contentId)
    return self._Model:GetBigWorldCourseContentTaskProgressItemIdByContentId(contentId)
end

function XBigWorldCourseControl:GetTaskRewardItemIcon(contentId)
    local itemId = self:GetTaskRewardItemId(contentId)

    if XTool.IsNumberValid(itemId) then
        return XMVCA.XBigWorldService:GetItemIcon(itemId)
    end

    return ""
end

function XBigWorldCourseControl:GetTaskRewardItemIconNoneColor(contentId)
    return self._Model:GetBigWorldCourseContentTaskProgressItemIconByContentId(contentId) or ""
end

function XBigWorldCourseControl:GetBigWorldCourseContentBannerBg(contentId)
    return self._Model:GetBigWorldCourseContentBannerBgByContentId(contentId) or ""
end

function XBigWorldCourseControl:GetBigWorldCourseContentTip(contentId)
    return self._Model:GetBigWorldCourseTypeContentTipByContentId(contentId) or ""
end

function XBigWorldCourseControl:GetTaskIdsByContentId(contentId)
    return self._Model:GetTaskIdsByContentId(contentId)
end

function XBigWorldCourseControl:GetTaskProgressIdsByContentId(contentId)
    return self._Model:GetTaskProgressIdsByContentId(contentId)
end

function XBigWorldCourseControl:GetTaskProgressCountByContentId(contentId)
    return table.nums(self:GetTaskProgressIdsByContentId(contentId))
end

function XBigWorldCourseControl:GetCurrentRecordTaskProgress(versionId)
    return self._CurrentTaskProgress[versionId] or 0
end

function XBigWorldCourseControl:SyncCurrentRecordTaskProgress(versionId)
    self._CurrentTaskProgress[versionId] = self._Model:GetCurrentTaskProgress(versionId)
end

---@param taskEntitys XBWCourseTaskEntity[]
function XBigWorldCourseControl:FinishMultiTask(taskEntitys)
    local taskIds = {}

    if not XTool.IsTableEmpty(taskEntitys) then
        for _, taskEntity in pairs(taskEntitys) do
            if taskEntity:IsAchieved() then
                table.insert(taskIds, taskEntity:GetTaskId())
            end
        end
    end

    if not XTool.IsTableEmpty(taskIds) then
        XMVCA.XBigWorldService:FinishMultiTasks(taskIds)
    end
end

--- endregion

--- region 箱庭探索

function XBigWorldCourseControl:GetExploreIdsByContentId(contentId)
    return self._Model:GetExploreIdsByContentId(contentId)
end

function XBigWorldCourseControl:GetExploreTotalProgress(contentId)
    local exploreIds = self:GetExploreIdsByContentId(contentId)

    return table.nums(exploreIds)
end

function XBigWorldCourseControl:GetExploreCurrentProgress(versionId, contentId)
    local exploreIds = self:GetExploreIdsByContentId(contentId)
    local result = 0

    if not XTool.IsTableEmpty(exploreIds) then
        for _, exploreId in pairs(exploreIds) do
            if self._Model:CheckExploreRewardAcquired(versionId, exploreId) then
                result = result + 1
            end
        end
    end

    return result
end

function XBigWorldCourseControl:GetExploreRewardId(contentId)
    return self._Model:GetBigWorldCourseContentExploreRewardIdByContentId(contentId)
end

function XBigWorldCourseControl:GetExploreRewardIcon(contentId)
    local rewardList = self:GetExploreRewardList(contentId)

    if not XTool.IsTableEmpty(rewardList) then
        return XMVCA.XBigWorldService:GetGoodsIconByTemplateId(rewardList[1].TemplateId)
    end

    return ""
end

function XBigWorldCourseControl:GetExploreRewardList(contentId)
    local rewardId = self:GetExploreRewardId(contentId)

    if XTool.IsNumberValid(rewardId) then
        return XMVCA.XBigWorldService:GetRewardDataList(rewardId)
    end

    return nil
end

function XBigWorldCourseControl:GetExplorePOICount(versionId, exploreId, poiId)
    return self._Model:GetExplorePOICount(versionId, exploreId, poiId)
end

--- endregion

--- region 核心玩法

function XBigWorldCourseControl:GetCoreIdsByContentId(contentId)
    return self._Model:GetCoreIdsByContentId(contentId)
end

function XBigWorldCourseControl:GetCoreGroupName(groupId)
    return self._Model:GetBigWorldCourseCoreGroupNameByGroupId(groupId) or ""
end

function XBigWorldCourseControl:GetCoreGroupLabelImage(groupId)
    return self._Model:GetBigWorldCourseCoreGroupLabelImageByGroupId(groupId) or ""
end

---@param coreEntity XBWCourseCoreEntity
function XBigWorldCourseControl:RecordCoreElementsByCoreEntity(coreEntity)
    local elements = coreEntity:GetUnRecordElementIds()

    if not XTool.IsTableEmpty(elements) then
        self:RequestBigWorldCourseCoreSet(coreEntity:GetVersionId(), elements)
    end
end

---@param coreEntitys XBWCourseCoreEntity[]
function XBigWorldCourseControl:CheckCoreEntitysUnlock(coreEntitys)
    if not XTool.IsTableEmpty(coreEntitys) then
        for _, coreEntity in pairs(coreEntitys) do
            if coreEntity:IsUnlock() then
                return true
            end
        end
    end

    return false
end

function XBigWorldCourseControl:CheckCoreQuestGroup(groupId)
    local groupType = self._Model:GetBigWorldCourseCoreGroupTypeByGroupId(groupId)

    return groupType == XEnumConst.BWCourse.CoreGroupType.Quest
end

--- endregion

--- region 协议

function XBigWorldCourseControl:RequestBigWorldCourseTaskCntGetReward(versionId)
    XNetwork.Call("BigWorldCourseTaskCntGetRewardRequest", {
        VersionId = versionId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        self._Model:UpdateTaskReward(versionId, res.GotRewardIds)
        XMVCA.XBigWorldUI:OpenBigWorldObtain(res.RewardGoodsList)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE)
    end)
end

function XBigWorldCourseControl:RequestBigWorldCourseExploreCntGetCompleteReward(versionId)
    XNetwork.Call("BigWorldCourseExploreCntGetCompleteRewardRequest", {
        VersionId = versionId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        self._Model:UpdateExploreCompleteData(versionId)
        XMVCA.XBigWorldUI:OpenBigWorldObtain(res.RewardGoodsList)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE)
    end)
end

function XBigWorldCourseControl:RequestBigWorldCourseExploreCntGetReward(versionId, exploreId)
    XNetwork.Call("BigWorldCourseExploreCntGetRewardRequest", {
        ExploreId = exploreId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        self._Model:UpdateExploreProgressCompleteData(versionId, exploreId)
        XMVCA.XBigWorldUI:OpenBigWorldObtain(res.RewardGoodsList)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE)
    end)
end

function XBigWorldCourseControl:RequestBigWorldCourseCoreSet(versionId, elementIds)
    if XTool.IsTableEmpty(elementIds) then
        return
    end

    for _, elementId in pairs(elementIds) do
        self._Model:AddElementBrowse(versionId, elementId)
    end

    XNetwork.Call("BigWorldCourseCoreSetReadRequest", {
        VersionId = versionId,
        ElementIds = elementIds,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        if not XTool.IsTableEmpty(res.SuccessIds) then
            if #res.SuccessIds ~= #elementIds then
                local successMap = {}

                for _, elementId in pairs(res.SuccessIds) do
                    successMap[elementId] = true
                end
                for _, elementId in pairs(elementIds) do
                    if not successMap[elementId] then
                        self._Model:RemoveBrowseElement(versionId, elementId)
                    end
                end
            end
        else
            for _, elementId in pairs(elementIds) do
                self._Model:RemoveBrowseElement(versionId, elementId)
            end
        end
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH)
    end)
end

--- endregion

function XBigWorldCourseControl:_InitCurrentTaskProgress()
    local versionDatas = self._Model:GetVersionDataMap()

    if not XTool.IsTableEmpty(versionDatas) then
        for versionId, versionData in pairs(versionDatas) do
            self._CurrentTaskProgress[versionId] = versionData.TaskData.TotalProgress
        end
    end
end

return XBigWorldCourseControl
