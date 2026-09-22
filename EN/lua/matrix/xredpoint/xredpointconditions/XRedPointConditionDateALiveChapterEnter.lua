---@class XRedPointConditionDateALiveChapterEnter
local XRedPointConditionDateALiveChapterEnter = {}

local SubConditions = nil
local Events = nil

function XRedPointConditionDateALiveChapterEnter.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_DAILY_RESET,
    }
    return SubConditions
end

function XRedPointConditionDateALiveChapterEnter.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_ON_FESTIVAL_CHANGED),
        XRedPointEventElement.New(XEventId.EVENT_DATE_A_LIVE_FESTIVAL_ENTER),
    }
    return Events
end

function XRedPointConditionDateALiveChapterEnter.Check()
    local chapterId = XSignInConfigs.GetIntClientConfigValue("DateALiveChapterId")
    if not XTool.IsNumberValid(chapterId) then
        return false
    end

    if not XDataCenter.FubenFestivalActivityManager.IsFestivalInActivity(chapterId) then
        return false
    end

    local chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(chapterId)
    local stageIds = chapter and chapter:GetStageIdList()
    local lastStageId = stageIds and stageIds[#stageIds]
    local lastStage = lastStageId and chapter:GetStageByStageId(lastStageId)
    if not lastStage or lastStage:GetIsPass() then
        return false
    end

    return XMVCA.XDailyReset:CheckDateALiveDailyRedPoint()
end

return XRedPointConditionDateALiveChapterEnter
