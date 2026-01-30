---@class XBWFunctionController
local XBWFunctionController = XClass(nil, "XBWFunctionController")

function XBWFunctionController:Ctor(functionType, target, method)
    self._FunctionType = functionType
    self._Target = target
    self._Method = method
end

function XBWFunctionController:IsEmpty()
    return not XTool.IsNumberValid(self._FunctionType) or not self._Target or not self._Method
end

function XBWFunctionController:IsEqual(functionType, target, method)
    return self._FunctionType == functionType and self._Target == target and self._Method == method
end

---@param data XBWFunctionControlData
function XBWFunctionController:Control(data)
    if not self:IsEmpty() then
        self._Method(self._Target, data)
    end
end

return XBWFunctionController
