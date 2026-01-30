---@class XUiRacePopupGameStart : XLuaUi 比赛开始弹框
---@field _Control XRaceControl
local XUiRacePopupGameStart = XLuaUiManager.Register(XLuaUi, "UiRacePopupGameStart")

function XUiRacePopupGameStart:OnAwake()
    self._Time = self._Control:GetIntClientConfig("StartGameCountDown")
    self.BtnCancel.CallBack = handler(self, self.Close)
    self.BtnReceive.CallBack = handler(self, self.OnBtnReceiveClick)
end

function XUiRacePopupGameStart:OnStart()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        -- 倒计时结束后自动进入比赛
        if self._Time >= 0 then
            self.TxtNum.text = self._Time
        else
            self:OnBtnReceiveClick()
        end
        self._Time = self._Time - 1
    end, nil, 0)
end

function XUiRacePopupGameStart:OnBtnReceiveClick()
    local roundId = self._Control:GetCurRound()
    self._Control:EnterGame(roundId, XEnumConst.Race.GameMode.LiveStream)
    self:Close()
end

return XUiRacePopupGameStart