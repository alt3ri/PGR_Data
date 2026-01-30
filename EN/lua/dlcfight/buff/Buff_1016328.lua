local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016328 : XBuffBase
local XBuffScript1016328 = XDlcScriptManager.RegBuffScript(1016328, "XBuffScript1016328", Base)
--在战斗中入场失去{0}%生命值（不会低于1%），获取损失量的等值护盾，此后10秒内全伤害提升{1}%

function XBuffScript1016328:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016328, 1016329, 1016330, 1016331, 1016332}  --5个等级
    self.selfDamagePercent ={ 0.4, 0.4, 0.4, 0.4, 0.4}  --我方扣血
    self.currentSelfDamagePercent = 0
    self.currentBuffLevel = 0
    self.selfDamageMagic = 1016333
    self.shieldMagic = 1016334
    self.magicIds={1016335,1016336,1016337,1016338}   --全属性增伤效果

    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.timer = 0
    self.selfDamageAlready = 0
    self.startCd = 0.15  --和开幕扣血的相关buff略微错开时间，避免自杀暴毙
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

    --开局错开时间扣自己的血
    if self._proxy:GetNpcTime(self._uuid) >= self.timer then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.selfDamageMagic,self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.shieldMagic, self.currentBuffLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + 999999  --已打效果
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
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.startCd -- 错开buff时间

        --开局时获得该等级的参数，避免后续持续遍历
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.currentSelfDamagePercent = self.selfDamagePercent[thisLevel]
                self.currentBuffLevel = thisLevel;
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
    if eventArgs.Launcher == self._uuid and eventArgs.Target == self._uuid and eventArgs.Id == self.selfDamageMagic and self.selfDamageAlready == 0 then
        --防自杀检测生命是否小于预计值
        local lifePercent = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)  --当前生命值百分比
        local selfDamageCal = self.currentSelfDamagePercent * self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)  --预计扣血
        if lifePercent <= self.currentSelfDamagePercent then  --当前生命百分比是否小于要扣的百分比
            --如果是，扣血到1%
            selfDamageCal = (lifePercent-0.01) * self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
        end
        --改动伤害上下文
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, selfDamageCal, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
        self.selfDamageAlready = 1
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
