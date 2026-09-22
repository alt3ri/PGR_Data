---@class XFlowTreeActionFunCall : XFlowTreeAction 函数调用动作节点：调用一个函数，用返回值决定结果
---@field private _Handler function 执行函数
---@field private _SelfHandle any self 句柄
local XFlowTreeActionFunCall = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionFunCall")

--@param handler function 执行函数
--@param selfHandle any 可选，self 句柄。传 nil 则按静态方法调用 handler(context)
function XFlowTreeActionFunCall:Ctor(handler, selfHandle)
    self._Handler = handler
    self._SelfHandle = selfHandle
end


function XFlowTreeActionFunCall:OnEnter(context)
    if self._Handler then
        local result
        if self._SelfHandle ~= nil then
            result = self._Handler(self._SelfHandle, context)
        else
            result = self._Handler(context)
        end
        if result == false then
            self:OnDone(self.XFlowTreeEnum.Result.Fail)
        else
            self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        end
    else
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
    end
end

function XFlowTreeActionFunCall:OnExit(isInterrupt)
 
end

function XFlowTreeActionFunCall:OnDestroy()
    self.Super.OnDestroy(self)
    self._Handler = nil
    self._SelfHandle = nil
end


return XFlowTreeActionFunCall
