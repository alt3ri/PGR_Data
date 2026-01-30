
---@class XRestaurantRandomPathNode : XLuaBehaviorNode 小人随机寻路
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantRandomPathNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantRandomPath", CsBehaviorNodeType.Action, true, false)


function XRestaurantRandomPathNode:OnEnter()
    self.AgentProxy:DoRandomPath()
    self.Node.Status = CsNodeStatus.SUCCESS 
end