local XHomeFurnitureSetNameVisibleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureSetNameVisible", CsBehaviorNodeType.Action, true, false)

function XHomeFurnitureSetNameVisibleNode:OnEnter()
    XEventManager.DispatchEvent(XEventId.EVENT_HOME_SET_FURNITURE_NAME_VISIBLE, self.Fields.FurnitureId, self.Fields.Visible)
    self.Node.Status = CsNodeStatus.SUCCESS
end