local XMovieActionSpineActorChangeAnim = XClass(XMovieActionBase, "XMovieActionSpineActorChangeAnim")

function XMovieActionSpineActorChangeAnim:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorChangeAnim:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.AnimId = paramToNumber(params[2])
    self.TransitionAnimId = paramToNumber(params[3])
end

function XMovieActionSpineActorChangeAnim:OnRunning()
    ---@type XUiGridMovieSpineActor
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    actor:PlayAnim(self.AnimId, self.TransitionAnimId)
end

function XMovieActionSpineActorChangeAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSpineActorChangeAnim:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorChangeAnim:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSpineActorChangeAnim