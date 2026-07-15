--- 局内控制器——负责方块实体管理
---@class XDyeMergeBlocksControl : XControl
---@field _MainControl XDyeMergeGamingControl
---@field private _Model XDyeMergeGameModel
local XDyeMergeBlocksControl = XClass(XControl, "XDyeMergeBlocksControl")

-- 方向索引 → 坐标增量，顺序与 TurnableMultyColor 的 Params 一致：1=上 2=右 3=下 4=左
local DirDelta = {
    [1] = { dx = 0,  dy = -1 },
    [2] = { dx = 1,  dy = 0  },
    [3] = { dx = 0,  dy = 1  },
    [4] = { dx = -1, dy = 0  },
}

-- Mirror 双面镜折射表：MirrorReflectMap[mirrorRotateIndex][入射方向索引] = 出射方向索引
-- RotateIndex 0,2 = "\" 形：1↔4, 2↔3
-- RotateIndex 1,3 = "/" 形：1↔2, 3↔4
local MirrorReflectMap = {
    [0] = { [1] = 4, [2] = 3, [3] = 2, [4] = 1 },
    [1] = { [1] = 2, [2] = 1, [3] = 4, [4] = 3 },
    [2] = { [1] = 4, [2] = 3, [3] = 2, [4] = 1 },
    [3] = { [1] = 2, [2] = 1, [3] = 4, [4] = 3 },
}

-- 单条射线最大步数，防止 Mirror 互射形成死循环
local MaxStepPerDir = 200

function XDyeMergeBlocksControl:OnInit()
    ---@type XPool
    self._BlockPool = XPool.New(function()
        local block = require("XModule/XDyeMergeGame/SubModules/InGame/Entity/XDyeMergeBlock").New()
        return block
    end, function(block)
        block:Reset()
    end)

    ---@type XDyeMergeBlock[]
    self._UsingBlockList = {}
    ---@type table<number, XDyeMergeBlock>
    self._Pos2BlockMap = {}
    ---@type table<number, XDyeMergeBlock>
    self._Uid2BlockMap = {}
    
    self._NewUidCounter = 1
    
    self._GetBlockInfluenceHandlers = {
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.Normal] = handler(self, self._GetNormalBlockInfluences),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.Target] = handler(self, self._GetNormalBlockInfluences),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.ColorChangeable] = handler(self, self._GetColorChangeableBlockInfluences),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.TurnableMultyColor] = handler(self, self._GetTurnableMultyColorBlockInfluences),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.Mirror] = handler(self, self._GetMirrorBlockInfluences),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.VariableLength] = handler(self, self._GetVariableLengthBlockInfluences),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.ShowOnly] = handler(self, self._GetNormalBlockInfluences),
    }

    self._InitBlockByTypeHandlers = {
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.ColorChangeable] = handler(self, self._InitColorChangeableBlock),
        [XMVCA.XDyeMergeGame.EnumConst.BlockType.VariableLength]  = handler(self, self._InitVariableLengthBlock),
    }

    -- 复用表：避免 RefreshTurnableRayInfluences 阶段2每次创建临时表产生 GC 压力
    self._RayWorkList      = {}
    self._RayWorkDirList   = {}
    self._RayWorkColorList = {}

    -- 复用表：避免 _GetRotatedColorDirOf 每次调用创建临时表
    self._ColorDirWork        = { 0, 0, 0, 0 }
    self._ColorDirRotatedWork = { 0, 0, 0, 0 }

    -- 复用表：避免 UpdateTargetReceivedColors 每个 Target 创建临时表
    self._ReceivedColorsWork = {} -- 纯色列表 {colorId, ...}，传给 GetMixedColorByFromColors 做合成判定
    self._DirColorsWork      = {} -- 方向→颜色映射 {[adjDir]=colorId, ...}，写入 block:SetReceivedDirColors 供表现层读取
    self._DeduplicateSeenWork = {} -- 去重辅助：已见颜色集合
