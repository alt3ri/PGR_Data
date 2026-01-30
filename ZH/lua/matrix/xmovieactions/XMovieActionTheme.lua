local XMovieActionTheme = XClass(XMovieActionBase, "XMovieActionTheme")

function XMovieActionTheme:OnInit(actionData)
    local params = actionData.Params

    self.Title = XMVCA.XMovie:FormatContent(params[1])
    self.Content = XMVCA.XMovie:FormatContent(params[2])
    self.LogoPath = params[3]
    self.Content2 = XMVCA.XMovie:FormatContent(params[4])
end

function XMovieActionTheme:OnEnter()
    self.UiRoot.TxtTitle.text = self.Title
    self.UiRoot.TxtContent.text = self.Content
    self.UiRoot:SetUiSprite(self.UiRoot.ImgLogo, self.LogoPath)
    self.UiRoot.PanelTheme.gameObject:SetActiveEx(true)

    local showContent2 = self.Content2 and self.Content2 ~= ""
    self.UiRoot.TxtContent2.gameObject:SetActiveEx(showContent2)
    self.UiRoot.TxtContent2.text = self.Content2
end

function XMovieActionTheme:OnExit()
    -- self.UiRoot.PanelTheme.gameObject:SetActiveEx(false)
end

function XMovieActionTheme:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionTheme:IsActionCover(action)
    if action:GetType() == self:GetType() then
        return true
    end

    if action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.ANIMATION_PLAY then
        local params = action:GetParams()
        local animName = params[1]
        if animName == XMVCA.XMovie.EnumConst.ANIMATION.THEME_ENABLE then
            return true
        end
    end

    return false
end

function XMovieActionTheme:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionTheme