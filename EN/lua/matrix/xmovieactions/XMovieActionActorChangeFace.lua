local XMovieActionActorChangeFace = XClass(XMovieActionBase, "XMovieActionActorChangeFace")

function XMovieActionActorChangeFace:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorChangeFace:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.FaceId = paramToNumber(params[2])
end

function XMovieActionActorChangeFace:GetActorIndex()
    return self.ActorIndex
end

function XMovieActionActorChangeFace:OnRunning()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetFace(self.FaceId)
end

function XMovieActionActorChangeFace:OnSkip()
    self:OnRunning()
end

function XMovieActionActorChangeFace:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionActorChangeFace:IsActionCover(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action:GetActorIndex()
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.ACTOR_APPEAR then
        return self.ActorIndex == action:GetActorIndex()
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.ACTOR_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionActorChangeFace:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionActorChangeFace