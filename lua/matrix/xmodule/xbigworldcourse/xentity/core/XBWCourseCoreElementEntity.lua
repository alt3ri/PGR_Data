local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")
require("XModule/XBigWorldCourse/XEntity/Core/XBWCourseCoreElementEntityProxy")

---@class XBWCourseCoreElementEntity : XBWCourseEntityBase
---@field private _ParentEntity XBWCourseCoreEntity
---@field private _Proxy XBWCourseCoreElementEntityProxy
local XBWCourseCoreElementEntity = XClass(XBWCourseEntityBase, "XBWCourseCoreElementEntity")

function XBWCourseCoreElementEntity:OnInit(elementId)
    self:SetElementId(elementId)
    local proxy = XMVCA.XBigWorldCourse:GetCoreElementEntityProxy(self:GetEntryType())
    if proxy then
        self._Proxy = self:AddChildEntity(proxy, elementId)
    end
end

function XBWCourseCoreElementEntity:IsNil()
    return not XTool.IsNumberValid(self:GetElementId())
end

function XBWCourseCoreElementEntity:IsNew()
    if not self:IsNil() then
        return not self._Model:CheckCoreElementBrowsed(self:GetVersionId(), self:GetElementId())
    end

    return false
end

function XBWCourseCoreElementEntity:IsComplete()
    if not self._Proxy then
        return
    end 
    return self._Proxy:IsComplete()
end

function XBWCourseCoreElementEntity:IsSkip()
    if not self._Proxy then
        return
    end

    return self._Proxy:IsSkip()
end

function XBWCourseCoreElementEntity:IsHaveTeach()
    local teachId = self:GetTeachId()

    return XTool.IsNumberValid(teachId) and XMVCA.XBigWorldTeach:CheckTeachUnlock(teachId)
end

function XBWCourseCoreElementEntity:IsLocked()
    if not self._Proxy then
        return
    end
    return self._Proxy:IsLocked()
end

function XBWCourseCoreElementEntity:IsSkipStateChange()
    if not self:IsNil() then
        return (not self:IsLocked()) and self:IsSkip() and not self._Model:GetCoreElementRecord(self:GetElementId())
    end

    return false
end

function XBWCourseCoreElementEntity:SetElementId(elementId)
    self._ElementId = elementId or 0
end

function XBWCourseCoreElementEntity:GetElementId()
    return self._ElementId
end

function XBWCourseCoreElementEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseCoreElementEntity:GetName()
    if not self._Proxy then
        return
    end
    return self._Proxy:GetName()
end

function XBWCourseCoreElementEntity:GetRewards()
    if not self._Proxy then
        return
    end
    return self._Proxy:GetRewards()
end

function XBWCourseCoreElementEntity:GetExtraItems()
    if not self._Proxy then
        return
    end
    return self._Proxy:GetExtraItems()
end

---@return table<string, string>
function XBWCourseCoreElementEntity:GetProgressTipData()
    if not self._Proxy then
        return
    end
    return self._Proxy:GetProgressTipData()
end

function XBWCourseCoreElementEntity:GetTeachId()
    if not self._Proxy then
        return
    end
    return self._Proxy:GetTeachId()
end

function XBWCourseCoreElementEntity:GetSkipBtnName()
    if not self._Proxy then
        return
    end
    return self._Proxy:GetSkipBtnName()
end

function XBWCourseCoreElementEntity:GetEntryType()
    if self:IsNil() then
        return XMVCA.XBigWorldCourse.CoreEntryType.None
    end
    return self._Model:GetBigWorldCourseCoreElementEntryTypeById(self:GetElementId())
end

function XBWCourseCoreElementEntity:GetSkipId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementSkipIdById(self:GetElementId())
    end

    return 0
end

function XBWCourseCoreElementEntity:GetCurrentSkipId()
    if not self:IsNil() then
        local conditionIds = self:GetLockSkipConditionIds()
        local lockSkipIds = self:GetLockSkipIds()

        if not XTool.IsTableEmpty(conditionIds) then
            for i, conditionId in pairs(conditionIds) do
                if not XMVCA.XBigWorldService:CheckCondition(conditionId) then
                    return lockSkipIds[i] or 0
                end
            end
        end

        return self:GetSkipId()
    end

    return 0
end

function XBWCourseCoreElementEntity:GetLockSkipIds()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementLockSkipIdsById(self:GetElementId())
    end

    return 0
end

function XBWCourseCoreElementEntity:GetUnableSkipTip()
    if not self:IsNil() and self:IsLocked() then
        local conditionIds = self:GetLockSkipConditionIds()

        if not XTool.IsTableEmpty(conditionIds) then
            for _, conditionId in pairs(conditionIds) do
                local isSuccess, text = XMVCA.XBigWorldService:CheckCondition(conditionId)

                if not isSuccess and not string.IsNilOrEmpty(text) then
                    return text
                end
            end
        end
    end

    return XMVCA.XBigWorldService:GetText("BigWorldCourseCoreSkipUnableTip")
end

function XBWCourseCoreElementEntity:GetLockSkipConditionIds()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementLockSkipConditionIdsById(self:GetElementId())
    end

    return 0
end

function XBWCourseCoreElementEntity:GetBackground()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreElementBackgroundById(self:GetElementId())
    end

    return ""
end

function XBWCourseCoreElementEntity:RecordSkipState()
    if not self:IsNil() then
        if self:IsSkip() then
            self._Model:SetCoreElementRecord(self:GetElementId())
        end
    end
end

function XBWCourseCoreElementEntity:IsShowEarlyAccess()
    local elmId = self:GetElementId()
    local customParamId = self._Model:GetBigWorldCourseCoreElementCustomParamIdById(elmId)
    if not customParamId or customParamId <= 0 then
        return false
    else
        if XMVCA.XBigWorldGamePlay:GetCurrentAgency():CheckParamMarked(customParamId) then
            return false
        end
    end
    if self:IsComplete() then
        return false
    end
    local locked, _ = self:IsLocked()
    if not locked then
        return false
    end
    local earlyAccessSkipIds = self._Model:GetBigWorldCourseCoreElementEarlyAccessSkipIdsById(elmId)
    return not XTool.IsTableEmpty(earlyAccessSkipIds)
end

function XBWCourseCoreElementEntity:OpenPopupAdvance()
    local elmId = self:GetElementId()
    local earlyAccessSkipIds = self._Model:GetBigWorldCourseCoreElementEarlyAccessSkipIdsById(elmId)
    if XTool.IsTableEmpty(earlyAccessSkipIds) then
        return
    end
    local customParamId = self._Model:GetBigWorldCourseCoreElementCustomParamIdById(elmId)
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupAdvance", earlyAccessSkipIds, customParamId)
end

return XBWCourseCoreElementEntity
