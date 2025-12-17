---@class XUiPanelRaceScheduleTable : XUiNode
---@field Parent XUiRaceCourse
---@field _Control XRaceControl
local XUiPanelRaceScheduleTable = XClass(XUiNode, "XUiPanelRaceScheduleTable")

local PointRaceCount = 4 --四组积分赛
local EliminatorCount = 3 --三组淘汰赛（其中一个是总决赛）

function XUiPanelRaceScheduleTable:OnStart()
    local XUiGridRaceScheduleGroup = require("XUi/XUiRace/Grid/XUiGridRaceScheduleGroup")
    ---@type XUiGridRaceScheduleGroup[]
    self._PointsRaces = {}
    ---@type XUiGridRaceScheduleGroup[]
    self._Eliminators = {}
    --积分赛
    local idx = 1
    local configs = self._Control:GetRaceRoundPointGroupAutoConfigs()
    for _, cfg in pairs(configs) do
        local race = self[string.format("PointsRace%s", idx)]
        self._PointsRaces[idx] = XUiGridRaceScheduleGroup.New(race, self)
        self._PointsRaces[idx]:InitPointsRace(cfg.Id)
        idx = idx + 1
    end
    --淘汰赛
    for i = 1, EliminatorCount do
        local race = self[string.format("Eliminator%s", i)]
        self._Eliminators[i] = XUiGridRaceScheduleGroup.New(race, self)
        self._Eliminators[i]:InitEliminator(self.Parent._EliminatorIds[i], i == EliminatorCount)
    end
end

function XUiPanelRaceScheduleTable:UpdateData()
    for i, v in ipairs(self._PointsRaces) do
        v:UpdatePointsRace()
    end
    for i, v in ipairs(self._Eliminators) do
        v:UpdateEliminator()
    end
end

function XUiPanelRaceScheduleTable:InstantiateHead(node)
    if self._IsCreate then
        return XUiHelper.Instantiate(self.UiRaceCourseHead, node)
    end
    self._IsCreate = true
    self.UiRaceCourseHead.gameObject:SetActiveEx(true)
    self.UiRaceCourseHead:SetParent(node, false)
    return self.UiRaceCourseHead
end

return XUiPanelRaceScheduleTable
