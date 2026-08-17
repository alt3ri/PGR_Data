-- ==============================--
-- 表相关扩展
-- ==============================--
local TABLE_STR = "table"

local table = table
local assert = assert
local mt = {
    __newindex = function(t, k, v)
        XLog.Error("Attempt to modify a read-only empty table")
    end,

    __index = function(t, k)
        return nil -- 显式返回nil，保持空表特性
    end,

    __pairs = function(t)
        return function()
            return nil
        end -- 空迭代器
    end,

    __ipairs = function(t)
        return function()
            return nil
        end -- 空迭代器
    end,

    __len = function(t)
        return 0 -- 长度为0
    end,

    __metatable = "readonly empty table"
}
table.empty = setmetatable({}, mt)

--- 清空表中所有键值（不创建新表，原表复用）
---@param t table
--------------------------
function table.clear(t)
    assert(type(t) == TABLE_STR)
    for k in pairs(t) do
        t[k] = nil
    end
end

--- 返回表的所有键组成的数组
---@generic K
---@param t table<K, any>
---@return K[]
function table.keys(t)
    assert(type(t) == TABLE_STR)
    local r, i = {}, 0
    for k in pairs(t) do i = i + 1; r[i] = k end
    return r
end

--- 返回表的所有值组成的数组
---@generic V
---@param t table<any, V>
---@return V[]
function table.values(t)
    assert(type(t) == TABLE_STR)
    local r, i = {}, 0
    for _, v in pairs(t) do i = i + 1; r[i] = v end
    return r
end

--- 原地反转数组（不产生新数组）
---@generic T
---@param t T[]
---@return T[]
function table.reverse(t)
    assert(type(t) == TABLE_STR)
    local len = #t
    local mid = math.floor(len / 2)
    for i = 1, mid do
        t[i], t[len - i + 1] = t[len - i + 1], t[i]
    end
    return t
end

--- 数组截取
---@generic T
---@param t table
---@param start number
---@param count number
---@return T[]
function table.range(t, start, count)
    assert(type(t) == TABLE_STR)
    local ret = {}
    for i = start, start + count - 1 do
        ret[#ret + 1] = t[i]
    end
    return ret
end

