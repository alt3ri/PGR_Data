
local XRedPointConditionPassportCombTaskWeekly = {}

local Events = nil

function XRedPointConditionPassportCombTaskWeekly.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionPassportCombTaskWeekly.Check()
    if XMVCA.XPassportComb:CheckPassportAchievedTaskRedPoint(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY) then
        return true
    end
    return false
end

return XRedPointConditionPassportCombTaskWeekly