local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2ActionLinkGrid = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2ActionLinkGrid")
local XLineArithmetic2ActionEat = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2ActionEat")
local XLineArithmetic2ActionReadyShot = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2ActionReadyShot")
local XLineArithmetic2ActionShot = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2ActionShot")
local XLineArithmetic2ActionCancelSelect = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2ActionCancelSelect")

-- 这是玩家操作
---@class XLineArithmetic2Operation
local XLineArithmetic2Operation = XClass(nil, "XLineArithmetic2Operation")

function XLineArithmetic2Operation:Ctor(operationType)
    self._Type = operationType or XLineArithmetic2Enum.OPERATION.NONE
    self._State = XLineArithmetic2Enum.OPERATION_STATE.NONE
    ---@type XLuaVector2
    self._Data = nil
    ---@type XLineArithmetic2OperationRecord
    self._Record = false
    self._StartScore = 0
    self._Score = 0
    self._IsSendRecord = false
end

function XLineArithmetic2Operation:SetData(data)
    self._Data = data
end

---@param game XLineArithmetic2Game
---@param model XLineArithmetic2Model
function XLineArithmetic2Operation:Execute(game, model)
    --self._State = XLineArithmetic2Enum.OPERATION_STATE.PLAYING

    if self._Type == XLineArithmetic2Enum.OPERATION.NONE then
        self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
        return
    end

    if self._State == XLineArithmetic2Enum.OPERATION_STATE.SUCCESS then
        return
    end

    -- 点击
    if self._Type == XLineArithmetic2Enum.OPERATION.CLICK
            or self._Type == XLineArithmetic2Enum.OPERATION.DRAG
    then
        ---@type Vector2
        local pos = self._Data
        if not pos then
            self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
            return
        end

        ---@type XLineArithmetic2Grid
        local grid = game:GetGrid(pos)

        if grid then
            -- 如果这是一个已经结束的终点格,那么它无论如何都不会再参与游戏
            if grid:GetType() == XLineArithmetic2Enum.GRID.END then
                if grid:IsFinish() then
                    self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                    return
                end
            end
        end

        -- 点击空白处，取消所有选中
        if not grid or grid:IsEmpty() then
            if self._Type == XLineArithmetic2Enum.OPERATION.CLICK then
                local line = game:GetLineGridList()
                if #line > 0 then
                    ---@type XLineArithmetic2ActionCancelSelect
                    local actionCancelSelect = XLineArithmetic2ActionCancelSelect.New()
                    self:EnqueueAction(game, actionCancelSelect)

                    self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                    return
                end
            end
        end

        local line = game:GetLineGridList()
        if #line == 0 then
            if not grid or grid:IsEmpty() then
                self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                return
            end

            -- 终点处于发射状态
            if grid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
                    or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
            then
                ---@type XLineArithmetic2ActionReadyShot
                local action = XLineArithmetic2ActionReadyShot.New()
                action:SetPos(pos)
                self:EnqueueAction(game, action)
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                return
            end

            -- 以下这些格子，可以作为起点
            if grid:GetType() == XLineArithmetic2Enum.GRID.BASE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_ONE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.COLOR_SCORE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_THROUGH
                    or grid:GetType() == XLineArithmetic2Enum.GRID.OBSTACLE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_FILL
            then
                ---@type XLineArithmetic2ActionLinkGrid
                local action = XLineArithmetic2ActionLinkGrid.New()
                action:SetPos(pos)
                self:EnqueueAction(game, action)
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                return
            end
        else
            -- 拖动发射
            local firstGrid = line[1]
            if firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                    or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
                    or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
            then
                if self._Type == XLineArithmetic2Enum.OPERATION.DRAG then
                    -- 已经准备发射
                    if firstGrid:GetShotState() == XLineArithmetic2Enum.SHOT_STATE.READY then
                        local direction = XLuaVector2.Sub(pos, firstGrid:GetPos())

                        -- 修改发射方向
                        ---@type XLineArithmetic2ActionReadyShot
                        local action = XLineArithmetic2ActionReadyShot.New()
                        action:SetPos(firstGrid:GetPos())
                        action:SetDirection(direction)
                        self:EnqueueAction(game, action)
                    end

                    -- 点击取消选中
                elseif self._Type == XLineArithmetic2Enum.OPERATION.CLICK then
                    ---@type XLineArithmetic2ActionLinkGrid
                    local action = XLineArithmetic2ActionLinkGrid.New()
                    action:SetPos(pos)
                    action:SetIsRemove(true)
                    self:EnqueueAction(game, action)
                end

                -- 选择了发射格之后，不能再连接其他格子
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                return
            end

            if not grid or grid:IsEmpty() then
                self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                return
            end

            -- 如果连到了发射中的格子, 取消之前全部,直接进入拖拽状态
            if grid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
                    or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
            then
                if grid:IsNeighbour(line[#line]) then
                    ---@type XLineArithmetic2ActionLinkGrid
                    local actionLink = XLineArithmetic2ActionLinkGrid.New()
                    actionLink:SetPos(pos)
                    self:EnqueueAction(game, actionLink)

                    -- 先亮一下选中, 再取消所有选中的格子
                    ---@type XLineArithmetic2ActionCancelSelect
                    local actionCancelSelect = XLineArithmetic2ActionCancelSelect.New()
                    self:EnqueueAction(game, actionCancelSelect)

                    -- 终点格子被占用的时候 连格子进去需要提示 toast：先进行发射操作
                    XUiManager.TipText("LineArithmeticShotPlease")

                    self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                    return
                end
            end

            -- 如果点击了已经选中的格子，取消选中
            if grid:IsSelected() then
                local isCancel = true
                local lastGrid = line[#line]
                if lastGrid and lastGrid:IsEndGrid() then
                    -- 点击最后一格
                    if ((grid:Equals(lastGrid) and self._Type == XLineArithmetic2Enum.OPERATION.CLICK)
                            -- 或者滑动到倒数第二格
                            or (#line >= 2 and grid:Equals(line[#line - 1])))
                    then
                        isCancel = true
                    else
                        -- 划到了其他已选中的格子
                        self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                        return
                    end
                else
                    isCancel = true
                end
                if isCancel then
                    -- 拖动的时候，保留多一格，必须和点击用不同的逻辑
                    local isKeepDragGrid = false
                    local gridLastButNotLeast = line[#line - 1]
                    if self._Type == XLineArithmetic2Enum.OPERATION.DRAG then
                        if gridLastButNotLeast then
                            if gridLastButNotLeast:Equals(grid) then
                                -- 如果只有2格,不保留选中
                                if #line ~= 2 then
                                    isKeepDragGrid = true
                                end
                            end
                        end
                    end
                    if isKeepDragGrid then
                        local lastGrid = line[#line]
                        ---@type XLineArithmetic2ActionLinkGrid
                        local action = XLineArithmetic2ActionLinkGrid.New()
                        action:SetPos(lastGrid:GetPos())
                        action:SetIsRemove(true)
                        self:EnqueueAction(game, action)
                        self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                        return
                    end

                    ---@type XLineArithmetic2ActionLinkGrid
                    local action = XLineArithmetic2ActionLinkGrid.New()
                    action:SetPos(pos)
                    action:SetIsRemove(true)
                    self:EnqueueAction(game, action)
                    self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                    return
                else
                    self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                    return
                end
            end

            -- 越过终点格，连线中断
            local lastGrid = line[#line]
            if lastGrid:GetType() == XLineArithmetic2Enum.GRID.END then
                self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                return
            end

            -- 发射格子只能在第一格
            -- 越过发射格，连线中断
            if #line > 1 then
                if lastGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                        or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
                        or grid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
                then
                    self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
                    return
                end
            end

            -- 进入发射状态
            -- 如果是点击，则直接触发
            if self._Type == XLineArithmetic2Enum.OPERATION.CLICK then
                if self:Shot(game, pos) then
                    return
                end
            end

            -- 以下这些格子，可以作为中点
            if grid:GetType() == XLineArithmetic2Enum.GRID.BASE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_ONE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.COLOR_SCORE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_COLOR_THROUGH
                    or grid:GetType() == XLineArithmetic2Enum.GRID.OBSTACLE
                    or grid:GetType() == XLineArithmetic2Enum.GRID.BULLET_FILL
            then
                -- 只有与上一个格子相邻 才能加入
                if grid:IsNeighbour(line[#line]) then
                    ---@type XLineArithmetic2ActionLinkGrid
                    local action = XLineArithmetic2ActionLinkGrid.New()
                    action:SetPos(pos)
                    self:EnqueueAction(game, action)
                end
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                return
            end

            -- 终点
            if grid:GetType() == XLineArithmetic2Enum.GRID.END then
                -- 只有与上一个格子相邻 才能加入
                if grid:IsNeighbour(line[#line]) then
                    -- 插入终点
                    ---@type XLineArithmetic2ActionLinkGrid
                    local action = XLineArithmetic2ActionLinkGrid.New()
                    action:SetPos(pos)
                    self:EnqueueAction(game, action)
                end
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                return
            end
        end

        self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
        XLog.Warning("[XLineArithmetic2Operation] 无处理的格子类型")

        -- 松手确认结果
    elseif self._Type == XLineArithmetic2Enum.OPERATION.CONFIRM then
        local gridList = game:GetLineGridList()
        if #gridList > 0 then
            ---@type XLineArithmetic2Grid
            local firstGrid = gridList[1]
            if firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
                    or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                    or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
            then
                local direction = firstGrid:GetShotDirection()
                -- 发射方向合法性
                if (direction.x ~= 0 and direction.y ~= 0) or (direction.x == 0 and direction.y == 0) then
                    -- 松手取消选中
                    firstGrid:SetSelected(false)
                    game:RemoveFromLine(firstGrid)
                    self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                    return
                end

                -- 触发发射
                ---@type XLineArithmetic2ActionShot
                local action = XLineArithmetic2ActionShot.New()
                action:SetPos(firstGrid:GetPos())
                action:SetDirection(firstGrid:GetShotDirection())
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                local pos = XLuaVector2.New()
                pos.x = firstGrid:GetPos().x + firstGrid:GetShotDirection().x
                pos.y = firstGrid:GetPos().y + firstGrid:GetShotDirection().y
                --XLog.Debug("[XLineArithmetic2Operation] 发射坐标：", pos)
                self:MakeRecord(game, pos)
                self:EnqueueAction(game, action)
                return
            end

            local lastGrid = gridList[#gridList]
            if lastGrid:GetType() == XLineArithmetic2Enum.GRID.END then
                -- 终点, 触发吃掉
                ---@type XLineArithmetic2ActionEat
                local action = XLineArithmetic2ActionEat.New()
                self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
                self:MakeRecord(game)
                self:EnqueueAction(game, action)
                return
            end
        end
        self._State = XLineArithmetic2Enum.OPERATION_STATE.FAIL
    end
end

function XLineArithmetic2Operation:IsFinish()
    return self._State == XLineArithmetic2Enum.OPERATION_STATE.SUCCESS
            or self._State == XLineArithmetic2Enum.OPERATION_STATE.FAIL
end

function XLineArithmetic2Operation:GetState()
    return self._State
end

---@param game XLineArithmetic2Game
function XLineArithmetic2Operation:Shot(game, pos)
    -- 终点处于发射状态
    local line = game:GetLineGridList()
    local firstGrid = line[1]
    if not firstGrid then
        return
    end
    if firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
            or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
            or firstGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
    then
        if firstGrid:GetShotState() == XLineArithmetic2Enum.SHOT_STATE.READY then
            self._State = XLineArithmetic2Enum.OPERATION_STATE.SUCCESS

            -- 发射方向只支持上下左右
            local startPos = firstGrid:GetPos()
            local direction = XLuaVector2.Sub(pos, startPos)
            if direction.x ~= 0 and direction.y ~= 0 then
                if direction.x * direction.y ~= 0 then
                    XLog.Warning("[XLineArithmetic2Operation] 发射方向只支持上下左右")
                end
            end

            ---@type XLineArithmetic2ActionShot
            local action = XLineArithmetic2ActionShot.New()
            action:SetPos(startPos)
            action:SetDirection(direction)
            self:MakeRecord(game)
            self:EnqueueAction(game, action)
            return true
        end
    end
    return false
end

---@param game XLineArithmetic2Game
---@param extraPos XLuaVector2@发射，只确定方向，不确定具体格子，所以这里额外传pos
function XLineArithmetic2Operation:MakeRecord(game, extraPos)
    if not game:IsOnline() then
        return
    end

    local line = game:GetLineGridList()
    local gridsRecord = {}
    for i = 1, #line do
        local grid = line[i]
        local pos = grid:GetPos()
        local gridRecord = {
            X = math.floor(pos.x),
            Y = math.floor(pos.y)
        }
        gridsRecord[#gridsRecord + 1] = gridRecord
    end

    --发射，只确定方向，不确定具体格子，所以这里额外传pos
    if extraPos then
        local pos = {
            X = math.floor(extraPos.x),
            Y = math.floor(extraPos.y)
        }
        gridsRecord[#gridsRecord + 1] = pos
    end

    local round = game:GetRound()
    ---@class XLineArithmetic2OperationRecord
    local record = {
        Round = round,
        Points = gridsRecord,
        Score = 0,

    }
    self._Record = record
    self._StartScore = 0
    --XLog.Error(record)
end

function XLineArithmetic2Operation:GetRecord()
    return self._Record
end

function XLineArithmetic2Operation:IsSendRecord()
    return self._IsSendRecord
end

function XLineArithmetic2Operation:SetSendRecord()
    self._IsSendRecord = true
end

function XLineArithmetic2Operation:SetScore(score)
    self._Score = score - self._StartScore
    self._Score = math.max(self._Score, 0)
    self._Record.Score = self._Score
end

---@param game XLineArithmetic2Game
---@param action XLineArithmetic2Action
function XLineArithmetic2Operation:EnqueueAction(game, action)
    action:SetRecord(self._Record)
    game:EnqueueAction(action)
end

return XLineArithmetic2Operation