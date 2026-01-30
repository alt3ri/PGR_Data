local XHomeCharPlayTalkSystem = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharPlayTalkSystem", CsBehaviorNodeType.Action, true, false)

function XHomeCharPlayTalkSystem:OnEnter()
    self.AgentProxy:PlayTalkSystem(self.Fields["TalkId"])
    self.Node.Status = CsNodeStatus.SUCCESS
end