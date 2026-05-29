local XBigWorldCourseConfigModel = require("XModule/XBigWorldCourse/XBigWorldCourseConfigModel")
local XBWCourseVersionData = require("XModule/XBigWorldCourse/XData/XBWCourseVersionData")

---@class XBigWorldCourseModel : XBigWorldCourseConfigModel
local XBigWorldCourseModel = XClass(XBigWorldCourseConfigModel, "XBigWorldCourseModel")

function XBigWorldCourseModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ContentTaskMap = {}
    self._ContentTaskProgressMap = {}
    self._ContentExploreMap = {}
    self._ContentCoreMap = {}

    self._ObtainRewardHash = {}

    self._TaskRecordMap = false
    self._VersionRecordMap = false
    self._CoreElementRecordMap = false

    ---@type table<number, XBWCourseVersionData>
    self._VersionDataMap = {}

    self._CurSelectVersion = false

    self:_InitTableKey()
end

function XBigWorldCourseModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
    self:__RecordTaskMap()
    self:__RecordVersionMap()
    self:__RecordCoreElementMap()
end

function XBigWorldCourseModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._ContentTaskMap = {}
    self._ContentTaskProgressMap = {}
    self._ContentExploreMap = {}
    self._ContentCoreMap = {}

    self._ObtainRewardHash = {}

    self._TaskRecordMap = false
    self._VersionRecordMap = false
    self._CoreElementRecordMap = false
    self._CurSelectVersion = false

    self._VersionDataMap = {}
end

function XBigWorldCourseModel:UpdateData(data)
    self._VersionDataMap = {}

    if not data then
        return
    end

    local versionDatas = data.Datas

    if not XTool.IsTableEmpty(versionDatas) then
        for versionId, versionData in pairs(versionDatas) do
            self._VersionDataMap[versionId] = XBWCourseVersionData.New(versionData)
        end
    end
end

function XBigWorldCourseModel:UpdateTaskReward(versionId, progressIds)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.TaskData:UpdateAcquireRewardData(progressIds)
    end
end

function XBigWorldCourseModel:UpdateVersionProgress(versionId, progress)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.TaskData.TotalProgress = progress
    end
end

