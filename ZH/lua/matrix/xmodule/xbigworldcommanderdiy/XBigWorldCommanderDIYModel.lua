local XBigWorldCommanderDIYConfigModel = require("XModule/XBigWorldCommanderDIY/XBigWorldCommanderDIYConfigModel")
local XBWCommanderDIYWearData = require("XModule/XBigWorldCommanderDIY/XData/XBWCommanderDIYWearData")
local XBWCommanderDIYOutfitData = require("XModule/XBigWorldCommanderDIY/XData/XBWCommanderDIYOutfitData")

---@class XBigWorldCommanderDIYModel : XBigWorldCommanderDIYConfigModel
local XBigWorldCommanderDIYModel = XClass(XBigWorldCommanderDIYConfigModel, "XBigWorldCommanderDIYModel")

function XBigWorldCommanderDIYModel:OnInit()
    self._OutfitMap = {}
    ---@type table<number, XBWCommanderDIYWearData>
    self._UnlockPartMap = {}
    self._CacheIncompatibleTypeMap = {}
    self._CacheOutfitDefaultPartIds = {}
    self._Gender = XEnumConst.PlayerFashion.Gender.Male
    self._IsInitDIY = false
    self._CommanderFashionOutfits = {}
    self._CurCommanderOutfitType = 0
    self._DelayRewardGoodsList = table.empty
    self._RecordPartMap = false

    self:_InitTableKey()
end

function XBigWorldCommanderDIYModel:ClearPrivate()
    -- 这里执行内部数据清理
    for k, v in pairs(self._CacheIncompatibleTypeMap) do
        self._CacheIncompatibleTypeMap[k] = nil
    end
    for k, v in pairs(self._CacheOutfitDefaultPartIds) do
        self._CacheOutfitDefaultPartIds[k] = nil
    end
    self:_ClearCheckData()
    self:_RecordPartMapToLocal()
end

function XBigWorldCommanderDIYModel:ResetAll()
    -- 这里执行重登数据清理
    self._UnlockPartMap = {}
    self._CacheIncompatibleTypeMap = {}
    self._CommanderFashionOutfits = {}
    self._OutfitMap = {}
    self._Gender = XEnumConst.PlayerFashion.Gender.Male
    self._DelayRewardGoodsList = {}
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

function XBigWorldCommanderDIYModel:ChangeGender(value, outfitType)
    if self._Gender ~= value then
        self:SetGender(value)

        if not XTool.IsTableEmpty(self:GetWearDataMap(outfitType)) then
            for typeId, wearData in pairs(self:GetWearDataMap(outfitType)) do
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

function XBigWorldCommanderDIYModel:GetCurrentOutfitType()
    return self._CurCommanderOutfitType
end

function XBigWorldCommanderDIYModel:SetCurrentOutfitType(outfitType)
    self._CurCommanderOutfitType = outfitType
end

function XBigWorldCommanderDIYModel:SetUsePart(typeId, partId, outfitType)
    -- not wear is tackoff
    local isWear = XTool.IsNumberValid(partId)
    if isWear then
        self:WearPart(typeId, partId, outfitType)
    else
        self:TackOffPart(typeId, partId, outfitType)
    end
end

function XBigWorldCommanderDIYModel:_CheckWearIsOverflow(typeId, partId)
    if self.__CheckWearOverflowData == nil then
        self.__checkDataOffset = 10000
        self.__CheckWearOverflowData = {}
        self.__CheckWearOverflowRawData = {}
    end
    partId = partId or 0
    typeId = typeId or 0
    local key = partId * self.__checkDataOffset + typeId
    table.insert(self.__CheckWearOverflowRawData, typeId)
    table.insert(self.__CheckWearOverflowRawData, partId)
    if self.__CheckWearOverflowData[key] == true then
        XLog.Error("指挥官DIY衣服穿衣服死循环：")
        for i = 1, #self.__CheckWearOverflowRawData, 2 do
            local _typeId = self.__CheckWearOverflowRawData[i]
            local _partId = self.__CheckWearOverflowRawData[i + 1]
            XLog.Error("穿衣服顺序 typeId:" .. _typeId .. "partId:" .. _partId)
        end
        return true
    else
        self.__CheckWearOverflowData[key] = true
        return false
    end
end

