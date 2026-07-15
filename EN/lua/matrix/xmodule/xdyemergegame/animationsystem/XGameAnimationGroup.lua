--- 动画并发组
---@class XGameAnimationGroup
local XGameAnimationGroup = XClass(nil, 'XGameAnimationGroup')

function XGameAnimationGroup:Ctor(priority)
    self._Priority = priority
    
    self._RunningActionList = {}
    ---@type XGame2048Animation[]
    self._WaittingActionList = {}
end

function XGameAnimationGroup:GetPriority()
    return self._Priority or 0
end

function XGameAnimationGroup:CheckIsAllFinish(curTime)
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

function XGameAnimationGroup:CheckCanStart()
    if XTool.IsTableEmpty(self._WaittingActionList) then
        return false
    end
    
    return true
end

function XGameAnimationGroup:SetStart(curTime)
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

function XGameAnimationGroup:AddPrePlayAnimation(animation)
    table.insert(self._WaittingActionList, animation)
end

function XGameAnimationGroup:ClearAnimations()
    self._RunningActionList = {}
    self._WaittingActionList = {}
end

function XGameAnimationGroup:CheckAndClearRunningAnimations()
    if not XTool.IsTableEmpty(self._RunningActionList) then
        self._RunningActionList = {}
    end
end

function XGameAnimationGroup:GetRunningActionList()
    return self._RunningActionList
end

function XGameAnimationGroup:GetWaittingActionList()
    return self._WaittingActionList
end

function XGameAnimationGroup:GetWaittingAnimationCount()
    return #self._WaittingActionList
end

function XGameAnimationGroup:CheckHasAnyWaittingAnimation()
    return not XTool.IsTableEmpty(self._WaittingActionList)
end

return XGameAnimationGroup