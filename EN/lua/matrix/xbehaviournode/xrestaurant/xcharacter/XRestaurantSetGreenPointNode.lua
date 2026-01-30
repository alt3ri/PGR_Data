
---@class XRestaurantSetGreenPointNode : XLuaBehaviorNode 设置顾客绿色点位
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantSetGreenPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantSetGreenPoint", CsBehaviorNodeType.Action, true, false)


function XRestaurantSetGreenPointNode:OnEnter()
    self.AgentProxy:DoSetGreenPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end