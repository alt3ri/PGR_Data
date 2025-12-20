local XGuideAction = require("XModule/XBigWorldGamePlay/OpeningGuide/GuideAction/XGuideAction")

---@class XOpenDIYAction : XGuideAction
local XOpenDIYAction = XClass(XGuideAction, "XOpenDIYAction")

function XOpenDIYAction:Begin()
    if not XMVCA.XBigWorldGamePlay:IsInGame() then
        return
    end
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_UI_BIG_WORLD_DIY_DESTROY, self.Finish, self)
    XMVCA.XBigWorldCommanderDIY:SetFromOpenGuide(true)
    XMVCA.XBigWorldCommanderDIY:OpenMainUi()
end

function XOpenDIYAction:OnFinish()
    if not XMVCA.XBigWorldGamePlay:IsInGame() then
        return
    end
    self._OpenGuide:SetUpdateEnterData(true)
    self:Clear()
    XMVCA.XBigWorldCommanderDIY:SetFromOpenGuide(false)
end

function XOpenDIYAction:Clear()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_UI_BIG_WORLD_DIY_DESTROY, self.Finish, self)
end

return XOpenDIYAction