end

function XDyeMergeBlocksControl:AddAgencyEvent()

end

function XDyeMergeBlocksControl:RemoveAgencyEvent()

end

function XDyeMergeBlocksControl:OnRelease()

end

function XDyeMergeBlocksControl:_GetNewUid()
    local uid = self._NewUidCounter
    
    self._NewUidCounter = self._NewUidCounter + 1
    
    return uid
end

function XDyeMergeBlocksControl:ResetData()
    self._NewUidCounter = 1

    if not XTool.IsTableEmpty(self._UsingBlockList) then
        for i, v in pairs(self._UsingBlockList) do
            self._BlockPool:ReturnItemToPool(v)
        end

        self._UsingBlockList = {}
        self._Pos2BlockMap = {}
        self._Uid2BlockMap = {}
    end
end

--- 以新增的方式添加一个指定方块到棋盘中
--- 该接口不进行位置边界检测，位置边界检测由父Control向地图Control确认
---@return boolean, number|nil 是否添加成功, 成功时的方块 uid
function XDyeMergeBlocksControl:AddNewBlock(id, posX, posY)
    if not XTool.IsNumberValidEx(id) then
        XLog.Error("[DyeMerge]往棋盘添加无效id的方块：" .. tostring(id))
        return false, nil
    end

    local cfg = self._MainControl:GetTableDyeMergeBlockById(id)

    if not cfg then
        return false, nil
    end

    local index = self._MainControl:Vec2ToIndex(posX, posY)

    if self._Pos2BlockMap[index] then
        XLog.Error("[DyeMerge]棋盘位置<" .. tostring(posX) .. ', ' ..tostring(posY) .. '> 已有方块，请勿重复添加')
        return false, nil
    end
    
    ---@type XDyeMergeBlock
    local block = self._BlockPool:GetItemFromPool()
    local uid = self:_GetNewUid()
    
    block:Init(id, uid, cfg.Type, cfg.InitRotateIndex, cfg.CanMove)
    block:SetCenter(posX, posY)

    local initHandler = self._InitBlockByTypeHandlers[cfg.Type]
    if initHandler then
        initHandler(block, cfg)
    end

    self._Pos2BlockMap[index] = block
    self._Uid2BlockMap[uid] = block
    
    table.insert(self._UsingBlockList, block)
    
    return true, uid
end

---@param block XDyeMergeBlock
---@param cfg table
function XDyeMergeBlocksControl:_InitColorChangeableBlock(block, cfg)
    block:SetChangeableColorIndex(cfg.Color)
end

---@param block XDyeMergeBlock
---@param cfg table
function XDyeMergeBlocksControl:_InitVariableLengthBlock(block, cfg)
    local initLen = cfg.Params[XMVCA.XDyeMergeGame.EnumConst.BlockCfgParams.VariableLength.InitLen]
    local maxLen  = cfg.Params[XMVCA.XDyeMergeGame.EnumConst.BlockCfgParams.VariableLength.MaxLen]
    local isExpand = initLen < maxLen
    block:SetVariableLength(initLen, isExpand)
end

--- 将方块从位置注册表中注销，但保留方块自身的坐标数据不变
--- 调用后该格子在 Pos2BlockMap 中变为空，其他方块可以安全 Attach 到此位置
--- 通常作为 AttachBlockToPos 的前置操作，成对使用（DetachBlockFromPos → AttachBlockToPos）
---@param uid number 目标方块的运行时唯一ID
function XDyeMergeBlocksControl:DetachBlockFromPos(uid)
    local block = self:GetBlockByUid(uid)

    if not block then
        return
    end

    local oldIndex = self._MainControl:Vec2ToIndex(block:GetX(), block:GetY())
    self._Pos2BlockMap[oldIndex] = nil
end

