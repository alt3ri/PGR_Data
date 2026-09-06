local PropertyTags = require('STEVM/Data/Property/PropertyTags')
local OrderedUtil  = require('STEVM/Tools/OrderedUtil')

--- STE框架的基本单位，聚合一组Property对象
---@class STEVM.Entity 
---@field _Id any 唯一 id
---@field _Env STEEnv 归属 env(提供 GetScope 等)
---@field Fields table<any, PropertyBase> 字段表:key -> Property
---@field Tags PropertyTags 内置标签集
local Entity = XClass(nil, 'Entity')

--- 构造。仅存储,不自注册(注册交给上层)。
---@param id string | number 唯一 id
---@param env table 归属 env(需提供 GetScope(scopeId)->Entity|nil)
function Entity:Ctor(id, env)
    self._Id = id
    self._Env = env
    self.Fields = {}
    -- 内置标签集:归属本 Entity。Tags 自身也是一个 Property(PropertyTags)。
    self.Tags = PropertyTags.New(id, env)
    
    -- 内部直接注册自身
    self._Env:RegisterScope(self)
end

--- 取 id。
---@return any
function Entity:GetId()
    return self._Id
end

--- 取归属 env。
---@return table
function Entity:GetEnv()
    return self._Env
end

--- 取内置标签集。
---@return PropertyTags
function Entity:GetTags()
    return self.Tags
end

--- 取字段(不存在返回 nil)。纯读。
---@param key any
---@return PropertyBase|nil
function Entity:GetField(key)
    if key == nil then
        return nil
    end
    return self.Fields[key]
end

--- 是否存在字段。纯读。
---@param key any
---@return boolean
function Entity:HasField(key)
    if key == nil then
        return false
    end
    return self.Fields[key] ~= nil
end

--- 取所有字段 key,按全序升序排成新数组(确定性)。纯读。
---@param ref_list table 允许外部传入table对象，作为key填充数组，以便对象复用。但table容器的空状态由外部自行保证
---@return any[]
function Entity:GetSortedFields(ref_list)
    return OrderedUtil.SortedKeys(self.Fields, ref_list)
end

--- 释放:遍历释放所有 Field 与 Tags,清空字段表。幂等:重复调用安全。
function Entity:Release()
    -- 读写分离:先取 key 快照再遍历,避免边遍历边删字典。
    local keys = OrderedUtil.SortedKeys(self.Fields)
    
    for i = 1, #keys do
        local key = keys[i]
        local field = self.Fields[key]
        if field and field.Release then
            field:Release()
        end

        self.Fields[key] = nil
    end
    
    if self.Tags and self.Tags.Release then
        self.Tags:Release()
    end
end

return Entity
