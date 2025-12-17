local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

---水、冰对象
---@class XRpgMakerGameWaterData:XRpgMakerGameObject
local XRpgMakerGameWaterData = XClass(XRpgMakerGameObject, "XRpgMakerGameWaterData")

function XRpgMakerGameWaterData:Ctor(id, gameObject)
    self.WaterStatus = XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water
    self.IsCheckPlayFlat = false    --是否需要根据当前的状态加载对应的特效
end

function XRpgMakerGameWaterData:InitData()
    -- local id = self:GetId()
    -- local x = XRpgMakerGameConfigs.GetEntityX(id)
    -- local y = XRpgMakerGameConfigs.GetEntityY(id)
    -- self:UpdatePosition({PositionX = x, PositionY = y})
    -- local type = XRpgMakerGameConfigs.GetEntityType(id)
    -- self:SetStatus(type == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Water and 
    --     XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water or
    --     XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice)
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
end

-- 重置关卡
function XRpgMakerGameWaterData:OnStageReset()
    self.WaterStatus = nil
    self:InitDataByMapObjData(self.MapObjData)

    local scene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    ---@type XRpgMakerGameCube
    local cubeObj = scene:GetCubeObj(self:GetPositionY(), self:GetPositionX())
    local poolModelPath = scene:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Pool)
    cubeObj:LoadModel(poolModelPath)
end

---@param mapObjData XMapObjectData
function XRpgMakerGameWaterData:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
    self:SetStatus(self.MapObjData:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water and 
        XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water or
        XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice)
end

---@return XMapObjectData
function XRpgMakerGameWaterData:GetMapObjData()
    return self.MapObjData
end

--1水，2冰
function XRpgMakerGameWaterData:SetStatus(waterType)
    self.LastWaterStatus = self.WaterStatus
    if self.WaterStatus ~= waterType then
        self.IsCheckPlayFlat = true
    end
    self.WaterStatus = waterType
end

function XRpgMakerGameWaterData:GetStatus()
    return self.WaterStatus
end

function XRpgMakerGameWaterData:IsStatusWater()
    return self.WaterStatus == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water
end

--检查加载哪种特效
function XRpgMakerGameWaterData:CheckPlayFlat()
    if not self.IsCheckPlayFlat then
        return
    end

    local status = self:GetStatus()
    
    if status == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Disappear then
        local path = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterVapor)
        self:LoadModel(path, nil, nil, XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterVapor)
    elseif status == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Water then
        if self.LastWaterStatus == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice then
            local modelPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Melt)
            self:LoadModel(modelPath, nil, nil, XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Melt)
            
            XScheduleManager.ScheduleOnce(function()
                self:LoadModel(XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterRipper))
            end, 500)
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Melt)
        else
            local modelPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterRipper)
            self:LoadModel(modelPath, nil, nil, XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.WaterRipper)
        end
    elseif status == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Ice then
        local modelPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Freeze)
        self:LoadModel(modelPath, nil, nil, XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Freeze)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Frezz)
    end
    
    self:RefreshCubePrefab()
    
    self.IsCheckPlayFlat = false
end

-- 刷新底部Cube
function XRpgMakerGameWaterData:RefreshCubePrefab()
    local scene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    local posX = self:GetPositionX()
    local posY = self:GetPositionY()
    local cubeModelPath = nil
    if self.WaterStatus ~= XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameWaterType.Disappear then
        cubeModelPath = scene:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Pool)
    else
        local curChapterGroupId = XDataCenter.RpgMakerGameManager.GetCurChapterGroupId()
        local cubePrefabs = scene:GetConfig():GetChapterGroupGroundPrefab(curChapterGroupId)
        cubeModelPath = (posX + posY) % 2 == 0 and cubePrefabs[1] or cubePrefabs[2]
    end

    ---@type XRpgMakerGameCube
    local cubeObj = scene:GetCubeObj(posY, posX)
    if cubeObj.ModelPath ~= cubeModelPath then
        cubeObj:ChangeCubeWithScaleAnim(cubeModelPath)
    end
end

return XRpgMakerGameWaterData