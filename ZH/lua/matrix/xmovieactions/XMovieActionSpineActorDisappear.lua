local XMovieActionSpineActorDisappear = XClass(XMovieActionBase, "XMovieActionSpineActorDisappear")
local CSDOTween = CS.DG.Tweening.DOTween
local DEFAULT_FADE_DURATION = 0.5
local MILLIS_TO_SECONDS = 0.001

local function FadeSpineImageAlpha(actor, fromAlpha, toAlpha, duration, finishCb)
    actor:StopSpineAlphaFade()

    local component = actor:GetOrAddSpineFadeComponent(fromAlpha)
    if not component then
        if finishCb then
            finishCb()
        end
        return
    end

    local curAlpha = fromAlpha
    component:SetSpineImageAlpha(curAlpha)
    local tween = CSDOTween.To(function()
        return curAlpha
    end, function(alpha)
        curAlpha = alpha
        component:SetSpineImageAlpha(alpha)
    end, toAlpha, duration)

    actor.SpineAlphaFadeTween = tween
    if tween then
        tween:OnComplete(function()
            if actor.SpineAlphaFadeTween == tween then
                actor.SpineAlphaFadeTween = nil
                component:SetSpineImageAlpha(toAlpha)
                component:RequestRender()
                if finishCb then
                    finishCb()
                end
            end
        end)
    elseif finishCb then
        finishCb()
    end
end

function XMovieActionSpineActorDisappear:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.ActorIndexs = {}
    for i = 1, 5 do
        local actorIndex = paramToNumber(params[i])
        if actorIndex ~= 0 then
            self.ActorIndexs[actorIndex] = actorIndex
        end
    end

    self.SkipAnim = paramToNumber(params[6]) ~= 0
    local endDelay = paramToNumber(actionData.EndDelay)
    if endDelay > 0 then
        self.FadeDuration = endDelay * MILLIS_TO_SECONDS
    else
        self.FadeDuration = DEFAULT_FADE_DURATION
    end
end

function XMovieActionSpineActorDisappear:OnEnter()
    for actorIndex, _ in pairs(self.ActorIndexs) do
        local actor = self.UiRoot:GetSpineActor(actorIndex)
        if self.SkipAnim then
            actor:CleanupSpineFadeComponent()
            actor:SetShow(false)
        else
            FadeSpineImageAlpha(actor, 1, 0, self.FadeDuration, function()
                actor:SetShow(false)
                actor:CleanupSpineFadeComponent(false)
            end)
        end
    end
end

function XMovieActionSpineActorDisappear:IsDisappear(actorIndex)
    return self.ActorIndexs[actorIndex] ~= nil
end

return XMovieActionSpineActorDisappear
