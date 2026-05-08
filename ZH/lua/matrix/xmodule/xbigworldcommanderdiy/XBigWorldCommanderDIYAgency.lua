---@class XBigWorldCommanderDIYAgency : XAgency
---@field private _Model XBigWorldCommanderDIYModel
local XBigWorldCommanderDIYAgency = XClass(XAgency, "XBigWorldCommanderDIYAgency")

local Protocol = {
    BigWorldShowRewardFinishRequest = "BigWorldShowRewardFinishRequest",
}

function XBigWorldCommanderDIYAgency:OnInit()
    -- 初始化一些变量
    self._IsFromOpenGuide = false
    self:InitConditionCheck()
end

function XBigWorldCommanderDIYAgency:InitRpc()
    -- 实现服务器事件注册
    self:AddRpc("NotifyBigWorldCommanderFashionBagUpdate", handler(self, self.OnNotifyBigWorldCommanderFashionBagUpdate))
    self:AddRpc("NotifyBigWorldShowReward", handler(self, self.OnNotifyBigWorldShowReward))
end

function XBigWorldCommanderDIYAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XBigWorldCommanderDIYAgency:OnRelease()
    self:ReleaseConditionCheck()
end

function XBigWorldCommanderDIYAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10102001, Handler(self, self.CheckPartUnlockCondition))
end

function XBigWorldCommanderDIYAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end

    XMVCA.XBigWorldService:UnRegisterConditionFunc(10102001)
end

function XBigWorldCommanderDIYAgency:CheckPartUnlockCondition(template)
    if template then
        if not XTool.IsTableEmpty(template.Params) then
            local count = template.Params[1]
            local result = 0
            
            for i = 2, #template.Params do
                local partId = template.Params[i]

                if XTool.IsNumberValid(partId) and self._Model:CheckPartUnlcok(partId) then
                    result = result + 1
                end
            end

            return result >= count
        end

    end

    return false
end

function XBigWorldCommanderDIYAgency:CheckHasNew()
    local configs = self._Model:GetDlcPlayerFashionPartConfigs()
    local recordPartMap = self._Model:GetRecordPartMap()

    if not XTool.IsTableEmpty(configs) then
        for id, config in pairs(configs) do
            if self._Model:GetDlcPlayerFashionPartIsPreviewById(id) and self._Model:CheckPartUnlcok(id) and not recordPartMap[id] then
                return true
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYAgency:OpenMainUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldDIY")
end

