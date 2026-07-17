--- 管理局内所有方块的缓存, 和XUiPanelDyeMergeBoard共用同一个GO
---@class XUiDyeMergeGameGridPools: XUiNode
---@field protected _Control
---@field Parent
local XUiDyeMergeGameGridPools = XClass(XUiNode, "XUiDyeMergeGameGridPools")
local XUiDyeMergeGamePrefabs = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Tools/XUiDyeMergeGamePrefabs")

-- GridLine 对象池常量
local LINE_POOL_NAME = "GridLine"
local LINE_CLS_PATH  = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/Part/XUiGridDyeMergeLine"

-- GridCircle 对象池常量
local CIRCLE_POOL_NAME = "GridCircle"
local CIRCLE_CLS_PATH  = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/Part/XUiGridDyeMergeCircle"

-- 射线入射方向 → 目标方块 pos 节点索引（对侧边缘）
local DirToEntryPosIndex = { [1] = 2, [2] = 3, [3] = 4, [4] = 1 }

function XUiDyeMergeGameGridPools:OnStart()
    ---@type XUiDyeMergeGamePrefabs
    self.PrefabsGetter = XUiDyeMergeGamePrefabs.New(self.PrefabRoot, self)
    
    -- 定义所有方块的对象池
    self._GridRecycleHandler = function(grid)
        if grid.Transform.parent.gameObject.activeInHierarchy then
            grid.Transform:SetParent(self.CacheRoot.transform)
        end
        
        grid:Close()
    end
    
    -- 懒加载各格子的对象池
    ---@type XPool[]
    self._Name2Pools = {}

    -- BlockType → Grid 子类路径（仅需专属子类的类型，其余走默认基类）
    -- 扩展时只在此表新增条目，_GetGridClsByType 无需修改
    local BT = XMVCA.XDyeMergeGame.EnumConst.BlockType
    self._BlockTypeToClsPath = {
        [BT.Floor]              = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeFloor",
        [BT.Normal]             = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeNormal",
        [BT.Target]             = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeTarget",
        [BT.ColorChangeable]    = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeColorChange",
        [BT.VariableLength]     = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeExtend",
        [BT.TurnableMultyColor] = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeTurnable",
        [BT.Mirror]             = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeMirror",
        [BT.ShowOnly]           = "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMergeShowOnly",
    }
end

---@return XUiGridDyeMerge
function XUiDyeMergeGameGridPools:GetGridByNameAndType(name, gridType)
    local pool = self._Name2Pools[name]
    if not pool then
        -- 尝试初始化目标对象池
        local prefab = self.PrefabsGetter:GetPrefabByName(name)

        if not prefab then
            return
        end
        
        self:_InitGridPool(name, prefab, gridType)
        pool = self._Name2Pools[name]
    end
    
    local grid = pool:GetItemFromPool()
    grid.Transform:SetParent(self.PanelBoard.transform)
    
    return grid
end

---@param grid XUiGridDyeMerge
function XUiDyeMergeGameGridPools:ReturnGridByName(name, grid)
    local pool = self._Name2Pools[name]

    if not pool then
        XLog.Error("目标对象池：" .. tostring(name) .. '不存在，由回收改为销毁操作')
        self:RemoveChildNode(grid)
        XUiHelper.Destroy(grid.GameObject)
        return
    end
    
    pool:ReturnItemToPool(grid)
end

function XUiDyeMergeGameGridPools:_InitGridPool(name, prefab, gridType)
    local pool = XPool.New(function()
        local go = XUiHelper.Instantiate(prefab, prefab.transform.parent)
        local cls = self:_GetGridClsByType(gridType)

        if cls then
            local grid = cls.New(go, self)
            
            return grid
        end
    end, self._GridRecycleHandler, false)
    
    self._Name2Pools[name] = pool
end

function XUiDyeMergeGameGridPools:_GetGridClsByType(gridType)
    local path = self._BlockTypeToClsPath[gridType]
               or "XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge"
    return require(path)
end

--region GridLine 对象池

---@return XUiGridDyeMergeLine
function XUiDyeMergeGameGridPools:GetLine()
    local pool = self._Name2Pools[LINE_POOL_NAME]
    if not pool then
        local prefab = self.PrefabsGetter:GetPrefabByName(LINE_POOL_NAME)
        if not prefab then
            return
        end
        self:_InitLinePool(prefab)
        pool = self._Name2Pools[LINE_POOL_NAME]
    end

    local line = pool:GetItemFromPool()
    line.Transform:SetParent(self.PanelBoard.transform)

    return line
end

