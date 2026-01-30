---@class XUiPanelFangKuaiCommander : XUiNode 首席弹框
---@field Parent XUiFangKuaiFight
---@field _Control XFangKuaiControl
local XUiPanelFangKuaiCommander = XClass(XUiNode, "XUiPanelFangKuaiCommander")

function XUiPanelFangKuaiCommander:OnStart()
    self._CommandantPopTime = tonumber(self._Control:GetClientConfig("CommandantPopTime"))
    self.TxtTips.text = self._Control:GetClientConfig("CommandantText")
end

function XUiPanelFangKuaiCommander:OnEnable()
    if self._PopTimer then
        XScheduleManager.UnSchedule(self._PopTimer)
        self._PopTimer = nil
    end
    XScheduleManager.ScheduleOnce(handler(self, self.Close), self._CommandantPopTime * 1000)
end

function XUiPanelFangKuaiCommander:OnDestroy()
    if self._PopTimer then
        XScheduleManager.UnSchedule(self._PopTimer)
        self._PopTimer = nil
    end
end

return XUiPanelFangKuaiCommander
