local XSkyGardenDormConfig = require("XModule/XSkyGardenDorm/XSkyGardenDormConfig")
local XSgDormFightFurnitureData = require("XModule/XSkyGardenDorm/Data/XSgDormFightFurnitureData")
local XSgDormFightContainerData = require("XModule/XSkyGardenDorm/Data/XSgDormFightContainerData")

---@class XSkyGardenDormModel : XSkyGardenDormConfig
---@field _DormData XSgDormData
---@field _FightFurnitureDict table<number, XSgDormFightFurnitureData>
---@field _FightPhotoDict table<number, XSgDormFightFurnitureData>
local XSkyGardenDormModel = XClass(XSkyGardenDormConfig, "XSkyGardenDormModel")
function XSkyGardenDormModel:OnInit()
    self._FightFurnitureDict = {}
    self._FightPhotoDict = {}
    self._Layer = 0
    XSkyGardenDormConfig.OnInit(self)
end

function XSkyGardenDormModel:ClearPrivate()
    XSkyGardenDormConfig.ClearPrivate(self)
end

function XSkyGardenDormModel:ResetAll()
    if self._DormData then
        self._DormData:Reset()
    end
    self._FightFurnitureDict = nil
    self._FightPhotoDict = nil
    self._DormData = nil
    self._WallFightData = nil
    self._GiftShelfFightData = nil
    self._HandBookNewMark = nil
    XSkyGardenDormConfig.ResetAll(self)
end

function XSkyGardenDormModel:NotifySgDormData(data)
    self:GetDormData():NotifySgDormData(data)
end

function XSkyGardenDormModel:NotifySgPhotoData(data)
    self:GetDormData():NotifySgPhotoData(data)
end

function XSkyGardenDormModel:NotifySgDormFurnitureAdd(data)
    if not data then
        return
    end
    self:GetDormData():AddFurnitureList(data.AddFurnitureList)
end

function XSkyGardenDormModel:NotifySgDormFashionAdd(data)
    self:GetDormData():NotifySgDormFashionAdd(data)
end

function XSkyGardenDormModel:NotifySgDormCurLayout(data)
    self:GetDormData():NotifySgDormCurLayout(data)
end

function XSkyGardenDormModel:NotifySgDormLayoutChanged(data)
    self:GetDormData():NotifySgDormLayoutChanged(data)
end

---@return XSgDormData
function XSkyGardenDormModel:GetDormData()
    if not self._DormData then
        self._DormData = require("XModule/XSkyGardenDorm/Data/XSgDormData").New()
    end
    return self._DormData
end

function XSkyGardenDormModel:CheckContainFurnitureById(areaType, id, isAlbumPhoto)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():CheckContainFurnitureById(areaType, layoutId, id, isAlbumPhoto)
end

function XSkyGardenDormModel:GetLayoutContainer(areaType, index)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():GetLayoutContainer(areaType, layoutId, index)
end

function XSkyGardenDormModel:GetContainerFurnitureData(areaType)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():GetContainerFurnitureData(areaType, layoutId)
end

---@return XSgDormFightContainerData
function XSkyGardenDormModel:GetWallFightData()
    if not self._WallFightData then
        self._WallFightData = XSgDormFightContainerData.New()
    end
    
    return self._WallFightData
end

---@return XSgDormFightContainerData
function XSkyGardenDormModel:GetGiftShelfFightData()
    if not self._GiftShelfFightData then
        self._GiftShelfFightData = XSgDormFightContainerData.New()
    end
    
    return self._GiftShelfFightData
end

function XSkyGardenDormModel:GetLayoutIdByAreaType(areaType)
    local id = self:GetDormData():GetLayoutIdByAreaType(areaType)
    if not id then
        local list = self:GetDormLayoutIdList(areaType)
        id = list[1]
    end
    return id
end

function XSkyGardenDormModel:SetLayoutIdWithAreaType(areaType, id)
    self:GetDormData():SetLayoutIdWithAreaType(areaType, id)
end

function XSkyGardenDormModel:UpdateFightFurnitureData(fightDataList)
    if XTool.IsTableEmpty(fightDataList) then
        return
    end
    for index, data in pairs(fightDataList) do
        local id = data.Id
        local photoId = data.PhotoId
        if id > 0 then
            self:AddFightFurnitureData(id, data, index, false)
        else
            self:AddFightFurnitureData(photoId, data, index, true)
        end
        
    end
end

