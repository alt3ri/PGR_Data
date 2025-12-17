local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local DieByTrapTime = CS.XGame.ClientConfig:GetInt("RpgMakerGameDieByTrapTime") / 1000  --草埔燃烧缩小动画时长

---草圃对象
---@class XRpgMakerGameGrassData:XRpgMakerGameObject
local XRpgMakerGameGrassData = XClass(XRpgMakerGameObject, "XRpgMakerGameGrassData")

function XRpgMakerGameGrassData:Ctor()
    self.RoundState = {} --key：回合数，value：是否显隐
end

function XRpgMakerGameGrassData:InitData()
    -- local id = self:GetId()
    -- local x = XRpgMakerGameConfigs.GetEntityX(id)
    -- local y = XRpgMakerGameConfigs.GetEntityY(id)
    -- self:UpdatePosition({PositionX = x, PositionY = y})
    local burnPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Burn)
    self:RemoveResource(burnPath)
    if not XTool.IsTableEmpty(self.MapObjData) then
        self:InitDataByMapObjData(self.MapObjData)
    end
    self:SetActive(true)
    self.IsBurned = false -- 是否已经烧毁
end

---@param mapObjData XMapObjectData
function XRpgMakerGameGrassData:InitDataByMapObjData(mapObjData)
    self.MapObjData = mapObjData
    self:UpdatePosition({PositionX = self.MapObjData:GetX(), PositionY = self.MapObjData:GetY()})
end

---@return XMapObjectData
function XRpgMakerGameGrassData:GetMapObjData()
    return self.MapObjData
end

--燃烧
function XRpgMakerGameGrassData:Burn()
    self:RemoveBurnTimer()
    local path = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Burn)
    local resource = self:ResourceManagerLoad(path)
    resource.Prefab.transform.position = XLuaVector3.New(0, 0, 0) -- 火焰特效有偏移，修正位置
    self:LoadEffect(resource.Asset)

    local easeMethod = function(f)
        return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, f)
    end

    local scale
    self.BurnTimer = XUiHelper.Tween(DieByTrapTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        scale = 1 - f
        self:SetGameObjScale(Vector3(scale, scale, scale))
    end, function()
        self:Init()
        self:ResetModel()
        self:Death()
    end, easeMethod)

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Burn)
end

function XRpgMakerGameGrassData:RemoveBurnTimer()
    if self.BurnTimer then
        XScheduleManager.UnSchedule(self.BurnTimer)
        self.BurnTimer = nil
    end
end

function XRpgMakerGameGrassData:RemoveBurnEffect()
    local path = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.Burn)
    self:RemoveResource(path)
end

--是否需要生长（模型是否需要显示）
function XRpgMakerGameGrassData:SetIsGrow(isGrow)
    self.IsGrow = isGrow
    self:RemoveBurnEffect()
end

--检查生长
function XRpgMakerGameGrassData:CheckPlayFlat()
    if not self.IsGrow then
        return
    end
    self:RemoveBurnTimer()
    self:Init()
    self:ResetModel()
    self:SetActive(false)
    self:SetActive(true)
    self.IsGrow = false
    self.IsBurned = false
end

function XRpgMakerGameGrassData:SetRoundState(round, state)
    self.RoundState[round] = state
end

--根据回合数检查非配置的草圃是否显示，并删除指定回合数以上的数据
function XRpgMakerGameGrassData:CheckRoundState(round)
    self:SetActive(false)

    local state
    local maxRound = 0  --比指定回合数小，且在缓存中的状态中最大的回合数
    for roundTemp, stateTemp in pairs(self.RoundState) do
        if roundTemp <= round and maxRound < roundTemp then
            maxRound = roundTemp
            state = stateTemp
        elseif roundTemp > round then
            self.RoundState[roundTemp] = nil
        end
    end

    if state == nil then
        state = false
    end
    self:SetActive(state)
end

function XRpgMakerGameGrassData:SetActive(state)
    if state then
        self:PlayGrowSound()
    end
    XRpgMakerGameGrassData.Super.SetActive(self, state)
end

function XRpgMakerGameGrassData:PlayGrowSound()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.RpgMakerGame_Grow)
end

function XRpgMakerGameGrassData:IsEmpty()
    return self.IsBurned == true
end

return XRpgMakerGameGrassData