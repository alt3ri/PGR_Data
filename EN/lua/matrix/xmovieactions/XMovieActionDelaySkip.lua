local XMovieActionDelaySkip = XClass(XMovieActionBase, "XMovieActionDelaySkip")

function XMovieActionDelaySkip:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.DelaySelectKey = paramToNumber(params[1])
end

function XMovieActionDelaySkip:GetDelaySelectKey()
    return self.DelaySelectKey
end

function XMovieActionDelaySkip:GetDelaySelectActionId()
    return XDataCenter.MovieManager.GetDelaySelectActionId(self.DelaySelectKey)
end

return XMovieActionDelaySkip