function XBigWorldCommanderDIYAgency:UpdateData(res)
    local gender = res.Gender
    local curCommanderOutfitType = res.CurCommanderOutfitType
    local commanderFashionOutfits = res.CommanderFashionOutfits
    local commanderFashionBags = res.CommanderFashionBags
    local isInitDiy = res.CharacterInitialized
    self._Model:SetInitDiy(isInitDiy)
    self._Model:SetGender(gender)
    self._Model:SetCommanderFashionOutfitsData(commanderFashionOutfits, curCommanderOutfitType)
    -- self._Model:UpdateFashion(fashionList)
    self._Model:UpdateUnlockParts(commanderFashionBags)
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:SetLookAtIK(displayController, target, lerpTime)
    if not displayController then
        return
    end
    local modelId, componentId

    local wearDataDict = self._Model:GetCurrentWearDataMap()

    for typeId, wearData in pairs(wearDataDict) do
        if wearData:IsFashion() and wearData:IsWaeredPart() then
            local fashionId = wearData:GetCurrentFashionId()

            if XTool.IsNumberValid(fashionId) then
                modelId = wearData:GetModelId()
                componentId = typeId
                break
            end
        end
    end
    if modelId and componentId then
        displayController:SetLookAtIKWithInfo(modelId, componentId, target, lerpTime)
    end
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:DisableLookAtIK(displayController)
    if not displayController then
        return
    end
    local modelId, componentId

    local wearDataDict = self._Model:GetCurrentWearDataMap()

    for typeId, wearData in pairs(wearDataDict) do
        if wearData:IsFashion() and wearData:IsWaeredPart() then
            local fashionId = wearData:GetCurrentFashionId()

            if XTool.IsNumberValid(fashionId) then
                modelId = wearData:GetModelId()
                componentId = typeId
                break
            end
        end
    end
    if modelId and componentId then
        displayController:DisableLookAtIK(modelId, componentId)
    end
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadCurrentModel(displayController, camera, parent, ikTarget)
    if not displayController then
        return
    end

    local modelId, isExist, fashionId
    local wearDatas = self._Model:GetCurrentWearDataMap()
    local wearData = wearDatas[XEnumConst.PlayerFashion.PartType.Fashion]
    if wearData and wearData:IsFashion() and wearData:IsWaeredPart() then
        fashionId = wearData:GetCurrentFashionId()
        if XTool.IsNumberValid(fashionId) then
            modelId = wearData:GetModelId()
            if not displayController:IsModelExist(modelId) then
                isExist = false
            else
                isExist = true
            end
        end
    else
        XLog.Error("不存在穿戴数据！！！")
        return modelId, isExist
    end
    if isExist then
        displayController:SetParent(modelId, parent, false)
        displayController:SetModelActive(modelId, true)
    else
        -- 加载模型 主体
        local helper = displayController:GetDisplayHelper()
        local modelInfo = helper.CreateBWCommonModelDisplayInfo(modelId, camera, parent,
            XEnumConst.PlayerFashion.PartType.Fashion, ikTarget)
        modelInfo:InitComponentType(XEnumConst.UiModel.ComponentType.PartCombine)
        displayController:AddModel(modelInfo)

        if XTool.IsNumberValid(fashionId) then
            helper.AddEffectInfos(modelInfo, fashionId)
        end

        -- 加载部位
        self:LoadAllPartModel(displayController, camera, modelId)
        -- 加载材质
        self:LoadMaterials(displayController, modelId)
    end
    return modelId, isExist
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:ForceUpdateCommandant(displayController, camera, parent, ikTarget)
    local modelId, fashionId
    local outfitType = self._Model:GetCurrentOutfitType()
    local wearData = self._Model:GetWearData(XEnumConst.PlayerFashion.PartType.Fashion, outfitType)
    if wearData and wearData:IsFashion() and wearData:IsWaeredPart() then
        fashionId = wearData:GetCurrentFashionId()
        if XTool.IsNumberValid(fashionId) then
            modelId = wearData:GetModelId()
        end
    else
        XLog.Error("不存在穿戴数据！！！")
        return
    end
    -- 加载模型 主体
    local helper = displayController:GetDisplayHelper()
    local modelInfo = helper.CreateBWCommonModelDisplayInfo(modelId, camera, parent,
        XEnumConst.PlayerFashion.PartType.Fashion, ikTarget)
    modelInfo:InitComponentType(XEnumConst.UiModel.ComponentType.PartCombine)
    displayController:DestroyModel(modelId)
    displayController:AddModel(modelInfo)

    if XTool.IsNumberValid(fashionId) then
        helper.AddEffectInfos(modelInfo, fashionId)
    end
    -- 加载部位
    self:LoadAllPartModel(displayController, camera, modelId)
    -- 加载材质
    self:LoadMaterials(displayController, modelId)
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadAllPartModel(displayController, camera, modelId)
    if not displayController or not displayController:IsModelExist(modelId) then
        return
    end
    local model = displayController:GetModelObject(modelId, XEnumConst.PlayerFashion.PartType.Fashion)

    if XTool.UObjIsNil(model) then
        return
    end
    local wearDataMap = self._Model:GetCurrentWearDataMap()
    local urls = {}
    for typeId, wearData in pairs(wearDataMap) do
        -- 已经加载过了
        if displayController:IsModelComponentExist(modelId, typeId) then
            goto continue
        end
        -- 只加载部位
        if wearData:IsFashion() or wearData:IsSuit() then
            goto continue
        end
        if not wearData:IsWaeredPart() then
            goto continue
        end
        local partModelId = wearData:GetModelId()
        if not string.IsNilOrEmpty(partModelId) then
            local modelUrl = XMVCA.XBigWorldResource:GetPartModelUrlByPartId(partModelId)
            urls[#urls + 1] = modelUrl
        end

        ::continue::
    end
    displayController:CombineParts(modelId, XEnumConst.PlayerFashion.PartType.Fashion, urls)
end

---@param displayController XUiModelDisplayController
function XBigWorldCommanderDIYAgency:LoadMaterials(displayController, modelId)
    if not displayController then
        return
    end
    if not displayController:IsModelExist(modelId) then
        return
    end

    local wearDataMap = self._Model:GetCurrentWearDataMap()

    for typeId, wearData in pairs(wearDataMap) do
        if wearData:IsWaeredColor() then
            local materials = wearData:GetColorMaterials()

            if materials then
                for i = 0, materials.Count - 1 do
                    --- 使用了战斗的组合逻辑，所有模型全在主骨架下
                    displayController:SetModelComponentMaterials(modelId, XEnumConst.PlayerFashion.PartType.Fashion,
                        materials[i].PartNodeName, materials[i].MaterialPathList)
                end
            end
        end
    end
end

function XBigWorldCommanderDIYAgency:GetNpcPartModelData(partList)
    local result = {}

    if not XTool.IsTableEmpty(partList) then
        for _, part in ipairs(partList) do
            local partId = part.PartId
            local colorId = part.ColourId
            local partModelId = self:GetCurrentPartModelIdByPartId(partId)

            if not string.IsNilOrEmpty(partModelId) then
                local colorName = ""

                if self._Model:CheckAllowSelectColor(partId) then
                    if not XTool.IsNumberValid(colorId) then
                        colorId = self:GetCurrentDefaultColorIdByPartId(partId)
                    end

                    if XTool.IsNumberValid(colorId) then
                        colorName = self:GetMaterialNameByColorId(colorId)
                    end
                end

                result[partModelId] = colorName
            end
        end
    end

    return result
end

function XBigWorldCommanderDIYAgency:GetColorNameByPartId(partId)
    local colorName = ""

    if self._Model:CheckAllowSelectColor(partId) then
        local colorId = self._Model:GetUsePartColor(partId)

        if XTool.IsNumberValid(colorId) then
            colorName = self:GetMaterialNameByColorId(colorId)
        end
    end

    return colorName
end

function XBigWorldCommanderDIYAgency:GetPartListByGender(gender)
    local result = {}
    local wearDataMap = self._Model:GetCurrentWearDataMap()

    for typeId, wearData in pairs(wearDataMap) do
        if not wearData:IsFashion() and not wearData:IsSuit() and wearData:IsWaeredPart() then
            table.insert(result, wearData:ToData(gender))
        end
    end

    return result
end

function XBigWorldCommanderDIYAgency:GetNpcPartDataByGender(gender)
    local partList = self:GetPartListByGender(gender)

    return {
        PartList = partList
    }
end

function XBigWorldCommanderDIYAgency:GetNpcPartData()
    return self:GetNpcPartDataByGender(self._Model:GetGender())
end

function XBigWorldCommanderDIYAgency:SetCurrentGender(value)
    self._Model:SetGender(value)
end

function XBigWorldCommanderDIYAgency:GetCurrentGender()
    return self._Model:GetGender()
end

function XBigWorldCommanderDIYAgency:GetCurrentPartModelIdByPartId(partId)
    local resId = self:GetCurrentResIdByPartId(partId)

    return self._Model:GetDlcPlayerFashionResPartModelIdById(resId)
end

function XBigWorldCommanderDIYAgency:GetPartModelIdByPartId(partId, gender)
    local resId = self:GetResIdByPartId(partId, gender)
    return self._Model:GetDlcPlayerFashionResPartModelIdById(resId)
end

function XBigWorldCommanderDIYAgency:GetCurrentDefaultColorIdByPartId(partId)
    local resId = self:GetCurrentResIdByPartId(partId)

    return self._Model:GetDlcPlayerFashionResDefaultColorIdById(resId)
end

function XBigWorldCommanderDIYAgency:GetCurrentResIdByPartId(partId)
    return self:GetResIdByPartId(partId)
end

function XBigWorldCommanderDIYAgency:GetResIdByPartId(partId, gender)
    return self._Model:GetResIdByPartId(partId, gender)
end

function XBigWorldCommanderDIYAgency:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)
    return self._Model:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)
