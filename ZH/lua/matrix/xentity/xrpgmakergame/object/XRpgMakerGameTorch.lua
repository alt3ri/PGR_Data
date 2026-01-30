local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

---推箱子火炬对象
---@class XRpgMakerGameTorch:XRpgMakerGameObject
local XRpgMakerGameTorch = XClass(XRpgMakerGameObject, "XRpgMakerGameTorch")

function XRpgMakerGameTorch:Ctor(id, gameObject)

end

-- 设置位置
function XRpgMakerGameTorch:SetPosition(posX, posY)
    self.PosX = posX
    self.PosY = posY
end

-- 获取坐标X
function XRpgMakerGameTorch:GetPosX()
    return self.PosX
end

-- 获取坐标Y
function XRpgMakerGameTorch:GetPosY()
    return self.PosY
end

-- 设置状态
function XRpgMakerGameTorch:SetState(state)
    self.State = state
    self:GetFireGo():SetActiveEx(false) -- 不用模型上的火焰，使用特效火焰

    -- 熄灭
    if state == XMVCA.XRpgMakerGame.EnumConst.TorchStateType.Inactive then
        self:RemoveDisappearEffect()
        self:RemoveFireEffectPath()
        self.GameObject.gameObject:SetActiveEx(true)
    -- 激活
    elseif state == XMVCA.XRpgMakerGame.EnumConst.TorchStateType.Active then
        self:RemoveDisappearEffect()
        self.GameObject.gameObject:SetActiveEx(true)

        self.FireEffectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TorchBurnEffect)
        local resource = self:ResourceManagerLoad(self.FireEffectPath)
        self:LoadEffect(resource.Asset)
    -- 消失
    elseif state == XMVCA.XRpgMakerGame.EnumConst.TorchStateType.Disappear then
        self.GameObject.gameObject:SetActiveEx(false)
        
        self.DisappearEffectPath = XMVCA.XRpgMakerGame:GetConfig():GetModelPath(XMVCA.XRpgMakerGame.EnumConst.ModelKeyMaps.TorchDisappearEffect)
        local resource = self:ResourceManagerLoad(self.DisappearEffectPath)
        local sceneObjRoot = XDataCenter.RpgMakerGameManager.GetCurrentScene():GetSceneObjRoot()
        self:LoadEffect(resource.Asset, self.Transform.position, sceneObjRoot)
    end
end

-- 移除火焰特效
function XRpgMakerGameTorch:RemoveFireEffectPath()
    if self.FireEffectPath then
        self:RemoveResource(self.FireEffectPath)
        self.FireEffectPath = nil
    end
end

-- 移除消失特效
function XRpgMakerGameTorch:RemoveDisappearEffect()
    if self.DisappearEffectPath then
        self:RemoveResource(self.DisappearEffectPath)
        self.DisappearEffectPath = nil
    end
end

-- 获取火焰
function XRpgMakerGameTorch:GetFireGo()
    if not self.FireGameObject then
        local prefab = self.Transform:GetChild(0) -- 火炬预制体
        self.FireGameObject = prefab:GetChild(0).gameObject -- 火焰
    end
    return self.FireGameObject
end

-- 重置关卡
function XRpgMakerGameTorch:OnStageReset()
    local scene = XDataCenter.RpgMakerGameManager.GetCurrentScene()
    local mapId = scene:GetMapId()
    local dataList = XMVCA.XRpgMakerGame:GetConfig():GetMixBlockDataListByPosition(mapId, self:GetPosX(), self:GetPosY())
    local state = 0
    for _, data in pairs(dataList) do
        if data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Torch then
            state = data:GetParams()[1] or 0
        end
    end
    
    -- 设置状态
    self:SetState(state)
end

function XRpgMakerGameTorch:IsEmpty()
    return self.State ~= XMVCA.XRpgMakerGame.EnumConst.TorchStateType.Disappear
end

return XRpgMakerGameTorch