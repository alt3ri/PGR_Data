---@class XRestaurantDisposeRoleNode : XLuaBehaviorNode 移除小人
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantDisposeRoleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantDisposeRole", CsBehaviorNodeType.Action, true, false)


function XRestaurantDisposeRoleNode:OnEnter()
    self.AgentProxy:DelayRelease()
    self.Node.Status = CsNodeStatus.SUCCESS 
end