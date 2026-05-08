local XUiBigWorldMessageGrid = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageGrid")
local XUiBigWorldMessageTask = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageTask")
local XMessagePlayer = require("XModule/XBigWorldMessage/Common/XMessagePlayer")

---@class XUiBigWorldMessageChat : XUiNode
---@field PanelTop UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field TxtSign XUiComponent.XUiRichTextCustomRender
---@field ListChat UnityEngine.RectTransform
---@field ChatContent UnityEngine.RectTransform
---@field PanelLeft UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field PanelTask UnityEngine.RectTransform
---@field PanelEnd UnityEngine.RectTransform
---@field ListAnswer UnityEngine.RectTransform
---@field BtnAnswer XUiComponent.XUiButton
---@field PanelNone UnityEngine.RectTransform
---@field PanelTaskBg UnityEngine.RectTransform
---@field PanelTips UnityEngine.RectTransform
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessageChat = XClass(XUiNode, "XUiBigWorldMessageChat")

-- region 生命周期

function XUiBigWorldMessageChat:OnStart(audioPlayer)
    ---@type XUiBigWorldMessageGrid[]
    self._ReceiveGridList = {}
    ---@type XUiBigWorldMessageGrid[]
    self._SendGridList = {}
    self._SystemTips = {}
    self._AnswerGroup = {}

    self._ReceiveGridIndex = 1
    self._SendGridIndex = 1
    self._SystemTipIndex = 1

    ---@type XUiBigWorldMessageTask
    self._TaskUi = XUiBigWorldMessageTask.New(self.PanelTask, self)
    ---@type XMessagePlayer
    self._Player = XMessagePlayer.New(self)

    self._ChatScroll = XUiHelper.TryGetComponent(self.ListChat, "", typeof(CS.UnityEngine.UI.ScrollRect))

    self._IsLockGridIndex = false
    self._IsShow = false

    self._IsScrolling = false
    self._ScrolledNotifyId = false
    self._OnScrollEndHandle = Handler(self, self.OnScrollEnd)

    self._AudioPlayer = audioPlayer

    self._Timer = false

    self._TaskUi:Close()
    self:_InitUi()
    self:_RegisterButtonClicks()

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PREVIEW_CLOSE, self.OnPreviewClose,
        self)
end

function XUiBigWorldMessageChat:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageChat:OnDisable()
    self:_RemoveListeners()
end

function XUiBigWorldMessageChat:OnDestroy()
    self.TxtSign.requestImage = nil
    self:_RemoveSchedules()
    self._Player:Destroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PREVIEW_CLOSE,
        self.OnPreviewClose, self)
end

-- endregion

---@param message XBWMessageEntity
function XUiBigWorldMessageChat:RefreshChat(message)
    self:_Reset()
    self:_RefreshChatPanel(message == nil or message:IsNil())
    self:_ShowAnswerOptions(false, 0, true)

    if message and not message:IsNil() then
        self.TxtName.text = self._Control:GetContactsName(message:GetContactsId())
        self.TxtSign.text = self._Control:GetContactsText(message:GetContactsId())
        self:_PlayMessage(message)
    end
end

function XUiBigWorldMessageChat:RefreshPanelTips(isActive)
    self.PanelTips.gameObject:SetActiveEx(isActive)
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:OnPlayMessage(content)
    local stepId = content:GetStepId()
    local isComplete = content:IsComplete()

    if content:IsReceive() then
        local grid = self:_GetReceiveGrid()

        grid:Refresh(content)
        grid:PlayEnableAnimation(content, self._AudioPlayer)

        if content:IsWait() then
            self:_TryScrolling(not isComplete)
        else
            self:_TryScrolling(not isComplete, nil, XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)
        end
    elseif content:IsSend() then
        local grid = self:_GetSendGrid()

        grid:Refresh(content)
        grid:PlayEnableAnimation(content, self._AudioPlayer)

        if content:IsWait() then
            self:_TryScrolling(not isComplete)
        else
            self:_TryScrolling(not isComplete, nil, XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)
        end
    elseif content:IsSystem() then
        local tip = self:_GetSystemTip()

        tip.text = content:GetText()
        self:_TryScrolling(not isComplete, nil, XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)

        if content:IsEnd() then
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_FINISH_NOTIFY, content, isComplete)
        end
    elseif content:IsOptions() then
        if content:IsCompleteWithOption() then
            self:_TryScrolling(false, nil, XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)
        else
            self:_RefreshAnswerOptions(content)
            self:_TryScrolling(true, 0.2)
        end
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:OnPlayMessageBeginLoading(content, duration)
    self._IsLockGridIndex = true
    if content:IsReceive() then
        local grid = self:_GetReceiveGrid()

        grid:Refresh(content)
        grid:SetLoadingEffectActive(true)
        self:_RefreshScrolling(math.min(0.4, duration))
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:OnPlayMessageEndLoading(content)
    if content:IsReceive() then
        local grid = self:_GetReceiveGrid()

        grid:SetLoadingEffectActive(false)
    end
    self._IsLockGridIndex = false
