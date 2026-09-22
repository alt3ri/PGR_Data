--- STEFramework 2.0 VM:单步执行的指令机
---
--- 定位:VM 模式(非真 VM)的执行层。只有 VM 指令能碰 Property / 黑板 / 事务;
---       一条指令 ≈ 一次业务动作(读字段/选目标/改值/算/发事件),算术与控制流交宿主 Lua。
---       effect 之间的调用、触发 N 次、计时、事件响应等编排属上层,不在 VM。
---
--- 字段定位:指令用 (scopeId, propKey) 定位字段;VM 内部 GetField 拿到的 Property 对象即
---       「handle」,VM 把它当不透明黑盒,只调它实现的协议(数值 Get/Set、容器 GetByKey 等),
---       不认具体类型(数值/字典/列表/业务派生)。
---
--- 黑板:VM 持一个 Blackboard 存中间值;Load* 把值放黑板,Set/Get 直接存取,算术用宿主 Lua。
---
--- 事务/确定性:写指令经 Property 写方法(内置 _BeforeWrite),事务态自动记写时日志、可回滚;
---       随机走 ctx.rng(env 唯一随机源)。VM 不直接碰 snapshot/staging。
---
--- 报错:经 ctx:Error 盖执行位置戳(无 ctx 时退化为 XLog.Error)。
local ValueOp    = require('STEVM/Engine/ValueOp')
local STEEnum   = require('STEVM/STEEnum')

local OpType = STEEnum.OpType

---@class STEVM.VM
---@field _Env STEEnv 运行期环境(scope/rng/事务)
---@field _ExecContext ExecContext|nil 执行上下文(位置/rng/事件通道;可空)
---@field Blackboard Blackboard 黑板(中间值)
local VM = XClass(nil, 'VM')

--- 构造。黑板从 env 框架池取(复用,减分配);用完调 VM:Release 归还。
---@param env STEEnv 运行期环境
---@param ctx ExecContext|nil 可选执行上下文(提供 rng / Error 定位 / events)
function VM:Ctor(env, ctx)
    assert(env ~= nil, 'VM:Ctor env 不可为 nil')
    self._Env = env
end

function VM:Init(ctx)
    -- 实例复用下需要先释放
    self:Release()

    self._ExecContext = ctx
    self.Blackboard   = self._Env:GetPoolBlackBoard()
end

--- 归还本 VM 借用的黑板到 env 池(框架入口在一次执行结束后调用)。幂等。
function VM:Release()
    if self.Blackboard then
        self._Env:ReturnPoolBlackBoard(self.Blackboard)
        self.Blackboard = nil
    end

    if self._ExecContext then
        self._Env:ReturnPoolExecContext(self._ExecContext)
        self._ExecContext = nil
    end
end

--- 报错:有 ctx 走 ctx:Error(带位置戳,事务内会触发回滚),否则退化 XLog.Error。
--- [用于外部函数主动调用，目的是让报错能够触发事务态回滚]
---@param msg string
function VM:Error(msg)
    self:_Error(msg)
end

--- 获取环境实例
---@return STEEnv
function VM:GetEnv()
    return self._Env
end

--- 报错:有 ctx 走 ctx:Error(带位置戳,事务内会触发回滚),否则退化 XLog.Error。
---@param msg string
function VM:_Error(msg)
    if self._ExecContext and self._ExecContext.Error then
        self._ExecContext:Error(msg)
    else
        XLog.Error(msg)
    end
end

--- 取字段对象(handle)。找不到报错返回 nil(不静默返回 0)。
---@param scopeId any
---@param propKey any
---@return table|nil field
function VM:_GetField(scopeId, propKey)
    local scope = self._Env:GetScope(scopeId)
    if scope == nil then
        self:_Error('VM 找不到 scope:' .. tostring(scopeId))
        return nil
    end
    local field = scope:GetField(propKey)
    if field == nil then
        self:_Error('VM 找不到字段:' .. tostring(propKey) .. ' @scope=' .. tostring(scopeId))
        return nil
    end
    return field
end

--region 读环境 → 黑板(纯读)-------------------------------------------------

