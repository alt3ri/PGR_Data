
local XRedPointConditionPassportCombPanelReward = {}

local Events = nil

function XRedPointConditionPassportCombPanelReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO),
        XRedPointEventElement.New(XEventId.EVENT_BUY_PASSPORT_COMPLEATE),
        XRedPointEventElement.New(XEventId.EVENT_BUY_EXP_COMPLEATE),
        XRedPointEventElement.New(XEventId.EVENT_BUY_RECV_REWARD_COMPLEATE),
        XRedPointEventElement.New(XEventId.EVENT_BUY_RECV_ALL_REWARD_COMPLEATE),
    }
    return Events
end

function XRedPointConditionPassportCombPanelReward.Check()
    if XMVCA.XPassportComb:CheckPassportRewardRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionPassportCombPanelReward