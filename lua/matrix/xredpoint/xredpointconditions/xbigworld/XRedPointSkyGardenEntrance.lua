
local XRedPointSkyGardenEntrance = {}
local SubEvent = nil

function XRedPointSkyGardenEntrance.GetSubEvents()
    SubEvent = SubEvent or {
        XRedPointEventElement.New(XEventId.EVENT_BIG_WORLD_ENTRANCE_RED_POINT_REFRESH)
    }
end

function XRedPointSkyGardenEntrance.Check()
    return XMVCA.XBigWorldGamePlay:CheckSkyGardenEntranceRedPoint()
end

return XRedPointSkyGardenEntrance