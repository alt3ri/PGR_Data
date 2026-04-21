local XMovieActionSpineAnim = XClass(XMovieActionBase, "XMovieActionSpineAnim")

function XMovieActionSpineAnim:OnInit(actionData)
    self.SpinePath = actionData.Params[1]
end

function XMovieActionSpineAnim:OnEnter()
    self.UiRoot.PanelSpine.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.SpinePath))
    if not string.IsNilOrEmpty(self.SpinePath) then
        self.UiRoot.PanelSpine:LoadPrefab(self.SpinePath)
    end
end

function XMovieActionSpineAnim:IsPassedActionRun(index)
    local isUnload = string.IsNilOrEmpty(self.SpinePath)
    if isUnload then return false end

    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSpineAnim:IsPassedActionCovered(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SPINE_LOAD
end

function XMovieActionSpineAnim:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionSpineAnim
