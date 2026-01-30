--- 负责管理方块相关数据读写的子控制器
---@class XGame2048GridsControl: XControl
---@field private _MainControl XGame2048GameControl
---@field private _Model XGame2048Model
local XGame2048GridsControl = XClass(XControl, 'XGame2048GridsControl')

local XGame2048Grid = require('XModule/XGame2048/InGame/Entity/XGame2048Grid')

function XGame2048GridsControl:OnInit()
    ---@type XPool
    self._GridBlockEntityPool = XPool.New(function()
        return XGame2048Grid.New()
    end, function(grid)
        grid:OnRecycle()
    end)

    -- 实体数组
    ---@type XGame2048Grid[]
    self._GridEntities = nil
    
    -- 被废弃的实体的哈希表
    ---@type table<XGame2048Grid, bool>
    self._WasteGridEntities = nil   
    
    -- 坐标映射字典, <key: 整数值，0100 - 9900 范围表示x，0-99范围表示y>
    ---@type table<number, XGame2048Grid>
    self._PosToGrid = nil
end

function XGame2048GridsControl:OnRelease()
    self._GridBlockEntityPool:Clear()
    self._GridBlockEntityPool = nil
    
    self._GridEntities = nil
    self._WasteGridEntities = nil
    self._PosToGrid = nil
end

function XGame2048GridsControl:InitGrids()
    -- 重置
    self._GridEntities = {}
    self._WasteGridEntities = {}
    self._PosToGrid = {}

    -- 刷新
    local gridInfos = self._MainControl.TurnControl:GetGridInfos()
    
    if not XTool.IsTableEmpty(gridInfos) then
        for i, info in pairs(gridInfos) do
            self:GetGridEntityByServerBlockData(info)
        end
    end
end

--region Get

--- 获取一个格子对象
---@return XGame2048Grid
function XGame2048GridsControl:GetGridDataInPool()
    return self._GridBlockEntityPool:GetItemFromPool()
end

--- 通过服务端的方块数据，实例化方块实体到缓存中，并返回
---@return XGame2048Grid
function XGame2048GridsControl:GetGridEntityByServerBlockData(info)
    ---@type XGame2048Grid
    local gridEntity = self:GetGridDataInPool()
    gridEntity.Uid = self._MainControl:GetNewUid()

    local blockCfg = self._Model:GetGame2048BlockCfgById(info.BlockId)
    local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(blockCfg.Type)

    gridEntity:InitData(info, blockCfg, blockTypeCfg)

    self:AddNewGrid(gridEntity)

    return gridEntity
end

--- 将传入的坐标值转换为索引值
function XGame2048GridsControl:GetGridEntityPosIndexByNormalizePos(x, y)
    return x * 100 + y
end

--- 添加新的方块到指定位置中
---@param gridEntity XGame2048Grid
function XGame2048GridsControl:AddNewGrid(gridEntity)
    table.insert(self._GridEntities, gridEntity)
    
    local posIndex = self:GetGridEntityPosIndexByNormalizePos(gridEntity:GetX(), gridEntity:GetY())
    
    self._PosToGrid[posIndex] = gridEntity
end

--- 获取方块实体数组
function XGame2048GridsControl:GetGridEntities()
    return self._GridEntities
end

--- 获取方块实体数量
function XGame2048GridsControl:GetGridEntitiesCount()
    return XTool.GetTableCount(self._GridEntities)
end

--- 通过uid获取方块实体
function XGame2048GridsControl:GetGridEntityByUid(uid)
    if not XTool.IsTableEmpty(self._GridEntities) then
        ---@param v XGame2048Grid
        for i, v in pairs(self._GridEntities) do
            if v.Uid == uid then
                return v
            end
        end
    end
end

--- 根据传入的坐标值，获取方块实体
---@return XGame2048Grid
function XGame2048GridsControl:GetGridEntityByNormalizePos(x, y)
    local posIndex = self:GetGridEntityPosIndexByNormalizePos(x, y)

    return self._PosToGrid[posIndex]
end

--- 获取棋盘上最高分数方块的数值，用于fever进度展示
function XGame2048GridsControl:GetMaxValueFromGridEntities()
    if not XTool.IsTableEmpty(self._GridEntities) then
        local maxValue = 0

        ---@param v XGame2048Grid
        for i, v in pairs(self._GridEntities) do
            local value = v:GetValue()
            if value > maxValue then
                maxValue = value
            end
        end

        return maxValue
    end

    return 0
end

--- 找到实体数组中第一个指定类型的方块
---@return XGame2048Grid
function XGame2048GridsControl:GetFirstGridEntityFromArrayByType(type)
    for i, v in pairs(self._GridEntities) do
        if v:GetGridType() == type then
            return v
        end
    end
end

--- 获取消除方块当前可消除的范围
---@param dispelGrid @消除方块，可缺省，缺省时手动找一次
function XGame2048GridsControl:GetDispelGridCleanUpRange(dispelGrid)
    -- 找到符合规则1的所有方块进行消除
    ---@type XGame2048Grid
    dispelGrid = dispelGrid or self:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)

    if dispelGrid then
        local direction = dispelGrid:GetExValue()

        local isVertical = direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up or direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Down
        local adds = 0

        if direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up or direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Right then
            adds = 1
        else
            adds = -1
        end

        local beginX = isVertical and 1 or (adds > 0 and dispelGrid:GetX() or 1)
        local endX = isVertical and 4 or (adds > 0 and 4 or dispelGrid:GetX())

        local beginY = not isVertical and 1 or (adds > 0 and dispelGrid:GetY() or 1)
        local endY = not isVertical and 4 or (adds > 0 and 4 or dispelGrid:GetY())
        
        return beginX, endX, beginY, endY
    else
        return 4, 4, 4, 4
    end
end

--- 获取消除方块当前不可消除的范围
function XGame2048GridsControl:GetDispelGridCleanUpInvalidRange()
    -- 获取无效区域的左下角和右上角
    local dispelGrid = self:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)

    local leftDownX, leftDownY, rightUpX, rightUpY = 0, 0, 0, 0
    local hasInValidArea = false

    local dispelGridX = dispelGrid:GetX()
    local dispelGridY = dispelGrid:GetY()

    if dispelGrid:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up and dispelGridY > 1 then
        leftDownX = 1
        leftDownY = 1
        rightUpX = 4
        rightUpY = dispelGridY - 1
        hasInValidArea = true
    elseif dispelGrid:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Down and dispelGridY < 4 then
        leftDownX = 1
        leftDownY = dispelGridY + 1
        rightUpX = 4
        rightUpY = 4
        hasInValidArea = true
    elseif dispelGrid:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Left and dispelGridX < 4 then
        leftDownX = dispelGridX + 1
        leftDownY = 1
        rightUpX = 4
        rightUpY = 4
        hasInValidArea = true
    elseif dispelGrid:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Right and dispelGridX > 1 then
        leftDownX = 1
        leftDownY = 1
        rightUpX = dispelGridX - 1
        rightUpY = 4
        hasInValidArea = true
    end
    
    return hasInValidArea, leftDownX, leftDownY, rightUpX, rightUpY
end

--- 判断消除方块当前范围内是否有可消除方块
function XGame2048GridsControl:CheckDispelRangeHasWaterOrFireGrid()
    local beginX, endX, beginY, endY = self:GetDispelGridCleanUpRange()

    for x = beginX, endX do
        for y = beginY, endY do
            local grid = self:GetGridEntityByNormalizePos(x, y)

            if grid then
                -- 判断是否指定方块
                if grid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.Water or grid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.Fire then
                    return true
                end
            end
        end
    end
    
    return false
end

--- 判断一个方块是否处于消除范围
function XGame2048GridsControl:CheckGridIsInCleanUpRange(x, y)
    local beginX, endX, beginY, endY = self:GetDispelGridCleanUpRange()

    if x >= beginX and x <= endX and y >= beginY and y <= endY then
        return true
    end
    
    return false
end

--- 获取消除方块的标准坐标
function XGame2048GridsControl:GetDispelGridNormalizePos()
    local dispelGrid = self:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)

    if dispelGrid then
        return dispelGrid:GetX(), dispelGrid:GetY()
    else
        return 0, 0
    end
end
--endregion

