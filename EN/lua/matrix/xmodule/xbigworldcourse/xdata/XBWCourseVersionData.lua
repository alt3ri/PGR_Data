local XBWCourseDataBase = require("XModule/XBigWorldCourse/XData/XBWCourseDataBase")
local XBWCourseTaskData = require("XModule/XBigWorldCourse/XData/XBWCourseTaskData")
local XBWCourseExploreData = require("XModule/XBigWorldCourse/XData/XBWCourseExploreData")
local XBWCourseCoreData = require("XModule/XBigWorldCourse/XData/XBWCourseCoreData")

---@class XBWCourseVersionData : XBWCourseDataBase
---@field VersionId number
---@field TaskData XBWCourseTaskData
---@field ExploreData XBWCourseExploreData
---@field CoreData XBWCourseCoreData
local XBWCourseVersionData = XClass(XBWCourseDataBase, "XBWCourseVersionData")

function XBWCourseVersionData:Init()
    self.VersionId = 0
    ---@type XBWCourseTaskData
    self.TaskData = XBWCourseTaskData.New()
    ---@type XBWCourseExploreData
    self.ExploreData = XBWCourseExploreData.New()
    ---@type XBWCourseCoreData
    self.CoreData = XBWCourseCoreData.New()
end

function XBWCourseVersionData:UpdateData(data)
    self.VersionId = data.VersionId or 0
    self.TaskData:Update(data.TaskCntData)
    self.ExploreData:Update(data.ExploreCntData)
    self.CoreData:Update(data.CoreCntData)
end

function XBWCourseVersionData:IsEmpty()
    return not XTool.IsNumberValid(self.VersionId)
end

return XBWCourseVersionData
