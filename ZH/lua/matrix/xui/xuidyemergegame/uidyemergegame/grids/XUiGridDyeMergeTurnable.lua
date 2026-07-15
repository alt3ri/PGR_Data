local XUiGridDyeMerge = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Grids/XUiGridDyeMerge")

-- 方向索引 → 坐标增量：1=上 2=右 3=下 4=左
local DirDelta = {
    [1] = { dx = 0,  dy = -1 },
    [2] = { dx = 1,  dy = 0  },
    [3] = { dx = 0,  dy = 1  },
    [4] = { dx = -1, dy = 0  },
}

-- Mirror 双面镜折射表：[旋转索引][入射方向] = 出射方向
-- RotateIndex 0,2 = "\" 形：1↔4, 2↔3
-- RotateIndex 1,3 = "/" 形：1↔2, 3↔4
local MirrorReflectMap = {
    [0] = { [1] = 4, [2] = 3, [3] = 2, [4] = 1 },
    [1] = { [1] = 2, [2] = 1, [3] = 4, [4] = 3 },
    [2] = { [1] = 4, [2] = 3, [3] = 2, [4] = 1 },
    [3] = { [1] = 2, [2] = 1, [3] = 4, [4] = 3 },
}

-- 逻辑方向 → 自身出射 pos 节点字段名（射线从本方块该边缘离开）
-- pos1=右上, pos2=左上, pos3=左下, pos4=右下
local DirToExitPosKey = {
    [1] = "Pos4",  -- 逻辑上→screen右下→pos4
    [2] = "Pos1",  -- 逻辑右→screen右上→pos1
    [3] = "Pos2",  -- 逻辑下→screen左上→pos2
    [4] = "Pos3",  -- 逻辑左→screen左下→pos3
}

-- 方向 → 反方向（将出射方向转为 GetBlockEntryOffset 入射查询方向）
local OppositeDir = { [1] = 3, [2] = 4, [3] = 1, [4] = 2 }

--- 可旋转色块
---@class XUiGridDyeMergeTurnable: XUiGridDyeMerge
---@field protected _Control XDyeMergeGameControl
---@field Parent
---@field RImgArrow
---@field BtnRotate
--- 单色时用到的UI，需要注意判空
---@field RImgYuan
---@field RImgObject @单色供色图标（IconSupprtTop）
---@field SpineFlower @单色骨骼动画节点（通过 RImgObjectSpine 控制，无需直接引用）
--- 多色时用到的UI，需要注意判空
---@field RImgYuan1 @对应未旋转时的左上
---@field RImgYuan2 @对应未旋转时的右上
---@field RImgYuan3 @对应未旋转时的左下
---@field RImgYuan4 @对应未旋转时的右下
---@field RImgObject1 @对应未旋转时的左上
---@field RImgObject2 @对应未旋转时的右上
---@field RImgObject3 @对应未旋转时的左下
---@field RImgObject4 @对应未旋转时的右下
---@field RImgWallRight @对应未旋转时右下的立面
---@field RImgWallLeft @对应未旋转时左下的立面
local XUiGridDyeMergeTurnable = XClass(XUiGridDyeMerge, "XUiGridDyeMergeTurnable")

function XUiGridDyeMergeTurnable:OnStart()
    XUiGridDyeMerge.OnStart(self)
    if self.BtnRotate then
        self.BtnRotate:AddEventListener(handler(self, self._OnBtnRotateClick))
    end
    -- 逻辑方向索引（1=上 2=右 3=下 4=左）→ 等距屏幕位置的预制节点映射
    -- 逻辑层 Y 轴与等距投影 Y 轴方向相反，映射关系：
    --   逻辑1(上)→screen右下→预制4  逻辑2(右)→screen右上→预制2
    --   逻辑3(下)→screen左上→预制1  逻辑4(左)→screen左下→预制3
    self._ColorNodes = {
        [1] = { yuan = self.RImgYuan4, object = self.RImgObject4, objectEnd = self.RImgObjectEnd4, wall = self.RImgWallRight },  -- 逻辑上→screen右下
        [2] = { yuan = self.RImgYuan2, object = self.RImgObject2, objectEnd = self.RImgObjectEnd2 },  -- 逻辑右→screen右上
        [3] = { yuan = self.RImgYuan1, object = self.RImgObject1, objectEnd = self.RImgObjectEnd1 },  -- 逻辑下→screen左上
        [4] = { yuan = self.RImgYuan3, object = self.RImgObject3, objectEnd = self.RImgObjectEnd3, wall = self.RImgWallLeft },  -- 逻辑左→screen左下
    }
    -- 线条节点管理（通过 GridPools 获取/回收）
    self._LineNodes = {}
    self._IsLineAnimating = false
