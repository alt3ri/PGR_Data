---@class XBWCourseEntityBase : XEntity
---@field private _OwnControl XBigWorldCourseControl
---@field private _Model XBigWorldCourseModel
local XBWCourseEntityBase = XClass(XEntity, "XBWCourseEntityBase")

function XBWCourseEntityBase:IsNil()
    return true
end

return XBWCourseEntityBase