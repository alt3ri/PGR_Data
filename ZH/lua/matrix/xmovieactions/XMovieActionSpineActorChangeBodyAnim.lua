local XMovieActionSpineActorChangeBodyAnim = XClass(XMovieActionBase, "XMovieActionSpineActorChangeBodyAnim")

function XMovieActionSpineActorChangeBodyAnim:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorChangeBodyAnim:OnInit error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.AnimName = params[2]
    self.AnimName2 = params[3]
    self.TransAnimName = params[4]
end

function XMovieActionSpineActorChangeBodyAnim:OnRunning()
    ---@type XUiGridMovieSpineActor
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    actor:PlayBodyAnimationsLoop(self.AnimName, self.AnimName2, self.TransAnimName)
end

function XMovieActionSpineActorChangeBodyAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSpineActorChangeBodyAnim:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorChangeBodyAnim:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSpineActorChangeBodyAnim
