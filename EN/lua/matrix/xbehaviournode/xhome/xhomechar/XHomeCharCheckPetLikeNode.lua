---@class XHomeCharCheckPetLikeNode : XLuaBehaviorNode
---@field AgentProxy XHomeCharAgent 
local XHomeCharCheckPetLikeNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharCheckPetLikeNode", CsBehaviorNodeType.Condition, true, false)

function XHomeCharCheckPetLikeNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["PetId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.PetId = self.Fields["PetId"]
end

function XHomeCharCheckPetLikeNode:OnEnter()
    if  self.AgentProxy:CheckPetLike(self.PetId) then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end
