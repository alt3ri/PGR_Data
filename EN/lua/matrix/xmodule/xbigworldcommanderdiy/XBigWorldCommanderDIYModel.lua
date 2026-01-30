local XBigWorldCommanderDIYConfigModel = require("XModule/XBigWorldCommanderDIY/XBigWorldCommanderDIYConfigModel")
local XBWCommanderDIYWearData = require("XModule/XBigWorldCommanderDIY/XData/XBWCommanderDIYWearData")

---@class XBigWorldCommanderDIYModel : XBigWorldCommanderDIYConfigModel
local XBigWorldCommanderDIYModel = XClass(XBigWorldCommanderDIYConfigModel, "XBigWorldCommanderDIYModel")

function XBigWorldCommanderDIYModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<number, XBWCommanderDIYWearData>
    self._WearDataMap = {}
    self._UnlockPartMap = {}
    self._Gender = XEnumConst.PlayerFashion.Gender.Male
    self._IsInitDIY = false

    self:_InitTableKey()
    self:_InitWearData()
end

function XBigWorldCommanderDIYModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldCommanderDIYModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._WearDataMap = {}
    self._UnlockPartMap = {}
    self._Gender = XEnumConst.PlayerFashion.Gender.Male
end

function XBigWorldCommanderDIYModel:GetCurrentCharacterId()
    local gender = self:GetValidGender()

    if gender == XEnumConst.PlayerFashion.Gender.Female then
        return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("PlayerFemaleCharacterId")
    else
        return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("PlayerMaleCharacterId")
    end
end

function XBigWorldCommanderDIYModel:GetCurrentNpcId()
    local characterId = self:GetCurrentCharacterId()

    return XMVCA.XBigWorldCharacter:GetCharacterNpcId(characterId)
end

function XBigWorldCommanderDIYModel:SetGender(value)
    self._Gender = value
end

function XBigWorldCommanderDIYModel:ChangeGender(value)
    if self._Gender ~= value then
        self:SetGender(value)

        if not XTool.IsTableEmpty(self._WearDataMap) then
            for typeId, wearData in pairs(self._WearDataMap) do
                wearData:ClearColor()
            end
        end
    end
end

function XBigWorldCommanderDIYModel:GetGender()
    return self._Gender
end

function XBigWorldCommanderDIYModel:SetInitDiy(value)
    self._IsInitDIY = value
end

function XBigWorldCommanderDIYModel:IsInitDiy()
    return self._IsInitDIY
end

function XBigWorldCommanderDIYModel:SetUsePart(typeId, partId)
    if XTool.IsNumberValid(partId) then
        if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
            self:_WearSuit(typeId, partId)
        else
            self:_TryTackOffSuit(typeId)
            self:_WearPart(typeId, partId)
        end
    else
        if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
            self:_TackOffSuit()
        else
            if not self:_TryRecoverSuit(typeId) then
                self:_WearPart(typeId, partId)
            end
        end
    end
end

function XBigWorldCommanderDIYModel:GetUsePart(typeId)
    local wearData = self._WearDataMap[typeId]

    if wearData then
        return wearData:GetPartId()
    end

    return 0
end

function XBigWorldCommanderDIYModel:SetUsePartColor(partId, colorId)
    local typeId = self:GetDlcPlayerFashionPartTypeIdById(partId)

    if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
        local partIds = self:GetDlcPlayerFashionPartPartsById(partId)

        if not XTool.IsTableEmpty(partIds) then
            for _, suitPartId in pairs(partIds) do
                local suitTypeId = self:GetDlcPlayerFashionPartTypeIdById(suitPartId)
                local usePartId = self:GetUsePart(suitTypeId)

                if usePartId == suitPartId then
                    self:_WearColor(suitTypeId, colorId)
                end
            end
        end
    end

    self:_WearColor(typeId, colorId)
end

function XBigWorldCommanderDIYModel:GetUsePartColor(partId)
    local typeId = self:GetDlcPlayerFashionPartTypeIdById(partId)
    local wearData = self._WearDataMap[typeId]

    if wearData then
        return wearData:GetColorId()
    end

    return 0
end

---@param wearData XBWCommanderDIYWearData
function XBigWorldCommanderDIYModel:SetWearData(typeId, other)
    local wearData = self._WearDataMap[typeId]

    if wearData then
        wearData:CopyFrom(other)
    end
end

function XBigWorldCommanderDIYModel:GetUsePartColorByGender(partId, gender)
    if gender == self:GetGender() then
        return self:GetUsePartColor(partId)
    end

    return self:GetDefaultColorIdByPartId(partId, gender) or 0
end

---@return table<number, XBWCommanderDIYWearData>
function XBigWorldCommanderDIYModel:GetWearDataMap()
    return self._WearDataMap
end

function XBigWorldCommanderDIYModel:GetWearData(typeId)
    return self._WearDataMap[typeId]
end

function XBigWorldCommanderDIYModel:GetIncompatibleTypeMap(partId)
    local incompatibleTypes = self:GetDlcPlayerFashionPartIncompatibleTypeById(partId)
    local result = {}

    if not XTool.IsTableEmpty(incompatibleTypes) then
        for _, incompatibleTypeId in pairs(incompatibleTypes) do
            result[incompatibleTypeId] = true
        end
    end

    return result
end

function XBigWorldCommanderDIYModel:UpdateFashion(fashionList)
    if not XTool.IsTableEmpty(fashionList) then
        for typeId, fashion in pairs(fashionList) do
            if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
                self:_WearSuit(typeId, fashion.PartId)
            end
        end
        for typeId, fashion in pairs(fashionList) do
            if not self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
                self:_WearPart(typeId, fashion.PartId)
                self:_WearColor(typeId, fashion.ColourId)
            end
        end
    end
