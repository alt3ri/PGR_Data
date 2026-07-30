local XMovieActionSpineActorChangeRoleAnim = XClass(XMovieActionBase, "XMovieActionSpineActorChangeRoleAnim")

function XMovieActionSpineActorChangeRoleAnim:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorChangeRoleAnim:OnInit error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex
    self.AnimId = paramToNumber(params[2])
    self.TransitionAnimId = paramToNumber(params[3])
end

function XMovieActionSpineActorChangeRoleAnim:OnRunning()
    ---@type XUiGridMovieSpineActor
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    if actor.IsV2 then
        actor:PlayAnim(self.AnimId, self.TransitionAnimId)
        return
    end

    local actorId = actor.ActorId
    local animName = XMovieConfigs.GetSpineActorRoleAnim(actorId, self.AnimId)
    local animName2 = XMovieConfigs.GetSpineActorRoleAnim2(actorId, self.AnimId)
    local transAnimName = XTool.IsNumberValidEx(self.TransitionAnimId) and XMovieConfigs.GetSpineActorTransitionAnim(actorId, self.TransitionAnimId) or nil

    actor:PlayRoleAnimationsLoop(animName, animName2, transAnimName)
    actor:PlayKouAnim(animName)
end

function XMovieActionSpineActorChangeRoleAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSpineActorChangeRoleAnim:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorChangeRoleAnim:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSpineActorChangeRoleAnim
