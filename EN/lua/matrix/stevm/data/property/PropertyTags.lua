local PropertyBase = require('STEVM/Data/Property/PropertyBase')
local OrderedUtil  = require('STEVM/Tools/OrderedUtil')

--- 标签属性(计数式)
---@class PropertyTags : PropertyBase 
---@field _Tags table<any, number> tag -> 引用计数(恒 > 0;归零即删键)
local PropertyTags = XClass(PropertyBase, 'PropertyTags')

function PropertyTags:Ctor(ownScopeId, ownEnv)
    -- 父类 PropertyBase.Ctor 已由 XClass.New 自动调用(存 ownScopeId/ownEnv)。
    self._Tags = self._OwnEnv:GetPoolDictSnap()
end

--- 增加一个标签的引用计数(+1)。tag 可为任意可比较 key(number/string/...)。
---@param tag any
---@return number count 增加后的计数
function PropertyTags:AddTag(tag)
    assert(tag ~= nil, 'PropertyTags:AddTag tag 不可为 nil')
    self:_BeforeWrite()
    local c = (self._Tags[tag] or 0) + 1
    self._Tags[tag] = c
    return c
end

--- 减少一个标签的引用计数(-1);归零即移除键。
--- 幂等友好:标签不存在或已归零时无副作用,返回 0。
---@param tag any
---@return number count 减少后的计数(0 表示已移除)
function PropertyTags:RemoveTag(tag)
    if tag == nil then
        return 0
    end
    local c = self._Tags[tag]
    if c == nil then
        return 0
    end
    self:_BeforeWrite()
    c = c - 1
    if c <= 0 then
        self._Tags[tag] = nil
        return 0
    end
    self._Tags[tag] = c
    return c
end

--- 是否拥有标签(计数 > 0)。纯读。
---@param tag any
---@return boolean
function PropertyTags:HasTag(tag)
    if tag == nil then
        return false
    end
    return (self._Tags[tag] or 0) > 0
end

--- 取标签的引用计数(无则 0)。纯读。
---@param tag any
---@return number
function PropertyTags:GetTagData(tag)
    if tag == nil then
        return 0
    end
    return self._Tags[tag] or 0
end

--- 取所有标签,按全序升序排成新数组(确定性,规范 A1)。
--- 转移所有权(规范#56):返回副本,调用方可安全持有/修改。
---@return any[]
function PropertyTags:GetSortedTags()
    return OrderedUtil.SortedKeys(self._Tags)
end

---@overload
--- 释放:回池 _Tags。幂等。
function PropertyTags:Release()
    if self._Tags then
        self._OwnEnv:ReturnPoolDictSnap(self._Tags)
        self._Tags = nil
    end
end

---@overload
--- 快照:拷贝标签计数表（pool'd dict，直接返回 copy 本身，无外层 wrapper）。
---@return table snap = copy dict 本身
function PropertyTags:Snapshot()
    local env = self._OwnEnv
    local copy = env:GetPoolDictSnap()
    for tag, count in pairs(self._Tags) do
        copy[tag] = count
    end
    return copy
end

---@overload
--- 还原:旧 _Tags 回池（onRelease key-collector 清空），转交 snap → runtime。
---@param snap table = copy dict 本身
function PropertyTags:Restore(snap)
    local env = self._OwnEnv
    env:ReturnPoolDictSnap(self._Tags)
    self._Tags = snap
end

---@overload
--- 释放快照（覆写基类）。Commit 丢弃 / Rollback Restore 后由 STEEnv 调。
---@param snap table
function PropertyTags:ReleaseSnapshot(snap)
    if snap ~= self._Tags then
        self._OwnEnv:ReturnPoolDictSnap(snap)
    end
end

return PropertyTags
