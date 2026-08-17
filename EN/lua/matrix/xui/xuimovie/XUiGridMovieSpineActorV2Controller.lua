---@class XUiGridMovieSpineActorV2Controller
local XUiMovieSpineTrackController = require("XUi/XUiMovie/XUiMovieSpineTrackController")
local XUiGridMovieSpineActorV2Controller = XClass(nil, "XUiGridMovieSpineActorV2Controller")

-- MARK: 调试开关。需要排查 SkeletonMecanim 自身问题时可临时开启。
local DISABLE_V2_MECANIM_DRIVER = false

local function GetComponent(gameObject, componentType)
    if XTool.UObjIsNil(gameObject) then
        return nil
    end

    local component = gameObject:GetComponent(typeof(componentType))
    if XTool.UObjIsNil(component) then
        return nil
    end

    return component
end

function XUiGridMovieSpineActorV2Controller:Ctor(owner, spineRoot, actorId)
    self.Owner = owner
    self.SpineRoot = spineRoot
    self.ActorId = actorId
    self.TrackControllers = {}

    if DISABLE_V2_MECANIM_DRIVER then
        return
    end

    self.RoleAnimator = self:FindRoleAnimator(spineRoot)

    if XTool.UObjIsNil(self.RoleAnimator) or XTool.UObjIsNil(self.RoleAnimator.runtimeAnimatorController) then
        XLog.Error("XUiGridMovieSpineActorV2Controller:Ctor error: Role animator is not found, actorId is " .. tostring(actorId))
        return
    end

    self.TrackControllers[XMovieConfigs.SpineActorTrackType.Base] = XUiMovieSpineTrackController.New(self, self.RoleAnimator, actorId, XMovieConfigs.SpineActorTrackType.Base)
    self.TrackControllers[XMovieConfigs.SpineActorTrackType.Mouth] = XUiMovieSpineTrackController.New(self, self.RoleAnimator, actorId, XMovieConfigs.SpineActorTrackType.Mouth)
    self.TrackControllers[XMovieConfigs.SpineActorTrackType.Face] = XUiMovieSpineTrackController.New(self, self.RoleAnimator, actorId, XMovieConfigs.SpineActorTrackType.Face)
end

function XUiGridMovieSpineActorV2Controller:FindRoleAnimator(spineRoot)
    if XTool.UObjIsNil(spineRoot) then
        return nil
    end

    local roleTransform = spineRoot.transform:Find("PanelActor/Role")
    if XTool.UObjIsNil(roleTransform) then
        roleTransform = spineRoot.transform:Find("Animation/PanelActor/Role")
    end
    if XTool.UObjIsNil(roleTransform) then
        return nil
    end

    return GetComponent(roleTransform.gameObject, CS.UnityEngine.Animator)
end

function XUiGridMovieSpineActorV2Controller:Destroy()
    for _, controller in pairs(self.TrackControllers) do
        controller:Stop()
    end

    self.TrackControllers = {}
    self.RoleAnimator = nil
    self.Owner = nil
end

function XUiGridMovieSpineActorV2Controller:GetTrackController(trackType)
    return self.TrackControllers and self.TrackControllers[trackType]
end

function XUiGridMovieSpineActorV2Controller:PlayAnim(animIndex, transIndex)
    self.AnimIndex = XTool.IsNumberValidEx(animIndex) and animIndex or 1

    if DISABLE_V2_MECANIM_DRIVER then
        return
    end

    local animName = XMovieConfigs.GetSpineActorRoleAnim(self.ActorId, self.AnimIndex)
    local animName2 = XMovieConfigs.GetSpineActorRoleAnim2(self.ActorId, self.AnimIndex)
    local transAnimName = XTool.IsNumberValidEx(transIndex) and XMovieConfigs.GetSpineActorTransitionAnim(self.ActorId, transIndex) or nil
    self:PlayFaceAnimationsLoop(animName, animName2, transAnimName)

    if self.Owner then
        if self.Owner.IsTalking then
            self:PlayKouTalkAnim(self.Owner.TalkSpeed)
        else
            self:PlayKouIdleAnim()
        end
    end
end

function XUiGridMovieSpineActorV2Controller:PlayBodyAnimationsLoop(animName, animName2, transAnimName)
    if DISABLE_V2_MECANIM_DRIVER then
        return
    end

    local controller = self:GetTrackController(XMovieConfigs.SpineActorTrackType.Base)
    if controller then
        controller:PlayAnimationsLoop(animName, animName2, transAnimName)
    end
end

function XUiGridMovieSpineActorV2Controller:PlayFaceAnimationsLoop(animName, animName2, transAnimName)
    if DISABLE_V2_MECANIM_DRIVER then
        return
    end

    local controller = self:GetTrackController(XMovieConfigs.SpineActorTrackType.Face)
    if controller then
        controller:PlayAnimationsLoop(animName, animName2, transAnimName)
    end
end

function XUiGridMovieSpineActorV2Controller:PlayKouTalkAnim(speed)
    local animIndex = XTool.IsNumberValidEx(self.AnimIndex) and self.AnimIndex or 1

    if DISABLE_V2_MECANIM_DRIVER then
        return
    end

    local talkAnim = XMovieConfigs.GetSpineActorKouTalkAnim(self.ActorId, animIndex)
    local controller = self:GetTrackController(XMovieConfigs.SpineActorTrackType.Mouth)
    if controller then
        controller:PlayAnimationsLoopIfChanged(talkAnim, nil, nil, speed)
    end
end

function XUiGridMovieSpineActorV2Controller:PlayKouIdleAnim()
    local animIndex = XTool.IsNumberValidEx(self.AnimIndex) and self.AnimIndex or 1

    if DISABLE_V2_MECANIM_DRIVER then
        return
    end

    local idleAnim = XMovieConfigs.GetSpineActorKouIdleAnim(self.ActorId, animIndex)
    local controller = self:GetTrackController(XMovieConfigs.SpineActorTrackType.Mouth)
    if controller then
        controller:PlayAnimationsLoopIfChanged(idleAnim)
    end
end

return XUiGridMovieSpineActorV2Controller
