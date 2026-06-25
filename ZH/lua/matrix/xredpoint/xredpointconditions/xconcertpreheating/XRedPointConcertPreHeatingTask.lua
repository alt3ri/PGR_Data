--- 音乐会预热任务奖励蓝点
local XRedPointConcertPreHeatingTask = {}

local Events = nil

function XRedPointConcertPreHeatingTask.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_MULTI),
        XRedPointEventElement.New(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_CONCERT_PRE_HEATING_RED_POINT_UPDATE),
    }
    return Events
end

function XRedPointConcertPreHeatingTask.Check()
    if not XMVCA.XConcertPreHeating:IsActivityOpen() then
        return false
    end

    return XMVCA.XConcertPreHeating:CheckHasTaskReward()
end

return XRedPointConcertPreHeatingTask