end

---@overload
function XUiGridDyeMergeTurnable:Refresh(uid, skipLinesRefresh)
    self.Uid = uid
    self:EnterEmptyDisplay()

    local blocksControl = self._Control.GamingControl.BlocksControl
    local block = blocksControl:GetBlockByUid(uid)
    if not block then return end
    local blockCfg = self._Control.GamingControl:GetTableDyeMergeBlockById(block:GetId())
    if not blockCfg then return end

    local colorDir = blocksControl:GetRotatedColorDir(uid)
    if not colorDir or next(colorDir) == nil then return end

    if blocksControl:IsMultiColorBlock(uid) then
        -- 隐藏单色节点（花/通关花已由 EnterEmptyDisplay 处理）
        if self.RImgYuan then self.RImgYuan.gameObject:SetActiveEx(false) end
        -- 按方向刷新四组多色节点
        for i = 1, 4 do
            local nodes = self._ColorNodes[i]
            
            local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(colorDir[i], true)
            
            local hasColor = colorCfg ~= nil
            if nodes.yuan   then
                nodes.yuan.gameObject:SetActiveEx(hasColor)
                
                if hasColor then 
                    nodes.yuan:SetRawImage(colorCfg.IconSector) 
                end
            end
            
            if nodes.object then
                nodes.object.gameObject:SetActiveEx(hasColor)

                if hasColor then
                    nodes.object:SetRawImage(colorCfg.IconSupprtTop)
                end
            end

            if nodes.objectEnd then
                nodes.objectEnd.gameObject:SetActiveEx(false)
            end

            if nodes.wall then
                nodes.wall.gameObject:SetActiveEx(hasColor)

                if hasColor then
                    nodes.wall:SetRawImage(colorCfg.IconSectorWall)
                end
            end
        end
    else
        -- 隐藏多色节点
        for i = 1, 4 do
            local nodes = self._ColorNodes[i]
            if nodes.yuan   then 
                nodes.yuan.gameObject:SetActiveEx(false) 
            end
            
            if nodes.object then
                nodes.object.gameObject:SetActiveEx(false)
            end

            if nodes.objectEnd then
                nodes.objectEnd.gameObject:SetActiveEx(false)
            end

            if nodes.wall then
                nodes.wall.gameObject:SetActiveEx(false)
            end
        end
        -- 刷新单色节点（取方向1的颜色，单色块四方向相同）
        local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(self:_GetFirstValidColorByColorDict(colorDir), true)
        local hasColor = colorCfg ~= nil
        if self.RImgYuan   then
            self.RImgYuan.gameObject:SetActiveEx(hasColor)
            if hasColor then self.RImgYuan:SetRawImage(colorCfg.IconCircle) end
        end
        self:SetFlowerVisible(hasColor, hasColor and colorCfg.IconSupprtTop or nil)
    end

    if not skipLinesRefresh then
        self:_RefreshLinesShow()
    end
end

function XUiGridDyeMergeTurnable:_GetFirstValidColorByColorDict(colorDict)
    for i, v in pairs(colorDict) do
        if XTool.IsNumberValid(v) then
            return v
        end
    end
    return 0
end

function XUiGridDyeMergeTurnable:_RefreshLinesShow()
    if self._IsLineAnimating then return end

    local gc = self._Control.GamingControl
    local blocksControl = gc.BlocksControl
    local mapControl = gc.MapControl
    local block = blocksControl:GetBlockByUid(self.Uid)
    if not block then return end

    local colorDir = blocksControl:GetRotatedColorDir(self.Uid)
    if not colorDir or next(colorDir) == nil then return end

    local board = self.Parent.Parent
    local halfW = board._HalfW
    local halfH = board._HalfH
    local lineIndex = 0
    local dirRanges = self._LineDirRanges or {}
    self._LineDirRanges = dirRanges
    local rangeCount = 0

    for dirIndex = 1, 4 do
        local colorId = colorDir[dirIndex]
        if colorId and colorId ~= 0 then
            local startIdx = lineIndex + 1
            lineIndex = self:_TraceAndShowLines(block, dirIndex, colorId, lineIndex, gc, mapControl, halfW, halfH)
            if lineIndex >= startIdx then
                rangeCount = rangeCount + 1
                local r = dirRanges[rangeCount]
                if not r then
                    r = {}
                    dirRanges[rangeCount] = r
                end
                r.start = startIdx
                r.finish = lineIndex
            end
        end
    end

    for i = rangeCount + 1, #dirRanges do
        dirRanges[i] = nil
    end

    self:_ReturnLinesFrom(lineIndex + 1)