function XSkyGardenDormModel:AddFightFurnitureData(id, data, index, isAlbumPhoto)
    local dict
    if isAlbumPhoto then
        if not self._FightPhotoDict then
            self._FightPhotoDict = {}
        end
        dict = self._FightPhotoDict
    else
        if not self._FightFurnitureDict then
            self._FightFurnitureDict = {}
        end
        dict = self._FightFurnitureDict
    end
    local fightFurniture = dict[id]
    if not fightFurniture then
        fightFurniture = XSgDormFightFurnitureData.New(id)
        dict[id] = fightFurniture
    end
    
    local min, max, component
    if data.ActorRef then
        min, max = data.MinPos, data.MaxPos
        component = data.ActorRef
    else
        local giftShelfData = self:GetGiftShelfFightData()
        min, max = giftShelfData:GetSize(index)
        component = data.Transform
    end
    fightFurniture:UpdateData(min, max, component)
end

function XSkyGardenDormModel:RemoveFightFurnitureData(id, isAlbumPhoto)
    local dict
    if isAlbumPhoto then
        dict = self._FightPhotoDict
    else
        dict = self._FightFurnitureDict
    end
    if not dict then
        return
    end
    dict[id] = nil
end

function XSkyGardenDormModel:RemoveAllFightFurnitureData()
    self._FightFurnitureDict = {}
    self._FightPhotoDict = {}
end

---@return XSgDormFightFurnitureData
function XSkyGardenDormModel:GetFightFurnitureData(id, isAlbumPhoto)
    local dict
    if isAlbumPhoto then
        dict = self._FightPhotoDict
    else
        dict = self._FightFurnitureDict
    end
    if not dict then
        return
    end
    
    local fightFurniture = dict[id]
    if not fightFurniture then
        XLog.Error("不存在家具Transform数据! Id = " .. id)
        return
    end
    return fightFurniture
end

function XSkyGardenDormModel:GetFightInitData(containWall, containGift)
    
    local photos, adorns, gifts

    if containWall then
        --照片墙
        local containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.Wall)
        photos, adorns = self:GetPhotoWallFightInitData(containerFurnitureData)
    end

    if containGift then
        --摆件架
        local containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.GiftShelf)
        gifts = self:GetGiftShelfFightInitData(containerFurnitureData)
        
    end
    return photos, adorns, gifts
end

---@param containerFurnitureData XSgContainerFurnitureData
function XSkyGardenDormModel:GetPhotoWallFightInitData(containerFurnitureData)
    if not containerFurnitureData then
        containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.Wall)
    end
    local photos, adorns = {}, {}
    if not containerFurnitureData then
        return photos, adorns
    end
    local photoType = XMVCA.XSkyGardenDorm.XSgFurnitureType.SystemPhoto
    local decorationType = XMVCA.XSkyGardenDorm.XSgFurnitureType.Decoration
    local ratio = XMVCA.XSkyGardenDorm.Ratio
    
    local dict = containerFurnitureData:GetFurnitureDict(false)
    for _, f in pairs(dict) do
        local cfgId = f:GetCfgId()
        local majorType = self:GetFurnitureMajorType(cfgId)
        local x, y = f:GetPos()
        if majorType == photoType then
            photos[#photos + 1] = {
                Id = f:GetId(),
                PhotoId = 0,
                SoId = self:GetFurnitureSceneObjId(cfgId),
                X = x / ratio,
                Y = y / ratio,
                Angle = f:GetAngle() / ratio,
                Layer = f:GetLayer(),
                SaltId = 0,
                Scale = f:GetScale(),
            }
        elseif majorType == decorationType then
            adorns[#adorns + 1] = {
                Id = f:GetId(),
                SoId = self:GetFurnitureSceneObjId(cfgId),
                X = x / ratio,
                Y = y / ratio,
                Angle = f:GetAngle() / ratio,
                Layer = f:GetLayer(),
                Scale = f:GetScale()
            }
        end
    end
    dict = containerFurnitureData:GetFurnitureDict(true)
    if not XTool.IsTableEmpty(dict) then
        for _, f in pairs(dict) do
            local x, y = f:GetPos()
            local photoId = f:GetPhotoId()
            photos[#photos + 1] = {
                Id = 0,
                PhotoId = photoId,
                SoId = 0,
                SaltId = self:GetDormData():GetAlbumPhotoSalt(photoId),
                X = x / ratio,
                Y = y / ratio,
                Angle = f:GetAngle() / ratio,
                Layer = f:GetLayer(),
                Scale = f:GetScale()
            }
        end
    end
    return photos, adorns
end

