---@class XHomeCharTurnToFurnitureStayPos : XLuaBehaviorNode 转向家具停留交互点
---@field IsSlerp boolean 是否使用插值
---@field IsSetPosition boolean 是否设置位置
---@deprecated 转向家具的StayPos点
local XHomeCharTurnToFurnitureStayPos = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharTurnToFurnitureStayPos", CsBehaviorNodeType.Action, true, false)

function XHomeCharTurnToFurnitureStayPos:OnEnter()
    self.AgentProxy:TurnToFurnitureStayPos(function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end, self.Fields["IsSlerp"], self.Fields["IsSetPosition"])
end