function XBigWorldCourseModel:UpdateExploreCompleteData(versionId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.ExploreData.IsRewardComplete = true
    end
end

function XBigWorldCourseModel:UpdateExploreProgressCompleteData(versionId, exploreId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.ExploreData:UpdateProgressRewardComplete(exploreId, true)
    end
end

function XBigWorldCourseModel:UpdateExploreProgressData(versionId, exploreId, poiId, count)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.ExploreData:UpdateProgressCount(exploreId, poiId, count)
    end
end

function XBigWorldCourseModel:AddElementBrowse(versionId, elementId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.CoreData:AddBrowseElement(elementId)
    end
end

function XBigWorldCourseModel:RemoveBrowseElement(versionId, elementId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        versionData.CoreData:RemoveBrowseElement(elementId)
    end
end

---@return table<number, XBWCourseVersionData>
function XBigWorldCourseModel:GetVersionDataMap()
    return self._VersionDataMap
end

---@return XBWCourseVersionData
function XBigWorldCourseModel:GetVersionData(versionId)
    return self._VersionDataMap[versionId]
end

function XBigWorldCourseModel:SetSelectVersion(version)
    if self._CurSelectVersion ~= version then
        self._SaveUtil:SaveData(self:__GetLocalSelectVersionKey(), version)
    end

    self._CurSelectVersion = version
end

function XBigWorldCourseModel:GetSelectVersion()
    if not self._CurSelectVersion then
        self._CurSelectVersion = self._SaveUtil:GetData(self:__GetLocalSelectVersionKey())
    end

    return self._CurSelectVersion
end

function XBigWorldCourseModel:GetCurrentTaskProgress(versionId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        return versionData.TaskData.TotalProgress
    end

    return 0
end

function XBigWorldCourseModel:GetExplorePOICount(versionId, exploreId, poiId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        return versionData.ExploreData:GetPOICount(exploreId, poiId)
    end

    return 0
end

function XBigWorldCourseModel:GetTaskIdsByContentId(contentId)
    local taskIds = self._ContentTaskMap[contentId]

    if not taskIds then
        local configs = self:GetBigWorldCourseTaskConfigs()

        taskIds = {}
        for _, config in pairs(configs) do
            if config.ContentId == contentId then
                table.insert(taskIds, config.TaskId)
            end
        end

        self._ContentTaskMap[contentId] = taskIds
    end

    return taskIds
end

function XBigWorldCourseModel:GetTaskProgressIdsByContentId(contentId)
    local progressIds = self._ContentTaskProgressMap[contentId]

    if not progressIds then
        local configs = self:GetBigWorldCourseTaskProgressRewardConfigs()

        progressIds = {}
        for _, config in pairs(configs) do
            if config.ContentId == contentId then
                table.insert(progressIds, config.Id)
            end
        end
        table.sort(progressIds, function(progressIdA, progressIdB)
            local progressA = configs[progressIdA].Progress
            local progressB = configs[progressIdB].Progress

            return progressA < progressB
        end)

        self._ContentTaskProgressMap[contentId] = progressIds
    end

    return progressIds
end

function XBigWorldCourseModel:GetExploreIdsByContentId(contentId)
    local exploreIds = self._ContentExploreMap[contentId]

    if not exploreIds then
        local configs = self:GetBigWorldCourseExploreConfigs()

        exploreIds = {}
        for _, config in pairs(configs) do
            if config.ContentId == contentId then
                table.insert(exploreIds, config.ExploreId)
            end
        end

        self._ContentExploreMap[contentId] = exploreIds
    end

    return exploreIds
end

function XBigWorldCourseModel:GetCoreIdsByContentId(contentId)
    local coreIds = self._ContentCoreMap[contentId]

    if not coreIds then
        local configs = self:GetBigWorldCourseCoreConfigs()

        coreIds = {}
        for _, config in pairs(configs) do
            if config.ContentId == contentId then
                table.insert(coreIds, config.CoreId)
            end
        end

        self._ContentCoreMap[contentId] = coreIds
    end

    return coreIds
end

function XBigWorldCourseModel:GetContentIdByVersionIdAndType(versionId, contentType)
    local contentIds = self:GetBigWorldCourseVersionContentIdsByVersionId(versionId)

    if not XTool.IsTableEmpty(contentIds) then
        for _, contentId in pairs(contentIds) do
            if self:GetBigWorldCourseContentTypeByContentId(contentId) == contentType then
                return contentId
            end
        end
    end

    return 0
end

function XBigWorldCourseModel:GetTaskRecord(taskId)
    self:__InitTaskRecordMap()

    return self._TaskRecordMap[taskId] or false
end

function XBigWorldCourseModel:SetTaskRecord(taskId)
    self:__InitTaskRecordMap()

    self._TaskRecordMap[taskId] = true
end

function XBigWorldCourseModel:GetCoreElementRecord(elementId)
    self:__InitCoreElementRecordMap()

    return self._CoreElementRecordMap[elementId] or false
end

function XBigWorldCourseModel:SetCoreElementRecord(elementId)
    self:__InitCoreElementRecordMap()

    self._CoreElementRecordMap[elementId] = true
end

function XBigWorldCourseModel:GetVersionRecord(versionId)
    self:__InitVersionRecordMap()

    return self._VersionRecordMap[versionId] or false
end

function XBigWorldCourseModel:SetVersionRecord(versionId)
    self:__InitVersionRecordMap()

    self._VersionRecordMap[versionId] = true
end

function XBigWorldCourseModel:CheckTaskProgressRewardAcquired(versionId, progressId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        return versionData.TaskData:IsRewardAcquired(progressId)
    end

    return false
end

function XBigWorldCourseModel:CheckExploreRewardAcquired(versionId, exploreId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        return versionData.ExploreData:IsExploreAcquired(exploreId)
    end

    return false
end

function XBigWorldCourseModel:CheckExploreContentRewardComplete(versionId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        return versionData.ExploreData.IsRewardComplete
    end

    return false
end

function XBigWorldCourseModel:CheckCoreElementBrowsed(versionId, elementId)
    local versionData = self._VersionDataMap[versionId]

    if versionData then
        return versionData.CoreData:IsElementBrowsed(elementId)
    end

    return false
end

function XBigWorldCourseModel:CheckTaskUnlock(taskId)
    if not XTool.IsNumberValid(taskId) then
        return false
    end

    local timeId = self:GetBigWorldCourseTaskTimeIdByTaskId(taskId)

    if not XMVCA.XBigWorldService:CheckInTimeByTimeId(timeId, true) then
        return false
    end

    local unlockType = self:GetBigWorldCourseTaskUnlockTypeByTaskId(taskId)
    local isUnlock = true
    local isActive = false

    if unlockType == XEnumConst.BWCourse.TaskUnlockType.Default then
        isUnlock = true
    elseif unlockType == XEnumConst.BWCourse.TaskUnlockType.Task then
        local params = self:GetBigWorldCourseTaskUnlockParamsByTaskId(taskId)

        if not XTool.IsTableEmpty(params) then
            for _, param in pairs(params) do
                if not XMVCA.XBigWorldService:CheckTaskFinish(param) then
                    isUnlock = false
                    break
                end
            end
        end
    elseif unlockType == XEnumConst.BWCourse.TaskUnlockType.Condition then
        local params = self:GetBigWorldCourseTaskUnlockParamsByTaskId(taskId)

        if not XTool.IsTableEmpty(params) then
            for _, param in pairs(params) do
                local isSuccess = XMVCA.XBigWorldService:CheckCondition(param)

                if not isSuccess then
                    isUnlock = false
                    break
                end
            end
        end
    end

    if isUnlock then
        isActive = XMVCA.XBigWorldService:CheckTaskActive(taskId) or XMVCA.XBigWorldService:CheckTaskAchieved(taskId) or
                       XMVCA.XBigWorldService:CheckTaskFinish(taskId)
    end

    return isUnlock and isActive
end

function XBigWorldCourseModel:__InitTaskRecordMap()
    if not self._TaskRecordMap then
        local recordData = XSaveTool.GetData(self.__GetTaskRecordKey())
        local records = string.ToIntArray(recordData)

        self._TaskRecordMap = {}
        if not XTool.IsTableEmpty(records) then
            for _, recordId in pairs(records) do
                self._TaskRecordMap[recordId] = true
            end
        end
    end
end

function XBigWorldCourseModel:__GetLocalSelectVersionKey()
    return string.format("BW_COURSE_SELECT_VERSION_%s", tostring(XPlayer.Id))
end

function XBigWorldCourseModel:__RecordTaskMap()
    if self._TaskRecordMap and not XTool.IsTableEmpty(self._TaskRecordMap) then
        local records = {}

        for taskId, _ in pairs(self._TaskRecordMap) do
            table.insert(records, taskId)
        end

        XSaveTool.SaveData(self.__GetTaskRecordKey(), table.concat(records, "|"))
    end
end

function XBigWorldCourseModel:__GetTaskRecordKey()
    return string.format("BW_COURSE_TASK_RECORD_%s", tostring(XPlayer.Id))
end

function XBigWorldCourseModel:__InitCoreElementRecordMap()
    if not self._CoreElementRecordMap then
        local recordData = XSaveTool.GetData(self.__GetCoreElementRecordKey())
        local records = string.ToIntArray(recordData)

        self._CoreElementRecordMap = {}
        if not XTool.IsTableEmpty(records) then
            for _, recordId in pairs(records) do
                self._CoreElementRecordMap[recordId] = true
            end
        end
    end
end

function XBigWorldCourseModel:__RecordCoreElementMap()
    if self._CoreElementRecordMap and not XTool.IsTableEmpty(self._CoreElementRecordMap) then
        local records = {}

        for elementId, _ in pairs(self._CoreElementRecordMap) do
            table.insert(records, elementId)
        end

        XSaveTool.SaveData(self.__GetCoreElementRecordKey(), table.concat(records, "|"))
    end
end

function XBigWorldCourseModel:__GetCoreElementRecordKey()
    return string.format("BW_COURSE_CORE_ELEMENT_RECORD_%s", tostring(XPlayer.Id))
end

function XBigWorldCourseModel:__InitVersionRecordMap()
    if not self._VersionRecordMap then
        local recordData = XSaveTool.GetData(self.__GetVersionRecordKey())
        local records = string.ToIntArray(recordData)

        self._VersionRecordMap = {}
        if not XTool.IsTableEmpty(records) then
            for _, recordId in pairs(records) do
                self._VersionRecordMap[recordId] = true
            end
        end
    end
end

function XBigWorldCourseModel:__RecordVersionMap()
    if self._VersionRecordMap and not XTool.IsTableEmpty(self._VersionRecordMap) then
        local records = {}

        for versionId, _ in pairs(self._VersionRecordMap) do
            table.insert(records, versionId)
        end

        XSaveTool.SaveData(self.__GetVersionRecordKey(), table.concat(records, "|"))
    end
end

function XBigWorldCourseModel:__GetVersionRecordKey()
    return string.format("BW_COURSE_VERSION_RECORD_%s", tostring(XPlayer.Id))
end

return XBigWorldCourseModel
