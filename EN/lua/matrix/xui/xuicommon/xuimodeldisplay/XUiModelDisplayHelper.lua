local XUiModelAnimationNodeVisibility = require("XUi/XUiCommon/XUiModelDisplay/XData/XUiModelAnimationNodeVisibility")
local XUiModelCamera = require("XUi/XUiCommon/XUiModelDisplay/XData/XUiModelCamera")
local XUiModelBone = require("XUi/XUiCommon/XUiModelDisplay/XData/XUiModelBone")
local XUiModelDisplayInfo = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayInfo")
local XUiModelAnimationIKInfo = require("XUi/XUiCommon/XUiModelDisplay/XInfo/XUiModelAnimationIKInfo")
local XUiModelLookAtIKInfo = require("XUi/XUiCommon/XUiModelDisplay/XInfo/XUiModelLookAtIKInfo")
local XUiModelEffectInfo = require("XUi/XUiCommon/XUiModelDisplay/XInfo/XUiModelEffectInfo")

---@class XUiModelDisplayHelper
local XUiModelDisplayHelper = XClass(nil, "XUiModelDisplayHelper")

---@return XUiModelDisplayInfo
function XUiModelDisplayHelper.CreateModelDisplayInfo()
    return XUiModelDisplayInfo.New()
end

---@return XUiModelDisplayInfo
function XUiModelDisplayHelper.CreateBWModelDisplayInfo(modelId, modelUrl, controller, camera, parent, componentId, ikTarget)
    local modelInfo = XUiModelDisplayHelper.CreateModelDisplayInfo()
    local nodeVisibilityData = XUiModelDisplayHelper.CreateAnimationNodeVisibilityByBWModelId(modelId)
    local cameraData = XUiModelDisplayHelper.CreateCameraData(camera)
    local ikInfo = XUiModelDisplayHelper.CreateLookAtIKInfo(ikTarget)

    modelInfo:InitModelKey(modelId):InitModel(modelUrl, controller):InitParent(parent)
    modelInfo:InitComponent(componentId or 0, XEnumConst.UiModel.ComponentType.AnimationNodeVisibility)
    modelInfo:AddModelData(nodeVisibilityData)
    modelInfo:AddModelData(cameraData)
    modelInfo:AddInfo(ikInfo)

    return modelInfo
end

---@return XUiModelDisplayInfo
function XUiModelDisplayHelper.CreateBWCommonModelDisplayInfo(modelId, camera, parent, componentId, ikTarget)
    local modelInfo = XUiModelDisplayHelper.CreateModelDisplayInfo()
    local nodeVisibilityData = XUiModelDisplayHelper.CreateAnimationNodeVisibilityByBWModelId(modelId)
    local cameraData = XUiModelDisplayHelper.CreateCameraData(camera)
    local modelUrl = XMVCA.XBigWorldResource:GetModelUrl(modelId)
    local controller = XMVCA.XBigWorldResource:GetModelControllerUrl(modelId)
    local ikInfo = XUiModelDisplayHelper.CreateLookAtIKInfo(ikTarget)

    modelInfo:InitModelKey(modelId):InitModel(modelUrl, controller):InitParent(parent)
    modelInfo:InitComponent(componentId or 0, XEnumConst.UiModel.ComponentType.AnimationNodeVisibility)
    modelInfo:AddModelData(nodeVisibilityData)
    modelInfo:AddModelData(cameraData)
    modelInfo:AddInfo(ikInfo)

    return modelInfo
end

---@return XUiModelCamera
function XUiModelDisplayHelper.CreateCameraData(camera)
    ---@type XUiModelCamera
    local cameraData = XUiModelCamera.New()

    cameraData:SetCamera(camera)

    return cameraData
end

---@return XUiModelBone
function XUiModelDisplayHelper.CreateBoneData(target)
    ---@type XUiModelBone
    local cameraData = XUiModelBone.New()

    cameraData:SetTarget(target)

    return cameraData
end

---@return XUiModelAnimationNodeVisibility
function XUiModelDisplayHelper.CreateAnimationNodeVisibilityData()
    return XUiModelAnimationNodeVisibility.New()
end

---@return XUiModelAnimationNodeVisibility
function XUiModelDisplayHelper.CreateAnimationNodeVisibilityByBWModelId(modelId)
    local controlData = XMVCA.XBigWorldResource:GetModelControlNodeData(modelId)

    if not controlData then
        return nil
    end

    local nodeVisibilityData = XUiModelDisplayHelper.CreateAnimationNodeVisibilityData()
    local activeNodesMap = controlData:GetActiveNodeMap()
    local unActiveNodesMap = controlData:GetUnActiveNodesMap()

    if not XTool.IsTableEmpty(activeNodesMap) then
        for animationName, nodeNames in pairs(activeNodesMap) do
            if not XTool.IsTableEmpty(nodeNames) then
                for _, nodeName in pairs(nodeNames) do
                    nodeVisibilityData:AddActiveNode(animationName, nodeName)
                end
            end
        end
    end

    if not XTool.IsTableEmpty(unActiveNodesMap) then
        for animationName, nodeNames in pairs(unActiveNodesMap) do
            if not XTool.IsTableEmpty(nodeNames) then
                for _, nodeName in pairs(nodeNames) do
                    nodeVisibilityData:AddUnActiveNode(animationName, nodeName)
                end
            end
        end
    end

    return nodeVisibilityData
