
---@class XRestaurantPerformHideBubbleNode : XLuaBehaviorNode 通过演出隐藏演员的气泡
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
---@field NpcId number 演员Id
local XRestaurantPerformHideBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantPerformHideBubble", CsBehaviorNodeType.Action, true, false)

function XRestaurantPerformHideBubbleNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["NpcId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.NpcId = self.Fields["NpcId"]
end

function XRestaurantPerformHideBubbleNode:OnEnter()
    self.AgentProxy:DoHideBubble(self.NpcId)
    self.Node.Status = CsNodeStatus.SUCCESS
end