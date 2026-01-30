
local XUiBigWorldObtain = require("XUi/XUiBigWorld/XCommon/XUiBigWorldObtain")

---@class XUiBigWorldObtainSpecial : XUiBigWorldObtain
local XUiBigWorldObtainSpecial = XMVCA.XBigWorldUI:Register(XUiBigWorldObtain, "UiBigWorldObtainSpecial")

function XUiBigWorldObtainSpecial:OnEnable()
    if self._DisableAutoClose then
        self:SetCloseInfoVisible(true)
    else
        self:RegisterForceShow()
        self:RegisterAutoClose()
    end
end

function XUiBigWorldObtainSpecial:OnDisable()
    self:UnRegisterAutoClose()
    self:UnRegisterForceShow()
end

function XUiBigWorldObtainSpecial:IsSetGridClickProxy()
    return true
end

function XUiBigWorldObtainSpecial:InitCb()
    XUiBigWorldObtain.InitCb(self)
    self._ForceRemoveCb = handler(self, self.ForceRemove)
    --有其他界面强制打开时，此界面会被关闭
    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, self._ForceRemoveCb)
end

function XUiBigWorldObtainSpecial:RemoveCb()
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, self._ForceRemoveCb)
end

function XUiBigWorldObtainSpecial:ForceRemove(evt, args)
    if not args or args.Length <= 0 then
        return
    end
    local first = 0
    local uiName = args[first].UiData.UiName
    if self.Name == uiName then
        return
    end
    self:Remove()
end

function XUiBigWorldObtainSpecial:GetShowTime()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("BigWorldObtainSpecialShowTime")
end

function XUiBigWorldObtainSpecial:GetForceShowTime()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("BigWorldObtainSpecialForceShowTime")
end

function XUiBigWorldObtainSpecial:RegisterForceShow()
    local time = self:GetForceShowTime()
    self:SetCloseInfoVisible(false)
    self:UnRegisterForceShow()
    self._ForceShowTimer = XScheduleManager.ScheduleOnce(function() 
        self._ForceShowTimer = nil
        self:SetCloseInfoVisible(true)
    end, XScheduleManager.SECOND * time)
end

function XUiBigWorldObtainSpecial:UnRegisterForceShow()
    if not self._ForceShowTimer then
        return
    end
    XScheduleManager.UnSchedule(self._ForceShowTimer)
    self._ForceShowTimer = nil
end

function XUiBigWorldObtainSpecial:SetCloseInfoVisible(visible)
    self.BtnBack.gameObject:SetActiveEx(visible)
    if self.Txt then
        self.Txt.gameObject:SetActiveEx(visible)
    end
end