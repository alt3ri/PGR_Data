---@class XGame2048GameControl: XControl
---@field private _MergeEffectPool XPool
---@field _MainControl XGame2048Control
---@field _Model XGame2048Model
local XGame2048GameControl = XClass(XControl, 'XGame2048GameControl', true)

local BoardConstWidth = 4
local BoardConstHeight = 4
local FeverAddMax = nil
local HeartAddMax = nil
local GameScoreMaxLimit = 0

local __IsDebug = false

local CSRandom = CS.System.Random

function XGame2048GameControl:OnInit()
    self._DebugOpenCache = XSaveTool.GetData('Game2048Debug')
    
    self._MergeEffectPool = XPool.New(function() 
        return {}
    end, function(effect)
        effect.LinkGrid = nil
        effect.Type = nil
    end)
    
    self._MergeEffectList = {}
    
    ---@type XGame2048ActionsControl
    self.ActionsControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048ActionsControl'))
    ---@type XGame2048TurnControl
    self.TurnControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048TurnControl'))
    ---@type XGame2048BoardShowControl
    self.BoardShowControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048BoardShowControl'))
    ---@type XGame2048GridsControl
    self.GridsControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048GridsControl'))
    ---@type XGame2048RecordReportControl
    self.RecordReportControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048RecordReportControl'))

    if self:CheckDebugEnable() then
        ---@type XGame2048DebugRecordControl
        self.DebugRecordControl = self:AddSubControl(require('XModule/XGame2048/InGame/XGame2048DebugRecordControl'))
    end
    
    self._LockMoveGridList = {}

    FeverAddMax = self._MainControl:GetClientConfigNum('GridFeverAddMax')
    HeartAddMax = self._MainControl:GetClientConfigNum('GridHeartAddMax')
    GameScoreMaxLimit = self._MainControl:GetClientConfigNum('GameScoreMaxLimit')
    
    self._NeedTransmit = false
    self._NeedDispelToTarget = false
    self._IsWaterFireSelected = false
    
    self:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_WATER_FIRE_DISPEL_SELECTION, self.EnterWaterFireDispelSelectionState, self)
end

function XGame2048GameControl:OnRelease()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System)
end

function XGame2048GameControl:CheckDebugEnable()
    -- debug环境下，代码手动开启，或者通过控制台开启
    return XMain.IsEditorDebug and (__IsDebug or self._DebugOpenCache)
end

function XGame2048GameControl:ResumeCurInputMap()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System)
end

--region 游戏初始化
function XGame2048GameControl:InitGame(stageContext)
    self.TurnControl:InitOnNewGame(stageContext)

    self._StageId = self._MainControl:GetCurStageId()
    self._Width = BoardConstWidth
    self._Height = BoardConstHeight
    self._BlockCount = self._Width * self._Height
    self:InitGrids()
    self._MainControl:MarkStageLastMaxScore(self._StageId)
    self._MainControl:MarkStageLastMaxBlockNum(self._StageId)
    self.ActionsControl:InitActions()
    self.BoardShowControl:SetCurStageShowConfigId(self._MainControl:GetStageBoardShowGroupId(self._StageId))

    local randomSeed = os.time()
    self:InitRandom(randomSeed)
    
    if self:CheckDebugEnable() then
        if self.DebugRecordControl:CheckIsRecordEnable() and not self.DebugRecordControl:CheckIsPlayBack() then
            self.DebugRecordControl:StartRecord()
            self.DebugRecordControl:RecordRandomSeed(randomSeed)
        end
    end
    
    self._GameState = XMVCA.XGame2048.EnumConst.GameState.None
    
    self.RecordReportControl:OnInitGame()
end

function XGame2048GameControl:InitGrids()
    self._UidPool = 1
    -- 重置
    self.GridsControl:InitGrids()
end

function XGame2048GameControl:InitRandom(seed)
    self.CustomRandom = CSRandom(seed)
end
--endregion

--region Getter
function XGame2048GameControl:CheckCanDragState()
    return self._GameState == XMVCA.XGame2048.EnumConst.GameState.None or not self._GameState
end

function XGame2048GameControl:GetIsWaterFireSelected()
    return self._IsWaterFireSelected
end

function XGame2048GameControl:GetFeverAddMax()
    return FeverAddMax
end

function XGame2048GameControl:GetHeartAddMax()
    return HeartAddMax
end

function XGame2048GameControl:GetGameScoreMaxLimit()
    return GameScoreMaxLimit
end

function XGame2048GameControl:GetWidth()
    return self._Width or 0
end

function XGame2048GameControl:GetHeight()
    return self._Height or 0
end

function XGame2048GameControl:GetNewUid()
    local newUid = self._UidPool
    self._UidPool = self._UidPool + 1
    return newUid
end

function XGame2048GameControl:GetGridEntities()
    return self.GridsControl:GetGridEntities()
end

function XGame2048GameControl:GetGridEntitiesCount()
    return self.GridsControl:GetGridEntitiesCount()
end

function XGame2048GameControl:GetGridEntityByUid(uid)
    return self.GridsControl:GetGridEntityByUid(uid)
end

--- 获取棋盘上最高分数方块的数值，用于fever进度展示
function XGame2048GameControl:GetMaxValueFromGridEntities()
    return self.GridsControl:GetMaxValueFromGridEntities()
end

function XGame2048GameControl:GetIsActionPlaying()
    return self.ActionsControl:GetIsActionPlaying()
end

function XGame2048GameControl:GetIsUsingProp()
    return self._IsUsingProp
end

function XGame2048GameControl:GetIsWaitForNextStep()
    return self._IsWaitForNextStep
end

function XGame2048GameControl:GetCurBoardId()
    ---@type XTableGame2048Stage
    local stageCfg = self._Model:GetGame2048StageCfgById(self._StageId)

    if stageCfg then
        return stageCfg.BoardId
    end
end

function XGame2048GameControl:GetStageId()
    return self._StageId
end
--endregion

--region Setter

function XGame2048GameControl:EnterWaterFireDispelSelectionState()
    self._GameState = XMVCA.XGame2048.EnumConst.GameState.WaterFireSelection
end

function XGame2048GameControl:ExitWaterFireDispelSelectionState()
    self._GameState = XMVCA.XGame2048.EnumConst.GameState.None
