
---@class XRestaurantIsWorkWithBuffNode : XLuaBehaviorNode 判断员工是否Buff加成
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantIsWorkWithBuffNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantIsWorkWithBuff", CsBehaviorNodeType.Condition, true, false)

function XRestaurantIsWorkWithBuffNode:OnEnter()
    local isEqual = self.AgentProxy:DoIsWorkWithBuff()
    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end