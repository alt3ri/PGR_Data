---=================================================================
--- XModelCachePool —— 通用模型缓存池
---
--- 职责：
---   · 以 key（字符串）为索引缓存已加载的 Unity 模型
---   · 通过可插拔的 IEvictionPolicy 决定何时淘汰哪些条目
---   · 提供异步竞态保护（单调令牌机制）
---   · 区分两种销毁路径，避免对外部已销毁的 GO 二次 Destroy
---
--- 缓存条目结构（entry）：
---   entry.Key      string               缓存键
---   entry.Model    UnityEngine.Component 主模型组件
---   entry.Payload  table                业务附属数据（特效/代理等）
---   entry.HideTime number               被切走时的服务器时间戳（0=当前激活）
---   entry.IsPinned boolean              true=永不被策略淘汰
---
--- 依赖：
---   XTime、XTool、XLog（全局可用）
---=================================================================

---@class XModelCachePool
---@field _Pool          table<string, table>   缓存池
---@field _ActiveKey     string|nil             当前激活的 key
---@field _TokenCounter  number                 单调递增异步令牌
---@field _Policy        table                  淘汰策略（IEvictionPolicy）
---@field _DestroyFunc   function               业务层销毁回调 function(key, entry)
local XModelCachePool = XClass(nil, "XModelCachePool")

---@param policy      table     淘汰策略实例（须实现 SelectEvictKeys）
---@param destroyFunc function  条目销毁前的业务清理回调 function(key, entry)
function XModelCachePool:Ctor(policy, destroyFunc)
    if not policy then
        XLog.Error("[XModelCachePool] policy 不能为空，请传入淘汰策略实例")
    end
    self._Pool         = {}
    self._ActiveKey    = nil
    self._TokenCounter = 0
    self._Policy       = policy
    self._DestroyFunc  = destroyFunc
end

-- ================================================================
-- 公开接口
-- ================================================================

--- 运行时热切换淘汰策略（不影响已有缓存条目状态）
---@param policy table 新策略实例
function XModelCachePool:SetPolicy(policy)
    if not policy then
        XLog.Error("[XModelCachePool] SetPolicy: policy 不能为空")
        return
    end
    self._Policy = policy
end

--- 查询缓存条目，同时进行悬空引用检测
--- 若 GO 已被外部销毁，自动清除该条目并返回 nil
---@param key string
---@return table|nil entry
function XModelCachePool:Get(key)
    local entry = self._Pool[key]
    if not entry then
        return nil
    end
    -- 悬空检测：GO 被外部销毁后 UObjIsNil 返回 true
    if XTool.UObjIsNil(entry.Model) then
        self:_InvalidateEntry(key)
        return nil
    end
    return entry
end

--- 切换当前激活 key，触发淘汰逻辑，返回异步令牌
---
--- 两种返回值组合：
---   token, false → 普通模式，可立即发起异步加载
---   token, true  → 低内存串行模式，须等下一帧再加载
---
---@param  newKey string
---@return number  token           本次加载的唯一令牌
---@return boolean needWaitDestroy 是否需要等待当帧 Destroy 完成
function XModelCachePool:BeginSwitch(newKey)
    -- 1. 给旧的激活条目打隐藏时间戳
    if self._ActiveKey and self._ActiveKey ~= newKey then
        local prev = self._Pool[self._ActiveKey]
        if prev and not XTool.UObjIsNil(prev.Model) then
            prev.HideTime = XTime.GetServerNowTimestamp()
        end
    end
    self._ActiveKey = newKey

    -- 2. 令牌自增（旧的未完成异步回调拿到旧令牌，Put 时会被拒绝）
    self._TokenCounter = self._TokenCounter + 1
    local token = self._TokenCounter

    -- 3. 委托策略执行淘汰
    local needWaitDestroy = self:_Evict()

    return token, needWaitDestroy
end

