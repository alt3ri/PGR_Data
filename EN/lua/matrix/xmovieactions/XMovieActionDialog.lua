local pairs = pairs
local stringUtf8Len = string.Utf8Len
local SPINE_INDEX_OFFSET = 100 -- spine位置的偏移值

---@class XMovieActionDialog
---@field UiRoot XUiMovie
local XMovieActionDialog = XClass(XMovieActionBase, "XMovieActionDialog")

function XMovieActionDialog:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.IsBlockTypeWriter = params[17] == "1" -- 打字机是否不可点击跳过，并在打字机播放完自动进入下一个节点
    self.CvId = paramToNumber(params[18])
    self.SpineActorIndexs = XMVCA.XMovie:SplitParam(params[19], "&",true)
    self.SpineActorKouSpeed = paramToNumber(params[20])
    self.LipAnimFolder = params[21] -- 嘴唇动画的文件夹名称
    self.IsAppendContent = params[22] == "1" -- 是否是追加文本的形式展示
    self.IsInReview = params[23] ~= "1" -- 是否进回顾。默认进回顾，配置1为不进回顾
    self.SkipRoleAnim = paramToNumber(params[1]) ~= 0
    self.RoleName = XUiHelper.ConvertLineBreakSymbol(XDataCenter.MovieManager.ReplacePlayerName(params[2]))
    self.Content = params[3] -- 配置内容
    self.DialogContent = "" -- 对话实际显示内容
    self.SpeakerIndexDic = {}
    self.SpeakerSpineIndexDic = {}

    -- params[4]-params[17]用于配置讲话的立绘/Spine
    for i = 4, 17 do
        local actorIndex = paramToNumber(params[i])
        if actorIndex ~= 0 then
            -- 配置1，则为立绘第1个位置，配置(SPINE_INDEX_OFFSET+1)则为spine第1个位置
            if actorIndex < SPINE_INDEX_OFFSET then
                self.SpeakerIndexDic[actorIndex] = true
            else
                actorIndex = actorIndex - SPINE_INDEX_OFFSET
                self.SpeakerSpineIndexDic[actorIndex] = true
            end
        end
    end

    -- 空文本报错提示
    if not self.Content or self.Content == "" then
        XLog.Error("XMovieActionDialog:OnRunning error:DialogContent is empty, actionId is: " .. self.ActionId)
    end
end

function XMovieActionDialog:GetEndDelay()
    if self.IsAutoPlay then
        local speed = XDataCenter.MovieManager.GetSpeed()
        local delayTime = XMovieConfigs.AutoPlayDelay + stringUtf8Len(self.DialogContent) * XMovieConfigs.PerWordDelay / speed
        delayTime = math.floor(delayTime)
        return delayTime
    elseif self.IsBlockTypeWriter then
        return self.EndDelay
    else
        return 0
    end
end

function XMovieActionDialog:IsBlock()
    return true
end

function XMovieActionDialog:OnEnter()
    self:GenDialogContent()
    self.IsAutoPlay = XDataCenter.MovieManager.GetIsAutoPlay()
    self.UiRoot:SetBtnNextCallback(function() self:OnClickBtnSkipDialog() end)
    self.UiRoot.DialogTypeWriter.CompletedHandle = function() self:OnTypeWriterComplete() end
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(true)
    self.Record = {
        DialogContent = self.UiRoot.TxtWords.text,
        IsActive = self.UiRoot.PanelDialog.gameObject.activeSelf
    }
    local roleName = self.RoleName
    local dialogContent = self.DialogContent
    self.UiRoot.TxtName.text = roleName
    self.UiRoot.TxtWords.text = dialogContent
    self.UiRoot.TxtName.gameObject:SetActiveEx(roleName ~= "")

    self.IsTyping = true
    local typeWriter = self.UiRoot.DialogTypeWriter
    local speed = XDataCenter.MovieManager.GetSpeed()
    typeWriter.Duration = stringUtf8Len(dialogContent) * XMovieConfigs.TYPE_WRITER_SPEED / speed
    if self.IsAppendContent then
        typeWriter:AppendPlay()
    else
        typeWriter:Play()
    end
    -- 加速播放时，不播音效
    if self.CvId ~= 0 and not XDataCenter.MovieManager.IsSpeedUp() then
        if self.AudioInfo then
            self.AudioInfo:Stop()
            self.AudioInfo = nil
        end
        self.IsAudioing = true
        self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, self.CvId, function()
            if self.IsDestroy then return end
            self:OnAudioComplete()
            self:StopSpineActorTalk()
        end)
        self:PlaySpineActorTalk()
        self:PlayAudioLipAnim()
    end
    self:PlaySpeakerAnim()
    if self.IsInReview then
        XDataCenter.MovieManager.PushInReviewDialogList(roleName, dialogContent, self.CvId, XMVCA.XMovie.EnumConst.ACTION_TYPE.DIALOG)
    end
end

function XMovieActionDialog:OnDestroy()
    self.IsDestroy = true
    self.IsTyping = nil
    self.IsAutoPlay = nil
    self.IsAudioing = nil
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
    self:StopSpineActorTalk()
    self:StopAudioLipAnim()
    self:ClearDelayId() -- 清理定时器
    self.UiRoot:RemoveBtnNextCallback()
end

