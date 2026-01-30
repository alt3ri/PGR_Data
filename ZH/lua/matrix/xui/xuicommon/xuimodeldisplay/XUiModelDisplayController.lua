local XUiModelDisplayHelper = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayHelper")

---@class XUiModelDisplayController
---@field Controller XUiComponent.XModelDisplay.XUiModelDisplayController
local XUiModelDisplayController = XClass(nil, "XUiModelDisplayController")

function XUiModelDisplayController:Ctor(modelRoot, showShadow, fixLight)
    if XTool.UObjIsNil(modelRoot) then
        XLog.Error("ModelRoot Is Nil!")
        return
    end

    self.GameObject = modelRoot.gameObject
    self.Transform = modelRoot.transform
    self.Controller = self.GameObject:GetComponent(typeof(CS.XUiComponent.XModelDisplay.XUiModelDisplayController))

    if XTool.UObjIsNil(self.Controller) then
        self.Controller = self.GameObject:AddComponent(typeof(CS.XUiComponent.XModelDisplay.XUiModelDisplayController))
    end

    self.ShowShadow = showShadow
    -- 单个模型才能使用，耗性能
    self.FixLight = fixLight

    self._ModelInfos = {}

    self.Controller:SetShadow(showShadow, fixLight)
end

---@return XUiModelDisplayHelper
function XUiModelDisplayController:GetDisplayHelper()
    return XUiModelDisplayHelper
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:AddModel(modelInfo)
    if not modelInfo or modelInfo:IsEmpty() then
        return false
    end

    local helper = self:GetDisplayHelper()
    local componentType = helper.ConvertComponentType(modelInfo.ComponentType)
    local parent = modelInfo.Parent or self.Transform
    self:SetModelActive(modelInfo.Key, true)
    local isSuccess = self.Controller:AddModelDisplay(componentType, modelInfo.Key, modelInfo.ComponentId,
        modelInfo.ModelUrl, modelInfo.ControllerUrl, parent)

    if isSuccess then
        self:_AfterModelLoaded(modelInfo)
    end

    return isSuccess
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:AddOrSetParentModel(modelInfo)
    local res = self:AddModel(modelInfo)
    if res then
        return
    end
    self:SetParent(modelInfo.Key, modelInfo.Parent, false)
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:AddOrUpdateModel(modelInfo)
    if not modelInfo or modelInfo:IsEmpty() then
        return false
    end

    if self:IsModelExist(modelInfo.Key) then
        self:ChangeModelComponent(modelInfo)
    else
        return self:AddModel(modelInfo)
    end

    return true
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:AddModelComponent(modelInfo)
    if not modelInfo or modelInfo:IsEmpty() then
        return false
    end

    local helper = self:GetDisplayHelper()
    local componentType = helper.ConvertComponentType(modelInfo.ComponentType)
    local parent = modelInfo.Parent or self.Transform
    local isSuccess = self.Controller:AddModelComponent(componentType, modelInfo.Key, modelInfo.ComponentId,
        modelInfo.ModelUrl, modelInfo.ControllerUrl, parent)

    if isSuccess then
        self:_AfterModelLoaded(modelInfo)
    end

    return isSuccess
end

function XUiModelDisplayController:GetModelObject(id, componentId)
    return self.Controller:GetModelObject(id, componentId)
end

function XUiModelDisplayController:GetModelAnimator(id, componentId)
    return self.Controller:GetModelAnimator(id, componentId)
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:ChangeModelComponent(modelInfo)
    if not modelInfo or modelInfo:IsEmpty() then
        return false
    end

    local helper = self:GetDisplayHelper()
    local componentType = helper.ConvertComponentType(modelInfo.ComponentType)
    local parent = modelInfo.Parent or self.Transform
    local isSuccess = self.Controller:ChangeModelComponent(componentType, modelInfo.Key, modelInfo.ComponentId,
        modelInfo.ModelUrl, modelInfo.ControllerUrl, parent)

    if isSuccess then
        self:_AfterModelLoaded(modelInfo)
    end

    return isSuccess
end

function XUiModelDisplayController:SetModelComponentActive(id, componentId, isActive)
    local modelInfo = self:GetModelInfo(id, componentId)

    if modelInfo and not modelInfo:IsEmpty() then
        modelInfo.IsActive = isActive
        self.Controller:SetModelComponentActive(id, componentId, isActive)
    end
end

function XUiModelDisplayController:SetModelActive(id, isActive)
    local modelInfos = self:GetModelInfos(id)

    if not XTool.IsTableEmpty(modelInfos) then
        for _, modelInfo in pairs(modelInfos) do
            modelInfo.IsActive = isActive
        end

        self.Controller:SetModelActive(id, isActive)
    end
end

