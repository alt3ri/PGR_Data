---@class XUiPanelRaceMatchInfo : XUiNode 赛程信息
---@field Parent XUiRaceMain
---@field _Control XRaceControl
local XUiPanelRaceMatchInfo = XClass(XUiNode, "XUiPanelRaceMatchInfo")

function XUiPanelRaceMatchInfo:OnStart()
    self.BtnCourse.CallBack = handler(self, self.OnBtnCourseClick)
end

function XUiPanelRaceMatchInfo:Update()
    local info = self.Parent._RoundInfo
    local isEnd = not info.Round

    self.PanelEnd.gameObject:SetActiveEx(isEnd)
    self.PanelTxt.gameObject:SetActiveEx(not isEnd)
    self.PanelBottom.gameObject:SetActiveEx(not isEnd)

    if info.Round then
        if info.Round.Id ~= self._RoundId then
            if string.IsNilOrEmpty(info.Round.SubTitle) then
                self.TxtMatchName.text = info.Round.Name
            else
                self.TxtMatchName.text = string.format("%s·%s", info.Round.Name, info.Round.SubTitle)
            end
            
            local startTimeStr = XTime.TimestampToGameDateTimeString(info.Etcd.StartTimeLong, "MM/dd HH:mm")
            self.TxtMatchTime.text = XUiHelper.GetText("RaceRoundStartTime", startTimeStr)
        end

        if info.State == XEnumConst.Race.RoundState.Guess then
            self.TxtCountdown.text = XUiHelper.GetText("RaceRoundTimeTip1", XUiHelper.GetTime(info.LeftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        elseif info.State == XEnumConst.Race.RoundState.WaitStart then
            self.TxtCountdown.text = XUiHelper.GetText("RaceRoundTimeTip2", XUiHelper.GetTime(info.LeftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        elseif info.State == XEnumConst.Race.RoundState.InProgress then
            self.TxtCountdown.text = XUiHelper.GetText("RaceRoundTimeTip3")
        elseif info.State == XEnumConst.Race.RoundState.End then
            self.TxtCountdown.text = XUiHelper.GetText("RaceRoundTimeTip4")
        end
        self._RoundId = info.Round.Id
    else
        self._RoundId = -1
    end
end

function XUiPanelRaceMatchInfo:OnBtnCourseClick()
    self._Control:RequestAllRoundResult(function()
        XLuaUiManager.Open("UiRaceCourse")
    end)
end

return XUiPanelRaceMatchInfo