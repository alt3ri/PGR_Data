local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016339 : XBuffBase
local XBuffScript1016339 = XDlcScriptManager.RegBuffScript(1016339, "XBuffScript1016339", Base)
--效果说明：脱离浑身时，根据触发技能次数出结算伤

function XBuffScript1016339:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016339, 1016340, 1016341, 1016342, 1016343}  --5个等级
    self.skillCountInCal={1,1,1,1,1}  --每制造x次伤害
    self.damageCal={1, 1.5, 1.75, 2, 2.25} --直接出伤
    self.currentDamageCal = 0
    self.damageMagic = 1016344

    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.magicLevel = 1
    self.damageAlready = 0
    self.skillCounter = 0 -- ==999时，已结算
    ------------执行------------

end
---@param dt number @ delta time
function XBuffScript1016339:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    local percentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)

    --生命值首次满足触发要求时，出伤
    if percentHp < 0.8 and self.damageAlready == 0 then

        --获得该等级的参数
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.currentDamageCal = self.damageCal[thisLevel]
                local magicTimes = math.min(5, math.floor(self.skillCounter / self.skillCountInCal[thisLevel]))
                for _ = 1, magicTimes do
                    self._proxy:ApplyMagic(self._uuid, self.targetId, self.damageMagic, self.magicLevel)
                end
            end
        end
        self.skillCounter = 999
        self.damageAlready = 1

    end


end

--region EventCallBack
function XBuffScript1016339:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
    self._proxy:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)              --注册技能释放事件
end

function XBuffScript1016339:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
    end

end

function XBuffScript1016339:HandleLuaEvent(eventType, eventArgs)
    --自定义事件
    Base.HandleLuaEvent(self, eventType, eventArgs)
    if eventType == EFightLuaEvent.AutoChessItemSkillComboStart then
        if self.skillCounter < 999 and eventArgs.NpcUUid == self._uuid then
            self.skillCounter = self.skillCounter + 1
        end
    end

end

function XBuffScript1016339:AfterDamageCalc(eventArgs)
    --出伤修正
    if eventArgs.Launcher == self._uuid and eventArgs.Target == self.targetId and eventArgs.Id == self.damageMagic then
        local thisDamageCal = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Attack) * self.currentDamageCal
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, thisDamageCal , eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    end

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016339:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016339:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016339
