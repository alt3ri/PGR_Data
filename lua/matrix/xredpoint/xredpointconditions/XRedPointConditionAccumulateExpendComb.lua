local XRedPointConditionAccumulateExpendComb = {}

function XRedPointConditionAccumulateExpendComb.Check()
    local result = 0
    
    if XMVCA.XAccumulateExpendL:CheckIsFirstOpen() then
        result = result + 1
    end
    if XMVCA.XAccumulateExpendL:CheckHasReward() then
        result = result + 1
    end

    return result
end

return XRedPointConditionAccumulateExpendComb