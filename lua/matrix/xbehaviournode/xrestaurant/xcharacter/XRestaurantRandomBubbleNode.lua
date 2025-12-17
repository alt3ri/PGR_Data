
---@class XRestaurantRandomBubbleNode : XLuaBehaviorNode 随机弹出气泡
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantRandomBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantRandomBubble", CsBehaviorNodeType.Action, true, false)


function XRestaurantRandomBubbleNode:OnEnter()
    self.AgentProxy:DoRandomBubble()
    self.Node.Status = CsNodeStatus.SUCCESS 
end