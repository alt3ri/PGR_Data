local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationRevertGridState : XLineArithmetic2Animation
local XLineArithmetic2AnimationRevertGridState = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationRevertGridState")

function XLineArithmetic2AnimationRevertGridState:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.COLOR
    self._Duration = 0
    self._Passed = 0
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationRevertGridState:Update(game, ui, deltaTime)
    self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
    ui:RevertGridStateBeforeAnimation()
end

return XLineArithmetic2AnimationRevertGridState