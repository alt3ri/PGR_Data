local XBWCommanderDIYEntityBase = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYEntityBase")
local XBWCommanderDIYPartEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYPartEntity")
local XBWCommanderDIYEmptyPartEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYEmptyPartEntity")

---@class XBWCommanderDIYTypeEntity : XBWCommanderDIYEntityBase
local XBWCommanderDIYTypeEntity = XClass(XBWCommanderDIYEntityBase, "XBWCommanderDIYTypeEntity")

function XBWCommanderDIYTypeEntity:Ctor()
    self._TypeId = 0
    ---@type XBWCommanderDIYPartEntity[]
    self._PartEntitys = false
    ---@type XBWCommanderDIYPartEntity[]
    self._SuitPartEntitys = false

    ---@type XBWCommanderDIYEmptyPartEntity
    self._TemporaryEntity = false
end

function XBWCommanderDIYTypeEntity:SetData(typeId)
    self:SetTypeId(typeId)
    self:_InitPart()
end

function XBWCommanderDIYTypeEntity:IsEmpty()
    return not XTool.IsNumberValid(self:GetTypeId())
end

function XBWCommanderDIYTypeEntity:SetTypeId(typeId)
    self._TypeId = typeId
end

function XBWCommanderDIYTypeEntity:GetTypeId()
    return self._TypeId
end

function XBWCommanderDIYTypeEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeNameByTypeId(self:GetTypeId())
    end

    return ""
end

function XBWCommanderDIYTypeEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypePriorityByTypeId(self:GetTypeId())
    end

    return 0
end

function XBWCommanderDIYTypeEntity:IsRequired()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsRequiredByTypeId(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYTypeEntity:IsFashion()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYTypeEntity:IsSuit()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsSuitByTypeId(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYTypeEntity:IsNew()
    if not self:IsNil() then
        local entitys = self:GetDisplayPartEntitys()

        if not XTool.IsTableEmpty(entitys) then
            for _, partEntity in pairs(entitys) do
                if partEntity:IsNew() then
                    return true
                end
            end
        end
    end

    return false
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetPartEntitysWithTemporary()
    if self:IsRequired() then
        return self:GetPartEntitys()
    end

    local result = {}
    local entitys = self:GetPartEntitys()
    local temporaryEntity = self:GetTemporaryPartEntity()

    if temporaryEntity then
        table.insert(result, self._TemporaryEntity)
    end
    if not XTool.IsTableEmpty(entitys) then
        for _, partEntity in pairs(entitys) do
            table.insert(result, partEntity)
        end
    end

    return result
end

---@return XBWCommanderDIYPartEntity
function XBWCommanderDIYTypeEntity:GetTemporaryPartEntity()
    if not self:IsRequired() then
        if not self._TemporaryEntity then
            self._TemporaryEntity = self:AddChildEntity(XBWCommanderDIYEmptyPartEntity, 0)
            self._TemporaryEntity:SetTypeId(self:GetTypeId())
        end

        return self._TemporaryEntity
    end

    return nil
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetPartEntitys()
    local result = {}

    if not XTool.IsTableEmpty(self._PartEntitys) then
        for _, partEntity in pairs(self._PartEntitys) do
            table.insert(result, partEntity)
        end
    end

    return result
end

---@return XBWCommanderDIYPartEntity
function XBWCommanderDIYTypeEntity:GetPartEntityByIndex(index)
    return self._PartEntitys[index]
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetPartEntitysWithSuit()
    local result = {}

    if self:GetTypeId() == XEnumConst.PlayerFashion.PartType.Fashion then
        local suitEntitys = self._OwnControl:GetSuitPartEntitys()

        if not XTool.IsTableEmpty(suitEntitys) then
            for _, suitEntity in pairs(suitEntitys) do
                table.insert(result, suitEntity)
            end
        end
    end

    if not XTool.IsTableEmpty(self._PartEntitys) then
        for _, partEntity in pairs(self._PartEntitys) do
            table.insert(result, partEntity)
        end
    end

    table.sort(result, function(entityA, entityB)
        if entityA:GetPriority() == entityB:GetPriority() then
            local isSuitA = entityA:IsSuit()
            local isSuitB = entityB:IsSuit()

            if isSuitA ~= isSuitB then
                return isSuitA
            end

            return entityA:GetPartId() < entityB:GetPartId()
        end

        return entityA:GetPriority() > entityB:GetPriority()
    end)

    return result
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetSuitPartEntitys()
    return self._SuitPartEntitys or {}
end

---@return XBWCommanderDIYPartEntity[]
function XBWCommanderDIYTypeEntity:GetDisplayPartEntitys()
    local result = {}
    local partEntitys = self:GetPartEntitysWithSuit()
    local temporaryEntity = self:GetTemporaryPartEntity()

    if temporaryEntity then
        table.insert(result, temporaryEntity)
    end
    if not XTool.IsTableEmpty(partEntitys) then
        for _, partEntity in pairs(partEntitys) do
            if partEntity:IsDisplay() then
                table.insert(result, partEntity)
            end
        end
    end

    return result
end

function XBWCommanderDIYTypeEntity:OnRelease()
    self._TypeId = 0
    self._PartEntitys = false
    self._SuitPartEntitys = false
end

function XBWCommanderDIYTypeEntity:_InitPart()
    if not self:IsNil() then
        local partIds = self._Model:GetDlcPlayerFashionPartGroupPartIdByTypeId(self:GetTypeId())

        self._PartEntitys = {}
        self._SuitPartEntitys = {}
        if not XTool.IsTableEmpty(partIds) then
            for _, partId in pairs(partIds) do
                local isSuitPart = self._Model:GetDlcPlayerFashionPartIsSuitPartById(partId)

                if isSuitPart then
                    self:_AddSuitPart(partId)
                else
                    self:_AddPart(partId)
                end
            end

            table.sort(self._PartEntitys, function(entityA, entityB)
                if entityA:GetPriority() == entityB:GetPriority() then
                    return entityA:GetPartId() < entityB:GetPartId()
                end

                return entityA:GetPriority() > entityB:GetPriority()
            end)
            table.sort(self._SuitPartEntitys, function(entityA, entityB)
                if entityA:GetPriority() == entityB:GetPriority() then
                    return entityA:GetPartId() < entityB:GetPartId()
                end

                return entityA:GetPriority() > entityB:GetPriority()
            end)
        end
    end
end

function XBWCommanderDIYTypeEntity:_AddPart(partId)
    table.insert(self._PartEntitys, self:AddChildEntity(XBWCommanderDIYPartEntity, partId))
end

function XBWCommanderDIYTypeEntity:_AddSuitPart(partId)
    table.insert(self._SuitPartEntitys, self:AddChildEntity(XBWCommanderDIYPartEntity, partId))
end

return XBWCommanderDIYTypeEntity
