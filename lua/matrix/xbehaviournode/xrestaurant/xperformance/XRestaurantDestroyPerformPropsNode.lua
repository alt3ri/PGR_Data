
---@class XRestaurantDestroyPerformPropsNode : XLuaBehaviorNode 销毁演员/演出道具
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
local XRestaurantDestroyPerformPropsNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDestroyPerformProps", CsBehaviorNodeType.Action, true, false)

function XRestaurantDestroyPerformPropsNode:OnEnter()
    self.AgentProxy:DestroyAllProps()
    self.Node.Status = CsNodeStatus.SUCCESS
end