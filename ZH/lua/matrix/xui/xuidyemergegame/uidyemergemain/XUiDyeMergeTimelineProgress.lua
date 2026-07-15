local function Clamp01(v)
    return math.max(0, math.min(1, v))
end

---@class XUiDyeMergeTimelineProgress: XUiNode
local XUiDyeMergeTimelineProgress = XClass(XUiNode, "XUiDyeMergeTimelineProgress")

function XUiDyeMergeTimelineProgress:OnStart()
    self._CurrentProgress = 0
    self._TargetProgress = 0
    self._Speed = 0
    self._ScheduleId = nil
    self._OnCompleteCb = nil
    self._UpdateHandler = handler(self, self._OnFrameUpdate)
    
    self:SetDirector(self.GameObject:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector)))
end

function XUiDyeMergeTimelineProgress:OnDisable()
    self:_StopSchedule()
end

function XUiDyeMergeTimelineProgress:SetDirector(director)
    self._Director = director
end

function XUiDyeMergeTimelineProgress:SmoothMoveTo(targetProgress, speed, fromProgress, onComplete)
    self:_StopSchedule()

    self._TargetProgress = Clamp01(targetProgress)
    self._Speed = speed
    self._OnCompleteCb = onComplete

    if fromProgress then
        self._CurrentProgress = Clamp01(fromProgress)
        self:_UpdateTimelineTime()
    end

    if self._CurrentProgress == self._TargetProgress then
        self:_OnReachTarget()
        return
    end

    self._ScheduleId = XScheduleManager.ScheduleForever(self._UpdateHandler, 0, 0)
end

function XUiDyeMergeTimelineProgress:SetProgress(progress, onComplete)
    self:_StopSchedule()

    self._CurrentProgress = Clamp01(progress)
    self._TargetProgress = self._CurrentProgress
    self:_UpdateTimelineTime()

    if onComplete then
        onComplete()
    end
end

function XUiDyeMergeTimelineProgress:GetCurrentProgress()
    return self._CurrentProgress
end

function XUiDyeMergeTimelineProgress:IsAnimating()
    return self._ScheduleId ~= nil
end

function XUiDyeMergeTimelineProgress:_OnFrameUpdate()
    if XTool.UObjIsNil(self._Director) then
        self:_StopSchedule()
        return
    end

    local direction = self._TargetProgress > self._CurrentProgress and 1 or -1
    local delta = self._Speed * CS.UnityEngine.Time.deltaTime * direction
    local newProgress = self._CurrentProgress + delta

    if (direction > 0 and newProgress >= self._TargetProgress)
            or (direction < 0 and newProgress <= self._TargetProgress) then
        newProgress = self._TargetProgress
    end

    self._CurrentProgress = newProgress
    self:_UpdateTimelineTime()

    if self._CurrentProgress == self._TargetProgress then
        self:_OnReachTarget()
    end
end

function XUiDyeMergeTimelineProgress:_UpdateTimelineTime()
    if XTool.UObjIsNil(self._Director) then
        return
    end

    local duration = self._Director.duration
    self._Director.time = duration * self._CurrentProgress
    self._Director:Evaluate()
end

function XUiDyeMergeTimelineProgress:_OnReachTarget()
    self:_StopSchedule()
    self._Speed = 0

    if self._OnCompleteCb then
        local cb = self._OnCompleteCb
        self._OnCompleteCb = nil
        cb()
    end
end

function XUiDyeMergeTimelineProgress:_StopSchedule()
    if self._ScheduleId then
        XScheduleManager.UnSchedule(self._ScheduleId)
        self._ScheduleId = nil
    end
end

return XUiDyeMergeTimelineProgress
