--- 双向队列
---@class XDeque
---@field __StartIndex @指向队首元素
---@field __EndIndex @指向队尾元素
local XDeque = XClass(nil, "XDeque")

function XDeque:Ctor(initialCapacity)
    self.InitialCapacity = initialCapacity
    self:Clear()
end

--region State

function XDeque:IsEmpty()
    return self.__StartIndex > self.__EndIndex
end

function XDeque:Count()
    return self.__EndIndex - self.__StartIndex + 1
end

function XDeque:Total()
    return self.__EndIndex
end

--endregion

--region Ops

function XDeque:Clear()
    self.__Container = {}
    self.__StartIndex = 1
    self.__EndIndex = 0
    if self.InitialCapacity then
        for i = 1, self.InitialCapacity do
            table.insert(self.__Container, false)  -- 插入占位元素
        end
    end
end

function XDeque:ClearUnUsed()
    local temp = {}
    for i = self.__StartIndex, self.__EndIndex do
        temp[#temp + 1] = self.__Container[i]
    end
    self.__StartIndex = 1
    self.__Container = temp
    self.__EndIndex = #temp
end

function XDeque:Enqueue(element)
    if not element then return end

    local endIndex = self.__EndIndex + 1
    self.__EndIndex = endIndex
    self.__Container[endIndex] = element
end

function XDeque:EnqueueFront(element)
    self.__Container[self.__StartIndex - 1] = element
    self.__StartIndex = self.__StartIndex - 1
end

function XDeque:Dequeue()
    if self:IsEmpty() then
        self:Clear()
        return
    end

    local startIndex = self.__StartIndex
    local element = self.__Container[startIndex]

    self.__StartIndex = startIndex + 1
    self.__Container[startIndex] = nil

    return element
end

function XDeque:Peek()
    return self.__Container[self.__StartIndex]
end

function XDeque:PopTail()
    if self:IsEmpty() then
        self:Clear()
        return
    end

    local endIndex = self.__EndIndex
    local element = self.__Container[endIndex]

    self.__EndIndex = endIndex - 1
    self.__Container[endIndex] = nil

    return element
end

function XDeque:PeekTail()
    return self.__Container[self.__EndIndex]
end

function XDeque:SetErgodicFun(fun)
    self.__ErgodicFun = fun
end

function XDeque:Ergodic(fun)
    for i = self.__StartIndex, self.__EndIndex, 1 do
        local item = self.__Container[i]
        if item then
            if fun then
                fun(item, i)
            elseif self.__ErgodicFun then
                self.__ErgodicFun(item, i)
            end
        end
    end
end

--endregion

return XDeque