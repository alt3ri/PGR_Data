local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016018 : XBuffBase
local XBuffScript1016018 = XDlcScriptManager.RegBuffScript(1016018, "XBuffScript1016018", Base)
--效果说明：失去生命，并对敌人造成等值伤害，持续10秒

function XBuffScript1016018:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1016028
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.damageRate = 0.05
    self.timer = 0
    self.stopTimer = 0
    self.cd = 1
    self.effTime = 10.5   --延迟0.5秒结束，避免伤害段数被吞
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016018:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end
    if not self._proxy:CheckNpc(self.targetId) then
        return
    end
    if self._proxy:GetNpcTime(self._uuid) > self.stopTimer then
        return
    end
    if self._proxy:GetNpcTime(self._uuid) >= self.timer then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
        self._proxy:ApplyMagic(self._uuid,self.targetId,self.magicId,self.magicLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
    end

end

--region EventCallBack
function XBuffScript1016018:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1016018:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
        self.stopTimer = self._proxy:GetNpcTime(self._uuid) + self.effTime

    end
end

function XBuffScript1016018:AfterDamageCalc(eventArgs)
    if eventArgs.Launcher == self._uuid and eventArgs.Id==self.magicId then
        local damage = self.damageRate * self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, damage, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016018:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016018:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016018
