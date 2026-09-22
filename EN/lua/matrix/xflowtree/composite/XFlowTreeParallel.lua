---@class XFlowTreeParallel : XFlowTreeCompositeBase 并行节点：所有子节点同时启动，全成功才成功，有失败则失败
---@field private _DoneCount number 已完成子节点数
---@field private _SucceedCount number 成功子节点数
---@field private _IsStarting boolean 是否处于批量启动阶段（期间只累加计数，不触发结算）
local XFlowTreeParallel = XClass(require("XFlowTree/Base/XFlowTreeCompositeBase"), "XFlowTreeParallel")

function XFlowTreeParallel:Ctor()
    self._DoneCount = 0
    self._SucceedCount = 0
    self._IsStarting = false
end

--region 行为树内部使用方法

function XFlowTreeParallel:OnStart(context)
    self.Super.OnStart(self, context)
    self._DoneCount = 0
    self._SucceedCount = 0

    self._IsStarting = true
    for i = 1, #self._Children do
        self._Children[i]:OnStart(context)
    end
    self._IsStarting = false
    self:_CheckFinish()
end

function XFlowTreeParallel:OnChildDone(child)
    self._DoneCount = self._DoneCount + 1
    if child:InternalGetResult() == self.XFlowTreeEnum.Result.Succeed then
        self._SucceedCount = self._SucceedCount + 1
    end
    self:_CheckFinish()
end

-- 结算：仅在非启动阶段、且全部子节点完成时上报结果
function XFlowTreeParallel:_CheckFinish()
    if self._IsStarting then
        return
    end
    if self._DoneCount < #self._Children then
        return
    end
    if self._SucceedCount == #self._Children then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
    else
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
    end
end

function XFlowTreeParallel:OnInterrupt()
    self.Super.OnInterrupt(self)
    for i = 1, #self._Children do
        if self._Children[i]:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
            self._Children[i]:OnInterrupt()
        end
    end
end

--endregion

return XFlowTreeParallel
