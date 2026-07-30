local XRedPointConditionEnvelopeGuessingEntrance = {}

function XRedPointConditionEnvelopeGuessingEntrance.Check()
    if XMVCA.XEnvelopeGuessing:GetCurrentActivity() == nil then
        return false
    end

    return XMVCA.XEnvelopeGuessing:HasDailyReward()
        or XMVCA.XEnvelopeGuessing:HasAnyAchievedTask()
end

return XRedPointConditionEnvelopeGuessingEntrance
