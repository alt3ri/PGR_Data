local XRedPointConditionActivityBtnOnce = {}

local Events = nil
function XRedPointConditionActivityBtnOnce.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE),
    }
    return Events
end

-- 活动按钮永久一次性红点：未点击过则亮，点击后永久不再显示
-- key 为 AddRedPointEvent 第5参数传入的身份key（由 XUiMain:GetActivityBtnIdentityKey 计算）
function XRedPointConditionActivityBtnOnce.Check(key)
    return not XMVCA.XUiMain:IsActivityBtnRedOnceClicked(key)
end

return XRedPointConditionActivityBtnOnce
