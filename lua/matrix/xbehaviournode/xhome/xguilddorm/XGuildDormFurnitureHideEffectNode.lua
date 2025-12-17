local XGuildDormFurnitureHideEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormFurnitureHideEffect", CsBehaviorNodeType.Action, true, false)

function XGuildDormFurnitureHideEffectNode:OnAwake()
    if self.Fields == nil or self.Fields["EffectIds"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    self.EffectIds = self.Fields["EffectIds"]
end

function XGuildDormFurnitureHideEffectNode:OnEnter()
    self.AgentProxy:FurnitureHideEffect(self.EffectIds)
    self.Node.Status = CsNodeStatus.SUCCESS
end