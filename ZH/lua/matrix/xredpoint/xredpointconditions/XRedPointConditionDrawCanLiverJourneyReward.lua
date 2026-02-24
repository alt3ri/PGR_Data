local XRedPointConditionDrawCanLiverJourneyReward = {}

function XRedPointConditionDrawCanLiverJourneyReward.Check(eventId, args)
    if args and args[1] then
        local drawId = args[1]
        local canLiverActivityId = XDataCenter.DrawManager.GetCanLiverActivityId()
        if not canLiverActivityId then
            return false
        end
        local config = XDrawConfigs.GetDrawCanLiverActivityCfgById(canLiverActivityId)
        local isShow = false
        if config and config.DrawIds then
            for k, v in pairs(config.DrawIds) do
                if v == drawId then
                    isShow = true
                    break
                end
            end
        end

        if not isShow then
            return false
        end
    end

    local index = XDataCenter.DrawManager.GetFirstCanJourneyRewardIndex()
    return index ~= nil
end

function XRedPointConditionDrawCanLiverJourneyReward.GetSubEvents()
    return
    {
        XRedPointEventElement.New(XEventId.EVENT_DRAW_CAN_LIVER_UPDATE),
    }
end

return XRedPointConditionDrawCanLiverJourneyReward
