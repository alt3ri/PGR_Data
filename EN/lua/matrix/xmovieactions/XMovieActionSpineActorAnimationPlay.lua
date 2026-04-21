local XMovieActionSpineActorAnimationPlay = XClass(XMovieActionBase, "XMovieActionSpineActorAnimationPlay")

function XMovieActionSpineActorAnimationPlay:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorAnimationPlay:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex
    self.AnimName = params[2]
end

function XMovieActionSpineActorAnimationPlay:OnRunning()
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    actor:PlayUiAnimation(self.AnimName)
end

function XMovieActionSpineActorAnimationPlay:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSpineActorAnimationPlay:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorAnimationPlay:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSpineActorAnimationPlay