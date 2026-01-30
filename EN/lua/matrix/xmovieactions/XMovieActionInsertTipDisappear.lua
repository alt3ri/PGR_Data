local XMovieActionInsertTipDisappear = XClass(XMovieActionBase,"XMovieActionInsertTipDisappear")

function XMovieActionInsertTipDisappear:OnInit(actionData)
    
end

function XMovieActionInsertTipDisappear:OnRunning()
    self.UiRoot:HideInsertTips()
end

return XMovieActionInsertTipDisappear