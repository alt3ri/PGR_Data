local XBWCommanderDIYTypeEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYTypeEntity")

---@class XBigWorldCommanderDIYControl : XEntityControl
---@field private _Model XBigWorldCommanderDIYModel
local XBigWorldCommanderDIYControl = XClass(XEntityControl, "XBigWorldCommanderDIYControl")

local Protocol = {
    BigWorldCommanderFashionUpdateRequest = "BigWorldCommanderFashionUpdateRequest"
}

function XBigWorldCommanderDIYControl:OnInit()
    -- 初始化内部变量
    ---@type XBWCommanderDIYTypeEntity[]
    self._TypeEntitys = false

    self._Gender = 0
    ---@type table<number, XBWCommanderDIYWearData>
    self._WearDataMap = {}
    self._CurrentModifiedIndex = self._Model:GetCurrentOutfitType()
end

function XBigWorldCommanderDIYControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldCommanderDIYControl:RemoveAgencyEvent()

end

function XBigWorldCommanderDIYControl:OnRelease()
    self._Gender = 0
    self._WearDataMap = {}
end

-- region Entity

---@return XBWCommanderDIYTypeEntity[]
function XBigWorldCommanderDIYControl:GetTypeEntitys()
    if not self._TypeEntitys then
        local configs = self._Model:GetDlcPlayerFashionTypeConfigs()

        self._TypeEntitys = {}
        for typeId, _ in pairs(configs) do
            table.insert(self._TypeEntitys, self:AddEntity(XBWCommanderDIYTypeEntity, typeId))
        end
        table.sort(self._TypeEntitys, function(entityA, entityB)
            return entityA:GetPriority() > entityB:GetPriority()
        end)
    end

    return self._TypeEntitys
end

---@return XBWCommanderDIYTypeEntity
function XBigWorldCommanderDIYControl:GetSuitTypeEntity()
    local typeEntitys = self:GetTypeEntitys()

    if not XTool.IsTableEmpty(typeEntitys) then
        for _, entity in pairs(typeEntitys) do
            if entity:IsSuit() then
                return entity
            end
        end
    end

    return nil
end

---@return XBWCommanderDIYPartEntity[]
function XBigWorldCommanderDIYControl:GetSuitPartEntitys()
    local typeEntity = self:GetSuitTypeEntity()

    if typeEntity then
        local partEntitys = typeEntity:GetPartEntitys()

        return partEntitys
    end

    return nil
end

---@param typeEntity XBWCommanderDIYTypeEntity
---@param outfitType number
---@return XBWCommanderDIYPartEntity[]
function XBigWorldCommanderDIYControl:GetFilteredDisplayPartEntitys(typeEntity, outfitType)
    -- 按Outfit进行筛选，目前只针对衣装进行筛选

    local entitys = typeEntity:GetDisplayPartEntitys()
    if not typeEntity:IsFashion() then
        return entitys
    end
    local config = self._Model:GetDlcPlayerFashionOutfitConfigById(outfitType)
    local allowedFashionIds = config and config.AllowFashionIds
    if not allowedFashionIds or XTool.IsTableEmpty(allowedFashionIds) then
        return entitys
    end
    if not self._allowedDicts then
        self._allowedDicts = {}
    end
    if not self._allowedDicts[outfitType] then
        local allowedDict = {}
        for _, id in ipairs(allowedFashionIds) do
            allowedDict[id] = true
        end
        self._allowedDicts[outfitType] = allowedDict
    end
    local allowedDict = self._allowedDicts[outfitType]
    for i = #entitys, 1, -1 do
        local ent = entitys[i]
        local fashionId = ent:GetFashionId()
        -- 如果是套装，修正一下检查的FashionId
        if ent:IsSuit() then
            local partIds = self._Model:GetDlcPlayerFashionPartPartsById(ent:GetPartId())
            for _, partId in ipairs(partIds) do
                local typeId = self._Model:GetDlcPlayerFashionPartTypeIdById(partId)
                if typeId == XEnumConst.PlayerFashion.PartType.Fashion then
                    local gender = self._Model:GetValidGender(self:GetCurrentGender())
                    local resId = self._Model:GetResIdByPartId(partId, gender)
                    fashionId = self._Model:GetDlcPlayerFashionResFashionIdById(resId)
                    break
                end
            end
        end
        if not allowedDict[fashionId] then
            table.remove(entitys, i)
        end
    end
    return entitys
