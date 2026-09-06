---@class XFlowTreeSequence : XFlowTreeCompositeBase 顺序节点：子节点依次执行，全成功才成功，遇失败终止
---@field private _CurIndex number 当前执行索引
local XFlowTreeSequence = XClass(require("XFlowTree/Base/XFlowTreeCompositeBase"), "XFlowTreeSequence")

function XFlowTreeSequence:Ctor()
    self._CurIndex = 0
end

--region 行为树内部使用方法

function XFlowTreeSequence:OnStart(context)
    self.Super.OnStart(self, context)
    self._CurIndex = 0
    if #self._Children == 0 then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end
    self:_Next()
end

function XFlowTreeSequence:_Next()
    self._CurIndex = self._CurIndex + 1
    if self._CurIndex <= #self._Children then
        self._Children[self._CurIndex]:OnStart(self._Context)
    end
end

function XFlowTreeSequence:OnChildDone(child)
    if child:InternalGetResult() == self.XFlowTreeEnum.Result.Succeed then
        if self._CurIndex == #self._Children then
            self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        else
            self:_Next()
        end
    else
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
    end
end

function XFlowTreeSequence:OnInterrupt()
    self.Super.OnInterrupt(self)
    if self._CurIndex >= 1 and self._CurIndex <= #self._Children then
        local child = self._Children[self._CurIndex]
        if child:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
            child:OnInterrupt()
        end
    end
end

--endregion

return XFlowTreeSequence
