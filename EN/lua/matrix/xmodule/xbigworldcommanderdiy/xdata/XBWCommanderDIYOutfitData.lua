local XBWCommanderDIYWearData = require("XModule/XBigWorldCommanderDIY/XData/XBWCommanderDIYWearData")

---@class XBWCommanderDIYOutfitData
---@field OutfitType number XEnumConst.PlayerFashion.OutfitType
---@field wearDataMap table<number, XBWCommanderDIYWearData>
---@description  CommanderDIYOutfitData 一套衣服。一套衣服会包括全身各个部件
local XBWCommanderDIYOutfitData = XClass(nil, "XBWCommanderDIYWearData")

function XBWCommanderDIYOutfitData:Ctor(outfitType)
    self.OutfitType = outfitType or XEnumConst.PlayerFashion.OutfitType.Normal
    self.wearDataMap = {}
    for _, partType in pairs(XEnumConst.PlayerFashion.PartType) do
        local partId = 0
        local colorId = 0
        self.wearDataMap[partType] = XBWCommanderDIYWearData.New(partType, partId, colorId, outfitType)
    end
end

---@param partType number XEnumConst.PlayerFashion.PartType
---@return XBWCommanderDIYWearData
function XBWCommanderDIYOutfitData:GetWearData(partType)
    return self.wearDataMap[partType]
end

---@return table<number, XBWCommanderDIYWearData>
function XBWCommanderDIYOutfitData:GetWearDataMap()
    return self.wearDataMap
end

---@param partType number XEnumConst.PlayerFashion.PartType
---@param partId number
---@param colorId number
function XBWCommanderDIYOutfitData:WearPart(partId, colorId)
    local partType = XMVCA.XBigWorldCommanderDIY:GetPartTypeId(partId)
    if not partType then
        XLog.Error("XBWCommanderDIYOutfitData:WearPart error: partId not found")
        return
    end
    if partType == XEnumConst.PlayerFashion.PartType.Suit then
        local t = XMVCA.XBigWorldCommanderDIY:GetSuitPartIds(partId)
        for i, suitPartId in ipairs(t) do
            local suitPartType = XMVCA.XBigWorldCommanderDIY:GetPartTypeId(suitPartId)
            self.wearDataMap[suitPartType]:SetPartId(suitPartId)
        end
    end
    if colorId ~= nil then
        self.wearDataMap[partType]:SetPartId(partId):SetColorId(colorId)
    else
        self.wearDataMap[partType]:SetPartId(partId)
    end
end

function XBWCommanderDIYOutfitData:IsWearPart(partType)
    return self.wearDataMap[partType]:IsWearPart()
end

function XBWCommanderDIYOutfitData:IsWearSuit()
    return self.wearDataMap[XEnumConst.PlayerFashion.PartType.Suit]:IsEmpty()
end

return XBWCommanderDIYOutfitData
