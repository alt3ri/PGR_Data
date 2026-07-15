--- 负责表现层动画驱动的组件，Ui节点逻辑上是XUiDyeMergeGame的子节点，但是GameObject绑定关系和XUiDyeMergeGame属于同一层级，所以使用了Component的概念（类比Unity）
---@class XUiComDyeMergeGameAction: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent
local XUiComDyeMergeGameAction = XClass(XUiNode, "XUiComDyeMergeGameAction")

function XUiComDyeMergeGameAction:OnStart()
    self:InitActionEvents()
    
    -- 单段线条播放时长上限（秒）
    self._LineAnimDurationPerSeg = XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("LineAnimDurationPerSeg")
    -- 单方向线段总时长上限（每段时长按Total/SegCount均分）
    self._LineAnimTotalCap = XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("LineAnimTotalCap")
end

function XUiComDyeMergeGameAction:OnEnable()
    self._Control.GamingControl:AddEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ANIMATION_RUN, self.OnActionEventNotify, self)
end

function XUiComDyeMergeGameAction:OnDisable()
    self._Control.GamingControl:RemoveEventListener(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ANIMATION_RUN, self.OnActionEventNotify, self)
end

function XUiComDyeMergeGameAction:InitActionEvents()
    self._ActionEventMap = {
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.SelectGrid] = handler(self, self._OnSelectGridAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.PlacedGird] = handler(self, self._OnPlacedGridAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.UpdateAllState] = handler(self, self._OnUpdateAllStateAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.StagePassed] = handler(self, self._OnStagePassedAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.TurnableRetractLines] = handler(self, self._OnRetractLinesAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.TurnableExtendLines] = handler(self, self._OnExtendLinesAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.ExtendBlockDisable] = handler(self, self._OnExtendBlockDisableAnimation),
        [XMVCA.XDyeMergeGame.EnumConst.AnimationType.ExtendBlockEnable] = handler(self, self._OnExtendBlockEnableAnimation),
    }
end

function XUiComDyeMergeGameAction:OnActionEventNotify(actionType, params)
    -- XLog.Debug("[DyeMerge][ComAction] 收到动画事件 actionType=" .. tostring(actionType) .. " blockUid=" .. tostring(params and params.BlockUid))
    if self._ActionEventMap[actionType] then
        self._ActionEventMap[actionType](params)
    else
        XLog.Warning("[DyeMerge][ComAction] 未注册的 actionType=" .. tostring(actionType))
    end
end

function XUiComDyeMergeGameAction:_OnSelectGridAnimation(params)
    -- XLog.Debug("[DyeMerge][ComAction] SelectGrid 开始，selectUid=" .. tostring(params.BlockUid))
    local board = self.Parent.PanelBoard
    local selectUid = params.BlockUid
    local blocksCtrl = self._Control.GamingControl.BlocksControl

    -- 地板格：未被占据的格子显示选择提示
    if not XTool.IsTableEmpty(board.Pos2FloorDict) then
        for posIndex, floorGrid in pairs(board.Pos2FloorDict) do
            local isOccupied = blocksCtrl:GetBlockIsExsistByPosIndex(posIndex)
            floorGrid:SetShowSelectable(not isOccupied)
        end
    end

    -- 方块格：当前选中方块及其他可移动方块均显示选择提示
    if not XTool.IsTableEmpty(board._Uid2GridDict) then
        for uid, blockGrid in pairs(board._Uid2GridDict) do
            local block = blocksCtrl:GetBlockByUid(uid)
            blockGrid:SetSelectVisible(block ~= nil and block:GetCanMove())
            -- 仅被选中的方块抬起偏移
            blockGrid:SetSelectOffset(uid == selectUid)
        end
    end
    
    self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
end

function XUiComDyeMergeGameAction:_OnPlacedGridAnimation(params)
    -- XLog.Debug("[DyeMerge][ComAction] PlacedGird 开始，blockUid=" .. tostring(params.BlockUid))
    local board = self.Parent.PanelBoard

    -- 隐藏所有地板格的选择提示
    if not XTool.IsTableEmpty(board.Pos2FloorDict) then
        for _, floorGrid in pairs(board.Pos2FloorDict) do
            floorGrid:SetShowSelectable(false)
        end
    end

    -- 隐藏所有方块格的选择标记，恢复偏移
    if not XTool.IsTableEmpty(board._Uid2GridDict) then
        for _, blockGrid in pairs(board._Uid2GridDict) do
            blockGrid:SetSelectVisible(false)
            blockGrid:SetSelectOffset(false)
        end
    end

    self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
