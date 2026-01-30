
---@class XUiBigWorldSetControllerTips : XUiBigWorldSetControllerTipsPartial
local XUiBigWorldSetControllerTips = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSetControllerTips")
local XUiSetControllerTipsGroup = require("XUi/XUiCommon/XUiSetControllerTipsGroup")

function XUiBigWorldSetControllerTips:OnStart()
    if self.UIBigWorldSetControllerTipsGroup then
        self.UISetControllerTipsGroup = XUiSetControllerTipsGroup.New(self.UIBigWorldSetControllerTipsGroup, self)
    end
end

function XUiBigWorldSetControllerTips:OnGetLuaEvents()
    return { XEventId.EVENT_CONTROLLER_TIPS_CHNAGE, }
end

function XUiBigWorldSetControllerTips:OnGetEvents()
    return { XEventId.EVENT_INPUT_DEVICE_CHANGE, }
end

function XUiBigWorldSetControllerTips:OnNotify(event, ...)
    if event == XEventId.EVENT_CONTROLLER_TIPS_CHNAGE or event == XEventId.EVENT_INPUT_DEVICE_CHANGE then
        local uiName = XUiManager.GetShowUIControllerTipsName()
        self:SetUIName(uiName)
    end
end

function XUiBigWorldSetControllerTips:SetUIName(uiName)
    if self.UISetControllerTipsGroup then
        self.UISetControllerTipsGroup:SetUIName(uiName)
    end
end

return XUiBigWorldSetControllerTips