--- 将方块绑定到指定新坐标，同步更新方块自身坐标及位置注册表
--- 调用前必须确保目标位置已通过 DetachBlockFromPos 腾空，否则会产生占位冲突
---@param uid number 目标方块的运行时唯一ID
---@param newPosX number 目标格的 X 坐标
---@param newPosY number 目标格的 Y 坐标
function XDyeMergeBlocksControl:AttachBlockToPos(uid, newPosX, newPosY)
    local block = self:GetBlockByUid(uid)

    if not block then
        return
    end

    local newIndex = self._MainControl:Vec2ToIndex(newPosX, newPosY)

    if self._Pos2BlockMap[newIndex] then
        XLog.Error("[DyeMerge]AttachBlockToPos：目标位置<" .. tostring(newPosX) .. ", " .. tostring(newPosY) .. ">已有方块占用，请先执行 DetachBlockFromPos")
        return
    end

    block:SetCenter(newPosX, newPosY)
    self._Pos2BlockMap[newIndex] = block
end

--- 获取所有方块，主要是提供给表现层刷新显示
---@return XDyeMergeBlock[]
function XDyeMergeBlocksControl:GetUsingBlockList()
    return self._UsingBlockList
end

---@return XDyeMergeBlock
function XDyeMergeBlocksControl:GetBlockByUid(uid)
    local block = self._Uid2BlockMap[uid]

    if not block then
        XLog.Error("[DyeMerge]指定方块不存在，uid：" .. tostring(uid))
    end
    
    return block
end

function XDyeMergeBlocksControl:GetBlockByPosIndex(posIndex)
    local block = self._Pos2BlockMap[posIndex]

    if not block then
        XLog.Error("[DyeMerge]指定方块不存在，posIndex：" .. tostring(posIndex))
    end

    return block
end

function XDyeMergeBlocksControl:GetBlockIsExsistByPosIndex(posIndex)
    local block = self._Pos2BlockMap[posIndex]

    return block ~= nil
end

--- 判断指定位置是否存在不可移动方块
---@param posIndex number Vec2ToIndex 编码后的坐标
---@return boolean
function XDyeMergeBlocksControl:CheckIsImmovableBlockAtPos(posIndex)
    local block = self._Pos2BlockMap[posIndex]
    return block ~= nil and not block:GetCanMove()
end

--region 获取各方块类型的影响范围

function XDyeMergeBlocksControl:GetBlockInfluenceCells(uid, mapList, in_list, in_dirList, in_colorList)
    in_list = in_list or {}
    in_dirList = in_dirList or {}
    in_colorList = in_colorList or {}

    local block = self._Uid2BlockMap[uid]

    if not block then
        XLog.Error("[DyeMerge]指定uid的方块不存在， uid: " .. tostring(uid))
        return in_list, in_dirList, in_colorList
    end

    local blockType = block:GetType()

    -- 获取func和传参
    local func = self._GetBlockInfluenceHandlers[blockType]

    if not func then
        XLog.Error("[DyeMerge]指定方块类型的方法未注册，blockType: " .. tostring(blockType))
        return in_list, in_dirList, in_colorList
    end

    return func(block, mapList, in_list, in_dirList, in_colorList)
end

---@param block XDyeMergeBlock
function XDyeMergeBlocksControl:_GetNormalBlockInfluences(block, mapList, in_list, in_dirList, in_colorList)
    in_list[1] = self._MainControl:Vec2ToIndex(block:GetX(), block:GetY())
    in_dirList[1] = nil
    in_colorList[1] = nil

    return in_list, in_dirList, in_colorList
end

---@param block XDyeMergeBlock
function XDyeMergeBlocksControl:_GetColorChangeableBlockInfluences(block, mapList, in_list, in_dirList, in_colorList)
    in_list[1] = self._MainControl:Vec2ToIndex(block:GetX(), block:GetY())
    in_dirList[1] = nil
    in_colorList[1] = nil

    return in_list, in_dirList, in_colorList
end

