local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationGroup : XLineArithmetic2Animation
local XLineArithmetic2AnimationGroup = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationGroup")

function XLineArithmetic2AnimationGroup:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.GROUP
    ---@type XLineArithmetic2Animation[]
    self._Animations = {}
end

---@param animation XLineArithmetic2Animation
function XLineArithmetic2AnimationGroup:Add(animation)
    self._Animations[#self._Animations + 1] = animation
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationGroup:Update(game, ui, deltaTime)
    local count = 0
    for _, animation in ipairs(self._Animations) do
        animation:Update(game, ui, deltaTime)
        if animation:IsFinish() then
            count = count + 1
        end
    end
    if count == #self._Animations then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
    end
end

return XLineArithmetic2AnimationGroup