end

function XUiComDyeMergeGameAction:_OnUpdateAllStateAnimation(params)
    local board = self.Parent.PanelBoard
    local gridDict = board._Uid2GridDict
    local count = gridDict and XTool.GetTableCount(gridDict) or 0
    -- XLog.Debug("[DyeMerge][ComAction] UpdateAllState 开始，方块格数量=" .. tostring(count))

    local extendEnableUid = self._Control.GamingControl:ConsumeExtendEnablePendingUid()

    if not XTool.IsTableEmpty(gridDict) then
        for uid, grid in pairs(gridDict) do
            if uid == extendEnableUid and grid.SetHideNewSlices then
                grid:SetHideNewSlices(true)
            end
            grid:Refresh(uid)
        end
    end

    self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
end

function XUiComDyeMergeGameAction:_OnStagePassedAnimation(params)
    -- XLog.Debug("[DyeMerge][ComAction] StagePassed 开始")
    local board = self.Parent.PanelBoard
    local gridDict = board._Uid2GridDict

    if not XTool.IsTableEmpty(gridDict) then
        for uid, grid in pairs(gridDict) do
            grid:RefreshOnStagePass(uid)
        end
    end

    self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
end

--region 射线缩回/延伸动画
--- 整体流程：
--- 1. Retract（优先级15）：各方向并发，每个方向内从远到近逐段缩回宽度至0，全部完成后回收线条节点
--- 2. UpdateAllState（优先级30）：刷新旋转后的颜色状态（由其他handler处理）
--- 3. Extend（优先级35）：先刷新线条得到新布局，各方向并发，每个方向内从近到远逐段从0延伸到目标宽度
---
--- 并发模型：以方向为单位并发（pendingDirs计数），同方向内的线段串行链式回调（远→近 或 近→远）
--- 中断安全：每次回调入口检查 IsLineAnimating()，grid被回收时OnDisable会清除标志并通知动画系统结束

--- 缩回动画：将旋转方块当前所有射线从远端向近端逐段收回
--- dirRanges 记录了各方向在 lineNodes 中的索引区间（由 _RefreshLinesShow 构建）
function XUiComDyeMergeGameAction:_OnRetractLinesAnimation(params)
    local board = self.Parent.PanelBoard
    local uid = params.BlockUid
    local grid = board._Uid2GridDict[uid]

    local lineNodes = grid and grid:GetLineNodes()
    if not lineNodes or #lineNodes == 0 then
        self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
        return
    end

    local dirRanges = grid:GetLineDirRanges()
    if not dirRanges or #dirRanges == 0 then
        self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
        return
    end

    grid:BeginLineAnimation(params)

    local animControl = self._Control.GamingControl.AnimationControl
    local pendingDirs = #dirRanges

    local function onAllDirsDone()
        if not grid:IsLineAnimating() then return end
        grid:EndLineAnimation()
        grid:ReturnAllLines()
        animControl:OnEndAnimation(params)
    end

    for _, range in ipairs(dirRanges) do
        local segCount = range.finish - range.start + 1
        -- 每段时长 = min(固定上限, 总时长上限/段数)，段数越多每段越快
        local duration = math.min(self._LineAnimDurationPerSeg, self._LineAnimTotalCap / segCount)
        -- 从最远段开始向近端递减（模拟射线从末端收回到发射源）
        local curSeg = range.finish + 1

        local function retractNext()
            if not grid:IsLineAnimating() then return end
            curSeg = curSeg - 1
            if curSeg < range.start then
                pendingDirs = pendingDirs - 1
                if pendingDirs == 0 then
                    onAllDirsDone()
                end
                return
            end
            local line = lineNodes[curSeg]
            if line then
                line:AnimateWidth(0, duration, retractNext)
            else
                retractNext()
            end
        end

        retractNext()
    end
