local XBWCommanderDIYTypeEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYTypeEntity")

---@class XBigWorldCommanderDIYControl : XEntityControl
---@field private _Model XBigWorldCommanderDIYModel
local XBigWorldCommanderDIYControl = XClass(XEntityControl, "XBigWorldCommanderDIYControl")

local Protocol = {
    BigWorldCommanderFashionUpdateRequest = "BigWorldCommanderFashionUpdateRequest",
}

function XBigWorldCommanderDIYControl:OnInit()
    -- 初始化内部变量
    ---@type XBWCommanderDIYTypeEntity[]
    self._TypeEntitys = false

    self._Gender = 0
    ---@type table<number, XBWCommanderDIYWearData>
    self._WearDataMap = {}

    self:_InitRecordPartMap()
end

function XBigWorldCommanderDIYControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldCommanderDIYControl:RemoveAgencyEvent()

end

function XBigWorldCommanderDIYControl:OnRelease()
    self._Gender = 0
    self._WearDataMap = {}

    self:_RecordPartMapToLocal()
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

---@param entity XBWCommanderDIYPartEntity
function XBigWorldCommanderDIYControl:SetUsePartEntity(entity)
    if entity and not entity:IsNil() then
        self:SetUsePart(entity:GetTypeId(), entity:GetPartId())
    end
end

---@param entity XBWCommanderDIYEmptyPartEntity
function XBigWorldCommanderDIYControl:ClearUsePartEntity(entity)
    if entity then
        self:SetUsePart(entity:GetTypeId())
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
    self._Model:SetUsePart(typeId, partId)
end

function XBigWorldCommanderDIYControl:GetTypeCurrentUsePart(typeId)
    return self._Model:GetUsePart(typeId)
end

function XBigWorldCommanderDIYControl:ResetUsePart(typeId)
    local partId = self:GetTypeCurrentUsePart(typeId)

    self:SetUsePart(typeId)
    self:SetUsePartColor(partId)
end

function XBigWorldCommanderDIYControl:GetPartCurrentUseColor(partId)
    return self._Model:GetUsePartColor(partId)
end

function XBigWorldCommanderDIYControl:GetPartUseColorByGender(partId, gender)
    return self._Model:GetUsePartColorByGender(partId, gender)
end

function XBigWorldCommanderDIYControl:SetUsePartColor(partId, colorId)
    self._Model:SetUsePartColor(partId, colorId)
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

function XBigWorldCommanderDIYControl:ChangeGender(value)
    self._Model:ChangeGender(value)
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
            self._Model:SetWearData(typeId, wearData)
        end
    end
    if XTool.IsNumberValid(self._Gender) then
        self._Model:SetGender(self._Gender)
    end
end

function XBigWorldCommanderDIYControl:TemporaryFashionInfo()
    local wearDataMap = self._Model:GetWearDataMap()

    self._WearDataMap = {}
    self._Gender = self._Model:GetValidGender()
    if not XTool.IsTableEmpty(wearDataMap) then
        for typeId, waerData in pairs(wearDataMap) do
            self._WearDataMap[typeId] = waerData:Clone()
        end
    end
end

function XBigWorldCommanderDIYControl:SaveFashionInfo(callback)
    self:RequestUpdate(self:GetCurrentGender(), self:GetDIYInfo(), callback)
end

function XBigWorldCommanderDIYControl:TrySaveFashionInfo(callback)
    self:TryOpenPreviewSavePopup(function()
        self:SaveFashionInfo(callback)
    end)
end

function XBigWorldCommanderDIYControl:TryOpenPreviewSavePopup(callback)
    if not self:CheckWearPreview() then
        if callback then
            callback()
        end

        return
    end

    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYPreviewConfirmTips"))
    confirmData:InitToggleActive(false)
    confirmData:InitSureClick(nil, function()
        self:RestorePreviewPart()
        if callback then
            callback()
        end
    end)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

function XBigWorldCommanderDIYControl:CheckIsInitDIY()
    return self._Model:IsInitDiy()
end

function XBigWorldCommanderDIYControl:SetInitDiy(value)
    self._Model:SetInitDiy(value)
end

function XBigWorldCommanderDIYControl:RestorePreviewPart()
    local wearDataMap = self._Model:GetWearDataMap()

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

