---超限启航活动入口红点
local XRedPointTransfiniteTowerMain = {}

local SubConditions = nil

function XRedPointTransfiniteTowerMain.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_TRANSFINITE_TOWER_UNLOCK,
        XRedPointConditions.Types.CONDITION_TRANSFINITE_TOWER_TASK,
    }
    return SubConditions
end

function XRedPointTransfiniteTowerMain.Check()
    return XRedPointManager.CheckConditions(XRedPointTransfiniteTowerMain.GetSubConditions())
end

return XRedPointTransfiniteTowerMain
