
---@class XRestaurantLoadEffectNode : XLuaBehaviorNode 小人加载特效
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
---@field EffectId number 特效Id，Effect表查看
---@field Position UnityEngine.Vector3Int 特效位置相对角色
local XRestaurantLoadEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantLoadEffect", CsBehaviorNodeType.Action, true, false)

function XRestaurantLoadEffectNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["EffectId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.EffectId = self.Fields["EffectId"]
    
    self.Position = CS.UnityEngine.Vector3(self.Fields["PositionX"], self.Fields["PositionY"], self.Fields["PositionZ"])
    
end

function XRestaurantLoadEffectNode:OnEnter()
    self.AgentProxy:DoLoadEffect(self.EffectId, self.Position)
    self.Node.Status = CsNodeStatus.SUCCESS
end