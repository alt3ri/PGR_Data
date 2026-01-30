local loader = {}

local BinaryTable = require("Binary/BinaryTable")

local AllTables = {}

local EmptyTable = {}

local function stateless_iter(tbl, key)
    local nk, nv = next(tbl, key)
    return nk, nv
end

--============= 内部读表函数 ============
local function ReadTable(path, identifier)
    if not identifier then
        XLog.Error(string.format("%s,identifier is null", path))
        return
    end

    local bin = BinaryTable.ReadHandle(path)
    if not bin then
        return EmptyTable
    end

    -- if bin.primarykey ~= identifier then
    --     XLog.Error("表格 " .. path .. " 读取Id与主键不一致，已改为强制读取模式，请按主键索引, 强制读取会带来较大性能损失")
    --     return ReadTableAll(path, identifier)
    -- end

    local tab = {}
    AllTables[path] = bin
    local meta = {}
    meta.__index = function(_, key)
        if not key then
            return nil
        end

        if not bin then
            return
        end

        local data = bin:Get(key)
        return data
    end

    meta.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    meta.__metatable = "readonly table"

    meta.__len = function(_)
        return bin:GetRowCount()
    end

    meta.__pairs = function(_)
        -- if XMain.IsDebug then
        --     XLog.Error("path: ".. path.. " 建议使用ReadAllByIntKey或ReadAllByStringKey接口，避免缓存数据，性能会降低")
        -- end

        local len = bin:GetRowCount()
        if len <= 0 then
            return stateless_iter, EmptyTable, nil
        end

        if bin and bin.cachesCount ~= len then
            bin:ReadAllContent(identifier, true)
        end

        return stateless_iter, bin.caches, nil
    end

    -- 解决next获取是nil的问题
    -- local len = bin:GetRowCount()
    -- if len ~= 0 then
    --     tab.__tableCount = len
    -- end
    tab.__tableNextFix = true

    setmetatable(tab, meta)

    return tab
end

local function ReadTableAll(path, identifier)
    local tab = BinaryTable.ReadAll(path, identifier)
    return tab
    -- ReadTable有缓存，ReadAll不保留缓存所以不用下面接口
    -- return ReadTable(path, identifier)
end

function loader.ReadAllByIntKey(path, xTable, identifier)
    return ReadTableAll(path, identifier)
end

function loader.ReadAllByStringKey(path, xTable, identifier)
    return ReadTableAll(path, identifier)
end

function loader.ReadByIntKey(path, xTable, identifier)
    local t = nil
    if not identifier then
        t = ReadTableAll(path)
    else
        t = ReadTable(path, identifier)
    end
    return t
end

function loader.ReadByStringKey(path, xTable, identifier)
    local t = nil
    if not identifier then
        t = ReadTableAll(path)
    else
        t = ReadTable(path, identifier)
    end
    return t
end

function loader.ReleaseCache()
    for _, v in pairs(AllTables) do
        v:ReleaseCache()
    end
end

function loader.ReleaseFull(path)
    local v = AllTables[path]
    if not v then
        return
    end
    v:ReleaseFull()
    AllTables[path] = nil
end


function loader.ReadArray(path, xTable, identifier)
    return nil
end

return loader;