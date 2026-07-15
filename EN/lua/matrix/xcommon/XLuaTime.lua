XLuaTime = XLuaTime or {}

-- 由 C# 每帧推送一次，业务代码字段直读，避免高频跨语言调用 CS.UnityEngine.Time
XLuaTime.deltaTime = 0
XLuaTime.time      = 0

function XLuaTime.SetFrame(deltaTime, time)
    XLuaTime.deltaTime = deltaTime
    XLuaTime.time      = time
end

-- Lua 侧主动把回调注册回 C#，规避 XLua CSharpCallLua 委托类型注册要求
CS.XLuaTime.Register(XLuaTime.SetFrame)
