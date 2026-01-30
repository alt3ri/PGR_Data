local XUiBigWorldMessageChat = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageChat")

---@class XUiBigWorldPopupMessageSingle : XBigWorldUi
---@field BtnBgClose XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field PanelChat UnityEngine.RectTransform
---@field _Control XBigWorldMessageControl
local XUiBigWorldPopupMessageSingle = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupMessageSingle")

-- region 生命周期

function XUiBigWorldPopupMessageSingle:OnAwake()
    ---@type XUiBigWorldMessageChat
    self._ChatUi = XUiBigWorldMessageChat.New(self.PanelChat, self, self.XAudioObjectPlayer)
    self._SequentialId = 0
    ---@type XBWMessageEntity
    self._Message = false
    self._IsForce = false
    self._IsPlayFinish = false
    self._Timer = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldPopupMessageSingle:OnStart(messageId, sequentialId)
    self._Message = self._Control:GetForceMessageByMessageId(messageId)
    self._SequentialId = sequentialId or 0
    self._IsForce = self._Control:CheckMessageIsForcePlay(messageId)

    if not self._Message or self._Message:IsNil() or self._Message:IsComplete() then
        self._IsPlayFinish = true
    end

    XMVCA.XBigWorldMessage:RecordStatistical(messageId, XMVCA.XBigWorldMessage.OperatorType.Enter, 0, self.Name)
end

function XUiBigWorldPopupMessageSingle:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
    self:_Refresh()
end

function XUiBigWorldPopupMessageSingle:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldPopupMessageSingle:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE)
    XMVCA.XBigWorldMessage:RecordStatistical(self._Message:GetMessageId(), XMVCA.XBigWorldMessage.OperatorType.Leave, 0,
        self.Name)
    if XTool.IsNumberValid(self._SequentialId) then
        XMVCA.XBigWorldCommon:FinishSequentialJob(self._SequentialId)
    end
end

-- endregion

function XUiBigWorldPopupMessageSingle:Close()
    XLuaUiManager.CloseWithCallback(self.Name, function()
        XMVCA.XBigWorldMessage:TryOpenMessageTipUi()
    end)
end

function XUiBigWorldPopupMessageSingle:OnMessageFinish()
    self._IsPlayFinish = true
    self.BtnClose.gameObject:SetActiveEx(true)
    self.BtnBgClose.gameObject:SetActiveEx(true)
end

-- region 私有方法

function XUiBigWorldPopupMessageSingle:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBgClose, self.Close, true)
    self:RegisterClickEvent(self.BtnClose, self.Close, true)
end

function XUiBigWorldPopupMessageSingle:_RegisterSchedules()
    -- 在此处注册定时器
    self._Timer = XScheduleManager.ScheduleForever(function()
        if not self._IsPlayFinish then
            if not self._Message or self._Message:IsNil() or self._Message:IsComplete() then
                self._IsPlayFinish = true
                self.BtnClose.gameObject:SetActiveEx(true)
                self.BtnBgClose.gameObject:SetActiveEx(true)

                XScheduleManager.UnSchedule(self._Timer)
                self._Timer = false
            end
        end
    end, XScheduleManager.SECOND * 3)
end

function XUiBigWorldPopupMessageSingle:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldPopupMessageSingle:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY, self.OnMessageFinish,
        self)
end

function XUiBigWorldPopupMessageSingle:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY,
        self.OnMessageFinish, self)
end

function XUiBigWorldPopupMessageSingle:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPopupMessageSingle:_Refresh()
    self.BtnClose.gameObject:SetActiveEx(not self._IsForce or self._IsPlayFinish)
    self.BtnBgClose.gameObject:SetActiveEx(not self._IsForce or self._IsPlayFinish)
    if self._Message and not self._Message:IsNil() then
        self._ChatUi:RefreshChat(self._Message)
    end
end

-- endregion

return XUiBigWorldPopupMessageSingle
