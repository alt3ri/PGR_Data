
local XRedPointConditionPassportCombTaskDaily = {}

local Events = nil

function XRedPointConditionPassportCombTaskDaily.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
    }
    return Events
end

function XRedPointConditionPassportCombTaskDaily.Check()
    if XMVCA.XPassportComb:CheckPassportAchievedTaskRedPoint(XEnumConst.PASSPORT.TASK_TYPE.DAILY) then
        return true
    end
    return false
end

return XRedPointConditionPassportCombTaskDaily