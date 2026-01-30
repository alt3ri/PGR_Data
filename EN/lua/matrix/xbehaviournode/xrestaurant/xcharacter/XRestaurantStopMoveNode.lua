
---@class XRestaurantStopMoveNode : XLuaBehaviorNode 小人停止移动
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantStopMoveNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantStopMove", CsBehaviorNodeType.Action, true, false)


function XRestaurantStopMoveNode:OnEnter()
    self.AgentProxy:DoStopMove()
    self.Node.Status = CsNodeStatus.SUCCESS 
end