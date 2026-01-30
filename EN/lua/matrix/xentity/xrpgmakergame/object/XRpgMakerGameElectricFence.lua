local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation

local Default = {
    _ElectricStatus = 1,       --状态，1开启，0关闭
}

---电网对象
---@class XRpgMakerGameElectricFence:XRpgMakerGameObject
local XRpgMakerGameElectricFence = XClass(XRpgMakerGameObject, "XRpgMakerGameElectricFence")

function XRpgMakerGameElectricFence:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self:InitData()
end

function XRpgMakerGameElectricFence:Dispose()
    if self.ElectricFenceEffect then
        CS.UnityEngine.GameObject.Destroy(self.ElectricFenceEffect)
        self.ElectricFenceEffect = nil
    end
    XRpgMakerGameElectricFence.Super.Dispose(self)
end

function XRpgMakerGameElectricFence:InitData()
    local id = self:GetId()
    -- local pointX = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceX(id)
    -- local pointY = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceY(id)
    -- self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:SetElectricStatus(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameElectricFenceStatus.Open)
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
end

---@param mapObjData XMapObjectData
function XRpgMakerGameElectricFence:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
    self:SetElectricStatus(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameElectricFenceStatus.Open)
end

--改变方向
function XRpgMakerGameElectricFence:ChangeDirectionAction(action, cb)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local modelKey = self:GetModelKey()
    local cubeSize = XMVCA.XRpgMakerGame:GetConfig():GetModelSize(modelKey)

    local objPosition = transform.position
    local direction = action.Direction
    local directionPos
    if direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridLeft then
        directionPos = objPosition - Vector3(cubeSize.x / 2, 0, 0)
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridRight then
        directionPos = objPosition + Vector3(cubeSize.x / 2, 0, 0)
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridTop then
        directionPos = objPosition + Vector3(0, 0, cubeSize.z / 2)
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridBottom then
        directionPos = objPosition - Vector3(0, 0, cubeSize.z / 2)
    end

    local lookRotation = LookRotation(directionPos - objPosition)
    self:SetGameObjectRotation(lookRotation)
    self:SetGameObjectPosition(directionPos)

    if cb then
        cb()
    end
end

function XRpgMakerGameElectricFence:SetElectricStatus(electricStatus)
    self._ElectricStatus = electricStatus
end

--播放状态切换动画
function XRpgMakerGameElectricFence:PlayElectricFenceStatusChangeAction(cb, isNotPlaySound)
    if self.ElectricFenceEffect then
        local isShow = self._ElectricStatus == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameElectricFenceStatus.Open and true or false
        self.ElectricFenceEffect.gameObject:SetActiveEx(isShow)
    end

    if cb then
        cb()
    end
end

--是否会被阻挡
function XRpgMakerGameElectricFence:IsElectricFenceInMiddle(curPosX, curPosY, direction, nextPosX, nextPosY)
    if not self:IsSamePoint(curPosX, curPosY) and not self:IsSamePoint(nextPosX, nextPosY)  then
        return false
    end

    -- local id = self:GetId()
    -- local electricDirection = XRpgMakerGameConfigs.GetRpgMakerGameElectricDirection(id)
    local electricDirection = self.MapObjData:GetParams()[1]
    if self:IsSamePoint(curPosX, curPosY) and electricDirection == direction then
        return true
    end

    --下一个坐标和电墙位置相同，且方向相反
    if self:IsSamePoint(nextPosX, nextPosY)
        and ((electricDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridLeft and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight)
        or (electricDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridRight and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft)
        or (electricDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridTop and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown)
        or (electricDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridBottom and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp)) then
        return true
    end

    return false
end

function XRpgMakerGameElectricFence:OnLoadComplete()
    local key = XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.ElectricFenceEffect
    local modelPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(key)
    local resource = self:ResourceManagerLoad(modelPath)
    local asset = resource and resource.Asset
    if asset then
        self.ElectricFenceEffect = self:LoadEffect(asset)
    end
    XRpgMakerGameElectricFence.Super.OnLoadComplete(self)
end

return XRpgMakerGameElectricFence