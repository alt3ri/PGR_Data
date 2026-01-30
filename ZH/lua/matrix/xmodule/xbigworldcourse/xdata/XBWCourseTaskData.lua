local XBWCourseDataBase = require("XModule/XBigWorldCourse/XData/XBWCourseDataBase")

---@class XBWCourseTaskData : XBWCourseDataBase
local XBWCourseTaskData = XClass(XBWCourseDataBase, "XBWCourseTaskData")

function XBWCourseTaskData:Init()
    self.ContentId = 0
    self.TotalProgress = 0
    self.AcquireReward = {}
end

function XBWCourseTaskData:UpdateData(data)
    self.ContentId = data.ContentId
    self.TotalProgress = data.TotalProgress
    self:UpdateAcquireRewardData(data.GotRewardIds)
end

function XBWCourseTaskData:UpdateAcquireRewardData(progressIds)
    self.AcquireReward = {}
    if not XTool.IsTableEmpty(progressIds) then
        for _, progressId in pairs(progressIds) do
            self.AcquireReward[progressId] = true
        end
    end
end

function XBWCourseTaskData:IsRewardAcquired(progressId)
    return self.AcquireReward[progressId] or false
end

function XBWCourseTaskData:IsEmpty()
    return not XTool.IsNumberValid(self.ContentId)
end

return XBWCourseTaskData
