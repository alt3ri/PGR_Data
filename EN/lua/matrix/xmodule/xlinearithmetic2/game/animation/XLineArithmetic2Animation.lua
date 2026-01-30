local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2Animation
local XLineArithmetic2Animation = XClass(nil, "XLineArithmetic2Animation")

function XLineArithmetic2Animation:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.NONE
    self._State = XLineArithmetic2Enum.ANIMATION_STATE.NONE
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2Animation:Update(game, ui, deltaTime)
    self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
end

function XLineArithmetic2Animation:IsFinish()
    return self._State == XLineArithmetic2Enum.ANIMATION_STATE.FINISH
end

return XLineArithmetic2Animation
