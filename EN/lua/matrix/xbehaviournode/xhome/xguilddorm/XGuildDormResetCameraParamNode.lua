local XGuildDormResetCameraParamNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormResetCameraParam", CsBehaviorNodeType.Action, true, false)

function XGuildDormResetCameraParamNode:OnEnter()
    self.AgentProxy:ResetCameraParam()
    self.Node.Status = CsNodeStatus.SUCCESS
end