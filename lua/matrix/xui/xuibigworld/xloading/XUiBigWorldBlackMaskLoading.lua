---@type X3CCommand
local X3C_CMD = CS.X3CCommand
---@class XUiBigWorldBlackMaskLoading : XBigWorldUi
local XUiBigWorldBlackMaskLoading = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldBlackMaskLoading")

function XUiBigWorldBlackMaskLoading:OnAwake()
    if not self.DarkEnable then
        self.DarkEnable = self.Transform:Find("FullScreenBackground/UiBigWorldDark/Animation/DarkEnable")
    end
    if not self.DarkDisable then
        self.DarkDisable = self.Transform:Find("FullScreenBackground/UiBigWorldDark/Animation/DarkDisable")
    end
    if self:IsSetMask() then
        XMVCA.XBigWorldUI:SetMaskActive(true)
    end
    
    self._PopupBegin = XMVCA.XBigWorldQuest.QuestOpType.PopupBegin
    self._PopupEnd = XMVCA.XBigWorldQuest.QuestOpType.PopupEnd
end

function XUiBigWorldBlackMaskLoading:OnStart(enableFinishCb, disableFinishCb, enableStartCb, disableStartCb, immediateFadeOut)
    self._EnableFinishCb = enableFinishCb
    self._DisableFinishCb = disableFinishCb
    self._EnableStartCb = enableStartCb
    self._DisableStartCb = disableStartCb
    self._ImmediateFadeOut = immediateFadeOut or false
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BLACK_MASK_LOADING_CLOSE, self.OnFadeOut, self)
    if self:IsRegisterX3CClose() then
        XMVCA.X3CProxy:RegisterHandler(X3C_CMD.CMD_CLOSE_BLACK_MASK_LOADING, self.OnFadeOut, self)
    end
end

function XUiBigWorldBlackMaskLoading:OnDestroy()
    if self:IsSetMask() then
        XMVCA.XBigWorldUI:SetMaskActive(false)
    end
    if self:IsRegisterX3CClose() then
        XMVCA.X3CProxy:UnRegisterHandler(X3C_CMD.CMD_CLOSE_BLACK_MASK_LOADING)
    end
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BLACK_MASK_LOADING_CLOSE, self.OnFadeOut, self)
end

function XUiBigWorldBlackMaskLoading:OnEnable()
    if self._ImmediateFadeOut then
        self:OnFadeOut()
    else
        self.DarkEnable:PlayTimelineAnimation(self._EnableFinishCb, self._EnableStartCb)
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self._PopupBegin)
end

function XUiBigWorldBlackMaskLoading:OnDisable()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, self._PopupEnd)
end

function XUiBigWorldBlackMaskLoading:OnFadeOut()
    self.DarkDisable:PlayTimelineAnimation(function() 
        self:Close()
        if self._DisableFinishCb then
            self._DisableFinishCb()
        end
    end, function()
        if self._DisableStartCb then
            self._DisableStartCb()
        end
    end)
end

function XUiBigWorldBlackMaskLoading:IsSetMask()
    return true
end

function XUiBigWorldBlackMaskLoading:IsRegisterX3CClose()
    return true
end

return XUiBigWorldBlackMaskLoading
