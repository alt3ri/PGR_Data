--- 集成框架内各种常用table的复用池
---@class STEVM.Pools
local Pools = XClass(nil, "Pools")
local STEEnum = require("STEVM/STEEnum")

local Blackboard  = require('STEVM/Engine/Blackboard')
local ExecContext = require("STEVM/Engine/ExecContext")

function Pools:Ctor()
    ---@type XPool[]
    self._PoolsDict = {}
    self._KeyCollector = {}  -- 单一共享，DictSnap onRelease 清空用（收集键再 nil）

    -- 注册黑板数据对象池
    self._PoolsDict[STEEnum.InnerPoolsKey.BlackBoard] = XPool.New(function()
        return Blackboard.New()
    end, function(blackboard)
        blackboard:OnRelease()
    end, false)
    
    -- 注册调用上下文对象池
    self._PoolsDict[STEEnum.InnerPoolsKey.ExecContext] = XPool.New(function()
        return ExecContext.New()
    end, function(execContext)
        execContext:Release()
    end, false)

    -- 注册运算队列项池（PropertyModifiedNum {op,value,sourceId}；事务快照/回滚高频，复用减 GC）
    self._PoolsDict[STEEnum.InnerPoolsKey.ModOp] = XPool.New(function()
        return { op = nil, value = nil, sourceId = nil }
    end, function(modOp)
        modOp.op = nil
        modOp.value = nil
        modOp.sourceId = nil  -- 释放 stale sourceId 引用
    end, false)

    -- 注册字典型快照池（PropertyDict/Tags copy + ModifiedNum wrapper）
    -- onRelease 用 _KeyCollector 收集键再 nil（不在 pairs 中增删）
    self._PoolsDict[STEEnum.InnerPoolsKey.DictSnap] = XPool.New(function()
        return {}
    end, function(t)
        local kc = self._KeyCollector
        local n = 0
        for k in pairs(t) do
            n = n + 1
            kc[n] = k
        end
        for i = 1, n do
            t[kc[i]] = nil
            kc[i] = nil
        end
    end, false)

    -- 注册数组型快照池（PropertyList copy + ModifiedNum ops 数组）
    -- onRelease 从尾部置空（用户指定，更友好）
    self._PoolsDict[STEEnum.InnerPoolsKey.ListSnap] = XPool.New(function()
        return {}
    end, function(t)
        for i = #t, 1, -1 do
            t[i] = nil
        end
    end, false)
end

function Pools:GetItemByPoolKey(poolKey)
    local pool = self._PoolsDict[poolKey]

    if pool then
        return pool:GetItemFromPool()
    else
        XLog.Error("[STEVM]对象池类型不存在：" .. poolKey)
    end
end

--- 非安全接口，约束仅框架内部有限使用
function Pools:ReturnItemByPoolKey(poolKey, item)
    local pool = self._PoolsDict[poolKey]

    if pool then
        pool:ReturnItemToPool(item)
    else
        XLog.Error("[STEVM]对象池类型不存在：" .. poolKey)
    end
end

return Pools