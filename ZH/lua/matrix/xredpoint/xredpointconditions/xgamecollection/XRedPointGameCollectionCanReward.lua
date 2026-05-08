local XRedPointGameCollectionCanReward = {}
function XRedPointGameCollectionCanReward.Check()
    local agency = XMVCA.XGameCollection
    if not agency then return 0 end

    if agency:HasRewardCanGet() or agency:HasGoodCanBuy() or agency:CheckActivityTips() then
        return 1
    end

    return 0
end

return XRedPointGameCollectionCanReward