end

function XBigWorldCommanderDIYControl:GetDlcPlayerFashionOutfitConfigById(outfitType)
    return self._Model:GetDlcPlayerFashionOutfitConfigById(outfitType)
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:CheckAnyPartEntityIsUse(entity)
    if entity then
        if entity:IsTemporary() then
            return self:CheckEmptyPartEntityIsUse(entity)
        else
            return self:CheckPartEntityIsUse(entity)
        end
    end

    return false
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:CheckPartEntityIsUse(entity)
    if entity and not entity:IsNil() then
        return self:GetTypeCurrentUsePart(entity:GetTypeId()) == entity:GetPartId()
    end

    return false
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:CheckEmptyPartEntityIsUse(entity)
    if entity then
        return not XTool.IsNumberValid(self:GetTypeCurrentUsePart(entity:GetTypeId()))
    end

    return false
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:CheckPartEntityIsNow(entity)
    if entity and not entity:IsNil() then
        local wearData = self._WearDataMap[entity:GetTypeId()]

        if wearData and wearData:IsWaeredPart() then
            return wearData:GetPartId() == entity:GetPartId()
        end
    end

    return false
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:CheckEmptyPartEntityIsNow(entity)
    if entity then
        local wearData = self._WearDataMap[entity:GetTypeId()]

        return wearData and not wearData:IsRequired() and not wearData:IsWaeredPart()
    end

    return false
end

---@param entity XBWCommanderDIYColorEntity
function XBigWorldCommanderDIYControl:CheckColorEntityIsUse(entity)
    if entity and not entity:IsNil() then
        return self:GetPartCurrentUseColor(entity:GetPartId()) == entity:GetColorId()
    end

    return false
end

---@param entity XBWCommanderDIYColorEntity
function XBigWorldCommanderDIYControl:CheckColorEntityIsNow(entity)
    if entity and not entity:IsNil() then
        local partId = entity:GetPartId()
        local typeId = self._Model:GetDlcPlayerFashionPartTypeIdById(partId)
        local wearData = self._WearDataMap[typeId]

        if wearData and wearData:IsWaeredColor() then
            return wearData:GetColorId() == entity:GetColorId()
        end
    end

    return false
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:CheckIncompatibleType(entity)
    if self:CheckUseSuit() then
        if entity and not entity:IsNil() then
            local partId = self:GetUseSuitPart()
            local targetTypeId = entity:GetTypeId()
            local incompatibleTypeMap = self._Model:GetIncompatibleTypeMap(partId)

            return incompatibleTypeMap[targetTypeId] or false
        end
    end

    return false
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:CheckIncompatibleParts(entity)
    -- 从模型中读取当前 Outfit 的穿戴数据，遍历当前部件配置的不兼容部件列表；
    -- 只要发现有任一不兼容部件已在对应类型上穿戴，则认为存在冲突并返回 true，否则返回 false。
    if entity:IsEmpty() then
        return false
    end
    local partId = entity:GetPartId()
    local incompatibleParts = self._Model:GetDlcPlayerFashionPartIncompatiblePartsByTypeId(partId)
    if XTool.IsTableEmpty(incompatibleParts) then
        return false
    end
    local outfitType = self._CurrentModifiedIndex
    local wearDataMap = self._Model:GetWearDataMap(outfitType)
    if XTool.IsTableEmpty(wearDataMap) then
        return false
    end
    for _, incompatiblePartId in ipairs(incompatibleParts) do
        local typeId = self._Model:GetDlcPlayerFashionPartTypeIdById(incompatiblePartId)
        local wearData = wearDataMap[typeId]
        if wearData and wearData:IsWaeredPart() and wearData:GetPartId() == incompatiblePartId then
            return true
        end
    end
    return false
