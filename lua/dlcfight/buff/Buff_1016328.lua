local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016328 : XBuffBase
local XBuffScript1016328 = XDlcScriptManager.RegBuffScript(1016328, "XBuffScript1016328", Base)
--效果说明：失去生命，并对敌人造成伤害，持续10秒

function XBuffScript1016328:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016328, 1016329, 1016330, 1016331, 1016332}  --5个等级
    self.selfDamagePercent ={ 0.4, 0.4, 0.4, 0.4, 0.4}  --我方扣血
    self.buffLevel = 0
    self.selfDamageMagic = 1016333
    self.shieldMagic = 1016334
    self.magicIds={1016335,1016336,1016337,1016338}   --全属性增伤效果

    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.timer = 0
    self.stopTimer = 0
    self.startCd = 0.15  --和开幕扣血的相关buff略微错开时间，避免自杀暴毙
    self.effTime = 10.5   --延迟0.5秒结束，避免伤害段数被吞
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016328:Update(dt)
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

    --超出计时器时间后，删除增伤效果
    if self._proxy:GetNpcTime(self._uuid) > self.stopTimer then
        for _, magicId in ipairs(self.magicIds) do
            self._proxy:RemoveBuff(self._uuid,magicId)
        end
        self.stopTimer = self._proxy:GetNpcTime(self._uuid) + 999  --已打效果
    end

    --开局错开时间扣自己的血
    if self._proxy:GetNpcTime(self._uuid) >= self.timer then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.damageMagic,self.magicLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + 999  --已打效果
    end


end

--region EventCallBack
function XBuffScript1016328:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1016328:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd -- 错开buff时间
        self.stopTimer = self._proxy:GetNpcTime(self._uuid) + self.effTime

        --开局时获得该等级的参数，避免后续持续遍历
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.buffLevel = thisLevel
                --把增伤效果全套上去
                for _, magicId in ipairs(self.magicIds) do
                    self._proxy:ApplyMagic(self._uuid,self._uuid,magicId, thisLevel)
                end
                return
            end
        end
    end
end

function XBuffScript1016328:AfterDamageCalc(eventArgs)
    if eventArgs.Launcher == self._uuid and eventArgs.targetId == self._uuid and eventArgs.Id == self.damageMagic then

        --防自杀检测生命是否小于预计值
        local lifePercent = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Life) / self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
        local selfDamageCal = self.selfDamagePercent[self.buffLevel] * self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
        if lifePercent <= self.selfDamagePercent[self.buffLevel] then
            --如果是，扣血到1%
            selfDamageCal = (lifePercent-0.01) * self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
        end

        --改动伤害上下文
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, selfDamageCal, eventArgs.ElementDamage, eventArgs.FinalHackDamage)

    end
end

function XBuffScript1016328:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if launcherId == self._uuid and targetId == self._uuid and magicId == self.selfDamageMagic then
        -- 添加护盾
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.shieldMagic, self.buffLevel)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016328:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016328:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016328
