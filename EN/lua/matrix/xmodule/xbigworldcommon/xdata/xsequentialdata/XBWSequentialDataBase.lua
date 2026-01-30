---@class XBWSequentialDataBase
local XBWSequentialDataBase = XClass(nil, "XBWSequentialDataBase")

function XBWSequentialDataBase:Ctor(id)
    self._Id = id or 0
    self._Behaviors = {}
end

function XBWSequentialDataBase:IsNil()
    return not XTool.IsNumberValid(self:GetId())
end

function XBWSequentialDataBase:GetId()
    return self._Id
end

function XBWSequentialDataBase:AddBehavior(behavior)
    if behavior then
        table.insert(self._Behaviors, behavior)
    end
end

function XBWSequentialDataBase:RemoveBehavior(behavior)
    if behavior then
        for _, value in pairs(self._Behaviors) do
            if value == behavior then
                table.remove(self._Behaviors, value)
                break
            end
        end
    end
end

function XBWSequentialDataBase:Execute(...)
    if not self:IsNil() then
        if not XTool.IsTableEmpty(self._Behaviors) then
            for _, behavior in pairs(self._Behaviors) do
                behavior(self._Id, ...)
            end
        end
    end
end

function XBWSequentialDataBase:Finish()
    self:Clear()
end

function XBWSequentialDataBase:Clear()
    self._Id = 0
    self._Behaviors = {}
end

return XBWSequentialDataBase
