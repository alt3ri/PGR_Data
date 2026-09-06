local stringUtf8Len = string.Utf8Len
local PlayingCvInfo

---@class XMovieActionFullScreenDialogNewNew
---@field UiRoot XUiMovie
---@field Panel XUiPanelFullScreenDialogNew
local XMovieActionFullScreenDialogNew = XClass(XMovieActionBase, "XMovieActionFullScreenDialogNew")

function XMovieActionFullScreenDialogNew:OnInit(actionData)
    local params = actionData.Params
    self.OriginContent = params[1]
    self.TypeWriteTime = XMVCA.XMovie:ParamToNumber(params[2])
    self.CvId = XMVCA.XMovie:ParamToNumber(params[3])
    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    if XMovieConfigs.IsMovieVoiceMuted(movieId) then
        self.CvId = 0
    end
    self.IsCanSkip = params[4] == nil
    self.EmptyLineCount = XMVCA.XMovie:ParamToNumber(params[5])
    self.IsLastText = params[6] == "1"
    self.IsClose = params[7] == "1"
end

function XMovieActionFullScreenDialogNew:GetEndDelay()
    local isAutoPlay = XDataCenter.MovieManager.GetIsAutoPlay()
    if not self.IsClose and isAutoPlay then
        return XMovieConfigs.AutoPlayDelay + stringUtf8Len(self.Content) * XMovieConfigs.PerWordDelay
    end
    return 0
end

function XMovieActionFullScreenDialogNew:IsBlock()
    return true
end

function XMovieActionFullScreenDialogNew:GetIsClose()
    return self.IsClose
end

function XMovieActionFullScreenDialogNew:CanContinue()
    return not self.IsTyping
end

function XMovieActionFullScreenDialogNew:OnUiRootDestroy()
    self:StopLastCv()
end

function XMovieActionFullScreenDialogNew:OnEnter()
    self.Panel = self.UiRoot:GetPanelFullScreenDialogNew()
    self.Panel:Open()
    self.UiRoot:SetBtnNextCallback(function() self:OnClickBtnSkipDialog() end)

    self.IsTyping = true
    self.Panel:CreateEmptyDialog(self.EmptyLineCount)
    self.Content = XMVCA.XMovie:FormatContent(self.OriginContent)
    self.DialogIndex = self.Panel:ShowDialog(self.Content, self.IsPassedRunning, self.TypeWriteTime, function() 
        self:OnTypeWriterComplete()
    end)
    XDataCenter.MovieManager.PushInReviewDialogList("", self.Content, self.CvId)

    -- 跳过的节点不播Cv
    if self.CvId ~= 0 and not self.IsPassedRunning then
        self:StopLastCv()
        PlayingCvInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, self.CvId)
    end
end

function XMovieActionFullScreenDialogNew:OnTypeWriterComplete()
    self.IsTyping = false
    self.Panel:ShowImgNext(self.IsLastText)

    local isAutoPlay = XDataCenter.MovieManager.GetIsAutoPlay()
    if isAutoPlay then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
    self.UiRoot:RemoveBtnNextCallback()
end

function XMovieActionFullScreenDialogNew:OnClickBtnSkipDialog()
    if self.IsTyping and self.IsCanSkip then
        self.IsSkipped = true
        self.Panel:CompleteDialogTypeWriter(self.DialogIndex)
    end
end

function XMovieActionFullScreenDialogNew:StopLastCv()
    if PlayingCvInfo then
        if PlayingCvInfo.Playing then
            PlayingCvInfo:Stop()
        end
        PlayingCvInfo = nil
    end
end

function XMovieActionFullScreenDialogNew:OnDestroy()
    self.IsTyping = nil
    self.IsSkipped = nil
    self.UiRoot:RemoveBtnNextCallback()

    if self.IsLastText then
        self.Panel:RecycleAllDialog()
    end

    if self.IsClose then
        self:StopLastCv()
        self.Panel:CloseWithAnimation()
    end
    self.Panel = nil
end

function XMovieActionFullScreenDialogNew:OnSwitchAutoPlay(autoPlay)
    if autoPlay and self.IsTyping == false then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, false)
    end
end

function XMovieActionFullScreenDialogNew:OnUndo()
    XDataCenter.MovieManager.RemoveFromReviewDialogList()
end

function XMovieActionFullScreenDialogNew:IsPassedActionRun(index)
    if self.IsClose then return false end
    
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionFullScreenDialogNew:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return action:GetIsClose()
    end
    return false
end

function XMovieActionFullScreenDialogNew:OnPassedActionRun()
    self.IsPassedRunning = true
    self:OnEnter()
    self.IsPassedRunning = false
end

return XMovieActionFullScreenDialogNew