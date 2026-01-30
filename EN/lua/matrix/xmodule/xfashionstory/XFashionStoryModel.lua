local TableKey = {
    FashionStory = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    FashionStoryStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId", },
    FashionStorySingleLine = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XFashionStoryModel : XModel
local XFashionStoryModel = XClass(XModel, "XFashionStoryModel")

function XFashionStoryModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/FashionStory", TableKey)
end

function XFashionStoryModel:ClearPrivate()
end

function XFashionStoryModel:ResetAll()
end

function XFashionStoryModel:GetGroupNewFullKey(singleLineId)
    local fullKey = "FashionStoryGroupNew" .. tostring(singleLineId) .. tostring(XMVCA.XFashionStory:GetCurrentActivityId()) .. XPlayer.Id
    return fullKey
end

function XFashionStoryModel:GetActivityIdOpened()
    for i, config in pairs(self._ConfigUtil:GetByTableKey(TableKey.FashionStory)) do
        if (config.TimeId ~= 0) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            return config.Id
        end
    end
    return CS.XGame.Config:GetInt("FashionStoryCurrentActivityId")
end

--------------------------------------------------内部接口---------------------------------------------------------------

function XFashionStoryModel:GetFashionStoryCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionStory, id)
end

function XFashionStoryModel:GetSingleLineCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionStorySingleLine, id)
end

function XFashionStoryModel:GetFashionStoryStageCfg(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FashionStoryStage, stageId)
end

----------------------------------------------FashionStory.tab----------------------------------------------------------

function XFashionStoryModel:GetAllFashionStoryId()
    local allFashionStoryId = {}
    for id, _ in pairs(self._ConfigUtil:GetByTableKey(TableKey.FashionStory)) do
        table.insert(allFashionStoryId, id)
    end
    return allFashionStoryId
end

function XFashionStoryModel:GetActivityTimeId(id)
    local cfg = self:GetFashionStoryCfg(id)
    return cfg and cfg.TimeId
end

function XFashionStoryModel:GetTrialBg(id)
    local cfg = self:GetFashionStoryCfg(id)
    return cfg and cfg.TrialBg
end

function XFashionStoryModel:GetSkipIdList(id)
    local cfg = self:GetFashionStoryCfg(id)
    return cfg and cfg.SkipId
end

function XFashionStoryModel:GetTrialStagesList(id)
    local cfg = self:GetFashionStoryCfg(id)
    return cfg and cfg.TrialStages
end

function XFashionStoryModel:GetPrefabType(id)
    local cfg = self:GetFashionStoryCfg(id)
    return cfg and cfg.PrefabType
end

function XFashionStoryModel:GetSingleLines(id)
    local cfg = self:GetFashionStoryCfg(id)
    local avaliableSingleLineIds = {}
    for i, singlelineid in ipairs(cfg.SingleLines) do
        if singlelineid then
            table.insert(avaliableSingleLineIds, singlelineid)
        end
    end
    return avaliableSingleLineIds
end

--获取singleline表中读取到的首个有效singlelineId：用于兼容旧玩法
function XFashionStoryModel:GetFirstSingleLine(id)
    local cfg = self:GetFashionStoryCfg(id)
    for i, singleLineId in ipairs(cfg.SingleLines) do
        if singleLineId then
            return singleLineId
        end
    end
end

function XFashionStoryModel:GetTaskLimitId(id)
    local cfg = self:GetFashionStoryCfg(id)
    return cfg and cfg.TaskLimitId
end

function XFashionStoryModel:GetFashionStorySkipId(activityId, id)
    local cfg = self:GetFashionStoryCfg(activityId)
    return cfg and cfg.SkipId[id]
end

function XFashionStoryModel:GetFashionStoryTrialStages(id)
    local cfg = self:GetFashionStoryCfg(id)
    local avaliableStages = {}
    for i, stage in ipairs(cfg.TrialStages) do
        if stage then
            table.insert(avaliableStages, stage)
        end
    end
    return avaliableStages
end

function XFashionStoryModel:GetFashionStoryTrialStageCount(id)
    local stages = self:GetFashionStoryCfg(id).TrialStages
    local count = 0
    for i, stage in ipairs(stages) do
        if stage then
            count = count + 1
        end
    end
    return count
end

