
---@class XRestaurantLoadCompleteNode : XLuaBehaviorNode 小人加载完成节点（设置标记）
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantLoadCompleteNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantLoadComplete", CsBehaviorNodeType.Action, true, false)


function XRestaurantLoadCompleteNode:OnEnter()
    self.AgentProxy:DoLoadComplete()
    self.Node.Status = CsNodeStatus.SUCCESS 
end