end

function XGame2048GameControl:SetIsSelectWaterOrFire()
    self._IsWaterFireSelected = true
end
--endregion

--region 2048 rules

function XGame2048GameControl:CheckIsGameOver()
    -- 分数到达上限，无论棋盘状态如何，都强制结算
    local curScore = self.TurnControl:GetCurScore()

    if curScore >= GameScoreMaxLimit then
        return true
    end
    
    -- 棋盘满了是前提
    if self:GetGridEntitiesCount() == self._BlockCount then
        -- 简单检查每个可合成的格子，是否能和它四周的格子进行合成
        for i, v in pairs(self.GridsControl:GetGridEntities()) do
            local gridX = v:GetX()
            local gridY = v:GetY()
            
            local left = self.GridsControl:GetGridEntityByNormalizePos(gridX - 1, gridY)
            local right = self.GridsControl:GetGridEntityByNormalizePos(gridX + 1, gridY)
            local up = self.GridsControl:GetGridEntityByNormalizePos(gridX, gridY + 1)
            local down = self.GridsControl:GetGridEntityByNormalizePos(gridX, gridY - 1)

            if left and self:_CheckCanMerge(v, left, true) then
                return false
            end

            if right and self:_CheckCanMerge(v, right, true) then
                return false
            end

            if up and self:_CheckCanMerge(v, up, true) then
                return false
            end

            if down and self:_CheckCanMerge(v, down, true) then
                return false
            end
        end
        return true
    else
        -- 普通关卡，fever等级达上限，且合成了最大方块
        if self._MainControl:GetStageTypeById(self._StageId) == XMVCA.XGame2048.EnumConst.StageType.Normal then
            if not self.TurnControl:CheckHasNextTarget() and self:GetMaxValueFromGridEntities() >= self.TurnControl:GetCurTargetMergeValue() then
                return true
            end
        end
        
        return not self:CheckCanMoveOrMerge()
    end
end

function XGame2048GameControl:CheckCanMoveOrMerge()
    if self:_CheckCanMoveOrMerge(1, 0) then
        return true
    end

    if self:_CheckCanMoveOrMerge(-1, 0) then
        return true
    end

    if self:_CheckCanMoveOrMerge(0, 1) then
        return true
    end

    if self:_CheckCanMoveOrMerge(0, -1) then
        return true
    end

    return false
end

function XGame2048GameControl:_CheckCanMoveOrMerge(x, y)
    local width = self._Width
    local height = self._Height

    --合并检查索引方向
    local beginX = x > 0 and width or 1
    local beginY = y > 0 and height or 1
    local endX = x > 0 and 1 or width
    local endY = y > 0 and 1 or height

    -- 所有可移动的实体，判断它们能否向指定方向移动一次
    if x ~= 0 then
        -- 逐行检查
        for ty = 1, height do
            for tx = beginX, endX, -x do
                local nextX = tx - x
                local nextY = ty

                if nextX < 1 or nextX > self._Width or nextY < 1 or nextY > self._Height then
                    goto CONTINUE_MOVE_H
                end

                local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(nextX, nextY)

                if curGrid == nil and nextGrid and nextGrid:IsMoveableGrid() then
                    -- 存在可移动
                    return true
                end

                :: CONTINUE_MOVE_H ::
            end
        end
    else
        -- 逐列检查
        for tx = 1, width do
            for ty = beginY, endY, -y do
                local nextX = tx
                local nextY = ty - y

                if nextX < 1 or nextX > self._Width or nextY < 1 or nextY > self._Height then
                    goto CONTINUE_MOVE_V
                end

                local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(nextX, nextY)

                if curGrid == nil and nextGrid and nextGrid:IsMoveableGrid() then
                    -- 存在可移动
                    return true
                end

                :: CONTINUE_MOVE_V ::
            end
        end
    end

    -- 检查常规实体是否能合成
    if x ~= 0 then
        -- 逐行检查
        for ty = 1, height do
            for tx = beginX, endX, -x do
                local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(tx - x, ty)

                if curGrid and nextGrid then
                    if self:_CheckCanMerge(curGrid, nextGrid, true) then
                        return true
                    end
                end
            end
        end
    else
        -- 逐列检查
        for tx = 1, width do
            for ty = beginY, endY, -y do
                local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty - y)

                if curGrid and nextGrid then
                    if self:_CheckCanMerge(curGrid, nextGrid, true) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

--- 外部调用，完成一次滑动后，参数表明滑动方向，互斥
function XGame2048GameControl:DoMove(x, y)
    -- 如果是在回放模式，那么执行回放的操作即可
    if self:CheckDebugEnable() and self.DebugRecordControl:CheckIsPlayBack() then
        x, y = self.DebugRecordControl:GetCurStepMove()
    end
    
    -- 移动方向为互斥
    if XTool.IsNumberValid(x) and XTool.IsNumberValid(y) then
        XLog.Error('2048同时存在两个方向的变化')
        return
    end
    -- 修正非数值    
    x = x == nil and 0 or x
    y = y == nil and 0 or y

    -- 数值标准化
    if x > 0 then
        x = 1
    elseif x < 0 then
        x = -1
    end

    if y > 0 then
        y = 1
    elseif y < 0 then
        y = -1
    end

    -- 执行移动
    if self:_DoMove(x, y) then
        -- 只有确实发生了移动或合成，该操作才有效，才能继续执行其他的判断
        -- 执行实体自身效果
        self:_DoRockReduce(x, y)
        self:_DoDoublingEffect()
        self:_DoTransferEffect()
        self:_DoGridDispelTransmit()
        self:_DoGridDispelLevelUpToTarget()
        
        -- 记录当前回合的移动方向
        if self:CheckDebugEnable() and self.DebugRecordControl:CheckIsRecording() then
            self.DebugRecordControl:RecordCurStepMoveDire(x, y)
        end
        
        return true
    end
    return false
end

