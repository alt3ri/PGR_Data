local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016322 : XBuffBase
local XBuffScript1016322 = XDlcScriptManager.RegBuffScript(1016322, "XBuffScript1016322", Base)
--效果说明：失去生命，并对敌人造成伤害，持续10秒

function XBuffScript1016322:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016322, 1016323, 1016324, 1016325, 1016326}  --5个等级
    self.selfDamagePercent ={ 0.03, 0.04, 0.05, 0.05, 0.05}  --我方扣血
    self.enemyDamageRate ={ 1, 1, 1, 1.15, 1.3}  --扣血转伤害倍率
    self.damageToMyself = 0
    self.damageToEnemy = 0

    self.damageMagic = 1016327 --刀刀我自己
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.timer = 0
    self.stopTimer = 0
    self.cd = 1
    self.effTime = 10.5   --延迟0.5秒结束，避免伤害段数被吞
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016322:Update(dt)
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
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.damageMagic,self.magicLevel)
        self._proxy:ApplyMagic(self._uuid,self.targetId,self.damageMagic,self.magicLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
    end

end

--region EventCallBack
function XBuffScript1016322:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1016322:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
        self.stopTimer = self._proxy:GetNpcTime(self._uuid) + self.effTime

        --开局时获得该等级的参数，避免后续持续遍历
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.damageToMyself = self.selfDamagePercent[thisLevel] * self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
                self.damageToEnemy = self.damageToMyself * self.enemyDamageRate[thisLevel]
                return
            end
        end
    end

end

function XBuffScript1016322:AfterDamageCalc(eventArgs)
    --防自杀检测生命是否大于1%
    local isLifeMoreThanOnePercent = (self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Life)/self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)) >= 0.01

    if isLifeMoreThanOnePercent and eventArgs.Launcher == self._uuid and eventArgs.Id == self.damageMagic then
        if eventArgs.Target == self._uuid then
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.damageToMyself, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
        elseif eventArgs.Target == self.targetId then
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.damageToEnemy, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016322:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016322:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016322
