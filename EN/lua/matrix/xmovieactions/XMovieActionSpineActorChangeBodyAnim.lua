local XMovieActionSpineActorChangeBodyAnim = XClass(XMovieActionBase, "XMovieActionSpineActorChangeBodyAnim")

local function IsAnimNameValid(animName)
    return not string.IsNilOrEmpty(animName)
end

local function IsTrackCovered(animName, coverAnimName)
    if not IsAnimNameValid(animName) then
        return true
    end

    return IsAnimNameValid(coverAnimName)
end

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

    -- Face动画 5 6 7
    self.FaAnimName = params[5]
    self.FaAnimName2 = params[6]
    self.FaTransAnimName = params[7]

    -- Mouth动画 8 9 10
    self.MoAnimName = params[8]
    self.MoAnimName2 = params[9]
    self.MoTransAnimName = params[10]
end

function XMovieActionSpineActorChangeBodyAnim:OnRunning()
    ---@type XUiGridMovieSpineActor
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    if not actor then
        return
    end

    actor:PlayBodyAnimationsLoop(self.AnimName, self.AnimName2, self.TransAnimName)

    if not actor.IsV2 or not actor.V2Controller then
        return
    end

    if IsAnimNameValid(self.FaAnimName) then
        actor.V2Controller:PlayFaceAnimationsLoop(self.FaAnimName, self.FaAnimName2, self.FaTransAnimName)
    end

    if IsAnimNameValid(self.MoAnimName) then
        actor.V2Controller:PlayMouthAnimationsLoop(self.MoAnimName, self.MoAnimName2, self.MoTransAnimName)
    end
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
            and IsTrackCovered(self.AnimName, action.AnimName)
            and IsTrackCovered(self.FaAnimName, action.FaAnimName)
            and IsTrackCovered(self.MoAnimName, action.MoAnimName)
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorChangeBodyAnim:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSpineActorChangeBodyAnim
