---@class XFastBlackboard Class
local XFastBlackboard = XClass(nil, "XFastBlackboard")

XFastBlackboard.ESyncVarType = {
    Boolean = 0,
    Integer = 1,
    Float = 2,
    Vector2 = 3,
    Vector3 = 4
}

function XFastBlackboard:Ctor(proxy, uuid, name, domain, autoUnregister)
    ---@type XDlcCSharpFuncs
    self._proxy = proxy

    self._name = name
    self._syncDomain = domain
    self._autoUnregister = autoUnregister
    self._debugMode = false
    self._uuid = uuid

    --- @class XFastBlackboardLocalVar
    --- @field value
    --- @field type

    --- @type table<int, XFastBlackboardLocalVar>
    self._syncVarLocalVals = {}
end

function XFastBlackboard:Terminate()
    if self._autoUnregister then
        for key, val in pairs(self._syncVarLocalVals) do
            self:UnregBBSyncVar(key)
        end
        return
    end
end

--- 将同步变量键注册至黑板
--- @param key int @黑板键值
function XFastBlackboard:RegBBSyncVar(key)
    self._proxy:RegisterBBSync(self._syncDomain, self._uuid, key)
end

--- 将同步变量键从黑板取消注册
function XFastBlackboard:UnregBBSyncVar(key)
    self._proxy:UnregisterBBSync(self._syncDomain, self._uuid, key)
end

--- 初始化同步变量，如果已经存在于服务器，则更新本端值，否则将注册新黑板键并赋值
--- @param key number @ 黑板键
--- @param initValue @ 初始值
--- @param varType @ 同步变量类型
--- @return bool @ 是否已经存在于服务器
function XFastBlackboard:InitBBSyncVar(key, varType, initValue)
    if initValue == nil then
        if varType == XFastBlackboard.ESyncVarType.Boolean then
            initValue = false
        elseif varType == XFastBlackboard.ESyncVarType.Integer then
            initValue = 0
        elseif varType == XFastBlackboard.ESyncVarType.Float then
            initValue = 0
        elseif varType == XFastBlackboard.ESyncVarType.Vector2 then
            initValue = { x = 0, y = 0 }
        elseif varType == XFastBlackboard.ESyncVarType.Vector3 then
            initValue = { x = 0, y = 0, z = 0 }
        end
    end
    self._syncVarLocalVals[key] = { value = initValue, type = varType }

    local hasSyncVar, val = self:GetSyncVarInternal(key, true)

    if hasSyncVar then
        -- 已有黑板键，直接应用给本地值
        self._syncVarLocalVals[key].value = val
        self:TryLogDebug(string.format("黑板键[%d(%s)]同步至本地, 值为[%s]", key, self:BBVarTypeToString(self._syncVarLocalVals[key].type), tostring(val)))
        return true
    else
        -- 没黑板键，执行注册
        if initValue == nil then
            XLog.Error(string.format("[XFastBlackboard][%s]: 尝试使用不存在或者不支持的类型进行黑板键注册", self._name))
            return false
        end

        self:RegBBSyncVar(key)
        self:SetSyncVar(key, initValue)
        self:TryLogDebug(string.format("注册黑板键[%d(%s)], 值为[%s]", key, self:BBVarTypeToString(self._syncVarLocalVals[key].type), tostring(initValue)))
        return false
    end
end

