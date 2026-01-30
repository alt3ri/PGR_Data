---@class XUiGridGame2048Grid: XUiNode
---@field _Control XGame2048Control
---@field ShakeTweener DG.Tweening.Tweener
---@field BlueArrow UnityEngine.Transform
local XUiGridGame2048Grid = XClass(XUiNode, 'XUiGridGame2048Grid')
local XUiComGame2048GridAction = require('XUi/XUiGame2048/UiGame2048Game/PanelMap/XUiComGame2048GridAction')

local FeverAddMax = nil
local BlueArrowAngle = {
    Up = 0,
    Left = 90,
    Down = 180,
    Right = 270,
}

function XUiGridGame2048Grid:OnStart()
    ---@type XUiComGame2048GridAction
    self.ActionCom = XUiComGame2048GridAction.New(self.GameObject, self)

    if XMain.IsEditorDebug then
        -- debug模式下方便配置表重载，每次加载都读
        FeverAddMax = self._Control:GetClientConfigNum('GridFeverAddMax')
    elseif not FeverAddMax then
        FeverAddMax = self._Control:GetClientConfigNum('GridFeverAddMax')
    end

    if self.BtnSelectDispel then
        self.BtnSelectDispel:AddEventListener(handler(self, self.OnBtnSelectDispelClickEvent))
        self.BtnSelectDispel.gameObject:SetActiveEx(false)
    end
    
    ---@type XGame2048GameControl
    self._GameControl = self._Control:GetGameControl()
end

--- 克隆的预制体的名称
function XUiGridGame2048Grid:SetCopyNameForDebug(copyName)
    self._CopyName = copyName
end

---@param data XGame2048Grid
function XUiGridGame2048Grid:RefreshData(data)
    self.Id = data.Id
    self.Uid = data.Uid

    if data:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.HeartShape then
        if self.GridPoint then
            self.GridPoint.transform.parent.gameObject:SetActiveEx(true)

            local curExValue = data:GetExValue()
            local maxExValue = self._Control.GameControl:GetHeartAddMax()
            
            self._GridPointList = XUiHelper.RefreshUiObjectList(self._GridPointList, self.GridPoint.transform.parent, self.GridPoint, maxExValue, function(index, grid)
                if grid.ImgOn then
                    grid.ImgOn.gameObject:SetActiveEx(index <= curExValue)
                end
            end)
        else
            XLog.Error('爱心方块缺少名为：GridPoint的UI引用')
        end
    end

    if self.TxtNum then
        self.TxtNum.gameObject:SetActiveEx(true)

        if data:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.Rock then
            self.TxtNum.text = data:GetValue()
        else
            self.TxtNum.text = data:GetShowLevel()
        end
    end

    if self.TxtNumEx then
        self.TxtNumEx.gameObject:SetActiveEx(true)
        self.TxtNumEx.text = data:GetExValue()
    end

    ---@type XTableGame2048Block
    local blockCfg = self._Control:GetBlockCfgById(self.Id)

    if self.Image then
        self.Image.gameObject:SetActiveEx(true)
        if blockCfg then
            if not string.IsNilOrEmpty(blockCfg.BgRes) then
                self.Image:SetRawImage(blockCfg.BgRes)
            end
        end
    end

    if self.ImgIcon then
        local hasIcon = not string.IsNilOrEmpty(blockCfg.IconRes)
        
        self.ImgIcon.gameObject:SetActiveEx(hasIcon)

        if hasIcon then
            self.ImgIcon:SetRawImage(blockCfg.IconRes)
        end
    end
    
    if self.BlueArrow then
        self.BlueArrow.gameObject:SetActiveEx(true)
        local eulerX, eulerY = self.BlueArrow.transform:GetLocalRotation()
        -- 旋转
        if data:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up then
            self.BlueArrow.transform:SetLocalRotation(eulerX, eulerY, BlueArrowAngle.Up)
        elseif data:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Left then
            self.BlueArrow.transform:SetLocalRotation(eulerX, eulerY, BlueArrowAngle.Left)
        elseif data:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Down then
            self.BlueArrow.transform:SetLocalRotation(eulerX, eulerY, BlueArrowAngle.Down)
        elseif data:GetExValue() == XMVCA.XGame2048.EnumConst.GridDispelDirection.Right then
            self.BlueArrow.transform:SetLocalRotation(eulerX, eulerY, BlueArrowAngle.Right)
        end
    end

    self:RefreshEffect(data:GetX(), data:GetY(), data:GetGridType())
