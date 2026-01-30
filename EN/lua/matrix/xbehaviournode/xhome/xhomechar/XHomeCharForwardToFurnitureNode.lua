---@class XHomeCharForwardToFurnitureNode : XLuaBehaviorNode 转向家具
---@field Direction number 方向 1 面向，-1 背向
---@deprecated 公会宿舍实现逻辑是获取家具的InteractPos的旋转角度，然后设置角色的朝向，如何Direction是1，那么角色朝向家具，如果Direction是-1，那么角色背向家具
local XHomeCharForwardToFurnitureNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharForwardToFurniture", CsBehaviorNodeType.Action, true, false)

function XHomeCharForwardToFurnitureNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Direction"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.Direction = self.Fields["Direction"]
end

function XHomeCharForwardToFurnitureNode:OnEnter()
    if self.AgentProxy:SetForwardToFurniture(self.Direction) then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end