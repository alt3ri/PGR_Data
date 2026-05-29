local XMovieActionVideoPlayNew = XClass(XMovieActionBase, "XMovieActionVideoPlay")

--- 视频播放(UiMovie内置视频播放，可叠加UiMovie的其他UI表现)
---@class XMovieActionVideoPlayNew
---@field UiRoot XUiMovie
function XMovieActionVideoPlayNew:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.VideoId = paramToNumber(params[1])
    self.WaitVideoFinish = params[2] == "1"
end

function XMovieActionVideoPlayNew:IsBlock()
    return self.WaitVideoFinish
end

function XMovieActionVideoPlayNew:OnRunning()
    self.UiRoot:PlayVideo(self.VideoId, self.WaitVideoFinish)
end


return XMovieActionVideoPlayNew