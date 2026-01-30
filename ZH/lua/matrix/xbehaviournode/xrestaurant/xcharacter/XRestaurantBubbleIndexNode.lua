
---@class XRestaurantBubbleIndexNode : XLuaBehaviorNode 根据下标弹出气泡
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
---@field Index number Dialog表中的下标
local XRestaurantBubbleIndexNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantBubbleIndex", CsBehaviorNodeType.Action, true, false)

function XRestaurantBubbleIndexNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Index"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.Index = self.Fields["Index"]
end

function XRestaurantBubbleIndexNode:OnEnter()
    self.AgentProxy:DoBubbleIndex(self.Index)
    self.Node.Status = CsNodeStatus.SUCCESS 
end