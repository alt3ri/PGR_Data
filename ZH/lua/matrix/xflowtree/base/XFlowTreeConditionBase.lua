---@class XFlowTreeConditionBase : XFlowTreeNode 条件判定基类
local XFlowTreeConditionBase = XClass(require("XFlowTree/Base/XFlowTreeNode"), "XFlowTreeConditionBase")

--region 使用者需要tobeoverrid 的方法

function XFlowTreeConditionBase:GetNodeType()
    return self.XFlowTreeEnum.NodeType.Condition
end

-- 子类重写：是否满足条件
--@return boolean
function XFlowTreeConditionBase:IsMeetCondition()
    return false
end

--endregion

--region 行为树内部使用方法

-- 条件节点进入后立即判定并完成
function XFlowTreeConditionBase:OnEnter(context)
    local meet = self:IsMeetCondition()
    if meet then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
    else
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
    end
end

--endregion

return XFlowTreeConditionBase
