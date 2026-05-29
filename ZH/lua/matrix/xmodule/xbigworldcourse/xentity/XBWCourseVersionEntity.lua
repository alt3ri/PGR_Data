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

function XBWCourseVersionEntity:IsNew()
    if not self:IsNil() then
        return not self._Model:GetVersionRecord(self:GetVersionId())
    end

    return false
end

function XBWCourseVersionEntity:IsComplete()
    if not self:IsNil() then
        for _, content in pairs(self._ContentEntitys) do
            if not content:IsComplete() then
                return false
            end
        end
    end
    
    return true
end

function XBWCourseVersionEntity:IsTaskComplete()
    if not self:IsNil() then
        for _, content in pairs(self._ContentEntitys) do
            if content:IsTask() and not content:IsComplete() then
                return false
            end
        end
    end
    
    return true
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

function XBWCourseVersionEntity:GetSwitchIcon()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseVersionSwitchIconByVersionId(self:GetVersionId())
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

function XBWCourseVersionEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseVersionPriorityByVersionId(self:GetVersionId())
    end

    return 0
end

function XBWCourseVersionEntity:GetUnlockTip()
    if not self:IsNil() then
        local condition = self:GetConditionId()

        if XTool.IsNumberValid(condition) then
            local isSuccess, tip = XMVCA.XBigWorldService:CheckCondition(condition)

            if not isSuccess then
                return tip
            end
        end

        if not XMVCA.XBigWorldService:CheckInTimeByTimeId(self:GetTimeId(), true) then
            return XMVCA.XBigWorldService:GetText("CourseVersionNotInTime")
        end
    end

    return ""
end

---@return XBWCourseContentEntity
function XBWCourseVersionEntity:GetContentEntityByType(type)
    if not self:IsNil() then
        for _, contentEntity in pairs(self:GetContentEntitys()) do
            if contentEntity:GetContentType() == type then
                return contentEntity
            end
        end
    end

    return nil
end

---@return XBWCourseContentEntity[]
function XBWCourseVersionEntity:GetContentEntitys()
    return self._ContentEntitys or {}
end

---@return XBWCourseContentEntity
function XBWCourseVersionEntity:GetContentEntityByIndex(index)
    return self:GetContentEntitys()[index]
end

function XBWCourseVersionEntity:GetProgress()
    local contentEntity = self:GetContentEntityByType(XEnumConst.BWCourse.ContentType.Task)

    if contentEntity then
        return contentEntity:GetTaskPercentageProgress()
    end

    return 0
end

function XBWCourseVersionEntity:GetProgressStr()
    return string.format("%d%%", math.floor(self:GetProgress()))
end

function XBWCourseVersionEntity:Record()
    if not self:IsNil() then
        self._Model:SetVersionRecord(self:GetVersionId())
    end
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
