local XHomeCharCheckIsCanDestroy = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharCheckIsCanDestroy", CsBehaviorNodeType.Condition, true, false)

function XHomeCharCheckIsCanDestroy:OnEnter()
    self.EntityId = self.AgentProxy:GetEntityId()
end

function XHomeCharCheckIsCanDestroy:OnGetEvents()
    return { XEventId.EVENT_DORM_ROLE_CAN_DESTROY }
end

function XHomeCharCheckIsCanDestroy:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_DORM_ROLE_CAN_DESTROY and args[1] == self.EntityId  then
        
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end