function XGame2048GameControl:_DoMove(x, y)
    -- 记录是否发生过移动或合成
    local hasAnyAction = false
    -- 记录循环内一次操作是否存在至少一个实体发生变化
    local hasAction = false
    local width = self._Width
    local height = self._Height

    --合并检查索引方向
    local beginX = x > 0 and width or 1
    local beginY = y > 0 and height or 1
    local endX = x > 0 and 1 or width
    local endY = y > 0 and 1 or height

    -- 二期新规：单次最多发生一次合成. 通过字段控制流程为： 移动-合成-移动 三步
    local hasTryMerge = false
    local hasAnyMove = false
    repeat
        hasAction = false

        -- 二期单次合成新规：在检查合成之前需要一直移动直到没有方块可以移动
        repeat
            hasAnyMove = false
            -- 所有可移动的实体，让它们向指定方向移动一次
            if x ~= 0 then
                -- 逐行检查
                for ty = 1, height do
                    for tx = beginX, endX, -x do
                        local nextX = tx - x
                        local nextY = ty

                        if nextX < 1 or nextX > self._Width or nextY < 1 or nextY > self._Height then
                            goto CONTINUE_MOVE_H
                        end
                        
                        local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                        local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(nextX, nextY)

                        if curGrid == nil and nextGrid and nextGrid:IsMoveableGrid() and not nextGrid:GetIsMoveLock() then
                            -- 移动
                            self.GridsControl:SetGridEntityToAimPos(nextGrid, tx, ty)
                            
                            hasAction = true
                            hasAnyAction = true
                            hasAnyMove = true

                            -- 添加移动行为
                            self.ActionsControl:AddMoveAction(nextGrid.Uid, nextX, nextY, tx, ty)
                        end

                        :: CONTINUE_MOVE_H ::
                    end
                end
            else
                -- 逐列检查
                for tx = 1, width do
                    for ty = beginY, endY, -y do
                        local nextX = tx
                        local nextY = ty - y

                        if nextX < 1 or nextX > self._Width or nextY < 1 or nextY > self._Height then
                            goto CONTINUE_MOVE_V
                        end
                        
                        local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                        local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(nextX, nextY)

                        if curGrid == nil and nextGrid and nextGrid:IsMoveableGrid() and not nextGrid:GetIsMoveLock() then
                            -- 移动
                            self.GridsControl:SetGridEntityToAimPos(nextGrid, tx, ty)
                            
                            hasAction = true
                            hasAnyAction = true
                            hasAnyMove = true

                            -- 添加移动行为
                            self.ActionsControl:AddMoveAction(nextGrid.Uid, nextX, nextY, tx, ty)
                        end

                        :: CONTINUE_MOVE_V ::
                    end
                end
            end
            
        until not hasAnyMove

        if hasTryMerge then
            break
        end
        
        -- 检查常规实体是否能合成
        if x ~= 0 then
            -- 逐行检查
            for ty = 1, height do
                for tx = beginX, endX, -x do
                    local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                    local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(tx - x, ty)

                    if curGrid and nextGrid then
                        if self:_CheckCanMerge(curGrid, nextGrid) then
                            -- 添加移动行为
                            self.ActionsControl:AddMoveAction(nextGrid.Uid, (tx - x), ty, tx, ty, curGrid.Uid)
                            hasAction = true
                            hasAnyAction = true
                        end
                    end
                end
            end
        else
            -- 逐列检查
            for tx = 1, width do
                for ty = beginY, endY, -y do
                    local curGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty)
                    local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(tx, ty - y)
                    
                    if curGrid and nextGrid then
                        if self:_CheckCanMerge(curGrid, nextGrid) then
                            -- 添加移动行为
                            self.ActionsControl:AddMoveAction(nextGrid.Uid, tx, ty - y, tx, ty, curGrid.Uid)
                            hasAction = true
                            hasAnyAction = true
                        end
                        
                    end
                end
            end
        end

        hasTryMerge = true

    until not hasAction


    -- 完成移动后需要给锁定移动的格子解锁
    if not XTool.IsTableEmpty(self._LockMoveGridList) then
        for i = #self._LockMoveGridList, 1, -1 do
            local grid = self._LockMoveGridList[i]

            if grid then
                grid:SetMoveLock(false)
                table.remove(self._LockMoveGridList, i)
            end
        end
    end
    
    return hasAnyAction
end

function XGame2048GameControl:_DoRockReduce(x, y)
    -- 检查场上所有石头，如果它们在滑动方向的反方向挨着其他格子的话，则降级
    local gridEntities = self.GridsControl:GetGridEntities()
    
    if not XTool.IsTableEmpty(gridEntities) then
        local needDispelRockList = nil
        ---@param v XGame2048Grid
        for i, v in pairs(gridEntities) do
            if v:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.Rock then
                local curX = v:GetX()
                local curY = v:GetY()
                local nextX = curX - x
                local nextY = curY - y
                
                local nextGrid = self.GridsControl:GetGridEntityByNormalizePos(nextX, nextY)
                
                if nextGrid ~= nil then
                    -- 除了石头、冰块不能动外，其他方块都可以作为撞击源
                    local nextGridType = nextGrid:GetGridType()

                    if nextGridType ~= XMVCA.XGame2048.EnumConst.GridType.Rock and nextGridType ~= XMVCA.XGame2048.EnumConst.GridType.ICE then
                        -- 记录石头撞击降级动画
                        self.ActionsControl:AddRockReduceAction(v.Uid)
                        self.ActionsControl:AddRockShakeAction(v.Uid)
                        v:SetValue(v:GetValue() - 1)
                        if v:GetValue() <= 0 then
                            needDispelRockList = needDispelRockList or {}
                            table.insert(needDispelRockList, v)
                        end
                    end
                end
            end
        end

        if not XTool.IsTableEmpty(needDispelRockList) then
            for i, v in pairs(needDispelRockList) do
                -- 记录石头的消除动画
                self.ActionsControl:AddDispelAction(v.Uid)
                self:DoDispel(v)
                self:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA)
            end
        end
    end
end

