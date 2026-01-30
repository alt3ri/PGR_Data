--- 2048玩法分管动画序列的子控制器
---@class XGame2048ActionsControl: XControl
---@field private _MainControl XGame2048GameControl
---@field private _Model XGame2048Model
local XGame2048ActionsControl = XClass(XControl, 'XGame2048ActionsControl')
local XGame2048AnimationGroup = require('XModule/XGame2048/AnimationGroup/XGame2048AnimationGroup')
local XGame2048Action = require('XModule/XGame2048/InGame/Entity/XGame2048Action')

function XGame2048ActionsControl:OnInit()
    ---@type XGame2048AnimationGroup[]
    self._AnimationQueue = {}
    ---@type XGame2048AnimationGroup[]
    self._Priority2AnimationGroup = {}
    
    self._CurRunningAnimationIndex = 0
    
    local animationPriorityHash = {}
    
    -- 初始化每个优先级对应的动画组
    for actionType, priority in pairs(XMVCA.XGame2048.EnumConst.ActionPriority) do
        if not animationPriorityHash[priority] then
            animationPriorityHash[priority] = true
            
            local animationGroup = XGame2048AnimationGroup.New(priority)
            table.insert(self._AnimationQueue, animationGroup)

            self._Priority2AnimationGroup[priority] = animationGroup
        end
    end
    
    -- 按照优先级对队列进行排序
    table.sort(self._AnimationQueue, function(a, b) 
        return a:GetPriority() < b:GetPriority()
    end)
    
    -- 动画对象池
    ---@type XPool
    self._AnimationPool = XPool.New(function() 
        return XGame2048Action.New()
    end, function(animation)
        animation:ResetData()
    end, false)
    
    self._AnimationUidPool = 1

    self._TickTimeId = XScheduleManager.ScheduleForever(handler(self, self.Update), 0.2 * XScheduleManager.SECOND)
end

function XGame2048ActionsControl:OnRelease()
    if self._TickTimeId then
        XScheduleManager.UnSchedule(self._TickTimeId)
        self._TickTimeId = nil
    end
end

function XGame2048ActionsControl:GetAnimationFromPool()
    ---@type XGame2048Action
    local animation = self._AnimationPool:GetItemFromPool()
    
    animation:SetUid(self._AnimationUidPool)
    
    self._AnimationUidPool = self._AnimationUidPool + 1
    
    return animation
end

function XGame2048ActionsControl:InitActions()
    -- 回收
    if not XTool.IsTableEmpty(self._AnimationQueue) then
        for priority, animationGroup in pairs(self._AnimationQueue) do
            local runningAnimations = animationGroup:GetRunningActionList()
            local waittingAnimations = animationGroup:GetWaittingActionList()
            
            animationGroup:ClearAnimations()
            
            if not XTool.IsTableEmpty(runningAnimations) then
                for i, v in pairs(runningAnimations) do
                    self._AnimationPool:ReturnItemToPool(v)
                end
            end

            if not XTool.IsTableEmpty(waittingAnimations) then
                for i, v in pairs(waittingAnimations) do
                    self._AnimationPool:ReturnItemToPool(v)
                end
            end
        end
    end

    -- 重置
    self._ActionPlaying = false
    self._AnimationUidPool = 1
end

function XGame2048ActionsControl:GetIsActionPlaying()
    return self._ActionPlaying
end

function XGame2048ActionsControl:StartActionList(cb)
    self._IsBreak = false
    
    if cb then
        self._ActionCallBack = cb
    end
    
    local anyAnimationGroupStart = false

    for i, animationGroup in ipairs(self._AnimationQueue) do
        if animationGroup:CheckCanStart() then
            self._ActionPlaying = true
            anyAnimationGroupStart = true
            
            animationGroup:SetStart(CS.UnityEngine.Time.time)

            ---@param v XGame2048Action
            for _, v in ipairs(animationGroup:GetRunningActionList()) do
                local params = v:GetParams()
                
                self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_NOTIFY_ACTION_EVENT, v:GetActionType(), params)
            end

            self._CurRunningAnimationIndex = i
            break
        end
    end

    if not anyAnimationGroupStart then
        -- 当没有可以执行的行为时执行回调
        if self._ActionCallBack then
            local cb = self._ActionCallBack
            self._ActionCallBack = nil

            cb()
        end
        self._ActionPlaying = false
    end
end