end

--- 沿指定方向追踪射线路径，为每段连续直线创建一条线条节点
---@return number 更新后的 lineIndex
function XUiGridDyeMergeTurnable:_TraceAndShowLines(block, dirIndex, colorId, lineIndex, gc, mapControl, halfW, halfH)
    local startX = block:GetX()
    local startY = block:GetY()
    local curDir = dirIndex
    local delta = DirDelta[curDir]
    local segStartX = startX
    local segStartY = startY
    local prevX = startX
    local prevY = startY
    local mapList = mapControl:GetMapList()
    local mirrorType = XMVCA.XDyeMergeGame.EnumConst.BlockType.Mirror
    local isFirstSeg = true
    local segStartDir = curDir
    local segStartUid = nil
    local segStartEntryDir = nil

    while true do
        local nextX = prevX + delta.dx
        local nextY = prevY + delta.dy
        if not mapControl:CheckPosInMapIsValid(nextX, nextY) then
            lineIndex = lineIndex + 1
            self:_ShowLine(lineIndex, colorId, segStartX, segStartY, nextX, nextY,
                gc, halfW, halfH, isFirstSeg, true, segStartDir, nil, nil, segStartUid, segStartEntryDir)
            break
        end

        local nextIndex = gc:Vec2ToIndex(nextX, nextY)
        local occupyUid = mapList[nextIndex]

        if XTool.IsNumberValidEx(occupyUid) then
            local occupyBlock = gc.BlocksControl:GetBlockByUid(occupyUid)
            if occupyBlock and occupyBlock:GetType() == mirrorType then
                lineIndex = lineIndex + 1
                self:_ShowLine(lineIndex, colorId, segStartX, segStartY, nextX, nextY,
                    gc, halfW, halfH, isFirstSeg, true, segStartDir, curDir, occupyUid, segStartUid, segStartEntryDir)
                local reflectMap = MirrorReflectMap[occupyBlock:GetRotateIndex()]
                local newDir = reflectMap and reflectMap[curDir]
                if not newDir then
                    break
                end
                curDir = newDir
                delta = DirDelta[curDir]
                segStartX = nextX
                segStartY = nextY
                prevX = nextX
                prevY = nextY
                isFirstSeg = false
                segStartDir = curDir
                segStartUid = occupyUid
                segStartEntryDir = OppositeDir[newDir]
            else
                lineIndex = lineIndex + 1
                self:_ShowLine(lineIndex, colorId, segStartX, segStartY, nextX, nextY,
                    gc, halfW, halfH, isFirstSeg, true, segStartDir, curDir, occupyUid, segStartUid, segStartEntryDir)
                break
            end
        else
            prevX = nextX
            prevY = nextY
        end
    end

    return lineIndex
end