function XGame2048GameControl:_DoDoublingEffect()
    local gridEntities = self.GridsControl:GetGridEntities()
    
    for i = #self._MergeEffectList, 1, -1 do
        local effect = self._MergeEffectList[i]

        -- 需要检查效果锁关联的方块是否还存在
        if effect.LinkGrid and table.contains(gridEntities, effect.LinkGrid) and effect.Type == XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling then
            local effectGrid = effect.LinkGrid
            -- 依次访问四个方向的方块，针对数字方块及传导方块，如果可以升级则让它们直接升级
            local left = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX() - 1, effectGrid:GetY())

            if left and not self:CheckGridLevelIsMaxInCurBoradLevel(left.Id) then
                self:_DoDoublingLevelUp(left)
            end

            local right = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX() + 1, effectGrid:GetY())

            if right and not self:CheckGridLevelIsMaxInCurBoradLevel(right.Id) then
                self:_DoDoublingLevelUp(right)
            end

            local up = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX(), effectGrid:GetY() + 1)

            if up and not self:CheckGridLevelIsMaxInCurBoradLevel(up.Id) then
                self:_DoDoublingLevelUp(up)
            end

            local down = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX(), effectGrid:GetY() - 1)

            if down and not self:CheckGridLevelIsMaxInCurBoradLevel(down.Id) then
                self:_DoDoublingLevelUp(down)
            end
            
            -- 执行完后移除该效果
            table.remove(self._MergeEffectList, i)
        end
    end
end

function XGame2048GameControl:_DoTransferEffect()
    local hasAnyEffectValid = false
    local gridEntities = self.GridsControl:GetGridEntities()
    
    for i = #self._MergeEffectList, 1, -1 do
        local effect = self._MergeEffectList[i]

        -- 需要检查效果锁关联的方块是否还存在
        if effect.LinkGrid and table.contains(gridEntities, effect.LinkGrid) and effect.Type == XMVCA.XGame2048.EnumConst.MergeEffectType.Transfer then
            local effectGrid = effect.LinkGrid
            -- 依次访问四个方向的方块，针对传导方块，如果可以升级则让它们直接升级

            local left = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX() - 1, effectGrid:GetY())

            if left then
                if self:_DoTransferLevelUp(left) then
                    hasAnyEffectValid = true
                end
            end

            local right = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX() + 1, effectGrid:GetY())

            if right then
                if self:_DoTransferLevelUp(right) then
                    hasAnyEffectValid = true
                end
            end

            local up = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX(), effectGrid:GetY() + 1)

            if up then
                if self:_DoTransferLevelUp(up) then
                    hasAnyEffectValid = true
                end
            end

            local down = self.GridsControl:GetGridEntityByNormalizePos(effectGrid:GetX(), effectGrid:GetY() - 1)

            if down then
                if self:_DoTransferLevelUp(down) then
                    hasAnyEffectValid = true
                end
            end

            -- 执行完后移除该效果
            table.remove(self._MergeEffectList, i)
        end
    end

    if hasAnyEffectValid then
        -- 如果传导成功，则需要重复检查，直到所有可传导的方块完成传导
        self:_DoTransferEffect()
    end
end

---@param grid XGame2048Grid
function XGame2048GameControl:_DoDoublingLevelUp(grid)
    local gridType = grid:GetGridType()
    if gridType == XMVCA.XGame2048.EnumConst.GridType.Normal then
        local levelUpId = grid:GetLevelUpId()
        -- 如果是数字方块，直接按照配置的levelUpId进行升级
        if XTool.IsNumberValid(levelUpId) then
            local newcfg = self._MainControl:GetBlockCfgById(levelUpId)
            local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)

            grid:SetNewConfig(newcfg, blockTypeCfg)

            self.ActionsControl:AddNormalLevelUpAction(grid.Uid, XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling)

            self:AddTransferEffect(grid)
        end
    elseif gridType == XMVCA.XGame2048.EnumConst.GridType.Transfer then
        -- 传导方块的升级需要读另外的字段
        local levelUpId = grid:GetDoublingLevelUpId()

        if XTool.IsNumberValid(levelUpId) then
            local newcfg = self._MainControl:GetBlockCfgById(levelUpId)
            local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)

            grid:SetNewConfig(newcfg, blockTypeCfg)

            self.ActionsControl:AddTransferLevelUpAction(grid.Uid, XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling)

            self:AddTransferEffect(grid)
        end
    elseif gridType == XMVCA.XGame2048.EnumConst.GridType.ICE then
        local levelUpId = grid:GetLevelUpId()
        -- 如果是冰块方块，直接按照配置的levelUpId进行升级
        if XTool.IsNumberValid(levelUpId) then
            local newcfg = self._MainControl:GetBlockCfgById(levelUpId)
            local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)

            grid:SetNewConfig(newcfg, blockTypeCfg)

            self.ActionsControl:AddICELevelUpAction(grid.Uid, XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling)

            self:AddTransferEffect(grid)
        end
    elseif gridType == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds then
        -- 加时方块升级后，加时累计+1
        local levelUpId = grid:GetLevelUpId()

        if XTool.IsNumberValid(levelUpId) then
            local newcfg = self._MainControl:GetBlockCfgById(levelUpId)
            local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)
            local exValue = grid:GetExValue()

            grid:SetNewConfig(newcfg, blockTypeCfg)

            if exValue < FeverAddMax then
                grid:SetExValue(exValue + 1)
            end
            self.ActionsControl:AddFeverUpLevelUpAction(grid.Uid, XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling)

            self:AddTransferEffect(grid)
        end
    end
end

function XGame2048GameControl:_DoTransferLevelUp(grid)
    local gridType = grid:GetGridType()

    if gridType == XMVCA.XGame2048.EnumConst.GridType.Transfer then
        -- 保底限制传导方块不可超越目标分数升级
        if self:CheckGridLevelIsMaxInCurBoradLevel(grid.Id) then
            return false
        end
        
        -- 传导方块的升级需要读另外的字段
        local levelUpId = grid:GetDoublingLevelUpId()

        if XTool.IsNumberValid(levelUpId) then
            local newcfg = self._MainControl:GetBlockCfgById(levelUpId)
            local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)

            grid:SetNewConfig(newcfg, blockTypeCfg)

            self.ActionsControl:AddTransferLevelUpAction(grid.Uid, XMVCA.XGame2048.EnumConst.MergeEffectType.Transfer)

            self:AddTransferEffect(grid)
            
            return true
        end
    end
    
    return false
end

