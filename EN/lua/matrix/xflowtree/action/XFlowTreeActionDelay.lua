---@class XFlowTreeActionDelay : XFlowTreeAction 延时动作节点：等待指定秒数后完成
---@field private _DelaySeconds number 延时秒数
---@field private _TimerId number 定时器Id
local XFlowTreeActionDelay = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionDelay")

--@param delaySeconds number 延时秒数
function XFlowTreeActionDelay:Ctor(delaySeconds)
    self._DelaySeconds = delaySeconds or 0
    self._TimerId = nil
end


function XFlowTreeActionDelay:OnEnter(context)
    self._TimerId = XScheduleManager.ScheduleOnce(function()
        self._TimerId = nil
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
    end, self._DelaySeconds * XScheduleManager.SECOND)
end

function XFlowTreeActionDelay:OnExit(isInterrupt)
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
end


return XFlowTreeActionDelay
