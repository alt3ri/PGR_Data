--- STEFramework 2.0 字典容器属性
---
--- 角色:一个字段持有「键→值」字典(如球:颜色→数量)。VM 经容器协议操作,不认具体语义。
---
--- 容器协议(VM 的 PropGet/PropSet/PropLen 转交至此):
---       GetByKey(key) / SetByKey(key, value) / Len();字典无 Append。
---
--- 确定性:GetSortedKeys 走 OrderedUtil 全序;元素 value 应为标量。
--- 事务:写方法首行 _BeforeWrite,事务态首次改即记快照,可回滚。
---
--- require('STEVM/Data/Property/PropertyDict')
local PropertyBase = require('STEVM/Data/Property/PropertyBase')
local OrderedUtil  = require('STEVM/Tools/OrderedUtil')

---@class PropertyDict : PropertyBase
---@field _Dict table<any, any> 键 -> 值
local PropertyDict = XClass(PropertyBase, 'PropertyDict')

--- 构造。
---@param ownScopeId any
---@param ownEnv table
function PropertyDict:Ctor(ownScopeId, ownEnv)
    -- 父类 Ctor 已存 ownScopeId/ownEnv。
    self._Dict = self._OwnEnv:GetPoolDictSnap()
end

--region 容器协议 ------------------------------------------------------------

--- 读一个键的值(不存在返回 nil)。纯读。
---@param key any
---@return any
function PropertyDict:GetByKey(key)
    return self._Dict[key]
end

--- 写一个键的值。事务态首次改即记快照。
---@param key any
---@param value any
function PropertyDict:SetByKey(key, value)
    assert(key ~= nil, 'PropertyDict:SetByKey key 不可为 nil')
    self:_BeforeWrite()
    self._Dict[key] = value
end

--- 当前键数量。纯读。
---@return number
function PropertyDict:Len()
    local n = 0
    for _ in pairs(self._Dict) do
        n = n + 1
    end
    return n
end

--- 是否包含某键。纯读。
---@param key any
---@return boolean
function PropertyDict:ContainsKey(key)
    return self._Dict[key] ~= nil
end
--endregion

--- 取所有键,按全序升序排成新数组(确定性)。纯读。
---@return any[]
function PropertyDict:GetSortedKeys()
    return OrderedUtil.SortedKeys(self._Dict)
end

---清空列表
function PropertyDict:Clear()
    self:_BeforeWrite()
    self._OwnEnv:ReturnPoolDictSnap(self._Dict)
    self._Dict = self._OwnEnv:GetPoolDictSnap()
end

--- 释放:回池 _Dict。幂等。
function PropertyDict:Release()
    if self._Dict then
        self._OwnEnv:ReturnPoolDictSnap(self._Dict)
        self._Dict = nil
    end
end

--region 事务快照 ------------------------------------------------------------

--- 快照:拷贝字典（pool'd dict，直接返回 copy 本身，无外层 wrapper）。
---@return table snap = copy dict 本身
function PropertyDict:Snapshot()
    local env = self._OwnEnv
    local copy = env:GetPoolDictSnap()
    for k, v in pairs(self._Dict) do
        copy[k] = v
    end
    return copy
end

--- 还原:旧 _Dict 回池（onRelease key-collector 清空），转交 snap → runtime。
---@param snap table = copy dict 本身
function PropertyDict:Restore(snap)
    local env = self._OwnEnv
    env:ReturnPoolDictSnap(self._Dict)
    self._Dict = snap
end

--- 释放快照（覆写基类）。Commit 丢弃 / Rollback Restore 后由 STEEnv 调。
---@param snap table
function PropertyDict:ReleaseSnapshot(snap)
    if snap ~= self._Dict then
        self._OwnEnv:ReturnPoolDictSnap(snap)
    end
end
--endregion

return PropertyDict
