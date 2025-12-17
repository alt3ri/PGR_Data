
---@class XRestaurantHideBubbleNode : XLuaBehaviorNode 隐藏小人气泡
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantHideBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantHideBubble", CsBehaviorNodeType.Action, true, false)


function XRestaurantHideBubbleNode:OnEnter()
    self.AgentProxy:DoHideBubble()
    self.Node.Status = CsNodeStatus.SUCCESS 
end