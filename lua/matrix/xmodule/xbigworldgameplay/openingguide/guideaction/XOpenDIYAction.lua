local XGuideAction = require("XModule/XBigWorldGamePlay/OpeningGuide/GuideAction/XGuideAction")

---@class XOpenDIYAction : XGuideAction
local XOpenDIYAction = XClass(XGuideAction, "XOpenDIYAction")

function XOpenDIYAction:Begin()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_UI_BIG_WORLD_DIY_DESTROY, self.Finish, self)
    XMVCA.XBigWorldCommanderDIY:SetFromOpenGuide(true)
    XMVCA.XBigWorldCommanderDIY:OpenMainUi()
end

function XOpenDIYAction:OnFinish()
    self._OpenGuide:SetUpdateEnterData(true)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_UI_BIG_WORLD_DIY_DESTROY, self.Finish, self)
    XMVCA.XBigWorldCommanderDIY:SetFromOpenGuide(false)
end

return XOpenDIYAction
