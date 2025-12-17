---@class XUiRaceToastHall : XLuaUi 主界面滚动条
---@field _Control XRaceControl
local XUiRaceToastHall = XLuaUiManager.Register(XLuaUi, "UiRaceToastHall")

local MathLerp = CS.UnityEngine.Mathf.Lerp

function XUiRaceToastHall:OnAwake()
    self._MoveSpeed = self._Control:GetIntClientConfig("TipMoveSpeed")
    self._WaitCloseTime = self._Control:GetIntClientConfig("WaitCloseTipTime") * 1000
    self._LoopTipTime = self._Control:GetIntClientConfig("LoopTipTime") * 1000
    self.BtnRaceToast.CallBack = handler(self, self.OnBtnRaceToastClick)

    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.CloseChatTip, self)
    XEventManager.AddEventListener(XEventId.EVENT_RACE_TOAST_HALL_UPDATE, self.ShowTip, self)
end

function XUiRaceToastHall:OnStart(data, tipType)
    self:ShowTip(data, tipType)
end

function XUiRaceToastHall:OnDestroy()
    XMVCA.XRace:SetTipShowing(self._TipType, false)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_DISABLE, self.CloseMainTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UICHAT_DISABLE, self.CloseChatTip, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RACE_TOAST_HALL_UPDATE, self.ShowTip, self)
end

function XUiRaceToastHall:ShowTip(data, tipType)
    self._TipType = tipType
    XMVCA.XRace:SetTipShow(tipType, data.Id)

    local timerId = XScheduleManager.ScheduleNextFrame(function()
        if tipType == XEnumConst.Race.Tip.Main then
            self:ShowMainTip(data)
        elseif tipType == XEnumConst.Race.Tip.Chat then
            self:ShowChatTip(data)
        end
    end)
    self:_AddTimerId(timerId)
end

---@param data XTableRaceBroadcast
function XUiRaceToastHall:ShowMainTip(data)
    self.PanelMain.gameObject:SetActiveEx(true)
    self.PanelRace.gameObject:SetActiveEx(false)
    self:StopTweener(self._MainMoveTimer)
    self:StopTweener(self._MainWaitTimer)
    self.Txt.text = data.Desc

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)
    local startPosX = self.Viewport.rect.width + self.Content.rect.width
    local endPosX = 0
    self.Content.anchoredPosition = Vector2(startPosX, 0)
    self._MainMoveTimer = XUiHelper.Tween(self._MoveSpeed, function(t)
        if not self.Content:Exist() then
            return true
        end
        self.Content.anchoredPosition = Vector2(MathLerp(startPosX, endPosX, t), 0)
    end, function()
        self._MainWaitTimer = XScheduleManager.ScheduleOnce(handler(self, self.Close), self._WaitCloseTime)
        self:_AddTimerId(self._MainWaitTimer)
    end)
    self:_AddTimerId(self._MainMoveTimer)
end

---@param data XTableRaceBroadcast
function XUiRaceToastHall:ShowChatTip(data)
    self.PanelMain.gameObject:SetActiveEx(false)
    self.PanelRace.gameObject:SetActiveEx(true)
    self:StopTweener(self._MoveTimer)
    self:StopTweener(self._EndTimer)
    self.BtnRaceToast:SetNameByGroup(0, string.format(data.Desc, data.BeforeTime))

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content1)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content2)

    local startPosX = self.Viewport1.rect.width
    local endPosX = -self.Content1.rect.width
    self.Content1.anchoredPosition = Vector2(startPosX, 0)
    self.Content2.anchoredPosition = Vector2(startPosX, 0)

    self._MoveTimer = XUiHelper.Tween(self._MoveSpeed, function(t)
        if not self.Content1:Exist() or not self.Content2:Exist() then
            return
        end
        self.Content1.anchoredPosition = Vector2(MathLerp(startPosX, endPosX, t), 0)
        self.Content2.anchoredPosition = Vector2(MathLerp(startPosX, endPosX, t), 0)
    end, function()
        if data.IsStill then
            -- 循环播放
            self._EndTimer = XScheduleManager.ScheduleOnce(function()
                self:ShowChatTip(data)
            end, self._LoopTipTime)
        else
            -- 隐藏播报
            self._EndTimer = XScheduleManager.ScheduleOnce(handler(self, self.Close), self._WaitCloseTime)
        end
        self:_AddTimerId(self._EndTimer)
    end)
    self:_AddTimerId(self._MoveTimer)
end

function XUiRaceToastHall:OnBtnRaceToastClick()
    XMVCA.XRace:OpenMain()
end

function XUiRaceToastHall:CloseMainTip()
    if self._TipType == XEnumConst.Race.Tip.Main then
        self:Close()
    end
end

function XUiRaceToastHall:CloseChatTip()
    if self._TipType == XEnumConst.Race.Tip.Chat then
        self:Close()
    end
end

return XUiRaceToastHall