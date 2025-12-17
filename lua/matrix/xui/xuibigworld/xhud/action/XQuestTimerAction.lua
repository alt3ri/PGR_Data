local XQuestBaseAction = require("XUi/XUiBigWorld/XHud/Action/XQuestBaseAction")

---@class XQuestTimerAction : XQuestBaseAction
local XQuestTimerAction = XClass(XQuestBaseAction, "XQuestTimerAction")

function XQuestTimerAction:OnInit(delay)
    self._Delay = delay or 0
end

function XQuestTimerAction:Execute()
    self:StopTimer()
    if self._Delay and self._Delay > 0 then
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self._Timer = nil
            self:Finish()
        end, self._Delay)

    else
        self:Finish()
    end
end

function XQuestTimerAction:OnFinish()
    self:StopTimer()
end

function XQuestTimerAction:OnDestroy()
    self:StopTimer()
end

function XQuestTimerAction:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = nil
end

function XQuestTimerAction:OnPause()
    self:StopTimer()
    self:Finish()
end

function XQuestTimerAction:GetActionType()
    return XMVCA.XBigWorldQuest.ActionType.Timer
end

return XQuestTimerAction