end

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:SetUsePartEntity(entity)
    if entity and not entity:IsNil() then
        self:SetUsePart(entity:GetTypeId(), entity:GetPartId())
    else
        XLog.Error("XBigWorldCommanderDIYControl:SetUsePartEntity - Entity is nil or invalid")
    end
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:ClearUsePartEntity(entity)
    if entity then
        self:SetUsePart(entity:GetTypeId())
    else
        XLog.Error("XBigWorldCommanderDIYControl:ClearUsePartEntity - Entity is nil")
    end
end

---@param entity XBWCommanderDIYColorEntity
function XBigWorldCommanderDIYControl:SetUsePartColorEntity(entity)
    if entity and not entity:IsNil() then
        self:SetUsePartColor(entity:GetPartId(), entity:GetColorId())
    end
end

---@return XBWCommanderDIYPartEntity[]
function XBigWorldCommanderDIYControl:GetUsePartEntitys()
    local typeEntitys = self:GetTypeEntitys()
    local result = {}

    if not XTool.IsTableEmpty(typeEntitys) then
        for _, entity in pairs(typeEntitys) do
            if not entity:IsSuit() then
                local partEntitys = entity:GetPartEntitys()
                local suitEntitys = entity:GetSuitPartEntitys()
                local isSearched = false

                if not XTool.IsTableEmpty(partEntitys) then
                    for _, partEntity in pairs(partEntitys) do
                        if self:CheckPartEntityIsUse(partEntity) then
                            table.insert(result, partEntity)
                            isSearched = true
                            break
                        end
                    end
                end
                if not isSearched and not XTool.IsTableEmpty(suitEntitys) then
                    for _, suitEntity in pairs(suitEntitys) do
                        if self:CheckPartEntityIsUse(suitEntity) then
                            table.insert(result, suitEntity)
                            break
                        end
                    end
                end
            end
        end
    end

    return result
end

---@return XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:GetUsePartEntityByTypeId(typeId)
    local usePartEntitys = self:GetUsePartEntitys()

    if not XTool.IsTableEmpty(usePartEntitys) then
        for _, entity in pairs(usePartEntitys) do
            if entity:GetTypeId() == typeId then
                return entity
            end
        end
    end

    return nil
end

---@return XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:GetUseFashionPartEntity()
    local entitys = self:GetUsePartEntitys()

    for _, entity in pairs(entitys) do
        if not entity:IsNil() and entity:IsFashion() then
            return entity
        end
    end

    return nil
end

-- endregion

-- region Data

function XBigWorldCommanderDIYControl:SetUsePart(typeId, partId)
    self._Model:SetUsePart(typeId, partId, self._CurrentModifiedIndex)
end

function XBigWorldCommanderDIYControl:GetTypeCurrentUsePart(typeId)
    return self._Model:GetUsePart(typeId, self._CurrentModifiedIndex)
end

function XBigWorldCommanderDIYControl:ResetUsePart(typeId)
    local partId = self:GetTypeCurrentUsePart(typeId)

    self:SetUsePart(typeId)
    self:SetUsePartColor(partId)
end

function XBigWorldCommanderDIYControl:GetPartCurrentUseColor(partId)
    return self._Model:GetUsePartColor(partId, self._CurrentModifiedIndex)
end

function XBigWorldCommanderDIYControl:GetPartUseColorByGender(partId, gender)
    return self._Model:GetUsePartColorByGender(partId, gender, self._CurrentModifiedIndex)
end

