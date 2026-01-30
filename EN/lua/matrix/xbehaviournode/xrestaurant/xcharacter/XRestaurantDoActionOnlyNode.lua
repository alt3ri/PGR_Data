
---@class XRestaurantDoActionOnlyNode : XLuaBehaviorNode 根据动画名播放动画（仅播放）
---@field AgentProxy XRestaurantCharAgent 厨房小人行为代理
---@field ActionId number 动画组下标
---@field NeedFadeCross boolean 是否需要动画融合
---@field CrossDuration number 动画融合时长
local XRestaurantDoActionOnlyNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDoActionOnly", CsBehaviorNodeType.Action, true, false)

function XRestaurantDoActionOnlyNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["ActionId"] == nil or self.Fields["NeedFadeCross"] == nil or self.Fields["CrossDuration"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.ActionId = self.Fields["ActionId"]
    self.NeedFadeCross = self.Fields["NeedFadeCross"]
    self.CrossDuration = self.Fields["CrossDuration"]
    
end

function XRestaurantDoActionOnlyNode:OnEnter()
    self.AgentProxy:DoAction(self.ActionId, self.NeedFadeCross, self.CrossDuration)
    self.Node.Status = CsNodeStatus.SUCCESS
end