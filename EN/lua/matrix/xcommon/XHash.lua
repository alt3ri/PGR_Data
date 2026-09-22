--- 封装的哈希表
--- 内部用紧凑列表索引管理值，支持一次循环清空、按连续索引遍历
---@class XHash 
local XHash = XClass(nil, "XHash")

function XHash:Ctor()
    self._Value2Index = {}
    self._Index2Value = {}
    
    self._Count = 0
end

function XHash:Count()
    return self._Count
end

function XHash:GetByIndex(index)
    return self._Index2Value[index]
end

function XHash:Add(value)
    if not value or self._Value2Index[value] then
        -- 有值跳过
        return
    end
    
    -- 记录双向映射
    local index = self._Count + 1
    
    self._Value2Index[value] = index
    self._Index2Value[index] = value
    
    self._Count = self._Count + 1
end

function XHash:Remove(value)
    if not self._Value2Index[value] then
        -- 无值跳过
        return
    end
    
    -- 获取移除的位置
    local index = self._Value2Index[value]
    
    -- 获取Index表末尾元素
    local lastValue = self._Index2Value[self._Count]
    
    -- 用末尾元素覆盖待移除的元素，这样在移除元素的同时，保证index的连续性
    if index ~= self._Count then
        self._Index2Value[index] = lastValue
        self._Value2Index[lastValue] = index
    end

    self._Value2Index[value] = nil
    self._Index2Value[self._Count] = nil
    
    self._Count = self._Count - 1
end

function XHash:IsExist(value)
    return self._Value2Index[value] and true or false
end

function XHash:Clear()
    for i = self._Count, 1, -1 do
        local value = self._Index2Value[i]
        
        self._Value2Index[value] = nil
        self._Index2Value[i] = nil
    end

    self._Count = 0
end

return XHash