end

function XBigWorldCommanderDIYAgency:GetCurrentCommandantId()
    return self._Model:GetCurrentCharacterId()
end

function XBigWorldCommanderDIYAgency:GetUseColorByGender(partId, gender)
    return self._Model:GetUsePartColorByGender(partId, gender)
end

function XBigWorldCommanderDIYAgency:GetMaterialNameByColorId(colorId)
    return self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)
end

function XBigWorldCommanderDIYAgency:GetCurrentFashionId()
    local partId = self._Model:GetUsePart(XEnumConst.PlayerFashion.PartType.Fashion)
    local resId = self:GetCurrentResIdByPartId(partId)

    return self:GetFashionIdByResId(resId)
end

function XBigWorldCommanderDIYAgency:GetFashionIdByResId(resId)
    return self._Model:GetDlcPlayerFashionResFashionIdById(resId)
end

--- 获取默认的PartId映射表
---@param outfitType any
function XBigWorldCommanderDIYAgency:GetDefaultPartIdMap(outfitType)
    local result = {}
    for _, typeId in pairs(XEnumConst.PlayerFashion.PartType) do
        local defaultPartId = self:GetTypeDefaultPartId(typeId, outfitType)
        result[typeId] = defaultPartId
    end
    return result
end

function XBigWorldCommanderDIYAgency:GetTypeDefaultPartId(typeId, outfitType)
    return self._Model:GetTypeDefaultPartId(typeId, outfitType)
