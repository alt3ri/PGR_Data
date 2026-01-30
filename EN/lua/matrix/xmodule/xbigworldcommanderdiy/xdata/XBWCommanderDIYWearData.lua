---@class XBWCommanderDIYWearData
local XBWCommanderDIYWearData = XClass(nil, "XBWCommanderDIYWearData")

function XBWCommanderDIYWearData:Ctor(typeId, partId, colorId)
    self:SetTypeId(typeId)
    self:SetPartId(partId)
    self:SetColorId(colorId)
end

function XBWCommanderDIYWearData:IsEmpty()
    return not XTool.IsNumberValid(self:GetTypeId())
end

function XBWCommanderDIYWearData:IsWaeredColor()
    return XTool.IsNumberValid(self:GetColorId())
end

function XBWCommanderDIYWearData:IsWaeredPart()
    return XTool.IsNumberValid(self:GetPartId())
end

function XBWCommanderDIYWearData:IsFashion()
    if not self:IsEmpty() then
        return XMVCA.XBigWorldCommanderDIY:CheckTypeFashion(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYWearData:IsSuit()
    if not self:IsEmpty() then
        return XMVCA.XBigWorldCommanderDIY:CheckTypeSuit(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYWearData:IsSuitPart()
    if not self:IsEmpty() and self:IsWaeredPart() then
        return XMVCA.XBigWorldCommanderDIY:CheckPartSuit(self:GetPartId())
    end

    return false
end

function XBWCommanderDIYWearData:IsRequired()
    if not self:IsEmpty() then
        return XMVCA.XBigWorldCommanderDIY:CheckTypeRequired(self:GetTypeId())
    end

    return false
end

---@param other XBWCommanderDIYWearData
function XBWCommanderDIYWearData:IsEqual(other)
    if not other then
        return false
    end
    if self:IsEmpty() and other:IsEmpty() then
        return true
    end
    if self:IsEmpty() or other:IsEmpty() then
        return false
    end

    return self:GetTypeId() == other:GetTypeId() and self:GetPartId() == other:GetPartId() and self:GetColorId() == other:GetColorId()
end

function XBWCommanderDIYWearData:SetTypeId(typeId)
    self._TypeId = typeId or 0
    self:ClearPart()
end

function XBWCommanderDIYWearData:GetTypeId()
    return self._TypeId
end

function XBWCommanderDIYWearData:SetPartId(partId)
    self._PartId = partId or 0
    self:ClearColor()
end

function XBWCommanderDIYWearData:GetPartId()
    if not self:IsEmpty() then
        if XTool.IsNumberValid(self._PartId) then
            return self._PartId
        end
        if self:IsRequired() then
            return XMVCA.XBigWorldCommanderDIY:GetTypeDefaultPartId(self:GetTypeId())
        end
    end

    return 0
end

function XBWCommanderDIYWearData:SetColorId(colorId)
    self._ColorId = colorId or 0
end

function XBWCommanderDIYWearData:GetColorId()
    if not self:IsEmpty() and self:IsWaeredPart() then
        if XMVCA.XBigWorldCommanderDIY:CheckCurrentAllowSelectColor(self:GetPartId()) then
            if XTool.IsNumberValid(self._ColorId) then
                return self._ColorId
            end
        end

        return XMVCA.XBigWorldCommanderDIY:GetPartDefaultColorId(self:GetPartId())
    end

    return 0
end

function XBWCommanderDIYWearData:GetColorIdByGender(gender)
    if not self:IsEmpty() and self:IsWaeredPart() then
        return XMVCA.XBigWorldCommanderDIY:GetUseColorByGender(self:GetPartId(), gender)
    end

    return 0
end

function XBWCommanderDIYWearData:GetCurrentResId()
    if not self:IsEmpty() and self:IsWaeredPart() then
        return XMVCA.XBigWorldCommanderDIY:GetCurrentResIdByPartId(self:GetPartId())
    end

    return 0
end

function XBWCommanderDIYWearData:GetCurrentFashionId()
    if self:IsFashion() and self:IsWaeredPart() then
        return XMVCA.XBigWorldCommanderDIY:GetFashionIdByResId(self:GetCurrentResId())
    end

    return 0
end

function XBWCommanderDIYWearData:GetModelId()
    if not self:IsEmpty() then
        if self:IsFashion() then
            return XMVCA.XBigWorldCharacter:GetUiModelIdByFashionId(self:GetCurrentFashionId())
        elseif not self:IsSuit() then
            return XMVCA.XBigWorldCommanderDIY:GetCurrentPartModelIdByPartId(self:GetPartId())
        end
    end

    return ""
end

function XBWCommanderDIYWearData:GetColorMaterials()
    if not self:IsEmpty() and self:IsWaeredColor() then
        local colorId = self:GetColorId()
        local modelId = self:GetModelId()
        local colorName = XMVCA.XBigWorldCommanderDIY:GetMaterialNameByColorId(colorId)

        if not string.IsNilOrEmpty(modelId) and not string.IsNilOrEmpty(colorName) then
            return XMVCA.XBigWorldResource:GetPartModelMaterials(modelId, colorName)
        end
    end

    return nil
end

function XBWCommanderDIYWearData:Clear()
    self:SetTypeId(0)
end

function XBWCommanderDIYWearData:ClearColor()
    self:SetColorId(0)
end

function XBWCommanderDIYWearData:ClearPart()
    self:SetPartId(0)
end

---@return XBWCommanderDIYWearData
function XBWCommanderDIYWearData:Clone()
    return XBWCommanderDIYWearData.New(self:GetTypeId(), self:GetPartId(), self:GetColorId())
end

---@param other XBWCommanderDIYWearData
function XBWCommanderDIYWearData:CopyFrom(other)
    if other then
        self:Clear()
        self._TypeId = other._TypeId
        self._PartId = other._PartId
        self._ColorId = other._ColorId
    end
end

function XBWCommanderDIYWearData:ToData(gender)
    if not XTool.IsNumberValid(gender) then
        return {
            PartId = self:GetPartId(),
            ColourId = self:GetColorId(),
        }
    end

    return {
        PartId = self:GetPartId(),
        ColourId = self:GetColorIdByGender(gender),
    }
end

return XBWCommanderDIYWearData