---@param isBreak @是否打断队列，直到手动调用startActionList
function XGame2048ActionsControl:EndAction(params, isBreak)
    self._IsBreak = isBreak
    
    if params.EventId ~= nil then
        self._MainControl:DispatchEvent(params.EventId, table.unpack(params.EventArgs))
    end

    --回收
    if params.TempGridData then
        self._MainControl.GridsControl:ReturnGridDataToPool(params.TempGridData)
        params.TempGridData = nil
    end

    if params.FinishHandle then
        params.FinishHandle()
    end

    local curAnimationGroup = self._AnimationQueue[self._CurRunningAnimationIndex]

    if curAnimationGroup and curAnimationGroup:CheckIsAllFinish(CS.UnityEngine.Time.time) then
        self:_RecycleRunningAnimations(curAnimationGroup)
        self._CurRunningAnimationIndex = 0

        if not isBreak then
            self:StartActionList()
        end
    end

    if isBreak then
        self._ActionPlaying = false
    end
end

function XGame2048ActionsControl:Update()
    local curTime = CS.UnityEngine.Time.time

    if XTool.IsNumberValidEx(self._CurRunningAnimationIndex) then
        local animationGroup = self._AnimationQueue[self._CurRunningAnimationIndex]

        if animationGroup then
            ---@param v XGame2048Action
            for i, v in ipairs(animationGroup:GetRunningActionList()) do
                if v:CheckIsTimeOut(curTime) then
                    if XMain.IsEditorDebug then
                        XLog.Warning('动画序列' .. tostring(v:GetActionType()) .. '超时，强制设置为完成')
                    end
                    v:MarkFinish()
                end
            end

            if animationGroup:CheckIsAllFinish(CS.UnityEngine.Time.time) then
                self:_RecycleRunningAnimations(animationGroup)
                self._CurRunningAnimationIndex = 0
                if not self._IsBreak then
                    self:StartActionList()
                end
            end
        end
    end
end

---@param animationGroup XGame2048AnimationGroup
function XGame2048ActionsControl:_RecycleRunningAnimations(animationGroup)
    local runningAnimations = animationGroup:GetRunningActionList()

    for i = #runningAnimations, 1, -1 do
        self._AnimationPool:ReturnItemToPool(runningAnimations[i])

        table.remove(runningAnimations, i)
    end
    
    animationGroup:CheckAndClearRunningAnimations()
end

---@param action XGame2048Action
function XGame2048ActionsControl:InsertActionToList(action)
    local type = action:GetActionType()
    local priority = XMVCA.XGame2048.EnumConst.ActionPriority[type]
    local noInsert = false
    local actionParams = action:GetParams()

    local animationGroup = self._Priority2AnimationGroup[priority]

    -- 在一次执行中，一个格子在一个方向上可能断断续续走了几步，需要将这几步合并为一步
    if type == XMVCA.XGame2048.EnumConst.ActionType.NormalMove and animationGroup:CheckHasAnyWaittingAnimation() then
        local mergeSameAction = false
        
        ---@param v XGame2048Action
        for i, v in pairs(animationGroup:GetWaittingActionList()) do
            local params = v:GetParams()
            
            if params.GridUidA == actionParams.GridUidA then
                -- 后续的移动行为，目的地覆盖旧的
                v:SetMoveAction(params.GridUidA, params.MoveFromX, params.MoveFromY, actionParams.MoveToX, actionParams.MoveToY, actionParams.GridUidB and actionParams.GridUidB or v.GridUidB)
                -- 关联相同移动对象的行为
                mergeSameAction = true
                break
            end
        end

        if mergeSameAction then
            self._AnimationPool:ReturnItemToPool(action)
            noInsert = true
        end
    end

    if not noInsert then
        animationGroup:AddPrePlayAnimation(action)
    end

    --处理具有关联性的移动
    if type == XMVCA.XGame2048.EnumConst.ActionType.NormalMove and animationGroup:CheckHasAnyWaittingAnimation() then
        -- 先构建gridUid-moveaction映射表
        local uidToAction = {}
        ---@param v XGame2048Action
        for i, v in pairs(animationGroup:GetWaittingActionList()) do
            local params = v:GetParams()
            uidToAction[params.GridUidA] = v
        end

        --再遍历将action的目标位置同步为follow的目标位置
        local beginIndex = 1
        local endIndex = animationGroup:GetWaittingAnimationCount()
        
        local waittingAnimations = animationGroup:GetWaittingActionList()

        for i = beginIndex, endIndex do
            local tmpAction = waittingAnimations[i]
            local tmpParams = tmpAction:GetParams()
            if XTool.IsNumberValid(tmpParams.GridUidB) and uidToAction[tmpParams.GridUidB] then
                local followAction = uidToAction[tmpParams.GridUidB]
                local followParams = followAction:GetParams()
                
                tmpAction:SetMoveAction(tmpParams.GridUidA, tmpParams.MoveFromX, tmpParams.MoveFromY, followParams.MoveToX, followParams.MoveToY, tmpParams.GridUidB)
            end
        end
    end
end