function XBigWorldCommanderDIYControl:SetUsePartColor(partId, colorId)
    self._Model:SetUsePartColor(partId, colorId, self._CurrentModifiedIndex)
end

function XBigWorldCommanderDIYControl:GetResIdByGender(partId, gender)
    return self._Model:GetResIdByPartId(partId, gender)
end

function XBigWorldCommanderDIYControl:GetDlcPlayerFashionResColorGroupIdById(resId)
    return self._Model:GetDlcPlayerFashionResColorGroupIdById(resId)
end

---@return number[]
function XBigWorldCommanderDIYControl:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)
    return self._Model:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)
end

function XBigWorldCommanderDIYControl:GetDlcPlayerFashionColorConfigById(colorId)
    return self._Model:GetDlcPlayerFashionColorConfigById(colorId)
end

function XBigWorldCommanderDIYControl:GetCurrentModifiedOutfitType()
    return self._CurrentModifiedIndex
end

function XBigWorldCommanderDIYControl:SetCurrentModifiedOutfitType(outfitType)
    self._CurrentModifiedIndex = outfitType
end

function XBigWorldCommanderDIYControl:GetCurrentCharacterId()
    return self._Model:GetCurrentCharacterId()
end

function XBigWorldCommanderDIYControl:GetCurrentNpcId()
    return self._Model:GetCurrentNpcId()
end

function XBigWorldCommanderDIYControl:GetCurrentGender()
    return self._Model:GetGender()
end

function XBigWorldCommanderDIYControl:GetCurrentValidGender()
    return self._Model:GetValidGender()
end

function XBigWorldCommanderDIYControl:ChangeGender(value, outfitType)
    self._Model:ChangeGender(value, outfitType)
end

function XBigWorldCommanderDIYControl:GetUseSuitPart()
    return self:GetTypeCurrentUsePart(XEnumConst.PlayerFashion.PartType.Suit)
end

function XBigWorldCommanderDIYControl:CheckUseSuit()
    return XTool.IsNumberValid(self:GetUseSuitPart())
end

-- endregion

-- region Config

function XBigWorldCommanderDIYControl:GetCurrentPartModelIdByPartId(partId)
    ---@type XBigWorldCommanderDIYAgency
    local agency = self:GetAgency()

    return agency:GetCurrentPartModelIdByPartId(partId)
end

function XBigWorldCommanderDIYControl:GetEntryAnimationNameByType(typeId)
    return self._Model:GetDlcPlayerFashionTypeEntryAnimationNameByTypeId(typeId)
end

function XBigWorldCommanderDIYControl:GetDefaultAnimationParamByType(typeId)
    return self._Model:GetDlcPlayerFashionTypeDefaultAnimationParamByTypeId(typeId)
end

-- endregion

-- region Other

function XBigWorldCommanderDIYControl:GetCameraMoveRange()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("DIYCameraMoveRange")
end

function XBigWorldCommanderDIYControl:ResetCommanderFashion()
    if not XTool.IsTableEmpty(self._WearDataMap) then
        for typeId, wearData in pairs(self._WearDataMap) do
            local outfitId = wearData:GetOutfitType()
            self._Model:SetWearData(typeId, wearData, outfitId)
        end
    end
    if XTool.IsNumberValid(self._Gender) then
        self._Model:SetGender(self._Gender)
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_COMMANDER_DIY_RESET)
end

function XBigWorldCommanderDIYControl:TemporaryFashionInfo(forceIndex)
    self._CurrentModifiedIndex = forceIndex or self._CurrentModifiedIndex
    local wearDataMap = self._Model:GetWearDataMap(self._CurrentModifiedIndex)
    self._WearDataMap = self._WearDataMap or {}
    self._Gender = self._Model:GetValidGender()
    if not XTool.IsTableEmpty(wearDataMap) then
        for typeId, waerData in pairs(wearDataMap) do
            if self._WearDataMap[typeId] then
                self._WearDataMap[typeId]:SetOutfitType(waerData:GetOutfitType())
                self._WearDataMap[typeId]:SetTypeId(waerData:GetTypeId())
                self._WearDataMap[typeId]:SetPartId(waerData:GetPartId())
                self._WearDataMap[typeId]:SetColorId(waerData:GetColorId())
            else
                self._WearDataMap[typeId] = waerData:Clone()
            end
        end
    end
