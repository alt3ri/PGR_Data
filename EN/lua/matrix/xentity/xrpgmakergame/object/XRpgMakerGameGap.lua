local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation

local Default = {
    _BlockStatus = 0,       --状态，1阻挡，0不阻挡
}

---缝隙对象
---@class XRpgMakerGameGap:XRpgMakerGameObject
local XRpgMakerGameGap = XClass(XRpgMakerGameObject, "XRpgMakerGameGap")

function XRpgMakerGameGap:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

---@param mapObjData XMapObjectData
function XRpgMakerGameGap:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
end

--改变方向
function XRpgMakerGameGap:ChangeDirectionAction(action, cb)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local cubeSize = self:GetGameObjSize()
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

--是否会被阻挡
function XRpgMakerGameGap:IsGapInMiddle(curPosX, curPosY, direction, nextPosX, nextPosY)
    if not self:IsSamePoint(curPosX, curPosY) and not self:IsSamePoint(nextPosX, nextPosY) then
        return false
    end

    local curGapDirection = self.MapObjData:GetParams()[1]
    if self:IsSamePoint(curPosX, curPosY) and curGapDirection == direction then
        return true
    end

    --下一个坐标和缝隙位置相同，且方向相反
    if self:IsSamePoint(nextPosX, nextPosY)
        and ((curGapDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridLeft and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveRight)
        or (curGapDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridRight and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveLeft)
        or (curGapDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridTop and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveDown)
        or (curGapDirection == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridBottom and direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameMoveDirection.MoveUp)) then
        return true
    end

    return false
end

return XRpgMakerGameGap