---@param containerFurnitureData XSgContainerFurnitureData
function XSkyGardenDormModel:GetGiftShelfFightInitData(containerFurnitureData)
    if not containerFurnitureData then
        containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.GiftShelf)
    end
    local giftType = XMVCA.XSkyGardenDorm.XSgFurnitureType.Gift
    local gifts = {}
    local dict = containerFurnitureData:GetFurnitureDict(false)
    for _, f in pairs(dict) do
        local cfgId = f:GetCfgId()
        local majorType = self:GetFurnitureMajorType(cfgId)
        if majorType == giftType then
            gifts[#gifts + 1] = {
                Id = f:GetId(),
                SoId = self:GetFurnitureSceneObjId(cfgId),
                PosIndex = f:GetIndex()
            }
        end
    end
    return gifts
end

function XSkyGardenDormModel:SetMaxLayer(layer)
    self._Layer = layer
end

function XSkyGardenDormModel:AddLayer()
    self._Layer = self._Layer + 1
    return self._Layer
end

function XSkyGardenDormModel:GetLayer()
    return self._Layer
end

function XSkyGardenDormModel:IsFashionUnlock(fashionId)
    local unlock = self:GetDormData():IsFashionUnlock(fashionId)
    if unlock then
        return true
    end
    return self:IsDefaultFashion(fashionId)
end

function XSkyGardenDormModel:GetCookieKey(key)
    return string.format("SKY_GARDEN_DORM_%s_%s", tostring(XPlayer.Id), key)
end

function XSkyGardenDormModel:InitHandBookNewMark()
    if self._HandBookNewMark then
        return
    end
    local key = self:GetCookieKey("HAND_BOOK_NEW_MARK")
    local data = XSaveTool.GetData(key)
    if not data then
        data = {}
    end
    self._HandBookNewMark = data
end

function XSkyGardenDormModel:SaveHandBookMark()
    if not self._HandBookNewMark then
        return
    end
    local key = self:GetCookieKey("HAND_BOOK_NEW_MARK")
    local data = XSaveTool.GetData(key)
    local equal
    if data then
        for type, dict in pairs(self._HandBookNewMark) do
            local tempDict = data[type]
            local cnt = 0
            for furnitureId, _ in pairs(dict) do
                if not tempDict or not tempDict[furnitureId] then
                    equal = false
                    break
                end
                cnt = cnt + 1
            end
            if XTool.GetTableCount(tempDict) ~= cnt or not equal then
                equal = false
                break
            end
        end
    else
        equal = false
    end
    
    --相等则不写入
    if equal then
        return
    end
    XSaveTool.SaveData(key, self._HandBookNewMark)
end

function XSkyGardenDormModel:CheckHandBookNewMark(type, furnitureId)
    self:InitHandBookNewMark()
    if type and type > 0 and furnitureId and furnitureId > 0 then
        return self:CheckHandBookNewMarkWithTypeAndFurnitureId(type, furnitureId)
    end

    if type and type > 0 then
        return self:CheckHandBookNewMarkWithType(type)
    end
    local typeList = self:GetHandBookTypeList()
    for _, t in pairs(typeList) do
        if self:CheckHandBookNewMarkWithType(t) then
            return true
        end
    end
    return false
end

function XSkyGardenDormModel:CheckHandBookNewMarkWithType(type)
    local list = self:GetHandBookFurnitureListByType(type)
    if XTool.IsTableEmpty(list) then
        return false
    end
    for _, furnitureId in pairs(list) do
        if self:CheckHandBookNewMarkWithTypeAndFurnitureId(type, furnitureId) then
            return true
        end
    end
    return false
end

function XSkyGardenDormModel:CheckHandBookNewMarkWithTypeAndFurnitureId(type, furnitureId)
    if not self:GetDormData():CheckFurnitureUnlockByConfigId(furnitureId) then
        return false
    end
    if not self._HandBookNewMark then
        return true
    end
    local dict = self._HandBookNewMark[type]
    if XTool.IsTableEmpty(dict) then
        return true
    end
    return dict[furnitureId] == nil
end

function XSkyGardenDormModel:MarkHandBookNewMark(type, furnitureId)
    if not self._HandBookNewMark then
        self._HandBookNewMark = {}
    end
    local dict = self._HandBookNewMark[type]
    if not dict then
        dict = {}
        self._HandBookNewMark[type] = dict
    end
    dict[furnitureId] = true
end


function XSkyGardenDormModel:GetDormLayoutIconFileName(areaType, id)
    return string.format("%s_sky_dorm_%s_%s", tostring(XPlayer.Id), tostring(areaType), tostring(id))
end

function XSkyGardenDormModel:GetAlbumPhotoTypeId()
    if not self._LocalPhotoTypeId then
        self._LocalPhotoTypeId = tonumber(self:GetConfigValue("LocalPhotoFurnitureTypeId", 1))
    end
    return self._LocalPhotoTypeId
end

return XSkyGardenDormModel