--- 封装的字典表, 追求复用性
---@class XDictionary
local XDictionary = XClass(nil, "XDictionary")

-- __pairs 元方法：pairs(xDict) GC-free 遍历内容（XClass 实例默认元表仅 __index 无 __pairs）
-- 模块级共享函数（非每实例闭包），返回 next,_Dict,nil → 零 GC（next 是 C 函数），hash 序
---@param t XDictionary
local function dictPairs(t)
    return next, t._Dict, nil
end

-- __len 元方法：#xDict 返回业务 count（非实例字段数）
---@param t XDictionary
local function dictLen(t)
    return t._Count
end

function XDictionary:Ctor(initSize)
    if XTool.IsNumberValidEx(initSize) then
        self._Dict = table.create(0, initSize)
    else
        self._Dict = {}
    end
    
    -- _KeyList：Clear 用的复用 scratch buffer（收集 key 再 nil），非有序键列表（Add/Remove 不维护）
    self._KeyList = {}

    self._Count = 0
    local mt = getmetatable(self)
    mt.__pairs = dictPairs
    mt.__len = dictLen
end

function XDictionary:Add(key, value)
    --- 只存有效数据，且不重复存
    if value ~= nil and self._Dict[key] == nil then
        self._Dict[key] = value

        self._Count = self._Count + 1
    end
end

--- 设值（upsert）：key 存在则更新 value，不存在则新增。nil 不写入（如需删用 RemoveByKey）
---@param key any
---@param value any
function XDictionary:SetValueByKey(key, value)
    if value == nil then
        return
    end
    if self._Dict[key] == nil then
        self._Count = self._Count + 1
    end
    self._Dict[key] = value
end

---@param return boolean 是否真的有数据并且移除了
function XDictionary:RemoveByKey(key)
    if self._Dict[key] ~= nil then
        self._Dict[key] = nil
        self._Count = self._Count - 1
        
        return true
    end
    
    return false
end

function XDictionary:ContainsKey(key)
    return self._Dict[key] ~= nil
end

function XDictionary:GetValueByKey(key)
    return self._Dict[key]
end

function XDictionary:GetCount()
    return self._Count
end

function XDictionary:Clear()
    -- 第一遍收集key
    local index = 0
    
    for k, v in pairs(self._Dict) do
        index = index + 1

        self._KeyList[index] = k
    end

    -- 同时清理两个table
    for i = index, 1, -1 do
        local key = self._KeyList[i]
        
        self._KeyList[i] = nil
        self._Dict[key] = nil
    end
    
    self._Count = 0
end

return XDictionary