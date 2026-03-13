----------------------------------------------------------------
local XRedPointConditionShopFirstBlue = {}
local Events = nil

function XRedPointConditionShopFirstBlue.Check(args)
    if args and args.Id and args.IsNeedFirstBluePoint then
        local key = string.format("ShopTabFirstBluePoint_%s_%s", tostring(args.Id), tostring(XPlayer.Id))
        local hasClicked = XSaveTool.GetData(key)
        return not hasClicked
    end
    return false
end

function XRedPointConditionShopFirstBlue.GetSubEvents()
    if Events then
        return Events
    end
    Events = {
        XRedPointEventElement.New(XEventId.EVENT_SHOP_TAB_BTN_RED_POINT_UPDATE)
    }


    return Events
end

return XRedPointConditionShopFirstBlue