---@param followGridUid @当多个方块连续合成时，为了实现视效上多个方块一起移动到最终合成的位置，而需要记录一个followUid，当更新合并移动位置时，followUid相同的做相同的合并处理
function XGame2048ActionsControl:AddMoveAction(moveGridUid, fromx, fromy, tox, toy, followGridUid)
    ---@type XGame2048Action
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalMove)
    action:SetMoveAction(moveGridUid, fromx, fromy, tox, toy, followGridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddMergeAction(mergeFromUid, mergeToUid, mergeToBlockId)
    ---@type XGame2048Action
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalMerge)
    action:SetMergeAction(mergeFromUid, mergeToUid, mergeToBlockId)
    
    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(mergeToUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddDispelAction(bombGridUid)
    ---@type XGame2048Action
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalDispel)
    action:SetDispelAction(bombGridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddRockReduceAction(rockUid)
    ---@type XGame2048Action
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.RockReduce)
    action:SetReduceAction(rockUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddRockShakeAction(rockUid)
    ---@type XGame2048Action
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.RockShake)
    action:SetReduceAction(rockUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddNormalReduceAction(normalUid)
    ---@type XGame2048Action
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalReduce)
    action:SetReduceAction(normalUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddNewBornAction(gridUid)
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NewBlockBorn)
    action:SetNewBornAction(gridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddFeverLevelUpAction()
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUp)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddNormalLevelUpAction(normalUid, mergeEffectType)
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.NormalLevelUp)
    action:SetLevelUpAction(normalUid)
    action:SetMergeEffectType(mergeEffectType)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(normalUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddTransferLevelUpAction(transferUid, mergeEffectType)
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.TransferLevelUp)
    action:SetLevelUpAction(transferUid)
    action:SetMergeEffectType(mergeEffectType)
    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(transferUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddICELevelUpAction(iceUid, mergeEffectType)
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.ICELevelUp)
    action:SetLevelUpAction(iceUid)
    action:SetMergeEffectType(mergeEffectType)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(iceUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddFeverUpLevelUpAction(feverUpUid, mergeEffectType)
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.FeverUpLevelUp)
    action:SetLevelUpAction(feverUpUid)
    action:SetMergeEffectType(mergeEffectType)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(feverUpUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddFeverLevelUpCheckAction(gridId)
    -- 同一时期最多只能有一个检查
    local priority = XMVCA.XGame2048.EnumConst.ActionPriority[XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUpCheck]

    local animationGroup = self._Priority2AnimationGroup[priority]
    
    if not animationGroup:CheckHasAnyWaittingAnimation() and self._MainControl:CheckFerverLevelUp(gridId) then
        local action = self:GetAnimationFromPool()
        action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.FeverLevelUpCheck)
        self:InsertActionToList(action)
        return action
    end
end

function XGame2048ActionsControl:AddDispelGridDirectionChangedAction(gridUid)
    local action = self:GetAnimationFromPool()
    action:SetActionType(XMVCA.XGame2048.EnumConst.ActionType.DispelGridDirectionChanged)
    action:SetCurGridUid(gridUid)
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddGridChangedAction(gridUid, targetActionType)
    targetActionType = targetActionType or XMVCA.XGame2048.EnumConst.ActionType.GridChanged
    
    local action = self:GetAnimationFromPool()
    action:SetActionType(targetActionType)
    action:SetCurGridUid(gridUid)

    -- 获取数据
    local tmpGridData = self:_GetCloneTempGridData(gridUid)

    if tmpGridData then
        -- 设置临时对象
        action:SetTempGridData(tmpGridData)
    end
    
    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:AddDispelRangeEffectAction(isEnable)
    local targetActionType = isEnable and XMVCA.XGame2048.EnumConst.ActionType.OpenDispelRangeEffect or XMVCA.XGame2048.EnumConst.ActionType.CloseDispelRangeEffect

    local action = self:GetAnimationFromPool()
    action:SetActionType(targetActionType)

    self:InsertActionToList(action)
    return action
end

function XGame2048ActionsControl:_GetCloneTempGridData(gridUid)
    -- 获取数据
    local gridData = self._MainControl:GetGridEntityByUid(gridUid)

    if gridData then
        -- 克隆临时对象
        ---@type XGame2048Grid
        local tmpGridData = self._MainControl.GridsControl:GetGridDataInPool()
        tmpGridData:SetNewConfig(gridData:GetConfig(), gridData:GetTypeCfg())
        tmpGridData.Uid = gridData.Uid
        tmpGridData:SetExValue(gridData:GetExValue())
        tmpGridData:SetMoveLock(gridData:GetIsMoveLock())
        tmpGridData:SetNewPosition(gridData:GetX(), gridData:GetY())
        
        return tmpGridData
    end
    
    return nil
end

return XGame2048ActionsControl