---@param block XDyeMergeBlock
function XDyeMergeBlocksControl:_GetTurnableMultyColorBlockInfluences(block, mapList, in_list, in_dirList, in_colorList)
    in_list[1] = self._MainControl:Vec2ToIndex(block:GetX(), block:GetY())
    in_dirList[1] = nil  -- 本体格：物理占位，无行进方向
    in_colorList[1] = nil  -- 本体格：无射线颜色

    -- 获取应用旋转后的四方向颜色表
    local colorDir = self:_GetRotatedColorDirOf(block)

    if not colorDir or next(colorDir) == nil then
        return in_list, in_dirList, in_colorList
    end

    -- 依次对各个方向进行延伸
    local listIdx = 2

    for dirIndex, color in pairs(colorDir) do
        -- 1. 该方向无颜色则跳过，不发射射线
        if color ~= 0 then
            local curDirIndex = dirIndex
            local delta = DirDelta[curDirIndex]
            local dx, dy = delta.dx, delta.dy
            local x, y = block:GetX(), block:GetY()

            for _ = 1, MaxStepPerDir do
                x = x + dx
                y = y + dy

                if not self._MainControl.MapControl:CheckPosInMapIsValid(x, y) then
                    break
                end

                local stepResult, newDirIndex
                stepResult, newDirIndex, listIdx = self:_TraceRayStep(x, y, curDirIndex, color, mapList, in_list, in_dirList, in_colorList, listIdx)

                if stepResult == "blocked" then
                    break
                elseif stepResult == "reflected" then
                    curDirIndex = newDirIndex
                    local newDelta = DirDelta[curDirIndex]
                    dx, dy = newDelta.dx, newDelta.dy
                end
                -- "extended" 直接继续循环
            end
        end
    end

    return in_list, in_dirList, in_colorList
end

--- 射线单步步进，返回本步的处理结果
--- 返回值1 (stepResult)：
---   "blocked"   = 射线被阻断（物理阻挡或不支持的 Mirror 入射），调用方应 break
---   "reflected" = 命中 Mirror 并折射，调用方继续循环（方向已更新）
---   "extended"  = 落入无物理方块的格子，已写入 in_list/in_dirList/in_colorList，调用方继续循环
--- 返回值2 (newDirIndex)：折射后的新方向（仅 stepResult=="reflected" 时有效）
---@param x number 当前步进到的格子 X 坐标
---@param y number 当前步进到的格子 Y 坐标
---@param curDirIndex number 当前射线行进方向
---@param color number 当前射线携带的颜色
---@param mapList table 当前地图快照
---@param in_list table 影响格列表（out 参数）
---@param in_dirList table 方向列表（out 参数）
---@param in_colorList table 颜色列表（out 参数）
---@param listIdx number 当前写入索引
---@return string stepResult
---@return number|nil newDirIndex
---@return number listIdx 更新后的写入索引
function XDyeMergeBlocksControl:_TraceRayStep(x, y, curDirIndex, color, mapList, in_list, in_dirList, in_colorList, listIdx)
    local index = self._MainControl:Vec2ToIndex(x, y)
    local occupyUid = mapList[index]

    if XTool.IsNumberValidEx(occupyUid) then
        local occupyBlock = self._Uid2BlockMap[occupyUid]

        if occupyBlock and occupyBlock:GetType() == XMVCA.XDyeMergeGame.EnumConst.BlockType.Mirror then
            -- 是 Mirror：查询该 Mirror 对当前入射方向的折射输出方向
            local reflectMap = MirrorReflectMap[occupyBlock:GetRotateIndex()]
            local newDirIndex = reflectMap and reflectMap[curDirIndex]

            if not newDirIndex then
                -- 入射角度不被此 Mirror 支持，阻断射线
                return "blocked", nil, listIdx
            end

            -- Mirror 格写入折射后的出射方向和颜色，供相邻 Target 采样
            in_list[listIdx] = index
            in_dirList[listIdx] = newDirIndex
            in_colorList[listIdx] = color
            return "reflected", newDirIndex, listIdx + 1

        else
            -- 物理阻挡（含 TurnableMultyColor 本体）
            return "blocked", nil, listIdx
        end
    else
        -- 无物理方块，射线延伸（不同方向射线可共存于同格）
        in_list[listIdx] = index
        in_dirList[listIdx] = curDirIndex
        in_colorList[listIdx] = color  -- 折射不改变颜色，color 始终是外层循环的原始颜色
        return "extended", nil, listIdx + 1
    end
