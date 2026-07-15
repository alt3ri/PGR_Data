--- 音乐会预热活动入口总蓝点
local XRedPointConcertPreHeatingMain = {}

local SubCondition = nil

function XRedPointConcertPreHeatingMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_CONCERT_PRE_HEATING_NEW_STAGE,
        XRedPointConditions.Types.CONDITION_CONCERT_PRE_HEATING_TASK,
        XRedPointConditions.Types.CONDITION_CONCERT_PRE_HEATING_LIVE,
    }
    return SubCondition
end

function XRedPointConcertPreHeatingMain.Check()
    if not XMVCA.XConcertPreHeating:IsActivityOpen() then
        return false
    end

    return XRedPointManager.CheckConditions(XRedPointConcertPreHeatingMain.GetSubConditions())
end

return XRedPointConcertPreHeatingMain
