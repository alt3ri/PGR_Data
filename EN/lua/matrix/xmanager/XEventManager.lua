XEventManager = XEventManager or {}

---@type XEventDispatcher
local Dispatcher = require("XCommon/XEventDispatcher").New(nil)

function XEventManager.AddEventListener(eventId, func, obj)
    Dispatcher:AddEventListener(eventId, func, obj)
end

function XEventManager.RemoveEventListener(eventId, func, obj)
    Dispatcher:RemoveEventListener(eventId, func, obj)
end

function XEventManager.DispatchEvent(eventId, ...)
    XUIEventBind.DispatchEvent(eventId, ...)
    Dispatcher:DispatchEvent(eventId, ...)
end

------ 添加节点的绑定 --------
local NodeEventBindRecord = {}

function XEventManager.BindEvent(node, eventId, func, obj)
    if not NodeEventBindRecord[node] then
        NodeEventBindRecord[node] = {}
    end
    local checkExist
    if node.Exist then
        checkExist = function() return node:Exist() end
    else
        local gameObject = node.GameObject or node.gameObject or node.Transform or node.transform
        if gameObject and gameObject.Exist then
            checkExist = function() return gameObject:Exist() end
        end
    end
    local handler
    if checkExist then
        local newFunc = function(...)
            if not checkExist() then
                XEventManager.UnBindEvent(node)
            else
                if obj then
                    func(obj, ...)
                else
                    func(...)
                end
            end
        end
        XEventManager.AddEventListener(eventId, newFunc)
        handler = {eventId, newFunc} 
    else
        XEventManager.AddEventListener(eventId, func, obj)
        handler = {eventId, func, obj} 
    end    
    table.insert(NodeEventBindRecord[node], handler)
    return handler
end

function XEventManager.UnBindEvent(node)
    if NodeEventBindRecord[node] then
        for _, v in ipairs(NodeEventBindRecord[node]) do
            XEventManager.RemoveEventListener(table.unpack(v))
        end
        NodeEventBindRecord[node] = nil
    end
end

local __Private = {}
__Private.__Clear__ = function ()
    if XMain.IsWindowsEditor then
        XLog.Debug("移除所有lua事件")
    end
    NodeEventBindRecord = {}
    Dispatcher:Clear()
end

return __Private