end

function XBigWorldCommanderDIYModel:UpdateUnlockParts(commanderFashionBags)
    self._UnlockPartMap = {}
    if not XTool.IsTableEmpty(commanderFashionBags) then
        for _, partId in pairs(commanderFashionBags) do
            self._UnlockPartMap[partId] = true
        end
    end
end

function XBigWorldCommanderDIYModel:GetResIdByPartId(partId, gender)
    local resIds = self:GetDlcPlayerFashionPartResIdById(partId)

    if XTool.IsTableEmpty(resIds) then
        return 0
    end

    gender = self:GetValidGender(gender)

    local resId = resIds[gender]

    return resId or 0
end

function XBigWorldCommanderDIYModel:GetValidGender(gender)
    gender = gender or self:GetGender()

    if not XTool.IsNumberValid(gender) then
        gender = XEnumConst.PlayerFashion.Gender.Male
    end

    return gender
end

function XBigWorldCommanderDIYModel:GetDefaultPartIdByTypeId(typeId)
    if not XTool.IsNumberValid(typeId) then
        return 0
    end

    local partId = self:GetDlcPlayerFashionTypeDefaultPartIdByTypeId(typeId)

    return partId or 0
end

function XBigWorldCommanderDIYModel:GetDefaultColorIdByPartId(partId, gender)
    if not XTool.IsNumberValid(partId) then
        return 0
    end

    local resId = self:GetResIdByPartId(partId, self:GetValidGender(gender))

    return self:GetDlcPlayerFashionResDefaultColorIdById(resId) or 0
end

function XBigWorldCommanderDIYModel:CheckAllowSelectColor(partId, gender)
    if not XTool.IsNumberValid(partId) then
        return false
    end

    local resId = self:GetResIdByPartId(partId, gender)

    if XTool.IsNumberValid(resId) then
        local colorGroupId = self:GetDlcPlayerFashionResColorGroupIdById(resId)

        return XTool.IsNumberValid(colorGroupId)
    end

    return false
end

function XBigWorldCommanderDIYModel:CheckPartUnlcok(partId)
    return self._UnlockPartMap[partId] or false
end

function XBigWorldCommanderDIYModel:_WearSuit(typeId, partId)
    local partIds = self:GetDlcPlayerFashionPartPartsById(partId)

    self:_WearPart(typeId, partId)
    if not XTool.IsTableEmpty(partIds) then
        for _, suitPartId in pairs(partIds) do
            local suitPartTypeId = self:GetDlcPlayerFashionPartTypeIdById(suitPartId)

            self:_WearPart(suitPartTypeId, suitPartId)
        end
    end
end

function XBigWorldCommanderDIYModel:_WearPart(typeId, partId)
    local wearData = self._WearDataMap[typeId]

    if wearData then
        wearData:SetPartId(partId)
    end
end

function XBigWorldCommanderDIYModel:_WearColor(typeId, colorId)
    local wearData = self._WearDataMap[typeId]

    if wearData then
        wearData:SetColorId(colorId)
    end
end

function XBigWorldCommanderDIYModel:_TackOffSuit()
    local wearData = self._WearDataMap[XEnumConst.PlayerFashion.PartType.Suit]

    if wearData:IsWaeredPart() then
        local partIds = self:GetDlcPlayerFashionPartPartsById(wearData:GetPartId())
        local incompatibleTypes = self:GetDlcPlayerFashionPartIncompatibleTypeById(wearData:GetPartId())
        local incompatibleTypeMap = {}

        if not XTool.IsTableEmpty(partIds) then
            for _, incompatibleType in pairs(incompatibleTypes) do
                if self._WearDataMap[incompatibleType] then
                    incompatibleTypeMap[incompatibleType] = true
                    self._WearDataMap[incompatibleType]:ClearPart()
                end
            end
        end
        if not XTool.IsTableEmpty(partIds) then
            for _, partId in pairs(partIds) do
                local typeId = self:GetDlcPlayerFashionPartTypeIdById(partId)

                if not incompatibleTypeMap[typeId] then
                    local suitWearData = self._WearDataMap[typeId]

                    if suitWearData:GetPartId() == partId then
                        suitWearData:ClearPart()
                    end
                end
            end
        end
        wearData:ClearPart()
    end
end

function XBigWorldCommanderDIYModel:_TryTackOffSuit(typeId)
    local wearData = self._WearDataMap[XEnumConst.PlayerFashion.PartType.Suit]

    if wearData and wearData:IsWaeredPart() then
        local incompatibleTypes = self:GetDlcPlayerFashionPartIncompatibleTypeById(wearData:GetPartId())

        if not XTool.IsTableEmpty(incompatibleTypes) then
            for _, incompatibleType in pairs(incompatibleTypes) do
                if incompatibleType == typeId then
                    self:_TackOffSuit()
                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYModel:_TryRecoverSuit(typeId)
    local wearData = self._WearDataMap[XEnumConst.PlayerFashion.PartType.Suit]

    if wearData and wearData:IsWaeredPart() then
        local partIds = self:GetDlcPlayerFashionPartPartsById(wearData:GetPartId())

        if not XTool.IsTableEmpty(partIds) then
            for _, partId in pairs(partIds) do
                local suitTypeId = self:GetDlcPlayerFashionPartTypeIdById(partId)

                if suitTypeId == typeId then
                    self:_WearPart(typeId, partId)

                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYModel:_InitWearData()
    self._WearDataMap = {}
    for _, typeId in pairs(XEnumConst.PlayerFashion.PartType) do
        self._WearDataMap[typeId] = XBWCommanderDIYWearData.New(typeId)
    end
end

return XBigWorldCommanderDIYModel