--region Set

--- 回收一个格子对象
function XGame2048GridsControl:ReturnGridDataToPool(gridEntity)
    self._GridBlockEntityPool:ReturnItemToPool(gridEntity)
end

--- 将一个方块设置到指定位置中，如果指定位置存在方块，则与它互换位置
---@param gridEntity XGame2048Grid
function XGame2048GridsControl:SetGridEntityToAimPos(gridEntity, newX, newY)
    local oldX = gridEntity:GetX()
    local oldY = gridEntity:GetY()
    
    local oldPosIndex = self:GetGridEntityPosIndexByNormalizePos(oldX, oldY)
    local newPosIndex = self:GetGridEntityPosIndexByNormalizePos(newX, newY)
    
    local gridInNewPos = self._PosToGrid[newPosIndex]
    
    -- 先交换坐标映射的缓存
    self._PosToGrid[newPosIndex] = gridEntity
    self._PosToGrid[oldPosIndex] = gridInNewPos
    
    -- 再修改实体内的坐标值
    gridEntity:SetNewPosition(newX, newY)

    if gridInNewPos then
        gridInNewPos:SetNewPosition(oldX, oldY)
    end
end

--- 移除一个方块数据并标记到废弃字典中
---@param isTurnBegin @是否是回合内移除的
function XGame2048GridsControl:RemoveGridAndMarkAsWaste(grid, isTurnBegin)
    local isIn, index = table.contains(self._GridEntities, grid)
    if isIn then
        table.remove(self._GridEntities, index)
    end
    self._WasteGridEntities[grid] = true
    self._PosToGrid[grid:GetX() * 100 + grid:GetY()] = nil

    -- 服务端数据也要移除掉
    self._MainControl.TurnControl:RemoveGridDataInServerData(grid, isTurnBegin)
end

--- 将上一回合产生的消除回收
function XGame2048GridsControl:RecycleAllWasteGridEntityLastTurn()
    if not XTool.IsTableEmpty(self._WasteGridEntities) then
        for k, v in pairs(self._WasteGridEntities) do
            self:ReturnGridDataToPool(k)
        end
        self._WasteGridEntities = {}
    end
end

function XGame2048GridsControl:UpdateServerDataByPos(serverData, posX, posY)
    local gridEntity = self:GetGridEntityByNormalizePos(posX, posY)

    if gridEntity then
        gridEntity:SetServerData(serverData)
        
        return gridEntity.Uid
    end
end
--endregion


--- 根据当前消除方块的方位，生成它的方向
---@param dispelGrid XGame2048Grid
function XGame2048GridsControl:UpdateDispelGridDirectionByPos(dispelGrid)
    if not dispelGrid then
        dispelGrid = self.GridsControl:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)
    end

    if self._DispelCornerDistance == nil then
        self._DispelCornerDistance = {} -- 索引次序：上下左右

        for i = 1, 4 do
            local data = {}

            data.Direction = i

            self._DispelCornerDistance[i] = data
        end
    end
    
    self._DispelCornerDistance[1].Distance = 4 - dispelGrid:GetY()
    self._DispelCornerDistance[2].Distance = dispelGrid:GetY() - 1

    self._DispelCornerDistance[3].Distance = dispelGrid:GetX() - 1
    self._DispelCornerDistance[4].Distance = 4 - dispelGrid:GetX()
    
    -- 找出距离最近的
    local minDist = math.maxinteger
    
    local minDistList = {}

    for i, v in ipairs(self._DispelCornerDistance) do
        if v.Distance < minDist then
            minDist = v.Distance

            for index = #minDistList, 1, -1 do
                minDistList[index] = nil
            end
            
            table.insert(minDistList, v)
        elseif v.Distance == minDist then
            table.insert(minDistList, v)
        end
    end
    
    local minCount = #minDistList

    if minCount == 1 then
        dispelGrid:SetExValue(minDistList[1].Direction)
    elseif minCount > 1 then
        local index = XMath.ToInt(self._MainControl.CustomRandom:Next(1, minCount + 1))
        
        local data = minDistList[index]

        if data then
            dispelGrid:SetExValue(data.Direction) 
        end
    end
end

return XGame2048GridsControl