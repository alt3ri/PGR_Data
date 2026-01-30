local XUiModelDisplayController = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayController")

---@class XUiBigWorldDIYModelHelper
local XUiBigWorldDIYModelHelper = XClass(nil, "XUiBigWorldDIYModelHelper")

function XUiBigWorldDIYModelHelper:Ctor(modelGameObject, drag)
    self._Drag = drag
    self._CurrentModelId = {}
    self._CurrentEntryAnimation = false

    self._TweenTimer = false

    ---@type XUiModelDisplayController
    self._ModelContorller = XUiModelDisplayController.New(modelGameObject, true)
    self._CameraControl = modelGameObject:GetComponent(typeof(CS.XUiComponent.XUiStateControl))

    self._MaleModelRoot = modelGameObject.transform:FindTransform("PanelRoleCommandantMan")
    self._FemaleModelRoot = modelGameObject.transform:FindTransform("PanelRoleCommandantWoman")
    self._NearMaleCamera = modelGameObject.transform:FindTransform("VCameraManNear")
    self._NearFemaleCamera = modelGameObject.transform:FindTransform("VCameraWomanNear")
    self._MaleChangeEffect = modelGameObject.transform:FindTransform("PanelRoleEffectMan")
    self._FemaleChangeEffect = modelGameObject.transform:FindTransform("PanelRoleEffectWoman")

    self._NearCamera = modelGameObject.transform:FindTransform("UiNearCamera")

    self._OriginalMaleCameraPosY = self._NearMaleCamera.transform.localPosition.y
    self._OriginalFemaleCameraPosY = self._NearFemaleCamera.transform.localPosition.y

    self._EulerAnglesYRecord = {
        [XEnumConst.PlayerFashion.Gender.Male] = 180,
        [XEnumConst.PlayerFashion.Gender.Female] = 180
    }
end

---@param entitys XBWCommanderDIYPartEntity[]
function XUiBigWorldDIYModelHelper:LoadModel(gender, entitys)
    if self:IsGenderModelLoaded(gender) then
        return
    end

    if not XTool.IsTableEmpty(entitys) then
        local fashionEntity = self:_ExtractingFashionEntity(entitys)

        if not fashionEntity or fashionEntity:IsNil() then
            return
        end

        local modelId = self:_LoadFashionModel(fashionEntity, gender)

        if string.IsNilOrEmpty(modelId) then
            return
        end
        
        local partEntitys = self:_ExtractingPartEntitys(entitys)
        
        self:_LoadMaterials(modelId, fashionEntity, gender)
        self:_LoadPartModels(modelId, entitys, gender, fashionEntity:GetTypeId())
        self:_BindModelDragTarget(gender)
    end
end

---@param entitys XBWCommanderDIYPartEntity[]
function XUiBigWorldDIYModelHelper:ChangeModel(gender, entitys, isUnloadOthers)
    if self:IsGenderModelLoaded(gender) then
        self:UnloadModel(gender)
    end

    if isUnloadOthers then
        self:UnloadOtherModel(gender)
    end

    self:LoadModel(gender, entitys)
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYModelHelper:ChangePartModel(gender, entity, fashionTypeId)
    if not self:IsGenderModelLoaded(gender) then
        return
    end
    if entity:IsFashion() then
        return
    end

    local modelId = self:GetModelId(gender)
    local typeId = entity:GetTypeId()

    if self:IsPartModelExist(modelId, typeId) then
        self:UnloadPartModel(gender, typeId)
    end

    self:_LoadPartModel(modelId, entity, gender, fashionTypeId)
    self:_LoadMaterials(modelId, entity, gender)
end

