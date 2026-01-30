--- 2048玩法统筹表现层行为序列的组件
---@class XUiComGame2048MapAction: XUiNode
---@field Parent XUiPanelGame2048Map
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiComGame2048MapAction = XClass(XUiNode, 'XUiComGame2048MapAction')

function XUiComGame2048MapAction:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self.EffectThunder.gameObject:SetActiveEx(false)

    self:InitActionEvents()
end

function XUiComGame2048MapAction:OnDisable()
    self:UnDoAllAnimation()
end

function XUiComGame2048MapAction:InitActionEvents()
    self._ActionEventMap = {
        [XMVCA.XGame2048.EnumConst.ActionType.NormalMove] = handler(self, self.GridMoveAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalMerge] = handler(self, self.GridMergeAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalDispel] = handler(self, self.GridDispelAction),
        [XMVCA.XGame2048.EnumConst.ActionType.RockReduce] = handler(self, self.GridRockReduceAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalReduce] = handler(self, self.GridNormalReduceAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NewBlockBorn] = handler(self, self.GridNewBornAction),
        [XMVCA.XGame2048.EnumConst.ActionType.RockShake] = handler(self, self.GridRockShakeAction),
        [XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUp] = handler(self, self.FeverLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.NormalLevelUp] = handler(self, self.NormalLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.TransferLevelUp] = handler(self, self.TransferLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.ICELevelUp] = handler(self, self.ICELevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.FeverUpLevelUp] = handler(self, self.FeverUpLevelUpAction),
        [XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUpCheck] = handler(self, self.FeverLevelUpCheckAction),
        [XMVCA.XGame2048.EnumConst.ActionType.DispelGridDirectionChanged] = handler(self ,self.GridDispelDirectionChangedAction),
        [XMVCA.XGame2048.EnumConst.ActionType.GridChanged] = handler(self, self.GridChangedAction),
        [XMVCA.XGame2048.EnumConst.ActionType.GridChangedAfterMerge] = handler(self, self.GridChangedAction),
        [XMVCA.XGame2048.EnumConst.ActionType.GridChangedAfterDoubleLevelUp] = handler(self, self.GridChangedAction),
        [XMVCA.XGame2048.EnumConst.ActionType.OpenDispelRangeEffect] = handler(self, self.OpenDispelRangeEffect),
        [XMVCA.XGame2048.EnumConst.ActionType.CloseDispelRangeEffect] = handler(self, self.CloseDispelRangeEffect),

    }
    
    self._GameControl:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_NOTIFY_ACTION_EVENT, self.OnActionEventNotify, self)
end


function XUiComGame2048MapAction:OnActionEventNotify(actionType, action)
    if self._ActionEventMap[actionType] then
        self._ActionEventMap[actionType](action)
    end
end

