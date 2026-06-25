XUIEventBind = XUIEventBind or {}

local function CallbackAdapter(func, caller, eventId, ...)
    if caller then
        func(caller, eventId, ...)
    else
        func(eventId, ...)
    end
end

---@type XEventDispatcher
local Dispatcher = require("XCommon/XEventDispatcher").New(CallbackAdapter)

function XUIEventBind.AddEventListener(eventId, func, obj)
    Dispatcher:AddEventListener(eventId, func, obj)
end

function XUIEventBind.RemoveEventListener(eventId, func, obj)
    Dispatcher:RemoveEventListener(eventId, func, obj)
end

function XUIEventBind.RemoveAllListener()
    Dispatcher:Clear()
end

function XUIEventBind.DispatchEvent(eventId, ...)
    Dispatcher:DispatchEvent(eventId, ...)
end