---@param entity XBWCommanderDIYColorEntity
function XUiBigWorldDIYModelHelper:ChangeMaterials(gender, entity)
    if not self:IsGenderModelLoaded(gender) then
        return
    end

    local partEntity = entity:GetPartEntity()

    if partEntity and not partEntity:IsNil() then
        local modelId = self:GetModelId(gender)
        local materials = entity:GetMaterialConfigs()
        local typeId = partEntity:GetTypeId()

        for _, material in pairs(materials) do
            self._ModelContorller:SetModelComponentMaterials(modelId, typeId, material.PartNodeName,
                material.MaterialPathList)
        end
    end
end

function XUiBigWorldDIYModelHelper:ChangeCamera(key)
    self._CameraControl:ChangeState(key)
end

function XUiBigWorldDIYModelHelper:MoveNearCamera(gender, offset)
    local camera = self:_ExtractingNearCamera(gender)
    local originalPos = self:_ExtractingNearCameraOriginalPosition(gender)
    local pos = camera.transform.localPosition

    offset = originalPos - offset
    camera.transform.localPosition = Vector3(pos.x, offset, pos.z)
end

function XUiBigWorldDIYModelHelper:PlayEffect(gender)
    local isCurrentMale = gender == XEnumConst.PlayerFashion.Gender.Male

    if self._MaleChangeEffect then
        self._MaleChangeEffect.gameObject:SetActiveEx(not isCurrentMale)
        self._MaleChangeEffect.gameObject:SetActiveEx(isCurrentMale)
    end
    if self._FemaleChangeEffect then
        self._FemaleChangeEffect.gameObject:SetActiveEx(isCurrentMale)
        self._FemaleChangeEffect.gameObject:SetActiveEx(not isCurrentMale)
    end
end

function XUiBigWorldDIYModelHelper:PlayAnimation(gender, animation, normalizedTime, layer)
    if not self:IsGenderModelLoaded(gender) then
        return
    end

    self._ModelContorller:PlayAnimation(self:GetModelId(gender), animation, normalizedTime, layer)
end

function XUiBigWorldDIYModelHelper:PlayChangePartAnimation(gender, entryAnimation, typeId)
    if not self:IsGenderModelLoaded(gender) then
        return
    end

    local modelId = self:GetModelId(gender)
    local animator = self._ModelContorller:GetModelAnimator(modelId, XEnumConst.PlayerFashion.PartType.Fashion)

    if not XTool.UObjIsNil(animator) then
        if self._CurrentEntryAnimation then
            if string.IsNilOrEmpty(entryAnimation) then
                self:PlayAnimation(gender, self._CurrentEntryAnimation .. "_End")
                animator:SetInteger("ChangeParam", 0)
                self._CurrentEntryAnimation = false
            else
                if entryAnimation ~= self._CurrentEntryAnimation then
                    self:PlayAnimation(gender, self._CurrentEntryAnimation .. "_End")
                    self._CurrentEntryAnimation = entryAnimation
                    animator:SetInteger("ChangeParam", typeId)
                end
            end
        else
            if not string.IsNilOrEmpty(entryAnimation) then
                self:PlayAnimation(gender, entryAnimation .. "_Start")
                self._CurrentEntryAnimation = entryAnimation
            else
                self:PlayStandAnimation(gender)
            end
        end
    end
end

function XUiBigWorldDIYModelHelper:PlayAppearAnimation(gender)
    self:PlayAnimation(gender, "UIAppear01", 0)
end

function XUiBigWorldDIYModelHelper:PlayStandAnimation(gender)
    self:PlayAnimation(gender, "UIStand01", 0)
end

function XUiBigWorldDIYModelHelper:PlayChangeSexAnimation(gender)
    if not self:IsGenderModelLoaded(gender) then
        return
    end

    if self._CurrentEntryAnimation then
        self:PlayAnimation(gender, self._CurrentEntryAnimation .. "_Start")
    else
        self:PlayStandAnimation(gender)
    end
end

function XUiBigWorldDIYModelHelper:PlayResettingAnimation(gender)
    if not self:IsGenderModelLoaded(gender) then
        return
    end

    if self._CurrentEntryAnimation then
        self:PlayAnimation(gender, self._CurrentEntryAnimation .. "_Start", 1)
    else
        self:PlayAnimation(gender, "UIStand01")
    end
