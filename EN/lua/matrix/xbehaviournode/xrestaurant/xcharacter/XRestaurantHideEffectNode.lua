
---@class XRestaurantHideEffectNode : XLuaBehaviorNode 隐藏小人特效
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantHideEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantHideEffect", CsBehaviorNodeType.Action, true, false)


function XRestaurantHideEffectNode:OnEnter()
    self.AgentProxy:DoHideEffect()
    self.Node.Status = CsNodeStatus.SUCCESS 
end