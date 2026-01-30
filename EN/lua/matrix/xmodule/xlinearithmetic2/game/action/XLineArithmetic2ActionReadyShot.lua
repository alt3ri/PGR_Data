local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2Action = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2Action")

---@class XLineArithmetic2ActionReadyShot:XLineArithmetic2Action
local XLineArithmetic2ActionReadyShot = XClass(XLineArithmetic2Action, "XLineArithmetic2ActionReadyShot")

function XLineArithmetic2ActionReadyShot:Ctor()
    self._Type = XLineArithmetic2Enum.ACTION.READY_SHOT
    self._Pos = false
    self._Direction = false
end

function XLineArithmetic2ActionReadyShot:SetPos(pos)
    self._Pos = pos
end

function XLineArithmetic2ActionReadyShot:SetDirection(direction)
    self._Direction = direction
end

---@param game XLineArithmetic2Game
---@param model XLineArithmetic2Model
function XLineArithmetic2ActionReadyShot:Execute(game, model)
    local grid = game:GetGrid(self._Pos)
    if not grid then
        XLog.Error("[XLineArithmetic2ActionReadyShot] 要发射的格子不存在")
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end
    grid:SetShotState(XLineArithmetic2Enum.SHOT_STATE.READY)
    if self._Direction then
        if math.abs(self._Direction.x) > math.abs(self._Direction.y) then
            if self._Direction.x > 0 then
                self._Direction.x = 1
            elseif self._Direction.x < 0 then
                self._Direction.x = -1
            end
            self._Direction.y = 0
        else
            self._Direction.x = 0
            if self._Direction.y > 0 then
                self._Direction.y = 1
            elseif self._Direction.y < 0 then
                self._Direction.y = -1
            end
        end
        if self._Direction.x > 0 and self._Direction.y > 0 then
            XLog.Error("[XLineArithmetic2ActionReadyShot] 发射的方向有问题")
        end
        grid:SetShotDirection(self._Direction)
        game:SetReadyShot(true, grid:GetPos())
    else
        game:SetReadyShot(false)
        grid:ClearShotDirection()
    end
    grid:SetSelected(true)

    local gridList = game:GetLineGridList()
    if #gridList == 0 then
        gridList[#gridList + 1] = grid
    end
    self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
end

return XLineArithmetic2ActionReadyShot