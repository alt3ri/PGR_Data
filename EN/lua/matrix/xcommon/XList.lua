--- 封装的列表，追求复用性
---@class XList
local XList = XClass(nil, "XList")

-- __len 元方法：#xList 返回业务 count（非实例字段数）
---@param t XList
local function listLen(t)
    return t._Count
end

function XList:Ctor(initSize)
    if XTool.IsNumberValidEx(initSize) then
        self._List = table.create(initSize, 0)
    else
        self._List = {}
    end

    self._Count = 0
    -- 注：__ipairs 元方法在 XClass 实例上不生效（XClass 元表机制限制，ipairs(xList) 无法遍历 _List）。
    -- 遍历 XList 请用常规增量 for + GetValueByIndex：
    --   for i = 1, xList:GetCount() do local v = xList:GetValueByIndex(i) ... end
    local mt = getmetatable(self)
    mt.__len = listLen
end

function XList:GetValueByIndex(index)
    if type(index) ~= "number" then
        return
    end
    index = math.floor(index)
    if index > 0 and index <= self._Count then
        return self._List[index]
    end
end

---@param index number 不能小于0，大于当前数量默认尾插
function XList:SetValueByIndex(index, value)
    if value == nil then
        return
    end

    if type(index) ~= "number" then
        XLog.Error("XList设置数据错误，index 非法: " .. tostring(index))
        return
    end
    
    index = math.floor(index)

    if index <= 0 then
        XLog.Error("XList设置数据错误，index 非法: " .. tostring(index))
        return
    end

    if index > self._Count then
        self:Append(value)
    else
        self._List[index] = value
    end
end

---@param index number 不能小于0，大于当前数量默认尾插
function XList:Insert(index, value)
    if value == nil then
        return
    end

    if type(index) ~= "number" then
        XLog.Error("XList:Insert index 非法: " .. tostring(index))
        return
    end

    index = math.floor(index)

    if index <= 0 then
        XLog.Error("XList:Insert index 非法: " .. tostring(index))
        return
    end

    if index > self._Count then
        self:Append(value)
    else
        table.insert(self._List, index, value)
        self._Count = self._Count + 1
    end
end

function XList:Append(value)
    --- 只存有效数据
    if value ~= nil then
        self._Count = self._Count + 1
        
        self._List[self._Count] = value
    end
end

---@param index number @1-base索引
---@param return boolean 是否真的有数据并且移除了
function XList:RemoveAt(index)
    if type(index) ~= "number" then
        XLog.Error("XList:RemoveAt index 非法: " .. tostring(index))
        return false
    end

    index = math.floor(index)

    if index > 0 and index <= self._Count then
        table.remove(self._List, index)
        self._Count = self._Count - 1
        return true
    end

    XLog.Error("XList:RemoveAt index 越界: index=" .. tostring(index) .. " count=" .. tostring(self._Count))
    return false
end

---@param return boolean 是否真的有数据并且移除了
function XList:Remove(value)
    if value ~= nil then
        for i = 1, self._Count do
            if self._List[i] == value then
                table.remove(self._List, i)
                self._Count = self._Count - 1
                return true
            end
        end
    end

    return false
end

---@return boolean, number
function XList:Contains(value)
    return table.contains(self._List, value)
end

function XList:GetCount()
    return self._Count
end

--- 排序（封装 table.sort，入参为排序比较函数，nil 用默认 <）
---@param compare function|nil 排序函数(a, b) -> boolean
function XList:Sort(compare)
    table.sort(self._List, compare)
end

function XList:Clear()
    for i = self._Count, 1, -1 do
        self._List[i] = nil
    end
    
    self._Count = 0
end

return XList