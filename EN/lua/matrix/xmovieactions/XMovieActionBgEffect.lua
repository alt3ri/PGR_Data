---@class XMovieActionBgEffect
---@field UiRoot XUiMovie
local XMovieActionBgEffect = XClass(XMovieActionBase, "XMovieActionBgEffect")

function XMovieActionBgEffect:OnInit(actionData)
    local params = actionData.Params
    self.IsShowEffect = params[1] == "1"
    self.EffectPath = params[2]
    self.EffectType = self:GetEffectType()
end

function XMovieActionBgEffect:OnEnter()
    if self.EffectType == XMVCA.XMovie.EnumConst.EFFECT_TYPE.SCREENSHOT then
        local fullScreenBackground = self.UiRoot.Transform:Find("FullScreenBackground")
        if self.IsShowEffect then
            self:LoadScreenshotEffect(fullScreenBackground)
        else
            self:ReleaseEffect(fullScreenBackground)
        end
    else
        local rImgBg = self.UiRoot.UiMovieBg:GetBg(1):GetRImgBg()
        if self.IsShowEffect then
            self:LoadEffect(rImgBg)
        else
            self:ReleaseEffect(rImgBg)
        end
    end
end

-- 释放特效
function XMovieActionBgEffect:ReleaseEffect(link)
    local loader = link:GetComponent(typeof(CS.XUiLoadPrefab))
    if loader then
        CS.UnityEngine.Object.DestroyImmediate(loader)
    end
end

-- 加载屏幕截图特效
function XMovieActionBgEffect:LoadScreenshotEffect(parent)
    -- 截图组件
    local component = self.UiRoot.UIScreenTrigger
    if not component then
        component = self.UiRoot.GameObject:AddComponent(typeof(CS.XACaptureUIScreenTrigger))
        self.UiRoot.UIScreenTrigger = component
    end
    component.enabled = false
    component.enabled = true

    -- 截图超过1帧再加载特效
    XScheduleManager.ScheduleOnce(function()
        self:LoadEffect(parent)
    end, 50)
end

-- 加载特效
---@param parent Transform 特效挂点
function XMovieActionBgEffect:LoadEffect(parent)
    if not parent or not self.EffectPath then return end

    local effectGo = parent.transform:LoadPrefab(self.EffectPath)
    effectGo.gameObject:SetActive(false)
    effectGo.gameObject:SetActive(true)

    -- 通用组件处理
    -- 动态模糊组件
    local component = effectGo:GetComponent("XARawImageMaterialAnimationBinder")
    if component then
        component.enabled = true
        component:SetupRenderer(parent)
        component:PlayAnimation()
    end
end

-- 获取特效类型
function XMovieActionBgEffect:GetEffectType()
    -- 需要截图的特效
    local params = XMVCA.XMovie:GetClientConfigParams("ScreenshotEffect")
    for _, effectPath in ipairs(params) do
        if self.EffectPath == effectPath then
            return XMVCA.XMovie.EnumConst.EFFECT_TYPE.SCREENSHOT
        end
    end
end

function XMovieActionBgEffect:IsPassedActionRun(index)
    -- 隐藏action跳过
    if not self.IsShowEffect then return false end

    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

function XMovieActionBgEffect:IsAdvanceStartAction()
    return true
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionBgEffect:IsActionCover(action)
    if action:GetType() == self:GetType() and self.EffectType == action:GetEffectType() then
        return true
    end
    return false
end

function XMovieActionBgEffect:OnPassedActionRun()
    self:OnEnter()
end

function XMovieActionBgEffect:IsStartAfterLoading()
    return self.EffectType == XMVCA.XMovie.EnumConst.EFFECT_TYPE.SCREENSHOT
end

return XMovieActionBgEffect