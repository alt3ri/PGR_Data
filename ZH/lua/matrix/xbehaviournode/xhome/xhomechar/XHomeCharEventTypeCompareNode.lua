---@class XHomeCharEventTypeCompareNode : XLuaBehaviorNode 事件类型比较节点
---@field EventType number 事件类型
---@deprecated 公会宿舍：类型是：FurnitureRewardEventType 目前只有一个事件类型 Normal = 1
local XHomeCharEventTypeCompareNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharEventTypeCompare", CsBehaviorNodeType.Condition, true, false)

function XHomeCharEventTypeCompareNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["EventType"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.EventType = self.Fields["EventType"]
end


function XHomeCharEventTypeCompareNode:OnEnter()
    local result = self.AgentProxy:CheckEventCompleted(self.EventType, function(isFailed)
        if not isFailed then
            self.Node.Status = CsNodeStatus.SUCCESS
        else
            self.Node.Status = CsNodeStatus.FAILED
        end
    end)

    if not result then
        self.Node.Status = CsNodeStatus.FAILED
    end
end