function XBigWorldCommanderDIYControl:CheckCurrentMaleGender()
    return self:GetCurrentGender() == XEnumConst.PlayerFashion.Gender.Male
end

function XBigWorldCommanderDIYControl:GetNpcPartData()
    ---@type XBigWorldCommanderDIYAgency
    local agency = self:GetAgency()

    return agency:GetNpcPartData()
end

function XBigWorldCommanderDIYControl:CheckNeedSyncInfo()
    if self._Gender ~= self:GetCurrentGender() then
        return true
    end

    local wearDataMap = self._Model:GetWearDataMap()

    if not XTool.IsTableEmpty(wearDataMap) then
        for typeId, wearData in pairs(wearDataMap) do
            if not wearData:IsEqual(self._WearDataMap[typeId]) then
                return true
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYControl:CheckWearPreview()
    local wearDataMap = self._Model:GetWearDataMap()

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

function XBigWorldCommanderDIYControl:GetDIYInfo()
    local info = {}
    local wearDataMap = self._Model:GetWearDataMap()
    local suitData = wearDataMap[XEnumConst.PlayerFashion.PartType.Suit]

    if suitData and suitData:IsWaeredPart() then
        local partId = suitData:GetPartId()
        local incompatibleTypes = self._Model:GetIncompatibleTypeMap(partId)
        local partIds = self._Model:GetDlcPlayerFashionPartPartsById(partId)
        local suitTypeMap = {}

        info[suitData:GetTypeId()] = suitData:ToData()
        for _, partId in pairs(partIds) do
            local typeId = self._Model:GetDlcPlayerFashionPartTypeIdById(partId)

            suitTypeMap[typeId] = true
            if not incompatibleTypes[typeId] then
                local wearData = wearDataMap[typeId]

                if wearData:IsWaeredPart() and wearData:GetPartId() ~= partId then
                    info[typeId] = wearData:ToData()
                end
            end
        end
        for typeId, wearData in pairs(wearDataMap) do
            if not suitTypeMap[typeId] and wearData:IsWaeredPart() then
                info[typeId] = wearData:ToData()
            end
        end
    else
        for typeId, wearData in pairs(wearDataMap) do
            if not wearData:IsSuit() and wearData:IsWaeredPart() then
                info[typeId] = wearData:ToData()
            end
        end
    end

    return info
end

function XBigWorldCommanderDIYControl:RecordPart(partId)
    if self._RecordPartMap then
        self._RecordPartMap[partId] = true
    end
end

function XBigWorldCommanderDIYControl:CheckPartRecord(partId)
    if self._RecordPartMap then
        return self._RecordPartMap[partId] or false
    end

    return false
end

-- endregion

-- region Protocol

function XBigWorldCommanderDIYControl:RequestUpdate(gender, fashionList, callback)
    XMessagePack.MarkAsTable(fashionList)
    XNetwork.Call(Protocol.BigWorldCommanderFashionUpdateRequest, {
        Gender = gender,
        CommanderFashionList = fashionList,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        self:TemporaryFashionInfo()
        self:SetInitDiy(true)
        if not XMVCA.XBigWorldCommanderDIY:IsFromOpenGuide() then
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("DIYSaveSuccessTip"))
        end
        if callback then
            callback()
        end
    end)
end

-- endregion

-- region Private

function XBigWorldCommanderDIYControl:_InitRecordPartMap()
    local record = XSaveTool.GetData(self:_GetRecordPartKey())

    self._RecordPartMap = {}
    if not string.IsNilOrEmpty(record) then
        local records = string.Split(record, "|")

        if not XTool.IsTableEmpty(records) then
            for _, partId in pairs(records) do
                self._RecordPartMap[tonumber(partId)] = true
            end
        end
    end
end

function XBigWorldCommanderDIYControl:_RecordPartMapToLocal()
    if self._RecordPartMap then
        local result = {}

        for partId, _ in pairs(self._RecordPartMap) do
            table.insert(result, partId)
        end

        XSaveTool.SaveData(self:_GetRecordPartKey(), table.concat(result, "|"))
    end
end

function XBigWorldCommanderDIYControl:_GetRecordPartKey()
    return "BW_DIY_PART_UNLOCK_" .. tostring(XPlayer.Id)
end

-- endregion

return XBigWorldCommanderDIYControl
