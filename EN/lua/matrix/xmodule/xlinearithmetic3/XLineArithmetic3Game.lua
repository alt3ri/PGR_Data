local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")

--- 实现游戏逻辑，并生成供 UI 播放的指令，支持回退。
--- 9*7 棋盘一笔连线游戏：从 A 连到 B，车头与车厢沿路径移动，乘客上下车与染色。
---@class XLineArithmetic3Game
local XLineArithmetic3Game = XClass(nil, "XLineArithmetic3Game")

--- 附近方向增量：上、左、下、右
local DIR_DELTA = {
    { x = 0,  y = 1 }, -- Up
    { x = -1, y = 0 },  -- Left
    { x = 0,  y = -1 },  -- Down
    { x = 1,  y = 0 },  -- Right
}

function XLineArithmetic3Game:Ctor()
    ---@type table[][] 格子 runtime：{ Type, Passenger = { Color } or nil, StationColor }
    self._Map = {}
    ---@type { x: number, y: number }
    self._MapSize = { x = 9, y = 7 }

    ---@type { x: number, y: number }[] 当前连线路径（路）
    self._Path = {}
    ---@type { x: number, y: number }[] 已走过的路径（从起点到当前车头位置）
    self._TraveledPath = {}
    ---@type { x: number, y: number } 车头位置
    self._HeadPos = nil
    ---@type table[] 车厢：{ Pos = {x,y}, Passenger = { Color } or nil, JustDisembarkAt = {x,y} or nil }
    self._Carriages = {}
    ---@type number 车厢数量上限
    self._MaxCarriages = 2

    ---@type table[] 本笔即将播放的指令
    self._Instructions = {}

    ---@type number 全局累计指令步数基数（跨笔单调递增，用于步数缓存比较）
    self._InstructionIndexBase = 0

    ---@type table<string, number> 角色表情状态字典，key: "head" | "carriage_N" | "grid_x_y"，value: Emoj枚举
    self._EmojState = {}
end

---@param pos { x: number, y: number }
---@return boolean
function XLineArithmetic3Game:IsInMap(pos)
    if not pos then return false end
    return pos.x >= 1 and pos.x <= self._MapSize.x and pos.y >= 1 and pos.y <= self._MapSize.y
end

---@return boolean
function XLineArithmetic3Game:IsInMapNoallc(x, y)
    if not x or not y then
        return false
    end
    
    return x >= 1 and x <= self._MapSize.x and y >= 1 and y <= self._MapSize.y
end

---@param pos { x: number, y: number }
---@return table|nil 格子数据
function XLineArithmetic3Game:GetGrid(pos)
    if not self:IsInMap(pos) then return nil end
    local row = self._Map[pos.y]
    if not row then return nil end
    return row[pos.x]
end

---@param pos { x: number, y: number }
---@return table|nil 格子数据
function XLineArithmetic3Game:GetGridNoalloc(posX, posY)
    if not self:IsInMapNoallc(posX, posY) then
        return nil 
    end
    
    local row = self._Map[posY]
    
    if not row then
        return nil 
    end
    
    return row[posX]
end

