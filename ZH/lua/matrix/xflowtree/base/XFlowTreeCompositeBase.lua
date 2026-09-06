local XFlowTreeNode = require("XFlowTree/Base/XFlowTreeNode")

---@class XFlowTreeCompositeBase : XFlowTreeNode 组合节点基类（管理子节点）
---@field private _Children XFlowTreeNode[] 子节点列表
local XFlowTreeCompositeBase = XClass(require("XFlowTree/Base/XFlowTreeNode"), "XFlowTreeCompositeBase")

function XFlowTreeCompositeBase:Ctor()
    self._Children = {}
end

function XFlowTreeCompositeBase:GetNodeType()
    return self.XFlowTreeEnum.NodeType.Composite
end

--region 使用者需要tobeoverrid 的方法

-- 子类重写：子节点完成时回调
function XFlowTreeCompositeBase:OnChildDone(child)
end

function XFlowTreeCompositeBase:GetChildren()
    return self._Children
end

function XFlowTreeCompositeBase:OnDestroy()
    for i = 1, #self._Children do
        self._Children[i]:OnDestroy()
    end
    self._Children = nil
    XFlowTreeNode.OnDestroy(self)
end

--endregion

--region 使用者外部使用方法

-- 添加子节点
function XFlowTreeCompositeBase:AddChild(node)
    if not self:InternalAssertNotStarted("AddChild") then return self end
    if node then
        table.insert(self._Children, node)
        node:InternalSetParent(self)
    end
    return self
end

--endregion

return XFlowTreeCompositeBase
