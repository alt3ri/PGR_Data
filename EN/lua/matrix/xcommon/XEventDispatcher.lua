---@class XEventDispatcher 事件管理基类
local XEventDispatcher = XClass(nil, "XEventDispatcher")

local IsUnityEditor = XMain.IsWindowsEditor

function XEventDispatcher:Ctor(adapter)
    self._ListenersMap = {}
    self._DelayRemoveMap = {}
    self._DelayAddMap = {}
    self._RunningRefCnt = {}
    self._CallBackAdapter = adapter
end

function XEventDispatcher:Clear()
    self._ListenersMap = {}
    self._DelayRemoveMap = {}
    self._DelayAddMap = {}
    self._RunningRefCnt = {}
end

function XEventDispatcher:_CheckInDelayRemoveMap(eventId, func, caller)
    local eventMap = self._DelayRemoveMap[eventId]
    if not eventMap then
        return false
    end
    local funcMap = eventMap[func]
    if not funcMap then
        return false
    end
    if caller then
        return funcMap[caller] ~= nil or funcMap[func] ~= nil
    end
    return funcMap[func] ~= nil
end

function XEventDispatcher:_TrySync()
    if next(self._DelayAddMap) then
        for eventId, funcDict in pairs(self._DelayAddMap) do
            if self._RunningRefCnt[eventId] and self._RunningRefCnt[eventId] > 0 then
                goto continue1
            end
            for func, callerDict in pairs(funcDict) do
                for key, _ in pairs(callerDict) do
                    if key == func then
                        self:AddEventListener(eventId, func)
                    else
                        self:AddEventListener(eventId, func, key)
                    end
                end
            end
            self._DelayAddMap[eventId] = nil

            ::continue1::
        end
    end

    if next(self._DelayRemoveMap) then
        for eventId, funcDict in pairs(self._DelayRemoveMap) do
            if self._RunningRefCnt[eventId] and self._RunningRefCnt[eventId] > 0 then
                goto continue2
            end
            for func, callerDict in pairs(funcDict) do
                for key, _ in pairs(callerDict) do
                    if key == func then
                        self:RemoveEventListener(eventId, func)
                    else
                        self:RemoveEventListener(eventId, func, key)
                    end
                end
            end
            self._DelayRemoveMap[eventId] = nil

            ::continue2::
        end
    end
end

---添加事件回调，注意同一个（函数地址相同）事件回调不能既带caller又不带caller参数注册两次
---@param eventId any
---@param func fun 事件回调
---@param caller any func的执行者
function XEventDispatcher:AddEventListener(eventId, func, caller)
    if (self._RunningRefCnt[eventId] or 0) > 0 then
        local key = caller or func
        if self._DelayRemoveMap[eventId] and self._DelayRemoveMap[eventId][func]
                and self._DelayRemoveMap[eventId][func][key] then
            self._DelayRemoveMap[eventId][func][key] = nil
            return
        end

        local eventMap = self._ListenersMap[eventId]
        local funcEntry = eventMap and eventMap[func]
        local alreadyExists
        if caller then
            alreadyExists = type(funcEntry) == "table" and funcEntry[caller]
        else
            alreadyExists = funcEntry == func
        end
        if not alreadyExists then
            self._DelayAddMap[eventId] = self._DelayAddMap[eventId] or {}
            self._DelayAddMap[eventId][func] = self._DelayAddMap[eventId][func] or {}
            self._DelayAddMap[eventId][func][key] = true
        end
        return
    end

    local listenerList = self._ListenersMap[eventId]
    if not listenerList then
        listenerList = {}
    end

    if caller then
        local funcList = listenerList[func]
        if IsUnityEditor and funcList and type(funcList) == "function" then
            XLog.Error("添加事件失败，已经对同一个函数添加了不带caller的行为")
            return
        end
        if not funcList then
            funcList = {}
        end
        funcList[caller] = caller
        listenerList[func] = funcList
    else
        if IsUnityEditor and listenerList[func] and type(listenerList[func]) == "table" then
            XLog.Error("添加事件失败，已经对同一个函数添加了带caller的行为")
            return
        end
        listenerList[func] = func
    end

    self._ListenersMap[eventId] = listenerList
end

function XEventDispatcher:RemoveEventListener(eventId, func, caller)
    if  (self._RunningRefCnt[eventId] or 0) > 0 then
        local key = caller or func
        if self._DelayAddMap[eventId] and self._DelayAddMap[eventId][func]
                and self._DelayAddMap[eventId][func][key] then
            self._DelayAddMap[eventId][func][key] = nil
            return
        end
        self._DelayRemoveMap[eventId] = self._DelayRemoveMap[eventId] or {}
        self._DelayRemoveMap[eventId][func] = self._DelayRemoveMap[eventId][func] or {}
        self._DelayRemoveMap[eventId][func][key] = true
        return
    end

    local listenerList = self._ListenersMap[eventId]
    if not listenerList then
        return
    end

    if caller then
        local funcList = listenerList[func]
        if not funcList then
            return
        end
        funcList[caller] = nil
        if XTool.IsTableEmpty(funcList) then
            listenerList[func] = nil
        end
    else
        listenerList[func] = nil
    end

    if XTool.IsTableEmpty(listenerList) then
        self._ListenersMap[eventId] = nil
    end
end

function XEventDispatcher:DispatchEvent(eventId, ...)
    local listenerList = self._ListenersMap[eventId]
    if not listenerList then
        return
    end
    self._RunningRefCnt[eventId] = (self._RunningRefCnt[eventId] or 0) + 1
    local adapter = self._CallBackAdapter
    for f, listener in pairs(listenerList) do
        if type(listener) == "table" then
            for _, caller in pairs(listener) do
                if not self:_CheckInDelayRemoveMap(eventId, f, caller) then
                    if adapter then
                        adapter(f, caller, eventId, ...)
                    else
                        f(caller, ...)
                    end
                end
            end
        else
            if not self:_CheckInDelayRemoveMap(eventId, f) then
                if adapter then
                    adapter(f, nil, eventId, ...)
                else
                    f(...)
                end
            end
        end
    end
    local depth = self._RunningRefCnt[eventId] - 1
    if depth <= 0 then
        self._RunningRefCnt[eventId] = nil
    else
        self._RunningRefCnt[eventId] = depth
    end
    self:_TrySync()
end

return XEventDispatcher
