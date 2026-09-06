---@class XFlowTreeBranch : XFlowTreeCompositeBase 分支节点：判定条件真假，真走 TrueWork，假走 FalseWork
---@field private _Condition XFlowTreeConditionBase 条件节点
---@field private _ConditionResult boolean 条件判定结果
---@field private _TrueWork XFlowTreeNode 条件为真时执行的子节点
---@field private _FalseWork XFlowTreeNode 条件为假时执行的子节点
local XFlowTreeBranch = XClass(require("XFlowTree/Base/XFlowTreeCompositeBase"), "XFlowTreeBranch")

function XFlowTreeBranch:Ctor()
    self._Condition = nil
    self._ConditionResult = false
    self._TrueWork = nil
    self._FalseWork = nil
end

--region 使用者外部使用方法
-- Branch 不支持 AddChild，请使用 SetCondition
function XFlowTreeBranch:AddChild(node)
    XLog.Error("[XFlowTreeBranch] AddChild 不可用：请使用 SetCondition 设置条件与分支")
    return self
end

-- 设置条件与分支
--@param condition XFlowTreeConditionBase
--@param trueWork XFlowTreeNode
--@param falseWork XFlowTreeNode
function XFlowTreeBranch:SetCondition(condition, trueWork, falseWork)
    if not self:InternalAssertNotStarted("SetCondition") then return end
    self._Condition = condition
    self._TrueWork = trueWork
    self._FalseWork = falseWork

    self._Condition:InternalSetParent(self)
    if self._TrueWork then
        self._TrueWork:InternalSetParent(self)
    end
    if self._FalseWork then
        self._FalseWork:InternalSetParent(self)
    end

    -- Children 供 GetChildren 遍历
    self._Children = {}
    table.insert(self._Children, self._Condition)
    if self._TrueWork then
        table.insert(self._Children, self._TrueWork)
    end
    if self._FalseWork then
        table.insert(self._Children, self._FalseWork)
    end
end

--endregion

--region 行为树内部使用方法

function XFlowTreeBranch:OnStart(context)
    self.Super.OnStart(self, context)
    self._Condition:OnStart(context)
end

function XFlowTreeBranch:OnChildDone(child)
    if child == self._Condition then
        -- 条件判定完成，选分支
        self._ConditionResult = (child:InternalGetResult() == self.XFlowTreeEnum.Result.Succeed)
        if self._ConditionResult then
            if self._TrueWork then
                self._TrueWork:OnStart(self._Context)
            else
                self:OnDone(self.XFlowTreeEnum.Result.Succeed)
            end
        else
            if self._FalseWork then
                self._FalseWork:OnStart(self._Context)
            else
                self:OnDone(self.XFlowTreeEnum.Result.Succeed)
            end
        end
    elseif child == self._TrueWork or child == self._FalseWork then
        -- 分支子节点完成，结果直接上报
        self:OnDone(child:InternalGetResult())
    end
end

function XFlowTreeBranch:OnInterrupt()
    self.Super.OnInterrupt(self)
    if self._Condition:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
        self._Condition:OnInterrupt()
    end
    if self._ConditionResult then
        if self._TrueWork and self._TrueWork:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
            self._TrueWork:OnInterrupt()
        end
    else
        if self._FalseWork and self._FalseWork:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
            self._FalseWork:OnInterrupt()
        end
    end
end

function XFlowTreeBranch:OnDestroy()
    self.Super.OnDestroy(self)
    self._Condition = nil
    self._TrueWork = nil
    self._FalseWork = nil
end

--endregion

return XFlowTreeBranch
