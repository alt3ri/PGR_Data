local PropertySingle = require('STEVM/Data/Property/PropertySingle')

local STEEnum       = require('STEVM/STEEnum')
local ValueOp        = require('STEVM/Engine/ValueOp')

local ValChangeType = STEEnum.ValChangeType

---@class ModifiedNumOp 运算队列中的一项(有序,按加入顺序)
---@field op number STEEnum.ValChangeType（Add/Subtract/Multiply/Divide/Set）
---@field value number 运算数
---@field sourceId any 来源 id（用于整源删除）

--- 可临时修正的数值属性
---@class PropertyModifiedNum : PropertySingle
---@field _Ops ModifiedNumOp[] 有序运算队列(按加入顺序;同源可有多条)
---@field _Min number|nil 常量下界;nil 表示无下界
---@field _Max number|nil 常量上界;nil 表示无上界
local PropertyModifiedNum = XClass(PropertySingle, 'PropertyModifiedNum')

--- 校验一个 min/max 限值:仅接受 number 或 nil(2.0 删除跨属性间接引用)。
---@param v any
---@param who string 报错用字段名
local function assertBound(v, who)
    assert(v == nil or type(v) == 'number',
        'PropertyModifiedNum ' .. who .. ' 仅接受常量 number 或 nil,实际 ' .. type(v))
end

---@param originVal number|nil 作为 base 的原始值,缺省 0
---@param minVal number|nil 常量下界,缺省 nil(无界)
---@param maxVal number|nil 常量上界,缺省 nil(无界)
function PropertyModifiedNum:Ctor(ownScopeId, ownEnv, originVal, minVal, maxVal)
    -- 父类 PropertySingle.Ctor 已由 XClass.New 自动调用,设置 _OriginVal(=base)。
    -- min/max 仅常量(2.0):构造期即 assert,杜绝旧版 {scopeId,fieldKey} 间接引用进入。
    assertBound(minVal, 'minVal')
    assertBound(maxVal, 'maxVal')
    self._Ops = self._OwnEnv:GetPoolListSnap()
    self._Min = minVal
    self._Max = maxVal
end

--region modifier 增删 -------------------------------------------------------

