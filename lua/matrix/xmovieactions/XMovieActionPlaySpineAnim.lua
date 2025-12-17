local XMovieActionPlaySpineAnim = XClass(XMovieActionBase, "XMovieActionPlaySpineAnim")

function XMovieActionPlaySpineAnim:OnInit(actionData)
    self.AnimationName = actionData.Params[1]
    self.IsLoop = XDataCenter.MovieManager.ParamToNumber(actionData.Params[2]) == 1
end

function XMovieActionPlaySpineAnim:OnEnter()
    ---@type UnityEngine.RectTransform
    local spineRoot = self.UiRoot.PanelSpine
    ---@type Spine.Unity.SkeletonAnimation
    local spineComponent = spineRoot:GetComponentInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    if spineComponent then
        local cb
        cb = function(track)
            spineComponent.AnimationState:SetAnimation(0, self.AnimationName, self.IsLoop)
            spineComponent.AnimationState:Complete('-', cb)
        end
        spineComponent.AnimationState:Complete('+', cb)
    end
end

function XMovieActionPlaySpineAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionPlaySpineAnim:IsActionCover(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_LOAD
end

function XMovieActionPlaySpineAnim:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionPlaySpineAnim
