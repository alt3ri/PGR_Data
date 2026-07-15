--- 通关飘窗
---@class XUiPanelDyeMergeFinish: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelDyeMergeFinish = XClass(XUiNode, "XUiPanelDyeMergeFinish")

function XUiPanelDyeMergeFinish:OnStart()
    self._CloseHandler = handler(self, self.Close)
end

function XUiPanelDyeMergeFinish:OnEnable()
    self:_StopDelayCloseTimer()
    
    local delay = math.floor(XScheduleManager.SECOND * XMVCA.XDyeMergeGame:GetClientDyeMergeNumberByKey("GameFinishPanelDelayCloseTime"))
    
    self._DelayCloseTimerId = XScheduleManager.ScheduleOnce(self._CloseHandler, delay)
    
    XLuaUiManager.SetMask(true)
end

function XUiPanelDyeMergeFinish:OnDisable()
    self:_StopDelayCloseTimer()

    XLuaUiManager.SetMask(false)
end

function XUiPanelDyeMergeFinish:_StopDelayCloseTimer()
    if self._DelayCloseTimerId then
        XScheduleManager.UnSchedule(self._DelayCloseTimerId)
        self._DelayCloseTimerId = nil
    end
end

return XUiPanelDyeMergeFinish