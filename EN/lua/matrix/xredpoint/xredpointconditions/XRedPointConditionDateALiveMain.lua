---@class XRedPointConditionDateALiveMain
local XRedPointConditionDateALiveMain = {}

local SubCondition = nil

function XRedPointConditionDateALiveMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_DATEALIVE_SIGN_IN_REWARD,
        XRedPointConditions.Types.CONDITION_DATEALIVE_CHAPTER_ENTER,
    }
    return SubCondition
end

function XRedPointConditionDateALiveMain.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DATEALIVE_SIGN_IN_REWARD) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DATEALIVE_CHAPTER_ENTER) then
        return true
    end
    return false
end

return XRedPointConditionDateALiveMain