function XBigWorldCommanderDIYModel:_ClearCheckData()
    if self.__CheckWearOverflowData then
        for k, v in pairs(self.__CheckWearOverflowData) do
            self.__CheckWearOverflowData[k] = nil
        end
    end
    if self.__CheckWearOverflowRawData then
        for i = 1, #self.__CheckWearOverflowRawData, 1 do
            self.__CheckWearOverflowRawData[i] = nil
        end
    end
end

function XBigWorldCommanderDIYModel:WearPart(typeId, partId, outfitType)
    if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
        self:_WearSuit(typeId, partId, outfitType)
    else
        self:_TryTackOffSuit(typeId, outfitType)
        self:_WearPart(typeId, partId, outfitType)
    end
end

function XBigWorldCommanderDIYModel:TackOffPart(typeId, partId, outfitType)
    if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
        self:_TackOffSuit(outfitType)
    else
        -- 如果脱的时候，套装有默认的部位，穿默认部位
        if not self:_TryRecoverSuit(typeId, outfitType) then
            self:_WearPart(typeId, partId, outfitType)
        end
    end
end

function XBigWorldCommanderDIYModel:GetUsePart(typeId, outfitType)
    local wearData = self:GetWearData(typeId, outfitType or self._CurCommanderOutfitType)

    if wearData then
        return wearData:GetPartId()
    end

    return 0
end

function XBigWorldCommanderDIYModel:SetUsePartColor(partId, colorId, outfitType)
    local targetOutfitType = outfitType or self._CurCommanderOutfitType
    local typeId = self:GetDlcPlayerFashionPartTypeIdById(partId)

    if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
        local partIds = self:GetDlcPlayerFashionPartPartsById(partId)

        if not XTool.IsTableEmpty(partIds) then
            for _, suitPartId in pairs(partIds) do
                local suitTypeId = self:GetDlcPlayerFashionPartTypeIdById(suitPartId)
                local usePartId = self:GetUsePart(suitTypeId, targetOutfitType)

                if usePartId == suitPartId then
                    self:_WearColor(suitTypeId, colorId, targetOutfitType)
                end
            end
        end
    end

    self:_WearColor(typeId, colorId, targetOutfitType)
end

function XBigWorldCommanderDIYModel:GetUsePartColor(partId, outfitType)
    local typeId = self:GetDlcPlayerFashionPartTypeIdById(partId)
    local wearData = self:GetWearData(typeId, outfitType)

    if wearData then
        return wearData:GetColorId()
    end

    return 0
end

---@param wearData XBWCommanderDIYWearData
function XBigWorldCommanderDIYModel:SetWearData(typeId, other, outfitType)
    local wearData = self:GetWearData(typeId, outfitType)
    wearData:CopyFrom(other)
end

function XBigWorldCommanderDIYModel:GetUsePartColorByGender(partId, gender, outfitType)
    if gender == self:GetGender() then
        return self:GetUsePartColor(partId, outfitType)
    end

    return self:GetDefaultColorIdByPartId(partId, gender) or 0
end

function XBigWorldCommanderDIYModel:GetCurrentWearDataMap()
    return self:GetWearDataMap(self._CurCommanderOutfitType)
end

---@return table<number, XBWCommanderDIYWearData>
function XBigWorldCommanderDIYModel:GetWearDataMap(outfitType)
    local result = self._OutfitMap[outfitType]
    if result == nil then
        local wearDataMap = {}
        self._OutfitMap[outfitType] = wearDataMap
        local _CommanderFashionOutfits = self:GetCommanderFashionOutfitsData()
        local outfitData = _CommanderFashionOutfits[outfitType]
        local wearFashionDict = outfitData.WearFashionDict
        -- 1.先处理套装数据，因为套装数据会包含其他部件数据
        local suitData = wearFashionDict[XEnumConst.PlayerFashion.PartType.Suit]
        if suitData then
            wearDataMap[XEnumConst.PlayerFashion.PartType.Suit] =
                XBWCommanderDIYWearData.New(XEnumConst.PlayerFashion.PartType.Suit, suitData.PartId, suitData.ColorId,
                    outfitType)
            for _, partId in pairs(self:GetDlcPlayerFashionPartPartsById(suitData.PartId)) do
                local partType = self:GetDlcPlayerFashionPartTypeIdById(partId)
                local partData = wearFashionDict[partType]
                if partData then
                    wearDataMap[partType] = XBWCommanderDIYWearData.New(partType, partData.PartId, partData.ColorId,
                        outfitType)
                end
            end
        else
            wearDataMap[XEnumConst.PlayerFashion.PartType.Suit] =
                XBWCommanderDIYWearData.New(XEnumConst.PlayerFashion.PartType.Suit, 0, 0, outfitType)
        end
        -- 2.再处理其他部件数据
        for _, typeId in pairs(XEnumConst.PlayerFashion.PartType) do
            if typeId ~= XEnumConst.PlayerFashion.PartType.Suit then
                local data = wearFashionDict[typeId]
                if data then
                    wearDataMap[typeId] = XBWCommanderDIYWearData.New(typeId, data.PartId, data.ColorId, outfitType)
                else
                    wearDataMap[typeId] = XBWCommanderDIYWearData.New(typeId, 0, 0, outfitType)
                end
            end
        end
        result = wearDataMap
    end
    return result
