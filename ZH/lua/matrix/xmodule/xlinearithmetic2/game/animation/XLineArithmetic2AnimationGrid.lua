local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationGrid : XLineArithmetic2Animation
local XLineArithmetic2AnimationGrid = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationGrid")

function XLineArithmetic2AnimationGrid:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.GRID_EAT
    self._Duration = 0
    self._Passed = 0
    self._GridUid = 0
    self._AnimationName = ""
end

function XLineArithmetic2AnimationGrid:SetData(gridUid, animationName, duration)
    self._GridUid = gridUid
    self._AnimationName = animationName
    self._Duration = duration
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationGrid:Update(game, ui, deltaTime)
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING
        local grid = ui:GetGrid(self._GridUid)
        if grid then
            grid:PlayAnimation(self._AnimationName)
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

return XLineArithmetic2AnimationGrid