
---@class XRestaurantSetRedPointNode : XLuaBehaviorNode 设置顾客红色点位
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantSetRedPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantSetRedPoint", CsBehaviorNodeType.Action, true, false)


function XRestaurantSetRedPointNode:OnEnter()
    self.AgentProxy:DoSetRedPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end