---@type XFubenActivityBossSingleManager

local XFubenActivityBossSingleManager = XDataCenter.FubenActivityBossSingleManager

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XFubenActivityBossSingleManager
end

local XTeam = require("XEntity/XTeam/XTeam")
local CurrentTeams = {}

function XFubenActivityBossSingleManager.GetCurrentTeam(teamId)
    if not CurrentTeams[teamId] then
        CurrentTeams[teamId] = XTeam.New(teamId)
    end
    return CurrentTeams[teamId]
end