local XRedPointConditionRadioSign = {}

function XRedPointConditionRadioSign.Check()
    local hasRewardAvailable = XMVCA.XRadioSign:HasRewardAvailable()
    return hasRewardAvailable
end

return XRedPointConditionRadioSign

