---@class XRedPointRaceTask
local XRedPointRaceTask = {}

function XRedPointRaceTask.Check()
    return XMVCA.XRace:CheckTaskRedPoint()
end

return XRedPointRaceTask