---@param pos { x: number, y: number }
---@return { x: number, y: number }[] 上、左、下、右
function XLineArithmetic3Game:GetNeighbors(pos)
    local list = {}
    for _, d in ipairs(DIR_DELTA) do
        local n = { x = pos.x + d.x, y = pos.y + d.y }
        if self:IsInMap(n) then
            list[#list + 1] = n
        end
    end
    return list
end

--- 车站颜色：附近（乘客格或车站格）内乘客颜色，优先级上左下右；无则白色
---@param pos { x: number, y: number }
---@return number
function XLineArithmetic3Game:GetStationColorAt(pos)
    local GridType = XLineArithmetic3Enum.GridType
    for _, n in ipairs(self:GetNeighbors(pos)) do
        local g = self:GetGrid(n)
        if g then
            local passenger = (g.Passenger and g.Passenger.Color) and g.Passenger or nil
            -- 白色不传递
            if passenger and passenger.Color and passenger.Color ~= XLineArithmetic3Enum.Color.White then
                return g.Passenger.Color
            end
            -- if g.Type == GridType.Station and g.StationColor and g.StationColor ~= XLineArithmetic3Enum.Color.White then
            --     return g.StationColor
            -- end
        end
    end
    return XLineArithmetic3Enum.Color.White
end

--============================================================================
-- 表情状态管理
--============================================================================

-- 表情状态Key编码常量
local EmojKeyOffset = {
    Head = 0,           -- 车头key: 0
    Carriage = 1000,    -- 车厢key: 1000 + carriageIndex (1001, 1002, ...)
    Grid = 10000,       -- 格子key: 10000 + y * 100 + x (10101-10709)
}

--- 获取车头表情key
---@return number
function XLineArithmetic3Game:_GetHeadEmojKey()
    return EmojKeyOffset.Head
end

--- 获取车厢乘客表情key
---@param carriageIndex number 车厢索引
---@return number
function XLineArithmetic3Game:_GetCarriageEmojKey(carriageIndex)
    return EmojKeyOffset.Carriage + carriageIndex
end

--- 获取地图格子乘客表情key
---@param x number 格子X坐标
---@param y number 格子Y坐标
---@return number
function XLineArithmetic3Game:_GetGridEmojKey(x, y)
    return EmojKeyOffset.Grid + y * 100 + x
end

--- 获取表情状态
---@param key number 表情key
---@return number Emoj枚举
function XLineArithmetic3Game:GetEmojState(key)
    return self._EmojState[key] or XLineArithmetic3Enum.Emoj.Initial
end

--- 设置表情状态
---@param key number 表情key
---@param emoj number Emoj枚举
function XLineArithmetic3Game:SetEmojState(key, emoj)
    self._EmojState[key] = emoj
end

--- 初始化表情状态（游戏开始时调用）
function XLineArithmetic3Game:InitEmojState()
    local Emoj = XLineArithmetic3Enum.Emoj

    -- 车头初始表情
    self:SetEmojState(self:_GetHeadEmojKey(), Emoj.Initial)

    -- 车厢乘客初始表情
    for ci = 1, #self._Carriages do
        if self._Carriages[ci].Passenger then
            self:SetEmojState(self:_GetCarriageEmojKey(ci), Emoj.AfterBoard)
        end
    end

    -- 地图格子乘客初始表情
    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            local grid = self:GetGrid({ x = x, y = y })
            if grid and grid.Passenger then
                self:SetEmojState(self:_GetGridEmojKey(x, y), Emoj.Initial)
            end
        end
    end
end

--- 初始化地图与车站颜色（在加载地图后调用）
function XLineArithmetic3Game:RefreshStationColors()
    local GridType = XLineArithmetic3Enum.GridType
    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            local pos = { x = x, y = y }
            local g = self:GetGrid(pos)
            if g and g.Type == GridType.Station then
                g.StationColor = self:GetStationColorAt(pos)
            end
        end
    end
end

--- 递归传播车站颜色：当车站颜色变更时，遍历附近车站，传递颜色，白色乘客永久染色
---@param pos { x: number, y: number } 颜色变更的车站位置
---@param color number 要传播的颜色
---@param visited table 已访问的位置集合（防止无限递归）
---@return table[] 变更记录列表，用于回退
function XLineArithmetic3Game:PropagateStationColor(pos, color, visited)
    local GridType = XLineArithmetic3Enum.GridType
    local Color = XLineArithmetic3Enum.Color
    if not visited then visited = {} end
    local key = pos.x .. "," .. pos.y
    if visited[key] then return {} end
    visited[key] = true

    local changes = {}
    for _, n in ipairs(self:GetNeighbors(pos)) do
        local ng = self:GetGrid(n)
        if ng and ng.Type == GridType.Station then
            local nKey = n.x .. "," .. n.y
            if not visited[nKey] then
                local oldStationColor = ng.StationColor
                -- 重新计算该车站颜色
                ng.StationColor = self:GetStationColorAt(n)
                if oldStationColor ~= ng.StationColor then
                    changes[#changes + 1] = {
                        Type = "StationColor",
                        X = n.x,
                        Y = n.y,
                        OldColor = oldStationColor,
                        NewColor = ng.StationColor,
                    }
                end
                -- 如果车站上有白色乘客，永久染色
                if ng.Passenger and ng.Passenger.Color == Color.White and ng.StationColor ~= Color.White then
                    local oldPassengerColor = ng.Passenger.Color
                    ng.Passenger.Color = ng.StationColor
                    changes[#changes + 1] = {
                        Type = "DyeStationPassenger",
                        X = n.x,
                        Y = n.y,
                        OldColor = oldPassengerColor,
                        NewColor = ng.StationColor,
                    }
                end
                -- 递归传播
                local subChanges = self:PropagateStationColor(n, ng.StationColor, visited)
                for _, c in ipairs(subChanges) do
                    changes[#changes + 1] = c
                end
            end
        end
    end
    return changes
end

--- 刷新车站颜色并递归传播，返回变更记录（用于生成可回退指令）
---@return table[] 变更记录列表
function XLineArithmetic3Game:RefreshStationColorsWithPropagate()
    local GridType = XLineArithmetic3Enum.GridType
    local Color = XLineArithmetic3Enum.Color
    local allChanges = {}

    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            local pos = { x = x, y = y }
            local g = self:GetGrid(pos)
            if g and g.Type == GridType.Station then
                local oldColor = g.StationColor
                g.StationColor = self:GetStationColorAt(pos)
                if oldColor ~= g.StationColor then
                    allChanges[#allChanges + 1] = {
                        Type = "StationColor",
                        X = x,
                        Y = y,
                        OldColor = oldColor,
                        NewColor = g.StationColor,
                    }
                    -- 如果车站上有白色乘客，永久染色
                    if g.Passenger and g.Passenger.Color == Color.White and g.StationColor ~= Color.White then
                        local oldPassengerColor = g.Passenger.Color
                        g.Passenger.Color = g.StationColor
                        allChanges[#allChanges + 1] = {
                            Type = "DyeStationPassenger",
                            X = x,
                            Y = y,
                            OldColor = oldPassengerColor,
                            NewColor = g.StationColor,
                        }
                    end
                    -- 递归传播到附近车站
                    local subChanges = self:PropagateStationColor(pos, g.StationColor, nil)
                    for _, c in ipairs(subChanges) do
                        allChanges[#allChanges + 1] = c
                    end
                end
            end
        end
    end
    return allChanges
end

---@param pos { x: number, y: number }
---@return boolean 是否在当前路径上
function XLineArithmetic3Game:IsOnPath(pos)
    for _, p in ipairs(self._Path) do
        if p.x == pos.x and p.y == pos.y then return true end
    end
    return false
end

---@param pos { x: number, y: number }
---@return boolean 是否在已走过的路径上
function XLineArithmetic3Game:IsOnTraveledPath(pos)
    for _, p in ipairs(self._TraveledPath) do
        if p.x == pos.x and p.y == pos.y then return true end
    end
    return false
end

--- 检查是否是回退点（TraveledPath 的倒数第二个点）
---@param pos { x: number, y: number }
---@return boolean
function XLineArithmetic3Game:IsUndoPoint(pos)
    if #self._TraveledPath < 2 then return false end
    local prevPoint = self._TraveledPath[#self._TraveledPath - 1]
    return prevPoint.x == pos.x and prevPoint.y == pos.y
end

--- 检查是否在当前正在绘制的临时路径 _Path 上（不能穿过已画的线）
---@param pos { x: number, y: number }
---@return boolean
function XLineArithmetic3Game:IsOnCurrentPath(pos)
    if not self._Path or not pos then return false end
    for _, p in ipairs(self._Path) do
        if p and p.x == pos.x and p.y == pos.y then
            return true
        end
    end
    return false
end

--- 判断是否为终点格（含额外终点格）
---@param g table
---@return boolean
function XLineArithmetic3Game:IsEndGrid(g)
    if not g then return false end
    local t = XLineArithmetic3Enum.GridType
    return g.Type == t.End or g.Type == t.ExtraEnd
end

--- 判断是否为可经过的格子
---@param g table
---@return boolean
function XLineArithmetic3Game:IsWalkable(g)
    if not g then return true end -- 没有格子也可以行走
    local GridType = XLineArithmetic3Enum.GridType
    -- 障碍格、车站、额外终点格、乘客格不能走进去
    if g.Type == GridType.Obstacle then return false end
    if g.Type == GridType.Station then return false end
    if g.Type == GridType.ExtraEnd then return false end
    if g.Type == GridType.Passenger then return false end
    return true
end

--- 判断是否是障碍
function XLineArithmetic3Game:IsObstacleByPos(x, y)
    local grid = self:GetGridNoalloc(x, y)

    if not grid then
        return false
    end
    
    return grid.Type == XLineArithmetic3Enum.GridType.Obstacle
end

--- 判断某位置是否有车厢占据
---@param pos { x: number, y: number }
---@return boolean
function XLineArithmetic3Game:IsCarriageAt(pos)
    if not pos then return false end
    for _, carriage in ipairs(self._Carriages) do
        if carriage.Pos and carriage.Pos.x == pos.x and carriage.Pos.y == pos.y then
            return true
        end
    end
    return false
end

--- 清空游戏状态（重新开始或下一关时调用，调用后需执行 ImportConfig 加载新关卡）
function XLineArithmetic3Game:Clear()
    self._Map = {}
    self._MapSize = { x = 9, y = 7 }
    self._Path = {}
    self._TraveledPath = {}
    self._HeadPos = nil
    self._Carriages = {}
    self._Instructions = {}
    self._EmojState = {}
    -- 星星目标相关：记录每个终点/额外终点在第几个指令后完成
    self._EndConditionCompleteStepByCellId = {}
    self._ExtraEndCompleteStepByCellId = {}
    self._InstructionIndexBase = 0
    -- 埋点相关：开始时间、一笔次数、回撤次数、是否使用提示
    self._StartTime = nil
    self._ConfirmPathCount = 0
    self._UndoCount = 0
    self._UsedTips = false
end

--- 从配置导入地图（配置表：格子、乘客、地图、车厢）
---@param model XLineArithmetic3Model 提供 GetGridById, GetPassengerById 等
---@param mapConfig table 地图配置
---@param carConfig table 车辆配置，包含 Carriages[] 数组
function XLineArithmetic3Game:ImportConfig(model, mapConfig, carConfig)
    if not mapConfig then return end

    self._Map = {}
    -- 初始化星星目标相关缓存
    self._EndConditionCompleteStepByCellId = {}
    self._ExtraEndCompleteStepByCellId = {}
    self._InstructionIndexBase = 0
    -- 初始化埋点数据（关卡开始时间、一笔次数、回撤次数、是否使用提示）
    if XTime and XTime.GetServerNowTimestamp then
        self._StartTime = XTime.GetServerNowTimestamp()
    else
        self._StartTime = os.time()
    end
    self._ConfirmPathCount = 0
    self._UndoCount = 0
    self._UsedTips = false
    for y = 1, self._MapSize.y do
        self._Map[y] = {}
        for x = 1, self._MapSize.x do
            self._Map[y][x] = nil
        end
    end

    -- 根据实际配置表结构修正：
    -- mapConfig = { Row = 7, Column = { [1] = {gridId1, gridId2, ...}, [2] = {...}, ... } }

    local GridType = XLineArithmetic3Enum.GridType
    local cfgGrid = mapConfig.Grid or mapConfig.Cells or mapConfig
    local rowCount = mapConfig.Row or mapConfig.LineCount or self._MapSize.y
    -- 修正：Column是数组，需要获取第一行的长度作为列数
    local colCount = (mapConfig.Column and mapConfig.Column[1] and #mapConfig.Column[1]) or self._MapSize.x

    self._MapSize.x = colCount
    self._MapSize.y = rowCount

    -- 若配置是二维数组 [y][x] = gridId
    if mapConfig.Column and type(mapConfig.Column[1]) == "table" then
        for y = 1, rowCount do
            local row = mapConfig.Column[y]
            if not row then break end
            for x = 1, #row do        -- 使用 #row 获取实际列数
                local gridId = row[x] -- 直接获取gridId
                if gridId and gridId > 0 and model and model.GetGridById then
                    local gridCfg = model:GetGridById(gridId)
                    if gridCfg then
                        local g = {
                            CellId = gridId,
                            Type = gridCfg.Type or GridType.Start,
                            Passenger = nil,
                            StationColor = XLineArithmetic3Enum.Color.White,
                        }
                        -- 初始化乘客数据
                        if g.Type == GridType.Passenger or g.Type == GridType.Station then
                            -- 优先使用 CharacterId 获取角色格的颜色
                            if gridCfg.CharacterId and gridCfg.CharacterId > 0 and model.GetGridById then
                                local characterCfg = model:GetGridById(gridCfg.CharacterId)
                                if characterCfg and characterCfg.Color then
                                    g.Passenger = { Color = characterCfg.Color }
                                end
                                -- 其次使用格子自身的 Color 字段
                            elseif gridCfg.Color and gridCfg.Color > 0 then
                                g.Passenger = { Color = gridCfg.Color }
                            end
                            -- 初始化额外终点格的颜色
                        elseif gridCfg.Type == GridType.ExtraEnd then
                            g.Color = gridCfg.Color
                        end
                        if not self._Map[y] then self._Map[y] = {} end
                        self._Map[y][x] = g
                    end
                end
            end
        end
    end

    self:RefreshStationColors()

    -- 起点：找起点格作为车头与车厢初始位置
    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            local g = self:GetGrid({ x = x, y = y })
            if g and g.Type == GridType.Start then
                self._HeadPos = { x = x, y = y }
                break
            end
        end
        if self._HeadPos then break end
    end

    -- 初始车厢，根据 carConfig.Carriages[] 初始化
    -- 注意：Carriages[1] 是车头配置，Carriages[2]开始才是车厢
    self._Carriages = {}
    if carConfig and carConfig.Carriages then
        -- 从索引2开始遍历，跳过车头配置
        for i = 2, #carConfig.Carriages do
            local carriageIndex = i - 1 -- 车厢索引（第1个车厢对应配置索引2）
            if carriageIndex > self._MaxCarriages then break end

            local cellId = carConfig.Carriages[i]
            local carriage = {
                Pos = { x = self._HeadPos.x, y = self._HeadPos.y },
                Passenger = nil,
                JustDisembarkAt = nil,
            }
            -- 从数据获取乘客颜色与 GridName（优先 CharacterId 对应角色格，其次格子自身）
            if cellId and cellId > 0 then
                local gridCfg = model:GetGridById(cellId)
                if gridCfg then
                    if gridCfg.CharacterId and gridCfg.CharacterId > 0 then
                        carriage.Passenger = {
                            Color = gridCfg.Color,
                            GridName = gridCfg.GridName,
                            CharacterId = gridCfg.CharacterId,
                        }
                    else
                        XLog.Error("[XLineArithmetic3Game] 乘客颜色与 GridName 获取失败，cellId:", cellId)
                    end
                end
            end
            self._Carriages[#self._Carriages + 1] = carriage
        end
    end

    self._Path = {}
    self._TraveledPath = { { x = self._HeadPos.x, y = self._HeadPos.y } } -- 起点
    self._Instructions = {}

    -- 初始化表情状态
    self:InitEmojState()
end

--- 埋点：记录一次回撤（按组）
---@param groupCount number 回撤的组数
function XLineArithmetic3Game:OnUndo(groupCount)
    self._UndoCount = (self._UndoCount or 0) + (groupCount or 1)
end

--- 埋点：标记使用过提示
function XLineArithmetic3Game:MarkUsedTips()
    self._UsedTips = true
end

--- 获取已完成的额外终点数量（用于埋点）
---@return number
function XLineArithmetic3Game:GetCompletedExtraEndCount()
    local count = 0
    local GridType = XLineArithmetic3Enum.GridType
    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            local grid = self._Map[y] and self._Map[y][x]
            if grid and grid.Type == GridType.ExtraEnd and self:IsEndGridComplete(grid, x, y) then
                count = count + 1
            end
        end
    end
    return count
end

--- 获取埋点数据：终点数量、关卡耗时、一笔完成、回撤次数、是否使用提示
---@return table
function XLineArithmetic3Game:GetAnalyticsData()
    local endCount = self:GetCompletedExtraEndCount()
    local duration = 0
    if self._StartTime then
        local now
        if XTime and XTime.GetServerNowTimestamp then
            now = XTime.GetServerNowTimestamp()
        else
            now = os.time()
        end
        duration = math.max(0, now - self._StartTime)
    end
    local strokeCount = self._ConfirmPathCount or 0
    local onlyOneLine = strokeCount <= 1 and 1 or 0
    local undoCount = self._UndoCount or 0
    local tipType = self._UsedTips and 1 or 0

    return {
        -- 注意：StarState 在结算时由 Control 按 StarCondition 重算为十进制位码；
        -- 这里保留一个默认值，避免上层缺字段
        StarState = endCount,
        Duration = duration,
        OnlyOneLine = onlyOneLine,
        UndoCount = undoCount,
        TipType = tipType,
    }
end

--- 判断从车头出发能否沿直线到达目标点（不修改路径，仅做预判）
---@param pos { x: number, y: number } 目标点
---@return boolean
function XLineArithmetic3Game:CanStraightReach(pos)
    if not self._HeadPos then return false end
    if not self:IsInMap(pos) then return false end

    -- 目标点就是车头位置，可达
    if pos.x == self._HeadPos.x and pos.y == self._HeadPos.y then
        return true
    end

    local dx = pos.x - self._HeadPos.x
    local dy = pos.y - self._HeadPos.y
    -- 必须沿水平或竖直方向
    if dx ~= 0 and dy ~= 0 then
        return false
    end

    -- 如果路径已经经过终点，不允许继续
    if self:IsPathPassedEnd() then return false end

    local stepX = (dx == 0) and 0 or (dx > 0 and 1 or -1)
    local stepY = (dy == 0) and 0 or (dy > 0 and 1 or -1)
    local cur = { x = self._HeadPos.x, y = self._HeadPos.y }
    while true do
        cur.x = cur.x + stepX
        cur.y = cur.y + stepY
        if not self:IsInMap(cur) then
            return false
        end
        if not self:IsWalkable(self:GetGrid(cur)) then
            return false
        end
        if self:IsOnTraveledPath(cur) and not self:IsUndoPoint(cur) then
            return false
        end
        -- 到达目标点
        if cur.x == pos.x and cur.y == pos.y then
            return true
        end
    end
end

--- 检查当前路径或已走过的路径是否已经经过最终终点格
---@return boolean
function XLineArithmetic3Game:IsPathPassedEnd()
    local GridType = XLineArithmetic3Enum.GridType
    -- 检查已走过的路径
    for _, p in ipairs(self._TraveledPath) do
        local g = self:GetGrid(p)
        if g and g.Type == GridType.End then
            return true
        end
    end
    -- 检查当前正在绘制的路径
    for _, p in ipairs(self._Path) do
        local g = self:GetGrid(p)
        if g and g.Type == GridType.End then
            return true
        end
    end
    return false
end

--- 从 last 向 pos 直线延伸路径，逐格添加直到 pos 或遇障碍/已走路径/当前路径，不回头
---@param last { x: number, y: number } 当前路径末端
---@param pos { x: number, y: number } 目标点（必须在 last 的某一轴向上）
---@return boolean 是否至少添加了一格
function XLineArithmetic3Game:_AddPathStraightLine(last, pos)
    local dx = pos.x - last.x
    local dy = pos.y - last.y
    -- 必须沿水平或竖直直线（不能斜向）
    if dx ~= 0 and dy ~= 0 then
        return false
    end
    local stepX = (dx == 0) and 0 or (dx > 0 and 1 or -1)
    local stepY = (dy == 0) and 0 or (dy > 0 and 1 or -1)
    -- 不允许朝"上一格"的方向回头
    if #self._Path >= 2 then
        local prev = self._Path[#self._Path - 1]
        local backX = prev.x - last.x
        local backY = prev.y - last.y
        if stepX == (backX == 0 and 0 or (backX > 0 and 1 or -1))
            and stepY == (backY == 0 and 0 or (backY > 0 and 1 or -1)) then
            return false
        end
    end

    local added = false
    local cur = { x = last.x, y = last.y }
    while true do
        cur.x = cur.x + stepX
        cur.y = cur.y + stepY
        if not self:IsInMap(cur) then
            break
        end
        if not self:IsWalkable(self:GetGrid(cur)) then
            break
        end
        if self:IsOnTraveledPath(cur) and not self:IsUndoPoint(cur) then
            break
        end
        if self:IsOnCurrentPath(cur) then
            break
        end
        -- 不能穿过车厢位置
        if self:IsCarriageAt(cur) then
            break
        end
        self._Path[#self._Path + 1] = { x = cur.x, y = cur.y }
        added = true
        if cur.x == pos.x and cur.y == pos.y then
            break
        end
    end
    return added
end

--- 玩家连线：添加路径点（可点击车头方向直线 n 格，沿直线延伸直到遇障碍或已走/当前路径）
---@param pos { x: number, y: number }
---@return boolean 是否添加成功
function XLineArithmetic3Game:OnPathAdd(pos)
    if not self:IsInMap(pos) then return false end
    local g = self:GetGrid(pos)
    if not self:IsWalkable(g) then return false end

    -- 如果路径已经经过最终终点格，禁止继续延长
    if self:IsPathPassedEnd() then return false end

    -- 不能穿过已走过的路径（回退点除外，车头位置除外）
    -- 注意：车头位置在 TraveledPath 上，但它是当前可延伸的起点，应该允许
    local isHeadPos = self._HeadPos and pos.x == self._HeadPos.x and pos.y == self._HeadPos.y
    if self:IsOnTraveledPath(pos) and not self:IsUndoPoint(pos) and not isHeadPos then
        return false
    end

    -- 不能穿过当前正在绘制的临时路径
    if self:IsOnCurrentPath(pos) then
        return false
    end

    if #self._Path == 0 then
        -- 初始化时自动加入车头位置作为起点
        if self._HeadPos then
            self._Path[#self._Path + 1] = { x = self._HeadPos.x, y = self._HeadPos.y }
        end
        -- 如果用户输入的点就是车头位置，已经加入了，返回 true
        if self._HeadPos and pos.x == self._HeadPos.x and pos.y == self._HeadPos.y then
            return true
        end
        -- 从车头向 pos 直线延伸（车头可视为"末端"，无回头方向）
        return self:_AddPathStraightLine(self._Path[#self._Path], pos)
    end

    local last = self._Path[#self._Path]
    if not last then return false end
    -- 从当前末端向 pos 直线延伸
    return self:_AddPathStraightLine(last, pos)
end

--- 回退一笔：撤销当前路径的最后一格
function XLineArithmetic3Game:OnPathUndo()
    if #self._Path > 0 then
        self._Path[#self._Path] = nil
    end
end

--- 当前路径是否可确认（至少 2 格，允许分段绘制）
---@return boolean
function XLineArithmetic3Game:CanConfirmPath()
    return #self._Path >= 2
end

--- 将传播变更记录转为可回退的指令
---@param changes table[] 变更记录列表
function XLineArithmetic3Game:_EmitPropagateInstructions(changes)
    local Ins = XLineArithmetic3Enum.Instruction
    for _, change in ipairs(changes) do
        if change.Type == "DyeStationPassenger" then
            self._Instructions[#self._Instructions + 1] = {
                Type = Ins.DyeStationPassenger,
                GridX = change.X,
                GridY = change.Y,
                Color = change.NewColor,
                PassengerColorBefore = change.OldColor,
            }
        elseif change.Type == "StationColor" then
            self._Instructions[#self._Instructions + 1] = {
                Type = Ins.StationColorChanged,
                GridX = change.X,
                GridY = change.Y,
                Color = change.NewColor,
                StationColorBefore = change.OldColor,
            }
        end
    end
end

--- 生成并执行本笔路径的指令，更新车头、车厢、地图状态
function XLineArithmetic3Game:ConfirmPath()
    if not self:CanConfirmPath() then return end

    -- 埋点：记录一笔完成次数
    self._ConfirmPathCount = (self._ConfirmPathCount or 0) + 1

    self._Instructions = {}
    -- 记录本笔开始时的全局步数基数（本笔 commandIndex 将在此基础上累加）
    local instructionBase = self._InstructionIndexBase or 0
    local Instruction = XLineArithmetic3Enum.Instruction
    local GridType = XLineArithmetic3Enum.GridType
    local Color = XLineArithmetic3Enum.Color

    -- 车头沿路径移动到末端
    local path = self._Path

    -- 从第2个点开始，跳过起点（第1个点是当前车头位置）
    for step = 2, #path do
        local pos = path[step]
        -- 保存之前的车头位置
        local headPosBefore = { x = self._HeadPos.x, y = self._HeadPos.y }
        -- 保存车厢移动前的位置（在更新车厢位置之前）
        local carriagePositionsBefore = {}
        for ci, carriage in ipairs(self._Carriages) do
            if carriage.Pos then
                carriagePositionsBefore[ci] = { x = carriage.Pos.x, y = carriage.Pos.y }
            end
        end
        self._HeadPos = { x = pos.x, y = pos.y }
        self._Instructions[#self._Instructions + 1] = {
            Type = Instruction.MoveHead,
            X = pos.x,
            Y = pos.y,
            HeadPosBefore = headPosBefore,
            CarriagePositionsBefore = carriagePositionsBefore
        }

        -- 车头移动后，检测车头周围是否有终点格和乘客
        local headNeighbors = self:GetNeighbors(self._HeadPos)
        local isHeadNearOrAtEnd = false  -- 车头靠近或在终点格上
        local passengerNearHead = {}  -- 与车头相邻的乘客位置

        -- 检测车头当前位置是否在终点格上
        local currentHeadGrid = self:GetGrid(self._HeadPos)
        if currentHeadGrid and currentHeadGrid.Type == GridType.End then
            isHeadNearOrAtEnd = true
        end

        for _, hn in ipairs(headNeighbors) do
            local hng = self:GetGrid(hn)
            -- 检测车头是否靠近终点格
            if hng and hng.Type == GridType.End then
                isHeadNearOrAtEnd = true
            end
            -- 记录与车头相邻的乘客（非额外终点格上的）
            if hng and hng.Passenger and hng.Type ~= GridType.ExtraEnd then
                table.insert(passengerNearHead, { x = hn.x, y = hn.y })
            end
        end

        -- 根据车头是否靠近/在终点，更新所有角色表情
        if isHeadNearOrAtEnd then
            -- 车头靠近/在终点：所有未到达目的地的角色切换为 ToFinalEnd
            local Emoj = XLineArithmetic3Enum.Emoj

            -- 车头切换为 ToFinalEnd 表情
            local headKey = self:_GetHeadEmojKey()
            self._Instructions[#self._Instructions + 1] = {
                Type = Instruction.ChangePassengerEmoj,
                IsHead = true,
                Emoj = Emoj.ToFinalEnd,
                EmojBefore = self:GetEmojState(headKey)
            }
            self:SetEmojState(headKey, Emoj.ToFinalEnd)

            -- 车厢上的乘客切换为 ToFinalEnd 表情
            for ci, carriage in ipairs(self._Carriages) do
                if carriage.Passenger then
                    local key = self:_GetCarriageEmojKey(ci)
                    self._Instructions[#self._Instructions + 1] = {
                        Type = Instruction.ChangePassengerEmoj,
                        CarriageIndex = ci,
                        Emoj = Emoj.ToFinalEnd,
                        EmojBefore = self:GetEmojState(key)
                    }
                    self:SetEmojState(key, Emoj.ToFinalEnd)
                end
            end

            -- 地图格子上的乘客切换为 ToFinalEnd 表情
            for y = 1, self._MapSize.y do
                for x = 1, self._MapSize.x do
                    local grid = self:GetGrid({ x = x, y = y })
                    if grid and grid.Passenger then
                        if grid.Type == GridType.Passenger or grid.Type == GridType.Station then
                            local key = self:_GetGridEmojKey(x, y)
                            self._Instructions[#self._Instructions + 1] = {
                                Type = Instruction.ChangePassengerEmoj,
                                GridX = x,
                                GridY = y,
                                Emoj = Emoj.ToFinalEnd,
                                EmojBefore = self:GetEmojState(key)
                            }
                            self:SetEmojState(key, Emoj.ToFinalEnd)
                        end
                    end
                end
            end
        else
            -- 车头远离终点：恢复角色表情到正常状态
            local Emoj = XLineArithmetic3Enum.Emoj

            -- 车头恢复为 Initial 表情
            local headKey = self:_GetHeadEmojKey()
            self._Instructions[#self._Instructions + 1] = {
                Type = Instruction.ChangePassengerEmoj,
                IsHead = true,
                Emoj = Emoj.Initial,
                EmojBefore = self:GetEmojState(headKey)
            }
            self:SetEmojState(headKey, Emoj.Initial)

            -- 车厢上的乘客恢复为 AfterBoard 表情
            for ci, carriage in ipairs(self._Carriages) do
                if carriage.Passenger then
                    local key = self:_GetCarriageEmojKey(ci)
                    self._Instructions[#self._Instructions + 1] = {
                        Type = Instruction.ChangePassengerEmoj,
                        CarriageIndex = ci,
                        Emoj = Emoj.AfterBoard,
                        EmojBefore = self:GetEmojState(key)
                    }
                    self:SetEmojState(key, Emoj.AfterBoard)
                end
            end

            -- 地图格子上的乘客：与车头相邻则 ReadyToBoard，否则 Initial
            for y = 1, self._MapSize.y do
                for x = 1, self._MapSize.x do
                    local grid = self:GetGrid({ x = x, y = y })
                    if grid and grid.Passenger then
                        if grid.Type == GridType.Passenger or grid.Type == GridType.Station then
                            -- 检查是否与车头相邻
                            local isNearHead = false
                            for _, pos in ipairs(passengerNearHead) do
                                if pos.x == x and pos.y == y then
                                    isNearHead = true
                                    break
                                end
                            end

                            local key = self:_GetGridEmojKey(x, y)
                            if isNearHead then
                                -- 与车头相邻，ReadyToBoard
                                self._Instructions[#self._Instructions + 1] = {
                                    Type = Instruction.ChangePassengerEmoj,
                                    GridX = x,
                                    GridY = y,
                                    Emoj = Emoj.ReadyToBoard,
                                    EmojBefore = self:GetEmojState(key)
                                }
                                self:SetEmojState(key, Emoj.ReadyToBoard)
                            else
                                -- 不与车头相邻，恢复 Initial
                                self._Instructions[#self._Instructions + 1] = {
                                    Type = Instruction.ChangePassengerEmoj,
                                    GridX = x,
                                    GridY = y,
                                    Emoj = Emoj.Initial,
                                    EmojBefore = self:GetEmojState(key)
                                }
                                self:SetEmojState(key, Emoj.Initial)
                            end
                        end
                    end
                end
            end
        end

        -- 保存所有车厢的旧位置（用于蛇形移动）
        local carriageOldPositions = {}
        for ci, carriage in ipairs(self._Carriages) do
            carriageOldPositions[ci] = { x = carriage.Pos.x, y = carriage.Pos.y }
        end

        -- 先移动所有车厢到新位置（蛇形移动）
        for ci, carriage in ipairs(self._Carriages) do
            if ci == 1 then
                -- 第1个车厢移动到车头的旧位置
                carriage.Pos = { x = headPosBefore.x, y = headPosBefore.y }
            elseif carriageOldPositions[ci - 1] then
                -- 第2个车厢移动到第1个车厢的旧位置
                local prevCarriageOldPos = carriageOldPositions[ci - 1]
                carriage.Pos = { x = prevCarriageOldPos.x, y = prevCarriageOldPos.y }
            end
        end

        -- 然后检测上下车和终点（使用车厢的新位置）
        for ci, carriage in ipairs(self._Carriages) do
            carriage.JustDisembarkAt = nil
            -- 使用车厢位置检测周遭，而不是车头位置
            local carriagePos = carriage.Pos
            local neighbors = self:GetNeighbors(carriagePos)

            -- 1. 下车：上左下右，有乘客的车厢在终点/车站无乘客时下车
            -- 优先级调整：当终点和空车站同时存在时，优先进入终点
            local disembarkTarget = nil
            for _, n in ipairs(neighbors) do
                local ng = self:GetGrid(n)
                if ng and carriage.Passenger then
                    -- 1) 先优先额外终点：颜色匹配且空
                    if ng.Type == GridType.ExtraEnd and not ng.Passenger then
                        if ng.Color and ng.Color == carriage.Passenger.Color then
                            disembarkTarget = { Pos = { x = n.x, y = n.y }, Grid = ng }
                            break -- 找到匹配的终点立即使用
                        end
                    end
                    -- 2) 记录一个候选空车站（仅在当前还没有更优目标时）
                    if not disembarkTarget and ng.Type == GridType.Station and not ng.Passenger then
                        disembarkTarget = { Pos = { x = n.x, y = n.y }, Grid = ng }
                        -- 不立即 break，继续看看周围是否还有更优的终点
                    end
                end
            end

            if disembarkTarget then
                local n = disembarkTarget.Pos
                local ng = disembarkTarget.Grid
                -- 保存之前状态
                local carriagePassengerBefore = { Color = carriage.Passenger.Color }
                local originalColor = carriage.Passenger.Color
                local color = originalColor

                local emoj = nil

                -- 染色逻辑：如果白色乘客下车到有颜色的车站
                local isInfected = false
                if ng and ng.Type == GridType.Station and color == Color.White and ng.StationColor and ng.StationColor ~= Color.White then
                    color = ng.StationColor
                    isInfected = true
                    self._Instructions[#self._Instructions + 1] = {
                        Type = Instruction.DyePassenger,
                        CarriageIndex = ci,
                        Color = color,
                        PassengerColorBefore = originalColor,
                        GridX = n.x,
                        GridY = n.y,
                    }
                    -- 更新车厢上乘客的颜色
                    carriage.Passenger.Color = color
                end

                carriage.JustDisembarkAt = { x = n.x, y = n.y }
                ng.Passenger = { Color = color }
                -- 记录额外终点在第几个指令后完成（用于星星目标预计算）
                if ng.Type == GridType.ExtraEnd and ng.CellId then
                    local commandIndex = instructionBase + #self._Instructions + 1
                    local extraSteps = self._ExtraEndCompleteStepByCellId
                    if extraSteps and not extraSteps[ng.CellId] then
                        extraSteps[ng.CellId] = commandIndex
                    end
                end
                self._Instructions[#self._Instructions + 1] = {
                    Type = Instruction.Disembark,
                    GridX = n.x,
                    GridY = n.y,
                    CarriageIndex = ci,
                    Color = color,
                    CarriagePassengerBefore = carriagePassengerBefore,
                    IsInfected = isInfected,
                }
                carriage.Passenger = nil
                -- 下车后修改乘客表情（根据颜色决定，从车厢转移到格子）
                local emoj = nil

                if ng.Type == GridType.Station then
                    emoj = XLineArithmetic3Enum.Emoj.Initial
                elseif ng.Type == GridType.ExtraEnd then
                    emoj = self:_GetEmojByColor(color)
                end

                local emojBefore = self:GetEmojState(self:_GetCarriageEmojKey(ci))
                self._Instructions[#self._Instructions + 1] = {
                    Type = Instruction.ChangePassengerEmoj,
                    GridX = n.x,
                    GridY = n.y,
                    Emoj = emoj,
                    EmojBefore = emojBefore
                }
                -- 更新表情状态：格子乘客表情设为下车后的表情
                self:SetEmojState(self:_GetGridEmojKey(n.x, n.y), emoj)
                -- 如果下车到额外终点，立即生成终点激活指令
                if ng.Type == GridType.ExtraEnd then
                    self._Instructions[#self._Instructions + 1] = {
                        Type = Instruction.ActivateEnd,
                        GridX = n.x,
                        GridY = n.y,
                    }
                end
                -- 下车后刷新车站颜色并递归传播
                self:_EmitPropagateInstructions(self:RefreshStationColorsWithPropagate())
            end

            -- 2. 若上下左右有 ≥2 个乘客（忽略刚刚下车的格子），谁都不能上车，跳过上车
            local passengerCountExcludeJustDisembark = 0
            for _, n in ipairs(neighbors) do
                if carriage.JustDisembarkAt and n.x == carriage.JustDisembarkAt.x and n.y == carriage.JustDisembarkAt.y then
                    -- 忽略刚下车的格子
                else
                    local ng = self:GetGrid(n)
                    if ng and ng.Passenger and ng.Type ~= GridType.ExtraEnd then
                        passengerCountExcludeJustDisembark = passengerCountExcludeJustDisembark + 1
                    end
                end
            end

            if passengerCountExcludeJustDisembark < 2 then
                -- 3. 上车：上左下右，乘客格有乘客且车厢空则上车；车站有乘客且车厢空则上车；白色进站染色
                for _, n in ipairs(neighbors) do
                    local ng = self:GetGrid(n)
                    if not ng then goto continue end
                    if carriage.JustDisembarkAt and n.x == carriage.JustDisembarkAt.x and n.y == carriage.JustDisembarkAt.y then
                        goto continue
                    end
                    if not carriage.Passenger then
                        -- 染色逻辑：如果白色乘客从有颜色的车站上车, 那么永久改为该颜色
                        if ng and ng.Type == GridType.Station and not carriage.Passenger and ng.Passenger and ng.Passenger.Color == Color.White and ng.StationColor and ng.StationColor ~= Color.White then
                            ng.Passenger.Color = ng.StationColor
                        end
                        if ng.Type == GridType.Passenger and ng.Passenger then
                            -- 保存之前状态
                            local gridPassengerBefore = { Color = ng.Passenger.Color }
                            local color = ng.Passenger.Color
                            local emojBefore = self:GetEmojState(self:_GetGridEmojKey(n.x, n.y))
                            carriage.Passenger = { Color = color }
                            ng.Passenger = nil
                            self._Instructions[#self._Instructions + 1] = {
                                Type = Instruction.Board,
                                GridX = n.x,
                                GridY = n.y,
                                CarriageIndex = ci,
                                Color = color,
                                GridPassengerBefore = gridPassengerBefore
                            }
                            -- 上车后修改乘客表情（从格子位置转移到车厢）
                            local Emoj = XLineArithmetic3Enum.Emoj
                            self._Instructions[#self._Instructions + 1] = {
                                Type = Instruction.ChangePassengerEmoj,
                                CarriageIndex = ci,
                                Emoj = Emoj.AfterBoard,
                                EmojBefore = emojBefore
                            }
                            -- 更新表情状态：车厢乘客表情设为AfterBoard
                            self:SetEmojState(self:_GetCarriageEmojKey(ci), Emoj.AfterBoard)
                            -- 乘客格上车后刷新车站颜色并递归传播
                            self:_EmitPropagateInstructions(self:RefreshStationColorsWithPropagate())
                            break
                        end
                        if ng.Type == GridType.Station and ng.Passenger then
                            -- 保存之前状态
                            local gridPassengerBefore = { Color = ng.Passenger.Color }
                            local originalColor = ng.Passenger.Color
                            local color = originalColor
                            local emojBefore = self:GetEmojState(self:_GetGridEmojKey(n.x, n.y))
                            local isInfected = false
                            if color == Color.White and ng.StationColor and ng.StationColor ~= Color.White then
                                color = ng.StationColor
                                isInfected = true
                                self._Instructions[#self._Instructions + 1] = {
                                    Type = Instruction.DyePassenger,
                                    CarriageIndex = ci,
                                    Color = color,
                                    PassengerColorBefore = originalColor,
                                    GridX = n.x,
                                    GridY = n.y,
                                }
                            end
                            carriage.Passenger = { Color = color }
                            ng.Passenger = nil
                            self._Instructions[#self._Instructions + 1] = {
                                Type = Instruction.Board,
                                GridX = n.x,
                                GridY = n.y,
                                CarriageIndex = ci,
                                Color = color,
                                GridPassengerBefore = gridPassengerBefore,
                                IsInfected = isInfected,
                            }
                            -- 上车后修改乘客表情（从格子位置转移到车厢）
                            local Emoj = XLineArithmetic3Enum.Emoj
                            self._Instructions[#self._Instructions + 1] = {
                                Type = Instruction.ChangePassengerEmoj,
                                CarriageIndex = ci,
                                Emoj = Emoj.AfterBoard,
                                EmojBefore = emojBefore
                            }
                            -- 更新表情状态：车厢乘客表情设为AfterBoard
                            self:SetEmojState(self:_GetCarriageEmojKey(ci), Emoj.AfterBoard)
                            -- 车站上车后刷新车站颜色并递归传播
                            self:_EmitPropagateInstructions(self:RefreshStationColorsWithPropagate())
                            break
                        end
                    end
                    ::continue::
                end

                -- 4. 上车后，如果附近同时有匹配的额外终点格，立即下车到额外终点格
                if carriage.Passenger then
                    for _, n in ipairs(neighbors) do
                        local ng = self:GetGrid(n)
                        if ng and ng.Type == GridType.ExtraEnd and not ng.Passenger then
                            if ng.Color and ng.Color == carriage.Passenger.Color then
                                local carriagePassengerBefore = { Color = carriage.Passenger.Color }
                                local color = carriage.Passenger.Color
                                carriage.JustDisembarkAt = { x = n.x, y = n.y }
                                ng.Passenger = { Color = color }
                                -- 记录额外终点在第几个指令后完成（用于星星目标预计算）
                                if ng.CellId then
                                    local commandIndex = instructionBase + #self._Instructions + 1
                                    local extraSteps = self._ExtraEndCompleteStepByCellId
                                    if extraSteps and not extraSteps[ng.CellId] then
                                        extraSteps[ng.CellId] = commandIndex
                                    end
                                end
                                self._Instructions[#self._Instructions + 1] = {
                                    Type = Instruction.Disembark,
                                    GridX = n.x,
                                    GridY = n.y,
                                    CarriageIndex = ci,
                                    Color = color,
                                    CarriagePassengerBefore = carriagePassengerBefore
                                }
                                carriage.Passenger = nil
                                -- 下车后修改乘客表情（根据颜色决定，从车厢转移到格子）
                                local emoj = self:_GetEmojByColor(color)
                                local emojBefore = self:GetEmojState(self:_GetCarriageEmojKey(ci))
                                self._Instructions[#self._Instructions + 1] = {
                                    Type = Instruction.ChangePassengerEmoj,
                                    GridX = n.x,
                                    GridY = n.y,
                                    Emoj = emoj,
                                    EmojBefore = emojBefore
                                }
                                -- 更新表情状态：格子乘客表情设为下车后的表情
                                self:SetEmojState(self:_GetGridEmojKey(n.x, n.y), emoj)
                                -- 下车到额外终点，立即生成终点激活指令
                                self._Instructions[#self._Instructions + 1] = {
                                    Type = Instruction.ActivateEnd,
                                    GridX = n.x,
                                    GridY = n.y,
                                }
                                -- 下车后刷新车站颜色并递归传播
                                self:_EmitPropagateInstructions(self:RefreshStationColorsWithPropagate())
                                break
                            end
                        end
                    end
                end
            else
                -- 上车冲突：收集周围所有冲突乘客坐标（排除额外终点上的乘客），生成冲突指令
                local conflictPassengers = {}
                for _, n in ipairs(neighbors) do
                    local ng = self:GetGrid(n)
                    if ng and ng.Passenger and ng.Type ~= GridType.ExtraEnd then
                        conflictPassengers[#conflictPassengers + 1] = { x = n.x, y = n.y }
                    end
                end
                self._Instructions[#self._Instructions + 1] = {
                    Type = Instruction.Conflict,
                    CarriageIndex = ci,
                    ConflictPassengers = conflictPassengers,
                }
            end

            -- 5. 检测终点：上左下右，若终点格满足完成条件则激活（只检测普通终点，额外终点在下车时已处理）
            for _, n in ipairs(neighbors) do
                local ng = self:GetGrid(n)
                -- 只检测普通终点（车头到达的终点），额外终点的激活已在下车时处理
                if ng and ng.Type == GridType.End and self:IsEndGridComplete(ng, n.x, n.y) then
                    -- 记录普通/额外终点在第几个指令后完成（用于星星目标预计算）
                    if ng.CellId then
                        local commandIndex = instructionBase + #self._Instructions + 1
                        local endSteps = self._EndConditionCompleteStepByCellId
                        if endSteps and not endSteps[ng.CellId] then
                            endSteps[ng.CellId] = commandIndex
                        end
                    end
                    self._Instructions[#self._Instructions + 1] = {
                        Type = Instruction.ActivateEnd,
                        GridX = n.x,
                        GridY = n.y,
                    }
                end
            end
        end
    end

    -- 本笔生成完毕，将全局基数推进本笔指令数量，供下一笔使用
    self._InstructionIndexBase = instructionBase + #self._Instructions

    -- 注意：不在这里清空 Path，由 UI 层在动画播放完成后调用 ClearPath
end

--- 清空当前绘制的路径（动画播放完成后调用）
function XLineArithmetic3Game:ClearPath()
    if #self._Path > 0 then
        self._Path = {}
    end
end

--- 检查车头是否到达终点格
---@return boolean
function XLineArithmetic3Game:IsHeadAtEnd()
    local GridType = XLineArithmetic3Enum.GridType

    -- 获取车头当前位置（已走过路径的最后一个点）
    if not self._TraveledPath or #self._TraveledPath == 0 then
        return false
    end

    local headPos = self._TraveledPath[#self._TraveledPath]
    local grid = self:GetGrid(headPos)

    -- 检查车头是否在终点格上
    if not grid then
        return false
    end
    return grid.Type == GridType.End
end

--- 获取当前路径
---@return { x: number, y: number }[]
function XLineArithmetic3Game:GetPath()
    return self._Path
end

--- 获取已走过的路径
---@return { x: number, y: number }[]
function XLineArithmetic3Game:GetTraveledPath()
    return self._TraveledPath
end

--- 添加已走过的路径点（去重）
---@param pos { x: number, y: number }
---@return boolean 是否添加成功
function XLineArithmetic3Game:AddTraveledPath(pos)
    -- 检查是否与最后一个点重复
    local lastPos = self._TraveledPath[#self._TraveledPath]
    if lastPos and lastPos.x == pos.x and lastPos.y == pos.y then
        return false
    end
    self._TraveledPath[#self._TraveledPath + 1] = { x = pos.x, y = pos.y }
    return true
end

--- 移除已走过的路径的最后一个点
function XLineArithmetic3Game:RemoveLastTraveledPath()
    if #self._TraveledPath > 1 then -- 保留起点
        self._TraveledPath[#self._TraveledPath] = nil
    end
end

--- 获取车头位置
---@return { x: number, y: number }
function XLineArithmetic3Game:GetHeadPos()
    return self._HeadPos
end

--- 设置车头位置
---@param pos { x: number, y: number }
function XLineArithmetic3Game:SetHeadPos(pos)
    self._HeadPos = { x = pos.x, y = pos.y }
end

--- 判断指定位置是否是车头
--- 需注意该接口不支持动画运行时的过渡期间判断
function XLineArithmetic3Game:CheckPosIsHead(x, y)
    if not self._HeadPos then
        return false
    end
    
    return self._HeadPos.x == x and self._HeadPos.y == y
end

--- 获取车厢列表
---@return table[]
function XLineArithmetic3Game:GetCarriages()
    return self._Carriages
end

--- 设置指定车厢的位置（用于 Undo 恢复）
---@param index number 车厢索引
---@param pos { x: number, y: number } 位置
function XLineArithmetic3Game:SetCarriagePos(index, pos)
    if self._Carriages[index] and pos then
        self._Carriages[index].Pos = { x = pos.x, y = pos.y }
    end
end

--- 获取本笔生成的指令（供 UI 依次播放）
---@return table[]
function XLineArithmetic3Game:GetInstructions()
    return self._Instructions
end

--- 获取本笔指令的全局步数基数（UI 播放时 currentIndex 需加上此值传给 UpdateStarTarget）
---@return number
function XLineArithmetic3Game:GetInstructionIndexBase()
    -- 本笔 base 是上笔结束后的累计值，即当前 _InstructionIndexBase 减去本笔 #Instructions
    -- 但调用时机是 ConfirmPath 之后、PlayInstructions 之前，此时 base 已推进
    -- 所以返回 base - #instructions，即本笔开始时的 base
    return (self._InstructionIndexBase or 0) - #self._Instructions
end

--- Undo 后重置全局步数基数，并根据地图实际状态重建步数缓存
--- 已完成的终点记录 completeStep = 1，保证任何后续 step >= 1 均满足
function XLineArithmetic3Game:ResetInstructionIndexBase()
    self._InstructionIndexBase = 0
    self._EndConditionCompleteStepByCellId = {}
    self._ExtraEndCompleteStepByCellId = {}
    local GridType = XLineArithmetic3Enum.GridType
    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            local grid = self._Map[y] and self._Map[y][x]
            if grid and grid.CellId then
                if grid.Type == GridType.ExtraEnd and self:IsEndGridComplete(grid, x, y) then
                    self._ExtraEndCompleteStepByCellId[grid.CellId] = 1
                elseif grid.Type == GridType.End and self:IsEndGridComplete(grid, x, y) then
                    self._EndConditionCompleteStepByCellId[grid.CellId] = 1
                end
            end
        end
    end
end

--- 获取地图与尺寸
function XLineArithmetic3Game:GetMap()
    return self._Map
end

function XLineArithmetic3Game:GetMapSize()
    return self._MapSize
end

--- 判断终点格是否已完成：普通终点看车头是否在格子上，额外终点看是否有乘客
---@param grid table 格子
---@param x number 格子 x 坐标
---@param y number 格子 y 坐标
---@return boolean
function XLineArithmetic3Game:IsEndGridComplete(grid, x, y)
    if not grid then
        return false
    end
    local GridType = XLineArithmetic3Enum.GridType
    -- 普通终点：车头在格子上
    if grid.Type == GridType.End then
        local headPos = (self._TraveledPath and #self._TraveledPath > 0) and self._TraveledPath[#self._TraveledPath] or nil
        return (headPos ~= nil) and (headPos.x == x) and (headPos.y == y)
        
        -- 额外终点：有乘客
    elseif grid.Type == GridType.ExtraEnd then
        return grid.Passenger ~= nil
    end
    return false
end

--- 在指定指令步数下判断条件是否满足（使用预计算的完成步数）
---@param condition table 条件模板
---@param step number 指令步数（对应 Instruction 序号）
---@return boolean 是否满足条件
function XLineArithmetic3Game:IsMatchConditionAtStep(condition, step)
    if not condition or not step or step <= 0 then
        return false
    end

    local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
    local conditionType = condition.Type
    local params = condition.Params or {}

    -- 完成指定终点：使用预计算的完成步数（普通终点和额外终点分别记录，需同时查询）
    if conditionType == XLineArithmetic3Enum.CONDITION.COMPLETE_END then
        local cellId = params[1]
        if not cellId then
            return false
        end
        -- 查普通终点缓存
        local endStep = self._EndConditionCompleteStepByCellId and self._EndConditionCompleteStepByCellId[cellId] or nil
        if endStep and step >= endStep then
            return true
        end
        -- 查额外终点缓存（COMPLETE_END 条件可能指向额外终点格）
        local extraStep = self._ExtraEndCompleteStepByCellId and self._ExtraEndCompleteStepByCellId[cellId] or nil
        if extraStep and step >= extraStep then
            return true
        end
        return false

        -- 完成的终点格数量（额外终点）：使用预计算的完成步数
    elseif conditionType == XLineArithmetic3Enum.CONDITION.COMPLETE_END_AMOUNT then
        local requiredAmount = params[1] or 0
        local extraSteps = self._ExtraEndCompleteStepByCellId
        if not extraSteps or requiredAmount <= 0 then
            return false
        end

        local activatedCount = 0
        for _, completeStep in pairs(extraSteps) do
            if completeStep and step >= completeStep then
                activatedCount = activatedCount + 1
            end
        end
        return activatedCount >= requiredAmount
    end

    -- 其他条件暂不支持按步数判断，统一视为未完成
    return false
end

--- 判断条件是否满足
---@param condition table 条件模板
---@return boolean 是否满足条件
function XLineArithmetic3Game:IsMatchCondition(condition)
    if not condition then
        return false
    end

    local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
    local conditionType = condition.Type
    local params = condition.Params or {}

    -- 完成指定终点
    if conditionType == XLineArithmetic3Enum.CONDITION.COMPLETE_END then
        local cellId = params[1]
        if not cellId then
            return false
        end

        -- 遍历地图，找到指定cellId的终点格，检查是否完成
        for y = 1, self._MapSize.y do
            for x = 1, self._MapSize.x do
                local grid = self._Map[y] and self._Map[y][x]
                if grid and grid.CellId == cellId then
                    local GridType = XLineArithmetic3Enum.GridType
                    if grid.Type == GridType.End or grid.Type == GridType.ExtraEnd then
                        return self:IsEndGridComplete(grid, x, y)
                    end
                end
            end
        end
        return false

        -- 完成的终点格数量
    elseif conditionType == XLineArithmetic3Enum.CONDITION.COMPLETE_END_AMOUNT then
        local requiredAmount = params[1] or 0
        local activatedCount = 0

        -- 统计已完成的终点格数量
        for y = 1, self._MapSize.y do
            for x = 1, self._MapSize.x do
                local grid = self._Map[y] and self._Map[y][x]
                if grid then
                    local GridType = XLineArithmetic3Enum.GridType
                    if grid.Type == GridType.ExtraEnd and self:IsEndGridComplete(grid, x, y) then
                        activatedCount = activatedCount + 1
                    end
                end
            end
        end

        return activatedCount >= requiredAmount
    end

    return false
end

--- 获取车头可移动的方向列表（排除回溯方向）
---@return table[] 可移动方向列表，每个元素为 { direction, pos } ，direction 为 Direction 枚举值
function XLineArithmetic3Game:GetMovableDirections()
    local result = {}
    if not self._HeadPos then
        return result
    end

    local Direction = XLineArithmetic3Enum.Direction

    -- 遍历四个方向
    for i, delta in ipairs(DIR_DELTA) do
        local targetPos = {
            x = self._HeadPos.x + delta.x,
            y = self._HeadPos.y + delta.y
        }

        -- 检查是否可以直线到达该位置
        if self:CanStraightReach(targetPos) then
            -- 排除回溯方向（撤销点方向）
            if not self:IsUndoPoint(targetPos) then
                table.insert(result, {
                    direction = i, -- 对应 Direction 枚举 (Up=1, Left=2, Down=3, Right=4)
                    pos = targetPos
                })
            end
        end
    end

    return result
end

--- 根据乘客颜色获取对应的终点表情
---@param color number 乘客颜色
---@return number 表情枚举值
function XLineArithmetic3Game:_GetEmojByColor(color)
    local Emoj = XLineArithmetic3Enum.Emoj
    -- 颜色1-6对应表情4-9
    if color >= 1 and color <= 6 then
        return Emoj["ToColor" .. color .. "End"]
    end
    -- 默认返回最终终点表情
    return Emoj.ToFinalEnd
end

return XLineArithmetic3Game
