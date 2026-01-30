local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XLineArithmetic2Grid
local XLineArithmetic2Grid = XClass(nil, "XLineArithmetic2Grid")

function XLineArithmetic2Grid:Ctor(uid)
    self._Uid = uid or 0
    self._Id = 0
    self._CellName = false
    self._Type = XLineArithmetic2Enum.GRID.NONE
    self._Pos = XLuaVector2.New()

    self._IsSelected = false
    self._IsCanColor = false
    self._IsCanMove = false
    self._Color = XLineArithmetic2Enum.COLOR.NONE
    self._Capacity = 0
    self._ExtraScore = 0
    self._InitScore = 0

    -- 子弹相关
    self._Bullet = 0
    self._BulletColorType = XLineArithmetic2Enum.COLOR.NONE
    self._ShotState = XLineArithmetic2Enum.SHOT_STATE.NONE
    self._ShotDirection = XLuaVector2.New()
    self._FillGridId = 0
    self._ColorAddScore = 0
end

---@param config XTableLineArithmetic2Cell
function XLineArithmetic2Grid:SetDataFromConfig(config)
    if not config then
        XLog.Error("[XLineArithmetic2Grid] 不存在的格子配置")
        return
    end
    self._Id = config.Id
    self._Type = config.Type
    self._ExtraScore = 0
    self._InitScore = config.InitialScore
    self._IsCanColor = config.CanDye
    self._IsCanMove = config.CanMerge
    self._Capacity = config.Capacity
    self._ColorAddScore = config.DyeAddScore
    self._Bullet = config.BulletNum
    self._BulletColorType = config.BulletColorType
    self._FillGridId = config.ManifestId
    self._CellName = config.CellName
    self._Color = config.Color
end

---@return XLuaVector2
function XLineArithmetic2Grid:GetPos()
    return self._Pos
end

function XLineArithmetic2Grid:SetPos(pos)
    self._Pos.x = pos.x
    self._Pos.y = pos.y
end

function XLineArithmetic2Grid:SetPosByXY(x, y)
    self._Pos.x = x
    self._Pos.y = y
end

---@param grid XLineArithmetic2Grid
function XLineArithmetic2Grid:IsNeighbour(grid)
    local pos = grid:GetPos()
    local x1 = pos.x
    local y1 = pos.y
    local selfPos = self:GetPos()
    local x2 = selfPos.x
    local y2 = selfPos.y
    if x1 == x2 + 1 and y1 == y2 then
        return true
    end
    if x1 == x2 - 1 and y1 == y2 then
        return true
    end
    if x1 == x2 and y1 == y2 - 1 then
        return true
    end
    if x1 == x2 and y1 == y2 + 1 then
        return true
    end
    return false
end

function XLineArithmetic2Grid:GetUid()
    return self._Uid
end

---@param grid XLineArithmetic2Grid
function XLineArithmetic2Grid:Equals(grid)
    if not grid then
        XLog.Error("[XLineArithmetic2Grid] 比较格子相等错误")
        return false
    end
    return self:GetUid() == grid:GetUid()
end

function XLineArithmetic2Grid:IsEmpty()
    return self._Type == XLineArithmetic2Enum.GRID.NONE
end

function XLineArithmetic2Grid:GetType()
    return self._Type
end

function XLineArithmetic2Grid:GetScore()
    return self._ExtraScore + self._InitScore
end

function XLineArithmetic2Grid:SetType(gridType)
    self._Type = gridType
end

function XLineArithmetic2Grid:SetCapacity(value)
    if value < 0 then
        XLog.Error("[XLineArithmetic2Grid] 设置格子容量错误:" .. value)
        self._Capacity = 0
        return
    end
    self._Capacity = value
end

function XLineArithmetic2Grid:GetCapacity()
    return self._Capacity
end

function XLineArithmetic2Grid:SetBullet(value)
    if value < 0 then
        XLog.Error("[XLineArithmetic2Grid] 设置格子子弹错误:" .. value)
        self._Bullet = 0
        return
    end
    self._Bullet = value
