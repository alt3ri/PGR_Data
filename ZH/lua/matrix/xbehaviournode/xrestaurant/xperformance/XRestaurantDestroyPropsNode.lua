
---@class XRestaurantDestroyPropsNode : XLuaBehaviorNode 销毁单个演员/演出道具
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
---@field NpcId number 演员/演出道具 Id
local XRestaurantDestroyPropsNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDestroyProps", CsBehaviorNodeType.Action, true, false)

function XRestaurantDestroyPropsNode:OnAwake()
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

function XRestaurantDestroyPropsNode:OnEnter()
    self.AgentProxy:DoDestroyProps(self.NpcId)
    self.Node.Status = CsNodeStatus.SUCCESS
end