end

function XBigWorldCommanderDIYModel:CreateTemporaryWearDataMap(outfitType)
    return XBWCommanderDIYOutfitData.New(outfitType)
end

function XBigWorldCommanderDIYModel:GetWearData(typeId, outfitType)
    return self:GetWearDataMap(outfitType)[typeId]
end

function XBigWorldCommanderDIYModel:GetIncompatibleTypeMap(partId)
    local cache = self._CacheIncompatibleTypeMap[partId]
    if cache then
        return cache
    end
    local incompatibleTypes = self:GetDlcPlayerFashionPartIncompatibleTypeById(partId)
    local result = {}

    if not XTool.IsTableEmpty(incompatibleTypes) then
        for _, incompatibleTypeId in pairs(incompatibleTypes) do
            result[incompatibleTypeId] = true
        end
    end
    self._CacheIncompatibleTypeMap[partId] = result
    return result
end

function XBigWorldCommanderDIYModel:UpdateUnlockParts(commanderFashionBags)
    self._UnlockPartMap = {}
    if not XTool.IsTableEmpty(commanderFashionBags) then
        for _, partId in pairs(commanderFashionBags) do
            self._UnlockPartMap[partId] = true
        end
    end
end

function XBigWorldCommanderDIYModel:UpdateDelayRewardGoods(delayRewardGoodsList)
    self._DelayRewardGoodsList = delayRewardGoodsList or table.empty
end

function XBigWorldCommanderDIYModel:GetDelayRewardGoods()
    return self._DelayRewardGoodsList
end

function XBigWorldCommanderDIYModel:ClearDelayRewardGoods()
    self._DelayRewardGoodsList = table.empty
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

function XBigWorldCommanderDIYModel:CheckColorIsInColorGroup(partId, gender, color)
    if not XTool.IsNumberValid(partId) then
        return false
    end
    if not XTool.IsNumberValid(color) then
        return false
    end
    local resId = self:GetResIdByPartId(partId, gender)
    if XTool.IsNumberValid(resId) then
        local colorGroupId = self:GetDlcPlayerFashionResColorGroupIdById(resId)

        return self:CheckHasColor(colorGroupId, color)
    end
    return false
end

function XBigWorldCommanderDIYModel:CheckHasColor(colorGroupId, color)
    local colorGroup = self:GetDlcPlayerFashionColorGroupColorIdByGroupId(colorGroupId)
    if XTool.IsTableEmpty(colorGroup) then
        return false
    end
    for _, colorId in pairs(colorGroup) do
        if colorId == color then
            return true
        end
    end
end

function XBigWorldCommanderDIYModel:CheckPartUnlcok(partId)
    return self._UnlockPartMap[partId] or false
end

function XBigWorldCommanderDIYModel:_WearSuit(typeId, partId, outfitType)
    local partIds = self:GetDlcPlayerFashionPartPartsById(partId)
    local incompatibleParts = self:GetDlcPlayerFashionPartIncompatibleTypeById(partId)
    self:_WearPart(typeId, partId, outfitType)
    if not XTool.IsTableEmpty(partIds) then
        for _, suitPartId in pairs(partIds) do
            local suitPartTypeId = self:GetDlcPlayerFashionPartTypeIdById(suitPartId)
            if incompatibleParts[suitPartTypeId] then
                self:_WearPart(suitPartTypeId, suitPartId, outfitType)
            end
        end
    end
end

