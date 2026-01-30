
---@class XRestaurantPerformShowBubbleNode : XLuaBehaviorNode 通过演出展示演员的气泡
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
---@field NpcId number 演员Id
---@field DialogId number 对话表Id
---@field Index number 对话内容下标
local XRestaurantPerformShowBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantPerformShowBubble", CsBehaviorNodeType.Action, true, false)

function XRestaurantPerformShowBubbleNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["NpcId"] == 0 or self.Fields["DialogId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.NpcId = self.Fields["NpcId"]
    self.DialogId = self.Fields["DialogId"]
    self.Index = self.Fields["Index"]
end

function XRestaurantPerformShowBubbleNode:OnEnter()
    self.AgentProxy:DoBubble(self.NpcId, self.DialogId, self.Index)
    self.Node.Status = CsNodeStatus.SUCCESS
end