end

function XBigWorldCommanderDIYControl:GetCurrentOutfitType()
    return self._Model:GetCurrentOutfitType()
end

-- 这个流程 callback 就是必然成功
function XBigWorldCommanderDIYControl:SaveFashionInfo(callback)
    self:RequestUpdate(self._CurrentModifiedIndex, self:GetCurrentGender(), self:GetDIYInfo(), callback)
end

function XBigWorldCommanderDIYControl:TrySaveFashionInfo(callback, tipText)
    self:TryOpenPreviewSavePopup(function(isSaveSuccess, isCancel)
        if isCancel then
            if callback then
                callback(isSaveSuccess, isCancel)
            end
        else
            self:SaveFashionInfo(callback)
        end
    end, tipText)
end

--- 弹出「是否确认放弃修改」确认框（文案默认取 DiscardChanges，也可由 tipText 覆盖）。
--- 确定：视为放弃修改，RestorePreviewPart 后 callback(true, false)。
--- 取消：保留当前编辑，callback(false, true)。
function XBigWorldCommanderDIYControl:OpenConfirmDiscardChangesPopup(tipText, callback)
    tipText = tipText or XMVCA.XBigWorldService:GetText("DIYDiscardChanges")
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    confirmData:InitInfo(nil, tipText)
    confirmData:InitToggleActive(false)
    confirmData:InitSureClick(nil, function()
        self:ResetCommanderFashion()
        if callback then
            local isSaveSuccess = true
            local isCancel = false
            callback(isSaveSuccess, isCancel)
        end
    end)
    confirmData:InitCancelClick(nil, function()
        if callback then
            local isSaveSuccess = false
            local isCancel = true
            callback(isSaveSuccess, isCancel)
        end
    end)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

-- 问询是否恢复到可保存状态
function XBigWorldCommanderDIYControl:TryOpenPreviewSavePopup(callback, tipText)
    -- DIYPreviewConfirmTips 穿戴了未获得部件，是否恢复未获得部件并保存其他部件？
    tipText = tipText or XMVCA.XBigWorldService:GetText("DIYPreviewConfirmTips")
    if not self:CheckWearPreview() then
        local isSaveSuccess = true
        local isCancel = false
        if callback then
            callback(isSaveSuccess, isCancel)
        end
        return
    end
    self:OpenConfirmDiscardChangesPopup(tipText, callback)
end

function XBigWorldCommanderDIYControl:CheckIsInitDIY()
    return self._Model:IsInitDiy()
end

function XBigWorldCommanderDIYControl:SetInitDiy(value)
    self._Model:SetInitDiy(value)
end

