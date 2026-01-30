local Base = require("Common/XFightBase")

---@class XBuffScript1015324 : XFightBase
local XBuffScript1015324 = XDlcScriptManager.RegBuffScript(1015324, "XBuffScript1015324", Base)

--效果说明：1秒内未受到攻击时，回复效率提升50点，受到攻击后移除
function XBuffScript1015324:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015325
    self.magicLevel = 1
    self.isHit = true
    self.hitCd = 1
    self.hitTimer = 0
    self.isAdd = false
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015324:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 1秒不被揍归零受击
    if self.isHit and self._proxy:GetNpcTime(self._uuid) - self.hitTimer >= self.hitCd then
        self.isHit = false
    end

    -- 正常上buff
    if not self.isHit and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.isAdd = true
    end
end

--region EventCallBack
function XBuffScript1015324:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015324:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
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
function XBuffScript1015324:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015324:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015324

    