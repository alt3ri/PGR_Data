
---@class XRestaurantChangePerformStateNode : XLuaBehaviorNode 演出改变状态
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
---@field State number 演出状态
local XRestaurantChangePerformStateNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantChangePerformState", CsBehaviorNodeType.Action, true, false)

function XRestaurantChangePerformStateNode:OnAwake()
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

function XRestaurantChangePerformStateNode:OnEnter()
    self.AgentProxy:ChangeState(self.State)
    self.Node.Status = CsNodeStatus.SUCCESS
end