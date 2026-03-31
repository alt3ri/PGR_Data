local XMovieActionPlaySpineAnim = XClass(XMovieActionBase, "XMovieActionPlaySpineAnim")

function XMovieActionPlaySpineAnim:OnInit(actionData)
    self.AnimationName = actionData.Params[1]
    self.IsLoop = XDataCenter.MovieManager.ParamToNumber(actionData.Params[2]) == 1
    self.ComponentPath = actionData.Params[3]
    self.IsSwitchImmediately = actionData.Params[4] == "1" -- 是否立刻切换
end

function XMovieActionPlaySpineAnim:OnEnter()
    ---@type Spine.Unity.SkeletonAnimation
    local spineComponent = self:GetSpineComponent()
    if not spineComponent then return end
    
    if self.IsSwitchImmediately then
        spineComponent.AnimationState:SetAnimation(0, self.AnimationName, self.IsLoop)
    else
        local cb
        cb = function(track)
            spineComponent.AnimationState:SetAnimation(0, self.AnimationName, self.IsLoop)
            spineComponent.AnimationState:Complete('-', cb)
        end
        spineComponent.AnimationState:Complete('+', cb)
    end
end

---@return Spine.Unity.SkeletonAnimation
function XMovieActionPlaySpineAnim:GetSpineComponent()
    ---@type UnityEngine.RectTransform
    local spineRoot = self.UiRoot.PanelSpine
    if string.IsNilOrEmpty(self.ComponentPath) then
        return spineRoot:GetComponentInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    else
        local spine = spineRoot.transform:GetChild(0)
        if spine then
            return spine:Find(self.ComponentPath):GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
        end
    end
end

function XMovieActionPlaySpineAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionPlaySpineAnim:IsPassedActionCovered(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_LOAD
end

function XMovieActionPlaySpineAnim:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionPlaySpineAnim
