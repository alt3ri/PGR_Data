local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015110 : XBuffBase
local XBuffScript1015110 = XDlcScriptManager.RegBuffScript(1015110, "XBuffScript1015110", Base)

--效果说明：2秒内没受到攻击时，增加【雷属性伤害提升】X%

------------配置------------
local ConfigMagicIdDict = {
    [1015110] = 1015111,
    [1015142] = 1015143,
    [1015144] = 1015145,
    [1015146] = 1015147,
    [1016108] = 1016109
}
local ConfigRuneIdDict = {
    [1015110] = 20110,
    [1015142] = 20142,
    [1015144] = 20144,
    [1015146] = 20146,
    [1016108] = 20146
}

function XBuffScript1015110:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]
    self.magicLevel = 1
    self.isHit = true
    self.hitCd = 0.5
    self.hitTimer = 0
    self.isAdd = false
    self.runeId = ConfigRuneIdDict[self._buffId]
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015110:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 2秒不被揍归零受击
    if self.isHit and self._proxy:GetNpcTime(self._uuid) - self.hitTimer >= self.hitCd then
        self.isHit = false
    end

    -- 正常上buff
    if not self.isHit and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.isAdd = true
    end
end

--region EventCallBack
function XBuffScript1015110:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015110:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    -- 判断吃了伤害后自己会不会死
    if not self._proxy:IsNpcDead(self._uuid) then
        -- 当受到伤害的npc是玩家npc时
        if targetId == self._uuid then
            self.isHit = true
            -- 获取本次受击时间
            self.hitTimer = self._proxy:GetNpcTime(self._uuid)
            -- 移除buff
            self._proxy:RemoveBuff(self._uuid, self.magicId)
            self.isAdd = false
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015110:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015110:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015110

    