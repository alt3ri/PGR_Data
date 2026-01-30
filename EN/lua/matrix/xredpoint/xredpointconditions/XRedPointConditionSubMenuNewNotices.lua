----------------------------------------------------------------
local XRedPointConditionSubMenuNewNotices = {}
local Events = nil

function XRedPointConditionSubMenuNewNotices.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_ACTIVITY_SUBMENU_READ_CHANGE),
    }
    return Events
end

function XRedPointConditionSubMenuNewNotices.Check()
    -- 整体屏蔽判断
    if not XMVCA.XUiMain:CheckUiMainTerminalMobileListUnlock() then
        return false
    end
    
    return XDataCenter.NoticeManager.CheckSubMenuRedPoint()
end

return XRedPointConditionSubMenuNewNotices