function XUiModelDisplayController:HideAllModel()
    self.Controller:HideAllModel()

    if not XTool.IsTableEmpty(self._ModelInfos) then
        for _, modelInfos in pairs(self._ModelInfos) do
            if not XTool.IsTableEmpty(modelInfos) then
                for _, modelInfo in pairs(modelInfos) do
                    modelInfo.IsActive = false
                end
            end
        end
    end
end

function XUiModelDisplayController:IsModelExist(id)
    return self.Controller:IsModelExist(id)
end

function XUiModelDisplayController:IsModelComponentExist(id, componentId)
    return self.Controller:IsModelComponentExist(id, componentId)
end

function XUiModelDisplayController:PlayAnimation(id, animationName, normalizedTime, layer)
    self.Controller:PlayAnimation(id, animationName, layer or -1, normalizedTime or 0)
end

function XUiModelDisplayController:SetModelComponentMaterials(id, componentId, objectName, materialsUrl)
    self.Controller:SetModelComponentMaterials(id, componentId, objectName, materialsUrl)
end

function XUiModelDisplayController:GetModelComponent(id, componentId)
    return self.Controller:GetModelComponent(id, componentId)
end

---@return XUiModelDisplayInfo
function XUiModelDisplayController:GetModelInfo(key, componentId)
    if not self._ModelInfos[key] then
        return nil
    end

    return self._ModelInfos[key][componentId]
end

---@return XUiModelDisplayInfo[]
function XUiModelDisplayController:GetModelInfos(key)
    return self._ModelInfos[key]
end

function XUiModelDisplayController:DestroyAllModel()
    self.Controller:DestroyAllModel()
    self._ModelInfos = {}
end

function XUiModelDisplayController:DestroyModel(id)
    self.Controller:DestroyModel(id)
    self._ModelInfos[id] = nil
end

function XUiModelDisplayController:DestroyModelComponent(modelId, componentId)
    self.Controller:DestroyModelComponent(modelId, componentId)
    self:_RemoveModelInfo(modelId, componentId)
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:_AddModelInfo(modelInfo)
    if not modelInfo or modelInfo:IsEmpty() then
        return
    end

    if not self._ModelInfos[modelInfo.Key] then
        self._ModelInfos[modelInfo.Key] = {}
    end

    self._ModelInfos[modelInfo.Key][modelInfo.ComponentId] = modelInfo
end

function XUiModelDisplayController:_RemoveModelInfo(key, componentId)
    if not self._ModelInfos[key] then
        return
    end

    self._ModelInfos[key][componentId] = nil
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:_InjectComponentData(modelInfo)
    if not modelInfo or modelInfo:IsEmpty() then
        return
    end

    local helper = self:GetDisplayHelper()
    local component = self:GetModelComponent(modelInfo.Key, modelInfo.ComponentId)

    modelInfo:InjectComponent(component, helper)
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayController:_AfterModelLoaded(modelInfo)
    self:_InjectComponentData(modelInfo)
    self:_AddModelInfo(modelInfo)
    modelInfo:InjectController(self)
    self:SetModelComponentActive(modelInfo.Key, modelInfo.ComponentId, modelInfo.IsActive)
end

function XUiModelDisplayController:SetLookAtIKWithInfo(id, componentId, target, lerpTime)
    local modelInfo = self:GetModelInfo(id, componentId)
    if not modelInfo then
        return
    end
    ---@type XUiModelLookAtIKInfo
    local ikInfo = modelInfo:GetInfoByType(XMVCA.XBigWorldCommon.ModelInfoType.LookAtIK)
    if not ikInfo then
        ikInfo = self:GetDisplayHelper().CreateLookAtIKInfo(target)
        modelInfo:AddInfo(ikInfo)
    else
        ikInfo.Target = target
    end
    ikInfo:SetLerpTime(lerpTime)
    ikInfo:InitModelController(self, modelInfo)
end

function XUiModelDisplayController:SetLookAtIKTarget(id, componentId, target)
    self.Controller:SetLookAtIKTarget(id, componentId, target)
end

function XUiModelDisplayController:SetLookAtIKWeight(id, componentId, weight,  bodyWeight, headWeight, eyesWeight, clampWeight, clampWeightHead, clampWeightEyes)
    self.Controller:SetLookAtIKWeight(id, componentId, weight,  bodyWeight, headWeight, eyesWeight, clampWeight, clampWeightHead, clampWeightEyes)
end

function XUiModelDisplayController:DisableLookAtIK(id, componentId)
    self.Controller:DisableLookAtIK(id, componentId)
end

function XUiModelDisplayController:SetParent(id, parent, worldPositionStays)
    if worldPositionStays ~= false then
        worldPositionStays = true
    end
    self.Controller:SetParent(id, parent, worldPositionStays)
end

function XUiModelDisplayController:CombineParts(id, componentId, urls)
    self.Controller:CombineParts(id, componentId, urls)
end

return XUiModelDisplayController
