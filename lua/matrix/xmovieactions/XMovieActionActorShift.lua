local mathMax = math.max
local vector = CS.UnityEngine.Vector3
local LineAnimCurve = CS.UnityEngine.AnimationCurve.Linear(0, 0, 1, 1)

local XMovieActionActorShift = XClass(XMovieActionBase, "XMovieActionActorShift")

function XMovieActionActorShift:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorShift:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.Duration = paramToNumber(params[2])

    local posX = paramToNumber(params[3])
    local posY = paramToNumber(params[4])
    local posZ = paramToNumber(params[5])
    self.TargetPos = vector(XDataCenter.MovieManager.Fit(posX), posY, posZ)
end

function XMovieActionActorShift:OnRunning()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    local startPos = actor:GetImagePos()
    self.Record = {
        OriginPos = startPos
    }
    local targetPos = self.TargetPos
    local transPos = targetPos - startPos
    local duration = mathMax(0, self.Duration)
    XUiHelper.Tween(duration, function(t)
        actor:SetImagePos(startPos + transPos * LineAnimCurve:Evaluate(t))
    end)
end

function XMovieActionActorShift:OnUndo()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetImagePos(self.Record.OriginPos)
end

function XMovieActionActorShift:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionActorShift:IsActionCover(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.ACTOR_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionActorShift:OnPassedActionRun()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetImagePos(self.TargetPos)
end

return XMovieActionActorShift