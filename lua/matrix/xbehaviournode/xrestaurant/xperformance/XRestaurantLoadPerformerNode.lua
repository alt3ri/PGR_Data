
---@class XRestaurantLoadPerformerNode : XLuaBehaviorNode 加载单个演员/演出道具
---@field AgentProxy XRestaurantPerformAgent 厨房演出行为代理
---@field NpcId number 演员/演出道具Id
---@field Position UnityEngine.Vector3Int 加载出来放置的位置
---@field Rotation UnityEngine.Vector3Int 加载出来旋转的角度
---@field IsPerformer boolean 是否为演员
local XRestaurantLoadPerformerNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantLoadPerformer", CsBehaviorNodeType.Action, true, false)

function XRestaurantLoadPerformerNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["NpcId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.NpcId = self.Fields["NpcId"]
    
    self.Position = Vector3(self.Fields["PositionX"], self.Fields["PositionY"], self.Fields["PositionZ"])
    self.Rotation = Vector3(self.Fields["RotationX"], self.Fields["RotationY"], self.Fields["RotationZ"])
    self.IsPerformer = self.Fields["IsPerformer"]
end

function XRestaurantLoadPerformerNode:OnEnter()
    self.AgentProxy:LoadPerformProp(self.IsPerformer, self.NpcId, self.Position, self.Rotation, function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end)
    
end