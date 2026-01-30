
---@class XRestaurantPerformStateCheckNode : XLuaBehaviorNode 对比演出的状态
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
---@field State number 演出状态
local XRestaurantPerformStateCheckNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantPerformStateCheck", CsBehaviorNodeType.Condition, true, false)

function XRestaurantPerformStateCheckNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["State"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.State = self.Fields["State"]
end


function XRestaurantPerformStateCheckNode:OnEnter()
    local isEqual = self.AgentProxy:IsEqualState(self.State)
    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end