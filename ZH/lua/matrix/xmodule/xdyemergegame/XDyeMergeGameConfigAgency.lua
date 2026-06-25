---@type XDyeMergeGameAgency 配置部分类
local XDyeMergeGameAgency = XClassPartial("XDyeMergeGameAgency")

local TableKey = {
    DyeMergeActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    DyeMergeChapter = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    DyeMergeStage = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    DyeMergeClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },
}

function XDyeMergeGameAgency:InitConfig()
    --初始化配置表
    self:InitConfigByTabKey("MiniActivity/DyeMerge", TableKey)
end

---@return XTableDyeMergeActivity
function XDyeMergeGameAgency:GetTableDyeMergeActivityById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeActivity, id, notips)
end

---@return XTableDyeMergeChapter
function XDyeMergeGameAgency:GetTableDyeMergeChapterById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeChapter, id, notips)
end

---@return XTableDyeMergeStage
function XDyeMergeGameAgency:GetTableDyeMergeStageById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeStage, id, notips)
end

---@return XTableDyeMergeClientConfig
function XDyeMergeGameAgency:GetTableDyeMergeClientConfigByKey(key, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.DyeMergeClientConfig, key, notips)
end

function XDyeMergeGameAgency:GetCfgDyeMergeChapterNameById(id)
    local cfg = self:GetTableDyeMergeChapterById(id)

    if cfg then
        return cfg.Name
    end
    
    return ''
end

function XDyeMergeGameAgency:GetCfgDyeMergeChapterIconById(id)
    local cfg = self:GetTableDyeMergeChapterById(id)

    if cfg then
        return cfg.ChapterIcon
    end

    return ''
end

---@return XTableDyeMergeActivity
function XDyeMergeGameAgency:GetCurActivityCfg(notips)
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValidEx(activityId) then
        return self:GetTableDyeMergeActivityById(activityId, notips)
    end
end

---@return XTableDyeMergeActivity
function XDyeMergeGameAgency:GetCurActivityPreviewRewardId(notips)
    local cfg = self:GetCurActivityCfg(notips)

    if cfg then
        return cfg.RewardId
    end
end

---@return number[]
function XDyeMergeGameAgency:GetCurActivityChapterIds(notips)
    local cfg = self:GetCurActivityCfg(notips)

    if cfg then
        return cfg.ChapterIds
    end
end

---@return XTableDyeMergeActivity
function XDyeMergeGameAgency:GetCurActivityHelpKey(notips)
    local cfg = self:GetCurActivityCfg(notips)

    if cfg then
        return cfg.HelpKey
    end
    
    return ''
end

function XDyeMergeGameAgency:GetCfgStageTipsImageById(stageId)
    local cfg = self:GetTableDyeMergeStageById(stageId)

    if cfg then
        return cfg.TipsImg
    end
    
    return ''
end

function XDyeMergeGameAgency:GetIsStageHasTipsImageById(stageId)
    local cfg = self:GetTableDyeMergeStageById(stageId)

    if cfg then
        return not string.IsNilOrEmpty(cfg.TipsImg)
    end

    return false
end

function XDyeMergeGameAgency:GetConfigTaskIdList(isSort, needReceiveAll)
    local curActCfg = self:GetCurActivityCfg()

    if not curActCfg or not XTool.IsNumberValidEx(curActCfg.TaskTimeLimitId) then
        return
    end
    
    local taskTimeLimitId = curActCfg.TaskTimeLimitId

    local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimeLimitId, isSort)

    local canRecieveTaskDataList = nil

    if needReceiveAll then
        -- 收集当前所有可领取任务数据，用于一键领取
        canRecieveTaskDataList = {}
        for _, taskData in ipairs(taskDataList) do
            if XTool.IsNumberValidEx(taskData) then
                taskData = XDataCenter.TaskManager.GetTaskDataById(taskData)
            end

            if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(canRecieveTaskDataList, taskData)
            end
        end
    end

    return taskDataList, canRecieveTaskDataList
end

--- 获取当期任务完成进度
---@return number, number @已完成数量，任务总数
function XDyeMergeGameAgency:GetCurTaskProgress()
    local taskDataList = self:GetConfigTaskIdList(false)
    
    local finishedCount = 0
    local totalCount = 0

    if not XTool.IsTableEmpty(taskDataList) then
        for i, taskData in pairs(taskDataList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved or taskData.State == XDataCenter.TaskManager.TaskState.Finish then
                finishedCount = finishedCount + 1
            end

            totalCount = totalCount + 1
        end
    end
    
    return finishedCount, totalCount
end

--- 判断是否有任意任务可领取奖励
---@return number, number @已完成数量，任务总数
function XDyeMergeGameAgency:GetHasAnyTaskAchieved()
    local taskDataList = self:GetConfigTaskIdList(false)

    if not XTool.IsTableEmpty(taskDataList) then
        for i, taskData in pairs(taskDataList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end

    return false
end

--region ClientConfig

function XDyeMergeGameAgency:GetClientDyeMergeTextByKey(key, index)
    index = index or 1
    
    local cfg = self:GetTableDyeMergeClientConfigByKey(key)

    if not cfg then
        return ''
    end
    
    return cfg.Values[index] or ''
end

function XDyeMergeGameAgency:GetClientDyeMergeNumberByKey(key, index)
    index = index or 1

    local cfg = self:GetTableDyeMergeClientConfigByKey(key)

    if not cfg then
        return 0
    end
    
    local numStr = cfg.Values[index]

    if string.IsNilOrEmpty(numStr) or not string.IsFloatNumber(numStr) then
        return 0
    end

    return tonumber(numStr)
end

--endregion

--- 获取同章节内的下一关 StageId，已是末关则返回 nil
function XDyeMergeGameAgency:GetNextStageIdInChapter(stageId)
    local chapterIds = self:GetCurActivityChapterIds()
    if XTool.IsTableEmpty(chapterIds) then return nil end
    for _, chapterId in ipairs(chapterIds) do
        local chapterCfg = self:GetTableDyeMergeChapterById(chapterId)
        if chapterCfg and not XTool.IsTableEmpty(chapterCfg.StageIds) then
            for i, sid in ipairs(chapterCfg.StageIds) do
                if sid == stageId then
                    return chapterCfg.StageIds[i + 1]
                end
            end
        end
    end
    return nil
end

--region 二次封装后的杂项表数据

function XDyeMergeGameAgency:GetClientConfigBtnNameInPassed(hasNextStage)
    return self:GetClientDyeMergeTextByKey("BtnNameInPassed", hasNextStage and 1 or 2)
end

--endregion

return XDyeMergeGameAgency
