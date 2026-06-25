local mathMax = math.max

---@class XMovieActionActorScale
---@field UiRoot XUiMovie
local XMovieActionActorScale = XClass(XMovieActionBase, "XMovieActionActorScale")

function XMovieActionActorScale:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_ACTOR_NUM then
        XLog.Error("XMovieActionActorScale:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.Scale = mathMax(0, paramToNumber(params[2]))
    self.Duration = paramToNumber(params[3])
    self.CurveType = XMVCA.XMovie:ParamToCurveType(params[4])
end

function XMovieActionActorScale:OnRunning()
    ---@type XUiGridMovieActor
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    local startScale = actor:GetImageScale()
    self.Record = {
        OriginScale = startScale
    }
    local transScale = self.Scale - startScale
    local duration = mathMax(0, self.Duration)
    local easeFn = XMVCA.XMovie:GetCurveEvaluator(self.CurveType)

    self:RemoveTimer()
    self.Timer = XUiHelper.Tween(duration, function(t)
        actor:SetImageScale(startScale + transScale * t)
    end, nil, easeFn)
end

function XMovieActionActorScale:OnUiRootDestroy()
    self:RemoveTimer()
end

function XMovieActionActorScale:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XMovieActionActorScale:OnUndo()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetImageScale(self.Record.OriginScale)
end

function XMovieActionActorScale:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionActorScale:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.ACTOR_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionActorScale:OnPassedActionRun()
    local actor = self.UiRoot:GetActor(self.ActorIndex)
    actor:SetImageScale(self.Scale)
end

return XMovieActionActorScale
