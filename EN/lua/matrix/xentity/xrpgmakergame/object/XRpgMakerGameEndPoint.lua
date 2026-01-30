local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs

local Default = {
    _OpenStatus = 0,       --状态，1开启，0关闭
}

---推箱子终点对象
---@class XRpgMakerGameEndPoint : XRpgMakerGameObject
local XRpgMakerGameEndPoint = XClass(XRpgMakerGameObject, "XRpgMakerGameEndPoint")

function XRpgMakerGameEndPoint:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerGameEndPoint:InitData(mapObjData)
    self.StatusIsChange = false  --新的状态是否和旧的不同
    -- local endPointId = XMVCA.XRpgMakerGame:GetConfig():GetMapEndPointId(mapId)
    -- local pointX = XRpgMakerGameConfigs.GetRpgMakerGameEndPointX(endPointId)
    -- local pointY = XRpgMakerGameConfigs.GetRpgMakerGameEndPointY(endPointId)
    -- local endPointType = XRpgMakerGameConfigs.GetRpgMakerGameEndPointType(endPointId)
    -- self:SetId(endPointId)

    self.MapObjData = mapObjData
    local pointX = mapObjData:GetX()
    local pointY = mapObjData:GetY()
    local endPointType = mapObjData:GetParams()[1]

    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:UpdateData({OpenStatus = endPointType})
end

---@return XMapObjectData
function XRpgMakerGameEndPoint:GetMapObjData()
    return self.MapObjData
end

function XRpgMakerGameEndPoint:UpdateData(data)
    self:SetStatusIsChange(self._OpenStatus ~= data.OpenStatus)
    self._OpenStatus = data.OpenStatus
end

function XRpgMakerGameEndPoint:SetStatusIsChange(isChange)
    self.StatusIsChange = isChange
end

function XRpgMakerGameEndPoint:IsOpen()
    return self._OpenStatus == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEndPointType.DefaultOpen
end

function XRpgMakerGameEndPoint:EndPointOpen()
    self:SetStatusIsChange(true)
    self._OpenStatus = XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEndPointType.DefaultOpen
end

function XRpgMakerGameEndPoint:UpdateObjStatus()
    self:PlayEndPointStatusChangeAction()
end

function XRpgMakerGameEndPoint:PlayEndPointStatusChangeAction(action, cb)
    local modelKey = self:IsOpen() and XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.GoldOpen or XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.GoldClose
    local modelPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(modelKey)
    local sceneObjRoot = self:GetGameObjModelRoot()
    self:LoadModel(modelPath, sceneObjRoot, nil, modelKey)

    if self.StatusIsChange then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_EndPointOpen)
    end
    
    if cb then
        cb()
    end
end

return XRpgMakerGameEndPoint