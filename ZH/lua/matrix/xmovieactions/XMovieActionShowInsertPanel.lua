local XMovieActionShowInsertPanel = XClass(XMovieActionBase,"XMovieActionShowInsertPanel")
local vector = CS.UnityEngine.Vector3

---@class XMovieActionShowInsertPanel
---@field UiRoot XUiMovie
function XMovieActionShowInsertPanel:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.BgPath = params[1]
    self.Direction =  paramToNumber(params[2])
end

function XMovieActionShowInsertPanel:OnRunning()
    self.UiRoot:SetInsertPanelBg(self.BgPath,self.Direction)
    self.UiRoot:PlayInsertPanelEnableAnimation(self.Direction)
end

function XMovieActionShowInsertPanel:OnUndo()
    self.UiRoot:PlayInsertPanelDisableAnimation(self.Direction)
end

function XMovieActionShowInsertPanel:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

function XMovieActionShowInsertPanel:GetDirection()
    return self.Direction
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionShowInsertPanel:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then 
        return self.Direction == action:GetDirection()
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.INSERT_PANEL_HIDE then
        return self.Direction == action:GetDirection()
    end
    return false
end

function XMovieActionShowInsertPanel:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionShowInsertPanel