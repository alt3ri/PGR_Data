---@class XRestaurantDestroyEffectNode : XLuaBehaviorNode 销毁角色身上挂载的特效
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantDestroyEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantDestroyEffect", CsBehaviorNodeType.Action, true, false)


function XRestaurantDestroyEffectNode:OnEnter()
    self.AgentProxy:DoDestroyEffect()
    self.Node.Status = CsNodeStatus.SUCCESS 
end