local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015024 : XBuffBase
local XBuffScript1015024 = XDlcScriptManager.RegBuffScript(1015024, "XBuffScript1015024", Base)

--效果说明：每次对敌人造成火伤，提升自身【火属性伤害提升】X点，持续10s，上限4X点

------------配置------------
local ConfigMagicIdDict = {
    [1015024] = 1015025,
    [1015058] = 1015059,
    [1015060] = 1015061,
    [1015062] = 1015063,
    [1016106] = 1016107
}
local ConfigRuneIdDict = {
    [1015024] = 20024,
    [1015058] = 20058,
    [1015060] = 20060,
    [1015062] = 20062,
    [1016106] = 20062
}

function XBuffScript1015024:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]
    self.magicKind = ConfigMagicIdDict[self._buffId]
    self.magicLevel = 1
    self.magicMaxLevel = 4
    self.runeId = ConfigRuneIdDict[self._buffId]
    ------------执行------------ 
end

---@param dt number @ delta time 
function XBuffScript1015024:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015024:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015024:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    -- 对方受击
    if targetId ~= self._uuid then
        -- 判断是否是火属性伤害
        if elementType == 1 then
            -- 上buff
            if not self._proxy:CheckBuffByKind(self._uuid, self.magicKind) then
                self.magicLevel = 1
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
                self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            else
                self.magicLevel = self.magicLevel + 1
                if self.magicLevel <= self.magicMaxLevel then
                    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                    self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
                    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
                else
                    self.magicLevel = self.magicMaxLevel
                    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                    self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
                    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
                end
            end
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015024:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015024:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015024

    