end

---@param block XDyeMergeBlock
function XDyeMergeBlocksControl:_GetMirrorBlockInfluences(block, mapList, in_list, in_dirList, in_colorList)
    in_list[1] = self._MainControl:Vec2ToIndex(block:GetX(), block:GetY())
    in_dirList[1] = nil
    in_colorList[1] = nil

    return in_list, in_dirList, in_colorList
end

---@param block XDyeMergeBlock
function XDyeMergeBlocksControl:_GetVariableLengthBlockInfluences(block, mapList, in_list, in_dirList, in_colorList)
    -- 中心格始终占位
    in_list[1] = self._MainControl:Vec2ToIndex(block:GetX(), block:GetY())
    in_dirList[1] = nil
    in_colorList[1] = nil

    local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
    if not cfg then
        return in_list, in_dirList, in_colorList
    end

    -- 获取应用了旋转角度的最终延伸方向
    local expandDir = self:GetFinalExpandDirection(block:GetUid())

    -- 计算单侧延伸格数
    --    长度始终为奇数，单侧格数 = (当前长度 - 1) / 2
    local curLen = block:GetVariableLength()
    local extendCount = (curLen - 1) / 2

    if extendCount <= 0 then
        return in_list, in_dirList, in_colorList
    end

    -- 4. 从中心向两侧逐格添加到 in_list（VariableLength 为物理延伸，无射线方向和颜色）
    local cx, cy = block:GetX(), block:GetY()
    local listIdx = 2

    if expandDir == XMVCA.XDyeMergeGame.EnumConst.VariableLengthBlockExpandType.Horizontal then
        -- 水平延伸：向左（x-）和向右（x+）各延伸 extendCount 格
        for i = 1, extendCount do
            local lx, rx = cx - i, cx + i
            -- 逐侧独立校验，越界的跳过，有效的正常记录
            if self._MainControl.MapControl:CheckPosInMapIsValid(lx, cy) then
                in_list[listIdx] = self._MainControl:Vec2ToIndex(lx, cy)
                in_dirList[listIdx] = nil
                in_colorList[listIdx] = nil
                listIdx = listIdx + 1
            end
            if self._MainControl.MapControl:CheckPosInMapIsValid(rx, cy) then
                in_list[listIdx] = self._MainControl:Vec2ToIndex(rx, cy)
                in_dirList[listIdx] = nil
                in_colorList[listIdx] = nil
                listIdx = listIdx + 1
            end
        end
    else
        -- 垂直延伸：向上（y-）和向下（y+）各延伸 extendCount 格
        for i = 1, extendCount do
            local uy, dy = cy - i, cy + i
            -- 逐侧独立校验，越界的跳过，有效的正常记录
            if self._MainControl.MapControl:CheckPosInMapIsValid(cx, uy) then
                in_list[listIdx] = self._MainControl:Vec2ToIndex(cx, uy)
                in_dirList[listIdx] = nil
                in_colorList[listIdx] = nil
                listIdx = listIdx + 1
            end
            if self._MainControl.MapControl:CheckPosInMapIsValid(cx, dy) then
                in_list[listIdx] = self._MainControl:Vec2ToIndex(cx, dy)
                in_dirList[listIdx] = nil
                in_colorList[listIdx] = nil
                listIdx = listIdx + 1
            end
        end
    end

    return in_list, in_dirList, in_colorList
end
--endregion

--region VariableLength 方向接口