end

function XUiBigWorldMessageChat:OnTaskStateChange(questId)
    self._TaskUi:RefreshState(questId)
end

function XUiBigWorldMessageChat:OnPlayMessagePause()
    self._Player:Pause()
end

function XUiBigWorldMessageChat:OnPreviewClose()
    self._Player:Resume()
end

function XUiBigWorldMessageChat:OnScrollEnd()
    self._IsScrolling = false

    if self._ScrolledNotifyId then
        XEventManager.DispatchEvent(self._ScrolledNotifyId)
        self._ScrolledNotifyId = false
    end
end

function XUiBigWorldMessageChat:OnTxtSignRequestImage(key, image)
    local icon = self._Control:GetIconByKey(key)

    if not string.IsNilOrEmpty(icon) then
        image:SetImage(icon)
    end
end

-- region 私有方法

function XUiBigWorldMessageChat:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.TxtSign.requestImage = Handler(self, self.OnTxtSignRequestImage)
end

function XUiBigWorldMessageChat:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageChat:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldMessageChat:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY, self.OnTaskStateChange,
        self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_PAUSE_NOTIFY,
        self.OnPlayMessagePause, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_FINISH_NOTIFY,
        self._RefreshPrepareEnd, self)
end

function XUiBigWorldMessageChat:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_QUEST_NOTIFY,
        self.OnTaskStateChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_PAUSE_NOTIFY,
        self.OnPlayMessagePause, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_FINISH_NOTIFY,
        self._RefreshPrepareEnd, self)
end

function XUiBigWorldMessageChat:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:_RefreshAnswerOptions(content)
    local count = content:GetOprionsCount()

    self:_ShowAnswerOptions(count > 0, content:GetMessageId())
    for i = 1, count do
        local answer = self:_GetAnswerGrid(i)
        local text = content:GetOprionsTextByIndex(i)
        local index = i

        answer:SetNameByGroup(0, text)
        answer.gameObject:SetActiveEx(true)
        answer:AddEventListener(function()
            self:_ShowAnswerOptions(false)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_OPTION_SELECT_NOTIFY, index)
        end)
    end
    for i = count + 1, table.nums(self._AnswerGroup) do
        self._AnswerGroup[i].gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMessageChat:_RefreshChatPanel(isNone)
    self.PanelNone.gameObject:SetActiveEx(isNone)
    self.ListChat.gameObject:SetActiveEx(not isNone)
    self.PanelTop.gameObject:SetActiveEx(not isNone)
end

function XUiBigWorldMessageChat:_Reset()
    self:_RefreshTask()
    self:_ResetAllReceiveGrid()
    self:_ResetAllSendGrid()
    self:_ResetAllSystemTip()
    self:_ResetMessageEnd()
end

function XUiBigWorldMessageChat:_ResetAllReceiveGrid()
    self._ReceiveGridIndex = 1
    for _, grid in pairs(self._ReceiveGridList) do
        grid:Close()
    end
end

function XUiBigWorldMessageChat:_ResetAllSendGrid()
    self._SendGridIndex = 1
    for _, grid in pairs(self._SendGridList) do
        grid:Close()
    end
end

function XUiBigWorldMessageChat:_ResetAllSystemTip()
    self._SystemTipIndex = 1
    for _, tip in pairs(self._SystemTips) do
        tip.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldMessageChat:_ResetMessageEnd()
    self.PanelEnd.gameObject:SetActiveEx(false)
end

function XUiBigWorldMessageChat:_GetReceiveGrid()
    local index = self._ReceiveGridIndex
    local grid = self._ReceiveGridList[index]

    if not grid then
        local gridObject = XUiHelper.Instantiate(self.PanelLeft, self.ChatContent)

        grid = XUiBigWorldMessageGrid.New(gridObject, self)
        self._ReceiveGridList[index] = grid
    end

    grid:Open()
    grid.Transform:SetAsLastSibling()
    if not self._IsLockGridIndex then
        self._ReceiveGridIndex = self._ReceiveGridIndex + 1
    end

    return grid
end

function XUiBigWorldMessageChat:_GetSendGrid()
    local index = self._SendGridIndex
    local grid = self._SendGridList[index]

    if not grid then
        local gridObject = XUiHelper.Instantiate(self.PanelRight, self.ChatContent)

        grid = XUiBigWorldMessageGrid.New(gridObject, self)
        self._SendGridList[index] = grid
    end

    grid:Open()
    grid.Transform:SetAsLastSibling()
    if not self._IsLockGridIndex then
        self._SendGridIndex = self._SendGridIndex + 1
    end

    return grid
end

