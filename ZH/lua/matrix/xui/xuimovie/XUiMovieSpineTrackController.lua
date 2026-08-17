---@class XUiMovieSpineTrackController
local XUiMovieSpineTrackController = XClass(nil, "XUiMovieSpineTrackController")

local DEFAULT_MAIN_LOOP_COUNT = 4
local DEFAULT_INSERT_LOOP_COUNT = 1
local DEFAULT_TRANSITION_DURATION = 0.25
local UPDATE_INTERVAL = 0
local CSXUnityInterface = CS.XUnityInterface

local function IsValidAnim(animName)
    return not string.IsNilOrEmpty(animName)
end

function XUiMovieSpineTrackController:Ctor(owner, animator, actorId, trackType)
    self.Owner = owner
    self.Animator = animator
    self.ActorId = actorId
    self.TrackType = trackType

    self.MainAnim = nil
    self.InsertAnim = nil
    self.TransitionAnim = nil
    self.PendingMainAnim = nil
    self.PendingInsertAnim = nil
    self.IsTransitioning = false
    self.IsPlayingInsert = false
    self.MainCompleteCount = 0
    self.InsertCompleteCount = 0
    self.CurrentAnimName = nil
    self.LastLoopIndex = 0
    self.HasEnteredState = false

    self:EnsureLayerWeight()
end

function XUiMovieSpineTrackController:Stop()
    self:RemoveTimer()

    self.MainAnim = nil
    self.InsertAnim = nil
    self.TransitionAnim = nil
    self.PendingMainAnim = nil
    self.PendingInsertAnim = nil
    self.IsTransitioning = false
    self.IsPlayingInsert = false
    self.MainCompleteCount = 0
    self.InsertCompleteCount = 0
    self.CurrentAnimName = nil
    self.LastLoopIndex = 0
    self.HasEnteredState = false
end

function XUiMovieSpineTrackController:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMovieSpineTrackController:StartTimer()
    if self.Timer then
        return
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        self:OnUpdate()
    end, UPDATE_INTERVAL)
end

function XUiMovieSpineTrackController:IsAnimatorValid(isSilent)
    local animator = self.Animator
    if XTool.UObjIsNil(animator) then
        if not isSilent then
            XLog.Error("XUiMovieSpineTrackController:IsAnimatorValid error: animator is nil, actorId is " .. tostring(self.ActorId))
        end
        return false
    end

    if XTool.UObjIsNil(animator.runtimeAnimatorController) then
        if not isSilent then
            XLog.Error("XUiMovieSpineTrackController:IsAnimatorValid error: runtimeAnimatorController is nil, actorId is " .. tostring(self.ActorId))
        end
        return false
    end

    if not animator.gameObject.activeInHierarchy then
        return false
    end

    return true
end

function XUiMovieSpineTrackController:HasLayer()
    local animator = self.Animator
    if XTool.UObjIsNil(animator) then
        return false
    end

    if animator.layerCount and self.TrackType >= animator.layerCount then
        XLog.Error("XUiMovieSpineTrackController:HasLayer error: animator layer not found, actorId is " .. tostring(self.ActorId) .. ", layerIndex is " .. tostring(self.TrackType))
        return false
    end

    return true
end

function XUiMovieSpineTrackController:EnsureLayerWeight()
    if self.TrackType <= XMovieConfigs.SpineActorTrackType.Base then
        return
    end

    if self:IsAnimatorValid(true) and self:HasLayer() then
        self.Animator:SetLayerWeight(self.TrackType, 1)
    end
end

function XUiMovieSpineTrackController:HasState(animName)
    if not IsValidAnim(animName) then
        return false
    end

    if not self:IsAnimatorValid() or not self:HasLayer() then
        return false
    end

    local stateId = CS.UnityEngine.Animator.StringToHash(animName)
    if not self.Animator:HasState(self.TrackType, stateId) then
        XLog.Error("XUiMovieSpineTrackController:HasState error: animator state not found, actorId is " .. tostring(self.ActorId) .. ", layerIndex is " .. tostring(self.TrackType) .. ", animName is " .. tostring(animName))
        return false
    end

    return true
end

function XUiMovieSpineTrackController:PlayState(animName, transitionDuration)
    if not self:HasState(animName) then
        return false
    end

    transitionDuration = transitionDuration or DEFAULT_TRANSITION_DURATION
    CSXUnityInterface.XCrossFadeInFixedTime(
        self.Animator,
        animName,
        transitionDuration,
        self.TrackType,
        0
    )
    self.CurrentAnimName = animName
    self.LastLoopIndex = 0
    self.HasEnteredState = false
    return true
