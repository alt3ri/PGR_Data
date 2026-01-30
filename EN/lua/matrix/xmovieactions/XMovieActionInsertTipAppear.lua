local XMovieActionInsertTipAppear = XClass(XMovieActionBase,"XMovieActionInsertTipAppear")

function XMovieActionInsertTipAppear:OnInit(actionData)
    self.BgPath = actionData.Params[1]
end

function XMovieActionInsertTipAppear:OnRunning()
    self.UiRoot:SetInsertBg(self.BgPath)
    self.UiRoot:ShowInsertTips()
end

function XMovieActionInsertTipAppear:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionInsertTipAppear:IsActionCover(action)
    return action:GetType() == self:GetType() or action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.TIP_DISAPPEAR
end

function XMovieActionInsertTipAppear:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionInsertTipAppear