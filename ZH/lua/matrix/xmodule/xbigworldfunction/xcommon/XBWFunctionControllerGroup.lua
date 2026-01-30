local XBWFunctionController = require("XModule/XBigWorldFunction/XCommon/XBWFunctionController")
local XBWFunctionControlData = require("XModule/XBigWorldFunction/XData/XBWFunctionControlData")

---@class XBWFunctionControllerGroup
local XBWFunctionControllerGroup = XClass(nil, "XBWFunctionControllerGroup")

function XBWFunctionControllerGroup:Ctor(functionType)
    self._FunctionType = functionType
    ---@type XBWFunctionControlData
    self._ControlData = XBWFunctionControlData.New(functionType)
    ---@type XBWFunctionController[]
    self._ControlGroup = {}
end

function XBWFunctionControllerGroup:IsNil()
    return not XTool.IsNumberValid(self._FunctionType)
end

function XBWFunctionControllerGroup:IsEmpty()
    if self:IsNil() then
        return true
    end

    return XTool.IsTableEmpty(self._ControlGroup)
end

---@param controller XBWFunctionController
function XBWFunctionControllerGroup:AddController(controller)
    if not self:IsNil() then
        if not controller:IsEmpty() then
            table.insert(self._ControlGroup, controller)
        end
    end
end

function XBWFunctionControllerGroup:AddControllerByMethod(target, method)
    if not self:IsNil() then
        self:AddController(XBWFunctionController.New(self._FunctionType, target, method))
    end
end

---@param controller XBWFunctionController
function XBWFunctionControllerGroup:RemoveController(removeController)
    if not self:IsEmpty() then
        for i, controller in ipairs(self._ControlGroup) do
            if controller == removeController then
                table.remove(self._ControlGroup, i)
                break
            end
        end
    end
end

---@param controller XBWFunctionController
function XBWFunctionControllerGroup:RemoveControllerByMethod(target, method)
    if not self:IsEmpty() then
        for i, controller in ipairs(self._ControlGroup) do
            if controller:IsEqual(self._FunctionType, target, method) then
                table.remove(self._ControlGroup, i)
                break
            end
        end
    end
end

---@param data XBWFunctionControlData
function XBWFunctionControllerGroup:Control(data)
    if not self:IsEmpty() then
        self._ControlData:SetArgs(data)
        for _, controller in ipairs(self._ControlGroup) do
            controller:Control(self._ControlData)
        end
    end
end

function XBWFunctionControllerGroup:Clear()
    self._ControlGroup = {}
end

return XBWFunctionControllerGroup
