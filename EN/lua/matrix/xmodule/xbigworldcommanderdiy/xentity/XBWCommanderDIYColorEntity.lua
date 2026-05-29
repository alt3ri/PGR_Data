local XBWCommanderDIYEntityBase = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYEntityBase")

---@class XBWCommanderDIYColorEntity : XBWCommanderDIYEntityBase
local XBWCommanderDIYColorEntity = XClass(XBWCommanderDIYEntityBase, "XBWCommanderDIYColorEntity")

function XBWCommanderDIYColorEntity:Ctor()
    self._ColorId = 0
end

function XBWCommanderDIYColorEntity:SetData(colorId)
    self:SetColorId(colorId)
end

function XBWCommanderDIYColorEntity:IsEmpty()
    return not XTool.IsNumberValid(self:GetColorId())
end

function XBWCommanderDIYColorEntity:SetColorId(colorId)
    self._ColorId = colorId
end

function XBWCommanderDIYColorEntity:GetColorId()
    return self._ColorId
end

function XBWCommanderDIYColorEntity:GetPartId()
    local entity = self:GetPartEntity()

    if entity and not entity:IsNil() then
        return entity:GetPartId()
    else
        return 0
    end
end

function XBWCommanderDIYColorEntity:GetMaterialName()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionColorMaterialNameById(self:GetColorId())
    end

    return ""
end

function XBWCommanderDIYColorEntity:GetModelId()
    local partEntity = self:GetPartEntity()

    if partEntity then
        return partEntity:GetModelId()
    else
        return ""
    end
end

---@return XBWCommanderDIYPartEntity
function XBWCommanderDIYColorEntity:GetPartEntity()
    return self._ParentEntity
end

function XBWCommanderDIYColorEntity:GetIcon()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionColorIconById(self:GetColorId())
    end

    return ""
end

function XBWCommanderDIYColorEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionColorPriorityById(self:GetColorId())
    end

    return 0
end

function XBWCommanderDIYColorEntity:GetMaterialConfigs()
    if not self:IsNil() then
        local modelId = self:GetModelId()

        if not string.IsNilOrEmpty(modelId) then
            return self._OwnControl:GetMaterialConfigs(modelId, self:GetColorId())
        end
    end

    return {}
end

function XBWCommanderDIYColorEntity:OnRelease()
    self._ColorId = 0
end

return XBWCommanderDIYColorEntity