end

---@param tweenPlayer XLuaUi
function XUiBigWorldDIYModelHelper:PlayRotationTween(gender, tweenPlayer)
    if not self:IsGenderModelLoaded(gender) then
        return
    end

    local target = self:_ExtractingModelRoot(gender)

    if self._TweenTimer then
        tweenPlayer:StopTweener(self._TweenTimer)
        self._TweenTimer = false
    end
    if not XTool.UObjIsNil(target) then
        local eulerAnglesY = target.transform.eulerAngles.y
        local offset = eulerAnglesY - 180

        self._TweenTimer = tweenPlayer:Tween(0.3, function(time)
            target.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, eulerAnglesY - offset * time, 0)
        end, function()
            self._TweenTimer = false
            target.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 180, 0)
        end, function(time)
            return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, time)
        end)
    end
end

function XUiBigWorldDIYModelHelper:IsModelExist(modelId)
    return self._ModelContorller:IsModelExist(modelId)
end

function XUiBigWorldDIYModelHelper:IsPartModelExist(modelId, typeId)
    return self:IsModelExist(modelId) and self._ModelContorller:IsModelComponentExist(modelId, typeId)
end

function XUiBigWorldDIYModelHelper:IsModelLoaded(gender, modelId)
    return self:GetModelId(gender) == modelId
end

function XUiBigWorldDIYModelHelper:IsGenderModelLoaded(gender)
    return not string.IsNilOrEmpty(self:GetModelId(gender))
end

function XUiBigWorldDIYModelHelper:GetModelId(gender)
    return self._CurrentModelId[gender] or ""
end

function XUiBigWorldDIYModelHelper:UnloadOtherModel(retainGender)
    for otherGender, modelId in pairs(self._CurrentModelId) do
        if not string.IsNilOrEmpty(modelId) and otherGender ~= retainGender then
            self:UnloadModel(otherGender)
        end
    end
end

function XUiBigWorldDIYModelHelper:UnloadModel(gender)
    if self:IsGenderModelLoaded(gender) then
        local modelId = self:GetModelId(gender)
        local target = self:_ExtractingModelRoot(gender)

        if not XTool.UObjIsNil(target) then
            self._EulerAnglesYRecord[gender] = target.transform.eulerAngles.y
        end
        self._ModelContorller:DestroyModel(modelId)
        self._CurrentModelId[gender] = nil
    end
end

function XUiBigWorldDIYModelHelper:UnloadPartModel(gender, typeId)
    if self:IsGenderModelLoaded(gender) then
        local modelId = self:GetModelId(gender)

        self._ModelContorller:DestroyModelComponent(modelId, typeId)
    end
end

function XUiBigWorldDIYModelHelper:Release()
    local maleTarget = self:_ExtractingModelRoot(XEnumConst.PlayerFashion.Gender.Male)
    local femaleTarget = self:_ExtractingModelRoot(XEnumConst.PlayerFashion.Gender.Female)

    if not XTool.UObjIsNil(maleTarget) then
        self._EulerAnglesYRecord[XEnumConst.PlayerFashion.Gender.Male] = maleTarget.transform.eulerAngles.y
    end
    if not XTool.UObjIsNil(femaleTarget) then
        self._EulerAnglesYRecord[XEnumConst.PlayerFashion.Gender.Female] = femaleTarget.transform.eulerAngles.y
    end

    self._ModelContorller:DestroyAllModel()
    self._CurrentModelId = {}
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYModelHelper:_LoadFashionModel(entity, gender)
    local modelId = entity:GetFashionModelIdByGender(gender)
    local typeId = entity:GetTypeId()

    if not self:IsModelExist(modelId) then
        local parent = self:_ExtractingModelRoot(gender)
        local helper = self._ModelContorller:GetDisplayHelper()
        local modelInfo = helper.CreateBWCommonModelDisplayInfo(modelId, self._NearCamera, parent, typeId)

        self._ModelContorller:AddModel(modelInfo)
    end

    self._CurrentModelId[gender] = modelId

    return modelId
