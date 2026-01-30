---@class XSGDroneEntityBase : XEntity
---@field _OwnControl XSkyGardenDroneGameControl
---@field _Model XSkyGardenDroneGameModel
local XSGDroneEntityBase = XClass(XEntity, "XSGDroneEntityBase")

function XSGDroneEntityBase:IsNil()
    return true
end

return XSGDroneEntityBase
