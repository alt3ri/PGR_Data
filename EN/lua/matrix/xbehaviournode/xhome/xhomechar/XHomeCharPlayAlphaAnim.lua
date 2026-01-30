local XHomeCharPlayAlphaAnim = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharPlayAlphaAnim", CsBehaviorNodeType.Action, true, false)

function XHomeCharPlayAlphaAnim:OnEnter()
    self.AgentProxy:PlayAlphaAnim(self.Fields["Alpha"], self.Fields["Time"], function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end)
end

local XHomeCharDestroy = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharDestroy", CsBehaviorNodeType.Action, true, false)

function XHomeCharDestroy:OnEnter()
    self.AgentProxy:Destroy()
end