---@param curGrid XGame2048Grid
---@param nextGrid XGame2048Grid
---@param onlyCheck @仅作可行性检查，不执行合成
function XGame2048GameControl:_CheckCanMerge(curGrid, nextGrid, onlyCheck)
    if not curGrid:IsMergeable() or not nextGrid:IsMergeable() then
        return false
    end
    
    local gridTypeA = curGrid:GetGridType()
    local gridTypeB = nextGrid:GetGridType()
    
    local curExValue = curGrid:GetExValue()
    local nextExValue = nextGrid:GetExValue()

    -- 涉及冰块合成，冰块不能在滑动方
    if gridTypeB == XMVCA.XGame2048.EnumConst.GridType.ICE then
        return false
    end

    -- 类型仅作可合成判断，且无先后限制，按照类型Id大小排序，减少判断情况
    -- 约定A <= B
    if gridTypeB < gridTypeA then
        local tmpType = gridTypeB
        gridTypeB = gridTypeA
        gridTypeA = tmpType
    end
    
    ---@type XTableGame2048BlockType
    local typeACfg = self._Model:GetGame2048BlockTypeCfgByType(gridTypeA)

    if typeACfg then
        local resultType = typeACfg.MergeResults[gridTypeB]
        
        -- 水火方块间的合成特殊处理：目前只有这一种特殊情况，先不扩展配置表
        -- 因为按照类型的值排序，所以水火方块合成一定是a水b火
        if gridTypeA == XMVCA.XGame2048.EnumConst.GridType.Water and gridTypeB == XMVCA.XGame2048.EnumConst.GridType.Fire then
            local randValue = self.CustomRandom:Next(0, 100)
            -- 等权随机
            resultType = randValue >= 50 and XMVCA.XGame2048.EnumConst.GridType.Water or XMVCA.XGame2048.EnumConst.GridType.Fire
        end
        
        if XTool.IsNumberValid(resultType) then
            -- 类型间可合成
            -- 判断具体格子是否可合成：数值相同，或星星存在星星方块
            if curGrid:GetValue() == nextGrid:GetValue() or (gridTypeA == XMVCA.XGame2048.EnumConst.GridType.Star or gridTypeB == XMVCA.XGame2048.EnumConst.GridType.Star) then
                -- 自己不能和自己合并
                if curGrid.Uid == nextGrid.Uid then
                    XLog.Error("方块不可与自己合成")
                else
                    if not onlyCheck then
                        -- 合并
                        local isMergeSuccess = self:_DoMerge(curGrid, nextGrid, curGrid:GetGridType() == resultType and curGrid or nextGrid)

                        if not isMergeSuccess then
                            return false
                        end

                        -- 如果有翻倍方块，则记录效果
                        if gridTypeA == XMVCA.XGame2048.EnumConst.GridType.Doubling or gridTypeB == XMVCA.XGame2048.EnumConst.GridType.Doubling then
                            self:AddDoublingEffect(curGrid)
                        end

                        -- 如果合成的方块是冰块方块，需要锁定移动
                        if gridTypeA == XMVCA.XGame2048.EnumConst.GridType.ICE or gridTypeB == XMVCA.XGame2048.EnumConst.GridType.ICE then
                            curGrid:SetMoveLock(true)
                            table.insert(self._LockMoveGridList, curGrid)
                        end

                        -- 合成方块存在加时方块，且合成后的方块也是加时方块，则该方块fever累积值+1（最大值为FeverAddMax 
                        if (gridTypeA == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds or gridTypeB == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds) and curGrid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds then
                            local summary = curExValue + nextExValue

                            if summary < FeverAddMax then
                                curGrid:SetExValue(summary + 1)
                            else
                                curGrid:SetExValue(FeverAddMax)
                            end
                        end

                        -- 原方块是冰块+传导时，增加额外计数
                        if gridTypeA == XMVCA.XGame2048.EnumConst.GridType.ICE and gridTypeB == XMVCA.XGame2048.EnumConst.GridType.Transfer then
                            curGrid:SetExValue(1)
                        elseif gridTypeA == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds and gridTypeB == XMVCA.XGame2048.EnumConst.GridType.ICE then
                            local summary = curExValue + nextExValue

                            if summary < FeverAddMax - 1 then
                                curGrid:SetExValue(summary + 2)
                            else
                                curGrid:SetExValue(FeverAddMax)
                            end
                        end
                        
                        -- 消除方块与其他方块合成时，保留消除方块的额外数据
                        if nextGrid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.Dispel then
                            curGrid:SetExValue(nextGrid:GetExValue())
                        end
                        
                        -- 合成原方块里包含传送方块，则触发一次传送
                        if gridTypeA == XMVCA.XGame2048.EnumConst.GridType.Transmit or gridTypeB == XMVCA.XGame2048.EnumConst.GridType.Transmit then
                            self._NeedTransmit = true
                        end
                        
                        -- 使用局部变量，是因为同时满足爱心方块效果和消除方块合成时，防止冲突
                        local needDispelToTargetThisTime = false

                        -- 合成方块存在爱心方块，且合成后的方块也是爱心方块，则该方块fever累积值+1（最大值为FeverAddMax 
                        if (gridTypeA == XMVCA.XGame2048.EnumConst.GridType.HeartShape or gridTypeB == XMVCA.XGame2048.EnumConst.GridType.HeartShape) and curGrid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.HeartShape then
                            local summary = curExValue + nextExValue

                            if summary < HeartAddMax then
                                curGrid:SetExValue(summary + 1)
                            else
                                curGrid:SetExValue(HeartAddMax)
                            end

                            if curGrid:GetExValue() >= HeartAddMax then
                                -- 触发消除方块升级效果
                                self._NeedDispelToTarget = true
                                needDispelToTargetThisTime = true
                            end
                        end

                        -- 添加合并行为
                        self.ActionsControl:AddMergeAction(nextGrid.Uid, curGrid.Uid, curGrid.Id)

                        if needDispelToTargetThisTime then
                            -- 清除累计，并播放动画更新状态，时机和消除方块升级一致
                            curGrid:SetExValue(0)
                            self.ActionsControl:AddGridChangedAction(curGrid.Uid, XMVCA.XGame2048.EnumConst.ActionType.GridChangedAfterDoubleLevelUp)
                        end
                    else
                        local upgradeFrom = curGrid:GetGridType() == resultType and curGrid or nextGrid
                        local levelUpId = self._MainControl:GetBlockLevelUpId(upgradeFrom.Id)
                        
                        return XTool.IsNumberValid(levelUpId)
                    end
                    
                    return true
                end
            end
        end
    end
    
    return false
