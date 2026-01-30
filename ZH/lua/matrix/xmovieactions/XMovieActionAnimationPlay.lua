---@class XMovieActionAnimationPlay
---@field UiRoot XUiMovie
local XMovieActionAnimationPlay = XClass(XMovieActionBase, "XMovieActionAnimationPlay")

function XMovieActionAnimationPlay:OnInit(actionData)
    local params = actionData.Params
    self.AnimName = params[1]
end

function XMovieActionAnimationPlay:OnRunning()
    local animName = self.AnimName
    local anim = self.UiRoot:GetUiAnimation(animName)
    if not anim then
        XLog.Error("XMovieActionAnimationPlay:OnRunning error: Animation not Exist, animName is: " .. animName)
        return
    end

    -- 父节点隐藏导致的动画节点隐藏
    if not anim.transform.parent.gameObject.activeInHierarchy then
        anim.gameObject:SetActiveEx(false)
        return
    end

    -- 是否是循环动画
    local isLoop = false
    local director = anim.transform:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    local directorWrapModeLoop = CS.UnityEngine.Playables.DirectorWrapMode.Loop
    if director and director.extrapolationMode == directorWrapModeLoop then
        isLoop = true
    end

    self:StopAnimtion(anim)
    anim.gameObject:SetActiveEx(true)
    if isLoop then
        anim:PlayTimelineAnimation(nil, nil, directorWrapModeLoop)
    else
        anim:PlayTimelineAnimation(function()
            anim.gameObject:SetActiveEx(false)
        end)
    end
end

function XMovieActionAnimationPlay:StopAnimtion(anim)
    local timelineAnimation = anim.transform:GetComponent(typeof(CS.XUiPlayTimelineAnimation))
    if timelineAnimation then
        timelineAnimation:Stop(false)
    end
end

return XMovieActionAnimationPlay