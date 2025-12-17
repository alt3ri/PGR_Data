---@class XUiRaceProjectChose : XLuaUi 赛事预测
---@field _Control XRaceControl
local XUiRaceProjectChose = XLuaUiManager.Register(XLuaUi, "UiRaceProjectChose")

function XUiRaceProjectChose:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "RaceProjectChoseHelp")
end

function XUiRaceProjectChose:OnStart()
    self._ActivityConfig = self._Control:GetCurrentConfig()
    self._MatchData = self._Control:GetMatchGuessData()
    ---@type XUiGridRaceMatchProject[]
    self._ProjectGrids = {}

    self:InitUi()
    self:CountDown()
end

function XUiRaceProjectChose:OnEnable()
    self:UpdateProjectState()
end

function XUiRaceProjectChose:InitUi()
    XUiHelper.NewPanelActivityAssetSafe({ self._ActivityConfig.ItemId }, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    self.GridProject.gameObject:SetActiveEx(false)
    local timerId = XScheduleManager.ScheduleOnce(function()
        self:InitProject()
    end, 500)
    self:_AddTimerId(timerId)
end

function XUiRaceProjectChose:InitProject()
    local matchGuesses = self._ActivityConfig.MatchGuess
    XUiHelper.RefreshCustomizedList(self.GridProject.parent, self.GridProject, #matchGuesses, function(i, go)
        ---@type XUiGridRaceMatchProject
        local grid = require("XUi/XUiRace/Grid/XUiGridRaceMatchProject").New(go, self, matchGuesses[i])
        table.insert(self._ProjectGrids, grid)
        --动效
        grid:Close()
        local timerId = XScheduleManager.ScheduleOnce(function()
            grid:Open()
            grid:PlayAnimationWithMask("GridProjectEnable")
        end, i * 50)
        self:_AddTimerId(timerId)
    end)
    self:UpdateProjectState()
end

function XUiRaceProjectChose:UpdateProject(matchState)
    if self._MatchState == matchState then
        return
    end
    
    local guessId = self._ActivityConfig.MatchGuess[1]
    local isGuessEnd = matchState == XEnumConst.Race.MatchState.GuessEnd
    local isWaitOpen = self._MatchData:IsWaitOpen(guessId)
    
    if isGuessEnd and isWaitOpen then
        self.TxtTimeLeft.text = XUiHelper.GetText("RaceMatchTimePlaying")
    end
    self._MatchState = matchState
    self.PanelTime.gameObject:SetActiveEx(not isGuessEnd or isWaitOpen)
    self:UpdateProjectState()
end

function XUiRaceProjectChose:UpdateProjectState()
    for _, grid in pairs(self._ProjectGrids) do
        grid:UpdateView()
    end
end

function XUiRaceProjectChose:CountDown()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end

        local state
        local endTime = XFunctionManager.GetEndTimeByTimeId(self._ActivityConfig.MatchGuessTime)
        local nowTime = XTime.GetServerNowTimestamp()
        if endTime > nowTime then
            -- 赛事预测进行中
            state = XEnumConst.Race.MatchState.Guess
            self.TxtTimeLeft.text = XUiHelper.GetText("RaceMatchTimeLeft", XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        else
            -- 赛事预测已结束
            state = XEnumConst.Race.MatchState.GuessEnd
        end
        self:UpdateProject(state)
    end, nil, 0)
end

return XUiRaceProjectChose