end

---@param upgradeGrid XGame2048Grid
function XGame2048GameControl:_DoMerge(upgradeGrid, dispelGrid, upgradeFrom)
    local levelUpId = self._MainControl:GetBlockLevelUpId(upgradeFrom.Id)

    if XTool.IsNumberValid(levelUpId) then
        local newcfg = self._MainControl:GetBlockCfgById(levelUpId)
        
        local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)

        self:RemoveGridAndMarkAsWaste(dispelGrid)
        
        upgradeGrid:SetNewConfig(newcfg, blockTypeCfg)
        
        -- 加分
        self.TurnControl:AddScore(upgradeGrid:GetScore())
        
        return true
    end
    
    return false
end

---@param bombGrid XGame2048Grid
function XGame2048GameControl:DoDispel(bombGrid, isTurnBegin)
    self:RemoveGridAndMarkAsWaste(bombGrid, isTurnBegin)
    
    -- 方块消除需要增加它们携带的分数
    local scoreAdds = bombGrid:GetScore()

    if XTool.IsNumberValid(scoreAdds) then
        self.TurnControl:AddScore(bombGrid:GetScore(), isTurnBegin)
    end
    
    -- 如果是加时方块，需要增加fever持续回合数
    if bombGrid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds then
        local turnsAdds = bombGrid:GetExValue()

        if XTool.IsNumberValid(turnsAdds) then
            self.TurnControl:AddFeverLeftRound(turnsAdds)
        end
    end
end

---@param firstIntoGame @是否是在外面重新进入游戏时的检查
function XGame2048GameControl:DoBuff(firstIntoGame)
    
end

function XGame2048GameControl:CheckFerverLevelUp(newGridId)
    local targetId = self.TurnControl:GetCurTargetBlockId()

    ---@type XTableGame2048Block
    local targetBlockCfg = self._Model:GetGame2048BlockCfgById(targetId)
    ---@type XTableGame2048Block
    local newBlockCfg = self._Model:GetGame2048BlockCfgById(newGridId)
    
    -- 要先判断方块是否是消除方块
    if not (newBlockCfg.Type == XMVCA.XGame2048.EnumConst.GridType.Dispel) then
        return false
    end
    
    if targetBlockCfg and newBlockCfg and targetBlockCfg.Level == newBlockCfg.Level then
        return true
    end
    
    return false
end

---@param targetType @消除指定类型的方块
function XGame2048GameControl:DoFeverLevelUp(targetType)
    local targetId = self.TurnControl:GetCurTargetBlockId()

    ---@type XTableGame2048Block
    local targetBlockCfg = self._Model:GetGame2048BlockCfgById(targetId)

    if self:CheckDebugEnable() then
        self:PrintGridsInBoardLogForDebug()
    end

    local isWaterFireSelect = self._MainControl:GetCurStageDispelRule() == XMVCA.XGame2048.EnumConst.GridDispelCleanUpRule.WaterFireSelect

    -- 消除棋盘方块
    -- 1. 消除方块不消除
    -- 2. 与消除方块方向上的行或列方块消除
    -- 3. 水火方块指定消除

    local feverTurnsAddsFromGrid = 0

    local gridEntities = self.GridsControl:GetGridEntities()

    ---@type XGame2048Grid
    local dispelGrid = nil
    local beginX, endX, beginY, endY = 0, 0, 0, 0
    
    if not XTool.IsTableEmpty(gridEntities) then
        -- 克隆一份列表用于迭代
        local gridPairs = {}

        -- 加时方块满足分数的个数
        local feverUpBlockNum = 0
        -- 所有满足分数的方块个数
        local totalSatisfyNum = 0

        -- 找到符合规则1的所有方块进行消除
        ---@type XGame2048Grid
        dispelGrid = self.GridsControl:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)
        
        beginX, endX, beginY, endY = self.GridsControl:GetDispelGridCleanUpRange(dispelGrid)
        
        for x = beginX, endX do
            for y = beginY, endY do
                local grid = self.GridsControl:GetGridEntityByNormalizePos(x, y)

                if grid and grid ~= dispelGrid then
                    -- 判断是否指定方块
                    if targetType and grid:GetGridType() ~= targetType then
                        goto CONTINUE_1
                    end
                    
                    table.insert(gridPairs, grid)

                    if grid:GetValue() == targetBlockCfg.Level then
                        totalSatisfyNum = totalSatisfyNum + 1

                        if grid:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds then
                            feverUpBlockNum = feverUpBlockNum + 1
                        end
                    end
                end
                
                :: CONTINUE_1 ::
            end
        end

        -- 埋点记录
        self.RecordReportControl:CollectDispelInfo(beginX, endX, beginY, endY, gridPairs, isWaterFireSelect, targetType)

        -- 执行消除操作
        ---@param v XGame2048Grid
        for i, v in pairs(gridPairs) do
            -- 加时方块需要消耗积攒的加时值进行fever加时
            if v:GetGridType() == XMVCA.XGame2048.EnumConst.GridType.FeverTurnAdds then
                local exValue = v:GetExValue()

                if XTool.IsNumberValid(exValue) then
                    feverTurnsAddsFromGrid = feverTurnsAddsFromGrid + exValue
                    v:SetExValue(0)
                end
            end

            -- 消除
            self.ActionsControl:AddDispelAction(v.Uid)
            self:DoDispel(v)

            :: CONTINUE ::
        end
        
        -- 插入消除范围特效显示动画
        self.ActionsControl:AddDispelRangeEffectAction(true)
        self.ActionsControl:AddDispelRangeEffectAction(false)
    end

    -- 有下一级配置才能升级
    if self.TurnControl:CheckHasNextTarget() then
        -- 盘面等级升级
        self.ActionsControl:AddFeverLevelUpAction()
        self.TurnControl:BoardLevelUp()

        self.BoardShowControl:OnFerverLevelUpEvent()

        -- 检查剩下存活的方块等级，是否比新盘面等级的最低生成方块等级还低
        local minGeneratedLevel = self.TurnControl:GetCurBoardLvGenerateGridLevel()
        
        for i, v in pairs(gridEntities) do
            local gridType = v:GetGridType()
            local needadjust = v:GetValue() < minGeneratedLevel
            local adjustLevelUpId = nil
            
            if gridType ~= XMVCA.XGame2048.EnumConst.GridType.Dispel then
                if isWaterFireSelect then
                    -- 水火方块特殊规则，消除范围内留下来的方块需转换成星星方块
                    if gridType == XMVCA.XGame2048.EnumConst.GridType.Water or gridType == XMVCA.XGame2048.EnumConst.GridType.Fire then
                        local posX = v:GetX()
                        local posY = v:GetY()

                        if (posX >= beginX and posX <= endX) and (posY >= beginY and posY <= endY) then
                            local specialAdjustLevelUpId = self._MainControl:GetClientConfigNum('SpecialAdjustLevelUpId')

                            if XTool.IsNumberValidEx(specialAdjustLevelUpId) then
                                adjustLevelUpId = specialAdjustLevelUpId
                                needadjust = true
                            end
                        end
                    end
                end
                
                if needadjust then
                    adjustLevelUpId = adjustLevelUpId or v:GetAdjustLevelUpId()

                    if XTool.IsNumberValidEx(adjustLevelUpId) then
                        local newcfg = self._MainControl:GetBlockCfgById(adjustLevelUpId)
                        local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newcfg.Type)

                        v:SetNewConfig(newcfg, blockTypeCfg)

                        self.ActionsControl:AddGridChangedAction(v.Uid)
                    end
                end
            end
        end
    else
        -- 不升级则只充能
        self.TurnControl:AddCurFeverLeftRound()
        
        -- 如果是无尽关，需要对消除方块做特殊处理
        if self._MainControl:GetStageTypeById(self._MainControl:GetCurStageId()) == XMVCA.XGame2048.EnumConst.StageType.Endless then
            if dispelGrid ~= nil then
                local lastLevelId = dispelGrid:GetLastLevelId()

                if XTool.IsNumberValid(lastLevelId) then
                    -- 消除方块等级回退
                    local lastLevelCfg = self._MainControl:GetBlockCfgById(lastLevelId)
                    local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(lastLevelCfg.Type)
                    
                    dispelGrid:SetNewConfig(lastLevelCfg, blockTypeCfg)
                    self.GridsControl:UpdateDispelGridDirectionByPos(dispelGrid)
                    
                    self.ActionsControl:AddGridChangedAction(dispelGrid.Uid)
                end
            end
        end
    end

    if XTool.IsNumberValid(feverTurnsAddsFromGrid) then
        self.TurnControl:AddFeverLeftRound(feverTurnsAddsFromGrid)
    end
    
    -- 上报埋点
    self.RecordReportControl:DoReport()
