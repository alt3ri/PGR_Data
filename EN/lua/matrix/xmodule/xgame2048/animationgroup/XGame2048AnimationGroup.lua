--- 动画并发组
---@class XGame2048AnimationGroup
local XGame2048AnimationGroup = XClass(nil, 'XGame2048AnimationGroup')

function XGame2048AnimationGroup:Ctor(priority)
    self._Priority = priority
    
    self._RunningActionList = {}
    ---@type XGame2048Animation[]
    self._WaittingActionList = {}
end

function XGame2048AnimationGroup:GetPriority()
    return self._Priority or 0
end

function XGame2048AnimationGroup:CheckIsAllFinish(curTime)
    if XTool.IsTableEmpty(self._RunningActionList) then
        return true
    end
    
    local totalCount = #self._RunningActionList
    local finishCount = 0

    for i, animation in ipairs(self._RunningActionList) do
        if animation:GetIsFinish() then
            finishCount = finishCount + 1
        elseif animation:CheckIsTimeOut(curTime) then
            animation:MarkFinish()
            finishCount = finishCount + 1
        end
    end
    
    return finishCount >= totalCount
end

function XGame2048AnimationGroup:CheckCanStart()
    if XTool.IsTableEmpty(self._WaittingActionList) then
        return false
    end
    
    return true
end

function XGame2048AnimationGroup:SetStart(curTime)
    if not XTool.IsTableEmpty(self._WaittingActionList) then
        for i = #self._WaittingActionList, 1, -1 do
            local animation = self._WaittingActionList[i]
            table.insert(self._RunningActionList, animation)
            table.remove(self._WaittingActionList, i)

            animation:MarkStart(curTime)
        end
    end
    
    return self._RunningActionList
end

function XGame2048AnimationGroup:AddPrePlayAnimation(animation)
    table.insert(self._WaittingActionList, animation)
end

function XGame2048AnimationGroup:ClearAnimations()
    self._RunningActionList = {}
    self._WaittingActionList = {}
end

function XGame2048AnimationGroup:CheckAndClearRunningAnimations()
    if not XTool.IsTableEmpty(self._RunningActionList) then
        self._RunningActionList = {}
    end
end

function XGame2048AnimationGroup:GetRunningActionList()
    return self._RunningActionList
end

function XGame2048AnimationGroup:GetWaittingActionList()
    return self._WaittingActionList
end

function XGame2048AnimationGroup:GetWaittingAnimationCount()
    return #self._WaittingActionList
end

function XGame2048AnimationGroup:CheckHasAnyWaittingAnimation()
    return not XTool.IsTableEmpty(self._WaittingActionList)
end

return XGame2048AnimationGroup