local XRedPointAccumulateExpendShopNotify = {}
local Events = nil
function XRedPointAccumulateExpendShopNotify.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_NOTIFY_ACCUMULATE_EXPEND_SHOP_DATA),
    }
    return Events
end

function XRedPointAccumulateExpendShopNotify.Check()
    return XMVCA.XShop:IsShowAccumulateExpendShopRedPoint()
end

return XRedPointAccumulateExpendShopNotify