end

--- 检查指定的方块等级是否到达棋盘上限，用于控制防止方块升级超出的判断
function XGame2048GameControl:CheckGridLevelIsMaxInCurBoradLevel(gridId)
    local targetId = self.TurnControl:GetCurTargetBlockId()

    ---@type XTableGame2048Block
    local targetBlockCfg = self._Model:GetGame2048BlockCfgById(targetId)
    ---@type XTableGame2048Block
    local blockCfg = self._Model:GetGame2048BlockCfgById(gridId)

    if targetBlockCfg and blockCfg and targetBlockCfg.Level == blockCfg.Level then
        return true
    end
    
    return false
end

--- 移除一个方块数据并标记到废弃字典中
---@param isTurnBegin @是否是回合内移除的
function XGame2048GameControl:RemoveGridAndMarkAsWaste(grid, isTurnBegin)
    self.GridsControl:RemoveGridAndMarkAsWaste(grid, isTurnBegin)
end

function XGame2048GameControl:AddDoublingEffect(grid)
    local effect = self._MergeEffectPool:GetItemFromPool()
    effect.LinkGrid = grid
    effect.Type = XMVCA.XGame2048.EnumConst.MergeEffectType.Doubling
    
    table.insert(self._MergeEffectList, effect)
end

function XGame2048GameControl:AddTransferEffect(grid)
    local effect = self._MergeEffectPool:GetItemFromPool()
    effect.LinkGrid = grid
    effect.Type = XMVCA.XGame2048.EnumConst.MergeEffectType.Transfer

    table.insert(self._MergeEffectList, effect)
end

function XGame2048GameControl:_DoGridDispelTransmit()
    if self._NeedTransmit then
        self._NeedTransmit = false
    else
        return
    end
    
    -- 1. 找到消除方块
    ---@type XGame2048Grid
    local dispelGrid = self.GridsControl:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)

    if not dispelGrid then
        return
    end
    
    local direction = dispelGrid:GetExValue()
    local x = dispelGrid:GetX()
    local y = dispelGrid:GetY()
    
    -- 2. 判断是否已经在方向归属区域内
    if (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up and y == 1) or
            (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Down and y == 4) or
            (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Left and x ==4) or
            (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Right and x == 1)
    then
        return
    end
    
    -- 3. 找到合适的位置
    local isVertical = direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up or direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Down
    
    local beginX = isVertical and 1 or (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Left and 4 or 1)
    local endX = isVertical and 4 or (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Left and 4 or 1)
    
    local beginY = not isVertical and 1 or (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up and 1 or 4)
    local endY = not isVertical and 4 or (direction == XMVCA.XGame2048.EnumConst.GridDispelDirection.Up and 1 or 4)

    local hasEmpty = false
    local aimX, aimY = 0, 0
    local minLevelGrid = nil
    
    for x = beginX, endX do
        for y = beginY, endY do
            -- 同时找空位和最小级别的方块
            local grid = self.GridsControl:GetGridEntityByNormalizePos(x, y)

            if grid then
                if not minLevelGrid or minLevelGrid:GetValue() > grid:GetValue() then
                    minLevelGrid = grid
                    aimX = x
                    aimY = y
                end
            else
                hasEmpty = true
                aimX = x
                aimY = y
                break 
            end
        end

        if hasEmpty then
            break
        end
    end
    
    self.GridsControl:SetGridEntityToAimPos(dispelGrid, aimX, aimY)
    
    -- 更新的动画
    self.ActionsControl:AddGridChangedAction(dispelGrid.Uid, XMVCA.XGame2048.EnumConst.ActionType.GridChangedAfterMerge)

    if minLevelGrid then
        self.ActionsControl:AddGridChangedAction(minLevelGrid.Uid, XMVCA.XGame2048.EnumConst.ActionType.GridChangedAfterMerge)
    end
