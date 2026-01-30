local XMovieActionSwitchMixMode = XClass(XMovieActionBase,"XMovieActionSwitchMixMode")

function XMovieActionSwitchMixMode:OnInit(actionData)
    
end

function XMovieActionSwitchMixMode:OnEnter()
    self.UiRoot:SwitchMixPanel()
end

function XMovieActionSwitchMixMode:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

function XMovieActionSwitchMixMode:IsAdvanceStartAction()
    return true
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSwitchMixMode:IsActionCover(action)
    return action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.BG_SWITCH
end

return XMovieActionSwitchMixMode