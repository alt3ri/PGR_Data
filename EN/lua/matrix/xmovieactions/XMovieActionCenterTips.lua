local XMovieActionCenterTips = XClass(XMovieActionBase, "XMovieActionCenterTips")

function XMovieActionCenterTips:OnInit(actionData)
    local params = actionData.Params

    self.Content = XMVCA.XMovie:FormatContent(params[1])
    self.IsHide = params[2] == "1"
    self.FontSize = params[3]
    self.FontColor = params[4]
    self.IsLeft = params[5] == "1"
    self.IsBgHide = params[6] == "1"
end

function XMovieActionCenterTips:OnEnter()
    self.UiRoot.PanelCenterTip.gameObject:SetActiveEx(not self.IsHide)
    if self.IsHide then
        return
    end

    local content = self.Content
    if self.FontSize and self.FontColor then
        content = string.format("<size=%s><color=#%s>%s</color></size>", self.FontSize, self.FontColor, self.Content)
    elseif self.FontSize then
        content = string.format("<size=%s>%s</size>", self.FontSize, self.Content)
    elseif self.FontColor then
        content = string.format("<color=#%s>%s</color>", self.FontColor, self.Content)
    end
    self.UiRoot.TxtCenterTipDescMid.text = content
    self.UiRoot.TxtCenterTipDescMid.gameObject:SetActiveEx(not self.IsLeft)
    self.UiRoot.TxtCenterTipDescLeft.text = content
    self.UiRoot.TxtCenterTipDescLeft.gameObject:SetActiveEx(self.IsLeft)
    self.UiRoot.PanelCenterTipBg.enabled = not self.IsBgHide
end


function XMovieActionCenterTips:IsPassedActionRun(index)
    if self.IsHide then return false end

    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionCenterTips:IsPassedActionCovered(action)
    return action:GetType() == self:GetType()
end

function XMovieActionCenterTips:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionCenterTips