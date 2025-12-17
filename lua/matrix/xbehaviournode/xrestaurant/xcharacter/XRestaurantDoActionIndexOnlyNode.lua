
---@class XRestaurantDoActionIndexOnlyNode : XLuaBehaviorNode 根据下标播放动画（仅播放）
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
---@field Index number 动画组下标
---@field NeedFadeCross boolean 是否需要动画融合
---@field CrossDuration number 动画融合时长
local XRestaurantDoActionIndexOnlyNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDoActionIndexOnly", CsBehaviorNodeType.Action, true, false)

function XRestaurantDoActionIndexOnlyNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Index"] == nil or self.Fields["NeedFadeCross"] == nil or self.Fields["CrossDuration"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.Index = self.Fields["Index"]
    self.NeedFadeCross = self.Fields["NeedFadeCross"]
    self.CrossDuration = self.Fields["CrossDuration"]
    
end

function XRestaurantDoActionIndexOnlyNode:OnEnter()
    self.AgentProxy:DoActionIndex(self.Index, self.NeedFadeCross, self.CrossDuration)
    self.Node.Status = CsNodeStatus.SUCCESS
end