--region -------------------- 行为动画 -------------------->>>

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridMoveAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    local fromIndex = action.MoveFromX + (action.MoveFromY - 1) * self._GameControl:GetWidth()
    local toIndex = action.MoveToX + (action.MoveToY - 1) * self._GameControl:GetWidth()

    if uiGrid then
        local fromBg = self.Parent:GetShowedUiGridByIndex(fromIndex)
        local toBg = self.Parent:GetShowedUiGridByIndex(toIndex)
        
        uiGrid.ActionCom:DoMove(fromBg.Transform, toBg.Transform, function()
            uiGrid:SetNormalizePos(action.MoveToX, action.MoveToY)
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridMoveSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridMergeAction(action)
    ---@type XUiGridGame2048Grid
    local upgradeGrid = self.Parent:GetShowedUiGridByUid(action.GridUidB)
    local disappearGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if action.GridUidB == action.GridUidA then
        XLog.Error("同一个方块不可与自己合成")
        self._GameControl.ActionsControl:EndAction(action)
        return
    end

    if disappearGrid then
        if action.GridUidA ~= disappearGrid.Uid then
            XLog.Error("行为对象里记录的Uid和表现层UI缓存的Uid不一致", action.GridUidA, disappearGrid.Uid)
        end
        
        self.Parent:ReturnUiGridToPool(disappearGrid)
    end

    ---@type XGame2048Grid
    local gridData = nil

    -- 如果升级的方块类型发生了变化，需要回收并按照新的类型获取UI
    if upgradeGrid then
        gridData = self._GameControl:GetGridEntityByUid(action.GridUidB)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end

        if upgradeGrid:GetGridType() ~= gridData:GetGridType() then
            self.Parent:ReturnUiGridToPool(upgradeGrid)
            self.Parent:RefreshNewGrid(gridData, upgradeGrid:GetNormalizePosX(), upgradeGrid:GetNormalizePosY())
            upgradeGrid = self.Parent:GetShowedUiGridByUid(action.GridUidB)
        end
    end

    if upgradeGrid then
        if gridData == nil then
            gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

            if action.TempGridData then
                action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
                gridData = action.TempGridData
            end
        end
        
        if gridData then
            local blockId = gridData.Id
            
            upgradeGrid:RefreshData(gridData)

            self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_FEVER_DATA_REFRESH)

            upgradeGrid.ActionCom:DoMerge(function()
                -- 方块合成后需检查盘面是否升级，并做相应的处理
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(blockId)
                self._GameControl.BoardShowControl:OnGridMergeEvent(blockId)
                
                self._GameControl.ActionsControl:EndAction(action)
            end, true)
        else
            -- 如果没有数据，则是在连续合成中被消除了，被消除的由DispelAction进行回收
            -- 这里仅刷新UI显示
            if XTool.IsNumberValid(action.GridIdB) then
                upgradeGrid:SetShow(action.GridIdB)
                upgradeGrid.ActionCom:DoMerge(function()
                    self._GameControl.ActionsControl:EndAction(action)
                end)
            else
                self._GameControl.ActionsControl:EndAction(action)
            end

        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridDispelAction(action)
    local dispelGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if dispelGrid then
        dispelGrid.ActionCom:DoDispel(function()
            if action.GridUidA ~= dispelGrid.Uid then
                XLog.Error("行为对象里记录的Uid和表现层UI缓存的Uid不一致", action.GridUidA, dispelGrid.Uid)
            end
            
            self.Parent:ReturnUiGridToPool(dispelGrid)
            
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridRockShakeAction(action)
    local rock = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if rock then
        -- 播放石头撞击动画
        rock.ActionCom:DoShake(function()
            -- 刷新显示
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridRockReduceAction(action)
    local rock = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    local rockGrid = self._GameControl:GetGridEntityByUid(action.GridUidA)
    if not rockGrid then
        
    else
        -- 刷新显示
        rock:RefreshData(rockGrid)
    end
    self._GameControl.ActionsControl:EndAction(action)
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridNormalReduceAction(action)
    local block = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    local blockGrid = self._GameControl:GetGridEntityByUid(action.GridUidA)
    -- 刷新显示
    block:RefreshData(blockGrid)

    self._GameControl.ActionsControl:EndAction(action)
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridNewBornAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        uiGrid.ActionCom:DoBorn(function()
            self._GameControl.ActionsControl:EndAction(action)
        end)
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridBornSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:NormalLevelUpAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:TransferLevelUpAction(action)
    -- 传导方块被传导升级后，类型会发生变化，需要替换UI
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            if uiGrid:GetGridType() ~= gridData:GetGridType() then
                self.Parent:ReturnUiGridToPool(uiGrid)
                self.Parent:RefreshNewGrid(gridData)
                uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
            end

            if uiGrid then
                uiGrid:RefreshData(gridData)
                uiGrid.ActionCom:DoMerge(function()
                    self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                    self._GameControl.ActionsControl:EndAction(action)
                end, true, action.MergeEffectType)
            else
                self._GameControl.ActionsControl:EndAction(action)
            end
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:ICELevelUpAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            if uiGrid:GetGridType() ~= gridData:GetGridType() then
                self.Parent:ReturnUiGridToPool(uiGrid)
                self.Parent:RefreshNewGrid(gridData)
                uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
            end
            
            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridDispelDirectionChangedAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)

    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end

        if gridData then
            if uiGrid:GetGridType() ~= gridData:GetGridType() then
                self.Parent:ReturnUiGridToPool(uiGrid)
                self.Parent:RefreshNewGrid(gridData)
                uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
            end

            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:GridChangedAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end

        if gridData then
            -- 如果方块变更后类型发生了变化，需要替换UI
            if uiGrid:GetGridType() ~= gridData:GetGridType() then
                self.Parent:ReturnUiGridToPool(uiGrid)
                self.Parent:RefreshNewGrid(gridData)
                uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
            end

            if uiGrid then

                -- 如果方块的坐标发生了变化，则直接对齐
                local realX = gridData:GetX()
                local realY = gridData:GetY()
                
                local uiX = uiGrid:GetNormalizePosX()
                local uiY = uiGrid:GetNormalizePosY()

                if uiX ~= realX or uiY ~= realY then
                    -- 获取实际坐标的UI
                    local toIndex = realX + (realY - 1) * self._GameControl:GetWidth()
                    local fromIndex = uiX + (uiY - 1) * self._GameControl:GetWidth()

                    local fromBg = self.Parent:GetShowedUiGridByIndex(fromIndex)
                    local toBg = self.Parent:GetShowedUiGridByIndex(toIndex)

                    uiGrid.ActionCom:DoMove(fromBg.Transform, toBg.Transform, function()
                        uiGrid:SetNormalizePos(realX, realY)
                        uiGrid:RefreshData(gridData)
                        --tmp：先使用合成的动画表现，看后续是否有特殊表现指定
                        uiGrid.ActionCom:DoMerge(function()
                            self._GameControl.ActionsControl:EndAction(action)
                        end, true, action.MergeEffectType)
                    end)
                else
                    uiGrid:RefreshData(gridData)
                    --tmp：先使用合成的动画表现，看后续是否有特殊表现指定
                    uiGrid.ActionCom:DoMerge(function()
                        self._GameControl.ActionsControl:EndAction(action)
                    end, true, action.MergeEffectType)
                end
            else
                self._GameControl.ActionsControl:EndAction(action)
            end
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:FeverUpLevelUpAction(action)
    ---@type XUiGridGame2048Grid
    local uiGrid = self.Parent:GetShowedUiGridByUid(action.GridUidA)
    if uiGrid then
        local gridData = self._GameControl:GetGridEntityByUid(action.GridUidA)

        if action.TempGridData then
            action.TempGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
            gridData = action.TempGridData
        end
        
        if gridData then
            uiGrid:RefreshData(gridData)
            uiGrid.ActionCom:DoMerge(function()
                self._GameControl.ActionsControl:AddFeverLevelUpCheckAction(gridData.Id)
                self._GameControl.ActionsControl:EndAction(action)
            end, true, action.MergeEffectType)
        else
            self._GameControl.ActionsControl:EndAction(action)
        end
    else
        self._GameControl.ActionsControl:EndAction(action)
    end

    self:EnableGridUpSFX()
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:FeverLevelUpCheckAction(action)
    local dispelRule = self._Control:GetCurStageDispelRule()

    if dispelRule == XMVCA.XGame2048.EnumConst.GridDispelCleanUpRule.DiretionOnly then
        self._GameControl:DoFeverLevelUp()
        self._GameControl.ActionsControl:EndAction(action)
    elseif dispelRule == XMVCA.XGame2048.EnumConst.GridDispelCleanUpRule.WaterFireSelect then
        -- 判断是否有可以消除的方块
        if self._GameControl.GridsControl:CheckDispelRangeHasWaterOrFireGrid() then
            self.TxtSelectionTips.text = self._Control:GetClientConfigText('WaterFireSelectionTips')
            self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_WATER_FIRE_DISPEL_SELECTION)
            self._GameControl.ActionsControl:EndAction(action, true)
        else
            if self.ImgTips then
                self.ImgTips.gameObject:SetActiveEx(true)
            end
            self.TxtSelectionTips.text = self._Control:GetClientConfigText('NoWaterFireCanDispelTips')
            self:DelayCall(function()
                if self.ImgTips then
                    self.ImgTips.gameObject:SetActiveEx(false)
                end
                self._GameControl:DoFeverLevelUp()
                self._GameControl.ActionsControl:EndAction(action)
            end, self._Control:GetClientConfigNum('NoWaterFireCanDispelTipsTime'))
        end
    else
        XLog.Error('未知的消除规则: '..tostring(dispelRule))
        self._GameControl.ActionsControl:EndAction(action)
    end