function XFastBlackboard:GetSyncVarInternal(key, isInternal)
    local hasSyncVar = false
    local val = nil

    if self._syncVarLocalVals[key] ~= nil then
        local varType = self._syncVarLocalVals[key].type
        if varType == XFastBlackboard.ESyncVarType.Boolean then
            hasSyncVar, val = self._proxy:TryGetBBBoolean(self._syncDomain, self._uuid, key)
        elseif varType == XFastBlackboard.ESyncVarType.Integer then
            hasSyncVar, val = self._proxy:TryGetBBInt(self._syncDomain, self._uuid, key)
        elseif varType == XFastBlackboard.ESyncVarType.Float then
            hasSyncVar, val = self._proxy:TryGetBBFloat(self._syncDomain, self._uuid, key)
        elseif varType == XFastBlackboard.ESyncVarType.Vector2 then
            hasSyncVar, val = self._proxy:TryGetBBVector2(self._syncDomain, self._uuid, key)
        elseif varType == XFastBlackboard.ESyncVarType.Vector3 then
            hasSyncVar, val = self._proxy:TryGetBBVector3(self._syncDomain, self._uuid, key)
        end
    end

    if not isInternal then
        if hasSyncVar then
            self:TryLogDebug(string.format("从黑板[%d(%s)]获取值, 获取结果[成功], 值为[%s]", key, self:BBVarTypeToString(self._syncVarLocalVals[key].type), tostring(val)))
        else
            self:TryLogDebug("尝试从黑板获取值, 获取结果[失败]")
        end
    end

    return hasSyncVar, val
end

--- 从黑板获取同步变量值，返回1. 该值是否存在 2. 实际值
--- @param key int @ 黑板键
function XFastBlackboard:GetSyncVar(key)
    return self:GetSyncVarInternal(key, false)
end

--- 获取同步变量的本地值
--- @param key int @ 黑板键
function XFastBlackboard:GetSyncVarLocal(key)
    if self._syncVarLocalVals[key] == nil then
        return nil
    end
    return self._syncVarLocalVals[key].value
end

--- 设置同步变量的本地值，并同步至黑板
--- @param key int @ 黑板键
--- @param val @ 值
function XFastBlackboard:SetSyncVar(key, val)
    -- 避免不存在的情况
    if self._syncVarLocalVals[key] == nil then
        return
    end
    -- 更新本地值
    self._syncVarLocalVals[key].value = val

    -- 更新黑板值
    local varType = self._syncVarLocalVals[key].type
    if varType == XFastBlackboard.ESyncVarType.Boolean then
        self._proxy:SetBBBoolean(self._syncDomain, self._uuid, key, val)
    elseif varType == XFastBlackboard.ESyncVarType.Integer then
        self._proxy:SetBBInt(self._syncDomain, self._uuid, key, val)
    elseif varType == XFastBlackboard.ESyncVarType.Float then
        self._proxy:SetBBFloat(self._syncDomain, self._uuid, key, val)
    elseif varType == XFastBlackboard.ESyncVarType.Vector2 then
        self._proxy:SetBBVector2(self._syncDomain, self._uuid, key, val)
    elseif varType == XFastBlackboard.ESyncVarType.Vector3 then
        self._proxy:SetBBVector3(self._syncDomain, self._uuid, key, val)
    end

    self:TryLogDebug(string.format("设置本地值并同步至黑板[%d(%s)], 值为[%s]", key, self:BBVarTypeToString(self._syncVarLocalVals[key].type), tostring(val)))
end

--- 设置同步变量的本地值, 不进行同步
--- @param key int @ 黑板键
--- @param val @ 值
function XFastBlackboard:SetSyncVarLocal(key, val)
    if self._syncVarLocalVals[key] == nil then
        return
    end
    self._syncVarLocalVals[key].value = val
end

function XFastBlackboard:TryLogDebug(logText)
    if not self._debugMode then
        return
    end
    XLog.Debug(string.format("[XFastBlackboard][%s]: %s", self._name, logText))
end

function XFastBlackboard:BBVarTypeToString(varType)
    if varType == XFastBlackboard.ESyncVarType.Boolean then
        return "布尔"
    elseif varType == XFastBlackboard.ESyncVarType.Integer then
        return "整数"
    elseif varType == XFastBlackboard.ESyncVarType.Float then
        return "浮点数"
    elseif varType == XFastBlackboard.ESyncVarType.Vector2 then
        return "二维向量"
    elseif varType == XFastBlackboard.ESyncVarType.Vector3 then
        return "三维向量"
    else
        return "未知类型"
    end
end

--- 设置调试模式（开启后，会在一些同步相关节点产生Log，本地值修改可能过于频繁，所以不发Log）
function XFastBlackboard:SetDebugMode(enabled)
    self._debugMode = enabled
end

return XFastBlackboard