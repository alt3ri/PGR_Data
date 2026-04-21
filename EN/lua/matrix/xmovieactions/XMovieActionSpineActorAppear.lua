local vector = CS.UnityEngine.Vector3

local XMovieActionSpineActorAppear = XClass(XMovieActionBase, "XMovieActionSpineActorAppear")

function XMovieActionSpineActorAppear:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local actorIndex = paramToNumber(params[1])
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorAppear:Ctor error:ActorIndex is not match, actionId is " .. self.ActionId)
        return
    end
    self.ActorIndex = actorIndex

    self.ActorId = paramToNumber(params[2])
    self.AnimId = paramToNumber(params[3])
    self.AnimId = self.AnimId == 0 and 1 or self.AnimId -- 不配置默认播第一个动画

    local posX = paramToNumber(params[4])
    local posY = paramToNumber(params[5])
    local posZ = paramToNumber(params[6])
    self.FixPos = vector(XDataCenter.MovieManager.Fit(posX), posY, posZ)
    self.IsSkipAnim = paramToNumber(params[7]) == 1
end

function XMovieActionSpineActorAppear:OnEnter()
    local actor = self.UiRoot:GetSpineActor(self.ActorIndex)
    actor:SetShow(true)
    actor:UpdateSpineActor(self.ActorId, self.AnimId)
    actor:SetPos(self.FixPos)

    if not self.IsSkipAnim then
        actor:PlayUiAnimation(XMovieConfigs.SpineActorAnim.PanelActorEnable)
    end
end

function XMovieActionSpineActorAppear:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSpineActorAppear:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorAppear:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionSpineActorAppear