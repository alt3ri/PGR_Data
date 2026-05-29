--- 肉鸽6 任务可领取红点
local XRedPointTheatre6Reward = {}
local Events = nil

function XRedPointTheatre6Reward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_MULTI),
    }
    return Events
end

function XRedPointTheatre6Reward.Check()
    return XMVCA.XTheatre6:CheckTaskRedPoint()
end

return XRedPointTheatre6Reward
