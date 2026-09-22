---@class STEVM.Random 封装的随机数生成器类，用于确定性随机，封装是为了支持后面更换其他随机数（例如C#的Random类）
---@field _Seed number 固定种子
---@field _Count number 自种子起已产出的随机数个数(= 内部状态游标)
local Random = XClass(nil, 'Random')

local DEFAULT_SEED = 0x123456789abcdef0

--- 构造:用种子初始化。seed 缺省取固定常量。
---@param seed number|nil
function Random:Ctor(seed)
    if seed == nil then
        seed = DEFAULT_SEED
    end
    self._Seed = math.tointeger(seed) or math.floor(seed)
    self._Count = 0 -- 目前使用的是lua的随机数，lua随机数是全局共享的，会被其他地方使用随机数重置掉，因此需要单独维护一个计数器确保使用时是在上一次的位置上生成
    math.randomseed(self._Seed)
end

--- 推进一步并返回本步原始随机(整数)。内部计数 +1。
---@return number
function Random:NextRaw()
    self._Count = self._Count + 1
    -- math.random() 无参返回 [0,1);转成一个整数原始值供内部使用。
    return math.random(0, 0x7FFFFFFF)
end

--- 返回 [lo, hi] 闭区间整数
---@param lo number
---@param hi number
---@return number
function Random:NextInt(lo, hi)
    assert(lo <= hi, 'Random:NextInt 要求 lo <= hi,实际 lo=' .. tostring(lo) .. ' hi=' .. tostring(hi))
    self._Count = self._Count + 1
    return math.random(lo, hi)
end

--- 返回 [0, 1) 浮点。
---@return number
function Random:NextFloat()
    self._Count = self._Count + 1
    return math.random()
end

--- 原地 Fisher-Yates 洗牌(确定性,使用本 RNG 推进)。
---@generic T
---@param arr T[]
---@return T[] arr 同一数组(就地)
function Random:Shuffle(arr)
    local n = #arr
    for i = n, 2, -1 do
        local j = self:NextInt(1, i)
        arr[i], arr[j] = arr[j], arr[i]
    end
    return arr
end

--- 导出内部状态(纯数据,可序列化;用于命令日志/回放复位/事务回滚)。
---@return table state { seed = number, count = number }
function Random:DumpState()
    return { seed = self._Seed, count = self._Count }
end

--- 恢复内部状态:重置种子后空跑 count 次,回到导出时的游标。
---@param state table { seed = number, count = number }
function Random:LoadState(state)
    assert(type(state) == 'table', 'Random:LoadState 需要 table 状态')
    assert(type(state.seed) == 'number' and type(state.count) == 'number',
        'Random:LoadState 状态字段必须为数值')
    self._Seed = state.seed
    self._Count = state.count
    math.randomseed(self._Seed)
    -- 空跑 count 次,使全局随机游标回到导出时的位置。
    for _ = 1, self._Count do
        math.random()
    end
end

return Random
