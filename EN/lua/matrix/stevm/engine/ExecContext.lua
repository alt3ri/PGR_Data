--- STEFramework 2.0 执行上下文 ExecContext
---
--- 设计依据(DESIGN 第三部分):E-S-T 是一棵单次执行的行为树,节点无状态、高度共享,
---   节点函数内无从知道「我属于哪棵树、在哪个位置」。解法:把位置作为数据,执行时一路带下去。
---   节点签名统一 function(ctx, intParams, floatParams, stringParams, ...),ctx 背着路径栈。
---
--- trace(DESIGN 3.3 增益2):可选钩子,记录每节点 进入/结果,产出执行 trace 树。
---   不挂 trace 时零开销;trace 必须确定性(本框架满足第一部分即自动成立)。
---
local AtomicGroup = require('STEVM/Engine/AtomicGroup')

--- 调用上下文，目前是简化实现，不记录完整的调用链
---@class ExecContext
---@field env STEEnv 运行期环境(STEEnv)
---@field root any 根入口 configId(回答「属于哪棵树」)
---@field events table|nil 事件输出通道(VM 写指令发事件用;具体类型待 VM 层定)
---@field rng table Random 实例(节点内若需随机走它)
---@field trace table|nil 可选 trace 收集器(有 OnEnter/OnResult 钩子则调用)
local ExecContext = XClass(nil, 'ExecContext')

--- 注意:子上下文由 Enter 派生(走 _Derive),不直接 New。
---@param env table 运行期环境
---@param rootId any 根入口 configId
---@param deps table 依赖 { events=事件通道, rng=Random, trace=table|nil }
function ExecContext:Init(env, rootId, events, rand, trace)
    -- 防御判空(规范#20):env / deps 是必须依赖,缺失则后续节点全跑空。
    assert(env ~= nil, 'ExecContext:Ctor env 不可为 nil')

    self.env       = env
    self.root      = rootId
    self.events    = events
    self.rng       = rand
    self.trace     = trace
end

--- 我在哪:把路径链格式化成可读门牌号(确定性、跨运行一致)。
--- 形如:root#1024 ─yes→ #5001 ─if.then→ #5003
--- 目前简化实现，不记录完整调用链，仅记录所属根配置
---@return string
function ExecContext:Where()
    return 'root#' .. tostring(self.root)
end

--- 报错:所有报错自动盖上「我在哪」的戳(DESIGN 3.2)。
--- 逻辑层只产事件、报错走 XLog,绝不碰 UI(契约 E1)。
--- 事务内(原子组)报错额外触发中止:让整组回滚而非带病提交。
---@param msg string
function ExecContext:Error(msg)
    XLog.Error(tostring(msg) .. '  @ ' .. self:Where())
    if self.env and self.env:IsInTransaction() then
        AtomicGroup.AbortTxn('原子组内逻辑错误:' .. tostring(msg))
    end
end

function ExecContext:Clear()
    self.env       = nil
    self.root      = nil
    self.events    = nil
    self.rng       = nil
    self.trace     = nil
end

--- 回收释放时调用
function ExecContext:Release()
    self:Clear()
end

--region trace 钩子(可选,DESIGN 3.3 增益2)-----------------------------------
-- trace 收集器约定(若提供):
--   trace.OnEnter(ctx, kind, configId)   进入某节点时
--   trace.OnResult(ctx, kind, configId, result) 节点产出结果时
-- 钩子缺失则静默跳过(零开销)。trace 仅观测、不改变模拟结果(纯 §C 旁路)。

--- 通知 trace:进入某节点。
---@param kind string 'effect'/'trigger'/'selector'
---@param configId any
function ExecContext:TraceEnter(kind, configId)
    local tr = self.trace
    if tr and tr.OnEnter then
        tr.OnEnter(self, kind, configId)
    end
end

--- 通知 trace:某节点产出结果。
---@param kind string
---@param configId any
---@param result any trigger 真假 / effect 是否提交 / selector 输出数组
function ExecContext:TraceResult(kind, configId, result)
    local tr = self.trace
    if tr and tr.OnResult then
        tr.OnResult(self, kind, configId, result)
    end
end
--endregion

return ExecContext
