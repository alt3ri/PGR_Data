---@class XBWCourseDataBase
local XBWCourseDataBase = XClass(nil, "XBWCourseDataBase")

function XBWCourseDataBase:Ctor(data)
    self:Init()
    self:Update(data)
end

function XBWCourseDataBase:Init()
end

function XBWCourseDataBase:Update(data)
    if data then
        self:UpdateData(data)
    end
end

function XBWCourseDataBase:UpdateData(data)
end

return XBWCourseDataBase