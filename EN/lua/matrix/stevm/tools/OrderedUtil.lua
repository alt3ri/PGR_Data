--- STEFramework 2.0 排序工具
---
--- 用途:确定性遍历的最小支撑——把字典 key 按全序排序后再遍历(取列表等边界处)。
---       存储用纯 table,只在需要确定性顺序的地方临时排序。
---
--- 说明:迭代期保持精简,只留排序原语。集合运算/取首等按需再加。
---
---@class OrderedUtil
local OrderedUtil = {}

-- 类型分桶序:不同类型间用固定优先级,保证混合类型 key 仍是全序。
local TYPE_RANK = {
    number  = 1,
    boolean = 2,
    string  = 3,
}
local function typeRank(v)
    return TYPE_RANK[type(v)] or 99
end

--- 全序比较器:a < b ?
--- 同类型按自然序(boolean 以 false<true),异类型按 TYPE_RANK 分桶。
---@param a any
---@param b any
---@return boolean
local function lessThan(a, b)
    local ra, rb = typeRank(a), typeRank(b)
    if ra ~= rb then
        return ra < rb
    end
    local t = type(a)
    if t == 'boolean' then
        return (a and 1 or 0) < (b and 1 or 0)
    end
    if t == 'number' or t == 'string' then
        return a < b
    end
    return tostring(a) < tostring(b)
end

OrderedUtil.LessThan = lessThan

--- 取出 t 的所有 key 并按全序排序,返回新数组(确定性)。
---@param t table
---@param ref_list table 允许外部传入table对象，作为key填充数组，以便对象复用。但table容器的空状态由外部自行保证
---@return any[] keys 升序 key 数组
function OrderedUtil.SortedKeys(t, ref_list)
    local keys = ref_list or {}
    local n = 0
    for k in pairs(t) do
        n = n + 1
        keys[n] = k
    end
    table.sort(keys, lessThan)
    return keys
end

return OrderedUtil
