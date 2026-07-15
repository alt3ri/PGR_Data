--- 音乐会预热直播中入口提示
local XRedPointConcertPreHeatingLive = {}

local Events = nil

function XRedPointConcertPreHeatingLive.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_CONCERT_PRE_HEATING_RED_POINT_UPDATE),
    }
    return Events
end

function XRedPointConcertPreHeatingLive.Check()
    if not XMVCA.XConcertPreHeating:IsActivityOpen() then
        return false
    end

    return XMVCA.XConcertPreHeating:CheckActivityEntryLive()
end

return XRedPointConcertPreHeatingLive
