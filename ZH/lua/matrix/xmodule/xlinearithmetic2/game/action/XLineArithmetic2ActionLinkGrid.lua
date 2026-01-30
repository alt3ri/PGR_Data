local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2Action = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2Action")

---@class XLineArithmetic2ActionLinkGrid: XLineArithmetic2Action
local XLineArithmetic2ActionLinkGrid = XClass(XLineArithmetic2Action, "XLineArithmetic2ActionLinkGrid")

function XLineArithmetic2ActionLinkGrid:Ctor()
    self._Type = XLineArithmetic2Enum.ACTION.LINK_GRID
    ---@type XLuaVector2
    self._Pos = XLuaVector2.New()
    self._IsRemove = false
end

function XLineArithmetic2ActionLinkGrid:SetPos(pos)
    self._Pos.x = pos.x
    self._Pos.y = pos.y
end

function XLineArithmetic2ActionLinkGrid:SetIsRemove(value)
    self._IsRemove = value
end

---@param game XLineArithmetic2Game
---@param model XLineArithmetic2Model
function XLineArithmetic2ActionLinkGrid:Execute(game, model)
    local grid = game:GetGrid(self._Pos)
    if not grid then
        XLog.Error("[XLineArithmetic2ActionLinkGrid] 要连接的格子不存在")
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end
    local gridList = game:GetLineGridList()

    if self._IsRemove then
        local beginIndex
        for i = 1, #gridList do
            local g = gridList[i]
            if g:Equals(grid) then
                beginIndex = i
            end
        end
        if beginIndex then
            for i = beginIndex, #gridList do
                gridList[i]:SetSelected(false)
                gridList[i] = nil
            end
        else
            XLog.Error("[XLineArithmetic2ActionLinkGrid] 找不到连线中要移除的格子")
        end
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    gridList[#gridList + 1] = grid
    grid:SetSelected(true)
    self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
end

return XLineArithmetic2ActionLinkGrid