--- 获取延伸块应用旋转后的最终延伸方向
--- 90°/270° 时水平与垂直互换；0°/180° 保持配置原值
---@param uid number
---@return number VariableLengthBlockExpandType（1=Horizontal / 2=Vertical）
function XDyeMergeBlocksControl:GetFinalExpandDirection(uid)
    local block = self:GetBlockByUid(uid)
    if not block then return XMVCA.XDyeMergeGame.EnumConst.VariableLengthBlockExpandType.Horizontal end
    local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
    if not cfg then return XMVCA.XDyeMergeGame.EnumConst.VariableLengthBlockExpandType.Horizontal end

    local EC = XMVCA.XDyeMergeGame.EnumConst
    local expandDir = cfg.Params[EC.BlockCfgParams.VariableLength.ExpandDir]
    local rotateIndex = block:GetRotateIndex()
    if rotateIndex % 2 == 1 then
        if expandDir == EC.VariableLengthBlockExpandType.Horizontal then
            expandDir = EC.VariableLengthBlockExpandType.Vertical
        else
            expandDir = EC.VariableLengthBlockExpandType.Horizontal
        end
    end
    return expandDir
end

--- 判断延伸块的最终延伸方向是否为竖直
---@param uid number
---@return boolean
function XDyeMergeBlocksControl:IsVerticalExtend(uid)
    return self:GetFinalExpandDirection(uid) == XMVCA.XDyeMergeGame.EnumConst.VariableLengthBlockExpandType.Vertical
end

--endregion

--region 旋转色块查询接口

--- 获取 TurnableMultyColor 方块应用旋转后的四方向颜色表（公开包装）
--- 返回内部复用表引用，索引 1~4 对应上/右/下/左方向的颜色 Id
--- 注意：返回的是共享引用，调用方必须即用即弃，不可跨调用保存
---@param uid number
---@return table|nil
function XDyeMergeBlocksControl:GetRotatedColorDir(uid)
    local block = self:GetBlockByUid(uid)
    if not block then return nil end
    return self:_GetRotatedColorDirOf(block)
end

--- 判断 TurnableMultyColor 方块是否为多色型
--- 多色 = Params[1~4] 中存在不同颜色值；单色 = Params[1~4] 全部相同
---@param uid number
---@return boolean
function XDyeMergeBlocksControl:IsMultiColorBlock(uid)
    local block = self:GetBlockByUid(uid)
    
    if not block then
        return false 
    end
    
    local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
    
    if not cfg then
        return false 
    end
    
    for i = 2, 4 do
        if XTool.IsNumberValidEx(cfg.Params[i]) and cfg.Params[i] ~= cfg.Params[1] then 
            return true
        end
    end
    
    return false
end

--endregion

--region UpdateBlocksState 核心逻辑

--- 刷新全部 TurnableMultyColor 射线的影响占位
--- 必须先批量移除再逐块写入，保证各射线计算时看到的是干净的物理方块基准
function XDyeMergeBlocksControl:RefreshTurnableRayInfluences(mapList)
    local BlockType = XMVCA.XDyeMergeGame.EnumConst.BlockType

    -- 阶段1：批量移除所有射线延伸格，保留本体格，还原干净 MapList
    -- 注意：必须使用 RemoveRayExtensionInfluences 而非 RemoveBlockInfluences，
    -- 否则本体格被清空后可能被后续射线抢占，导致 AddBlockInfluence 静默跳过，本体永久丢失占位
    for _, block in pairs(self._UsingBlockList) do
        if block:GetType() == BlockType.TurnableMultyColor then
            self._MainControl.MapControl:RemoveRayExtensionInfluences(block:GetUid())
        end
    end

    -- 阶段2：逐块计算并写入（不同方向射线可共存于同格，无先到先占问题）
    for _, block in pairs(self._UsingBlockList) do
        if block:GetType() == BlockType.TurnableMultyColor then
            local uid = block:GetUid()

            -- 清空复用表
            for i = #self._RayWorkList, 1, -1 do
                self._RayWorkList[i]      = nil
                self._RayWorkDirList[i]   = nil
                self._RayWorkColorList[i] = nil
            end

            self:GetBlockInfluenceCells(uid, mapList, self._RayWorkList, self._RayWorkDirList, self._RayWorkColorList)
            for i, posIndex in pairs(self._RayWorkList) do
                self._MainControl.MapControl:AddBlockInfluence(uid, posIndex, self._RayWorkDirList[i], self._RayWorkColorList[i])
            end
        end
    end
