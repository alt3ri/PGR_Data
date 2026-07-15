XRpc = XRpc or {}

------- 方便调试协议的打印 ------
local IsPrintLuaRpc = false
XRpc.IgnoreRpcNames = { ["HeartbeatRequest"] = true, ["HeartbeatResponse"] = true, ["KcpHeartbeatRequest"] = true, ["KcpHeartbeatResponse"] = true
    , ["NotifyGuildDormSyncEntities"] = true, ["GuildDormHeartbeatRequest"] = true }
XRpc.DEBUG_TYPE = {
    Send = "Send",
    Send_Call = "Send_Call",
    Recv = "Recv",
    Recv_Call = "Recv_Call",
}
XRpc.DEBUG_TYPE_COLOR = {
    Send = "#5bf54f",
    Send_Call = "#5bf54f",
    Recv = "#42a8fa",
    Recv_Call = "#42a8fa",
}
-- 浅色主题用的字体颜色
-- XRpc.DEBUG_TYPE_COLOR = {
--     Send = "green",
--     Send_Call = "green",
--     Recv = "blue",
--     Recv_Call = "blue",
-- }
XRpc.DebugKeyWords = {"GuildBoss"} -- 【关键协议】

function XRpc.CheckLuaNetLogEnable()
    IsPrintLuaRpc = XMain.IsEditorDebug and XSaveTool.GetData(XPrefs.LuaNetLog)
    return IsPrintLuaRpc
end

function XRpc.SetLuaNetLogEnable(value)
    IsPrintLuaRpc = value
    XSaveTool.SaveData(XPrefs.LuaNetLog, IsPrintLuaRpc)
end

function XRpc.DebugPrint(debugType, rpcName, request)
    if not IsPrintLuaRpc or XRpc.IgnoreRpcNames[rpcName] then
        return
    end
    local color = XRpc.DEBUG_TYPE_COLOR[debugType]
    if XRpc.DebugKeyWords then
        for i, keyWord in ipairs(XRpc.DebugKeyWords) do
            if (string.find(rpcName, keyWord)) then
                rpcName = "<color=red>" .. rpcName .. "</color>" -- 【关键协议】显示为红色  可本地自定义
                break
            end
        end
    end
    XLog.Debug("<color=" .. color .. "> " .. debugType .. ": " .. rpcName .. ", content: </color>" .. XLog.Dump(request))
end
-------------------------------

local handlers = {}
-- 与 C# GM「实用功能/Lua重载监控」开关对齐：仅当 Debug 包且用户显式开启 Lua 热重载监控时为 true。
-- 其他场景（外网 Release / Debug 包未开启监控）一律严格检测重复注册。
local IsHotReloadOpen = CS.XApplication.Debug and CS.UnityEngine.PlayerPrefs.GetInt("LuaHotReload") ~= 0

function XRpc.RemoveRpc(name)
    handlers[name] = nil
end

-- 一键重登场景使用：大量 Agency 用裸 `XRpc.X = handler` 注册（绕过 AddRpc/_RpcNameDict）。
-- 重登重建 agency 时 InitRpc 会再次走 __newindex 触发重复检测；此时应允许新实例的 handler 覆盖。
-- 仅 _HotReloadAll 闭合的临时窗口期使用，外部业务不要碰。
local IsSuppressDuplicateCheck = false
function XRpc.SetSuppressDuplicateCheck(value)
    IsSuppressDuplicateCheck = value and true or false
end

function XRpc.Do(name, content)
    local handler = handlers[name]
    if handler == nil then
        XLog.Error("XRpc.Do 函数错误, 没有定义相应的接收服务端数据的函数, 函数名是: " .. name)
        return
    end

    local request, error = XMessagePack.Decode(content)
    if request == nil then
        XLog.Error("XRpc.Do 函数(" .. name ..")错误, 服务端返回的数据解码错误, 错误原因: " .. error)
        return
    end

    XRpc.DebugPrint(XRpc.DEBUG_TYPE.Recv, name, request)
    handler(request)
end

setmetatable(XRpc, {
    __newindex = function(_, name, handler)
        if type(name) ~= "string" then
            XLog.Error("XRpc.register 函数错误, 参数name必须是string类型, type: " .. type(name))
            return
        end

        if type(handler) ~= "function" then
            XLog.Error("XRpc.register 函数错误, 注册的接收服务端数据的函数的值必须是函数类型, type: " .. type(handler))
            return
        end

        if handlers[name] then
            if IsSuppressDuplicateCheck then
                -- 一键重登窗口：agency 实例重建，新 handler 必须覆盖旧 handler（不报错）
            elseif IsHotReloadOpen then
                -- Editor / 开发包且 GM 开了 Lua 重载监控：允许覆盖以兼容热重载，但仍以 Error 暴露重复注册，便于与 Release 行为对齐
                XLog.Error("【Rpc HotReload】XRpc.register 检测到重复注册, 名字是: " .. name)
            else
                XLog.Error("XRpc.register 函数错误, 存在相同名字的接收服务端数据的函数, 名字是: " .. name)
                return
            end
        end
        handlers[name] = handler
    end,
})

XRpc.TestRequest = function(request)
    XLog.Warning(request);
end