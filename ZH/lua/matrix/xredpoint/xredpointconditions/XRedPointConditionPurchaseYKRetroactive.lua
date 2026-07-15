-- 当月卡可补签时

local XRedPointConditionPurchaseYKRetroactive = {}
local Events = nil

function XRedPointConditionPurchaseYKRetroactive.GetEvents()
    Events = Events or {
        XEventId.EVENT_CARD_REFRESH_WELFARE_BTN
    }

    return Events
end

function XRedPointConditionPurchaseYKRetroactive.Check()
    local data = XDataCenter.PurchaseManager.GetYKInfoData()
    if not data then return false end
    if data.DailyRewardRemainDay <= 0 then return false end
    if not data.DailyRewardSupplementGetData then return false end

    local cardsMissed = data.DailyRewardSupplementGetData.Count

    if cardsMissed > 0 then
        local retroactiveItemId = data.DailyRewardSupplementGetConsumeItemId
        local retroactiveItemCount = XDataCenter.ItemManager.GetCount(
            retroactiveItemId)

        return retroactiveItemCount > 0
    end

    return false
end

return XRedPointConditionPurchaseYKRetroactive
