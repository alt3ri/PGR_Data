local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015400 : XBuffBase
local XBuffScript1015400 = XDlcScriptManager.RegBuffScript(1015400, "XBuffScript1015400", Base)

--效果说明：造成冰属性伤害后，使下一次造成冰属性伤害提升X%（内置CD）

------------配置------------
local ConfigMagicIdDict = {
    [1015400] = 1015401,
    [1015448] = 1015449,
    [1015450] = 1015451,
    [1015452] = 1015453,
    [1016140] = 1016141
}
local ConfigRuneIdDict = {
    [1015400] = 20400,
    [1015448] = 20448,
    [1015450] = 20450,
    [1015452] = 20452,
    [1016140] = 20452
}

function XBuffScript1015400:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1          --Buff等级
    self.triggerCD = 1          --施加增伤效果的最小CD
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
    self.cdTimer = 0  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015400:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015400:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015400:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --当有Npc受到伤害时
    --如果不是自己造成伤害，不用继续
    if not (self._uuid == launcherId) then
        return
    end

    --是否冰属性 0物理、1火/2雷/3冰/4暗
    if not (elementType == 3) then
        return
    end

    --检查是否有增伤Buff
    if self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        self._proxy:RemoveBuff(self._uuid, self.magicId)      --删除增伤Buff
        return      --如果有增伤Buff，删除Buff后直接返回
    end

    --如果没有增伤buff，检查CD，CD好了的话加新buff
    if self._proxy:GetNpcTime(self._uuid) >= self.cdTimer then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)  --挂上增伤Buff
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015400:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015400:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015400
