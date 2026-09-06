--- XUiNode 列表容器：管理「模板节点 + 克隆列表项」的创建、复用与显隐，替代
--- XUiHelper.RefreshCustomizedList（其注释已明确「不能兼容 XUiNode 类型子节点」）。
---
--- 解决三件事：
---   1. **模板恒 inactive**：RefreshCustomizedList 会把模板自身当第 1 个显示项启用，模板一旦启用，
---      其身上的 XUiEffectLayer 便执行 Init/ProcessSortingOrder 将 sortingOrder 抬高一层；此后再以
---      该模板为源 Instantiate，克隆体的 XUiEffectLayer 会把「已抬高值」当作原始基准重新快照并再抬
---      一层，导致特效渲染层级二次叠加。本容器的模板只作克隆源、永不参与显示，克隆源恒干净。
---   2. **内部直接持 XUiNode 实例**：替代调用方各自维护 `_XxxGridDict[go]` 手工缓存的样板代码。
---   3. **显隐走 Open/Close**：而非裸 SetActiveEx，使 _IsNodeShow 语义正确，规避
---      「Open 态节点挂 inactive 祖先」的框架铁律（re-enable 时 EnableChildNodes 级联报错）。
---
--- **复用策略：位置绑定**（对齐框架既有 XTool.UpdateDynamicItem）。
--- 第 i 个实例自创建起固定服务于第 i 个显示位，多余项只 Close、不移位、不跨位复用。
--- 因实例与位置永久绑定，hierarchy 顺序天然等于显示序，无需逐项 SetSiblingIndex 校正。
--- 若业务把节点 SetParent 移走（如拖拽托管到高层 DragRoot），Refresh 时自动归位到本容器并复位序号。
--- 同一列表的项同构、同模板、同父节点，位置绑定相较无序复用无任何损失，却省去排序开销。
---
--- 用法：
--- ```lua
--- -- OnStart 建容器（模板节点会被自动置为 inactive）
--- self._SlotList = XUiNodeList.New(self.GridSlot, self.PanelSlotList.transform, XUiGridShopCardSlot, self)
--- -- 刷新列表（多余项自动 Close，不足项自动创建）
--- self._SlotList:Refresh(count, function(index, node)
---     node:Refresh(dataList[index])
--- end)
--- -- 容器隐藏前全部关闭
--- self._SlotList:CloseAll()
--- ```
---@class XUiNodeList
---@field private _Template UnityEngine.Component 模板节点（恒 inactive，仅作克隆源）
---@field private _Container UnityEngine.Transform 克隆挂载父节点
---@field private _NodeCls any XUiNode 派生类
---@field private _Parent XLuaUi|XUiNode 节点构造的 parent
---@field private _CtorArgs table 透传给 nodeCls.New 的附加构造参数（table.pack 结果）
---@field private _Nodes XUiNode[] 全部已创建节点，下标 = 固定显示位（1-based）
---@field private _ActiveCount number 当前显示数量（_Nodes 中前 _ActiveCount 个为显示态）
---@field private _OnNodeClose fun(node:XUiNode)|nil 节点关闭时的业务扩展回调
local XUiNodeList = XClass(nil, "XUiNodeList")

--- 构造。模板节点在此被置为 inactive，此后仅作克隆源，不再参与显示。
---@param template UnityEngine.Component 模板节点（通常为容器下的 GridXxx）
---@param container UnityEngine.Transform 克隆挂载父节点（不可为空）
---@param nodeCls any XUiNode 派生类（克隆后以 nodeCls.New(go, parent, ...) 实例化）
---@param parent XLuaUi|XUiNode 节点构造的 parent 参数（XUiNode 父子绑定用，不可为空）
---@param ... any 透传给 nodeCls.New 的附加构造参数（对应 XUiNode:Ctor(ui, parent, ...)）
function XUiNodeList:Ctor(template, container, nodeCls, parent, ...)
    if XTool.UObjIsNil(template) then
        XLog.Error("[XUiNodeList] Ctor: template 为空，无法创建")
        return
    end
    if XTool.UObjIsNil(container) then
        XLog.Error("[XUiNodeList] Ctor: container 为空，无法创建")
        return
    end
    if not nodeCls then
        XLog.Error("[XUiNodeList] Ctor: nodeCls 为空，无法创建")
        return
    end
    if not parent then
        -- parent 决定 XUiNode 的父子绑定与生命周期级联，缺失会导致节点游离于框架管理之外
        XLog.Error("[XUiNodeList] Ctor: parent 为空，无法创建")
        return
    end

    -- 铁律：模板恒 inactive，永不参与显示——保证克隆源的特效层级值始终是 prefab 原始值，
    -- 不会被 XUiEffectLayer 抬高后再被克隆继承（二次叠层根因）。
    template.gameObject:SetActiveEx(false)

    self._Template = template
    self._Container = container
    self._NodeCls = nodeCls
    self._Parent = parent
    self._CtorArgs = table.pack(...)
    self._Nodes = {}
    self._ActiveCount = 0
