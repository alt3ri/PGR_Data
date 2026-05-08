---@class XGuideHideDragPanel : XLuaBehaviorNode 隐藏拖拽界面
---@field AgentProxy XGuideAgent
local XGuideHideDragPanel = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideHideDragPanel", CsBehaviorNodeType.Action, true, false)


function XGuideHideDragPanel:OnEnter()
    self.AgentProxy:ResetDragPanel()
    self.Node.Status = CsNodeStatus.SUCCESS
end