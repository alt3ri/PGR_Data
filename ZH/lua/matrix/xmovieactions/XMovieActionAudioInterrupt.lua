local XMovieActionInterrupt = XClass(XMovieActionBase, "XMovieActionInterrupt")

function XMovieActionInterrupt:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    -- 参数1=普通音频CueId，参数2=配音CvId。两套编号空间各占一位，按需各自打断
    self.CueId = paramToNumber(params[1])
    self.CvId = paramToNumber(params[2])
end

function XMovieActionInterrupt:OnRunning()
    if XTool.IsNumberValid(self.CueId) then
        XLuaAudioManager.StopAudioByCueId(self.CueId)
    end
    if XTool.IsNumberValid(self.CvId) then
        CS.XAudioManager.StopCv(self.CvId)
    end
end

function XMovieActionInterrupt:GetCueId()
    return self.CueId
end

function XMovieActionInterrupt:GetCvId()
    return self.CvId
end

return XMovieActionInterrupt