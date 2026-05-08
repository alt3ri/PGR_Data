---=================================================================
--- 模型缓存淘汰策略集合
---
--- 所有策略均须实现同一接口：
---   SelectEvictKeys(pool, activeKey)
---     -> toRemove: string[]      需要被销毁的 key 列表
---     -> needWaitDestroy: bool   是否需要等本帧 Destroy 完成后再加载
---
--- 使用方式：实例化后注入 XModelCachePool
---=================================================================

-- ================================================================
-- 策略一：组合策略（TTL 超时 + 数量上限，等效原有逻辑）
--
-- 两个条件取并集：
--   1. 非激活且隐藏时间 >= ttlSeconds 的条目全部淘汰
--   2. 淘汰后若数量仍 >= maxCount，额外踢掉 HideTime 最早的那个
--
-- needWaitDestroy = false：销毁与加载并行，无需等待
-- ================================================================
---@class XCompositeEvictionPolicy
local XCompositeEvictionPolicy = XClass(nil, "XCompositeEvictionPolicy")

---@param ttlSeconds number 超时阈值（秒），默认 5
---@param maxCount   number 最大缓存数量
function XCompositeEvictionPolicy:Ctor(ttlSeconds, maxCount)
    self._TTL      = ttlSeconds or 5
    self._MaxCount = maxCount or 3
end

---@param pool      table<string, table>  缓存池原始数据
---@param activeKey string|nil            当前激活的 key
---@return string[] toRemove
---@return boolean  needWaitDestroy
function XCompositeEvictionPolicy:SelectEvictKeys(pool, activeKey)
    local now        = XTime.GetServerNowTimestamp()
    local toRemove   = {}
    local removedSet = {}
    local oldestKey, oldestTime = nil, math.huge

    for key, entry in pairs(pool) do
        if key ~= activeKey and not entry.IsPinned and entry.HideTime > 0 then
            local diff = now - entry.HideTime
            if diff >= self._TTL then
                toRemove[#toRemove + 1] = key
                removedSet[key] = true
            elseif entry.HideTime < oldestTime then
                oldestTime = entry.HideTime
                oldestKey  = key
            end
        end
    end

    -- 超出数量上限时，额外踢掉最老的（且尚未被列入删除）
    local totalCount  = table.nums(pool)
    local removeCount = #toRemove
    if totalCount - removeCount >= self._MaxCount
        and oldestKey
        and not removedSet[oldestKey]
    then
        toRemove[#toRemove + 1] = oldestKey
    end

    return toRemove, false
end


-- ================================================================
-- 策略二：低内存策略（切换即销毁所有非激活条目）
--
-- needWaitDestroy = true：
--   Unity 的 Object.Destroy 是延迟到帧末执行的，
--   告知调用方须等下一帧再发起新模型的加载请求，
--   避免新旧模型在同一帧内同时存在导致内存峰值。
-- ================================================================
---@class XLowMemoryEvictionPolicy
local XLowMemoryEvictionPolicy = XClass(nil, "XLowMemoryEvictionPolicy")

function XLowMemoryEvictionPolicy:Ctor() end

---@param pool      table<string, table>
---@param activeKey string|nil
---@return string[] toRemove
---@return boolean  needWaitDestroy
function XLowMemoryEvictionPolicy:SelectEvictKeys(pool, activeKey)
    local toRemove = {}
    for key, entry in pairs(pool) do
        if key ~= activeKey and not entry.IsPinned then
            toRemove[#toRemove + 1] = key
        end
    end
    return toRemove, true
end


-- ================================================================
-- 策略三：永不淘汰（多人展示厅等需同时保留所有已加载模型的场景）
--
-- needWaitDestroy = false
-- ================================================================
---@class XNeverEvictPolicy
local XNeverEvictPolicy = XClass(nil, "XNeverEvictPolicy")

function XNeverEvictPolicy:Ctor() end

---@param pool      table<string, table>
---@param activeKey string|nil
---@return string[] toRemove
---@return boolean  needWaitDestroy
function XNeverEvictPolicy:SelectEvictKeys(pool, activeKey)
    return {}, false
end


return {
    XCompositeEvictionPolicy  = XCompositeEvictionPolicy,
    XLowMemoryEvictionPolicy  = XLowMemoryEvictionPolicy,
    XNeverEvictPolicy         = XNeverEvictPolicy,
}
