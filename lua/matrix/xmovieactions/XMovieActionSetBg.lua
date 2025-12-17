local XMovieActionSetBg = XClass(XMovieActionBase,"XMovieActionSetBg")

function XMovieActionSetBg:OnInit(actionData)
    self.BgPath = actionData.Params[1]
end

function XMovieActionSetBg:OnRunning()
    self.UiRoot:SetMixBg(self.BgPath)
end

return XMovieActionSetBg