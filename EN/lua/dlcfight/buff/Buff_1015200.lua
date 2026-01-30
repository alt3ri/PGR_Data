local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015200 : XBuffBase
local XBuffScript1015200 = XDlcScriptManager.RegBuffScript(1015200, "XBuffScript1015200", Base)

--效果说明：受到攻击时（内置cd），【护盾强度】提升10点（上限4X点）

------------配置------------
local ConfigMagicIdDict = {
    [1015200] = 1015201,
    [1015255] = 1015256,
    [1015257] = 1015258,
    [1015259] = 1015260,
    [1016120] = 1016121
}
local ConfigRuneIdDict = {
    [1015200] = 20200,
    [1015255] = 20255,
    [1015257] = 20257,
    [1015259] = 20259,
    [1016120] = 20259
}

function XBuffScript1015200:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 3
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1
    self.count = 0
    self.maxCount = 4
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
    self.cdTimer = 0  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015200:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015200:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuffScript1015200:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if not self._proxy:IsNpcDead(self._uuid) and self.count < self.maxCount and targetId == self._uuid then
        if self._proxy:GetNpcTime(self._uuid) >= self.cdTimer then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD
            self.count = self.count + 1
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015200:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015200:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015200

    