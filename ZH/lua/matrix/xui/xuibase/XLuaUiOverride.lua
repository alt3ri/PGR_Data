
---@type XLuaUi
local XLuaUi = XClassPartial("XLuaUi")

--- UI打开时执行一次，最先执行
--------------------------
function XLuaUi:OnAwake()
end

--- UI打开时执行一次，在OnAwake之后执行
---@param ... any 打开界面传参
--------------------------
function XLuaUi:OnStart(...)
end

--- UI显示时执行，在OnStart之后执行
--------------------------
function XLuaUi:OnEnable()
end

--- UI隐藏时执行
--------------------------
function XLuaUi:OnDisable()
end

--- UI隐藏时执行
--------------------------
function XLuaUi:OnDestroy()
end

--- UI销毁但是不关闭时执行 eg:进入战斗时，界面不会关闭但是会销毁
--------------------------
function XLuaUi:OnReleaseInst()
end

--- Ui销毁但是不关闭之后重新打开时调用
---@param ... any 恢复界面传参
function XLuaUi:OnResume(...)
end

--- 界面销毁时调用
--------------------------
function XLuaUi:OnRelease()
end

--- 响应通过OnGetEvents or OnGetLuaEvents注册的事件
---@param evt string 事件名
---@param ... any 事件传参
--------------------------
function XLuaUi:OnNotify(evt, ...)
end

--- 返回事件列表，注册在C#的事件管理器
---@return string[]
--------------------------
function XLuaUi:OnGetEvents()
end

--- 返回事件列表，注册在Lua的事件管理器
---@return string[]
--------------------------
function XLuaUi:OnGetLuaEvents()
end

return XLuaUi