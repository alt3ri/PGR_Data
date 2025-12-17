local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationGridEnable : XLineArithmetic2Animation
local XLineArithmetic2AnimationGridEnable = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationGridEnable")

function XLineArithmetic2AnimationGridEnable:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.GRID_ENABLE
    self._Duration = 0
    self._Passed = 0
    self._GridUid = 0
end

function XLineArithmetic2AnimationGridEnable:SetData(gridUid)
    self._GridUid = gridUid
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationGridEnable:Update(game, ui, deltaTime)
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING
        local grid = ui:GetGrid(self._GridUid)
        if grid then
            grid:PlayAnimation("GridEnable")
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

return XLineArithmetic2AnimationGridEnable