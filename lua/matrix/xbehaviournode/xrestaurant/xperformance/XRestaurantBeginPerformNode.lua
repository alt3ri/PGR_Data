
---@class XRestaurantBeginPerformNode : XLuaBehaviorNode 演出开始节点
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
local XRestaurantBeginPerformNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantBeginPerform", CsBehaviorNodeType.Action, true, false)


function XRestaurantBeginPerformNode:OnEnter()
    self.AgentProxy:BeginPerform()
    self.Node.Status = CsNodeStatus.SUCCESS
end