end

function XBigWorldCommanderDIYAgency:GetPartDefaultColorId(partId)
    return self:GetCurrentDefaultColorIdByPartId(partId) or 0
end

function XBigWorldCommanderDIYAgency:CheckTypeRequired(typeId)
    return self._Model:GetDlcPlayerFashionTypeIsRequiredByTypeId(typeId)
end

function XBigWorldCommanderDIYAgency:CheckTypeFashion(typeId)
    return self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(typeId)
end

function XBigWorldCommanderDIYAgency:CheckTypeSuit(typeId)
    return self._Model:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId)
end

function XBigWorldCommanderDIYAgency:CheckPartSuit(partId)
    return self._Model:GetDlcPlayerFashionPartIsSuitPartById(partId)
end

function XBigWorldCommanderDIYAgency:GetPartIsSuit(partId)
    return self._Model:GetDlcPlayerFashionPartTypeIdById(partId) == XEnumConst.PlayerFashion.PartType.Suit
end

function XBigWorldCommanderDIYAgency:GetPartTypeId(partId)
    return self._Model:GetDlcPlayerFashionPartTypeIdById(partId)
end

function XBigWorldCommanderDIYAgency:GetSuitPartIds(partId)
    if self:CheckPartSuit(partId) then
        return table.empty
    end
    return self._Model:GetDlcPlayerFashionPartPartsById(partId)
end

function XBigWorldCommanderDIYAgency:GetDlcPlayerFashionPartResIdById(partId, gender)
    return self._Model:GetDlcPlayerFashionPartResIdById(partId)[gender]
end

function XBigWorldCommanderDIYAgency:CheckCurrentAllowSelectColor(partId)
    local gender = self._Model:GetValidGender()

    return self._Model:CheckAllowSelectColor(partId, gender)
end

function XBigWorldCommanderDIYAgency:CheckColorIsInColorGroup(partId, color)
    local gender = self._Model:GetValidGender()

    return self._Model:CheckColorIsInColorGroup(partId, gender, color)
end

function XBigWorldCommanderDIYAgency:GetPartPriority(partId)
    return self._Model:GetDlcPlayerFashionPartPriorityById(partId) or 0
end

function XBigWorldCommanderDIYAgency:GetPartGoodsIcon(partId)
    return self._Model:GetPartGoodsIcon(partId) or ""
end

function XBigWorldCommanderDIYAgency:GetPartGoodsName(partId)
    return self._Model:GetPartGoodsName(partId) or ""
end

function XBigWorldCommanderDIYAgency:GetDlcPlayerFashionResDefaultColorIdById(resId)
    return self._Model:GetDlcPlayerFashionResDefaultColorIdById(resId) or 0
end

