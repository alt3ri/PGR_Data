local XRedPointGameCollectionCanReward = {}

function XRedPointGameCollectionCanReward.Check()
    local agency = XMVCA.XGameCollection
    if not agency then return false end

    if agency:HasRewardCanGet() or (agency:CheckActivityTips() and agency:HasGoodCanBuy()) then
        return true
    end

    if agency:HasFirstEnterMainBluePoint() then
        return true
    end

    return false
end

return XRedPointGameCollectionCanReward