function XFashionStoryModel:GetAllStoryStages(id)
    local allStages = {}
    if self:GetPrefabType(id) == XMVCA.XFashionStory.PrefabType.Group then
        local singleLineIds = self:GetSingleLines(id)
        for i, singleLineId in ipairs(singleLineIds) do
            local stages = self:GetSingleLineStages(singleLineId)
            allStages = XTool.MergeArray(allStages, stages)
        end
    elseif self:GetPrefabType(id) == XMVCA.XFashionStory.PrefabType.Old then
        local singleLineId = self:GetFirstSingleLine(id)
        if singleLineId then
            local stages = self:GetSingleLineStages(singleLineId)
            allStages = XTool.MergeArray(allStages, stages)
        end
    end

    return allStages
end

function XFashionStoryModel:GetAllStageId(id)
    return XTool.MergeArray(XFashionStoryModel:GetAllStoryStages(id), XFashionStoryModel:GetTrialStagesList(id))
end
----------------------------------------------SingleLine.tab----------------------------------------------------------
function XFashionStoryModel:GetSingleLineName(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.Name
end

function XFashionStoryModel:GetSingleLineFirstStage(id)
    local cfg = self:GetSingleLineCfg(id)
    if cfg.ChapterStages then
        return cfg and cfg.ChapterStages[1]
    end
end

function XFashionStoryModel:GetSingleLineStages(id)
    local cfg = self:GetSingleLineCfg(id)
    local avaliableStages = {}
    local count = 0
    for i, stage in ipairs(cfg.ChapterStages) do
        if count > XMVCA.XFashionStory.StageCountInGroupUpperLimit then
            break
        end

        if stage then
            table.insert(avaliableStages, stage)
            count = count + 1
        end
    end
    return avaliableStages
end

function XFashionStoryModel:GetSingleLineStagesCount(id)
    local stages = self:GetSingleLineCfg(id).ChapterStages
    local count = 0
    for i, stage in ipairs(stages) do
        if stage then
            count = count + 1
        end
    end
    return count > XMVCA.XFashionStory.StageCountInGroupUpperLimit and XMVCA.XFashionStory.StageCountInGroupUpperLimit or count
end

function XFashionStoryModel:GetSingleLineTimeId(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.StoryTimeId
end

function XFashionStoryModel:GetChapterPrefab(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.ChapterPrefab
end

function XFashionStoryModel:GetChapterStoryStagePrefab(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.StoryStagePrefab
end

function XFashionStoryModel:GetChapterFightStagePrefab(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.FightStagePrefab
end

function XFashionStoryModel:GetStoryEntranceBg(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.StoryEntranceBg
end

function XFashionStoryModel:GetStoryEntranceFinishTag(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.StoryFinishTag
end

function XFashionStoryModel:GetSingleLineAsGroupStoryIcon(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.AsGroupStoryIcon
end

function XFashionStoryModel:GetSingleLineSummerFashionTitleImg(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.SummerFashionTitleImg
end

function XFashionStoryModel:GetSingleLineChapterBg(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.ChapterBg
end

function XFashionStoryModel:GetActivityBannerIcon(id)
    local cfg = self:GetSingleLineCfg(id)
    return cfg and cfg.ActivityBannerIcon
end
----------------------------------------------FashionStoryStage.tab----------------------------------------------------------

function XFashionStoryModel:GetStageTimeId(stageId)
    local cfg = self:GetFashionStoryStageCfg(stageId)
    return cfg and cfg.TimeId
end

function XFashionStoryModel:GetPreStageId(stageId)
    local cfg = self:GetFashionStoryStageCfg(stageId)
    return cfg and cfg.PreStageId
end

function XFashionStoryModel:GetStoryStageDetailBg(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.StoryStageDetailBg
end

function XFashionStoryModel:GetStoryStageDetailIcon(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.StoryStageDetailIcon
end

function XFashionStoryModel:GetTrialDetailBg(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialDetailBg
end

function XFashionStoryModel:GetTrialDetailSpine(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialDetailSpine
end

function XFashionStoryModel:GetTrialDetailHeadIcon(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialDetailHeadIcon
end

function XFashionStoryModel:GetTrialDetailRecommendLevel(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialDetailRecommendLevel
end

function XFashionStoryModel:GetTrialDetailDesc(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialDetailDesc
end

function XFashionStoryModel:GetTrialFinishTag(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.FinishTag
end

function XFashionStoryModel:GetStoryStageFace(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.StoryStageFace
end

function XFashionStoryModel:GetTrialFace(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialFace
end

function XFashionStoryModel:GetTrialLockIcon(id)
    local cfg = self:GetFashionStoryStageCfg(id)
    return cfg and cfg.TrialLockIcon
end

return XFashionStoryModel