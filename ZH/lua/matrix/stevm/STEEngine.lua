--- STEFramework 2.0 框架门面:对外执行入口
---
--- 上层骨架极简——只提供「把业务 effect 函数跑起来」的入口;EST 的定义、配置、颗粒度、
--- 传参全交玩法自由发挥。框架只传 vm,不碰业务参数。
---
local AtomicGroup = require('STEVM/Engine/AtomicGroup')

---@class STEEngine
local STEEngine = {}

--- 业务层主入口，执行一次完整逻辑, 不可递归调用
--- 执行一次:给业务 effect 函数一个 vm,跑起来。可选原子(全成或全回滚)。
--- 业务 fn 的签名/参数由玩法自定(闭包捕获),框架只传 vm 这一个参数。
--- 无论成功或报错,本次借用的黑板都归还框架池(经 vm:Release)。
---@param env STEEnv
---@param fn fun(vm:STEVM.VM):any 业务 effect 函数
---@param atomic boolean|nil 是否原子执行(true 时全成或全回滚)
---@param ... @业务层自定义参数
---@return boolean ok 是否成功(非原子:fn 未抛错即 true;原子:事务是否提交)
---@return any result 非原子:fn 返回值;原子:fn 返回值(中止时为 nil)
---@return any reason 原子中止时的原因(否则 nil)
function STEEngine.Run(env, fn, atomic, rootId, ...)
    assert(env ~= nil, 'STEEngine.Run env 不可为 nil')
    assert(type(fn) == 'function', 'STEEngine.Run fn 必须为函数')

    local ctx = env:GetPoolExecContext()
    
    ctx:Init(env, rootId, env:GetEventSystem(), env:GetRandom())
    
    local vm  = env:GetVM()
    
    vm:Init(ctx)

    -- 用 pcall 包裹,保证无论如何都归还黑板(避免报错路径泄漏池对象)。
    local pok, a, b
    if atomic then
        local pack = table.pack(...)
        -- 原子:fn 的返回值经闭包带出(RunAtomic 自身返回 ok,reason)。
        local result
        pok, a, b = pcall(function()
            local committed, reason = AtomicGroup.RunAtomic(env, function() result = fn(vm, table.unpack(pack, 1, pack.n)) end)
            return committed, reason
        end)
        vm:Release()
        if not pok then
            XLog.Error(a)
        end
        return a, result, b  -- a=committed, result=fn返回, b=reason
    end

    -- 非事务态则正常调用
    local result = fn(vm, ...)
    vm:Release()

    return true, result
end

return STEEngine
