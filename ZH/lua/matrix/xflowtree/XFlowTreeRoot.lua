---@class XFlowTreeRoot : XFlowTreeCompositeBase 行为树根节点管理器
---@field private _CurrentNode XFlowTreeNode 当前执行到的节点
---@field private _IsInited boolean 是否已初始化
local XFlowTreeRoot = XClass(require("XFlowTree/Base/XFlowTreeCompositeBase"), "XFlowTreeRoot")

function XFlowTreeRoot:Ctor()
    self._CurrentNode = nil
    self._IsInited = false
end

--region 使用者外部使用方法

-- 添加子节点（Root 只持有一个子节点）
function XFlowTreeRoot:AddChild(node)
    if not self:InternalAssertNotStarted("AddChild") then return self end
    if self._Children[1] then
        XLog.Error("[XFlowTreeRoot] AddChild 失败：已存在子节点")
        return self
    end
    self.Super.AddChild(self, node)
    self._IsInited = false
    return self
end

-- 启动行为树
--@param context any 流程上下文
function XFlowTreeRoot:StartFlowTree(context)
    if self:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
        XLog.Error("[XFlowTreeRoot] StartFlowTree 失败：行为树正在执行中")
        return
    end

    self:_InitTree()
    self._CurrentNode = self
    self:OnStart(context)
end

-- 停止行为树（打断）
function XFlowTreeRoot:StopFlowTree()
    if self:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
        self:OnInterrupt()
    end
end

-- 销毁行为树
function XFlowTreeRoot:DestroyFlowTree()
    if self:InternalGetStatus() == self.XFlowTreeEnum.Status.Running then
        self:OnInterrupt()
    end
    self._IsInited = false
    self._CurrentNode = nil
    self:OnDestroy()
end

--endregion

--region 行为树内部使用方法

function XFlowTreeRoot:OnDestroy()
    self._IsInited = false
    self._CurrentNode = nil
    self.Super.OnDestroy(self)
end

function XFlowTreeRoot:GetNodeType()
    return self.XFlowTreeEnum.NodeType.Root
end

-- 记录当前执行到的节点。
function XFlowTreeRoot:InternalRecordCurrentNode(node)
    self._CurrentNode = node
end

-- 初始化：为所有节点绑定 TreeRoot
function XFlowTreeRoot:_InitTree()
    if self._IsInited then return end
    self:_BindTreeRoot(self)
    self._IsInited = true
end

function XFlowTreeRoot:_BindTreeRoot(node)
    node:InternalSetTreeRoot(self)
    local nodeType = node:GetNodeType()
    local hasChildren = nodeType == self.XFlowTreeEnum.NodeType.Composite or nodeType == self.XFlowTreeEnum.NodeType.Root
    if hasChildren then
        local children = node:GetChildren()
        if children then
            for i = 1, #children do
                self:_BindTreeRoot(children[i])
            end
        end
    end
end

-- Root 自身作为根节点，OnStart 直接驱动第一个子节点
function XFlowTreeRoot:OnStart(context)
    self.Super.OnStart(self, context)
    if #self._Children > 0 then
        self._Children[1]:OnStart(context)
    else
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
    end
end

function XFlowTreeRoot:OnChildDone(child)
    self:OnDone(child:InternalGetResult())
end

--endregion

return XFlowTreeRoot
