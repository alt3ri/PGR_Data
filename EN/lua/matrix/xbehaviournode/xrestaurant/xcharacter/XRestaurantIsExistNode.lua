
---@class XRestaurantIsExistNode : XLuaBehaviorNode 判断小人是否加载且显示
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
local XRestaurantIsExistNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantIsExist", CsBehaviorNodeType.Condition, true, false)

function XRestaurantIsExistNode:OnEnter()
    local isExist = self.AgentProxy:DoIsExist()

    if isExist then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end