--- 将异步加载完成的模型写入缓存
--- 内含令牌校验：令牌过期时自动销毁多余 GO 并返回 false
---
---@param key     string
---@param model   userdata  Unity Component
---@param token   number    BeginSwitch 返回的令牌
---@param payload table     业务附属数据（可为空 table）
---@return boolean  ok      false 表示令牌过期，调用方应直接返回不做后续处理
function XModelCachePool:Put(key, model, token, payload)
    -- 令牌校验：不是最新请求的回调，销毁多余 GO
    if token ~= self._TokenCounter then
        if not XTool.UObjIsNil(model) then
            CS.UnityEngine.Object.Destroy(model.gameObject)
        end
        return false
    end

    local entry     = {}
    entry.Key       = key
    entry.Model     = model
    entry.Payload   = payload
    entry.HideTime  = 0       -- 0 表示当前激活，不参与超时淘汰
    entry.IsPinned  = false
    self._Pool[key] = entry
    return true
end

--- 锁定条目，使其不被任何策略淘汰（适用于过场动画、固定展示等场景）
---@param key string
function XModelCachePool:Pin(key)
    local entry = self._Pool[key]
    if entry then
        entry.IsPinned = true
    end
end

--- 解锁条目，恢复正常淘汰
---@param key string
function XModelCachePool:Unpin(key)
    local entry = self._Pool[key]
    if entry then
        entry.IsPinned = false
    end
end

--- 获取缓存总数（含当前激活条目）
---@return number
function XModelCachePool:Count()
    return table.nums(self._Pool)
end

--- 销毁全部缓存（UI 关闭时调用）
--- 先收集 key 列表再遍历，避免 pairs 迭代期间修改 table
function XModelCachePool:Clear()
    local keys = {}
    for key in pairs(self._Pool) do
        keys[#keys + 1] = key
    end
    for _, key in ipairs(keys) do
        local entry = self._Pool[key]
        if entry then
            self:_DestroyEntry(key, entry)
        end
        self._Pool[key] = nil
    end
    self._ActiveKey = nil
end

--- 主动巡检：遍历所有条目，清除 GO 已被外部销毁的悬空引用
--- 建议在 UI OnDisable 或低频定时器中调用
function XModelCachePool:ValidateAll()
    local invalid = {}
    for key, entry in pairs(self._Pool) do
        if XTool.UObjIsNil(entry.Model) then
            invalid[#invalid + 1] = key
        end
    end
    for _, key in ipairs(invalid) do
        self:_InvalidateEntry(key)
    end
end

-- ================================================================
-- 内部方法
-- ================================================================

--- 委托策略选出需要淘汰的 key，执行销毁
--- 返回策略的 needWaitDestroy 标志
---@return boolean needWaitDestroy
function XModelCachePool:_Evict()
    local toRemove, needWaitDestroy = self._Policy:SelectEvictKeys(
        self._Pool,
        self._ActiveKey
    )
    for _, key in ipairs(toRemove) do
        local entry = self._Pool[key]
        if entry then
            self:_DestroyEntry(key, entry)
            self._Pool[key] = nil
        end
    end
    return needWaitDestroy
end

--- Lua 主动销毁路径：
---   1. 先调业务层清理回调（pcall 隔离，防止异常中断整个清理链）
---   2. 再 Object.Destroy（GO 由 Unity 在帧末真正销毁）
---@param key   string
---@param entry table
function XModelCachePool:_DestroyEntry(key, entry)
    if self._DestroyFunc then
        local ok, err = pcall(self._DestroyFunc, key, entry)
        if not ok then
            XLog.Error(string.format(
                "[XModelCachePool] _DestroyEntry 业务回调异常, key=%s, err=%s",
                tostring(key), tostring(err)
            ))
        end
    end
    if entry.Model and not XTool.UObjIsNil(entry.Model) then
        CS.UnityEngine.Object.Destroy(entry.Model.gameObject)
    end
end

--- 外部销毁路径（GO 已不存在，只清 Lua 侧引用）：
---   不调 Object.Destroy，避免对已销毁 GO 二次操作触发 Unity 报错
---@param key string
function XModelCachePool:_InvalidateEntry(key)
    -- 业务回调不在此处触发：GO 已无效，附属特效的引用同样可能已失效
    self._Pool[key] = nil
    if self._ActiveKey == key then
        self._ActiveKey = nil
    end
end


return XModelCachePool
