local XGuildDormSetCameraByFurnitureGameObjectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormSetCameraByFurnitureGameObject", CsBehaviorNodeType.Action, true, false)

function XGuildDormSetCameraByFurnitureGameObjectNode:OnAwake()
    if self.Fields == nil or self.Fields["FurnitureId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.FurnitureId = self.Fields["FurnitureId"]
    self.ObjectName = self.Fields["ObjectName"]
    self.Disatance = self.Fields["Disatance"]
end

function XGuildDormSetCameraByFurnitureGameObjectNode:OnEnter()
    self.AgentProxy:SetCameraByFurnitureGameObjectNode(self.FurnitureId, self.ObjectName, self.Disatance)
    self.Node.Status = CsNodeStatus.SUCCESS
end