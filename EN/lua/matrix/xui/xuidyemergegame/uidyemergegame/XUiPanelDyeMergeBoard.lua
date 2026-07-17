--- 控制局内棋盘面板
---@class XUiPanelDyeMergeBoard: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent XUiDyeMergeGame
local XUiPanelDyeMergeBoard = XClass(XUiNode, "XUiPanelDyeMergeBoard")

local XUiIsometricDepthSorter = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Tools/XUiIsometricDepthSorter")
local XUiDyeMergeGameGridPools = require("XUi/XUiDyeMergeGame/UiDyeMergeGame/Tools/XUiDyeMergeGameGridPools")

function XUiPanelDyeMergeBoard:OnStart()
    --- 三个功能根节点强制激活
    if self.CacheRoot then
        self.CacheRoot.gameObject:SetActiveEx(true)
    end

    if self.PrefabRoot then
        self.PrefabRoot.gameObject:SetActiveEx(true)
    end

    if self.PanelBoard then
        self.PanelBoard.gameObject:SetActiveEx(true)
    end
    
    ---@type XUiIsometricDepthSorter
    self._DepthSorter = XUiIsometricDepthSorter.New()   -- 统一管理地板与方块的深度排序
    ---@type XUiDyeMergeGameGridPools
    self.GridPools = XUiDyeMergeGameGridPools.New(self.GameObject, self)

    --- uid -> GameObject，供深度排序动态更新使用
    self.Uid2BlockGoDict = {}

    self:_InitGridClickSenders()
    self:InitFloorMap()
    self._IsExternalEntry = true
    self:InitGridsInMap()
    
    self._DefaultPosX, self._DefaultPosY, self._DefaultPosZ = self.Transform:GetLocalPosition()
    self._DefaultScaleX, self._DefaultScaleY, self._DefaultScaleZ = self.Transform:GetLocalScale()
end

function XUiPanelDyeMergeBoard:OnEnable()
    self._Control.GamingControl:AddEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_BLOCK_DEPTH_DIRTY, self._OnBlockDepthDirty, self)
    XEventManager.AddEventListener(XEventId.EVENT_DYEMERGE_GAME_CLICK_POS, self._OnEventClickPos, self)
end

function XUiPanelDyeMergeBoard:OnDisable()
    self._Control.GamingControl:RemoveEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_BLOCK_DEPTH_DIRTY, self._OnBlockDepthDirty, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DYEMERGE_GAME_CLICK_POS, self._OnEventClickPos, self)

    self:StopCircleDelayTimer()
end

function XUiPanelDyeMergeBoard:OnDestroy()
    
end

function XUiPanelDyeMergeBoard:_InitGridClickSenders()
    local mediator = self.Parent._InputMediator
    local inputTypes = self._Control.EnumConst.UIInputTypes
    local gc = self._Control.GamingControl

    self._BlockClickSender = function(uid)
        mediator:ReceiveInputSignal(inputTypes.GamingClickGrid, uid)
    end
    self._FloorClickSender = function(x, y)
        mediator:ReceiveInputSignal(inputTypes.GamingClickFloor, gc:Vec2ToIndex(x, y))
    end
end

function XUiPanelDyeMergeBoard:InitFloorMap()
    self:_RecycleFloorGrids()
    ---@type XUiGridDyeMerge[]
    self.Pos2FloorDict = {}
    self._DepthSorter:Clear()

    local mapSizeX = self._Control.GamingControl.MapControl:GetMapSizeX()
    local mapSizeY = self._Control.GamingControl.MapControl:GetMapSizeY()

    -- 从对象池临时取一个地板格读取尺寸，所有同类型格尺寸相同
    local styleName = "GridFloor"
    local floorType = XMVCA.XDyeMergeGame.EnumConst.BlockType.Floor
    local tempFloor = self.GridPools:GetGridByNameAndType(styleName, floorType)
    if not tempFloor then return end
    local tileW, tileH = tempFloor.Transform:GetUISizeDelta()
    self._HalfW = tileW / 2
    self._HalfH = tileH / 2
    self.GridPools:ReturnGridByName(styleName, tempFloor)
    local halfW = self._HalfW
    local halfH = self._HalfH

    for x = 1, mapSizeX do
        for y = 1, mapSizeY do
            local isValid, id = self._Control.GamingControl:IsGridValid(x, y)
            if isValid and not self._Control.GamingControl:IsImmovableBlockAt(x, y) then
                local gridFloor = self.GridPools:GetGridByNameAndType(styleName, floorType)

                if not gridFloor then
                    return
                end
                gridFloor:SetPrefabStyleName(styleName)
                gridFloor.GameObject.name = "GridFloor(" .. tostring(y) .. ', ' .. tostring(x) .. ')'
                gridFloor:Open()
                gridFloor:SetGridClickSignalSender(self._FloorClickSender)
                gridFloor:SetFloorCoord(x, y)
                gridFloor:SetBgStyle(id == -1)

                local posIndex = self._Control.GamingControl:Vec2ToIndex(x, y)
                self.Pos2FloorDict[posIndex] = gridFloor

                local posX, posY = self._Control.GamingControl:Vec2ToIsoPos(x, y, halfW, halfH)
                gridFloor.Transform:SetLocalPosition(posX, posY, 0)
                -- subKey=0 表示地板；同坐标时地板渲染在方块之后
                self._DepthSorter:Add(gridFloor.Transform, x + y, 0)
            end
        end
    end
    -- 地板添加完毕，待 InitGridsInMap 完成后统一排序，此处不 Sort