end

function XGame2048GameControl:_DoGridDispelLevelUpToTarget()
    if self._NeedDispelToTarget then
        self._NeedDispelToTarget = false
    else
        return
    end
    
    -- 1. 找到消除方块
    ---@type XGame2048Grid
    local dispelGrid = self.GridsControl:GetFirstGridEntityFromArrayByType(XMVCA.XGame2048.EnumConst.GridType.Dispel)

    if not dispelGrid then
        return
    end
    
    -- 2. 从当前消除方块的id出发，找到与盘面目标等级相同的消除方块Id
    local targetId = self.TurnControl:GetTargetIdByCurId(dispelGrid.Id)

    if not XTool.IsNumberValidEx(targetId) then
        return
    end
    
    -- 3. 更新配置
    local newBlockCfg = self._Model:GetGame2048BlockCfgById(targetId)
    local blockTypeCfg = self._Model:GetGame2048BlockTypeCfgByType(newBlockCfg.Type)

    dispelGrid:SetNewConfig(newBlockCfg, blockTypeCfg)
    
    -- 4. 更新的动画
    self.ActionsControl:AddGridChangedAction(dispelGrid.Uid, XMVCA.XGame2048.EnumConst.ActionType.GridChangedAfterDoubleLevelUp)
    -- 升级检查
    self.ActionsControl:AddFeverLevelUpCheckAction(dispelGrid.Id)
end
--endregion

--region 协议请求

function XGame2048GameControl:RequestGame2048NextStep(cb)
    -- 记录当前棋盘状态
    self.TurnControl:SyncCurGridsToTransformData(self.GridsControl:GetGridEntities())

    self._IsWaitForNextStep = true

    -- 如果是在回放模式，那么执行回放的操作即可
    if self:CheckDebugEnable() and self.DebugRecordControl:CheckIsPlayBack() then
        self.DebugRecordControl:DoNextStep(cb)
        
        return
    end
    
    XNetwork.Call('Game2048NextStepRequest', {AfterBlocks = self.TurnControl:GetTransformDataForServer(), BoardLv = self.TurnControl:GetBoardLv(), FeverLeftRound = self.TurnControl:GetFeverLeftRound(), Score = self.TurnControl:GetCurScore()}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb()
            end
            return
        end
        -- 清空记录
        self.TurnControl:ClearLastTurnData()
        
        -- 将上一回合产生的消除回收
        self.GridsControl:RecycleAllWasteGridEntityLastTurn()
        
        -- 更新数据
        local gridEntities = self.GridsControl:GetGridEntities()
        
        if not XTool.IsTableEmpty(gridEntities) then
            for i, v in pairs(gridEntities) do
                v:SyncToServerData()
            end
        end
        
        self.TurnControl:UpdateNewTurnStageData(res.ResultData)
        self.TurnControl:CountDownFeverLeftRound()
        self:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_DATA)

        -- 广播新格子生成事件
        local resultData = res.ResultData
        if not XTool.IsTableEmpty(resultData.GeneratedResults) then
            for i, v in pairs(resultData.GeneratedResults) do
                if not XTool.IsTableEmpty(v.TargetBlock) then
                    ---@type XGame2048Grid
                    local gridEntity = self.GridsControl:GetGridEntityByServerBlockData(v.TargetBlock)
                    self.ActionsControl:AddNewBornAction(gridEntity.Uid)
                    self:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_REFRESH_NEW_GRID, gridEntity)
                end
            end
        end
        
        -- 消除方块方向改变
        local changeBlocks = resultData.ChangeBlocks

        if not XTool.IsTableEmpty(changeBlocks) then
            for i, v in pairs(changeBlocks) do
                local uid = self.GridsControl:UpdateServerDataByPos(v, v.X, v.Y)

                if XTool.IsNumberValidEx(uid) then
                    self.ActionsControl:AddDispelGridDirectionChangedAction(uid)
                end
            end
        end
        
        -- 执行机制逻辑
        self:DoBuff()
        -- 尝试一次动画播放
        self.ActionsControl:StartActionList(cb)

        self._IsWaitForNextStep = false
        self._IsWaterFireSelected = false

        if self._GameState ~= XMVCA.XGame2048.EnumConst.GameState.None then
            self._GameState = XMVCA.XGame2048.EnumConst.GameState.None
        end

        if self:CheckDebugEnable() then
            self:PrintGridsInBoardLogForDebug()
            
            if self.DebugRecordControl:CheckIsRecording() then
                -- 开始新一回合的记录
                self.DebugRecordControl:RecordNextSteps()
                -- 记录新回合的新生成的方块数据
                self.DebugRecordControl:RecordCurStepNewGrid(resultData.GeneratedResults)
            end
        end
    end)
end
--endregion

-- debug打印棋盘数据
function XGame2048GameControl:PrintGridsInBoardLogForDebug()
    local gridEntities = self.GridsControl:GetGridEntities()
    
    if not XTool.IsTableEmpty(gridEntities) then
        -- 二维展开
        local array2 = {}

        ---@param grid XGame2048Grid
        for i, grid in pairs(gridEntities) do
            local x = grid:GetX()
            local y = grid:GetY()
            
            if array2[y] == nil then
                array2[y] = {}
            end

            array2[y][x] = grid
        end
        
        -- 转换成字符串
        local stringBuilder = {}
        
        -- 固定4x4
        for y = BoardConstHeight, 1, -1 do
            -- 每行单独
            local line = '|  '
            for x = 1, BoardConstWidth do
                ---@type XGame2048Grid
                local grid = array2[y] and array2[y][x] or nil

                if grid then
                    line = line..tostring(grid:GetValue())..'('..tostring(grid.Id)..')['..tostring(grid:GetExValue())..']\t  |  '
                else
                    line = line..'\t口\t  |  '
                end
            end
            line = line..'\n'
            table.insert(stringBuilder, line)
        end
        
        -- 打印
        XLog.Error('[Debug]----->2048玩法棋盘状态打印：', table.concat(stringBuilder))
    end
    
end

return XGame2048GameControl