function XBigWorldCommanderDIYModel:_WearPart(typeId, partId, outfitType)
    if self:_CheckWearIsOverflow(typeId, partId) then
        self:_ClearCheckData()
        return
    end
    --     逻辑流程：
    -- 处理套装类型参数，默认当前套装。
    -- 准备穿戴数据和不兼容检查。
    -- 清理冲突部件。
    -- 更新穿戴状态为新部件。
    local targetOutfitType = outfitType or self._CurCommanderOutfitType
    local wearData = self:GetWearData(typeId, targetOutfitType)
    -- 穿戴的目标是有东西再检查是否冲突
    if partId then
        local parts = self:GetDlcPlayerFashionPartIncompatiblePartsByTypeId(partId)
        self:TackOffParts(parts, targetOutfitType)
    end
    if wearData then
        wearData:SetPartId(partId)
    end
    self:_ClearCheckData()
end

function XBigWorldCommanderDIYModel:TackOffParts(parts, outfitType)
    for i, part in ipairs(parts) do
        local typeId = self:GetDlcPlayerFashionPartTypeIdById(part)
        local wearData = self:GetWearData(typeId, outfitType)
        if wearData:GetPartId() == part then
            if wearData:IsSuit() then
                self:_TackOffSuit(outfitType)
            else
                self:TackOffPart(typeId, part, outfitType)
            end
        end
    end
end

function XBigWorldCommanderDIYModel:_WearColor(typeId, colorId, outfitType)
    local wearData = self:GetWearData(typeId, outfitType)

    if wearData then
        wearData:SetColorId(colorId)
    end
end

function XBigWorldCommanderDIYModel:_TackOffSuit(outfitType)
    -- 逻辑流程：
    -- 记录不兼容类型映射，避免重复清理。
    -- 遍历不兼容类型，清除对应部件（这些是套装穿戴时被替代的部件）。
    -- 遍历套装部件 ID，清除属于该套装的部件（但跳过已在不兼容清理中处理的类型）。
    -- 清除套装主部件，确保整套服装完全脱下。
    local wearData = self:GetWearData(XEnumConst.PlayerFashion.PartType.Suit, outfitType)

    if wearData:IsWaeredPart() then
        local partIds = self:GetDlcPlayerFashionPartPartsById(wearData:GetPartId())
        local incompatibleTypes = self:GetDlcPlayerFashionPartIncompatibleTypeById(wearData:GetPartId())
        local incompatibleTypeMap = {}

        if not XTool.IsTableEmpty(partIds) then
            for _, incompatibleType in pairs(incompatibleTypes) do
                if self:GetWearData(incompatibleType, outfitType) then
                    incompatibleTypeMap[incompatibleType] = true
                    self:GetWearData(incompatibleType, outfitType):ClearPart()
                end
            end
        end
        if not XTool.IsTableEmpty(partIds) then
            for _, partId in pairs(partIds) do
                local typeId = self:GetDlcPlayerFashionPartTypeIdById(partId)

                if not incompatibleTypeMap[typeId] then
                    local suitWearData = self:GetWearData(typeId, outfitType)

                    if suitWearData:GetPartId() == partId then
                        suitWearData:ClearPart()
                    end
                end
            end
        end
        wearData:ClearPart()
    end
end

function XBigWorldCommanderDIYModel:_TryTackOffSuit(typeId, outfitType)
    local wearData = self:GetWearData(XEnumConst.PlayerFashion.PartType.Suit, outfitType)

    if wearData and wearData:IsWaeredPart() then
        local incompatibleTypes = self:GetDlcPlayerFashionPartIncompatibleTypeById(wearData:GetPartId())

        if not XTool.IsTableEmpty(incompatibleTypes) then
            for _, incompatibleType in pairs(incompatibleTypes) do
                if incompatibleType == typeId then
                    self:_TackOffSuit(outfitType)
                    return true
                end
            end
        end
    end

    return false
end

function XBigWorldCommanderDIYModel:_TryRecoverSuit(typeId, outfitType)
    local wearData = self:GetWearData(XEnumConst.PlayerFashion.PartType.Suit, outfitType)

    if wearData and wearData:IsWaeredPart() then
        local partIds = self:GetDlcPlayerFashionPartPartsById(wearData:GetPartId())

        if not XTool.IsTableEmpty(partIds) then
            for _, partId in pairs(partIds) do
                local suitTypeId = self:GetDlcPlayerFashionPartTypeIdById(partId)

                if suitTypeId == typeId then
                    self:_WearPart(typeId, partId, outfitType)

                    return true
                end
            end
        end
    end

    return false
