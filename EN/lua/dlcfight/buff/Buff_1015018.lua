local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015018 : XBuffBase
local XBuffScript1015018 = XDlcScriptManager.RegBuffScript(1015018, "XBuffScript1015018", Base)

--效果说明：目标在自身周围1m内时，每秒检查1次，自身获得火伤加成X，可叠加2次，自身周围没有敌人时清空加成

------------配置------------
local ConfigMagicIdDict = {
    [1015018] = 1015019,
    [1015046] = 1015047,
    [1015048] = 1015049,
    [1015050] = 1015051,
    [1016102] = 1016103
}
local ConfigRuneIdDict = {
    [1015018] = 20018,
    [1015046] = 20046,
    [1015048] = 20048,
    [1015050] = 20050,
    [1016102] = 20050
}

function XBuffScript1015018:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicRange = 2     --magic生效范围
    self.triggerCD = 1      --检查位置的CD，Buff持续时间为1s
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 0     --magic等级
    self.magicMaxLevel = 2 --magic最大等级
    self.runeId = ConfigRuneIdDict[self._buffId]    --宝珠id，用于ui和记录次数
    ------------执行------------
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015018:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --每秒判断1次距离，在距离内则+1，不在则清零
    --CD没有冷却好时，返回
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then
        return
    end
    --如果在距离内，则等级加1，更新Buff，如果不在距离内，则重置Buff等级
    local enemyId = self._proxy:GetFightTargetId(self._uuid)

    if enemyId == 0 then
        return
    end

    if self._proxy:CheckNpcDistance(self._uuid, enemyId, self.magicRange) then
        self.magicLevel = self.magicLevel + 1
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, math.min(self.magicLevel, self.magicMaxLevel))
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    else
        self._proxy:RemoveBuff(self._uuid,self.magicId)
        self.magicLevel = 0
    end
    --更新计时器
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015018:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015018:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015018
