---@class XUiDlcRelinkMatching : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkMatching = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkMatching")

function XUiDlcRelinkMatching:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkMatching:OnStart()
    self.ElapsedSeconds = 0
    self.IsMatchSuccess = false
    self:BeginMatching()
end

function XUiDlcRelinkMatching:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS,
    }
end

function XUiDlcRelinkMatching:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_ROOM_MATCH_SUCCESS then
        self:OnMatchSuccess()
    end
end

function XUiDlcRelinkMatching:OnDisable()
    self:StopMatchingTimer()
    self.IsMatchSuccess = false
end

function XUiDlcRelinkMatching:OnClose()
    if self.IsMatchSuccess then
        return
    end
    self:Close()
end

function XUiDlcRelinkMatching:BeginMatching()
    self:StopMatchingTimer()
    self.MatchingTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.TxtTime) then
            return
        end

        self.ElapsedSeconds = (self.ElapsedSeconds or 0) + 1
        local m = math.floor(self.ElapsedSeconds / 60)
        local s = self.ElapsedSeconds % 60
        self.TxtTime.text = string.format("%02d:%02d", m, s)
    end, XScheduleManager.SECOND)
end

function XUiDlcRelinkMatching:StopMatchingTimer()
    if self.MatchingTimer then
        XScheduleManager.UnSchedule(self.MatchingTimer)
        self.MatchingTimer = nil
    end
end

function XUiDlcRelinkMatching:OnMatchSuccess()
    self.IsMatchSuccess = true
    self:StopMatchingTimer()
    self.TxtTime.text = self._Control:GetClientConfig("MatchSuccessTips") or ""
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self._Control:OpenOrReturnRoom()
        self:Close()
    end, 1000)
end

function XUiDlcRelinkMatching:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick)
end

function XUiDlcRelinkMatching:OnBtnMatchingClick()
    self._Control:OpenOrReturnRoom()
end

return XUiDlcRelinkMatching
