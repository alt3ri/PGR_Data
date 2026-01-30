local XTheatre5GameEntityBase = require('XModule/XTheatre5/ControlEntity/XTheatre5GameEntityBase')

--- PVP玩法内Entity
---@class XTheatre5PVPGameEntity: XTheatre5GameEntityBase
---@field protected _Model XTheatre5Model
local XTheatre5PVPGameEntity = XClass(XTheatre5GameEntityBase, 'XTheatre5PVPGameEntity')

function XTheatre5PVPGameEntity:OnInit()
    self._Data = self._Model.PVPAdventureData
end

function XTheatre5PVPGameEntity:OnRelease()
    self._Data = nil
end

---@overload
function XTheatre5PVPGameEntity:GetCurRoundGridUnlockCostReduce()
    local turns = self._Data:GetRoundNumWithoutGridUnlock()

    local baseReduce = self._Model:GetTheatre5ConfigValByKey('PvpGridUnlockDiscount')

    return baseReduce * turns
end

function XTheatre5PVPGameEntity:GetRuneGridInitCount()
    return self._Model:GetTheatre5ConfigValByKey('RuneGridMinNum')
end

return XTheatre5PVPGameEntity