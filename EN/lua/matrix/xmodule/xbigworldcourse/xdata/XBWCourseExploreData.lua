local XBWCourseDataBase = require("XModule/XBigWorldCourse/XData/XBWCourseDataBase")
local XBWCourseExploreProgressData = require("XModule/XBigWorldCourse/XData/XBWCourseExploreProgressData")

---@class XBWCourseExploreData : XBWCourseDataBase
local XBWCourseExploreData = XClass(XBWCourseDataBase, "XBWCourseExploreData")

function XBWCourseExploreData:Init()
    self.ContentId = 0
    self.IsRewardComplete = false
    ---@type table<number, XBWCourseExploreProgressData>
    self.ProgressMap = {}
end

function XBWCourseExploreData:UpdateData(data)
    self.ContentId = data.ContentId
    self.IsRewardComplete = data.IsGotCompleteReward

    self.ProgressMap = {}
    if not XTool.IsTableEmpty(data.ExploreDatas) then
        for exploreId, progressData in pairs(data.ExploreDatas) do
            self:AddProgressData(exploreId, progressData)
        end
    end
end

function XBWCourseExploreData:UpdateProgressCount(exploreId, poiId, count)
    local progressData = self.ProgressMap[exploreId]

    if progressData then
        progressData:UpdatePOICount(poiId, count)
    else
        self:AddProgressData(exploreId, {
            ExploreId = exploreId,
            PoiCounts = {
                [poiId] = count
            },
            IsGotReward = false,
        })
    end
end

function XBWCourseExploreData:UpdateProgressRewardComplete(exploreId, isComplete)
    local progressData = self.ProgressMap[exploreId]

    if progressData then
        progressData.IsRewardComplete = isComplete
    end
end

function XBWCourseExploreData:AddProgressData(exploreId, progressData)
    self.ProgressMap[exploreId] = XBWCourseExploreProgressData.New(progressData)
end

function XBWCourseExploreData:IsExploreAcquired(exploreId)
    local progressData = self.ProgressMap[exploreId]

    if progressData then
        return progressData.IsRewardComplete
    end

    return false
end

function XBWCourseExploreData:GetPOICount(exploreId, poiId)
    local progressData = self.ProgressMap[exploreId]

    if progressData then
        return progressData:GetPOICount(poiId)
    end

    return 0
end

return XBWCourseExploreData
