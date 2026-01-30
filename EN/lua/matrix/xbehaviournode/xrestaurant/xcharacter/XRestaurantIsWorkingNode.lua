
---@class XRestaurantIsWorkingNode : XLuaBehaviorNode 判断员工是否工作中（非暂停）
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantIsWorkingNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantIsWorking", CsBehaviorNodeType.Condition, true, false)

function XRestaurantIsWorkingNode:OnEnter()
    local isWorking = self.AgentProxy:DoIsWorking()

    if isWorking then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end