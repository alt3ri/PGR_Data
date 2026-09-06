---@class PropertyBase STE框架属性基类，属性是STE虚拟机的基本操作单元
---@field _OwnScopeId any 归属 Scope 的 id
---@field _OwnEnv table 归属 env(提供 GetScope)
local PropertyBase = XClass(nil, 'PropertyBase')

---@param ownScopeId any 归属 Scope 的 id
---@param ownEnv table 归属 env(需提供 GetScope(scopeId)->Scope|nil)
function PropertyBase:Ctor(ownScopeId, ownEnv)
    self._OwnScopeId = ownScopeId
    self._OwnEnv = ownEnv
end

--- 取归属 Scope id。
---@return any
function PropertyBase:GetOwnScopeId()
    return self._OwnScopeId
end

--- 取归属 env。
---@return table
function PropertyBase:GetOwnEnv()
    return self._OwnEnv
end


--region 原子事务相关

--- 写前钩子:在任何改状态的方法体最前面调用。事务态下首次改本 property 即记一份快照到日志。
--- 取自身持有的 env;非事务态无副作用(写时日志,拷贝量 = 本次改动量)。
function PropertyBase:_BeforeWrite()
    local env = self._OwnEnv
    if env and env:IsInTransaction() then
        env:JournalRecord(self)
    end
end

--- 事务态时的数据快照，子类重写
---@return table snap { tags = table<any, number> }
function PropertyBase:Snapshot()
    return nil
end

--- 事务回滚时的还原，子类重写
---@param snap table Snapshot 产出的结构
function PropertyBase:Restore(snap)
    -- do nothing
end

--- 释放快照内复用的资源（子类覆写：回池快照内 pool'd table）。
--- Commit 丢弃快照 / Rollback Restore 后由 STEEnv 调，快照生命周期收口（防 pool'd table 静默丢 GC）。
---@param snap table Snapshot 产出的结构
function PropertyBase:ReleaseSnapshot(snap)
    -- 基类快照无可复用资源；子类（如 PropertyModifiedNum）覆写回池。
end

--endregion

--- 释放。基类无可释放资源;子类如持有资源应重写并保证幂等。
function PropertyBase:Release()
    -- 基类无状态可释放;空实现,重复调用安全。
end

return PropertyBase