function XBigWorldCommanderDIYAgency:GetPartItemCount(partId)
    if self._Model:CheckPartUnlcok(partId) then
        return 1
    end

    return 0
end

function XBigWorldCommanderDIYAgency:GetDlcPlayerFashionPartConfigById(partId)
    return self._Model:GetDlcPlayerFashionPartConfigById(partId) or {}
end

function XBigWorldCommanderDIYAgency:GetDlcPlayerFashionPreviewConfigs(previewId)
    return self._Model:GetDlcPlayerFashionPreviewConfigs(previewId)
end

function XBigWorldCommanderDIYAgency:GetPartItemName(partId)
    return self._Model:GetDlcPlayerFashionPartNameById(partId) or ""
end

function XBigWorldCommanderDIYAgency:GetPartItemQuality(partId)
    return self._Model:GetDlcPlayerFashionPartQualityById(partId) or 3
end

function XBigWorldCommanderDIYAgency:GetPartItemIcon(partId)
    local resId = self._Model:GetResIdByPartId(partId)

    local itemIcon = self._Model:GetPartItemIcon(partId)
    if not string.IsNilOrEmpty(itemIcon) then
        return itemIcon
    end

    if XTool.IsNumberValid(resId) then
        return self._Model:GetDlcPlayerFashionResIconById(resId)
    end

    return ""
end

function XBigWorldCommanderDIYAgency:GetPartItemBigIcon(partId)
    local resId = self._Model:GetResIdByPartId(partId)

    if XTool.IsNumberValid(resId) then
        return self._Model:GetDlcPlayerFashionResBigIconById(resId)
    end

    return ""
end

function XBigWorldCommanderDIYAgency:GetPartItemDescription(partId)
    return self._Model:GetDlcPlayerFashionPartDescriptionById(partId) or ""
end

function XBigWorldCommanderDIYAgency:GetPartItemWorldDescription(partId)
    return self._Model:GetDlcPlayerFashionPartWorldDescriptionById(partId) or ""
end

function XBigWorldCommanderDIYAgency:GetPartItemParams(templateId)
    if not XTool.IsNumberValid(templateId) then
        XLog.Error("显示的道具数据TemplateId为空！")
        return
    end

    return {
        RewardType = XRewardManager.XRewardType.BWDIYPart,
        TemplateId = templateId,
        Name = self:GetPartItemName(templateId),
        Icon = self:GetPartItemIcon(templateId),
        BigIcon = self:GetPartItemBigIcon(templateId),
        Quality = self:GetPartItemQuality(templateId),
        Priority = self:GetPartPriority(templateId),
        WorldDesc = self:GetPartItemWorldDescription(templateId),
        Description = self:GetPartItemDescription(templateId),
        ShopIcon = self:GetPartGoodsIcon(templateId),
        CharacterIcon = self:GetPartGoodsIcon(templateId),
        GoodsName = self:GetPartGoodsName(templateId),
    }
end

function XBigWorldCommanderDIYAgency:OnNotifyBigWorldCommanderFashionBagUpdate(data)
    self._Model:UpdateUnlockParts(data.DlcFashionBags)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_COMMANDER_DIY_BACKPACK_UPDATE)
end

function XBigWorldCommanderDIYAgency:OnNotifyBigWorldShowReward(data)
    self._Model:UpdateDelayRewardGoods(data.RewardGoodsList)
end

function XBigWorldCommanderDIYAgency:FinishDelayRewardGoods()
    --直接清理奖励数据，不需要等待服务器返回
    self._Model:ClearDelayRewardGoods()
    XNetwork.Call(Protocol.BigWorldShowRewardFinishRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XBigWorldCommanderDIYAgency:GetDelayRewardGoodsList()
    return self._Model:GetDelayRewardGoods()
end

function XBigWorldCommanderDIYAgency:IsFromOpenGuide()
    return self._IsFromOpenGuide
end

function XBigWorldCommanderDIYAgency:SetFromOpenGuide(value)
    self._IsFromOpenGuide = value
end

function XBigWorldCommanderDIYAgency:GetWearDataMap(outfitType)
    return self._Model:GetWearDataMap(outfitType)
end

return XBigWorldCommanderDIYAgency
