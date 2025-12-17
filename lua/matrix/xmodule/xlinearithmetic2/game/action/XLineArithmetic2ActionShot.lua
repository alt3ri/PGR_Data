local XLineArithmetic2Action = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2Action")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2Util = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Util")
local XLineArithmetic2AnimationColor = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationColor")
local XLineArithmetic2AnimationGroup = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGroup")
local XLineArithmetic2AnimationUpdateMap = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationUpdateMap")
local XLineArithmetic2AnimationGrid = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGrid")
local XLineArithmetic2AnimationGroupLine = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGroupLine")

---@class XLineArithmetic2ActionShot:XLineArithmetic2Action
local XLineArithmetic2ActionShot = XClass(XLineArithmetic2Action, "XLineArithmetic2ActionShot")

function XLineArithmetic2ActionShot:Ctor()
    self._Type = XLineArithmetic2Enum.ACTION.SHOT
    ---@type XLuaVector2
    self._Pos = false
    ---@type XLuaVector2
    self._Direction = false
end

function XLineArithmetic2ActionShot:SetPos(pos)
    self._Pos = pos
end

function XLineArithmetic2ActionShot:SetDirection(direction)
    self._Direction = direction
end

---@param game XLineArithmetic2Game
---@param model XLineArithmetic2Model
function XLineArithmetic2ActionShot:Execute(game, model)
    local grid = game:GetGrid(self._Pos)
    if not grid then
        XLog.Error("[XLineArithmetic2ActionShot] 找不到该坐标对应的终点格")
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 由于预览功能,改变了棋盘上的内容,所以需要先还原一遍棋盘内容
    local mapData = {}
    game:GetGameMapData(mapData)
    ---@type XLineArithmetic2AnimationUpdateMap
    local animationUpdateMap = XLineArithmetic2AnimationUpdateMap.New()
    animationUpdateMap:SetMapData(mapData)
    game:AddAnimation(animationUpdateMap)

    -- 确保方向正确性, 只有上下左右, 并且每次只移动一格
    local direction = self._Direction
    local offset = XLuaVector2.New()
    if direction.x > 0 then
        offset.x = 1
    elseif direction.x < 0 then
        offset.x = -1
    elseif direction.y > 0 then
        offset.y = 1
    elseif direction.y < 0 then
        offset.y = -1
    else
        XLog.Error("[XLineArithmetic2ActionShot] 找不到该方向对应的偏移量")
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 染色单格
    if grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE then
        local grid2Color = XLineArithmetic2Util.FindGrid2Shot(game, grid, offset)
        if grid2Color then
            self:ColorAdjacentSameColorGrid(game, { grid2Color }, grid, model)
        end

        -- 如果子弹用完, 还原终点格
        grid:SetBullet(grid:GetBullet() - 1)
        if grid:GetBullet() == 0 then
            grid:SetColor(XLineArithmetic2Enum.COLOR.NONE)
            grid:SetBulletColor(XLineArithmetic2Enum.COLOR.NONE)
            grid:SetType(XLineArithmetic2Enum.GRID.END)
            self:PlayAnimationBulletClear(game, grid)
        end

        -- 发射后，清除弹道方向
        game:SetReadyShot(false)
        grid:ClearShotDirection()
        game:RemoveFromLine(grid)
        if self._Record then
            self._Record.Type = XLineArithmetic2Enum.GRID.END_COLOR_ONE
        end
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 染色多格
    if grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH then
        local grid2Colors = XLineArithmetic2Util.FindGrid2Shot(game, grid, offset)
        if #grid2Colors > 0 then
            self:ColorAdjacentSameColorGrid(game, grid2Colors, grid, model)
        end

        -- 如果子弹用完, 还原终点格
        grid:SetBullet(grid:GetBullet() - 1)
        if grid:GetBullet() == 0 then
            grid:SetColor(XLineArithmetic2Enum.COLOR.NONE)
            grid:SetBulletColor(XLineArithmetic2Enum.COLOR.NONE)
            grid:SetType(XLineArithmetic2Enum.GRID.END)
            game:SetReadyShot(false)
            grid:ClearShotDirection()
            game:RemoveFromLine(grid)
            self:PlayAnimationBulletClear(game, grid)
        end
        if self._Record then
            self._Record.Type = XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
        end
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 填充格子
    if grid:GetType() == XLineArithmetic2Enum.GRID.END_FILL then
        local p = grid:GetPos()
        local nextP = XLuaVector2.New(p.x, p.y)
        local newGrids = {}
        for i = 1, 99 do
            nextP.x = nextP.x + offset.x
            nextP.y = nextP.y + offset.y
            if game:IsInMap(nextP) then
                local grid2Fill = game:GetGrid(nextP)
                if not grid2Fill or grid2Fill:IsEmpty() then
                    local fillId = grid:GetFillGridId()
                    if fillId and fillId > 0 then
                        local config = model:GetGridById(fillId)
                        grid2Fill = game:NewGrid(config, nextP)
                        newGrids[#newGrids + 1] = grid2Fill
                        if self._Record then
                            self._Record.FillAmount = self._Record.FillAmount or 0
                            self._Record.FillAmount = self._Record.FillAmount + 1
                        end
                    else
                        XLog.Error("[XLineArithmetic2ActionShot] 要填充的格子id为空")
                    end
                end
            else
                -- 超出棋盘
                break
            end
        end

        self:PLayAnimationNewGrid(game, newGrids)

        -- 如果子弹用完, 还原终点格
        grid:SetBullet(grid:GetBullet() - 1)
        if grid:GetBullet() == 0 then
            grid:SetColor(XLineArithmetic2Enum.COLOR.NONE)
            grid:SetBulletColor(XLineArithmetic2Enum.COLOR.NONE)
            grid:SetType(XLineArithmetic2Enum.GRID.END)
            game:SetReadyShot(false)
            grid:ClearShotDirection()
            game:RemoveFromLine(grid)
            self:PlayAnimationBulletClear(game, grid)
        end
        if self._Record then
            self._Record.Type = XLineArithmetic2Enum.GRID.END_FILL
        end
        self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
        return
    end

    -- 有问题
    XLog.Error("[XLineArithmetic2ActionShot] 未处理的发射类型")
end

-- 染色相邻相同颜色的格子
---@param game XLineArithmetic2Game
---@param grids XLineArithmetic2Grid[]
---@param endGrid XLineArithmetic2Grid
---@param model XLineArithmetic2Model
function XLineArithmetic2ActionShot:ColorAdjacentSameColorGrid(game, grids, endGrid, model)
    -- 认为grid是安全的, 如果grid非法, 那么这个函数gg
    local color = endGrid:GetBulletColor()
    local queue = XQueue.New()
    local layerDict = { }
    local passed = {}
    local color2ReplaceDict = {}
    local gridDataDict = {}
    for i = 1, #grids do
        local grid = grids[i]
        local pos = grid:GetPos()
        queue:Enqueue(pos)
        layerDict[grid:GetUid()] = 1
        passed[grid:GetUid()] = true
    end

    while queue:Count() > 0 do
        local p = queue:Dequeue()
        local grid2Color = game:GetGrid(p)
        if grid2Color then
            local color2Replace = grid2Color:GetColor()
            if game:IsAnimation() then
                color2ReplaceDict[grid2Color:GetUid()] = color2Replace
            end
            --XLog.Debug(string.format("[XLineArithmetic2ActionShot] 染色格子: %s, %s", grid2Color:GetPos().x, grid2Color:GetPos().y))
            grid2Color:SetColor(color, model, true)
            -- 保存染色后的数据, 在播放染色动画之前, 先updateGrid
            if game:IsAnimation() then
                gridDataDict[grid2Color:GetUid()] = game:GetGridData(grid2Color)
            end

            for i = 1, 4 do
                local nextP = XLuaVector2.New(p.x, p.y)
                if i == 1 then
                    nextP.x = nextP.x + 1
                elseif i == 2 then
                    nextP.x = nextP.x - 1
                elseif i == 3 then
                    nextP.y = nextP.y + 1
                else
                    nextP.y = nextP.y - 1
                end
                if game:IsInMap(nextP) then
                    local neighbour = game:GetGrid(nextP)
                    if neighbour and neighbour:IsCanColor() and neighbour:GetColor() == color2Replace then
                        if not passed[neighbour:GetUid()] then
                            passed[neighbour:GetUid()] = true
                            if game:IsAnimation() then
                                local layer = layerDict[grid2Color:GetUid()] + 1
                                if (not layerDict[neighbour:GetUid()])
                                        or (layerDict[neighbour:GetUid()] > layer)
                                then
                                    layerDict[neighbour:GetUid()] = layer
                                    --print(string.format("坐标（%s,%s），传染者(%s,%s) 层级: %s", nextP.x, nextP.y, p.x, p.y, layer))
                                end
                            end

                            queue:Enqueue(nextP)
                            --print(string.format("[XLineArithmetic2ActionShot] 压入队列: %s, %s", nextP.x, nextP.y))
                            if self._Record then
                                self._Record.ColorAmount = self._Record.ColorAmount or 0
                                self._Record.ColorAmount = self._Record.ColorAmount + 1
                            end
                        end
                    end
                end
            end
        end
    end

    if game:IsAnimation() then
        local duplicates = {}
        local layer2Animation = {}
        for uid, layer in pairs(layerDict) do
            if not duplicates[uid] then
                duplicates[uid] = true
                if not layer2Animation[layer] then
                    layer2Animation[layer] = XLineArithmetic2AnimationGroup.New()
                end

                ---@type XLineArithmetic2AnimationGroup
                local animationGroup = XLineArithmetic2AnimationGroup.New()
                layer2Animation[layer]:Add(animationGroup)

                local gridData = gridDataDict[uid]
                if gridData then
                    ---@type XLineArithmetic2AnimationUpdateMap
                    local animationUpdateMap = XLineArithmetic2AnimationUpdateMap.New()
                    animationUpdateMap:SetGridData(gridData)
                    animationGroup:Add(animationUpdateMap)
                else
                    XLog.Error("[XLineArithmetic2ActionShot] 要染色的格子,没有预先缓存gridData, uid:" .. tostring(uid))
                end

                ---@type XLineArithmetic2AnimationColor
                local animation = XLineArithmetic2AnimationColor.New()
                animationGroup:Add(animation)

                local colorAnimationType
                local color2Replace = color2ReplaceDict[uid]
                -- 紫色->蓝色
                if color2Replace == XLineArithmetic2Enum.COLOR.PURPLE and color == XLineArithmetic2Enum.COLOR.BLUE then
                    colorAnimationType = XLineArithmetic2Enum.COLOR_ANIMATION.PURPLE_TO_BLUE

                    -- 紫色->红色
                elseif color2Replace == XLineArithmetic2Enum.COLOR.PURPLE and color == XLineArithmetic2Enum.COLOR.RED then
                    colorAnimationType = XLineArithmetic2Enum.COLOR_ANIMATION.PURPLE_TO_RED

                    -- 紫色
                elseif color == XLineArithmetic2Enum.COLOR.PURPLE then
                    colorAnimationType = XLineArithmetic2Enum.COLOR_ANIMATION.TO_PURPLE

                    -- 红蓝色
                elseif color2Replace == XLineArithmetic2Enum.COLOR.RED or color2Replace == XLineArithmetic2Enum.COLOR.BLUE then
                    if endGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE then
                        colorAnimationType = XLineArithmetic2Enum.COLOR_ANIMATION.TO_RED_BLUE_SINGLE
                    elseif endGrid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH then
                        colorAnimationType = XLineArithmetic2Enum.COLOR_ANIMATION.TO_RED_BLUE_THROUGH
                    end
                end
                animation:SetData(uid, colorAnimationType, 0.1)
            end
        end
        for layer, animationGroup in ipairs(layer2Animation) do
            game:AddAnimation(animationGroup)
        end
    end
end

---@param game XLineArithmetic2Game
---@param grid XLineArithmetic2Grid
function XLineArithmetic2ActionShot:PlayAnimationBulletClear(game, grid)
    if game:IsAnimation() then
        ---@type XLineArithmetic2AnimationGroup
        local animationGroup = XLineArithmetic2AnimationGroup.New()
        game:AddAnimation(animationGroup)

        -- 先把格子刷成终点格,才能播放动画
        ---@type XLineArithmetic2AnimationUpdateMap
        local animationUpdateMap = XLineArithmetic2AnimationUpdateMap.New()
        local gridData = game:GetGridData(grid)
        animationUpdateMap:SetGridData(gridData)
        animationGroup:Add(animationUpdateMap)

        ---@type XLineArithmetic2AnimationGrid
        local animationGrid = XLineArithmetic2AnimationGrid.New()
        animationGrid:SetData(grid:GetUid(), "Grid04Enable", 0.5)
        animationGroup:Add(animationGrid)
    end
end

---@param game XLineArithmetic2Game
---@param newGrids XLineArithmetic2Grid[]
function XLineArithmetic2ActionShot:PLayAnimationNewGrid(game, newGrids)
    if game:IsAnimation() then
        ---@type XLineArithmetic2AnimationGroup
        local animationGroup = XLineArithmetic2AnimationGroup.New()
        game:AddAnimation(animationGroup)

        -- 在增加填充格子的时候已经update
        ---@type XLineArithmetic2AnimationUpdateMap
        local animationUpdateMap = XLineArithmetic2AnimationUpdateMap.New()
        animationGroup:Add(animationUpdateMap)

        for i = 1, #newGrids do
            local grid = newGrids[i]
            ---@type XLineArithmetic2AnimationGrid
            local animationGrid = XLineArithmetic2AnimationGrid.New()
            if grid:GetColor() == XLineArithmetic2Enum.COLOR.RED then
                animationGrid:SetData(grid:GetUid(), "RedEnable", 0.1)
            elseif grid:GetColor() == XLineArithmetic2Enum.COLOR.BLUE then
                animationGrid:SetData(grid:GetUid(), "BlueEnable", 0.1)
            end
            animationGroup:Add(animationGrid)
        end
    end
end

return XLineArithmetic2ActionShot