end

function XLineArithmetic2Grid:GetBullet()
    return self._Bullet
end

function XLineArithmetic2Grid:SetShotState(value)
    self._ShotState = value
end

function XLineArithmetic2Grid:GetShotState()
    return self._ShotState
end

function XLineArithmetic2Grid:ClearShotDirection()
    self._ShotDirection.x = 0
    self._ShotDirection.y = 0
end

function XLineArithmetic2Grid:SetShotDirection(direction)
    self._ShotDirection.x = direction.x
    self._ShotDirection.y = direction.y
end

function XLineArithmetic2Grid:GetShotDirection()
    return self._ShotDirection
end

function XLineArithmetic2Grid:IsCanColor()
    return self._IsCanColor
end

function XLineArithmetic2Grid:SetBulletColor(color)
    self._BulletColorType = color
end

function XLineArithmetic2Grid:GetBulletColor()
    return self._BulletColorType
end

---@param model XLineArithmetic2Model
function XLineArithmetic2Grid:SetColor(color, model, addScore)
    -- 先换分数
    if color ~= XLineArithmetic2Enum.COLOR.NONE then
        local grids = model:GetGrids()
        for id, config in pairs(grids) do
            if config.Type == self._Type then
                if config.Color == color then
                    self._InitScore = config.InitialScore
                    break
                end
            end
        end
    end
    
    -- 染色加分
    if addScore then
        if self._Type == XLineArithmetic2Enum.GRID.COLOR_SCORE then
            if self._Color ~= color then
                if self._Color ~= XLineArithmetic2Enum.COLOR.NONE then
                    XLog.Debug(string.format("[XLineArithmetic2Grid] 触发染色加分, 从%s到%s", self._ExtraScore, self._ExtraScore + self._ColorAddScore))
                    self._ExtraScore = self._ColorAddScore + self._ExtraScore
                end
            end
        end
    end
    self._Color = color
end

function XLineArithmetic2Grid:GetColor()
    return self._Color
end

function XLineArithmetic2Grid:GetFillGridId()
    return self._FillGridId
end

function XLineArithmetic2Grid:SetFillGridId(value)
    self._FillGridId = value
end

function XLineArithmetic2Grid:SetSelected(value)
    self._IsSelected = value
    --if not value then
    --    print("selected", self._Pos.x, self._Pos.y)
    --end
end

function XLineArithmetic2Grid:IsSelected()
    return self._IsSelected
end

function XLineArithmetic2Grid:GetCellName()
    return self._CellName
end

function XLineArithmetic2Grid:IsFinish()
    return self._Capacity <= 0
end

function XLineArithmetic2Grid:IsEndGrid()
    return self._Type == XLineArithmetic2Enum.GRID.END
            or self._Type == XLineArithmetic2Enum.GRID.END_FILL
            or self._Type == XLineArithmetic2Enum.GRID.END_COLOR_ONE
            or self._Type == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
end

---@param grid XLineArithmetic2Grid
function XLineArithmetic2Grid:Clone(grid)
    grid = grid or XLineArithmetic2Grid.New()
    grid._Uid = self._Uid
    grid._Id = self._Id
    grid._Pos.x = self._Pos.x
    grid._Pos.y = self._Pos.y
    grid._Type = self._Type
    grid._ExtraScore = self._ExtraScore
    grid._InitScore = self._InitScore
    grid._IsCanColor = self._IsCanColor
    grid._IsCanMove = self._IsCanMove
    grid._Capacity = self._Capacity
    grid._ColorAddScore = self._ColorAddScore
    grid._Bullet = self._Bullet
    grid._BulletColorType = self._BulletColorType
    grid._FillGridId = self._FillGridId
    grid._CellName = self._CellName
    grid._Color = self._Color
    grid._ShotState = self._ShotState
    grid._ShotDirection.x = self._ShotDirection.x
    grid._ShotDirection.y = self._ShotDirection.y
    grid._IsSelected = self._IsSelected
    return grid
end

return XLineArithmetic2Grid