function XUiBigWorldMessageChat:_GetSystemTip()
    local index = self._SystemTipIndex
    local tip = self._SystemTips[index]

    if not tip then
        tip = XUiHelper.Instantiate(self.TxtTips, self.ChatContent)

        self._SystemTips[index] = tip
    end

    tip.gameObject:SetActiveEx(true)
    tip.transform:SetAsLastSibling()
    self._SystemTipIndex = self._SystemTipIndex + 1

    return tip
end

function XUiBigWorldMessageChat:_GetAnswerGrid(index)
    local grid = self._AnswerGroup[index]

    if not grid then
        grid = XUiHelper.Instantiate(self.BtnAnswer, self.ListAnswer)

        self._AnswerGroup[index] = grid
    end

    return grid
end

function XUiBigWorldMessageChat:_ShowMessageEnd()
    self.PanelEnd.gameObject:SetActiveEx(true)
    self.PanelEnd.transform:SetAsLastSibling()
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:_RefreshTeskPanel(content)
    if content:IsQuest() then
        local questId = self._Control:GetMessageQuestId(content:GetMessageId())

        self:_RefreshTask(questId)
    else
        self:_RefreshTask()
    end
end

function XUiBigWorldMessageChat:_RefreshTask(questId)
    if XTool.IsNumberValid(questId) then
        self._TaskUi:Open()
        self._TaskUi:Refresh(questId)
        if not self._Player:IsMessagePlayed() then
            self._TaskUi:PlayEnableAnimation()
        end
        self._TaskUi.Transform:SetAsLastSibling()
    else
        self._TaskUi:Close()
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:_RefreshPrepareEnd(content, isComplete)
    self:_RemoveSchedules()

    if isComplete then
        self:_RefreshEnd(content)
    else
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self._Timer = false
            self:_RefreshEnd(content)
        end, 0.5 * XScheduleManager.SECOND)
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageChat:_RefreshEnd(content)
    self:_RefreshTeskPanel(content)
    self:_ShowMessageEnd()
    self._Control:SendMessageComplete(content:GetMessageId())
    self:_TryScrolling(true, 0.3, XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY)
end

function XUiBigWorldMessageChat:_RefreshScrolling(time, notifyEventId)
    if not self._IsScrolling then
        self._ScrolledNotifyId = notifyEventId
        self._ChatScroll:DOVerticalNormalizedPos(0, time or 0.4):OnComplete(self._OnScrollEndHandle)
    end
end

function XUiBigWorldMessageChat:_TryScrolling(isScrolling, time, notifyEventId)
    if isScrolling then
        self:_RefreshScrolling(time, notifyEventId)
    else
        self._ChatScroll.verticalNormalizedPosition = 0
        if notifyEventId then
            XEventManager.DispatchEvent(notifyEventId)
        end
    end
end

function XUiBigWorldMessageChat:_ShowAnswerOptions(isShow, messageId, isForce)
    if self._IsShow == isShow then
        if isForce then
            self.PanelTaskBg.gameObject:SetActiveEx(isShow)
            self.ListAnswer.gameObject:SetActiveEx(isShow)
        end

        return
    end

    if isShow then
        self.PanelTaskBgDisable:StopTimelineAnimation()
        self.PanelTaskBg.gameObject:SetActiveEx(isShow)
        self.ListAnswer.gameObject:SetActiveEx(isShow)
        self.PanelTaskBgEnable:PlayTimelineAnimation()

        if XTool.IsNumberValid(messageId) then
            XMVCA.XBigWorldMessage:RecordStatistical(messageId, XMVCA.XBigWorldMessage.OperatorType.Options)
        end
    else
        self.PanelTaskBgEnable:StopTimelineAnimation()
        self.PanelTaskBgDisable:PlayTimelineAnimation(function()
            self.PanelTaskBg.gameObject:SetActiveEx(false)
            self.ListAnswer.gameObject:SetActiveEx(false)
        end)
    end
    self._IsShow = isShow
end

function XUiBigWorldMessageChat:_InitUi()
    self.BtnAnswer.gameObject:SetActiveEx(false)
    self.PanelEnd.gameObject:SetActiveEx(false)
    self.PanelLeft.gameObject:SetActiveEx(false)
    self.PanelRight.gameObject:SetActiveEx(false)
    self.TxtTips.gameObject:SetActiveEx(false)
    self.PanelTips.gameObject:SetActiveEx(false)

    self.PanelTaskBgEnable = self.PanelTaskBg:FindTransform("PanelTaskBgEnable")
    self.PanelTaskBgDisable = self.PanelTaskBg:FindTransform("PanelTaskBgDisable")
end

---@param message XBWMessageEntity
function XUiBigWorldMessageChat:_PlayMessage(message)
    self._Player:SetMessage(message)
    self._Player:Play()
end

-- endregion

return XUiBigWorldMessageChat
