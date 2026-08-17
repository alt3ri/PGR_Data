----------------------------------------------------------------
local XRedPointConditionMainStore = {}
local Events = nil

function XRedPointConditionMainStore.Check(eventId, args)
    if not (XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive, nil, true)) then
        return false
    end

    if XSaveTool.GetData("IsUiMainBtnStoreBlue" .. XPlayer.Id) == 1 then
        return true
    end

    -- 有免费商品可购买(服务端MainUiShopRedpointNotify下发)
    if XShopManager.CheckAnyShopFreeGoodsRedPoint() then
        return true
    end

    return false
end

function XRedPointConditionMainStore.GetSubEvents()
    if Events then
        return Events
    end
    Events = {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_RESTRICT_CONFIG_TRIGGER_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_SHOP_FREE_GOODS_RED_POINT_UPDATE)
    }
    return Events
end

return XRedPointConditionMainStore
