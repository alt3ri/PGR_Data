local XLineArithmetic2Animation = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2Animation")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2AnimationMoveGrid : XLineArithmetic2Animation
local XLineArithmetic2AnimationMoveGrid = XClass(XLineArithmetic2Animation, "XLineArithmetic2AnimationMoveGrid")

function XLineArithmetic2AnimationMoveGrid:Ctor()
    self._Type = XLineArithmetic2Enum.ANIMATION.MOVE_GRID
    self._Duration = 0.2
    self._Passed = 0

    self._GridUid = 0
    self._TargetPos = false
    self._StartPos = false
end

function XLineArithmetic2AnimationMoveGrid:SetData(gridUid, targetPos)
    self._GridUid = gridUid
    self._TargetPos = targetPos
end

---@param game XLineArithmetic2Game
---@param ui XUiLineArithmetic2Game
---@param deltaTime number
function XLineArithmetic2AnimationMoveGrid:Update(game, ui, deltaTime)
    local grid = ui:GetGrid(self._GridUid)
    if not grid then
        XLog.Error("[XLineArithmetic2AnimationMoveGrid] 找不到要移动的grid:" .. tostring(self._GridUid))
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
        return
    end
    if self._State == XLineArithmetic2Enum.ANIMATION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.PLAYING
        -- 设置格子层级到最低,避免挡住
        grid.Transform:SetAsFirstSibling()
        --grid.Transform:SetAsLastSibling()
    end
    self._Passed = self._Passed + deltaTime
    local progress = self._Passed / self._Duration
    if progress >= 1 then
        progress = 1
        self._State = XLineArithmetic2Enum.ANIMATION_STATE.FINISH
    end

    local currentPos = grid.Transform.localPosition
    if not self._StartPos then
        self._StartPos = currentPos
    end
    local targetPos = self._TargetPos
    local posToMove = CS.UnityEngine.Vector3.Lerp(self._StartPos, targetPos, progress)
    grid.Transform.localPosition = posToMove
end

return XLineArithmetic2AnimationMoveGrid