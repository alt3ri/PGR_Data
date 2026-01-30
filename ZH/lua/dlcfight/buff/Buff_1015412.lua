local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015412 : XFightBase
local XBuffScript1015412 = XDlcScriptManager.RegBuffScript(1015412, "XBuffScript1015412", Base)

--效果说明：使受到冰伤的敌人脚下产生冰霜路径，自身在路径上时，造成的冰伤提升X%，路径持续10s（CD）

------------配置------------
local ConfigMissileIdDict = {
    [1015412] = 82000108,
    [1015436] = 82000109,
    [1015438] = 82000110,
    [1015440] = 82000111
}
local ConfigRuneIdDict = {
    [1015412] = 20412,
    [1015436] = 20436,
    [1015438] = 20438,
    [1015440] = 20440
}

function XBuffScript1015412:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.range = 1  --路径半径
    self.areaCnt = 10   --路径点数量
    self.durTime = 10   --生成路径的时间，每个路径点的寿命配置在子弹表里
    self.cd = 0.5         --路径生成间隔

    self.missileId = ConfigMissileIdDict[self._buffId]  --子弹id
    self.missileLevel = 1
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    self.targetId = 0

    ------------执行------------

    self.activeTimer = 0    --标记计时器
    self.cdTimer = 0        --路径点生成间隔计时器
end

---@param dt number @ delta time 
function XBuffScript1015412:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --当有标记存在时，判断时间，持续时间后删除，有标记时，定时向敌人脚底发射子弹
    --如果没有目标，无需走后续逻辑
    if self.targetId == 0 then
        return
    end
    if not self._proxy:CheckNpc(self.targetId) then
        return
    end
    --如果超过buff生效时间了，则重置self.targetId
    if self._proxy:GetNpcTime(self._uuid) > self.activeTimer then
        self.targetId = 0
        return
    end
    --处于生效时间内，则每间隔1秒，向敌人脚下发射一个路径的子弹
    if self._proxy:GetNpcTime(self._uuid) > self.cdTimer then
        local targetPos = self._proxy:GetNpcPosition(self.targetId)
        self._proxy:LaunchMissileFromPosToPos(self._uuid, self.missileId, self.missileId, targetPos, targetPos, self.missileLevel)
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.cd
    end
end

--region EventCallBack
function XBuffScript1015412:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015412:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --当存在目标时，不用走设定目标的逻辑
    if self.targetId ~= 0 then
        return
    end
    if elementType ~= 3 then
        return
    end
    --记录敌人的id，更新buff激活时间
    if launcherId == self._uuid then
        self.targetId = targetId
        self.activeTimer = self._proxy:GetNpcTime(self._uuid) + self.durTime --更新标记计时时间
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015412:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015412:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015412
