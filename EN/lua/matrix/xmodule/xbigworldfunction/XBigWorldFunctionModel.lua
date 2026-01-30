local XBWFunctionControllerGroup = require("XModule/XBigWorldFunction/XCommon/XBWFunctionControllerGroup")

---@class XBigWorldFunctionModel : XModel
local XBigWorldFunctionModel = XClass(XModel, "XBigWorldFunctionModel")

function XBigWorldFunctionModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<number, XBWFunctionControllerGroup>
    self._ShieldControllerMap = {}
    
    self._CurrentShieldFunction = {}
end

function XBigWorldFunctionModel:ClearPrivate()
end

function XBigWorldFunctionModel:ResetAll()
    self._ShieldControllerMap = {}

    self:ClearCurrentShield()
end

function XBigWorldFunctionModel:AddCurrentShield(functionType)
    self._CurrentShieldFunction[functionType] = true
end

function XBigWorldFunctionModel:SetShieldState(functionType, value)
    self._CurrentShieldFunction[functionType] = value
end

function XBigWorldFunctionModel:RemoveCurrentShield(functionType)
    self._CurrentShieldFunction[functionType] = nil
end

function XBigWorldFunctionModel:ClearCurrentShield()
    if XTool.IsTableEmpty(self._CurrentShieldFunction) then
        return
    end
    for k, _ in pairs(self._CurrentShieldFunction) do
        self._CurrentShieldFunction[k] = nil
    end
end

function XBigWorldFunctionModel:CheckCurrentShield(functionType)
    return self._CurrentShieldFunction[functionType]
end

function XBigWorldFunctionModel:IsSetShield(functionType)
    return self._CurrentShieldFunction[functionType] ~= nil
end

---@param functionType number
---@param controller XBWFunctionController
function XBigWorldFunctionModel:RegisterFunctionController(functionType, controller)
    local controllerGroup = self._ShieldControllerMap[functionType]

    if not controllerGroup then
        controllerGroup = XBWFunctionControllerGroup.New(functionType)
        self._ShieldControllerMap[functionType] = controllerGroup
    end

    controllerGroup:AddController(controller)
end

function XBigWorldFunctionModel:RegisterFunctionControllerByMethod(functionType, target, method)
    local controllerGroup = self._ShieldControllerMap[functionType]

    if not controllerGroup then
        controllerGroup = XBWFunctionControllerGroup.New(functionType)
        self._ShieldControllerMap[functionType] = controllerGroup
    end

    controllerGroup:AddControllerByMethod(target, method)
end

---@param functionType number
---@param controller XBWFunctionController
function XBigWorldFunctionModel:RemoveFunctionController(functionType, controller)
    local controllerGroup = self._ShieldControllerMap[functionType]

    if controllerGroup then
        controllerGroup:RemoveController(controller)
    end
end

function XBigWorldFunctionModel:RemoveFunctionControllerByMethod(functionType, target, method)
    local controllerGroup = self._ShieldControllerMap[functionType]

    if controllerGroup then
        controllerGroup:RemoveControllerByMethod(target, method)
    end
end

---@return XBWFunctionControllerGroup
function XBigWorldFunctionModel:GetFunctionControllerGroup(functionType)
    return self._ShieldControllerMap[functionType]
end

return XBigWorldFunctionModel
