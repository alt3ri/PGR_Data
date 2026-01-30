----------------------------------------------------------------
--检测设置自定义键位冲突
local XRedPointConditionMainSet = {}
local Events = nil
function XRedPointConditionMainSet.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED)
            }
    return Events
end

function XRedPointConditionMainSet.Check()
    local isOpenUiFightCustomRed = XKeyPadManager.IsOpenUiFightCustomRed()
    return CS.XRLFightSettings.UiConflict or not isOpenUiFightCustomRed
end

return XRedPointConditionMainSet