end

function XUiMovieSpineTrackController:PlayAnimationsLoopIfChanged(animName, insertAnimName, transAnimName, speed)
    if not IsValidAnim(transAnimName) and self.CurrentAnimName == animName and self.InsertAnim == insertAnimName then
        return
    end

    self:PlayAnimationsLoop(animName, insertAnimName, transAnimName, speed)
end

function XUiMovieSpineTrackController:PlayAnimationsLoop(animName, insertAnimName, transAnimName, speed)
    if not IsValidAnim(animName) then
        return
    end

    self.Speed = speed
    if IsValidAnim(transAnimName) then
        self.PendingMainAnim = animName
        self.PendingInsertAnim = insertAnimName
        self.TransitionAnim = transAnimName
        self.IsTransitioning = true
        if self:PlayState(transAnimName) then
            self:StartTimer()
            return
        end
    end

    self:PlayLoop(animName, insertAnimName, speed)
end

function XUiMovieSpineTrackController:PlayLoop(animName, insertAnimName, speed)
    self.MainAnim = animName
    self.InsertAnim = insertAnimName
    self.TransitionAnim = nil
    self.PendingMainAnim = nil
    self.PendingInsertAnim = nil
    self.IsTransitioning = false
    self.IsPlayingInsert = false
    self.MainCompleteCount = 0
    self.InsertCompleteCount = 0
    self.Speed = speed

    self:PlayMainAnim()
end

function XUiMovieSpineTrackController:PlayMainAnim()
    if not IsValidAnim(self.MainAnim) then
        self:RemoveTimer()
        return
    end

    self.IsPlayingInsert = false
    self.MainCompleteCount = 0
    self.InsertCompleteCount = 0
    if self:PlayState(self.MainAnim) then
        if IsValidAnim(self.InsertAnim) then
            self:StartTimer()
        else
            self:RemoveTimer()
        end
    else
        self:RemoveTimer()
    end
end

function XUiMovieSpineTrackController:PlayInsertAnim()
    if not IsValidAnim(self.InsertAnim) then
        self:RemoveTimer()
        return
    end

    self.InsertCompleteCount = 0
    if self:PlayState(self.InsertAnim) then
        self.IsPlayingInsert = true
        self:StartTimer()
    else
        self.InsertAnim = nil
        self.IsPlayingInsert = false
        self:RemoveTimer()
    end
end

function XUiMovieSpineTrackController:GetCurrentStateInfo(animName)
    if not self:IsAnimatorValid(true) or not self:HasLayer() then
        self:RemoveTimer()
        return nil
    end

    local stateInfo = self.Animator:GetCurrentAnimatorStateInfo(self.TrackType)
    if not stateInfo or not stateInfo:IsName(animName) then
        return nil
    end

    self.HasEnteredState = true
    return stateInfo
end

function XUiMovieSpineTrackController:IsStateComplete(animName)
    local stateInfo = self:GetCurrentStateInfo(animName)
    if not stateInfo then
        return self.HasEnteredState
    end

    if self.Animator:IsInTransition(self.TrackType) then
        return false
    end

    return stateInfo.normalizedTime >= 1
end

function XUiMovieSpineTrackController:UpdateLoopCount(animName, countField)
    local stateInfo = self:GetCurrentStateInfo(animName)
    if not stateInfo then
        return self[countField] or 0
    end

    local loopIndex = math.floor(stateInfo.normalizedTime)
    if loopIndex > self.LastLoopIndex then
        self[countField] = (self[countField] or 0) + loopIndex - self.LastLoopIndex
        self.LastLoopIndex = loopIndex
    end

    return self[countField] or 0
end

function XUiMovieSpineTrackController:OnUpdate()
    if self.IsTransitioning then
        if self:IsStateComplete(self.TransitionAnim) then
            self:PlayLoop(self.PendingMainAnim, self.PendingInsertAnim, self.Speed)
        end
        return
    end

    if not IsValidAnim(self.InsertAnim) then
        self:RemoveTimer()
        return
    end

    if self.IsPlayingInsert then
        if self:UpdateLoopCount(self.InsertAnim, "InsertCompleteCount") >= DEFAULT_INSERT_LOOP_COUNT then
            self:PlayMainAnim()
        end
        return
    end

    if self:UpdateLoopCount(self.MainAnim, "MainCompleteCount") >= DEFAULT_MAIN_LOOP_COUNT then
        self:PlayInsertAnim()
    end
end

return XUiMovieSpineTrackController
