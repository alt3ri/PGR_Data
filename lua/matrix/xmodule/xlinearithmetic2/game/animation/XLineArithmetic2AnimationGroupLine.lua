local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationGroupLine : XLineArithmetic2Animation
local XLineArithmetic2AnimationGroupLine = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationGroupLine")

function XLineArithmetic2AnimationGroupLine:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.GROUP_LINE
    ---@type XLineArithmetic2Animation[]
    self._Animations = {}
    self._Index = 1
end

---@param animation XLineArithmetic2Animation
function XLineArithmetic2AnimationGroupLine:Add(animation)
    self._Animations[#self._Animations + 1] = animation
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationGroupLine:Update(game, ui, deltaTime)
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING
    end
    local animation = self._Animations[self._Index]
    if animation then
        animation:Update(game, ui, deltaTime)
        if animation:IsFinish() then
            self._Index = self._Index + 1
        end
    else
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
    end
end

return XLineArithmetic2AnimationGroupLine
