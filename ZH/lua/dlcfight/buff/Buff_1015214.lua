local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015214 : XBuffBase
local XBuffScript1015214 = XDlcScriptManager.RegBuffScript(1015214, "XBuffScript1015214", Base)

--效果说明：获得护盾时，提升50的冰火雷伤，持续2秒

------------配置------------
local ConfigMagicIdDict1 = {
    [1015214] = 1015240,
    [1015261] = 1015262,
    [1015265] = 1015266,
    [1015269] = 1015270,
    [1016122] = 1016123,
}
local ConfigMagicIdDict2 = {
    [1015214] = 1015241,
    [1015261] = 1015263,
    [1015265] = 1015267,
    [1015269] = 1015271,
    [1016122] = 1016124
}
local ConfigMagicIdDict3 = {
    [1015214] = 1015242,
    [1015261] = 1015264,
    [1015265] = 1015268,
    [1015269] = 1015272,
    [1016122] = 1016125
}
local ConfigRuneIdDict = {
    [1015214] = 20214,
    [1015261] = 20261,
    [1015265] = 20265,
    [1015269] = 20269,
    [1016122] = 20270
}

function XBuffScript1015214:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = ConfigMagicIdDict1[self._buffId]
    self.magicId2 = ConfigMagicIdDict2[self._buffId]
    self.magicId3 = ConfigMagicIdDict3[self._buffId]
    self.magicLevel = 1
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015214:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015214:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)           -- OnNpcAddBuffEvent
end

function XBuffScript1015214:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue,MagicId)
    if TargetId == self._uuid then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId2, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId3, self.magicLevel)
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015214:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015214:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015214

    