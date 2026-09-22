--- STEFramework 2.0 原子事务 AtomicGroup
---
--- 角色:把一组写操作包成「全成功或全回滚」的原子组。组内任意一步中止,
---       整组对状态(rng/tick/各 Scope/scope 增删)的改动全部撤销。
---
--- 中止机制:用一个带 _atomicAbort 标记的错误对象经 error 抛出,由 RunAtomic 的 pcall 捕获;
---       区别于「真 bug」(普通 Lua error):真 bug 回滚后原样重抛,不被吞掉。
---
--- 嵌套:env 用写时日志帧栈(每层一帧),故外层/内层各自成事务。
---
--- 状态管理收口:BeginTxn/CommitTxn/RollbackTxn 内部已处理日志栈,
---       本模块不再直接碰 snapshot。
---
--- 不依赖 ExecContext(ExecContext 反过来 require 本模块,避免 require 环)。
local AtomicGroup = {}

--- 构造一个中止标记对象(纯数据)。
---@param reason string|nil 中止原因
---@return table abort { _atomicAbort=true, reason=string|nil }
local function MakeAbort(reason)
    return { _atomicAbort = true, reason = reason }
end

--- 判断一个被 pcall 捕获的错误是否为本框架的中止标记(而非真 bug)。
---@param e any
---@return boolean
local function IsAbort(e)
    return type(e) == 'table' and e._atomicAbort == true
end

--- 主动中止当前原子组(经 error 抛出中止标记)。只应在 RunAtomic 的 fn 内调用。
---@param reason string|nil 中止原因
function AtomicGroup.AbortTxn(reason)
    error(MakeAbort(reason))
end

--- 运行一个原子组:fn 内的写操作要么全部提交,要么全部回滚。
---   ① BeginTxn:压一帧写时日志(捕获 rng/tick)+ 进入事务标记;
---   ② pcall(fn);
---   ③ 成功 → CommitTxn(日志合并/并入父帧),返回 true;
---      失败且是中止标记 → RollbackTxn(逐项 Restore),返回 false + reason;
---      失败但是真 bug → RollbackTxn 后原样重抛(不吞)。
---@param env STEEnv
---@param fn fun() 事务体(内部做写操作;中止用 AtomicGroup.AbortTxn)
---@return boolean ok 是否提交成功
---@return string|nil reason 中止原因(ok 为 true 时为 nil)
function AtomicGroup.RunAtomic(env, fn)
    env:BeginTxn()
    local ok, err = pcall(fn)
    if ok then
        env:CommitTxn()
        return true, nil
    end
    env:RollbackTxn()
    if IsAbort(err) then
        return false, err.reason
    end
    -- 真 bug:回滚后原样重抛,不被事务吞掉。
    error(err)
end

return AtomicGroup
