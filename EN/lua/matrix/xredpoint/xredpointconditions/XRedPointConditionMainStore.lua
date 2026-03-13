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
    
    return false
end

function XRedPointConditionMainStore.GetEvents()
    if Events then
        return Events
    end
    Events = {
        XEventId.EVENT_ITEM_RESTRICT_CONFIG_TRIGGER_CHANGE
    }
    return Events
end

return XRedPointConditionMainStore