end

---@param commanderFashionOutfits table 设置指挥官时装数据
---@param curCommanderOutfitType number 当前指挥官套装类型
function XBigWorldCommanderDIYModel:SetCommanderFashionOutfitsData(commanderFashionOutfits, curCommanderOutfitType)
    self._CurCommanderOutfitType = curCommanderOutfitType or 0
    if commanderFashionOutfits and not XTool.IsTableEmpty(commanderFashionOutfits) then
        self._CommanderFashionOutfits = commanderFashionOutfits
        local fashionList = self._CommanderFashionOutfits[self._CurCommanderOutfitType].WearFashionDict
        if not XTool.IsTableEmpty(fashionList) then
            self:DoSetCommanderFashionOutfitsData(fashionList, self._CurCommanderOutfitType)
        end
    else
        XLog.Error("指挥官时装数据为空，无法设置时装数据")
    end
end

function XBigWorldCommanderDIYModel:DoSetCommanderFashionOutfitsData(fashionList, targetOutfitType)
    if not XTool.IsTableEmpty(fashionList) then
        -- 不可同时穿戴套装和其他部件
        -- 先穿戴套装
        for typeId, fashion in pairs(fashionList) do
            if self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
                self:_WearSuit(typeId, fashion.PartId, targetOutfitType)
            end
        end
        -- 再穿戴其他部件
        for typeId, fashion in pairs(fashionList) do
            if not self:GetDlcPlayerFashionTypeIsSuitByTypeId(typeId) then
                self:_WearPart(typeId, fashion.PartId, targetOutfitType)
                self:_WearColor(typeId, fashion.ColourId, targetOutfitType)
            end
        end
        for typeId, v in pairs(self:GetWearDataMap(targetOutfitType)) do
            XLog.Debug(v:GetTypeId() .. " " .. v:GetPartId() .. " " .. v:GetColorId())
        end
    end
end

---@return table 获取指挥官时装数据
function XBigWorldCommanderDIYModel:GetCommanderFashionOutfitsData()
    return self._CommanderFashionOutfits or {}
end

---@param typeId number
---@return number partId
function XBigWorldCommanderDIYModel:GetTypeDefaultPartId(typeId, outfitType)
    local targetOutfitType = outfitType or self._CurCommanderOutfitType
    local typeMap = self._CacheOutfitDefaultPartIds[targetOutfitType]
    if typeMap then
        return typeMap[typeId] or 0
    else
        local outfitDefaultPartConfig = self:GetOutfitDefaultPartConfigById(targetOutfitType)
        if outfitDefaultPartConfig then
            typeMap = {}
            for i, partId in ipairs(outfitDefaultPartConfig) do
                local partConfig = self:GetDlcPlayerFashionPartConfigById(partId)
                typeMap[partConfig.TypeId] = partId
                self._CacheOutfitDefaultPartIds[targetOutfitType] = typeMap
            end
            return typeMap[typeId] or 0
        else
            XLog.Error("GetTypeDefaultPartId Error")
            return 0
        end
    end
end

function XBigWorldCommanderDIYModel:GetRecordPartMap()
    if not self._RecordPartMap then
        self:_InitRecordPartMap()
    end

    return self._RecordPartMap
end

function XBigWorldCommanderDIYModel:SetRecordPart(partId)
    if not self._RecordPartMap then
        self:_InitRecordPartMap()
    end

    self._RecordPartMap[partId] = true
end

function XBigWorldCommanderDIYModel:_InitRecordPartMap()
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

function XBigWorldCommanderDIYModel:_RecordPartMapToLocal()
    if self._RecordPartMap then
        local result = {}

        for partId, _ in pairs(self._RecordPartMap) do
            table.insert(result, partId)
        end

        XSaveTool.SaveData(self:_GetRecordPartKey(), table.concat(result, "|"))
        self._RecordPartMap = false
    end
end

function XBigWorldCommanderDIYModel:_GetRecordPartKey()
    return "BW_DIY_PART_UNLOCK_" .. tostring(XPlayer.Id)
end

return XBigWorldCommanderDIYModel
