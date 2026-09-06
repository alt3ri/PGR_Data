---@class XRedPointConditionDateALiveSignInReward 约战联动签到存在可领取奖励
local XRedPointConditionDateALiveSignInReward = {}

local Events = nil

function XRedPointConditionDateALiveSignInReward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_SIGN_IN_FIVE_OCLOCK_REFRESH),
        XRedPointEventElement.New(XEventId.EVENT_SIGN_IN_SUCCESS_REFRESH),
    }
    return Events
end

function XRedPointConditionDateALiveSignInReward.Check()
    local signInId = XSignInConfigs.GetIntClientConfigValue("DateALiveSignInId")
    if not XTool.IsNumberValid(signInId) then
        return false
    end
    local signData = XDataCenter.SignInManager.GetSignInData(signInId)
    return signData and not signData.Got
end

return XRedPointConditionDateALiveSignInReward