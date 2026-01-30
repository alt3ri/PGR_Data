local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2Action = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2Action")
local XLineArithmetic2AnimationGroup = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGroup")
local XLineArithmetic2AnimationMoveGrid = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationMoveGrid")
local XLineArithmetic2AnimationEat = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationEat")
local XLineArithmetic2AnimationUpdateMap = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationUpdateMap")
local XLineArithmetic2AnimationGrid = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGrid")
local XLineArithmetic2AnimationRevertGridState = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationRevertGridState")

---@class XLineArithmetic2ActionEat: XLineArithmetic2Action
local XLineArithmetic2ActionEat = XClass(XLineArithmetic2Action, "XLineArithmetic2ActionEat")

function XLineArithmetic2ActionEat:Ctor()
    self._Type = XLineArithmetic2Enum.ACTION.EAT
end

---@param game XLineArithmetic2Game
---@param model XLineArithmetic2Model
function XLineArithmetic2ActionEat:Execute(game, model)
    if self._State == XLineArithmetic2Enum.ACTION_STATE.NONE then
        self._State = XLineArithmetic2Enum.ACTION_STATE.PLAYING
        if self._Record then
            self._Record.Type = XLineArithmetic2Enum.GRID.END
        end
    end

    -- 带终点的格子
    local gridListWithEnd = game:GetLineGridList()
    if #gridListWithEnd < 2 then
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    ---@type XLineArithmetic2Grid
    local endGrid = gridListWithEnd[#gridListWithEnd]

    -- 终点格容量为0
    if endGrid:IsFinish() then
        XLog.Debug("[XLineArithmetic2ActionEat] 终点格容量为0")
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 不带终点的格子
    local gridList = {}
    for i = 1, #gridListWithEnd - 1 do
        local grid = gridListWithEnd[i]
        table.insert(gridList, grid)
    end
    ---@type XLineArithmetic2Grid
    local lastGrid = gridList[#gridList]

    -- 每一次execute, 吃一格
    -- 吃掉不同的格子, 会带来不同的效果
    local gridType = lastGrid:GetType()

    -- 空格子，不应该存在
    if gridType == XLineArithmetic2Enum.GRID.NONE then
        XLog.Error("[XLineArithmetic2ActionEat] 空格子不能吃, 发生了什么")
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 基础格子，障碍格子，染色加分格子
    if gridType == XLineArithmetic2Enum.GRID.BASE
            or gridType == XLineArithmetic2Enum.GRID.OBSTACLE
            or gridType == XLineArithmetic2Enum.GRID.COLOR_SCORE
    then
        -- 移动格子, 吃掉最后一个
        self:MoveGridAndEatLastOne(game, gridList, gridListWithEnd)

        -- 终点格容量为0
        if endGrid:IsFinish() then
            self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
            game:ClearLineGridList()
            self:PlayAnimationComplete(game, endGrid)
            return
        end

        -- 可以连续吃, 所以不终止
        return
    end

    -- 染色子弹
    if gridType == XLineArithmetic2Enum.GRID.BULLET_COLOR_ONE then
        -- 移动格子, 吃掉最后一个
        self:MoveGridAndEatLastOne(game, gridList, gridListWithEnd)
        endGrid:SetType(XLineArithmetic2Enum.GRID.END_COLOR_ONE)
        endGrid:SetColor(lastGrid:GetBulletColor(), model)
        endGrid:SetBullet(endGrid:GetBullet() + lastGrid:GetBullet())
        endGrid:SetBulletColor(lastGrid:GetBulletColor())
        self:AddAnimationEatBullet(game, endGrid)

        -- 进入发射状态以后，那次的连线记录就被清掉了
        game:ClearLineGridList()
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 染色穿透子弹
    if gridType == XLineArithmetic2Enum.GRID.BULLET_COLOR_THROUGH then
        -- 移动格子, 吃掉最后一个
        self:MoveGridAndEatLastOne(game, gridList, gridListWithEnd)
        endGrid:SetType(XLineArithmetic2Enum.GRID.END_COLOR_THROUGH)
        endGrid:SetColor(lastGrid:GetBulletColor(), model)
        endGrid:SetBullet(endGrid:GetBullet() + lastGrid:GetBullet())
        endGrid:SetBulletColor(lastGrid:GetBulletColor())
        self:AddAnimationEatBullet(game, endGrid)

        -- 进入发射状态以后，那次的连线记录就被清掉了
        game:ClearLineGridList()
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 填充子弹
    if gridType == XLineArithmetic2Enum.GRID.BULLET_FILL then
        -- 移动格子, 吃掉最后一个
        self:MoveGridAndEatLastOne(game, gridList, gridListWithEnd)
        endGrid:SetType(XLineArithmetic2Enum.GRID.END_FILL)
        endGrid:SetColor(lastGrid:GetBulletColor(), model)
        endGrid:SetBullet(endGrid:GetBullet() + lastGrid:GetBullet())
        endGrid:SetBulletColor(lastGrid:GetBulletColor())
        endGrid:SetFillGridId(lastGrid:GetFillGridId())
        self:AddAnimationEatBullet(game, endGrid)

        -- 进入发射状态以后，那次的连线记录就被清掉了
        game:ClearLineGridList()
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    XLog.Error("[XLineArithmetic2ActionEat] 未处理的格子类型")
end

-- 移动格子, 吃掉最后一个
---@param game XLineArithmetic2Game
---@param gridList XLineArithmetic2Grid[]
---@param gridListWithEnd XLineArithmetic2Grid[]
---@param record XLineArithmetic2OperationRecord
function XLineArithmetic2ActionEat:MoveGridAndEatLastOne(game, gridList, gridListWithEnd)
    -- 生成动画
    if game:IsAnimation() then
        ---@type XLineArithmetic2AnimationGroup
        local animationGroup = XLineArithmetic2AnimationGroup.New()
        
        -- 还原预览状态
        local revertGridState = XLineArithmetic2AnimationRevertGridState.New()
        animationGroup:Add(revertGridState)
        
        local endGrid = gridListWithEnd[#gridListWithEnd]
        
        for i = 1, #gridListWithEnd do
            local grid = gridListWithEnd[i]
            local nextGrid = gridListWithEnd[i + 1]
            if nextGrid then
                ---@type XLineArithmetic2AnimationMoveGrid
                local animationMoveGrid = XLineArithmetic2AnimationMoveGrid.New()
                local nextGridPos = nextGrid:GetPos()
                local nextGridUiPosX, nextGridUiPosY = game:GetGridUiPos(nextGridPos.x, nextGridPos.y)
                --print("移动格子: " .. tostring(grid:GetUid()) .. " 到 " .. string.format("(%d, %d)", nextGridPos.x, nextGridPos.y))
                animationMoveGrid:SetData(grid:GetUid(), Vector3(nextGridUiPosX, nextGridUiPosY, 0))
                animationGroup:Add(animationMoveGrid)
            end
        end
        game:AddAnimation(animationGroup)

        ---@type XLineArithmetic2AnimationEat
        local animationEat = XLineArithmetic2AnimationEat.New()
        local grid2Eat = gridList[#gridList]
        animationEat:SetData(grid2Eat:GetUid(), endGrid:GetUid(), #gridList, grid2Eat:GetType())
        game:AddAnimation(animationEat)
    end

    -- 把之前的格子清空
    for i = 1, #gridList do
        local grid = gridList[i]
        local pos = grid:GetPos()
        game:SetEmpty(pos)
    end

    -- 把格子向前移动
    for i = 1, #gridList do
        local grid = gridList[i]
        local nextGrid = gridList[i + 1]
        if nextGrid then
            grid:SetPos(nextGrid:GetPos())
            -- 重新设置格子位置
            game:SetGrid(grid)
        end
    end
    local lastGrid = gridList[#gridList]
    gridList[#gridList] = nil

    -- 移除最后一个格子
    table.remove(gridListWithEnd, #gridListWithEnd - 1)

    -- 终点格容量-1
    local endGrid = gridListWithEnd[#gridListWithEnd]
    -- 排除3种子弹
    if lastGrid:GetType() ~= XLineArithmetic2Enum.GRID.BULLET_COLOR_ONE and
            lastGrid:GetType() ~= XLineArithmetic2Enum.GRID.BULLET_COLOR_THROUGH and
            lastGrid:GetType() ~= XLineArithmetic2Enum.GRID.BULLET_FILL then
        self:DecreaseCapacity(game, endGrid)
    end

    -- 只剩下终点格，那么完成本次连线
    if #gridListWithEnd == 1 then
        gridListWithEnd[1] = nil
        endGrid:SetSelected(false)
    end

    -- 加分
    game:AddScore(lastGrid:GetScore())

    --if self._Record then
    --    self._Record.EatAmount = self._Record.EatAmount or 0
    --    self._Record.EatAmount = self._Record.EatAmount + 1
    --end
    --if XMVCA.XLineArithmetic2:IsDebugLog() then
    --    XLog.Debug("[XLineArithmetic2ActionEat] 吃掉了格子:" .. lastGrid:GetCellName(), string.format("(%s,%s)", lastGrid:GetPos().x, lastGrid:GetPos().y))
    --end
end

-- 终点格容量-1
---@param game XLineArithmetic2Game
---@param endGrid XLineArithmetic2Grid
function XLineArithmetic2ActionEat:DecreaseCapacity(game, endGrid)
    if endGrid:GetCapacity() > 0 then
        endGrid:SetCapacity(endGrid:GetCapacity() - 1)
        if endGrid:GetCapacity() == 0 then
            game:SetEndGridFinished(game:GetEndGridFinished() + 1)
        end
    end
end

---@param game XLineArithmetic2Game
---@param grid XLineArithmetic2Grid
function XLineArithmetic2ActionEat:AddAnimationEatBullet(game, grid)
    if not game:IsAnimation() then
        return
    end
    local animationName
    local gridType = grid:GetType()
    if gridType == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
            or gridType == XLineArithmetic2Enum.GRID.END_COLOR_ONE
    then
        animationName = "ColourEnable"
    elseif gridType == XLineArithmetic2Enum.GRID.END_FILL then
        animationName = "LineEnable"
    end
    if not animationName then
        return
    end
    ---@type XLineArithmetic2AnimationGroup
    local animationGroup = XLineArithmetic2AnimationGroup.New()
    game:AddAnimation(animationGroup)

    -- 在同一帧内完成,切换格子类型,和播放动画
    local animationUpdateMap = XLineArithmetic2AnimationUpdateMap.New()
    animationGroup:Add(animationUpdateMap)

    local animationGrid = XLineArithmetic2AnimationGrid.New()
    animationGrid:SetData(grid:GetUid(), animationName, 0.5)
    animationGroup:Add(animationGrid)
end

function XLineArithmetic2ActionEat:PlayAnimationComplete(game, grid)
    if not game:IsAnimation() then
        return
    end
    ---@type XLineArithmetic2AnimationGroup
    local animationGroup = XLineArithmetic2AnimationGroup.New()
    game:AddAnimation(animationGroup)

    ---@type XLineArithmetic2AnimationUpdateMap
    local animationUpdateMap = XLineArithmetic2AnimationUpdateMap.New()
    animationGroup:Add(animationUpdateMap)

    ---@type XLineArithmetic2AnimationGrid
    local animationGrid = XLineArithmetic2AnimationGrid.New()
    animationGrid:SetData(grid:GetUid(), "CompleteEnable", 0.5)
    animationGroup:Add(animationGrid)
end

return XLineArithmetic2ActionEat