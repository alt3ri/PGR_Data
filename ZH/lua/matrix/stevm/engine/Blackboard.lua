--- STEFramework 2.0 黑板
---
--- 角色:单步执行内的命名数据袋,承载中间值——配置值(LoadConst)、读出的 property 值、
---       前置算出的结果。让 effect 内的数据走黑板而非参数层层对齐。
---
--- 语义:命名 key → 值;读写都是 O(1) table 存取。算术不在黑板做(取出用宿主 Lua 算,
---       算完写回),黑板只存「节点边界上的值」。
---
--- 生命周期:与 VM 实例同生共死(一个 RunStep 单步),跨该步内多条 VM 指令 / 多个 effect
---       共享同一黑板(事务不清黑板,只管 Property 写时日志)。RunStep 结束 vm:Release 归还池时 Clear。
---       不进状态指纹、不持久化——回放靠 env 级状态快照(rngState/tick),黑板是瞬态中间值不参与。
---
---@class Blackboard
---@field _Data table<any, any>
local Blackboard = XClass(nil, 'Blackboard')

function Blackboard:Ctor()
    self._Data = {}
end

--- 写一个值。
---@param key any
---@param value any
function Blackboard:Set(key, value)
    self._Data[key] = value
end

--- 读一个值(不存在返回 nil)。
---@param key any
---@return any
function Blackboard:Get(key)
    return self._Data[key]
end

--- 是否存在某 key。
---@param key any
---@return boolean
function Blackboard:Has(key)
    return self._Data[key] ~= nil
end

function Blackboard:Clear()
    self._Data = {}
end

--- 入池钩子(对象池归还时调):清空内部 table 字段,复用不弃。
function Blackboard:OnRelease()
    self:Clear()
end

return Blackboard