end

---@return XUiModelAnimationIKInfo
function XUiModelDisplayHelper.CreateLookAtIKInfo(target)
    if XTool.UObjIsNil(target) then
        return
    end

    ---@type XUiModelLookAtIKInfo
    local info = XUiModelLookAtIKInfo.New()

    info.Target = target

    return info
end

---@return XUiModelAnimationIKInfo
function XUiModelDisplayHelper.CreateAnimationIKInfo(target)
    if XTool.UObjIsNil(target) then
        return
    end

    ---@type XUiModelAnimationIKInfo
    local info = XUiModelAnimationIKInfo.New()

    info.Target = target

    return info
end

---@return XUiModelEffectInfo[]
function XUiModelDisplayHelper.CreateEffectInfos(fashionId)
    local result = {}
    local effectInfos = XMVCA.XBigWorldCharacter:GetCharacterUiEffectInfos(fashionId)

    if not XTool.IsTableEmpty(effectInfos) then
        for _, effectInfo in pairs(effectInfos) do
            local effectCount = effectInfo:GetEffectCount()

            for i = 1, effectCount do
                ---@type XUiModelEffectInfo
                local info = XUiModelEffectInfo.New()

                info.EffectId = effectInfo:GetEffectIdByIndex(i)
                info.EffectUrl = effectInfo:GetEffectPathByIndex(i)
                info.TargetRootName = effectInfo:GetRootName()
                info.TargetAnimation = effectInfo:GetActionId()
                info.IsIgnoreRotate = effectInfo:GetIsIgnoreRotate()
                info.DelayFrame = effectInfo:GetEffectDelayTimeByIndex(i)

                table.insert(result, info)
            end
        end
    end

    return result
end

---@param modelInfo XUiModelDisplayInfo
function XUiModelDisplayHelper.AddEffectInfos(modelInfo, fashionId)
    if not XTool.IsNumberValid(fashionId) then
        return
    end

    local effectInfos = XUiModelDisplayHelper.CreateEffectInfos(fashionId)

    if not XTool.IsTableEmpty(effectInfos) then
        for _, effectInfo in pairs(effectInfos) do
            modelInfo:AddInfo(effectInfo)
        end
    end
end

function XUiModelDisplayHelper.ConvertComponentType(componentType)
    if componentType == XEnumConst.UiModel.ComponentType.Base then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentBase)
    elseif componentType == XEnumConst.UiModel.ComponentType.Materials then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentMaterials)
    elseif componentType == XEnumConst.UiModel.ComponentType.AnimationNodeVisibility then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentActionNodeVisible)
    elseif componentType == XEnumConst.UiModel.ComponentType.Camera then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentCamera)
    elseif componentType == XEnumConst.UiModel.ComponentType.Bone then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentBone)
    elseif componentType == XEnumConst.UiModel.ComponentType.PartCombine then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentPartCombine)
    elseif componentType == XEnumConst.UiModel.ComponentType.Effect then
        return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentEffect)
    end

    XLog.Error("XUiModelDisplayHelper.ConvertComponentType error, componentType = " .. componentType)

    return typeof(CS.XUiComponent.XModelDisplay.XModelComponent.XUiModelComponentBase)
end

--- 如果C#端类型继承有修改，这里也要修改
--- 位运算 : 1 << 当前类型 | 父类型
function XUiModelDisplayHelper.ConvertComponentFlag(componentType)
    local componentEnum = XEnumConst.UiModel.ComponentType

    if componentType == componentEnum.Base then
        return 1 << XEnumConst.UiModel.ComponentType.Base
    elseif componentType == componentEnum.Materials then
        return 1 << componentEnum.Materials | XUiModelDisplayHelper.ConvertComponentFlag(componentEnum.Camera)
    elseif componentType == componentEnum.AnimationNodeVisibility then
        return 1 << componentEnum.AnimationNodeVisibility | XUiModelDisplayHelper.ConvertComponentFlag(componentEnum.Materials)
    elseif componentType == componentEnum.Camera then
        return 1 << componentEnum.Camera | XUiModelDisplayHelper.ConvertComponentFlag(componentEnum.Bone)
    elseif componentType == componentEnum.Bone then
        return 1 << componentEnum.Bone | XUiModelDisplayHelper.ConvertComponentFlag(componentEnum.Base)
    elseif componentType == componentEnum.PartCombine then
        return 1 << componentEnum.PartCombine | XUiModelDisplayHelper.ConvertComponentFlag(componentEnum.AnimationNodeVisibility)
    elseif componentType == componentEnum.Effect then
        return 1 << componentEnum.Effect | XUiModelDisplayHelper.ConvertComponentFlag(componentEnum.Base)
    end

    XLog.Error("XUiModelDisplayHelper.ConvertComponentFlag error, componentType = ".. componentType)

    return 0
end

--- 判断类型是否有继承
function XUiModelDisplayHelper.CheckComponentDerived(componentType, derivedType)
    local componentFlag = XUiModelDisplayHelper.ConvertComponentFlag(componentType)
    local derivedFlag = XUiModelDisplayHelper.ConvertComponentFlag(derivedType)

    return (componentFlag & derivedFlag) == componentFlag
end

return XUiModelDisplayHelper
