local XHomeResetCamera = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeResetCamera", CsBehaviorNodeType.Action, true, false)

function XHomeResetCamera:OnEnter()
    self.AgentProxy:ResetCamera(function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end)
end