
---@class XRestaurantCheckIntNode : XLuaBehaviorNode 判断数字是否相等，小人为员工时，判断区域类型
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
---@field IntValue number 需要判断的数字
local XRestaurantCheckIntNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantCheckInt", CsBehaviorNodeType.Condition, true, false)

function XRestaurantCheckIntNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["IntValue"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.IntValue = self.Fields["IntValue"]
    
end

function XRestaurantCheckIntNode:OnEnter()
    local isEqual = self.AgentProxy:DoCheckInt(self.IntValue)

    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end