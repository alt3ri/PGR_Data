---@class XRedPointRaceMain
local XRedPointRaceMain = {}

local SubConditions = nil
function XRedPointRaceMain.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_RACE_TASK,
        XRedPointConditions.Types.CONDITION_RACE_ROUND_GUESS,
        XRedPointConditions.Types.CONDITION_RACE_MATCH_GUESS,
    }
    return SubConditions
end

function XRedPointRaceMain.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_RACE_TASK)
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_RACE_ROUND_GUESS)
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_RACE_MATCH_GUESS)

end

return XRedPointRaceMain