--- 显示一条线段：优先使用 pos 节点偏移定位端点，回退到菱形几何计算
function XUiGridDyeMergeTurnable:_ShowLine(index, colorId, gridX1, gridY1, gridX2, gridY2,
    gc, halfW, halfH, shrinkStart, shrinkEnd, startDirIndex, endDirIndex, endUid, startUid, startEntryDir)
    local line = self:_GetOrCreateLine(index)
    if not line then return end
    line:Open()
    local sx1, sy1 = gc:Vec2ToIsoPos(gridX1, gridY1, halfW, halfH)
    local sx2, sy2 = gc:Vec2ToIsoPos(gridX2, gridY2, halfW, halfH)

    -- 起点偏移：优先外部方块（Mirror 出射），其次自身 pos 节点（首段出射）
    local startPosNode
    local startOffsetX, startOffsetY
    if startUid and startEntryDir then
        startOffsetX, startOffsetY = self.Parent:GetBlockEntryOffset(startUid, startEntryDir)
    elseif shrinkStart and startDirIndex then
        startPosNode = self[DirToExitPosKey[startDirIndex]]
    end
    -- 终点偏移从目标方块获取（通过服务层解耦）
    local endOffsetX, endOffsetY
    if shrinkEnd and endDirIndex and endUid then
        endOffsetX, endOffsetY = self.Parent:GetBlockEntryOffset(endUid, endDirIndex)
    end

    if startPosNode and endOffsetX then
        -- 两端都有 pos 节点（起点=自身 pos）：各自偏移到对应边缘
        local scaleX, scaleY = self.Transform:GetLocalScale()
        local px1, py1 = startPosNode:GetLocalPosition()
        sx1 = sx1 + px1 * scaleX
        sy1 = sy1 + py1 * scaleY
        sx2 = sx2 + endOffsetX
        sy2 = sy2 + endOffsetY
    elseif startOffsetX and endOffsetX then
        -- 两端都有 pos 节点（起点=外部方块 pos）：各自偏移到对应边缘
        sx1 = sx1 + startOffsetX
        sy1 = sy1 + startOffsetY
        sx2 = sx2 + endOffsetX
        sy2 = sy2 + endOffsetY
    elseif startPosNode then
        -- 仅起点有 pos（自身节点，终点在边界外）：
        -- 1. 平移整条线段到 pos 位置，保持线方向不变
        -- 2. 终点需回退，消除 pos 偏移中沿线方向的分量 + 菱形边缘缩进
        local scaleX, scaleY = self.Transform:GetLocalScale()
        local px, py = startPosNode:GetLocalPosition()
        local offsetX = px * scaleX
        local offsetY = py * scaleY
        sx1 = sx1 + offsetX
        sy1 = sy1 + offsetY
        sx2 = sx2 + offsetX
        sy2 = sy2 + offsetY
        local dx = sx2 - sx1
        local dy = sy2 - sy1
        local len = math.sqrt(dx * dx + dy * dy)
        if len >= 1 then
            local ux, uy = dx / len, dy / len
            -- d: 菱形中心到边缘的距离（沿当前线方向）
            local d = 1 / (math.abs(ux) / halfW + math.abs(uy) / halfH)
            -- proj: pos 偏移在线方向上的投影，抵消平移引入的沿线位移
            local proj = offsetX * ux + offsetY * uy
            sx2 = sx2 - ux * (d + proj)
            sy2 = sy2 - uy * (d + proj)
        end
    elseif startOffsetX then
        -- 仅起点有 pos（外部方块，终点在边界外）：同上逻辑，偏移值已是 Board 空间
        sx1 = sx1 + startOffsetX
        sy1 = sy1 + startOffsetY
        sx2 = sx2 + startOffsetX
        sy2 = sy2 + startOffsetY
        local dx = sx2 - sx1
        local dy = sy2 - sy1
        local len = math.sqrt(dx * dx + dy * dy)
        if len >= 1 then
            local ux, uy = dx / len, dy / len
            local d = 1 / (math.abs(ux) / halfW + math.abs(uy) / halfH)
            local proj = startOffsetX * ux + startOffsetY * uy
            sx2 = sx2 - ux * (d + proj)
            sy2 = sy2 - uy * (d + proj)
        end
    elseif endOffsetX then
        -- 仅终点有 pos（起点无 pos 节点可用）
        sx2 = sx2 + endOffsetX
        sy2 = sy2 + endOffsetY
    else
        if shrinkStart or shrinkEnd then
            sx1, sy1, sx2, sy2 = self:_ShrinkLineEndpoints(sx1, sy1, sx2, sy2, halfW, halfH, shrinkStart, shrinkEnd)
        end
    end

    line:Refresh(colorId, sx1, sy1, sx2, sy2)
end

