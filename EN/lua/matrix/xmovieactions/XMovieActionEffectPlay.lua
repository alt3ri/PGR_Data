local stringFormat = string.format
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XMovieActionEffectPlay = XClass(XMovieActionBase, "XMovieActionEffectPlay")

function XMovieActionEffectPlay:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.EffectPath = params[1]
    self.EffectLayer = paramToNumber(params[2])
    self.EffectActorIndex = paramToNumber(params[3])
    self.BodyActorIndex = paramToNumber(params[4])
    self.EffectKey = params[5]
end

function XMovieActionEffectPlay:OnEnter()
    XLuaUiManager.SetMask(true)
end

function XMovieActionEffectPlay:OnRunning()
    local effectPath = self.EffectPath
    local effectActorIndex = self.EffectActorIndex
    local isActorEffect = effectActorIndex > 0 and effectActorIndex <= XMovieConfigs.MAX_ACTOR_NUM
    self.EffectKey = self:GetEffectKey()

    local effectGo = self.UiRoot.EffectGoDic[self.EffectKey]
    if not effectGo then
        local baseEffectGo, parentGo, effectLayer

        if isActorEffect then
            local actor = self.UiRoot:GetActor(effectActorIndex)
            baseEffectGo = actor:GetEffectGo()
            parentGo = actor:GetEffectParentGo()
        else
            effectLayer = self.EffectLayer
            baseEffectGo = self.UiRoot.PanelEffects[effectLayer]
            parentGo = self.UiRoot.PanelEffect
        end

        if not baseEffectGo then
            XLog.Error("XMovieActionEffectPlay:OnRunning error: can Not find baseEffectGo, effectActorIndex is: " .. effectActorIndex .. ", effectLayer is: " .. effectLayer)
            return
        end

        ---@type UnityEngine.GameObject
        effectGo = CSUnityEngineObjectInstantiate(baseEffectGo)
        effectGo.transform:SetParent(parentGo, false)

        self.UiRoot.EffectGoDic[self.EffectKey] = effectGo
        effectGo.gameObject:LoadUiEffect(effectPath)
        if self.BodyActorIndex > 0 then
            local actor = self.UiRoot:GetActor(self.BodyActorIndex)
            local path = XMovieConfigs.GetActorImgPath(actor.ActorId)
            local texture = self.UiRoot:LoadResource(path)

            local bodyParticle = effectGo.transform:FindTransform("lihui")
            if bodyParticle then
                local renderer = bodyParticle:GetComponent(typeof(CS.UnityEngine.Renderer))
                renderer.material:SetTexture("_MainTex", texture)
            end
        end
    else
        effectGo.gameObject:SetActiveEx(false)
        effectGo.gameObject:SetActiveEx(true)
        if self.BodyActorIndex > 0 then
            local actor = self.UiRoot:GetActor(self.BodyActorIndex)
            local path = XMovieConfigs.GetActorImgPath(actor.ActorId)
            local texture = self.UiRoot:LoadResource(path)

            local bodyParticle = effectGo.transform:FindTransform("lihui")
            if bodyParticle then
                local renderer = bodyParticle:GetComponent(typeof(CS.UnityEngine.Renderer))
                renderer.material:SetTexture("_MainTex", texture)
            end
        end
    end
end

function XMovieActionEffectPlay:OnExit()
    XLuaUiManager.SetMask(false)
end

function XMovieActionEffectPlay:GetEffectKey()
    if not string.IsNilOrEmpty(self.EffectKey) then
        return self.EffectKey
    end

    if self.EffectActorIndex > 0 and self.EffectActorIndex <= XMovieConfigs.MAX_ACTOR_NUM then
        return string.format("%s%s", self.EffectPath, self.EffectActorIndex)
    else
        return self.EffectPath
    end
end

function XMovieActionEffectPlay:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionEffectPlay:IsActionCover(action)
    if action:GetType() == self:GetType() or action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.EFFECT_UNLOAD then
        return action:GetEffectKey() == self:GetEffectKey()
    end
    return false
end

function XMovieActionEffectPlay:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionEffectPlay