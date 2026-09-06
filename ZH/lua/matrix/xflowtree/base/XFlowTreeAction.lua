---@class XFlowTreeAction : XFlowTreeNode 动作节点基类（叶子节点）
-- 本身继承 XFlowTreeNode，不添加额外逻辑，纯语义标记
local XFlowTreeAction = XClass(require("XFlowTree/Base/XFlowTreeNode"), "XFlowTreeAction")

function XFlowTreeAction:GetNodeType()
    return self.XFlowTreeEnum.NodeType.Action
end

return XFlowTreeAction