--- 追加一个修正到有序运算队列(按加入顺序;同源多次 = 多个条目)。
--- 顺序敏感:[Add 5, Multiply 2] 与 [Multiply 2, Add 5] 结果不同(见 GetFinalVal)。
--- 幂等说明:本接口是「追加」语义,非幂等去重;要清掉某源用 RemoveModifierBySource。
---@param op number STEEnum.ValChangeType(Add/Subtract/Multiply/Divide/Set)
---@param value number 运算数
---@param sourceId any 来源 id(必须非 nil,用于整源删除)
function PropertyModifiedNum:AddModifier(op, value, sourceId)
    -- 校验与除零拒绝放在记录之前:被拒的运算不算改动,不应进事务日志。
    assert(sourceId ~= nil, 'PropertyModifiedNum:AddModifier sourceId 不可为 nil')
    assert(type(value) == 'number', 'PropertyModifiedNum:AddModifier value 必须为 number')

    -- 除零入队即拒绝:value==0 的 Divide 会在读期产生 inf/nan 污染,在入队点就拦下。
    if op == ValChangeType.Divide and value == 0 then
        XLog.Error('PropertyModifiedNum:AddModifier Divide value 为 0,拒绝入队,sourceId=' .. tostring(sourceId))
        return
    end

    self:_BeforeWrite()
    -- 追加到队尾(保留加入顺序)；op-table 走 env 池复用（零 GC，onRelease 清 op/value/sourceId）。
    local item = self._OwnEnv:GetPoolModOp()
    item.op = op
    item.value = value
    item.sourceId = sourceId
    self._Ops[#self._Ops + 1] = item
end

--- 整源删除:移除运算队列中该 sourceId 的全部条目,其余条目保持原有顺序。
--- 幂等:源不存在时无副作用。
---@param sourceId any
function PropertyModifiedNum:RemoveModifierBySource(sourceId)
    if sourceId == nil then
        return
    end
    self:_BeforeWrite()
    -- 倒序 remove:从后往前删,既移除该源全部条目,又不打乱其余条目的相对顺序。
    local env = self._OwnEnv
    local ops = self._Ops
    for i = #ops, 1, -1 do
        if ops[i].sourceId == sourceId then
            env:ReturnPoolModOp(table.remove(ops, i))
        end
    end
end
--endregion

--region min/max -------------------------------------------------------------

--- 设置取值范围。min/max 仅接受常量 number 或 nil(2.0 删除间接引用)。
---@param minVal number|nil
---@param maxVal number|nil
function PropertyModifiedNum:SetRange(minVal, maxVal)
    self:_BeforeWrite()
    assertBound(minVal, 'minVal')
    assertBound(maxVal, 'maxVal')
    self._Min = minVal
    self._Max = maxVal
end

--- 取下界(常量或 nil)。纯读。
---@return number|nil
function PropertyModifiedNum:GetMinVal()
    return self._Min
end

--- 取上界(常量或 nil)。纯读。
---@return number|nil
function PropertyModifiedNum:GetMaxVal()
    return self._Max
end
--endregion

--region 求值 ----------------------------------------------------------------

--- 计算最终值:running = base，按 _Ops 顺序逐项 ValueOp.Apply，再夹到常量 _Min/_Max。
--- 纯读(DESIGN C1/C2):不修改 self,夹紧只作用于返回值,绝不回写 base。
--- 顺序敏感(纯数学):队列是有序的,加/乘/除不满足交换律,顺序影响结果。
---@return number
function PropertyModifiedNum:GetFinalVal()
    -- 正向计算:从 base 起,按加入顺序逐项施加运算(运算语义复用 ValueOp,全框架单一来源)。
    local running = self._OriginVal
    local ops = self._Ops
    for i = 1, #ops do
        local item = ops[i]
        local nextVal = ValueOp.Apply(running, item.op, item.value)
        -- 入队点已拒绝除零,正常不会得到 nil;防御性兜底:非法运算跳过该项,不污染 running。
        if nextVal ~= nil then
            running = nextVal
        end
    end

    -- 夹紧:常量 min/max,存在才夹。先夹下界再夹上界(两界都存在且 min>max 时上界优先)。
    -- 只夹返回值,不回写 base。
    local result = running
    if self._Min ~= nil and result < self._Min then
        result = self._Min
    end
    if self._Max ~= nil and result > self._Max then
        result = self._Max
    end
    return result
end
--endregion

--- 快照(覆写父类):深拷 base + 运算队列逐项 + 常量 min/max(事务工具)。
--- op-table 走 ModOp 池，ops 数组走 ListSnap 池，wrapper 走 DictSnap 池。逐项 distinct 实例。
---@return table snap = wrapper（{origin, ops, min, max}，pool'd）
function PropertyModifiedNum:Snapshot()
    local env = self._OwnEnv
    local ops = self._Ops
    local copy = env:GetPoolListSnap()
    for i = 1, #ops do
        local item = ops[i]
        local opSnap = env:GetPoolModOp()
        opSnap.op = item.op
        opSnap.value = item.value
        opSnap.sourceId = item.sourceId
        copy[i] = opSnap
    end
    local snap = env:GetPoolDictSnap()
    snap.origin = self._OriginVal
    snap.ops = copy
    snap.min = self._Min
    snap.max = self._Max
    return snap
end

--- 还原(覆写父类):写回 base、接管 snap.ops、还原常量 min/max。
---@param snap table = wrapper
function PropertyModifiedNum:Restore(snap)
    self._OriginVal = snap.origin
    local env = self._OwnEnv
    -- 旧 _Ops op-table 回 ModOp 池 + ops 数组回 ListSnap 池
    local oldOps = self._Ops
    for i = 1, #oldOps do
        env:ReturnPoolModOp(oldOps[i])
    end
    env:ReturnPoolListSnap(oldOps)
    -- 直接接管 snap.ops（所有权转移）：snap 副本与运行期本就 distinct 实例，
    -- 转交 runtime 后 snap.ops 置 nil 断引用，无共享（隔离不变量保）。
    self._Ops = snap.ops
    snap.ops = nil
    self._Min = snap.min
    self._Max = snap.max
end

--- 释放快照内 pool'd 资源（覆写基类）。Commit 丢弃 / Rollback Restore 后由 STEEnv 调。
--- 释放顺序：op-tables→ModOp + ops 数组→ListSnap + wrapper→DictSnap。
--- Rollback 路径：snap.ops nil（Restore 转交了）→ 跳过 ops，仅回 wrapper。
---@param snap table = wrapper
function PropertyModifiedNum:ReleaseSnapshot(snap)
    local env = self._OwnEnv
    local ops = snap.ops
    if ops then
        for i = 1, #ops do
            env:ReturnPoolModOp(ops[i])
        end
        env:ReturnPoolListSnap(ops)
    end
    env:ReturnPoolDictSnap(snap)
end

--- 释放:回池 _Ops op-tables(ModOp) + _Ops 数组(ListSnap)。幂等。
function PropertyModifiedNum:Release()
    local env = self._OwnEnv
    if self._Ops then
        for i = 1, #self._Ops do
            env:ReturnPoolModOp(self._Ops[i])
        end
        env:ReturnPoolListSnap(self._Ops)
        self._Ops = nil
    end
end

return PropertyModifiedNum