function XBigWorldCommanderDIYControl:RestorePreviewPart()
    local wearDataMap = self._Model:GetWearDataMap(self._CurrentModifiedIndex)

    if not XTool.IsTableEmpty(wearDataMap) then
        for typeId, wearData in pairs(wearDataMap) do
            if wearData:IsWaeredPart() and not self._Model:CheckPartUnlcok(wearData:GetPartId()) then
                local temporaryWearData = self._WearDataMap[typeId]

                wearData:ClearPart()

                if temporaryWearData then
                    --- 套装部分需要特殊处理
                    if temporaryWearData:IsSuitPart() then
                        local suitWearData = wearDataMap[XEnumConst.PlayerFashion.PartType.Suit]
                        local currentSuitWearData = self._WearDataMap[XEnumConst.PlayerFashion.PartType.Suit]

                        if not suitWearData or not currentSuitWearData then
                            wearData:ClearPart()
                        else
                            --- 如果当前穿戴套装，且当前套装与保存套装相同，则直接覆盖
                            if suitWearData:IsWaeredPart() and currentSuitWearData:IsWaeredPart() then
                                local suitPartId = suitWearData:GetPartId()
                                local currentSuitPartId = currentSuitWearData:GetPartId()

                                if suitPartId == currentSuitPartId then
                                    wearData:SetPartId(temporaryWearData:GetPartId())
                                    wearData:SetColorId(temporaryWearData:GetColorId())
                                else
                                    local partIds = self._Model:GetDlcPlayerFashionPartPartsById(suitPartId)

                                    if not XTool.IsTableEmpty(partIds) then
                                        for _, partId in pairs(partIds) do
                                            local suitPartTypeId = self._Model:GetDlcPlayerFashionPartTypeIdById(partId)

                                            if suitPartTypeId == typeId then
                                                local colorId = self._Model:GetDefaultColorIdByPartId(partId)

                                                wearData:SetPartId(partId)
                                                wearData:SetColorId(colorId)
                                                break
                                            end
                                        end
                                    else
                                        wearData:ClearPart()
                                    end
                                end
                            else
                                wearData:ClearPart()
                            end
                        end
                    else
                        wearData:SetPartId(temporaryWearData:GetPartId())
                        wearData:SetColorId(temporaryWearData:GetColorId())
                    end
                else
                    wearData:ClearPart()
                end
            end
        end
    end
end

function XBigWorldCommanderDIYControl:CreateTemporaryWearDataMap(outfitType)
    local wearDataMap = self._Model:CreateTemporaryWearDataMap(outfitType)
    return wearDataMap
end

function XBigWorldCommanderDIYControl:CheckCurrentMaleGender()
    return self:GetCurrentGender() == XEnumConst.PlayerFashion.Gender.Male
end

function XBigWorldCommanderDIYControl:GetNpcPartData()
    ---@type XBigWorldCommanderDIYAgency
    local agency = self:GetAgency()

    return agency:GetNpcPartData()
end

function XBigWorldCommanderDIYControl:CheckNeedSyncInfo()
    -- 性别变更需要保存（即使没有穿戴数据，也要把切性别同步给服务端）
    if self._Gender ~= self:GetCurrentGender() then
        return true
    end
    -- 如果没有数据就认为还没开始修改，直接返回不需要保存
    if XTool.IsTableEmpty(self._WearDataMap) then
        return false
    end
    local currentOutfitType = self._Model:GetCurrentOutfitType()
    if currentOutfitType ~= self._CurrentModifiedIndex then
        return true
    end
    local wearDataMap = self._Model:GetWearDataMap(self._CurrentModifiedIndex)

    if not XTool.IsTableEmpty(wearDataMap) then
        for typeId, wearData in pairs(wearDataMap) do
            if not wearData:IsEqual(self._WearDataMap[typeId]) then
                XLog.Debug(typeId .. "[from]:" .. self._WearDataMap[typeId]:GetPartId() .. " " ..
                               self._WearDataMap[typeId]:GetColorId() .. "[to]:" .. wearData:GetPartId() .. " " ..
                               wearData:GetColorId())
                return true
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYControl:CheckWearPreview()
    local wearDataMap = self._Model:GetWearDataMap(self._CurrentModifiedIndex)

    if not XTool.IsTableEmpty(wearDataMap) then
        for typeId, wearData in pairs(wearDataMap) do
            if wearData:IsWaeredPart() and not wearData:IsSuitPart() and
                not self._Model:CheckPartUnlcok(wearData:GetPartId()) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYControl:GetMaterialConfigs(partModelId, colorId)
    if not XTool.IsNumberValid(colorId) then
        return {}
    end

    local colorName = self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)

    if string.IsNilOrEmpty(colorName) then
        return {}
    end

    local result = XMVCA.XBigWorldResource:GetPartModelMaterials(partModelId, colorName)

    if not result then
        return {}
    end

    return XTool.CsList2LuaTable(result)
