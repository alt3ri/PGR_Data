---@class XSgFurnitureData 家具数据
local XSgFurnitureData = XClass(nil, "XSgFurnitureData")

local ScaleRatio = 1000

function XSgFurnitureData:Ctor(id, isAlbumPhoto)
    self:Reset()
    if isAlbumPhoto then
        self._Id = 0
        self._PhotoId = id
    else
        self._Id = id
        self._PhotoId = 0
    end
end

function XSgFurnitureData:Reset()
    --唯一id
    self._Id = 0
    --本地照片Id与家具Id互斥，只能有一个值是有效的
    self._PhotoId = 0
    --配置id
    self._CfgId = 0
    --坐标
    self._X = 0
    --坐标
    self._Y = 0
    --角度
    self._Angle = 0
    --层级
    self._Layer = 0
    --下标
    self._Index = 0
    --缩放
    self._Scale = 1000
end

function XSgFurnitureData:UpdateData(data)
    if not data then
        return
    end
    self._Id = data.Id
    self._PhotoId = data.PhotoId or 0
    self._CfgId = data.CfgId
    self._X = data.X or 0
    self._Y = data.Y or 0
    self._Angle = data.Angle or 0
    self._Layer = data.Layer or 0
    self._Index = data.Index or 0
    self._Scale = data.Scale or 1000
end

function XSgFurnitureData:GetId()
    if self._Id > 0 then
        return self._Id
    end
    return self._PhotoId
end

function XSgFurnitureData:GetPhotoId()
    return self._PhotoId
end

function XSgFurnitureData:GetCfgId()
    return self._CfgId
end

function XSgFurnitureData:GetPos()
    return self._X, self._Y
end

function XSgFurnitureData:GetAngle()
    return self._Angle
end

function XSgFurnitureData:GetLayer()
    return self._Layer
end

function XSgFurnitureData:GetIndex()
    return self._Index
end

function XSgFurnitureData:SetPos(x, y)
    local ratio = XMVCA.XSkyGardenDorm.Ratio
    self._X = math.floor(ratio * x)
    self._Y = math.floor(ratio * y)
end

function XSgFurnitureData:SetAngle(angle)
    local ratio = XMVCA.XSkyGardenDorm.Ratio
    self._Angle = math.floor(angle * ratio)
end

function XSgFurnitureData:SetLayer(layer)
    self._Layer = layer
end

function XSgFurnitureData:SetIndex(index)
    self._Index = index
end

function XSgFurnitureData:SetCfgId(cfgId)
    self._CfgId = cfgId
end

function XSgFurnitureData:IsAlbumPhoto()
    return self._PhotoId > 0 and self._Id <= 0
end

function XSgFurnitureData:GetScale()
    return self._Scale / ScaleRatio
end

function XSgFurnitureData:SetScale(scale)
    self._Scale = math.floor(scale * ScaleRatio)
end

---@param furniture XSgFurnitureData
function XSgFurnitureData:Equal(furniture)
    if not furniture then
        return false
    end
    if self._Id ~= furniture:GetId() and self._PhotoId ~= furniture:GetId() then
        return false
    end
    if self._CfgId ~= furniture:GetCfgId() then
        return false
    end
    local x, y = furniture:GetPos()
    --因为存储的服务器是 float * 1000000, 把误差控制在0.001内都算相等
    if math.abs(self._X - x) > 1000 or math.abs(self._Y - y) > 1000 then
        return false
    end

    if self:GetAngle() ~= furniture:GetAngle() then
        return false
    end

    if self:GetLayer() ~= furniture:GetLayer() then
        return false
    end

    if self:GetIndex() ~= furniture:GetIndex() then
        return false
    end

    if self:GetScale() ~= furniture:GetScale() then
        return false
    end
    
    return true
end

function XSgFurnitureData:ToServerData()
    if not self._ServerData then
        self._ServerData = {
            Id = 0,
            PhotoId = 0,
            CfgId = 0,
            X = 0,
            Y = 0,
            Angle = 0,
            Layer = 0,
            Index = 0,
            Scale = 1000
        }
    end
    self._ServerData.Id = self._Id
    self._ServerData.PhotoId = self._PhotoId
    self._ServerData.CfgId = self._CfgId
    self._ServerData.X = self._X
    self._ServerData.Y = self._Y
    self._ServerData.Angle = self._Angle
    self._ServerData.Layer = self._Layer
    self._ServerData.Index = self._Index
    self._ServerData.Scale = self._Scale
    
    return self._ServerData
end

---@return XSgFurnitureData
function XSgFurnitureData:Clone()
    ---@type XSgFurnitureData
    local data = XSgFurnitureData.New(self:GetId(), self:IsAlbumPhoto())
    data:UpdateData({
        Id = self._Id,
        PhotoId = self._PhotoId,
        CfgId = self._CfgId,
        X = self._X,
        Y = self._Y,
        Angle = self._Angle,
        Layer = self._Layer,
        Index = self._Index,
        Scale = self._Scale
    })
    return data
end

return XSgFurnitureData