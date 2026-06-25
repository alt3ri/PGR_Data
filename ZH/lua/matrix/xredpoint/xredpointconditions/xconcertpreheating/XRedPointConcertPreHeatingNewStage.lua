--- 音乐会预热新开放关卡蓝点
local XRedPointConcertPreHeatingNewStage = {}

local Events = nil

function XRedPointConcertPreHeatingNewStage.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_CONCERT_PRE_HEATING_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_CONCERT_PRE_HEATING_RED_POINT_UPDATE),
    }
    return Events
end

function XRedPointConcertPreHeatingNewStage.Check(stageId)
    if not XMVCA.XConcertPreHeating:IsActivityOpen() then
        return false
    end

    if XTool.IsNumberValid(stageId) then
        return XMVCA.XConcertPreHeating:CheckStageIsNew(stageId)
    end

    return XMVCA.XConcertPreHeating:CheckAnyStageIsNew()
end

return XRedPointConcertPreHeatingNewStage