--- 读字段最终值进黑板(经修正队列+夹紧)。找不到则不写、报错。
---@param scopeId any
---@param propKey any
---@param bbKey any|nil 黑板键,缺省用 propKey
---@return number|nil val 读到的值(便于宿主直接用)
function VM:Load(scopeId, propKey, bbKey)
    local v = self:Read(scopeId, propKey)

    if v then
        self.Blackboard:Set(bbKey or propKey, v)
    end
    
    return v
end

--- 读字段原始 base 值进黑板(无视修正)。
---@param scopeId any
---@param propKey any
---@param bbKey any|nil
---@return number|nil
function VM:LoadOrigin(scopeId, propKey, bbKey)
    local v = self:ReadOrigin(scopeId, propKey)

    if v then
        self.Blackboard:Set(bbKey or propKey, v)
    end
    
    return v
end

--- 取字段对象(handle)放黑板,VM 不拆。供容器操作或宿主直接调协议。
---@param scopeId any
---@param propKey any
---@param bbKey any|nil
---@return table|nil handle
function VM:LoadProperty(scopeId, propKey, bbKey)
    local field = self:_GetField(scopeId, propKey)
    if field == nil then
        return nil
    end
    self.Blackboard:Set(bbKey or propKey, field)
    return field
end

--- 把一个常量/配置值写进黑板。
---@param bbKey any
---@param value any
---@return any value
function VM:LoadConst(bbKey, value)
    self.Blackboard:Set(bbKey, value)
    return value
end

--- 返回 id 升序数组(确定性)。domain 过滤由宿主 Lua 接着做。
---@return any[] ids
function VM:GetEntityIdsList()
    return self._Env:GetAllEntityIds()
end

--- 读字段最终值直接返回，不写入黑板。找不到则不写、报错。
---@param scopeId any
---@param propKey any
---@param bbKey any|nil 黑板键,缺省用 propKey
---@return number|nil val 读到的值(便于宿主直接用)
function VM:Read(scopeId, propKey)
    local field = self:_GetField(scopeId, propKey)
    if field == nil or type(field.GetFinalVal) ~= 'function' then
        if field then self:_Error('VM:Read 字段不支持 GetFinalVal:' .. tostring(propKey)) end
        return nil
    end
    local v = field:GetFinalVal()
    return v
end

--- 读字段原始 base 值(无视修正)。
---@param scopeId any
---@param propKey any
---@param bbKey any|nil
---@return number|nil
function VM:ReadOrigin(scopeId, propKey)
    local field = self:_GetField(scopeId, propKey)
    if field == nil or type(field.GetOriginVal) ~= 'function' then
        if field then self:_Error('VM:ReadOrigin 字段不支持 GetOriginVal:' .. tostring(propKey)) end
        return nil
    end
    local v = field:GetOriginVal()
    return v
end

--- 取字段对象(handle)放黑板,VM 不拆。供容器操作或宿主直接调协议。
---@param scopeId any
---@param propKey any
---@param bbKey any|nil
---@return table|nil handle
function VM:ReadProperty(scopeId, propKey)
    local field = self:_GetField(scopeId, propKey)
    if field == nil then
        return nil
    end
    return field
end
--endregion

--region 黑板存取 ------------------------------------------------------------

---@param key any
---@param value any
function VM:SetToBlackBoard(key, value) self.Blackboard:Set(key, value) end

---@param key any
---@return any
function VM:GetFromBlackBoard(key) return self.Blackboard:Get(key) end
--endregion

--region 写环境(事务内首写记快照)------------------------------------------

--- 对字段做一次数值变更(op 取 ValChangeType;operand 来自黑板或字面)。复用 ValueOp。
---@param scopeId any
---@param propKey any
---@param opType number STEEnum.ValChangeType
---@param operand number
---@return boolean ok
function VM:Store(scopeId, propKey, opType, operand)
    local field = self:_GetField(scopeId, propKey)
    if field == nil then
        return false
    end
    if type(field.GetOriginVal) ~= 'function' or type(field.SetOriginVal) ~= 'function' then
        self:_Error('VM:Store 字段不支持 Get/SetOriginVal:' .. tostring(propKey))
        return false
    end
    if type(operand) ~= 'number' then
        self:_Error('VM:Store operand 必须为 number:' .. tostring(operand))
        return false
    end
    -- 运算与写作用于 base(GetOriginVal/SetOriginVal),避免 modifier/clamp 下 base 漂移。
    local newBase = ValueOp.Apply(field:GetOriginVal(), opType, operand)
    if newBase == nil then
        self:_Error('VM:Store 非法运算(除零/未知 op),opType=' .. tostring(opType))
        return false
    end
    field:SetOriginVal(newBase)
    return true
