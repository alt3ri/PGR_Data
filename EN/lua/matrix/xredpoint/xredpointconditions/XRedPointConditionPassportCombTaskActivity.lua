
local XRedPointConditionPassportCombTaskActivity = {}

local Events = nil

function XRedPointConditionPassportCombTaskActivity.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionPassportCombTaskActivity.Check()
    if XMVCA.XPassportComb:CheckPassportAchievedTaskRedPoint(XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY) then
        return true
    end
    return false
end

return XRedPointConditionPassportCombTaskActivity