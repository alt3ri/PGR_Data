local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1056020 : XBuffBase
local XBuffScript1056020 = XDlcScriptManager.RegBuffScript(1056020, "XBuffScript1056020", Base)

--效果说明：剑损buff逻辑，存在buff时，buff增加2秒，不存在buff时，buff设置为2秒。buff效果为易且每秒造成伤害。

function XBuffScript1056020:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self, isGainControl)
    ------------配置------------
    self.AddTime = 1
    self.damageTime = 1          --增加时间
    self.isDamageApply = false

    ------------执行------------
    self.damageTimer = self._proxy:GetFightTime() + self.damageTime    --造成伤害时间

    if isGainControl then
        local hasKey, val = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid, 1056020)
        if hasKey then
            self.damageTimer = val
        end
    else
        self._proxy:RegisterBBSync(XVarDomain.Npc, self._uuid, 1056020)
        self._proxy:SetBBFloat(XVarDomain.Npc, self._uuid, 1056020, self.damageTimer)
    end
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

---@param dt number @ delta time 
function XBuffScript1056020:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if (self._proxy:GetFightTime() > self.damageTimer) then
        if self._proxy:CheckNpc(self._casterUUID) then
            self._proxy:ApplyMagic(self._casterUUID,self._uuid,1056021)
            self._proxy:ApplyMagic(self._casterUUID,self._uuid,1056038)
        end
        self.damageTimer = self._proxy:GetFightTime() + self.damageTime
        self._proxy:SetBBFloat(XVarDomain.Npc, self._uuid, 1056020, self.damageTimer)
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1056024,1)
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1056025,1)

        if (self._proxy:GetBuffStacks(self._uuid,1056024) <1 and self._proxy:GetBuffStacks(self._uuid,1056025) <1) then
            self._proxy:RemoveBuff(self._uuid,1056020)
        end
    end
end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1056020:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1056020:Terminate()
    Base.Terminate(self)
end

function XBuffScript1056020:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --删除buff事件
    -- if (buffId == 1056022) then
    --     self._proxy:RemoveBuffByKindAndCount(self._uuid,1056020,0)
    -- end     
end

return XBuffScript1056020
