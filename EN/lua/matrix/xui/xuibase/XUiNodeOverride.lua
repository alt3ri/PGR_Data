

---@type XUiNode
local XUiNode = XClassPartial("XUiNode")

--- 节点打开时执行一次
---@param ... any 打开界面传参
--------------------------
function XUiNode:OnStart()
end

function XUiNode:OnEnable()
end

function XUiNode:OnDisable()
end

function XUiNode:OnDestroy()
end

--- 跟随父界面销毁时一并调用，在父界面销毁之后调用
--------------------------
function XUiNode:OnRelease()
end

--- 界面显隐状态修改时调用，在OnEnable与OnDisable之前调用
---@param val boolean 是否显示
--------------------------
function XUiNode:OnSetDisplay(val)
end

--- 返回事件列表，注册在Lua的事件管理器
---@return string[]
--------------------------
function XUiNode:OnGetLuaEvents()
end

--- 响应通过OnGetLuaEvents注册的事件
---@param evt string 事件名
---@param ... any 事件传参
--------------------------
function XUiNode:OnNotify(evt, ...)
end

return XUiNode