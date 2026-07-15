--- 负责表现层动画驱动的组件，Ui节点逻辑上是XUiDyeMergeGame的子节点，但是GameObject绑定关系和XUiDyeMergeGame属于同一层级，所以使用了Component的概念（类比Unity）
---@class XUiComDyeMergeGameAction: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent
local XUiComDyeMergeGameAction = XClass(XUiNode, "XUiComDyeMergeGameAction")

function XUiComDyeMergeGameAction:OnStart()
    self:InitActionEvents()
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
    }
end

function XUiComDyeMergeGameAction:OnActionEventNotify(actionType, params)
    XLog.Debug("[DyeMerge][ComAction] 收到动画事件 actionType=" .. tostring(actionType) .. " blockUid=" .. tostring(params and params.BlockUid))
    if self._ActionEventMap[actionType] then
        self._ActionEventMap[actionType](params)
    else
        XLog.Warning("[DyeMerge][ComAction] 未注册的 actionType=" .. tostring(actionType))
    end
end

function XUiComDyeMergeGameAction:_OnSelectGridAnimation(params)
    XLog.Debug("[DyeMerge][ComAction] SelectGrid 开始，selectUid=" .. tostring(params.BlockUid))
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
    XLog.Debug("[DyeMerge][ComAction] PlacedGird 开始，blockUid=" .. tostring(params.BlockUid))
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
    XLog.Debug("[DyeMerge][ComAction] UpdateAllState 开始，方块格数量=" .. tostring(count))

    if not XTool.IsTableEmpty(gridDict) then
        for uid, grid in pairs(gridDict) do
            grid:Refresh(uid)
        end
    end

    self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
end

function XUiComDyeMergeGameAction:_OnStagePassedAnimation(params)
    XLog.Debug("[DyeMerge][ComAction] StagePassed 开始")
    local board = self.Parent.PanelBoard
    local gridDict = board._Uid2GridDict

    if not XTool.IsTableEmpty(gridDict) then
        for uid, grid in pairs(gridDict) do
            grid:RefreshOnStagePass(uid)
        end
    end

    self._Control.GamingControl.AnimationControl:OnEndAnimation(params)
end

return XUiComDyeMergeGameAction