end

--- 遍历所有 Target 方块，采样四邻格颜色，查混色表后写入 _ReceivedColor
--- 查不到匹配项则保持原值不变
function XDyeMergeBlocksControl:UpdateTargetReceivedColors(mapList)
    local BlockType = XMVCA.XDyeMergeGame.EnumConst.BlockType
    -- 邻格方向D（1=上2=右3=下4=左）→ 射线进入 Target 的入射方向（反向）
    local IncomingDir = { [1] = 3, [2] = 4, [3] = 1, [4] = 2 }

    for _, block in pairs(self._UsingBlockList) do
        if block:GetType() == BlockType.Target then
            -- 读取该 Target 方块的目标颜色
            local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
            local targetColor = cfg and cfg.Color

            if not targetColor or targetColor < 0 then
                XLog.Error("[DyeMerge] Target 配置的 Color 字段无效，blockId=" .. tostring(block:GetId()) .. " color=" .. tostring(targetColor))
                goto continueTarget
            end

            do
                local cx, cy = block:GetX(), block:GetY()
                local receivedColors = self._ReceivedColorsWork
                local dirColors = self._DirColorsWork
                -- 清空复用表
                for i = #receivedColors, 1, -1 do receivedColors[i] = nil end
                for k in pairs(dirColors) do dirColors[k] = nil end

                for adjDir = 1, 4 do
                    local nx = cx + DirDelta[adjDir].dx
                    local ny = cy + DirDelta[adjDir].dy

                    if self._MainControl.MapControl:CheckPosInMapIsValid(nx, ny) then
                        local adjIndex = self._MainControl:Vec2ToIndex(nx, ny)
                        local uid = mapList[adjIndex]

                        if XTool.IsNumberValidEx(uid) then
                            -- 邻格有物理方块
                            local adjBlock = self._Uid2BlockMap[uid]
                            local color = self:_GetBlockEmittedColor(adjBlock, IncomingDir[adjDir])
                            if color ~= 0 then
                                table.insert(receivedColors, color)
                                dirColors[adjDir] = color
                            elseif adjBlock and adjBlock:GetType() == BlockType.Mirror then
                                -- Mirror 不发色，但可能有穿过此格的折射射线
                                local rayUid, rayColor = self._MainControl.MapControl:GetRayInfoByDir(adjIndex, IncomingDir[adjDir])
                                if rayUid and rayColor and rayColor ~= 0 then
                                    table.insert(receivedColors, rayColor)
                                    dirColors[adjDir] = rayColor
                                end
                            end
                        else
                            -- 邻格无物理方块，检查是否有朝向 Target 的射线（按方向查询）
                            local rayUid, rayColor = self._MainControl.MapControl:GetRayInfoByDir(adjIndex, IncomingDir[adjDir])
                            if rayUid and rayColor and rayColor ~= 0 then
                                table.insert(receivedColors, rayColor)
                                dirColors[adjDir] = rayColor
                            end
                        end
                    end
                end

                -- 去重：多个方向射入相同颜色视为 1 个
                self:_DeduplicateColors(receivedColors)

                -- 直达：去重后仅 1 色且等于目标色，无需查表
                local finalColor
                if #receivedColors == 1 and receivedColors[1] == targetColor then
                    finalColor = targetColor
                else
                    finalColor = self._MainControl:GetMixedColorByFromColors(receivedColors, targetColor)
                end
                block:SetReceivedColor(finalColor)
                block:SetReceivedDirColors(dirColors)
            end
            ::continueTarget::
        end
    end
