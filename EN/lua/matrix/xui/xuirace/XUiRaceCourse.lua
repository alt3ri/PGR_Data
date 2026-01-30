---@class XUiRaceCourse : XLuaUi 赛程
---@field _Control XRaceControl
local XUiRaceCourse = XLuaUiManager.Register(XLuaUi, "UiRaceCourse")

local TabAll = 1
local TabPointsRace = 2
local TabEliminator = 3

function XUiRaceCourse:OnAwake()
    self._SortRound = handler(self, self.SortRound)
    self:BindHelpBtn(self.BtnHelp, "RaceCourseHelp")
end

function XUiRaceCourse:OnStart()
    self:InitData()
    ---@type XUiPanelRaceScheduleTable
    self._ScheduleTable = require("XUi/XUiRace/Panel/XUiPanelRaceScheduleTable").New(self.PanelMatchTable, self)
    ---@type XUiPanelRaceScheduleRank
    self._ScheduleRank = require("XUi/XUiRace/Panel/XUiPanelRaceScheduleRank").New(self.PanelMatchRank, self)
    
    self:InitComponent()
    self:CountDown()
end

function XUiRaceCourse:OnEnable()

end

function XUiRaceCourse:InitComponent()
    local buttons = { self.GridTags1, self.GridTags2, self.GridTags3 }
    self.PanelTopTags:Init(buttons, function(index)
        self:OnSelectTab(index)
    end)
    self.PanelTopTags:SelectIndex(TabAll)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiRaceCourse:InitData()
    ---@type number[]
    self._PointGroupIds = {}
    ---@type number[]
    self._EliminatorIds = {}

    --筛选出积分赛和淘汰赛
    local etcds = self._Control:GetEtcdRoundConfigs()
    for roundId, etcd in pairs(etcds) do
        if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
            if not table.contains(self._PointGroupIds, etcd.PointGroupId) then
                table.insert(self._PointGroupIds, etcd.PointGroupId)
            end
        else
            table.insert(self._EliminatorIds, roundId)
        end
    end

    --根据比赛开始时间进行排序
    table.sort(self._PointGroupIds, function(aGroupId, bGroupId)
        local aRoundIds = self._Control:GetRaceRoundPointGroupAutoById(aGroupId).RoundIds
        local bRoundIds = self._Control:GetRaceRoundPointGroupAutoById(bGroupId).RoundIds
        return self:SortRound(aRoundIds[1], bRoundIds[1])
    end)

    table.sort(self._EliminatorIds, self._SortRound)
end

function XUiRaceCourse:OnSelectTab(index)
    self._CurIndex = index
    if index == TabAll then
        self._ScheduleTable:Open()
        self._ScheduleRank:Close()
    elseif index == TabPointsRace then
        self._ScheduleTable:Close()
        self._ScheduleRank:Open()
        self._ScheduleRank:Switch(XEnumConst.Race.Format.PointsRace, self._JumpToPointGroupId)
    elseif index == TabEliminator then
        if not self._IsEliminatorOpen then
            local startTime = self._Control:GetEliminatorOpenTime()
            local timeStr = XTime.TimestampToGameDateTimeString(startTime, XUiHelper.GetText("RaceTimeFormat"))
            self._Control:OpenTip("RaceRoundStartTime", timeStr)
            return
        end
        self._ScheduleTable:Close()
        self._ScheduleRank:Open()
        self._ScheduleRank:Switch(XEnumConst.Race.Format.Eliminator, self._JumpToRoundId)
    end
    self:UpdateState()
    self._JumpToPointGroupId = nil
    self._JumpToRoundId = nil
    self:PlayAnimationWithMask("QieHuan")
end

function XUiRaceCourse:SortRound(aId, bId)
    local aStartTime = self._Control:GetEtcdRoundConfig(aId).StartTimeLong
    local bStartTime = self._Control:GetEtcdRoundConfig(bId).StartTimeLong
    return aStartTime < bStartTime
end

function XUiRaceCourse:CountDown()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        self:UpdateState()
    end)
    self:UpdateState()
end

function XUiRaceCourse:UpdateState()
    --淘汰赛是否已开启
    self._IsEliminatorOpen = self._Control:IsEliminatorOpen()
    if self.GridTags3.ButtonState ~= CS.UiButtonState.Select then
        self.GridTags3:SetButtonState(self._IsEliminatorOpen and XUiButtonState.Normal or XUiButtonState.Disable)
    end
    --实时更新赛程信息
    if self._CurIndex == TabAll then
        self._ScheduleTable:UpdateData()
    elseif self._CurIndex == TabEliminator then
        self._ScheduleRank:UpdateEliminatorTab()
    end
end

function XUiRaceCourse:JumpToPointsRace(pointGroupId)
    self._JumpToPointGroupId = pointGroupId
    self.PanelTopTags:SelectIndex(TabPointsRace)
end

function XUiRaceCourse:JumpToEliminator(roundId)
    self._JumpToRoundId = roundId
    self.PanelTopTags:SelectIndex(TabEliminator)
end

return XUiRaceCourse