
local XSgFurnitureData = require("XModule/XSkyGardenDorm/Data/XSgFurnitureData")

---@class XSgContainerFurnitureData 容器数据
---@field _Container XSgFurnitureData 
---@field _FurnitureDict table<number, XSgFurnitureData>
---@field _PhotoDict table<number, XSgFurnitureData>
local XSgContainerFurnitureData = XClass(nil, "XSgContainerFurnitureData")

function XSgContainerFurnitureData:Ctor()
    self._FurnitureDict = {}
    self._PhotoDict = {}
end

function XSgContainerFurnitureData:UpdateData(data)
    if not data then
        return
    end
    local container = data.Container
    if not self._Container then
        self._Container = XSgFurnitureData.New(container.Id)
    end
    self._Container:UpdateData(container)
    local place = data.PlacementFurniture
    if not XTool.IsTableEmpty(place) then
        local newFurnitureDict, newPhotoDict = {}, {}
        for _, fData in pairs(place) do
            local id, photoId = fData.Id, fData.PhotoId
            local dict, targetId, newDict
            if id > 0 then
                dict = self._FurnitureDict
                targetId = id
                newDict = newFurnitureDict
            else
                dict = self._PhotoDict
                targetId = photoId
                newDict = newPhotoDict
            end
            local f = dict[targetId]
            if not f then
                f = XSgFurnitureData.New(targetId, id > 0)
            end
            f:UpdateData(fData)
            newDict[targetId] = f
        end

        self._FurnitureDict = newFurnitureDict
        self._PhotoDict = newPhotoDict
    else
        self:ClearAllFurniture()
    end
end

---@return XSgFurnitureData
function XSgContainerFurnitureData:GetContainer()
    return self._Container
end

function XSgContainerFurnitureData:ChangeContainer(id, cfgId)
    self._Container:UpdateData({
        Id = id,
        CfgId = cfgId
    })
end

function XSgContainerFurnitureData:ClearAllFurniture()
    self._FurnitureDict = {}
    self._PhotoDict = {}
end

function XSgContainerFurnitureData:GetFurnitureDict(isAlbumPhoto)
    local dict = isAlbumPhoto and self._PhotoDict or self._FurnitureDict
    return dict
end

---@return XSgFurnitureData
function XSgContainerFurnitureData:GetFurniture(id, isAlbumPhoto)
    local dict = isAlbumPhoto and self._PhotoDict or self._FurnitureDict
    return dict[id]
end

function XSgContainerFurnitureData:CheckContainFurnitureById(id, isAlbumPhoto)
    if self._Container and self._Container:GetId() == id then
        return true
    end
    local furniture = self:GetFurniture(id, isAlbumPhoto)
    return furniture ~= nil
end

function XSgContainerFurnitureData:AddFurniture(id, cfgId, index, layer, isAlbumPhoto)
    local dict = isAlbumPhoto and self._PhotoDict or self._FurnitureDict
    local f = dict[id]
    if not f then
        ---@type XSgFurnitureData
        f = XSgFurnitureData.New(id, isAlbumPhoto)
        dict[id] = f
    end
    f:SetCfgId(cfgId)
    f:SetIndex(index)
    f:SetLayer(layer)
end

function XSgContainerFurnitureData:RemoveFurniture(id, isAlbumPhoto)
    local dict = isAlbumPhoto and self._PhotoDict or self._FurnitureDict
    dict[id] = nil
end

---@param other XSgContainerFurnitureData
function XSgContainerFurnitureData:Equal(other)
    if not other then
        return false
    end
    if not self._Container:Equal(other:GetContainer()) then
        return false
    end
    local furnitureDict = other:GetFurnitureDict(false)
    for id, furniture in pairs(self._FurnitureDict) do
        local oF = furnitureDict[id]
        if not oF or not furniture:Equal(oF) then
            return false
        end
    end
    local photoDict = other:GetFurnitureDict(true)
    for id, furniture in pairs(self._PhotoDict) do
        local oF = photoDict[id]
        if not oF or not furniture:Equal(oF) then
            return false
        end
    end
    return XTool.GetTableCount(self._FurnitureDict) == XTool.GetTableCount(furnitureDict) 
            and XTool.GetTableCount(self._PhotoDict) == XTool.GetTableCount(photoDict)
end

function XSgContainerFurnitureData:ToServerData()
    local list = {}
    local minLayer = 99999999
    for _, furniture in pairs(self._FurnitureDict) do
        local data = furniture:ToServerData()
        minLayer = math.min(minLayer, data.Layer)
        list[#list + 1] = data
    end
    for _, furniture in pairs(self._PhotoDict) do
        local data = furniture:ToServerData()
        minLayer = math.min(minLayer, data.Layer)
        list[#list + 1] = data
    end
    --避免超出上限，每次tongue服务器时，将layer同比减少
    if minLayer > 1000 then
        for _, data in pairs(list) do
            data.Layer = data.Layer - minLayer
        end
    end
    
    return {
        Container = self._Container:ToServerData(),
        PlacementFurniture = list
    }
end

function XSgContainerFurnitureData:IsEmpty()
    if self._Container then
        return false
    end
    if not XTool.IsTableEmpty(self._FurnitureDict) then
        return false
    end
    return XTool.IsTableEmpty(self._PhotoDict)
end

---@return XSgContainerFurnitureData
function XSgContainerFurnitureData:Clone()
    ---@type XSgContainerFurnitureData
    local data = XSgContainerFurnitureData.New()
    
    data._Container = self._Container:Clone()
    local furnitureDict = data._FurnitureDict
    for id, f in pairs(self._FurnitureDict) do
        furnitureDict[id] = f:Clone()
    end
    local photoDict = data._PhotoDict
    for id, f in pairs(self._PhotoDict) do
        photoDict[id] = f:Clone()
    end
    return data
end

return XSgContainerFurnitureData