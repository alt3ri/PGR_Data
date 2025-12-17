
---@class XRestaurantSetStartPointNode : XLuaBehaviorNode 设置顾客起始点
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantSetStartPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantSetStartPoint", CsBehaviorNodeType.Action, true, false)


function XRestaurantSetStartPointNode:OnEnter()
    self.AgentProxy:DoSetStartPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end