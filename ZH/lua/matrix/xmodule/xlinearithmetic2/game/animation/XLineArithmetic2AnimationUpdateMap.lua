local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationUpdateMap : XLineArithmetic2Animation
local XLineArithmetic2AnimationUpdateMap = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationUpdateMap")

function XLineArithmetic2AnimationUpdateMap:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.UPDATE_MAP
    self._MapData = false
    self._GridData = false
end

function XLineArithmetic2AnimationUpdateMap:SetMapData(mapData)
    self._MapData = mapData
end

function XLineArithmetic2AnimationUpdateMap:SetGridData(gridData)
    self._GridData = gridData
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationUpdateMap:Update(game, ui, deltaTime)
    self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
    if self._MapData then
        ui:UpdateMap(self._MapData)
    elseif self._GridData then
        ui:UpdateGrid(self._GridData)
    else
        ui:UpdateMap()
    end
end

return XLineArithmetic2AnimationUpdateMap