end

--- 延伸动画：旋转刷新后，将新射线从发射源向远端逐段伸出
--- 需要先调用 RefreshLinesForAnimation 重建线条布局（得到旋转后的新路径），
--- 然后记录各线段的目标宽度，将宽度清零后逐段动画恢复
function XUiComDyeMergeGameAction:_OnExtendLinesAnimation(params)
    local board = self.Parent.PanelBoard
    local uid = params.BlockUid
    local grid = board._Uid2GridDict[uid]

    if not grid then
        self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
        return
    end

    -- 临时解除动画锁 → 执行 _RefreshLinesShow 得到新布局 → 重新加锁
    grid:RefreshLinesForAnimation()
    grid:BeginLineAnimation(params)

    local lineNodes = grid:GetLineNodes()
    local dirRanges = grid:GetLineDirRanges()
    if not dirRanges or #dirRanges == 0 or not lineNodes or #lineNodes == 0 then
        grid:EndLineAnimation()
        self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
        return
    end

    -- 快照目标宽度并将线段宽度清零，作为延伸动画的起始状态
    local targetWidths = {}
    for i = 1, #lineNodes do
        local line = lineNodes[i]
        if line then
            targetWidths[i] = line:GetCurrentWidth()
            line:SetCurrentWidth(0)
        end
    end

    local animControl = self._Control.GamingControl.AnimationControl
    local pendingDirs = #dirRanges

    local function onAllDirsDone()
        if not grid:IsLineAnimating() then return end
        grid:EndLineAnimation()
        animControl:OnEndAnimation(params)
    end

    for _, range in ipairs(dirRanges) do
        local segCount = range.finish - range.start + 1
        local duration = math.min(self._LineAnimDurationPerSeg, self._LineAnimTotalCap / segCount)
        -- 从最近段开始向远端递增（模拟射线从发射源射出）
        local curSeg = range.start - 1

        local function extendNext()
            if not grid:IsLineAnimating() then return end
            curSeg = curSeg + 1
            if curSeg > range.finish then
                pendingDirs = pendingDirs - 1
                if pendingDirs == 0 then
                    onAllDirsDone()
                end
                return
            end
            local line = lineNodes[curSeg]
            if line and targetWidths[curSeg] then
                line:AnimateWidth(targetWidths[curSeg], duration, extendNext)
            else
                extendNext()
            end
        end

        extendNext()
    end
end

--endregion

--region 延伸块切片 Disable/Enable 动画

--- 缩回前播放 Disable：对即将消失的切片播放 Disable 动画，全部完成后 EndAnimation
function XUiComDyeMergeGameAction:_OnExtendBlockDisableAnimation(params)
    local board = self.Parent.PanelBoard
    local uid = params.BlockUid
    local grid = board._Uid2GridDict[uid]
    local animControl = self._Control.GamingControl.AnimationControl

    if not grid or not grid.PlaySliceDisableAnim then
        animControl:OnEndAnimation(params)
        return
    end

    local gc = self._Control.GamingControl
    local block = gc.BlocksControl:GetBlockByUid(uid)
    if not block then
        animControl:OnEndAnimation(params)
        return
    end

    local newLen = block:GetVariableLength()
    local newSliceCount = (newLen - 1)

    grid:PlaySliceDisableAnim(newSliceCount, function()
        animControl:OnEndAnimation(params)
    end)
end

--- 延伸后播放 Enable：对 UpdateAllState 中新增但隐藏的切片播放 Enable 动画
function XUiComDyeMergeGameAction:_OnExtendBlockEnableAnimation(params)
    local board = self.Parent.PanelBoard
    local uid = params.BlockUid
    local grid = board._Uid2GridDict[uid]
    local animControl = self._Control.GamingControl.AnimationControl

    if not grid or not grid.PlaySliceEnableAnim then
        animControl:OnEndAnimation(params)
        return
    end

    local oldLen = params.OldLen or 1
    local oldSliceCount = (oldLen - 1)

    grid:PlaySliceEnableAnim(oldSliceCount, function()
        animControl:OnEndAnimation(params)
    end)
end

--endregion

return XUiComDyeMergeGameAction