local XGuildDormOpenInstrumentUiByFurnitureIdNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormOpenInstrumentUiByFurnitureId", CsBehaviorNodeType.Action, true, false)

function XGuildDormOpenInstrumentUiByFurnitureIdNode:OnAwake()
    if self.Fields == nil or self.Fields["FurnitureId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.FurnitureId = self.Fields["FurnitureId"]
end

function XGuildDormOpenInstrumentUiByFurnitureIdNode:OnEnter()
    self.AgentProxy:OpenMusicUi(self.FurnitureId)
    self.Node.Status = CsNodeStatus.SUCCESS
end