end

--- 给可修正字段加一条来源修正(buff;按 sourceId 可整源撤)。
---@param scopeId any
---@param propKey any
---@param opType number
---@param value number
---@param sourceId any
---@return boolean ok
function VM:AddModifier(scopeId, propKey, opType, value, sourceId)
    local field = self:_GetField(scopeId, propKey)
    if field == nil then return false end
    if type(field.AddModifier) ~= 'function' then
        self:_Error('VM:AddModifier 字段不支持修正:' .. tostring(propKey))
        return false
    end
    field:AddModifier(opType, value, sourceId)
    return true
end

--- 移除某来源在某字段上的全部修正。
---@param scopeId any
---@param propKey any
---@param sourceId any
---@return boolean ok
function VM:RemoveModifier(scopeId, propKey, sourceId)
    local field = self:_GetField(scopeId, propKey)
    if field == nil then return false end
    if type(field.RemoveModifierBySource) ~= 'function' then
        self:_Error('VM:RemoveModifier 字段不支持修正:' .. tostring(propKey))
        return false
    end
    field:RemoveModifierBySource(sourceId)
    return true
end

--- 给 scope 加标签。
---@param scopeId any
---@param tag any
---@return boolean ok
function VM:AddTag(scopeId, tag)
    local scope = self._Env:GetScope(scopeId)
    if scope == nil then self:_Error('VM:AddTag 找不到 scope:' .. tostring(scopeId)); return false end
    scope:GetTags():AddTag(tag)
    return true
end

--- 移除 scope 标签。
---@param scopeId any
---@param tag any
---@return boolean ok
function VM:RemoveTag(scopeId, tag)
    local scope = self._Env:GetScope(scopeId)
    if scope == nil then self:_Error('VM:RemoveTag 找不到 scope:' .. tostring(scopeId)); return false end
    scope:GetTags():RemoveTag(tag)
    return true
end
--endregion

--region 容器操作(认识容器协议,不认识具体类型;写经事务)----------------------

--- 容器读:转交 handle:GetByKey。handle 来自 LoadProperty 或直接传字段对象。
---@param handle table 容器型 Property
---@param key any
---@return any
function VM:PropGet(handle, key)
    if handle == nil or type(handle.GetByKey) ~= 'function' then
        self:_Error('VM:PropGet 目标不支持容器读')
        return nil
    end
    return handle:GetByKey(key)
end

--- 容器写:转交 handle:SetByKey(内部 _BeforeWrite,事务可回滚)。
---@param handle table
---@param key any
---@param value any
---@return boolean ok
function VM:PropSet(handle, key, value)
    if handle == nil or type(handle.SetByKey) ~= 'function' then
        self:_Error('VM:PropSet 目标不支持容器写')
        return false
    end
    handle:SetByKey(key, value)
    return true
end

--- 容器长度:转交 handle:Len。
---@param handle table
---@return number
function VM:PropLen(handle)
    if handle == nil or type(handle.Len) ~= 'function' then
        self:_Error('VM:PropLen 目标不支持容器')
        return 0
    end
    return handle:Len()
end

--- 容器键枚举:转交 handle:GetSortedKeys,返回有序键数组(字典=排序键,列表=1..n)。
--- 让宿主能遍历整个容器(消耗全部、按颜色统计等),不必伸手进 handle 内部。纯读。
---@param handle table
---@return any[] keys 有序键数组(空容器返回空数组)
function VM:PropKeys(handle)
    if handle == nil or type(handle.GetSortedKeys) ~= 'function' then
        self:_Error('VM:PropKeys 目标不支持键枚举')
        return {}
    end
    return handle:GetSortedKeys()
end

--- 列表追加:转交 handle:Append(内部 _BeforeWrite)。
---@param handle table
---@param value any
---@return boolean ok
function VM:PropAppend(handle, value)
    if handle == nil or type(handle.Append) ~= 'function' then
        self:_Error('VM:PropAppend 目标不支持追加')
        return false
    end
    handle:Append(value)
    return true
