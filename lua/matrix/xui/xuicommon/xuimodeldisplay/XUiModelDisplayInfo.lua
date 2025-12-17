---@class XUiModelDisplayInfo
local XUiModelDisplayInfo = XClass(nil, "XUiModelDisplayInfo")

function XUiModelDisplayInfo:Ctor(modelId)
    self.Key = ""
    self.ModelId = ""
    self.ModelUrl = ""
    self.ControllerUrl = ""
    self.Parent = false
    self.ComponentId = 0
    self.ComponentType = XEnumConst.UiModel.ComponentType.Base
    self.IsActive = true
    ---@type XUiModelInfoBase[]
    self.Infos = {}
    ---@type XUiModelDataBase[]
    self.ModelDatas = {}
end

function XUiModelDisplayInfo:IsEmpty()
    return string.IsNilOrEmpty(self.ModelId) or string.IsNilOrEmpty(self.Key)
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitKey(key)
    self.Key = key or ""

    return self
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitModelKey(modelId)
    self:InitModelId(modelId)

    return self:InitKey(modelId)
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitModelId(modelId)
    self.ModelId = modelId or ""

    return self
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitModel(modelUrl, controllerUrl)
    self.ModelUrl = modelUrl or ""
    self.ControllerUrl = controllerUrl or ""

    return self
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitParent(parent)
    self.Parent = parent or false

    return self
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitComponentId(componentId)
    self.ComponentId = componentId or 0

    return self
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitComponentType(componentType)
    self.ComponentType = componentType or XEnumConst.UiModel.ComponentType.Base

    return self
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitComponent(componentId, componentType)
    self:InitComponentType(componentType)
    
    return self:InitComponentId(componentId)
end

---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:InitActive(isActive)
    self.IsActive = isActive or false

    return self
end

---@param modelData XUiModelDataBase
---@return XUiModelDisplayInfo
function XUiModelDisplayInfo:AddModelData(modelData)
    if modelData and not modelData:IsEmpty() then
        table.insert(self.ModelDatas, modelData)
    end

    return self
end

---@param info XUiModelInfoBase
function XUiModelDisplayInfo:AddInfo(info)
    if info and not info:IsEmpty() then
        table.insert(self.Infos, info)
    end
end

---@param helper XUiModelDisplayHelper
function XUiModelDisplayInfo:InjectComponent(component, helper)
    if not component then
        return
    end

    if not XTool.IsTableEmpty(self.ModelDatas) then
        for _, modelData in pairs(self.ModelDatas) do
            if not modelData:IsEmpty() and modelData:IsCompatibility(self.ComponentType, helper) then
                modelData:InjectComponent(component)
            end
        end
    end
end

---@param controller XUiModelDisplayController
function XUiModelDisplayInfo:InjectController(controller)
    if not XTool.IsTableEmpty(self.Infos) then
        for _, info in pairs(self.Infos) do
            if not info:IsEmpty() then
                info:InitModelController(controller, self)
            end
        end
    end
end

function XUiModelDisplayInfo:GetInfoByType(infoType)
    for _, info in pairs(self.Infos) do
        if info:GetInfoType() == infoType then
            return info
        end
    end
end

return XUiModelDisplayInfo