end

function XBigWorldCommanderDIYControl:GetMaterialNameById(colorId)
    return self._Model:GetDlcPlayerFashionColorMaterialNameById(colorId)
end

function XBigWorldCommanderDIYControl:GetDIYInfo()
    local info = {}
    local wearDataMap = self._Model:GetWearDataMap(self._CurrentModifiedIndex)
    local suitData = wearDataMap[XEnumConst.PlayerFashion.PartType.Suit]
    for typeId, wearData in pairs(wearDataMap) do
        if wearData:IsWaeredPart() then
            info[typeId] = wearData:ToData()
        end
    end

    if suitData and suitData:IsWaeredPart() then
        local partId = suitData:GetPartId()
        local incompatibleTypes = self._Model:GetIncompatibleTypeMap(partId)
        local partIds = self._Model:GetDlcPlayerFashionPartPartsById(partId)

        for typeId in pairs(incompatibleTypes) do
            info[typeId] = nil
        end
        for _, suitPartId in pairs(partIds) do
            local typeId = self._Model:GetDlcPlayerFashionPartTypeIdById(suitPartId)
            local wearData = wearDataMap[typeId]
            if wearData:GetPartId() == suitPartId then
                info[typeId] = nil
            end
        end

        info[suitData:GetTypeId()] = suitData:ToData()
    end

    return info
end

function XBigWorldCommanderDIYControl:RecordPart(partId)
    self._Model:SetRecordPart(partId)
end

function XBigWorldCommanderDIYControl:CheckPartRecord(partId)
    local record = self._Model:GetRecordPartMap()

    return record[partId] or false
end

-- endregion

-- region Protocol

function XBigWorldCommanderDIYControl:RequestUpdate(outfitType, gender, fashionList, callback)
    -- 发包前先校验拥有性，避免把未拥有部件发出去再被服务端 HasOwnPart 打回
    if not self._Model:IsFashionListAllOwned(fashionList) then
        -- XUiManager.TipCode(XCode.DlcFashionPartIdNotOwn)
        return
    end
    XMessagePack.MarkAsTable(fashionList)
    XNetwork.Call(Protocol.BigWorldCommanderFashionUpdateRequest, {
        OutfitType = outfitType,
        Gender = gender,
        CommanderFashionList = fashionList
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        else
            self._Model:DoSetCommanderFashionOutfitsData(fashionList, outfitType)
            self._Model:SetCurrentOutfitType(outfitType)
            self:TemporaryFashionInfo(outfitType)
            self:SetInitDiy(true)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_COMMANDER_DIY_MODEL_UPDATE)
            if callback then
                callback(res.Code == XCode.Success)
            end
        end
    end)
end

-- endregion

-- region Private

--- 处理保存和完成回调
--- 如果需要同步信息，则弹出确认框；否则直接调用回调
---@param callback function 完成后的回调函数 
---@return isSuccess boolean 是否发送协议保存成功
function XBigWorldCommanderDIYControl:AskSaveAndFinishCallBack(callback)
    if self:CheckNeedSyncInfo() then
        local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
        -- DIYConfirmTips 是否保存修改？
        confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYConfirmTips"))
        confirmData:InitToggleActive(false)
        confirmData:InitCancelClick(nil, function()
            local isSaveSuccess = false
            local isCancel = true
            callback(isSaveSuccess, isCancel)
        end)
        confirmData:InitSureClick(nil, function()
            self:TrySaveFashionInfo(callback)
        end)
        XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
    else
        local isSaveSuccess = false
        local isCancel = false
        callback(isSaveSuccess, isCancel)
    end
end

-- endregion
return XBigWorldCommanderDIYControl