end

---- 容器清空 handle:Clear(内部 _BeforeWrite)
---@param handle table
---@return boolean ok
function VM:PropClear(handle)
    if handle == nil or type(handle.Clear) ~= 'function' then
        self:_Error('VM:PropClear 目标不支持清空')
        return false
    end
    handle:Clear()
    return true
end

---- 容器清空 handle:RemoveByKey(内部 _BeforeWrite)
---@param handle table
---@return boolean ok
function VM:PropRemoveByKey(handle, key)
    if handle == nil or type(handle.RemoveByKey) ~= 'function' then
        self:_Error('VM:PropRemoveByKey 目标不支持移除')
        return false
    end
    handle:RemoveByKey(key)
    return true
end

--- 列表是否包含值:转交 handle:Contains。纯读。
---@param handle table
---@param value any
---@return boolean
function VM:PropContains(handle, value)
    if handle == nil or type(handle.Contains) ~= 'function' then
        self:_Error('VM:PropContains 目标不支持包含判定')
        return false
    end
    return handle:Contains(value)
end

--- 字典是否包含键:转交 handle:ContainsKey。纯读。
---@param handle table
---@param key any
---@return boolean
function VM:PropContainsKey(handle, key)
    if handle == nil or type(handle.ContainsKey) ~= 'function' then
        self:_Error('VM:PropContainsKey 目标不支持包含判定')
        return false
    end
    return handle:ContainsKey(key)
end

---- 容器清空 handle:RemoveValue(内部 _BeforeWrite)
---@param handle table
---@return boolean ok
function VM:PropRemoveValue(handle, value)
    if handle == nil or type(handle.RemoveValue) ~= 'function' then
        self:_Error('VM:PropRemoveValue 目标不支持移除')
        return false
    end
    handle:RemoveValue(value)
    return true
end
--endregion

--region 读判断 → bool(Trigger 原子谓词;组合用宿主 and/or/not)-----------------

--- scope 是否有标签。
---@param scopeId any
---@param tag any
---@return boolean
function VM:HasTag(scopeId, tag)
    local scope = self._Env:GetScope(scopeId)
    if scope == nil then return false end
    return scope:GetTags():HasTag(tag)
end

--- 数值比较。a/b 为字面值(宿主可先 Load/Get 出来再传)。op 取 STEEnum.OpType。
---@param a number
---@param op number STEEnum.OpType
---@param b number
---@return boolean
function VM:Compare(a, op, b)
    if op == OpType.Equals then return a == b
    elseif op == OpType.NotEquals then return a ~= b
    elseif op == OpType.Bigger then return a > b
    elseif op == OpType.BiggerOrEquals then return a >= b
    elseif op == OpType.Smaller then return a < b
    elseif op == OpType.SmallerOrEquals then return a <= b
    end
    self:_Error('VM:Compare 未知比较 op:' .. tostring(op))
    return false
end

--- scope 是否存在。
---@param scopeId any
---@return boolean
function VM:Exists(scopeId)
    return self._Env:GetScope(scopeId) ~= nil
end

--- 区间判断:lo <= value <= hi(闭区间;开闭由宿主自行用 Compare 组合)。
---@param value number
---@param lo number
---@param hi number
---@return boolean
function VM:InRange(value, lo, hi)
    return value >= lo and value <= hi
end
--endregion

--region 随机 / 输出 ---------------------------------------------------------

--- 取 [lo, hi] 闭区间随机整数,走 env 唯一随机源(确定性)。
---@param lo number
---@param hi number
---@return number
function VM:RandInt(lo, hi)
    return self._Env:GetRandom():NextInt(lo, hi)
end

--- 发语义事件到事件通道(ctx.events;未接入时 no-op)。args 应为纯数据。
---@param eventType any
---@param args table|nil
function VM:Emit(eventType, args)
    local events = self._ExecContext and self._ExecContext.events
    if events and events.Emit then
        events:Emit(eventType, args)
    end
    -- 未接入事件通道时静默(上层 EventStream 落地后生效)。
end
--endregion

return VM
