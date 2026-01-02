local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")
local XBWCourseCoreElementEntity = require("XModule/XBigWorldCourse/XEntity/Core/XBWCourseCoreElementEntity")

---@class XBWCourseCoreEntity : XBWCourseEntityBase
---@field private _ParentEntity XBWCourseContentEntity
local XBWCourseCoreEntity = XClass(XBWCourseEntityBase, "XBWCourseCoreEntity")

function XBWCourseCoreEntity:OnInit(coreId)
    ---@type XBWCourseCoreElementEntity[]
    self._ElementEntitys = {}

    self:SetCoreId(coreId)
end

function XBWCourseCoreEntity:IsNil()
    return not XTool.IsNumberValid(self:GetCoreId())
end

function XBWCourseCoreEntity:IsGamePlay()
    return self:GetGroupType() == XEnumConst.BWCourse.CoreGroupType.GamePlay
end

function XBWCourseCoreEntity:IsQuest()
    return self:GetGroupType() == XEnumConst.BWCourse.CoreGroupType.Quest
end

function XBWCourseCoreEntity:IsNew()
    if not self:IsNil() then
        local elementEntitys = self:GetElementEntitys()

        if not XTool.IsTableEmpty(elementEntitys) then
            for _, elementEntity in pairs(elementEntitys) do
                if elementEntity:IsNew() or elementEntity:IsSkipStateChange() then
                    return true
                end
            end
        end
    end

    return false
end

function XBWCourseCoreEntity:IsUnlock()
    local conditionId = self:GetConditionId()

    if XTool.IsNumberValid(conditionId) then
        return XMVCA.XBigWorldService:CheckCondition(conditionId)
    end

    return true
end

function XBWCourseCoreEntity:SetCoreId(coreId)
    self._CoreId = coreId or 0
    self:_Init()
end

function XBWCourseCoreEntity:GetCoreId()
    return self._CoreId
end

function XBWCourseCoreEntity:GetContentId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreContentIdByCoreId(self:GetCoreId())
    end

    return 0
end

function XBWCourseCoreEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseCoreEntity:GetGroupId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreGroupIdByCoreId(self:GetCoreId())
    end

    return 0
end

function XBWCourseCoreEntity:GetConditionId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreConditionIdByCoreId(self:GetCoreId())
    end

    return 0
end

function XBWCourseCoreEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCorePriorityByCoreId(self:GetCoreId())
    end

    return 0
end

function XBWCourseCoreEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreNameByCoreId(self:GetCoreId())
    end

    return ""
end

function XBWCourseCoreEntity:GetLabelImage()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreLabelImageByCoreId(self:GetCoreId())
    end

    return ""
end

function XBWCourseCoreEntity:GetBanner()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreBannerByCoreId(self:GetCoreId())
    end

    return ""
end

function XBWCourseCoreEntity:GetSpineBanner()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseCoreSpineBannerByCoreId(self:GetCoreId())
    end

    return ""
end

function XBWCourseCoreEntity:GetGroupType()
    local groupId = self:GetGroupId()

    if XTool.IsNumberValid(groupId) then
        return self._Model:GetBigWorldCourseCoreGroupTypeByGroupId(groupId)
    end

    return XEnumConst.BWCourse.CoreGroupType.None
end

function XBWCourseCoreEntity:GetGroupPriority()
    local groupId = self:GetGroupId()

    if XTool.IsNumberValid(groupId) then
        return self._Model:GetBigWorldCourseCoreGroupPriorityByGroupId(groupId)
    end

    return 0
end

function XBWCourseCoreEntity:GetGroupName()
    local groupId = self:GetGroupId()

    if XTool.IsNumberValid(groupId) then
        return self._Model:GetBigWorldCourseCoreGroupNameByGroupId(groupId)
    end

    return ""
end

function XBWCourseCoreEntity:GetGroupLabelImage()
    local groupId = self:GetGroupId()

    if XTool.IsNumberValid(groupId) then
        return self._Model:GetBigWorldCourseCoreGroupLabelImageByGroupId(groupId)
    end

    return ""
end

---@return XBWCourseCoreElementEntity[]
function XBWCourseCoreEntity:GetElementEntitys()
    return self._ElementEntitys or {}
end

---@return XBWCourseCoreElementEntity[]
function XBWCourseCoreEntity:GetElementEntitysWithSort()
    local elementEntitys = self:GetElementEntitys()
    local result = {}

    if not XTool.IsTableEmpty(elementEntitys) then
        for _, elementEntity in pairs(elementEntitys) do
            table.insert(result, elementEntity)
        end
    end

    table.sort(result, function(elementA, elementB)
        local isCompleteA = elementA:IsComplete()
        local isCompleteB = elementB:IsComplete()

        if isCompleteA ~= isCompleteB then
            return not isCompleteA
        end

        return elementA:GetElementId() < elementB:GetElementId()
    end)

    return result
end

function XBWCourseCoreEntity:GetUnRecordElementIds()
    local elementEntitys = self:GetElementEntitys()
    local result = {}

    if not XTool.IsTableEmpty(elementEntitys) then
        for _, elementEntity in pairs(elementEntitys) do
            if elementEntity:IsNew() then
                table.insert(result, elementEntity:GetElementId())
            end
        end
    end

    return result
end

function XBWCourseCoreEntity:_Init()
    self._ElementEntitys = {}

    if not self:IsNil() then
        local elementIds = self._Model:GetBigWorldCourseCoreElementIdsByCoreId(self:GetCoreId())

        if not XTool.IsTableEmpty(elementIds) then
            for _, elementId in pairs(elementIds) do
                self:_AddElement(elementId)
            end
        end
    end
end

function XBWCourseCoreEntity:_AddElement(elementId)
    table.insert(self._ElementEntitys, self:AddChildEntity(XBWCourseCoreElementEntity, elementId))
end

return XBWCourseCoreEntity
