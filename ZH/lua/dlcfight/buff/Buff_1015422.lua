local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015422 : XBuffBase
local XBuffScript1015422 = XDlcScriptManager.RegBuffScript(1015422, "XBuffScript1015422", Base)

--效果说明：移动或位移时，将积攒层数，层数到100时，下一次伤害消耗全部层数，冰伤提升X%

------------配置------------
local ConfigMagicIdDict = {
    [1015422] = 1015423,
    [1015442] = 1015443,
    [1015444] = 1015445,
    [1015446] = 1015447,
    [1016138] = 1016139
}
local ConfigRuneIdDict = {
    [1015422] = 20422,
    [1015442] = 20442,
    [1015444] = 20444,
    [1015446] = 20446,
    [1016138] = 20446
}

function XBuffScript1015422:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]
    self.magicKind = ConfigMagicIdDict[self._buffId]
    self.magicLevel = 1
    self.accMove = 0
    self.targetMove = 10        --触发效果所需的位移距离
    self.isAdd = false
    self.getPosTrigger = true
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015422:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if self.getPosTrigger then
        self.historyPos = self._proxy:GetNpcPosition(self._uuid)
        self.getPosTrigger = false
    end

    if not self.isAdd then
        self.accMove = self._proxy:GetNpcToPositionDistance(self._uuid, self.historyPos, true) + self.accMove
        self.historyPos = self._proxy:GetNpcPosition(self._uuid)
        if self.accMove >= self.targetMove then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            self.isAdd = true
        end
    end
end

--region EventCallBack
function XBuffScript1015422:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015422:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if self.isAdd and elementType == 3 then
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        self.isAdd = false
        self.accMove = 0
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015422:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015422:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015422

    