end

--- 设置节点关闭扩展回调（自上而下注入）：节点 Close 后调用，供业务按需处理。
--- 典型用途：SetParent 到缓存根（避免留在原容器下被自定义 Layout 统计）、清业务缓存字段等。
--- 移走的节点无需业务手动移回：Refresh 显示时会自动归位到本容器并复位序号。
---@param cb fun(node:XUiNode)|nil
function XUiNodeList:SetOnNodeClose(cb)
    self._OnNodeClose = cb
end

--- 刷新列表到指定数量（替代 XUiHelper.RefreshCustomizedList）。
--- 不足项按需创建（克隆恒干净的模板），多余项 Close，随后前 count 项归位 + Open + 回调刷新。
---@param count number 目标显示数量（0 = 全部关闭）
---@param onRefresh fun(index:number, node:XUiNode)|nil 每项刷新回调，index 为 1-based 显示序
function XUiNodeList:Refresh(count, onRefresh)
    if not self._Nodes then
        return
    end
    count = count or 0

    -- 关闭多余项（保留实例在 _Nodes 原位，下次复用同一实例，保证位置绑定不变）
    for i = count + 1, #self._Nodes do
        self:_Close(self._Nodes[i])
    end

    -- 显示前 count 项，不足则按需创建
    for i = 1, count do
        local node = self._Nodes[i]
        if not node then
            node = self:_CreateNode()
            self._Nodes[i] = node
        end
        -- 父节点归位：业务可能因拖拽托管等把节点 SetParent 到别处（如高层 DragRoot），
        -- 位置绑定策略要求节点常驻本容器，否则「hierarchy 顺序 = 显示序」的前提被破坏。
        -- 已在容器下时跳过，避免无谓的 SetParent 触发 Layout 重建。
        if node.Transform.parent ~= self._Container then
            node.Transform:SetParent(self._Container, false)
            node.Transform:SetSiblingIndex(i - 1)
        end
        node:Open()
        if onRefresh then
            onRefresh(i, node)
        end
    end

    self._ActiveCount = count
end

--- 创建一个新节点：克隆模板 + 实例化 XUiNode 派生类。
--- 克隆 append 到 container 末尾，与其固定显示位一致（位置绑定的前提）。
---@return XUiNode
function XUiNodeList:_CreateNode()
    local go = XUiHelper.Instantiate(self._Template, self._Container)
    local args = self._CtorArgs
    return self._NodeCls.New(go, self._Parent, table.unpack(args, 1, args.n))
end

--- 关闭单个节点：走完整 XUiNode 生命周期 + 业务扩展回调。
---@param node XUiNode
function XUiNodeList:_Close(node)
    if not node then
        return
    end
    -- Close 自带 _IsNodeShow 幂等守卫，重复调无副作用
    node:Close()
    if self._OnNodeClose then
        self._OnNodeClose(node)
    end
end

--- 全部关闭（容器隐藏 / 面板 Close 前调用）。
--- 复用 Refresh 的关闭路径，避免 Open 态节点挂 inactive 祖先。
function XUiNodeList:CloseAll()
    self:Refresh(0)
end

--- 取指定显示序的在用节点（超出当前显示数量返回 nil）。
---@param index number 1-based 显示序
---@return XUiNode|nil
function XUiNodeList:GetActive(index)
    if not self._Nodes or not index or index < 1 or index > self._ActiveCount then
        return nil
    end
    return self._Nodes[index]
end

--- 当前显示中的节点数量。
---@return number
function XUiNodeList:GetActiveCount()
    return self._ActiveCount or 0
end

--- 遍历当前显示中的节点（顺序 = 显示序）。
---@param func fun(index:number, node:XUiNode)
function XUiNodeList:ForEachActive(func)
    if not func or not self._Nodes then
        return
    end
    for i = 1, self._ActiveCount do
        local node = self._Nodes[i]
        if node then
            func(i, node)
        end
    end
end

return XUiNodeList
