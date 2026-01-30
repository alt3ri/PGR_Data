local XMovieActionInterrupt = XClass(XMovieActionBase, "XMovieActionInterrupt")

function XMovieActionInterrupt:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.CueId = paramToNumber(params[1])
end

function XMovieActionInterrupt:OnRunning()
    XLuaAudioManager.StopAudioByCueId(self.CueId)
end

function XMovieActionInterrupt:GetCueId()
    return self.CueId
end

return XMovieActionInterrupt