-- ==============================--
-- 表相关扩展
-- ==============================--
local table = table
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

table.clear = function(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

