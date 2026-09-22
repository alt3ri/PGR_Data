--- STEFramework 2.0 列表容器属性
---
--- 角色:一个字段持有有序列表(如装备区、背包)。VM 经容器协议操作,不认具体语义。
---
--- 容器协议(VM 的 PropGet/PropSet/PropLen/PropAppend 转交至此):
---       GetByKey(index) / SetByKey(index, value) / Len() / Append(value)。
---
--- 确定性:列表天然有序;元素 value 应为标量。
--- 事务:写方法首行 _BeforeWrite,事务态首次改即记快照,可回滚。
---
--- require('STEVM/Data/Property/PropertyList')
local PropertyBase = require('STEVM/Data/Property/PropertyBase')

---@class PropertyList : PropertyBase
---@field _List any[] 有序元素数组(下标 1..n)
local PropertyList = XClass(PropertyBase, 'PropertyList')

--- 构造。
---@param ownScopeId any
---@param ownEnv table
function PropertyList:Ctor(ownScopeId, ownEnv)
    -- 父类 Ctor 已存 ownScopeId/ownEnv。
    self._List = self._OwnEnv:GetPoolListSnap()
end

--region 容器协议 ------------------------------------------------------------

--- 读一个下标的值(越界返回 nil)。纯读。
---@param index number 1..n
---@return any
function PropertyList:GetByKey(index)
    return self._List[index]
end

--- 写一个下标的值(要求 index 在 1..n 内,不做自动扩展;追加用 Append)。事务态首次改即记快照。
---@param index number
---@param value any
function PropertyList:SetByKey(index, value)
    assert(type(index) == 'number', 'PropertyList:SetByKey index 必须为 number')
    assert(index >= 1 and index <= #self._List,
        'PropertyList:SetByKey index 越界:' .. tostring(index) .. '(长度 ' .. #self._List .. ')')
    self:_BeforeWrite()
    self._List[index] = value
end

--- 长度。纯读。
---@return number
function PropertyList:Len()
    return #self._List
end

--- 是否包含某值。纯读。
---@param value any
---@return boolean
function PropertyList:Contains(value)
    for i = 1, #self._List do
        if self._List[i] == value then
            return true
        end
    end
    return false
end

--- 取所有下标(1..n 有序数组),与字典容器的键枚举口径一致。纯读。
---@return number[]
function PropertyList:GetSortedKeys()
    local keys = {}
    for i = 1, #self._List do
        keys[i] = i
    end
    return keys
end

--- 追加到末尾。事务态首次改即记快照。
---@param value any
function PropertyList:Append(value)
    self:_BeforeWrite()
    self._List[#self._List + 1] = value
end

--- 移除中间元素，并保持列表连续
function PropertyList:RemoveByKey(index)
    self:_BeforeWrite()
    table.remove(self._List, index)
end

--- 移除中间元素，并保持列表连续
function PropertyList:RemoveValue(value)
    self:_BeforeWrite()

    if not XTool.IsTableEmpty(self._List) then
        for i, v in ipairs(self._List) do
            if v == value then
                table.remove(self._List, i)
                break
            end
        end
    end
end

---清空列表
function PropertyList:Clear()
    self:_BeforeWrite()
    self._OwnEnv:ReturnPoolListSnap(self._List)
    self._List = self._OwnEnv:GetPoolListSnap()
end

--endregion

--- 释放:回池 _List。幂等。
function PropertyList:Release()
    if self._List then
        self._OwnEnv:ReturnPoolListSnap(self._List)
        self._List = nil
    end
end

--region 事务快照 ------------------------------------------------------------

--- 快照:拷贝列表（pool'd 数组，直接返回 copy 本身，无外层 wrapper）。
---@return table snap = copy 数组本身
function PropertyList:Snapshot()
    local env = self._OwnEnv
    local copy = env:GetPoolListSnap()
    for i = 1, #self._List do
        copy[i] = self._List[i]
    end
    return copy
end

--- 还原:旧 _List 回池（onRelease 尾部清空），转交 snap → runtime。
---@param snap table = copy 数组本身
function PropertyList:Restore(snap)
    local env = self._OwnEnv
    env:ReturnPoolListSnap(self._List)
    self._List = snap
end

--- 释放快照（覆写基类）。Commit 丢弃 / Rollback Restore 后由 STEEnv 调。
--- Rollback 路径：Restore 已转交 snap→self._List → snap == self._List → no-op。
--- Commit 路径：snap ≠ self._List（仍是 copy）→ 回池。
---@param snap table
function PropertyList:ReleaseSnapshot(snap)
    if snap ~= self._List then
        self._OwnEnv:ReturnPoolListSnap(snap)
    end
end
--endregion

return PropertyList
