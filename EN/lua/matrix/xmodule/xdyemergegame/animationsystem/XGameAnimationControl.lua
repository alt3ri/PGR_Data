--- 动画播放控制器
---@class XGameAnimationControl
local XGameAnimationControl = XClass(nil, 'XGameAnimationControl')

function XGameAnimationControl:Ctor()
    ---@type XGame2048AnimationGroup[]
    self._AnimationQueue = {}
    ---@type XGame2048AnimationGroup[]
    self._Priority2AnimationGroup = {}

    self._CurRunningAnimationIndex = 0

    self._AnimationPlaying = false
    -- 从激活开始累计的时间
    self._CurTime = 0
end

function XGameAnimationControl:Init(animationCls, groupCls, groupTypes, groupPriorityList)
    self._AnimationCls = animationCls or require('XModule/XDyeMergeGame/AnimationSystem/XGameAnimation')
    self._AnimationGroupCls = groupCls or require('XModule/XDyeMergeGame/AnimationSystem/XGameAnimationGroup')

    if not XTool.IsTableEmpty(groupTypes) then
        -- 初始化每个动画组
        for i, v in pairs(groupTypes) do
            local priority = groupPriorityList and groupPriorityList[i] or 0
            local animationGroup = self._AnimationGroupCls.New(priority)
            table.insert(self._AnimationQueue, animationGroup)

            self._Priority2AnimationGroup[priority] = animationGroup
        end

        if not XTool.IsTableEmpty(groupPriorityList) then
            -- 按照优先级对队列进行排序
            table.sort(self._AnimationQueue, function(a, b)
                return a:GetPriority() < b:GetPriority()
            end)
        end
    end

    -- 动画对象池
    ---@type XPool
    self._AnimationPool = XPool.New(function()
        return self._AnimationCls.New()
    end, function(animation)
        animation:ResetData()
    end, false)

    self._AnimationUidPool = 1
end

function XGameAnimationControl:InitAnimationCallbacks(startCb, endCb)
    -- 每一个动画开始播放时执行回调，及用于通知具体的业务执行对应逻辑
    self._AnimationStartCallback = startCb
    -- 每一个动画结束时执行回调，用于具体的业务处理额外的逻辑
    self._AnimationEndCallback = endCb
end

--- 数据重置
function XGameAnimationControl:Reset()
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
    self._AnimationPlaying = false
    self._AnimationUidPool = 1
    self._CurTime = 0
end

--- 添加一个动画到指定动画组待播放列表中
function XGameAnimationControl:InsertActionToList(action, priority)
    local animationGroup = self._Priority2AnimationGroup[priority]

    if animationGroup then
        animationGroup:AddPrePlayAnimation(action)
    end
end

--- 轮询更新：动画组完成播放检查
---@param dt @每两次更新的间隔时间
function XGameAnimationControl:Update(dt)
    self._CurTime = self._CurTime + dt

    if XTool.IsNumberValidEx(self._CurRunningAnimationIndex) then
        local animationGroup = self._AnimationQueue[self._CurRunningAnimationIndex]

        if animationGroup then
            ---@param v XGame2048Action
            for i, v in ipairs(animationGroup:GetRunningActionList()) do
                if v:CheckIsTimeOut(self._CurTime) then
                    if XMain.IsEditorDebug then
                        XLog.Warning('动画序列' .. tostring(v:GetActionType()) .. '超时，强制设置为完成')
                    end
                    v:MarkFinish()
                end
            end

            if animationGroup:CheckIsAllFinish(self._CurTime) then
                self:_RecycleRunningAnimations(animationGroup)
                self._CurRunningAnimationIndex = 0
                if not self._IsBreak then
                    self:StartAnimationList()
                end
            end
        end
    end
end

--region AnimationPool

function XGameAnimationControl:GetAnimationFromPool()
    local animation = self._AnimationPool:GetItemFromPool()

    animation:SetUid(self._AnimationUidPool)

    self._AnimationUidPool = self._AnimationUidPool + 1

    return animation
end

---@param animationGroup XGame2048AnimationGroup
function XGameAnimationControl:_RecycleRunningAnimations(animationGroup)
    local runningAnimations = animationGroup:GetRunningActionList()

    for i = #runningAnimations, 1, -1 do
        self._AnimationPool:ReturnItemToPool(runningAnimations[i])

        table.remove(runningAnimations, i)
    end

    animationGroup:CheckAndClearRunningAnimations()
end

--endregion

--region Running

function XGameAnimationControl:GetIsAnimationPlaying()
    return self._AnimationPlaying
end

function XGameAnimationControl:StartAnimationList(cb)
    self._IsBreak = false

    if cb then
        self._AnimationCallBack = cb
    end

    local anyAnimationGroupStart = false

    for i, animationGroup in ipairs(self._AnimationQueue) do
        if animationGroup:CheckCanStart() then
            self._AnimationPlaying = true
            anyAnimationGroupStart = true

            animationGroup:SetStart(self._CurTime)

            local runningList = animationGroup:GetRunningActionList()
            -- XLog.Debug("[DyeMerge][AnimationSystem] 动画组启动 groupIndex=" .. tostring(i) .. " priority=" .. tostring(animationGroup:GetPriority()) .. " 动画数=" .. tostring(#runningList))

            self._CurRunningAnimationIndex = i

            for _, v in ipairs(runningList) do
                local params = v:GetParams()

                if self._AnimationStartCallback then
                    self._AnimationStartCallback(v:GetActionType(), params)
                end
            end

            break
        end
    end

    if not anyAnimationGroupStart then
        -- XLog.Debug("[DyeMerge][AnimationSystem] 无待播放动画组，动画列表全部完成")
        -- 当没有可以执行的行为时执行回调
        if self._AnimationCallBack then
            cb = self._AnimationCallBack

            self._AnimationCallBack = nil

            cb()
        end
        self._AnimationPlaying = false
    end
end

---@param isBreak @是否打断队列，直到手动调用startActionList
function XGameAnimationControl:EndAnimation(params, isBreak)
    self._IsBreak = isBreak

    if self._AnimationEndCallback then
        self._AnimationEndCallback(params)
    end
    
    if params.FinishHandle then
        params.FinishHandle()
    end

    local curAnimationGroup = self._AnimationQueue[self._CurRunningAnimationIndex]

    if curAnimationGroup and curAnimationGroup:CheckIsAllFinish(self._CurTime) then
        self:_RecycleRunningAnimations(curAnimationGroup)
        self._CurRunningAnimationIndex = 0

        if not isBreak then
            self:StartAnimationList()
        end
    end

    if isBreak then
        self._AnimationPlaying = false
    end
end

--endregion

return XGameAnimationControl