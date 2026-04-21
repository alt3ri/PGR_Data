local XMovieActionLeftTitleAppear = XClass(XMovieActionBase, "XMovieActionLeftTitleAppear")

function XMovieActionLeftTitleAppear:OnInit(actionData)
    local params = actionData.Params

    self.Title = XMVCA.XMovie:FormatContent(params[1])
    self.Subtitle = XMVCA.XMovie:FormatContent(params[2])
    self.TitleEn = XMVCA.XMovie:FormatContent(params[3])
    self.Subtitle2 = XMVCA.XMovie:FormatContent(params[4])
    self.Subtitle3 = XMVCA.XMovie:FormatContent(params[5])
end

function XMovieActionLeftTitleAppear:OnRunning()
    self.UiRoot.PanelLeftTitle.gameObject:SetActiveEx(true)
    local titleLocation
    if XOverseaManager.IsOverSeaRegion() then
        titleLocation = string.gsub(self.Title, "\\n", "\n")
    else
        titleLocation = self.Title
    end
    local uiObj = self.UiRoot.PanelLocationTip
    uiObj:GetObject("TxtLocation").text = titleLocation
    uiObj:GetObject("TxtSubtitle").text = self.Subtitle
    uiObj:GetObject("TxtLocationEn").text = self.TitleEn
    uiObj:GetObject("AnimEnable").gameObject:PlayTimelineAnimation()
    uiObj:GetObject("TxtSubtitle2").text = self.Subtitle2
    uiObj:GetObject("TxtSubtitle3").text = self.Subtitle3
end

function XMovieActionLeftTitleAppear:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionLeftTitleAppear:IsPassedActionCovered(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.LEFT_TITLE_DISAPPEAR
end

function XMovieActionLeftTitleAppear:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionLeftTitleAppear