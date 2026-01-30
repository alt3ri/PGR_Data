local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")

---@class XBWCourseExplorePOIEntity : XBWCourseEntityBase
---@field private _ParentEntity XBWCourseExploreEntity
local XBWCourseExplorePOIEntity = XClass(XBWCourseEntityBase, "XBWCourseExplorePOIEntity")

function XBWCourseExplorePOIEntity:OnInit(id)
    self:SetPOIId(id)
end

function XBWCourseExplorePOIEntity:IsNil()
    return not XTool.IsNumberValid(self:GetPOIId())
end

function XBWCourseExplorePOIEntity:IsComplete()
    return self:GetCurrentProgress() >= self:GetTotalProgress()
end

function XBWCourseExplorePOIEntity:IsLock()
    return false
end

function XBWCourseExplorePOIEntity:IsTreasureBox()
    if not self:IsNil() then
        return self._ParentEntity:GetType() == XEnumConst.BWCourse.ExploreType.TreasureBox
    end

    return false
end

function XBWCourseExplorePOIEntity:IsPlayInst()
    if not self:IsNil() then
        return self._ParentEntity:GetType() == XEnumConst.BWCourse.ExploreType.PlayInst
    end

    return false
end

function XBWCourseExplorePOIEntity:SetPOIId(exploreId)
    self._POIId = exploreId or 0
end

function XBWCourseExplorePOIEntity:GetPOIId()
    return self._POIId
end

function XBWCourseExplorePOIEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseExplorePOIEntity:GetExploreId()
    if not self:IsNil() then
        return self._ParentEntity:GetExploreId()
    end

    return 0
end

function XBWCourseExplorePOIEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOINameById(self:GetPOIId())
    end

    return ""
end

function XBWCourseExplorePOIEntity:GetIcon()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOIIconById(self:GetPOIId())
    end

    return ""
end

function XBWCourseExplorePOIEntity:GetCurrentProgress()
    if not self:IsNil() then
        return self._OwnControl:GetExplorePOICount(self:GetVersionId(), self:GetExploreId(), self:GetPOIId())
    end

    return 0
end

function XBWCourseExplorePOIEntity:GetTotalProgress()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOITotalProgressById(self:GetPOIId())
    end

    return 0
end

function XBWCourseExplorePOIEntity:GetProgressText()
    local current = self:GetCurrentProgress()
    local total = self:GetTotalProgress()

    if current >= 0 and total >= 0 then
        if current > total then
            current = total
        end

        return string.format("%d/%d", current, total)
    end

    return ""
end

function XBWCourseExplorePOIEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOIPriorityById(self:GetPOIId())
    end

    return 0
end

function XBWCourseExplorePOIEntity:GetSkipId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOISkipIdById(self:GetPOIId())
    end

    return 0
end

function XBWCourseExplorePOIEntity:GetCollectionLevelId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOICollectionLevelIdById(self:GetPOIId())
    end

    return nil
end

function XBWCourseExplorePOIEntity:GetConditionIds()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePOIConditionIdsById(self:GetPOIId())
    end

    return nil
end

return XBWCourseExplorePOIEntity