function XMovieActionDialog:OnClickBtnSkipDialog()
    if self.IsTyping then
        -- 设置打字机不可跳过
        if self.IsBlockTypeWriter then return end
        
        -- 打字中，直接显示完所有字体
        self.IsTyping = false
        self.UiRoot.DialogTypeWriter:ShowAllText()
    else
        -- 字体完全显示，点击屏幕播放下一个MovieAction
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, false)
    end
end

function XMovieActionDialog:CanContinue()
    return not self.IsTyping
end

function XMovieActionDialog:OnTypeWriterComplete()
    self.IsTyping = false

    -- 自动播放状态，打字完、语音播放完，播放下一个MovieAction
    if self.IsAutoPlay and not self.IsAudioing then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    -- 打字机不可跳过，在打字机播放完自动进入下一个节点
    elseif self.IsBlockTypeWriter then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, false)
    end
end

function XMovieActionDialog:OnAudioComplete()
    self.IsAudioing = false

    -- 自动播放状态，打字完、语音播放完，播放下一个MovieAction
    if self.IsAutoPlay and not self.IsTyping then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    -- 打字机不可跳过，在打字机播放完自动进入下一个节点
    elseif self.IsBlockTypeWriter then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, false)
    end
end

function XMovieActionDialog:OnSwitchAutoPlay(autoPlay)
    self.IsAutoPlay = autoPlay
    self:ClearDelayId() -- 清理定时器
    
    -- self.IsTyping == false 只处理当前dialog打印结束的情况
    -- 发送事件触发MovieManager.DoAction()，执行action的Exit()函数，即开启结束定时器
    if autoPlay and self.IsTyping == false and not self.IsAudioing then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionDialog:PlaySpeakerAnim()
    local skipAnim = self.SkipRoleAnim

    local speakerIndexDic = self.SpeakerIndexDic
    local actors = self.UiRoot.Actors
    for index, actor in pairs(actors) do
        if not speakerIndexDic[index] then
            actor:PlayAnimBack(skipAnim)
        else
            actor:PlayAnimFront(skipAnim)
        end
    end

    local spineActors = self.UiRoot.SpineActors
    for index, spineActor in pairs(spineActors) do
        if self.SpeakerSpineIndexDic[index] then
            spineActor:PlayAnimFront(skipAnim)
        else
            spineActor:PlayAnimBack(skipAnim)
        end
    end
end

-- 播放音频嘴型动画
function XMovieActionDialog:PlayAudioLipAnim()
    if self.LipAnimFolder and not XDataCenter.MovieManager.IsSpeedUp() then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:PlayLipAnim(self.LipAnimFolder, self.CvId)
        end
    end
end

-- 停止音频嘴型动画
function XMovieActionDialog:StopAudioLipAnim()
    if self.LipAnimFolder and not XDataCenter.MovieManager.IsSpeedUp() then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:StopLipAnim()
        end
    end
end

function XMovieActionDialog:OnUndo()
    self.UiRoot.TxtWords.text = self.Record.DialogContent
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(self.Record.IsActive)
    self.UiRoot.DialogTypeWriter.CompletedHandle = nil
    self:OnDestroy()
    XDataCenter.MovieManager.RemoveFromReviewDialogList(self.ActionId)
end

-- 播放语音时切换spine讲话动画
function XMovieActionDialog:PlaySpineActorTalk()
    if #self.SpineActorIndexs > 0 and not self.LipAnimFolder then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            if actor then
                actor:PlayKouTalkAnim(self.SpineActorKouSpeed)
            end
        end
    end
end

-- 停止spine讲话动画，切回之前的动画
function XMovieActionDialog:StopSpineActorTalk()
    if #self.SpineActorIndexs > 0 and not self.LipAnimFolder then
        for _, index in ipairs(self.SpineActorIndexs) do
            local actor = self.UiRoot:GetSpineActor(index)
            if actor then
                actor:PlayKouIdleAnim()
            end
        end
    end
end

-- 生成要显示的DialogContent
function XMovieActionDialog:GenDialogContent()
    if self.IsAppendContent then
        local dialogData = XDataCenter.MovieManager.PopLastReviewDialog(XMVCA.XMovie.EnumConst.ACTION_TYPE.DIALOG)
        local lastContent = dialogData and dialogData.Content or ""
        self.DialogContent = lastContent .. XMVCA.XMovie:FormatContent(self.Content)
    else
        self.DialogContent = XMVCA.XMovie:FormatContent(self.Content)
    end
end

function XMovieActionDialog:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionDialog:IsPassedActionCovered(action)
    return action:GetType() == self:GetType()
end

function XMovieActionDialog:OnPassedActionRun()
    self:GenDialogContent()
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(true)
    self.UiRoot.TxtName.text = self.RoleName
    self.UiRoot.TxtWords.text = self.DialogContent
    self.UiRoot.TxtName.gameObject:SetActiveEx(self.RoleName ~= "")
    self:PlaySpeakerAnim()
    if self.IsInReview then
        XDataCenter.MovieManager.PushInReviewDialogList(self.RoleName, self.DialogContent, self.CvId, XMVCA.XMovie.EnumConst.ACTION_TYPE.DIALOG)
    end
end

function XMovieActionDialog:OnPassedActionSkip()
    self:GenDialogContent()
    if self.IsInReview then
        XDataCenter.MovieManager.PushInReviewDialogList(self.RoleName, self.DialogContent, self.CvId, XMVCA.XMovie.EnumConst.ACTION_TYPE.DIALOG)
    end
end

return XMovieActionDialog
