---@class XMovieActionSpineActorAlphaChange
---@field UiRoot XUiMovie
local XMovieActionSpineActorAlphaChange = XClass(XMovieActionBase, "XMovieActionSpineActorAlphaChange")
local CSDOTween = CS.DG.Tweening.DOTween
local SPINE_INDEX_OFFSET = 100

local function NormalizeActorIndex(actorIndex)
    if actorIndex > SPINE_INDEX_OFFSET and actorIndex <= SPINE_INDEX_OFFSET + XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        return actorIndex - SPINE_INDEX_OFFSET
    end
    return actorIndex
end

function XMovieActionSpineActorAlphaChange:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    local rawActorIndex = paramToNumber(params[1])
    local actorIndex = NormalizeActorIndex(rawActorIndex)
    if actorIndex == 0 or actorIndex > XMovieConfigs.MAX_SPINE_ACTOR_NUM then
        XLog.Error("XMovieActionSpineActorAlphaChange:OnInit error:ActorIndex is not match, actionId is " .. self.ActionId .. ", actorIndex is " .. tostring(rawActorIndex))
        return
    end

    self.ActorIndex = actorIndex
    self.BeginAlpha = paramToNumber(params[2])
    self.EndAlpha = paramToNumber(params[3])
    self.Duration = paramToNumber(params[4])
    self.CurveType = XMVCA.XMovie:ParamToCurveType(params[5])
end

function XMovieActionSpineActorAlphaChange:OnRunning()
    if not self.ActorIndex then
        return
    end

    self:StopFadeTween()

    if XTool.IsNumberValidEx(self.Duration) and self.BeginAlpha ~= self.EndAlpha then
        self:SetSpineImageAlpha(self.BeginAlpha, true)

        self.FadeTween = CSDOTween.To(function()
            return self.CurrentAlpha
        end, function(alpha)
            self:SetSpineImageAlpha(alpha, true)
        end, self.EndAlpha, self.Duration)

        local ease = XMVCA.XMovie:GetDOTweenEase(self.CurveType)
        if ease and self.FadeTween then
            self.FadeTween:SetEase(ease)
        end
        if self.FadeTween then
            local tween = self.FadeTween
            local actor = self:GetSpineActor()
            if actor then
                actor.SpineAlphaFadeTween = tween
            end
            tween:OnComplete(function()
                local curActor = self:GetSpineActor()
                if curActor and curActor.SpineAlphaFadeTween == tween then
                    curActor.SpineAlphaFadeTween = nil
                end
                if self.FadeTween == tween then
                    self.FadeTween = nil
                end
                self:SetSpineImageAlpha(self.EndAlpha)
            end)
        else
            self:SetSpineImageAlpha(self.EndAlpha)
        end
    else
        self:SetSpineImageAlpha(self.EndAlpha)
    end
end

function XMovieActionSpineActorAlphaChange:GetSpineActor()
    return self.UiRoot:GetSpineActor(self.ActorIndex)
end

function XMovieActionSpineActorAlphaChange:SetSpineImageAlpha(alpha, isKeepComponent)
    self.CurrentAlpha = XMath.Clamp(alpha, 0, 1)

    local actor = self:GetSpineActor()
    if not actor then
        return
    end

    if not isKeepComponent then
        if self.CurrentAlpha >= 1 then
            actor:SetShow(true)
            actor:CleanupSpineFadeComponent(false)
            return
        elseif self.CurrentAlpha <= 0 then
            actor:SetShow(false)
            actor:CleanupSpineFadeComponent(false)
            return
        end
    end

    actor:SetShow(true)
    local component = actor:GetOrAddSpineFadeComponent(self.CurrentAlpha)
    if not component then
        return
    end
    component:SetSpineImageAlpha(self.CurrentAlpha)
end

function XMovieActionSpineActorAlphaChange:StopFadeTween()
    local fadeTween = self.FadeTween
    if self.FadeTween then
        self.FadeTween:Kill()
        self.FadeTween = nil
    end

    local actor = self:GetSpineActor()
    if actor and actor.SpineAlphaFadeTween then
        if actor.SpineAlphaFadeTween ~= fadeTween then
            actor.SpineAlphaFadeTween:Kill()
        end
        actor.SpineAlphaFadeTween = nil
    end
end

function XMovieActionSpineActorAlphaChange:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionSpineActorAlphaChange:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.ActorIndex == action.ActorIndex
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_DISAPPEAR then
        return action:IsDisappear(self.ActorIndex)
    end
    return false
end

function XMovieActionSpineActorAlphaChange:OnPassedActionRun()
    if not self.ActorIndex then
        return
    end

    self:StopFadeTween()
    self:SetSpineImageAlpha(self.EndAlpha)
end

return XMovieActionSpineActorAlphaChange
