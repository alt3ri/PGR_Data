local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2Grid = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Grid")
local XLineArithmetic2Operation = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2Operation")

---@class XLineArithmetic2Game
local XLineArithmetic2Game = XClass(nil, "XLineArithmetic2Game")

function XLineArithmetic2Game:Ctor()
    ---@type XLineArithmetic2Grid[][]
    self._Map = {}

    self._MapSize = XLuaVector2.New()

    ---@type XLineArithmetic2Grid[]
    self._LineGridList = {}

    ---@type XQueue
    self._OperationList = XQueue.New()

    ---@type XLineArithmetic2Operation[]
    self._OperationRecord = {}

    ---@type XQueue
    self._ActionList = XQueue.New()

    ---@type XQueue
    self._AnimationList = XQueue.New()

    self._Score = 0

    self._GridUid = 0

    self._IsRequestSettle = false

    self._IsOnline = true
    self._IsAnimation = true

    self._AllCondition = {}

    self._Round = 0

    self._StageId = 0

    self._EndGridAmountFinished = 0
    self._EndGridAmount = 0

    self._ReadyShot = false
    self._ReadyShotPos = XLuaVector2.New()

    self._IsDirty = false

    self._GridSize = XLuaVector2.New()
    self._BgSize = XLuaVector2.New()
end

function XLineArithmetic2Game:IsInMap(pos)
    if not pos then
        return false
    end
    return pos.x >= 1 and pos.x <= self._MapSize.x and pos.y >= 1 and pos.y <= self._MapSize.y
end

---@param pos XLuaVector2
---@return XLineArithmetic2Grid
function XLineArithmetic2Game:GetGrid(pos)
    local x = pos.x
    local y = pos.y
    if x < 1 or x > self._MapSize.x then
        return nil
    end
    if y < 1 or y > self._MapSize.y then
        return nil
    end
    if not self._Map[y] then
        return nil
    end
    return self._Map[y][x]
end

function XLineArithmetic2Game:GetGridByUid(uid)
    for y = 1, self._MapSize.y do
        local line = self._Map[y]
        if line then
            for x = 1, self._MapSize.x do
                local grid = line[x]
                if grid and grid:GetUid() == uid then
                    return grid
                end
            end
        end
    end
end

function XLineArithmetic2Game:SetEmpty(pos)
    local map = self._Map
    if map[pos.y] then
        map[pos.y][pos.x] = false
    else
        XLog.Error("[XLineArithmetic2ActionEat] 要置空的格子不存在:" .. string.format("%d,%d", pos.x, pos.y))
    end
end

function XLineArithmetic2Game:SetGrid(grid)
    local map = self._Map
    local pos = grid:GetPos()
    if map[pos.y] then
        map[pos.y][pos.x] = grid
    else
        XLog.Error("[XLineArithmetic2ActionEat] 要设置的坐标不存在:" .. string.format("%d,%d", pos.x, pos.y))
    end
end

function XLineArithmetic2Game:NewGrid(config, pos)
    self._GridUid = self._GridUid + 1
    ---@type XLineArithmetic2Grid
    local grid = XLineArithmetic2Grid.New(self._GridUid)
    grid:SetPos(pos)
    grid:SetDataFromConfig(config)

    self._Map[pos.y] = self._Map[pos.y] or {}
    self:SetGrid(grid)
    return grid
end

function XLineArithmetic2Game:IsCanOperate()
    return self._ActionList:IsEmpty() and self._OperationList:IsEmpty()
            and not self:IsFinish()
end

---@param pos XLuaVector2
function XLineArithmetic2Game:OnClickPos(pos)
    if self:IsCanOperate() then
        ---@type XLineArithmetic2Operation
        local operation = XLineArithmetic2Operation.New(XLineArithmetic2Enum.OPERATION.CLICK)
        operation:SetData(pos)
        self._OperationList:Enqueue(operation)
    end
end

function XLineArithmetic2Game:OnClickDrag(pos, force)
    if self:IsCanOperate() or force then
        ---@type XLineArithmetic2Operation
        local operation = XLineArithmetic2Operation.New(XLineArithmetic2Enum.OPERATION.DRAG)
        operation:SetData(pos)
        self._OperationList:Enqueue(operation)
    end
end

function XLineArithmetic2Game:ConfirmAction()
    -- 因为confirm在OnDragEnd之后执行，会和OnDrag产生的operation并存，所以这里不做验证
    --if self:IsCanOperate() then
    self._OperationList:Enqueue(XLineArithmetic2Operation.New(XLineArithmetic2Enum.OPERATION.CONFIRM))
    --end
end

function XLineArithmetic2Game:EnqueueAction(action)
    self._ActionList:Enqueue(action)
end

---@param model XLineArithmetic2Model
---@param ui XUiLineArithmetic2Game
function XLineArithmetic2Game:Update(model, ui)
    -- 有动画播动画
    if ui then
        local deltaTime = CS.UnityEngine.Time.deltaTime
        ---@type XLineArithmetic2Animation
        local animation = self._AnimationList:Peek()
        if animation then
            animation:Update(self, ui, deltaTime)
            if animation:IsFinish() then
                self._AnimationList:Dequeue()
                -- 所有动画播完后, update一次界面
                if self._AnimationList:IsEmpty() then
                    self:SetDirty()
                end
            end
            return
        end
    end

    -- 请求中不响应操作
    if model:IsRequesting() then
        return
    end

    -- 有玩家操作执行
    if not self._OperationList:IsEmpty() then
        ---@type XLineArithmetic2Operation
        local operation = self._OperationList:Dequeue()
        if operation then
            operation:Execute(self)
            if operation:IsFinish() and operation:GetRecord() then
                self._OperationRecord[#self._OperationRecord + 1] = operation
            end
        end
    end

    -- 再判断action
    if not self._ActionList:IsEmpty() then
        for i = 1, 99 do
            ---@type XLineArithmetic2Action
            local action = self._ActionList:Peek()
            if action then
                action:Execute(self, model)
                if action:IsFinish() then
                    self._ActionList:Dequeue()
                    -- 有动画就不更新界面, 但是其实更新界面也应该被抽象成animation
                    if self._AnimationList:IsEmpty() then
                        self:SetDirty()
                    end
                end
            else
                break
            end
        end
    end

    -- 发送请求
    if self._IsOnline then
        local operation = self._OperationRecord[#self._OperationRecord]
        if operation then
            if operation:GetState() == XLineArithmetic2Enum.OPERATION_STATE.SUCCESS then
                if not operation:IsSendRecord() then
                    operation:SetScore(self:GetScore())
                    operation:SetSendRecord()
                    local record = operation:GetRecord()
                    self:RequestOperation(record)
                end
            end
        end
    end
end

---@return XLineArithmetic2Grid[]
function XLineArithmetic2Game:GetLineGridList()
    return self._LineGridList
end

function XLineArithmetic2Game:ClearLineGridList()
    for i = #self._LineGridList, 1, -1 do
        local grid = self._LineGridList[i]
        grid:SetSelected(false)
        self._LineGridList[i] = nil
    end
end

function XLineArithmetic2Game:IsOnLineGridList(grid)
    if not grid then
        return false
    end
    for _, lineGrid in ipairs(self._LineGridList) do
        if lineGrid:Equals(grid) then
            return true
        end
    end
    return false
end

function XLineArithmetic2Game:AddScore(score)
    self._Score = self._Score + score
end

---@param model XLineArithmetic2Model
function XLineArithmetic2Game:ImportConfig(model, configs, stageId)
    self._StageId = stageId
    if not configs then
        return
    end
    if #configs <= 0 then
        return
    end
    self._MapSize.x = #configs[1].Column
    self._MapSize.y = #configs
    for y = 1, self._MapSize.y do
        self._Map[y] = {}
        for x = 1, self._MapSize.x do
            self._Map[y][x] = false
        end
    end
    for y = 1, #configs do
        local config = configs[y]
        for x = 1, #config.Column do
            local gridId = config.Column[x]
            if gridId > 0 then
                local gridConfig = model:GetGridById(gridId)
                self:NewGrid(gridConfig, {
                    x = x,
                    y = y,
                })
            end
        end
    end

    local pos = XLuaVector2.New()
    local endGridAmount = 0
    for y = 1, self._MapSize.y do
        for x = 1, self._MapSize.x do
            pos.x = x
            pos.y = y
            local grid = self:GetGrid(pos)
            if grid and grid:IsEndGrid() then
                endGridAmount = endGridAmount + 1
            end
        end
    end
    self._EndGridAmount = endGridAmount
    XLog.Debug("[XLineArithmetic2Game] 地图配置读取完成")
end

function XLineArithmetic2Game:MarkUseHelp()
    self._UseHelp = true
end

function XLineArithmetic2Game:IsUseHelp()
    return self._UseHelp
end

function XLineArithmetic2Game:IsHasRecord()
    return #self._OperationRecord > 0
end

function XLineArithmetic2Game:GetOperationRecord()
    return self._OperationRecord
end

function XLineArithmetic2Game:IsRequestSettle()
    return self._IsRequestSettle
end

function XLineArithmetic2Game:SetRequestSettle()
    self._IsRequestSettle = true
end

function XLineArithmetic2Game:ClearAnimation()
    self._AnimationList:Clear()
end

function XLineArithmetic2Game:SetOffline()
    self._IsOnline = false
end

function XLineArithmetic2Game:DisableAnimation()
    self._IsAnimation = false
end

function XLineArithmetic2Game:SetOnline()
    self._IsOnline = true
end

function XLineArithmetic2Game:GetMap()
    return self._Map
end

function XLineArithmetic2Game:IsFinishSomeFinalGrids()
    return self._EndGridAmountFinished > 0
end

function XLineArithmetic2Game:GetMapSize()
    return self._MapSize
end

function XLineArithmetic2Game:IsMatchCondition(condition, needProgress)
    if condition.Type == XLineArithmetic2Enum.CONDITION.SCORE then
        local score = condition.Params[1]
        return self._Score >= score
    end
    if condition.Type == XLineArithmetic2Enum.CONDITION.END_AMOUNT then
        for y, line in pairs(self._Map) do
            for x, grid in pairs(line) do
                if grid and grid:GetType() == XLineArithmetic2Enum.GRID.END then
                    local isFinish = grid:IsFinish()
                    if isFinish then
                        return true
                    end
                end
            end
        end
    end
    return false
end

---@param grid XLineArithmetic2Grid
function XLineArithmetic2Game:RemoveFromLine(grid)
    for i = 1, #self._LineGridList do
        local grid2 = self._LineGridList[i]
        if grid2:Equals(grid) then
            grid:SetSelected(false)
            table.remove(self._LineGridList, i)
            break
        end
    end
end

function XLineArithmetic2Game:GetScore()
    return self._Score
end

function XLineArithmetic2Game:GetCompleteConditionAmount(isGetByteCode)
    local amount = 0
    local byteCode = 0
    for i = 1, #self._AllCondition do
        local condition = self._AllCondition[i]
        if self:IsMatchCondition(condition) then
            amount = amount + 1
            if isGetByteCode then
                byteCode = byteCode + (10 ^ (i - 1))
            end
        end
    end

    -- byteCode转整型
    byteCode = math.floor(byteCode)
    return amount, byteCode
end

function XLineArithmetic2Game:SetCondition(conditions)
    self._AllCondition = conditions
end

function XLineArithmetic2Game:GetAllCondition()
    return self._AllCondition
end

function XLineArithmetic2Game:IsOnline()
    return self._IsOnline
end

function XLineArithmetic2Game:GetRound()
    return #self._OperationRecord + 1
end

---@param record XLineArithmetic2OperationRecord
function XLineArithmetic2Game:RequestOperation(record)
    if not self._IsOnline then
        return
    end
    local star = self:GetCompleteConditionAmount()
    XMVCA.XLineArithmetic2:RequestOperation(self._StageId, record.Round, star, record.Points)
end

function XLineArithmetic2Game:IsFinish()
    return self._EndGridAmountFinished == self._EndGridAmount
end

function XLineArithmetic2Game:SetEndGridFinished(value)
    value = math.min(value, self._EndGridAmount)
    self._EndGridAmountFinished = value
end

function XLineArithmetic2Game:GetEndGridFinished()
    return self._EndGridAmountFinished
end

function XLineArithmetic2Game:GetStageId()
    return self._StageId
end

function XLineArithmetic2Game:SetReadyShot(value, pos)
    self._ReadyShot = value
    if pos then
        self._ReadyShotPos.x = pos.x
        self._ReadyShotPos.y = pos.y
    end
end

function XLineArithmetic2Game:IsReadyShot()
    return self._ReadyShot
end

function XLineArithmetic2Game:GetReadyShotPos()
    return self._ReadyShotPos
end

---@param game XLineArithmetic2Game
function XLineArithmetic2Game:Copy(game)
    self._MapSize.x = game._MapSize.x
    self._MapSize.y = game._MapSize.y
    self._EndGridAmount = game._EndGridAmount
    self._EndGridAmountFinished = game._EndGridAmountFinished
    self._Score = game._Score
    self._AllCondition = game._AllCondition
    self._IsOnline = game._IsOnline
    self._StageId = game._StageId
    self._ReadyShot = game._ReadyShot
    self._ReadyShotPos = game._ReadyShotPos
    self._OperationRecord = game._OperationRecord
    self._IsRequestSettle = game._IsRequestSettle
    self._UseHelp = game._UseHelp
    self._GridSize.x = game._GridSize.x
    self._GridSize.y = game._GridSize.y
    self._BgSize.x = game._BgSize.x
    self._BgSize.y = game._BgSize.y
    self._Map = {}
    local tempPos = XLuaVector2.New()
    for y = 1, self._MapSize.y do
        self._Map[y] = self._Map[y] or {}
        for x = 1, self._MapSize.x do
            tempPos.x = x
            tempPos.y = y
            local newGrid = self:GetGrid(tempPos)
            local grid = game:GetGrid(tempPos)
            if grid then
                newGrid = grid:Clone(newGrid)
                self._Map[y][x] = newGrid
            elseif newGrid then
                self._Map[y][x] = false
            end
        end
    end
    if #self._LineGridList > 0 then
        for i = #self._LineGridList, 1, -1 do
            self._LineGridList[i] = nil
        end
    end
    for i = 1, #game._LineGridList do
        local grid = game._LineGridList[i]
        local pos = grid:GetPos()
        local newGrid = self:GetGrid(pos)
        table.insert(self._LineGridList, newGrid)
    end
    self._GridUid = game._GridUid
    self._Round = game._Round
    --no animation
    --no action
    --no operation
end

---@param line XLineArithmetic2Grid[]
function XLineArithmetic2Game:GetEatCount(line)
    local firstGrid = line[1]
    if not firstGrid then
        return nil
    end
    --第一个选到可发射格子时 不显示
    if firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
            or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
            or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
    then
        return nil
    end
    --第一个选到终点不显示
    if firstGrid:GetType() == XLineArithmetic2Enum.GRID.END then
        return nil
    end
    local count = 0
    local countIncludeBullet = 0
    for i = 1, #line do
        local grid = line[i]
        if grid:GetType() == XLineArithmetic2Enum.GRID.BASE
                or grid:GetType() == XLineArithmetic2Enum.GRID.OBSTACLE
                or grid:GetType() == XLineArithmetic2Enum.GRID.COLOR_SCORE then
            --之后连线连到障碍格子 障碍格子 染色加分格子 计数+1
            count = count + 1
            countIncludeBullet = countIncludeBullet + 1

        elseif grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_ONE
                or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_THROUGH
                or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_FILL then
            --之后连到可以被发射的格子（染色格子 穿透染色格子 填补格子）计数归0 重新计数
            count = 0
            countIncludeBullet = 1
        end
    end
    return count, countIncludeBullet
end

function XLineArithmetic2Game:IsDirty()
    return self._IsDirty
end

function XLineArithmetic2Game:SetDirty()
    self._IsDirty = true
end

function XLineArithmetic2Game:ClearDirty()
    self._IsDirty = false
end

---@param animation XLineArithmetic2Animation
function XLineArithmetic2Game:AddAnimation(animation)
    self._AnimationList:Enqueue(animation)
end

function XLineArithmetic2Game:IsAnimation()
    return self._IsAnimation
end

function XLineArithmetic2Game:GetGridUiPos(x, y)
    return self._GridSize.x * (x - 0.5) - self._BgSize.x / 2, self._GridSize.y * (y - 0.5) - self._BgSize.y / 2
end

function XLineArithmetic2Game:SetGridAndBgSize(gridSize, bgSize)
    self._GridSize.x = gridSize.x
    self._GridSize.y = gridSize.y
    self._BgSize.x = bgSize.x
    self._BgSize.y = bgSize.y
end

function XLineArithmetic2Game:IsPlayingAnimation()
    return not self._AnimationList:IsEmpty()
end

function XLineArithmetic2Game:GetGridData(grid, isSelected)
    local pos = grid:GetPos()
    local uiX, uiY = self:GetGridUiPos(pos.x, pos.y)

    local number = grid:GetScore()
    local shotDirection
    if grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_THROUGH
            or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_ONE
            or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_FILL
    then
        number = grid:GetBullet()
    elseif grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
            or grid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
            or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
    then
        number = grid:GetBullet()
        shotDirection = grid:GetShotDirection()
    end
    local capacity = grid:GetCapacity()

    ---@class XLineArithmetic2ControlMapData
    local gridData = {
        Uid = grid:GetUid(),
        UiX = uiX,
        UiY = uiY,
        PosX = pos.x,
        PosY = pos.y,
        UiName = "Grid" .. math.floor(pos.x) .. "_" .. math.floor(pos.y),
        Type = grid:GetType(),
        Color = grid:GetColor(),
        IsSelected = isSelected,
        Number = number,
        Capacity = capacity,
        ShotDirection = shotDirection,
        PreviewEatCount = nil,
        IsEatRed = nil,
        Score = grid:GetScore(),
    }
    return gridData
end

---@param mapData XLineArithmetic2ControlMapData[]
function XLineArithmetic2Game:GetGameMapData(mapData)
    local selectedGrid = {}
    local line = self:GetLineGridList()
    for i = 1, #line do
        local grid = line[i]
        selectedGrid[grid:GetUid()] = true
    end

    local map = self:GetMap()
    local mapSize = self:GetMapSize()
    for y = 1, mapSize.y do
        for x = 1, mapSize.x do
            local index = (y - 1) * mapSize.x + x
            local grid = map[y][x]
            if grid then
                local isSelected = selectedGrid[grid:GetUid()]
                local gridData = self:GetGridData(grid, isSelected)
                mapData[index] = gridData
            else
                mapData[index] = false
            end
        end
    end

    -- 预览可以被吃掉的格子数量，在第一个格子上显示数量
    local firstGrid = line[1]
    local eatCount, eatCountIncludeBullet = self:GetEatCount(line)
    if firstGrid then
        ---@type XLineArithmetic2ControlMapData
        local girdToPreviewEatCount
        for i = 1, #mapData do
            local gridData = mapData[i]
            if gridData then
                if gridData.Uid == firstGrid:GetUid() then
                    girdToPreviewEatCount = gridData
                end
            end
        end
        if girdToPreviewEatCount then
            girdToPreviewEatCount.PreviewEatCount = eatCount

            local lastGrid = line[#line]
            if lastGrid then
                if lastGrid:GetType() == XLineArithmetic2Enum.GRID.END then
                    local canEat = lastGrid:GetCapacity()
                    if canEat < eatCount then
                        girdToPreviewEatCount.IsEatRed = true
                    end
                end
            end
        end
    end

    --遍历line, 添加可以吃的标记
    local lastGrid = line[#line]
    if lastGrid and lastGrid:IsEndGrid() then
        local canEat = lastGrid:GetCapacity()
        if eatCountIncludeBullet then
            eatCountIncludeBullet = math.min(eatCountIncludeBullet, canEat)
            local index = 0
            for i = #line, 1, -1 do
                local grid = line[i]
                if grid and not grid:IsEndGrid() then
                    index = index + 1
                    if index <= eatCountIncludeBullet then
                        for i = 1, #mapData do
                            local gridData = mapData[i]
                            if gridData then
                                if gridData.Uid == grid:GetUid() then
                                    gridData.IsPreview = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

return XLineArithmetic2Game