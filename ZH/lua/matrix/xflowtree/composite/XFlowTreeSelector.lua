---@class XFlowTreeSelector : XFlowTreeCompositeBase 选择节点：子节点依次执行，首个成功即成功，全失败才失败
---@field private _CurIndex number 当前执行索引
local XFlowTreeSelector = XClass(require("XFlowTree/Base/XFlowTreeCompositeBase"), "XFlowTreeSelector")

function XFlowTreeSelector:Ctor()
    self._CurIndex = 0
end

--region 行为树内部使用方法

function XFlowTreeSelector:OnStart(context)
    self.Super.OnStart(self, context)
    self._CurIndex = 0
    self:_Next()
end

function XFlowTreeSelector:_Next()
    self._CurIndex = self._CurIndex + 1
    if self._CurIndex <= #self._Children then
        self._Children[self._CurIndex]:OnStart(self._Context)
    else
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
    end
end

function XFlowTreeSelector:OnChildDone(child)
    if child:InternalGetResult() == self.XFlowTreeEnum.Result.Succeed then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
    else
        self:_Next()
    end
end

function XFlowTreeSelector:OnInterrupt()
    self.Super.OnInterrupt(self)
    if self._CurIndex >= 1 and self._CurIndex <= #self._Children then
        local child = self._Children[self._CurIndex]
        if child:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
            child:OnInterrupt()
        end
    end
end

--endregion

return XFlowTreeSelector
