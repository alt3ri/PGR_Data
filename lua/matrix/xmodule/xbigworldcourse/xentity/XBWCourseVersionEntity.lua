local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")
local XBWCourseContentEntity = require("XModule/XBigWorldCourse/XEntity/XBWCourseContentEntity")

---@class XBWCourseVersionEntity : XBWCourseEntityBase
local XBWCourseVersionEntity = XClass(XBWCourseEntityBase, "XBWCourseVersionEntity")

function XBWCourseVersionEntity:OnInit(versionId)
    ---@type XBWCourseContentEntity[]
    self._ContentEntitys = false
    self:SetVersionId(versionId)
end

function XBWCourseVersionEntity:IsNil()
    return not XTool.IsNumberValid(self:GetVersionId())
end

function XBWCourseVersionEntity:IsValid()
    if not self:IsNil() then
        local condition = self:GetConditionId()

        if XTool.IsNumberValid(condition) then
            if not XMVCA.XBigWorldService:CheckCondition(condition) then
                return false
            end
        end

        return XMVCA.XBigWorldService:CheckInTimeByTimeId(self:GetTimeId(), true)
    end

    return false
end

function XBWCourseVersionEntity:SetVersionId(versionId)
    self._VersionId = versionId or 0
    self:_InitContent()
end

function XBWCourseVersionEntity:GetVersionId()
    return self._VersionId
end

function XBWCourseVersionEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseVersionNameByVersionId(self:GetVersionId())
    end

    return ""
end

function XBWCourseVersionEntity:GetTimeId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseVersionTimeIdByVersionId(self:GetVersionId())
    end

    return 0
end

function XBWCourseVersionEntity:GetConditionId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseVersionConditionIdByVersionId(self:GetVersionId())
    end

    return 0
end

---@return XBWCourseContentEntity[]
function XBWCourseVersionEntity:GetContentEntitys()
    return self._ContentEntitys or {}
end

---@return XBWCourseContentEntity
function XBWCourseVersionEntity:GetContentEntityByIndex(index)
    return self:GetContentEntitys()[index]
end

function XBWCourseVersionEntity:_InitContent()
    self._ContentEntitys = {}

    if not self:IsNil() then
        local versionId = self:GetVersionId()
        local contentIds = self._OwnControl:GetEnableCourseContentIdByVersionId(versionId)

        if not XTool.IsTableEmpty(contentIds) then
            for _, contentId in pairs(contentIds) do
                self:_AddContentEntitys(contentId)
            end
        end

        table.sort(self._ContentEntitys, function(contentA, contentB)
            return contentA:GetPriority() > contentB:GetPriority()
        end)
    end
end

function XBWCourseVersionEntity:_AddContentEntitys(contentId)
    table.insert(self._ContentEntitys, self:AddChildEntity(XBWCourseContentEntity, contentId))
end

return XBWCourseVersionEntity