end

--endregion <<<---------------------------------------------

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:FeverLevelUpAction(action)
    self._GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_FEVER_LEVELUP)
    XLuaUiManager.OpenWithCloseCallback('UiGame2048ToastLvUp', function()
        self._GameControl.ActionsControl:EndAction(action)
    end)
end

--region -------------------- 特效动画 -------------------->>>
function XUiComGame2048MapAction:UnDoAllAnimation()
    
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:OpenDispelRangeEffect(action)
    self.Parent.DispelMaskPanel:ShowDispelRangeEffect()
    self._GameControl.ActionsControl:EndAction(action)
end

---@param action XGame2048ActionParams
function XUiComGame2048MapAction:CloseDispelRangeEffect(action)
    self.Parent.DispelMaskPanel:HideDispelRangeEffect()
    self._GameControl.ActionsControl:EndAction(action)
end
--endregion <<<---------------------------------------------

--region 棋盘音效
function XUiComGame2048MapAction:HideAllSFX()
    self.SFX_GridUp.gameObject:SetActiveEx(false)
    self.SFX_GridMove.gameObject:SetActiveEx(false)
    self.SFX_GridBorn.gameObject:SetActiveEx(false)
end

function XUiComGame2048MapAction:ResetSFXLock()
    self._GridUpSFXPlaying = false
    self._GridMoveSFXPlaying = false
    self._GridBornSFXPlaying = false

    self:HideAllSFX()
end

function XUiComGame2048MapAction:EnableGridUpSFX()
    if not self._GridUpSFXPlaying then
        self._GridUpSFXPlaying = true
        self.SFX_GridUp.gameObject:SetActiveEx(true)
    end
end

function XUiComGame2048MapAction:EnableGridMoveSFX()
    if not self._GridMoveSFXPlaying then
        self._GridMoveSFXPlaying = true
        self.SFX_GridMove.gameObject:SetActiveEx(true)
    end
end

function XUiComGame2048MapAction:EnableGridBornSFX()
    if not self._GridBornSFXPlaying then
        self._GridBornSFXPlaying = true
        self.SFX_GridBorn.gameObject:SetActiveEx(true)
    end
end
--endregion

return XUiComGame2048MapAction