end

---@param entitys XBWCommanderDIYPartEntity[]
function XUiBigWorldDIYModelHelper:_LoadPartModels(modelId, entitys, gender, fashionTypeId)
    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            self:_LoadPartModel(modelId, entity, gender, fashionTypeId)
            self:_LoadMaterials(modelId, entity, gender)
        end
    end
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYModelHelper:_LoadPartModel(modelId, entity, gender, fashionTypeId)
    local partTypeId = entity:GetTypeId()
    local partModelId = entity:GetPartModelIdByGender(gender)

    if self:IsModelExist(modelId) and not self:IsPartModelExist(modelId, partTypeId) then
        local parent = self:_ExtractingModelRoot(gender)
        local modelUrl = XMVCA.XBigWorldResource:GetPartModelUrlByPartId(partModelId)
        local modelBone = self._ModelContorller:GetModelObject(modelId, fashionTypeId)
        local helper = self._ModelContorller:GetDisplayHelper()
        local boneData = helper.CreateBoneData(modelBone)
        local modelInfo = helper.CreateBWModelDisplayInfo(modelId, modelUrl, nil, self._NearCamera, parent, partTypeId)

        modelInfo:InitComponentType(XEnumConst.UiModel.ComponentType.Materials)
        modelInfo:AddModelData(boneData)

        self._ModelContorller:AddModelComponent(modelInfo)
    end
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYModelHelper:_LoadMaterials(modelId, entity, gender)
    local typeId = entity:GetTypeId()
    local materials = entity:GetUseMaterialConfigsByGender(gender)

    if not XTool.IsTableEmpty(materials) then
        for _, material in pairs(materials) do
            self._ModelContorller:SetModelComponentMaterials(modelId, typeId, material.PartNodeName,
                material.MaterialPathList)
        end
    end
end

function XUiBigWorldDIYModelHelper:_BindModelDragTarget(gender)
    local target = self:_ExtractingModelRoot(gender)

    target.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, self._EulerAnglesYRecord[gender] or 180, 0)
    if not XTool.UObjIsNil(target) then
        self._Drag.Target = target.transform
    end
end

function XUiBigWorldDIYModelHelper:_ExtractingModelRoot(gender)
    if gender == XEnumConst.PlayerFashion.Gender.Male then
        return self._MaleModelRoot
    end

    return self._FemaleModelRoot
end

function XUiBigWorldDIYModelHelper:_ExtractingNearCamera(gender)
    if gender == XEnumConst.PlayerFashion.Gender.Male then
        return self._NearMaleCamera
    end

    return self._NearFemaleCamera
end

function XUiBigWorldDIYModelHelper:_ExtractingNearCameraOriginalPosition(gender)
    if gender == XEnumConst.PlayerFashion.Gender.Male then
        return self._OriginalMaleCameraPosY
    end

    return self._OriginalFemaleCameraPosY
end

---@param entitys XBWCommanderDIYPartEntity[]
---@return XBWCommanderDIYPartEntity
function XUiBigWorldDIYModelHelper:_ExtractingFashionEntity(entitys)
    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            if not entity:IsNil() and entity:IsFashion() then
                return entity
            end
        end
    end

    return nil
end

---@param entitys XBWCommanderDIYPartEntity[]
---@return XBWCommanderDIYPartEntity[]
function XUiBigWorldDIYModelHelper:_ExtractingPartEntitys(entitys)
    local result = {}

    if not XTool.IsTableEmpty(entitys) then
        for _, entity in pairs(entitys) do
            if not entity:IsNil() and not entity:IsFashion() then
                table.insert(result, entity)
            end
        end
    end

    return result
end

return XUiBigWorldDIYModelHelper