end

function XUiPanelDyeMergeBoard:_RecycleFloorGrids()
    if not XTool.IsTableEmpty(self.Pos2FloorDict) then
        for i, v in pairs(self.Pos2FloorDict) do
            v:OnRecycle()
            self.GridPools:ReturnGridByName(v:GetStyleName(), v)
        end
    end
end

function XUiPanelDyeMergeBoard:InitGridsInMap()
    self:_RecycleGridsInMap()
    ---@type table<number, XUiGridDyeMerge>
    self._Uid2GridDict = {}
    self.Uid2BlockGoDict = {}

    local blocks = self._Control.GamingControl.BlocksControl:GetUsingBlockList()

    if XTool.IsTableEmpty(blocks) then
        XLog.Error("关卡不存在有效的方块，stageId: " .. tostring(self._Control.GamingControl:GetCurStageId()))
        self._Control.GamingControl:SetInitPhaseState(false)
        return
    end

    local BT = XMVCA.XDyeMergeGame.EnumConst.BlockType
    -- 收集 Target 类型方块，待所有方块实例化后统一刷新
    local deferredTargets = {}
    -- 收集 Turnable 类型方块，待所有方块实例化后统一刷新射线
    local deferredTurnables = {}

    for i, v in pairs(blocks) do
        local cfg = self._Control.GamingControl:GetTableDyeMergeBlockById(v:GetId())

        if cfg then
            local grid = self.GridPools:GetGridByNameAndType(cfg.UiGridName, cfg.Type)

            if not grid then
                return
            end
            local x = v:GetX()
            local y = v:GetY()
            local uid = v:GetUid()

            grid:SetPrefabStyleName(cfg.UiGridName)
            grid.GameObject.name = cfg.UiGridName .. "(" .. tostring(y) .. ', ' .. tostring(x) .. ')'
            grid:Open()
            grid:InitRootOriginY()
            grid:SetGridClickSignalSender(self._BlockClickSender)

            if cfg.Type == BT.Target then
                -- Target 方块延迟刷新：依赖其他方块的颜色数据
                deferredTargets[uid] = grid
            elseif cfg.Type == BT.TurnableMultyColor then
                -- Turnable 先刷新图标，跳过射线（目标 grid 可能尚未注册）
                grid:Refresh(uid, true)
                deferredTurnables[#deferredTurnables + 1] = grid
            else
                grid:Refresh(uid)
            end

            self._Uid2GridDict[uid] = grid
            -- 填充 Uid2BlockGoDict 供 _OnBlockDepthDirty 动态更新使用
            self.Uid2BlockGoDict[uid] = grid.GameObject

            local posX, posY = self._Control.GamingControl:Vec2ToIsoPos(x, y, self._HalfW, self._HalfH)
            grid.Transform:SetLocalPosition(posX, posY, 0)
            -- subKey=1 表示方块；同坐标时方块渲染在地板之前
            self._DepthSorter:Add(grid.Transform, x + y, 1)
        end
    end

    -- 所有方块实例化完毕，统一刷新 Target 方块
    if not XTool.IsTableEmpty(deferredTargets) then
        for uid, grid in pairs(deferredTargets) do
            grid:Refresh(uid)
        end
    end

    -- 所有 grid 就位后统一刷新 Turnable 射线（依赖目标方块的 pos 节点）
    if not XTool.IsTableEmpty(deferredTurnables) then
        for i = 1, #deferredTurnables do
            deferredTurnables[i]:_RefreshLinesShow()
        end
    end

    self._Control.GamingControl:SetInitPhaseState(false)

    -- 地板与方块全部注册完毕，统一执行首次深度排序
    self._DepthSorter:Sort()

    -- 关卡开始聚焦圈
    self:_ShowStartFocusCircles()
end

function XUiPanelDyeMergeBoard:_RecycleGridsInMap()
    if not XTool.IsTableEmpty(self._Uid2GridDict) then
        for i, v in pairs(self._Uid2GridDict) do
            v:SetSelectOffset(false)
            v:OnRecycle()
            self.GridPools:ReturnGridByName(v:GetStyleName(), v)
        end
    end
end

--- 根据关卡配置 StartFocusPosIndexs 显示聚焦圈动画
function XUiPanelDyeMergeBoard:_ShowStartFocusCircles()
    self:_RecycleStartFocusCircles()

    local stageId = self._Control.GamingControl:GetCurStageId()
    local stageCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeStageById(stageId)
    if not stageCfg then return end

    local posIndexs = stageCfg.StartFocusPosIndexs
    if XTool.IsTableEmpty(posIndexs) then return end

    local isExternal = self._IsExternalEntry
    self._IsExternalEntry = nil

    if isExternal then
        local delay = XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("GameTipsStartFocusCircleDelay") or 0
        if delay > 0 then
            self._CircleDelayTimer = XScheduleManager.ScheduleOnce(function()
                self._CircleDelayTimer = nil
                self:_SpawnCircles(posIndexs)
            end, math.floor(delay * XScheduleManager.SECOND))
            return
        end
    end

    self:_SpawnCircles(posIndexs)
end

--- 实际生成聚焦圈并播放动画
function XUiPanelDyeMergeBoard:_SpawnCircles(posIndexs)
    local gc = self._Control.GamingControl
    self._ActiveCircles = {}
    for _, posIndex in ipairs(posIndexs) do
        local raw = posIndex % 10000
        local x, y = gc:IndexToVec2(raw)
        local posX, posY = gc:Vec2ToIsoPos(x, y, self._HalfW, self._HalfH)
        local circle = self.GridPools:GetCircle()
        if circle then
            circle.Transform:SetLocalPosition(posX, posY, 0)
            circle:PlayAndRecycle()
            self._ActiveCircles[circle] = true
        end
    end
end

--- 聚焦圈动画播完后的回调入口（由 GridCircle 调用）
function XUiPanelDyeMergeBoard:OnCircleRecycled(circle)
    if self._ActiveCircles then
        self._ActiveCircles[circle] = nil
    end
end

function XUiPanelDyeMergeBoard:StopCircleDelayTimer()
    if self._CircleDelayTimer then
        XScheduleManager.UnSchedule(self._CircleDelayTimer)
        self._CircleDelayTimer = nil
    end
end

--- 强制回收所有飞行中的聚焦圈（切关卡/退出时调用）
function XUiPanelDyeMergeBoard:_RecycleStartFocusCircles()
    self:StopCircleDelayTimer()
    if XTool.IsTableEmpty(self._ActiveCircles) then return end
    for circle in pairs(self._ActiveCircles) do
        circle:Close()
        self.GridPools:ReturnCircle(circle)
    end
    self._ActiveCircles = nil
end

--- 方块 GO 被创建并放入棋盘时调用（动态新增路径）
---@param uid number
---@param go userdata
function XUiPanelDyeMergeBoard:OnBlockGoAdded(uid, go)
    self.Uid2BlockGoDict[uid] = go
    local key = self:_CalcDepthKey(uid)
    self._DepthSorter:AddAndSort(go.transform, key, 1)
end

--- 方块 GO 从棋盘移除时调用
---@param uid number
---@param go userdata
function XUiPanelDyeMergeBoard:OnBlockGoRemoved(uid, go)
    self.Uid2BlockGoDict[uid] = nil
    self._DepthSorter:RemoveAndSort(go.transform)
end

--- 计算方块的等距深度键
--- depthKey = x + y，所有方块统一按中心格坐标排序
--- 延伸块的各切片在 _RefreshSlices 中按各自坐标独立注册
---@param uid number
---@return number
function XUiPanelDyeMergeBoard:_CalcDepthKey(uid)
    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    return block:GetX() + block:GetY()
end

--- 方块深度脏标记回调（方块移动或变长后触发）
---@param uid number
function XUiPanelDyeMergeBoard:_OnBlockDepthDirty(uid)
    local grid = self._Uid2GridDict[uid]
    if not grid then return end

    local block = self._Control.GamingControl.BlocksControl:GetBlockByUid(uid)
    if not block then return end

    -- 同步视觉位置（跟随逻辑坐标，方块交换/移动后必须更新）
    local posX, posY = self._Control.GamingControl:Vec2ToIsoPos(block:GetX(), block:GetY(), self._HalfW, self._HalfH)
    grid.Transform:SetLocalPosition(posX, posY, 0)

    -- 更新深度排序（使用与 InitGridsInMap 注册时相同的 grid.Transform 引用）
    local key = self:_CalcDepthKey(uid)
    self._DepthSorter:SetKey(grid.Transform, key)

    -- 收回场景跳过 Refresh：保留旧切片供 Disable 动画播放，由 UpdateAllState 统一清理
    if not self._Control.GamingControl:HasPendingShrinkAnim(uid) then
        grid:Refresh(uid)
    end

    self._DepthSorter:Sort()
end

--- 获取复用节点回收时所属的父节点
function XUiPanelDyeMergeBoard:_GetGoCacheRoot()
    return self.CacheRoot.transform
end

--- 获取节点被使用展示时所属的父节点
function XUiPanelDyeMergeBoard:_GetGoShowRoot()
    return self.PanelBoard.transform
end

function XUiPanelDyeMergeBoard:_OnEventClickPos(x, y)
    if XMain.IsEditorDebug then
        XLog.Debug("[DyeMerge]点击事件：（x，y）= " .. x .. ", " .. y)
    end
    
    x = tonumber(x)
    y = tonumber(y)
    
    local gc = self._Control.GamingControl
    local posIndex = gc:Vec2ToIndex(x, y)
    local mapList = gc.MapControl:GetMapList()
    local occupyUid = mapList[posIndex]
    if XTool.IsNumberValidEx(occupyUid) then
        self._BlockClickSender(occupyUid)
    elseif self.Pos2FloorDict[posIndex] then
        self._FloorClickSender(x, y)
    end
end

--region 重置

--- 重置棋盘表现层：回收所有 Grid，重建地板和方块
function XUiPanelDyeMergeBoard:ResetBoard()
    self:InitFloorMap()
    self:InitGridsInMap()
end

--endregion

--region 棋盘整体变换

function XUiPanelDyeMergeBoard:UpdateBoardTransform(offsetX, offsetY, scale)
    self.Transform:SetLocalPosition(self._DefaultPosX + offsetX, self._DefaultPosY + offsetY, self._DefaultPosZ)

    if XTool.IsNumberValidEx(scale) then
        self.Transform:SetLocalScale(scale, scale, self._DefaultScaleZ)
    else
        self.Transform:SetLocalScale(self._DefaultScaleX, self._DefaultScaleY, self._DefaultScaleZ)
    end
end

--endregion

--region [Test] 表现层快照

--- [Test] 拍摄表现层数据快照
---@return table
function XUiPanelDyeMergeBoard:TestTakeViewSnapshot()
    local snapshot = {}

    snapshot.FloorCount = XTool.IsTableEmpty(self.Pos2FloorDict) and 0 or XTool.GetTableCount(self.Pos2FloorDict)

    snapshot.GridCount = XTool.IsTableEmpty(self._Uid2GridDict) and 0 or XTool.GetTableCount(self._Uid2GridDict)
    snapshot.GridUids = {}
    if not XTool.IsTableEmpty(self._Uid2GridDict) then
        for uid, _ in pairs(self._Uid2GridDict) do
            table.insert(snapshot.GridUids, uid)
        end
        table.sort(snapshot.GridUids)
    end

    return snapshot
end

--- [Test] 比对表现层快照，差异以 XLog.Warning 输出
---@param snapshot table
function XUiPanelDyeMergeBoard:TestCompareViewSnapshot(snapshot)
    if not snapshot then return end

    local prefix = "[DyeMerge][TestReset][View] "

    local curFloorCount = XTool.IsTableEmpty(self.Pos2FloorDict) and 0 or XTool.GetTableCount(self.Pos2FloorDict)
    if curFloorCount ~= snapshot.FloorCount then
        XLog.Warning(prefix .. "地板格数量不一致: 期望=" .. tostring(snapshot.FloorCount) .. " 实际=" .. tostring(curFloorCount))
    end

    local curGridCount = XTool.IsTableEmpty(self._Uid2GridDict) and 0 or XTool.GetTableCount(self._Uid2GridDict)
    if curGridCount ~= snapshot.GridCount then
        XLog.Warning(prefix .. "方块Grid数量不一致: 期望=" .. tostring(snapshot.GridCount) .. " 实际=" .. tostring(curGridCount))
    end

    for _, uid in ipairs(snapshot.GridUids) do
        if not self._Uid2GridDict[uid] then
            XLog.Warning(prefix .. "Grid Uid=" .. tostring(uid) .. " 重置后不存在")
        end
    end

    XLog.Debug(prefix .. "表现层快照比对完成")
end

--endregion

return XUiPanelDyeMergeBoard
