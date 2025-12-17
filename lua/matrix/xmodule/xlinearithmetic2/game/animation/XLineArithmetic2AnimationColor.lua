local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationColor : XLineArithmetic2Animation
local XLineArithmetic2AnimationColor = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationColor")

function XLineArithmetic2AnimationColor:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.COLOR
    self._Duration = 0
    self._Passed = 0
    self._GridUid = 0
    self._ColorAnimation = XLineArithmetic2Enum.COLOR_ANIMATION.NONE
end

function XLineArithmetic2AnimationColor:SetData(gridUid, colorAnimation, duration)
    self._GridUid = gridUid
    self._ColorAnimation = colorAnimation
    self._Duration = duration
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationColor:Update(game, ui, deltaTime)
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING
        local grid = ui:GetGrid(self._GridUid)
        if grid then
            grid:PlayAnimation(self._ColorAnimation)
        end
        return
    end
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.PLAYING then
        self._Passed = self._Passed + deltaTime
        if self._Passed >= self._Duration then
            self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
        end
    end
end

return XLineArithmetic2AnimationColor