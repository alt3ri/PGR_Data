local XRedPointConditionEnvelopeGuessingEntrance = {}

function XRedPointConditionEnvelopeGuessingEntrance.Check()
    if not XMVCA.XEnvelopeGuessing:GetIsOpen(true) then
        return false
    end

    return XMVCA.XEnvelopeGuessing:HasDailyReward() or XMVCA.XEnvelopeGuessing:HasAnyAchievedTask()
end

return XRedPointConditionEnvelopeGuessingEntrance