end

--- 原地去重：移除 colors 中重复的 colorId，保留首次出现的顺序
---@param colors number[] 将被原地修改
function XDyeMergeBlocksControl:_DeduplicateColors(colors)
    local seen = self._DeduplicateSeenWork
    for k in pairs(seen) do seen[k] = nil end

    local writeIdx = 0
    for i = 1, #colors do
        local v = colors[i]
        if not seen[v] then
            seen[v] = true
            writeIdx = writeIdx + 1
            colors[writeIdx] = v
        end
    end
    for i = #colors, writeIdx + 1, -1 do
        colors[i] = nil
    end
end

--- 查询某方块朝指定入射方向发出的颜色
--- incomingDir：射线进入 Target 的方向（与邻格相对 Target 的方向相反）
---@param block XDyeMergeBlock
---@param incomingDir number 1=上 2=右 3=下 4=左
---@return number colorId，0 表示不发色
function XDyeMergeBlocksControl:_GetBlockEmittedColor(block, incomingDir)
    if not block then return 0 end
    local blockType = block:GetType()
    local BlockType = XMVCA.XDyeMergeGame.EnumConst.BlockType

    if blockType == BlockType.ColorChangeable then
        return block:GetChangeableColorIndex() or 0

    elseif blockType == BlockType.TurnableMultyColor then
        local colorDir = self:_GetRotatedColorDirOf(block)
        return colorDir and colorDir[incomingDir] or 0

    elseif blockType == BlockType.Normal or blockType == BlockType.VariableLength then
        local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
        return (cfg and cfg.Color) or 0

    else
        return 0
    end
end

--- 返回 TurnableMultyColor 应用当前旋转后的四方向颜色表（索引1~4对应上右下左）
--- 与 _GetTurnableMultyColorBlockInfluences 中的旋转逻辑共享，避免重复
--- 注意：返回的是内部复用表引用，调用方必须即用即弃，不可跨调用保存
---@param block XDyeMergeBlock
---@return table|nil colorDir
function XDyeMergeBlocksControl:_GetRotatedColorDirOf(block)
    local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
    if not cfg then return nil end

    local colorDir = self._ColorDirWork
    local allSameColor = true

    for i = 1, 4 do
        colorDir[i] = cfg.Params[i] or 0
        if i > 1 and cfg.Params[i] ~= cfg.Params[i - 1] then
            allSameColor = false
        end
    end

    local rotateIndex = block:GetRotateIndex()
    if rotateIndex ~= XMVCA.XDyeMergeGame.EnumConst.RotateIndex.Zero and not allSameColor then
        local rotated = self._ColorDirRotatedWork
        for i = 1, 4 do
            local newIdx = (i - 1 + rotateIndex) % 4 + 1
            rotated[newIdx] = colorDir[i]
        end
        return rotated
    end

    return colorDir
end

--endregion

--region 通关判断

--- 检查所有 Target 方块是否已被正确颜色覆盖
---@return boolean
function XDyeMergeBlocksControl:CheckIsAllTargetSatisfied()
    local BlockType = XMVCA.XDyeMergeGame.EnumConst.BlockType

    for _, block in pairs(self._UsingBlockList) do
        if block:GetType() == BlockType.Target then
            local cfg = self._MainControl:GetTableDyeMergeBlockById(block:GetId())
            local targetColor = cfg and cfg.Color

            if targetColor == 0 then
                -- Color=0：接受任意有效颜色
                if not XTool.IsNumberValidEx(block:GetReceivedColor()) then
                    return false
                end
            else
                if not XTool.IsNumberValidEx(targetColor) then
                    -- 配置异常的 Target 视为未满足
                    return false
                end

                if block:GetReceivedColor() ~= targetColor then
                    return false
                end
            end
        end
    end

    return true
end

--endregion

return XDyeMergeBlocksControl