----------------------------------------------------------------
local XRedPointConditionShopNotifyRed = {}
local Events = nil

function XRedPointConditionShopNotifyRed.Check(args)
    local key = string.format("IsShopTabRedPoint%s", tostring(XPlayer.Id))
    local state = XSaveTool.GetData(key)
    return state == 1
end

function XRedPointConditionShopNotifyRed.GetSubEvents()
    if Events then
        return Events
    end
    Events = {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_RESTRICT_CONFIG_TRIGGER_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_SHOP_TAB_BTN_RED_POINT_UPDATE),
    }
    return Events
end

return XRedPointConditionShopNotifyRed
