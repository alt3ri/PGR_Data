local XBWCourseDataBase = require("XModule/XBigWorldCourse/XData/XBWCourseDataBase")

---@class XBWCourseCoreData : XBWCourseDataBase
local XBWCourseCoreData = XClass(XBWCourseDataBase, "XBWCourseCoreData")

function XBWCourseCoreData:Init()
    self.ContentId = 0
    self.BrowseElement = {}
end

function XBWCourseCoreData:UpdateData(data)
    self.ContentId = data.ContentId

    self.BrowseElement = {}
    if not XTool.IsTableEmpty(data.ReadElementIds) then
        for _, elementId in pairs(data.ReadElementIds) do
            self:AddBrowseElement(elementId)
        end
    end
end

function XBWCourseCoreData:IsElementBrowsed(elementId)
    return self.BrowseElement[elementId] or false
end

function XBWCourseCoreData:AddBrowseElement(elementId)
    self.BrowseElement[elementId] = true
end

function XBWCourseCoreData:RemoveBrowseElement(elementId)
    self.BrowseElement[elementId] = nil
end

return XBWCourseCoreData
