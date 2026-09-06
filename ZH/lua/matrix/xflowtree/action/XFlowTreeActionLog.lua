---@class XFlowTreeActionLog : XFlowTreeAction 日志动作节点：打印一条日志后立即完成
---@field private _Msg string 日志内容
local XFlowTreeActionLog = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionLog")

--@param msg string 日志内容
function XFlowTreeActionLog:Ctor(msg)
    self._Msg = msg or ""
end


function XFlowTreeActionLog:OnEnter(context)
    XLog.Debug("[XFlowTree] " .. tostring(self._Msg))
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionLog:OnExit(isInterrupt)
    -- 事件清理：本节点无运行态事件需要处理
end

function XFlowTreeActionLog:OnDestroy()
    self.Super.OnDestroy(self)
    self._Msg = nil
end


return XFlowTreeActionLog
