---@class XMessagePlayer
local XMessagePlayer = XClass(nil, "XMessagePlayer")

local State = {
    None = 0,
    Playing = 1,
}

---@param message XBWMessageEntity
function XMessagePlayer:Ctor(proxy, message)
    ---@type XBWMessageContentEntity
    self._AwaitRecordContent = false
    self._State = State.None
    self._Timer = false
    self._IsBeginLoading = false

    self:SetMessage(message)
    self:SetProxy(proxy)
end

---@param message XBWMessageEntity
function XMessagePlayer:SetMessage(message)
    self:Stop()
    self._CurrentStepId = -1
    self._Message = message
end

function XMessagePlayer:SetProxy(proxy)
    self._Proxy = proxy
end

function XMessagePlayer:IsPlaying()
    return self._State ~= State.None
end

--- 短信是否播放过
---@return boolean
function XMessagePlayer:IsMessagePlayed()
    if self:IsExist() then
        return self._Message:IsComplete()
    end

    return true
end

function XMessagePlayer:Play()
    if self:IsExist() then
        self:Stop()
        self:_RecordAwait()
        XMVCA.XBigWorldMessage:RecordStatistical(self._Message:GetMessageId(), XMVCA.XBigWorldMessage.OperatorType.Read)
        self:_ChangeState(State.Playing)
    end
end

function XMessagePlayer:Stop()
    self:_ChangeState(State.None)
end

function XMessagePlayer:IsExist()
    return self._Message and not self._Message:IsNil()
end

function XMessagePlayer:Destroy()
    self:Stop()
    self:_RecordAwait()
    self._Proxy = nil
    self._Message = nil
end

function XMessagePlayer:_RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XMessagePlayer:_Play()
    self._CurrentStepId = self._Message:GetFirstStepId()
    self:_OnPlayNextNotify()
end

---@param content XBWMessageContentEntity
function XMessagePlayer:_PlayNext(content, isRecord)
    self:_RemoveTimer()

    local duration = content:GetDuration()
    local isComplete = content:IsComplete()

    if XTool.IsNumberValid(duration) and not isComplete then
        CS.XLog.Debug("[BigWorldMessage]: Play NonComplete Message Content, Duration: " .. tostring(duration) .. "\n" .. debug.traceback())

        self:_OnProxyPlayBeginLoading(content)
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self._Timer = false
            self:_OnPlaying(content, isRecord)
        end, duration * XScheduleManager.SECOND)
    else
        if isComplete then
            CS.XLog.Debug("[BigWorldMessage]: Play Complete Message Content.\n" .. debug.traceback())
        else
            CS.XLog.Debug("[BigWorldMessage]: Play NonComplete Message Content, Duration: 0\n" .. debug.traceback())
        end
        self:_OnPlaying(content, isRecord)
    end
end

---@param content XBWMessageContentEntity
function XMessagePlayer:_OnPlaying(content, isRecord)
    self:_OnProxyPlayEndLoading(content)
    self:_OnProxyPlay(content)

    if content:IsEnd() then
        CS.XLog.Debug("[BigWorldMessage]: Play Message Content Finish.\n" .. debug.traceback())
        self:_RequestCurrentMessageReadRecord(content)
        self:Stop()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY)
    elseif content:IsOptions() then
        self:_RequestCurrentMessageReadRecord(content)
    elseif isRecord then
        self:_RequestCurrentMessageReadRecord(content)
    end

    content:Read()
end

function XMessagePlayer:_OnProxyPlay(content)
    if self._Proxy and self._Proxy.OnPlayMessage then
        self._Proxy:OnPlayMessage(content)
    end
end

function XMessagePlayer:_OnPlayNextNotify()
    if self:IsPlaying() and self:IsExist() then
        local content = self._Message:GetContentByStepId(self._CurrentStepId)

        if content then
            if content:IsCompleteWithOption() or not content:IsOptions() then
                self._CurrentStepId = content:GetNextStepId()
            end

            self:_PlayNext(content)
        end
    end
end

function XMessagePlayer:_OnOptionsSelectNotify(index)
    if self:IsPlaying() and self:IsExist() then
        local content = self._Message:GetContentByStepId(self._CurrentStepId)

        if content then
            local selectStep = content:GetOprionsNextStepByIndex(index)
            local selectContent = self._Message:GetContentByStepId(selectStep)

            if selectContent then
                if not selectContent:IsOptions() then
                    if not selectContent:IsEnd() then
                        self._CurrentStepId = selectContent:GetNextStepId()
                    end
                else
                    XLog.Error("当前短信存在相连的两个选项节点！ StepId = " .. tostring(selectStep))
                end

                XMVCA.XBigWorldMessage:RecordStatistical(selectContent:GetMessageId(), XMVCA.XBigWorldMessage.OperatorType.Reply, selectStep)
                self:_PlayNext(selectContent, true)
            end
        end
    end
end

function XMessagePlayer:_OnProxyPlayBeginLoading(content)
    self._IsBeginLoading = true
    if self._Proxy and self._Proxy.OnPlayMessageBeginLoading then
        self._Proxy:OnPlayMessageBeginLoading(content)
    end
end

function XMessagePlayer:_OnProxyPlayEndLoading(content)
    if self._IsBeginLoading then
        self._IsBeginLoading = false
        if self._Proxy and self._Proxy.OnPlayMessageEndLoading then
            self._Proxy:OnPlayMessageEndLoading(content)
        end
    end
end

function XMessagePlayer:_ChangeState(state)
    self._State = state
    if state == State.Playing then
        self:_RecordMessage()
        self:_RegisterEvent()
        self:_Play()
    elseif state == State.None then
        self._CurrentStepId = 0
        self:_RemoveTimer()
        self:_UnRegisterEvent()
    end
end

function XMessagePlayer:_RecordAwait()
    if self._AwaitRecordContent then
        self:_RequestMessageReadRecord(self._AwaitRecordContent)
        self._AwaitRecordContent = false
    end
end

function XMessagePlayer:_RecordMessage()
    if self:IsExist() then
        self._Message:Record()
    end
end

function XMessagePlayer:_RequestCurrentMessageReadRecord(content)
    if content and not content:IsComplete() then
        if not self._Message:IsForce() or not content:IsEnd() then
            self:_RequestMessageReadRecord(content)
        else
            self._AwaitRecordContent = content
        end
    end
end

---@param content XBWMessageContentEntity
function XMessagePlayer:_RequestMessageReadRecord(content)
    local groupStepId = content:GetStepId()
    local messageId = content:GetMessageId()

    if content:IsEnd() and not content:IsComplete() then
        XMVCA.XBigWorldMessage:RecordStatistical(messageId, XMVCA.XBigWorldMessage.OperatorType.Complete)
    end

    XMVCA.XBigWorldMessage:RequestBigWorldMessageReadRecord(messageId, groupStepId, content:IsEnd())
    content:Read()
end

function XMessagePlayer:_RegisterEvent()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY,
        self._OnPlayNextNotify, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_OPTION_SELECT_NOTIFY,
        self._OnOptionsSelectNotify, self)
end

function XMessagePlayer:_UnRegisterEvent()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY,
        self._OnPlayNextNotify, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_OPTION_SELECT_NOTIFY,
        self._OnOptionsSelectNotify, self)
end

return XMessagePlayer
