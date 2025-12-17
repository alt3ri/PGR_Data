local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

local XLineArithmetic2Util = {}

---@param game XLineArithmetic2Game@ game
---@param grid XLineArithmetic2Grid@ 发射终点格 
---@param directionNormalized XLuaVector2@ 发射方向, 长度为1
function XLineArithmetic2Util.FindGrid2Shot(game, grid, directionNormalized)
    -- 普通染色子弹
    if grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE then
        local p = grid:GetPos()
        local nextP = XLuaVector2.New(p.x, p.y)
        for i = 1, 99 do
            nextP.x = nextP.x + directionNormalized.x
            nextP.y = nextP.y + directionNormalized.y
            if game:IsInMap(nextP) then
                local grid2Color = game:GetGrid(nextP)
                if grid2Color then
                    if grid2Color:IsCanColor() then
                        return grid2Color
                    end
                    break
                end
            else
                -- 超出棋盘
                break
            end
        end
        return false
    end

    -- 穿透染色子弹
    if grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH then
        local p = grid:GetPos()
        local nextP = XLuaVector2.New(p.x, p.y)
        local grids = {}
        for i = 1, 99 do
            nextP.x = nextP.x + directionNormalized.x
            nextP.y = nextP.y + directionNormalized.y
            if game:IsInMap(nextP) then
                local grid2Color = game:GetGrid(nextP)
                if grid2Color and grid2Color:IsCanColor() then
                    grids[#grids + 1] = grid2Color
                end
            else
                -- 超出棋盘
                break
            end
        end
        return grids
    end

    XLog.Error("[XLineArithmetic2Util] 未处理的子弹类型")
end

return XLineArithmetic2Util