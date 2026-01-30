local XLevelScript4021 = XDlcScriptManager.RegLevelPresentScript(4021, "XLevel4021") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript4021:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._tempLevelSwitcherPlaceId = 1
end

function XLevelScript4021:Init() --初始化逻辑
    self._proxy:ControlSystemFunction(ESystemFunctionType.Map, { true})         --地图不能点击
    self._proxy:ControlSystemFunction(ESystemFunctionType.Task, {1}) --任务不能点击
end

---@param dt number @ delta time
function XLevelScript4021:Update(dt) --每帧更新逻辑

end

---@param eventType number
---@param eventArgs userdata
function XLevelScript4021:HandleEvent(eventType, eventArgs) --事件响应逻辑

end

function XLevelScript4021:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）
    self._proxy:ControlSystemFunction(ESystemFunctionType.Map, {false})         --地图不能点击
    self._proxy:ControlSystemFunction(ESystemFunctionType.Task, {0}) --任务不能点击
end

return XLevelScript4021 