--- 对线段端点做菱形边缘缩进：沿连线方向将端点从格子中心移动到菱形边界
function XUiGridDyeMergeTurnable:_ShrinkLineEndpoints(sx1, sy1, sx2, sy2, halfW, halfH, shrinkStart, shrinkEnd)
    if not shrinkStart and not shrinkEnd then
        return sx1, sy1, sx2, sy2
    end
    local dx = sx2 - sx1
    local dy = sy2 - sy1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return sx1, sy1, sx2, sy2 end

    -- 单位方向向量（起点→终点）
    local ux, uy = dx / len, dy / len
    -- 菱形边缘距离公式：|cos(θ)|/halfW + |sin(θ)|/halfH = 1/d
    -- d 即沿 (ux,uy) 方向从菱形中心到边缘的距离
    local d = 1 / (math.abs(ux) / halfW + math.abs(uy) / halfH)

    if shrinkStart then
        -- 起点沿正方向前移 d，从中心移到菱形边缘
        sx1 = sx1 + ux * d
        sy1 = sy1 + uy * d
    end
    if shrinkEnd then
        -- 终点沿反方向回退 d，从中心移到菱形边缘
        sx2 = sx2 - ux * d
        sy2 = sy2 - uy * d
    end
    return sx1, sy1, sx2, sy2
end

--- 从 GridPools 获取第 index 条线段节点
function XUiGridDyeMergeTurnable:_GetOrCreateLine(index)
    if self._LineNodes[index] then
        return self._LineNodes[index]
    end
    local line = self.Parent:GetLine()
    if not line then return nil end
    self._LineNodes[index] = line
    return line
end

--- 回收从 fromIndex 开始的所有线条节点到池
function XUiGridDyeMergeTurnable:_ReturnLinesFrom(fromIndex)
    for i = fromIndex, #self._LineNodes do
        if self._LineNodes[i] then
            self.Parent:ReturnLine(self._LineNodes[i])
            self._LineNodes[i] = nil
        end
    end
end

--- 方块被回收到池时归还所有线条
function XUiGridDyeMergeTurnable:OnDisable()
    XUiGridDyeMerge.OnDisable(self)
    if self._IsLineAnimating then
        self._IsLineAnimating = false
        if self._LineAnimParams then
            self._Control.GamingControl.AnimationControl:OnEndAnimation(self._LineAnimParams)
            self._LineAnimParams = nil
        end
    end
    self:_ReturnLinesFrom(1)
end

--region 线条动画公开接口

function XUiGridDyeMergeTurnable:BeginLineAnimation(params)
    self._IsLineAnimating = true
    self._LineAnimParams = params
end

function XUiGridDyeMergeTurnable:EndLineAnimation()
    self._IsLineAnimating = false
    self._LineAnimParams = nil
end

function XUiGridDyeMergeTurnable:IsLineAnimating()
    return self._IsLineAnimating
end

function XUiGridDyeMergeTurnable:GetLineNodes()
    return self._LineNodes
end

function XUiGridDyeMergeTurnable:GetLineDirRanges()
    return self._LineDirRanges
end

function XUiGridDyeMergeTurnable:ReturnAllLines()
    self:_ReturnLinesFrom(1)
end

function XUiGridDyeMergeTurnable:RefreshLinesForAnimation()
    self._IsLineAnimating = false
    self:_RefreshLinesShow()
    self._IsLineAnimating = true
end

--endregion

function XUiGridDyeMergeTurnable:_OnBtnRotateClick()
    if self._SendGridClickSignal then
        self._SendGridClickSignal(self.Uid)
    end
end

--- 通关后播放供色骨骼动画（单色用 spine，多色保持静态图标）
function XUiGridDyeMergeTurnable:RefreshOnStagePass(uid)
    local blocksControl = self._Control.GamingControl.BlocksControl
    local block = blocksControl:GetBlockByUid(uid)
    if not block then return end

    local colorDir = blocksControl:GetRotatedColorDir(uid)
    if not colorDir or next(colorDir) == nil then return end

    self:_ClearObjectSpine()
    if blocksControl:IsMultiColorBlock(uid) then
        for i = 1, 4 do
            local nodes = self._ColorNodes[i]
            local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(colorDir[i], true)
            if colorCfg and nodes.objectEnd then
                nodes.objectEnd.gameObject:SetActiveEx(true)
                nodes.objectEnd:SetRawImage(colorCfg.IconTop)
            end
            if nodes.object then
                nodes.object.gameObject:SetActiveEx(false)
            end
        end
    else
        local colorCfg = self._Control.GamingControl:GetTableDyeMergeBlocksConfig(self:_GetFirstValidColorByColorDict(colorDir), true)
        self:EnterPassDisplay(colorCfg)
    end
end

return XUiGridDyeMergeTurnable