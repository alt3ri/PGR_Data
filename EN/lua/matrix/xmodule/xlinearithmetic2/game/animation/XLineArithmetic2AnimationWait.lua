local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationWait : XLineArithmetic2Animation
local XLineArithmetic2AnimationWait = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationWait")

function XLineArithmetic2AnimationWait:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.WAIT
    self._Duration = 0
    self._Passed = 0
end

function XLineArithmetic2AnimationWait:SetData(duration)
    self._Duration = duration
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationWait:Update(game, ui, deltaTime)
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING
        return
    end
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.PLAYING then
        self._Passed = self._Passed + deltaTime

        if self._Passed >= self._Duration then
            self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
        end
    end
end

return XLineArithmetic2AnimationWait