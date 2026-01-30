local XBWCourseDataBase = require("XModule/XBigWorldCourse/XData/XBWCourseDataBase")

---@class XBWCourseExploreProgressData : XBWCourseDataBase
local XBWCourseExploreProgressData = XClass(XBWCourseDataBase, "XBWCourseExploreProgressData")

function XBWCourseExploreProgressData:Init()
    self.ExploreId = 0
    self.IsRewardComplete = false
    self.POICountMap = {}
end

function XBWCourseExploreProgressData:UpdateData(data)
    self.ExploreId = data.ExploreId
    self.IsRewardComplete = data.IsGotReward

    self.POICountMap = {}
    if not XTool.IsTableEmpty(data.PoiCounts) then
        for poiId, count in pairs(data.PoiCounts) do
            self:UpdatePOICount(poiId, count)
        end
    end
end

function XBWCourseExploreProgressData:UpdatePOICount(poiId, count)
    self.POICountMap[poiId] = count or 0
end

function XBWCourseExploreProgressData:GetPOICount(poiId)
    return self.POICountMap[poiId] or 0
end

return XBWCourseExploreProgressData
