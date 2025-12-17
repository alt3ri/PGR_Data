---@class XUiDlcRelinkMatching : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkMatching = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkMatching")

local UI_ROOM = "UiDlcRelinkRoom"

function XUiDlcRelinkMatching:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkMatching:OnStart()
    self.ElapsedSeconds = 0
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

function XUiDlcRelinkMatching:OpenOrReturnRoom()
    if XLuaUiManager.IsStackUiOpen(UI_ROOM) then
        XLuaUiManager.CloseAllUpperUi(UI_ROOM)
    else
        XLuaUiManager.Open(UI_ROOM)
    end
end

function XUiDlcRelinkMatching:OnMatchSuccess()
    self:StopMatchingTimer()
    self.TxtTime.text = self._Control:GetClientConfig("MatchSuccessTips") or ""
    XScheduleManager.ScheduleOnce(function()
        self:OpenOrReturnRoom()
    end, 1000)
end

function XUiDlcRelinkMatching:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick)
end

function XUiDlcRelinkMatching:OnBtnMatchingClick()
    self:OpenOrReturnRoom()
end

return XUiDlcRelinkMatching
