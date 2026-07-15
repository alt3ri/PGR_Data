local XRedPointConditionFashionStoryReward = {}

function XRedPointConditionFashionStoryReward.Check()
    local activityId = XMVCA.XFashionStory:GetCurrentActivityId()
    local state = XMVCA.XFashionStory:GetRewardClaimState(activityId)
    return state == XMVCA.XFashionStory.RewardState.CanReceive
end

return XRedPointConditionFashionStoryReward