end

function XUiGridGame2048Grid:RefreshEffect(x, y, gridType)
    if self.EffectDispelAimShow then
        if gridType ~= XMVCA.XGame2048.EnumConst.GridType.Dispel then
            self.EffectDispelAimShow.gameObject:SetActiveEx(self._GameControl.GridsControl:CheckGridIsInCleanUpRange(x, y))
        end
    end
end

function XUiGridGame2048Grid:RefreshAfterTurnEnd()
    self:RefreshEffect(self:GetNormalizePosX(), self:GetNormalizePosY(), self:GetGridType())
end

function XUiGridGame2048Grid:SetShow(blockId)
    ---@type XTableGame2048Block
    local cfg = self._Control:GetBlockCfgById(blockId)

    if cfg then
        if self.TxtNum then
            if cfg.Type == XMVCA.XGame2048.EnumConst.GridType.Rock then
                self.TxtNum.text = cfg.HitTimes
            else
                self.TxtNum.text = cfg.Level
            end
        end

        if self.Image then
            if not string.IsNilOrEmpty(cfg.BgRes) then
                self.Image:SetRawImage(cfg.BgRes)
            end
        end
    end
end

function XUiGridGame2048Grid:SetNormalizePos(x, y)
    self.X = x
    self.Y = y

    if XMain.IsEditorDebug then
        self.GameObject.name = 'Grid'..tostring(self.Id).."_"..tostring(self.X)..","..tostring(self.Y)..' [From: '..tostring(self._CopyName)..'][Type: '..tostring(self._GridType)..']'
    end
end

function XUiGridGame2048Grid:GetNormalizePosX()
    return self.X
end

function XUiGridGame2048Grid:GetNormalizePosY()
    return self.Y
end

function XUiGridGame2048Grid:SetGridType(type)
    self._GridType = type

    self.ActionCom:UpdateConfigParams(type)
end

function XUiGridGame2048Grid:GetGridType()
    return self._GridType
end

function XUiGridGame2048Grid:OnBtnSelectDispelClickEvent()
    -- 判断能否触发（防止多指或连点)
    if self._Control.GameControl:GetIsWaterFireSelected() then
        return
    end
    
    self._Control.GameControl:SetIsSelectWaterOrFire()
    
    local gridType = self:GetGridType()

    if self._Control.GameControl:CheckDebugEnable() then
        if self._Control.GameControl.DebugRecordControl:CheckIsPlayBack() then
            -- 如果是在回放，则按照回放的来
            gridType = self._Control.GameControl.DebugRecordControl:GetCurStepDispelSelectionType()
        elseif self._Control.GameControl.DebugRecordControl:CheckIsRecording() then
            -- 如果是在录制，则记录选择消除的类型
            self._Control.GameControl.DebugRecordControl:RecordCurWaterFireSelection(gridType)
        end
    end
    
    --todo: 临时复制，后面再优化
    self._Control.GameControl:DoFeverLevelUp(gridType)
    
    
    self._Control.GameControl.ActionsControl:StartActionList(function()
        self._Control.GameControl:RequestGame2048NextStep(function()
            self._Control.GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_MAPDATA_VERIFICATION)
            -- 检查游戏是否结束
            if self._Control.GameControl:CheckIsGameOver() then
                self._Control:RequestGame2048Settle(XMVCA.XGame2048.EnumConst.SettleType.CannotMove, function(res)
                    self._Control.GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_GAMEOVER, res, nil, self._Control:GetClientConfigNum('GameSettlePopDelay'))
                    self._Control.GameControl.BoardShowControl:OnStageEnd()
                end)
            end
        end)
    end)
    
    self._Control.GameControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_WATER_FIRE_DISPEL_SELECTION_EXIT)
end

function XUiGridGame2048Grid:OnWaterFireDispelSelectionEnter()
    if self.BtnSelectDispel then
        self.BtnSelectDispel.gameObject:SetActiveEx(true)
    end
end

function XUiGridGame2048Grid:OnWaterFireDispelSelectionExit()
    if self.BtnSelectDispel then
        self.BtnSelectDispel.gameObject:SetActiveEx(false)
    end
end

return XUiGridGame2048Grid