---@param line XUiGridDyeMergeLine
function XUiDyeMergeGameGridPools:ReturnLine(line)
    local pool = self._Name2Pools[LINE_POOL_NAME]
    if not pool then
        XLog.Error("[DyeMerge] GridLine 对象池不存在，由回收改为销毁操作")
        self:RemoveChildNode(line)
        XUiHelper.Destroy(line.GameObject)
        return
    end
    pool:ReturnItemToPool(line)
end

function XUiDyeMergeGameGridPools:_InitLinePool(prefab)
    local cls = require(LINE_CLS_PATH)
    local pool = XPool.New(function()
        local go = XUiHelper.Instantiate(prefab, prefab.transform.parent)
        local line = cls.New(go, self)
        return line
    end, self._GridRecycleHandler, false)

    self._Name2Pools[LINE_POOL_NAME] = pool
end

--endregion

--region ExtendSlice 对象池

local EXTEND_SLICE_POOL_NAME = "ExtendSlice"

---@return XUiGridDyeMerge
function XUiDyeMergeGameGridPools:GetExtendSlice(extendPrefabName)
    local pool = self._Name2Pools[EXTEND_SLICE_POOL_NAME]
    if not pool then
        local prefab = self.PrefabsGetter:GetPrefabByName(extendPrefabName)
        if not prefab then return end
        self:_InitExtendSlicePool(prefab)
        pool = self._Name2Pools[EXTEND_SLICE_POOL_NAME]
    end

    local slice = pool:GetItemFromPool()
    slice.Transform:SetParent(self.PanelBoard.transform)

    return slice
end

---@param slice XUiGridDyeMerge
function XUiDyeMergeGameGridPools:ReturnExtendSlice(slice)
    local pool = self._Name2Pools[EXTEND_SLICE_POOL_NAME]
    if not pool then
        XLog.Error("[DyeMerge] ExtendSlice 对象池不存在，由回收改为销毁操作")
        self:RemoveChildNode(slice)
        XUiHelper.Destroy(slice.GameObject)
        return
    end
    pool:ReturnItemToPool(slice)
end

function XUiDyeMergeGameGridPools:_InitExtendSlicePool(prefab)
    local cls = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/Part/XUiGridDyeMergeExtendPart")
    local pool = XPool.New(function()
        local go = XUiHelper.Instantiate(prefab, prefab.transform.parent)
        local slice = cls.New(go, self)
        return slice
    end, self._GridRecycleHandler, false)

    self._Name2Pools[EXTEND_SLICE_POOL_NAME] = pool
end

--endregion

--region GridCircle 对象池

---@return XUiGridDyeMergeCircle
function XUiDyeMergeGameGridPools:GetCircle()
    local pool = self._Name2Pools[CIRCLE_POOL_NAME]
    if not pool then
        local prefab = self.PrefabsGetter:GetPrefabByName(CIRCLE_POOL_NAME)
        if not prefab then return end
        self:_InitCirclePool(prefab)
        pool = self._Name2Pools[CIRCLE_POOL_NAME]
    end

    local circle = pool:GetItemFromPool()
    circle.Transform:SetParent(self.PanelBoard.transform)
    return circle
end

---@param circle XUiGridDyeMergeCircle
function XUiDyeMergeGameGridPools:ReturnCircle(circle)
    local pool = self._Name2Pools[CIRCLE_POOL_NAME]
    if not pool then
        self:RemoveChildNode(circle)
        XUiHelper.Destroy(circle.GameObject)
        return
    end
    pool:ReturnItemToPool(circle)
end

function XUiDyeMergeGameGridPools:_InitCirclePool(prefab)
    local cls = require(CIRCLE_CLS_PATH)
    local pool = XPool.New(function()
        local go = XUiHelper.Instantiate(prefab, prefab.transform.parent)
        local circle = cls.New(go, self)
        return circle
    end, self._GridRecycleHandler, false)

    self._Name2Pools[CIRCLE_POOL_NAME] = pool
end

--endregion

--region 射线端点查询服务

--- 获取目标方块入射方向对应 pos 节点的 Board 空间偏移
--- 用于射线终点定位，解耦发出方与目标方之间的直接引用
---@param uid number 目标方块 uid
---@param dirIndex number 射线行进方向（1=上 2=右 3=下 4=左）
---@return number|nil, number|nil offsetX, offsetY（Board 空间），无节点时返回 nil
function XUiDyeMergeGameGridPools:GetBlockEntryOffset(uid, dirIndex)
    local grid = self.Parent._Uid2GridDict[uid]
    if not grid then return nil end
    local posIndex = DirToEntryPosIndex[dirIndex]
    if not posIndex then return nil end
    local node = grid:GetPosNode(posIndex)
    if not node then return nil end
    local scaleX, scaleY = grid.Transform:GetLocalScale()
    local px, py = node:GetLocalPosition()
    return px * scaleX, py * scaleY
end

--endregion

return XUiDyeMergeGameGridPools