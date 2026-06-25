local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10272040 : XTheatre6SkillBase
local XBuffScript10272040 = XDlcScriptManager.RegBuffScript(10272040, "XBuffScript10272040", XTheatre6SkillBase)

--效果说明：自身每次【体力值】归零时触发：
--· 耗尽自身【护盾】，每消耗1点【护盾】，额外造成2点伤害；
--· 耗尽自身<坚毅>层数，每消耗1层，伤害倍率提升70%；

function XBuffScript10272040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self.dmgMagicId = 10270151 --临时伤害id，要换
    self.dmgExtraMagicId = 10270126 --由magic造成的附加伤害id，要换
    self.BlockBuffId = 1025105
    self.dmgTriggerBlock = false --是否有格挡增伤
    self.dmgTriggerProtector = false --是否有护盾增伤
    self.ExtraDmg = 0 --附加伤害
    self.DmgPerProtector = 2 --每点护盾转伤
    self.DmgPerBlock = 7000 --每层格挡转倍率
end

function XBuffScript10272040:InitEventCallBackRegister()
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
end

function XBuffScript10272040:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    if self.originAttrib1 <= 0 then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
            self.ChanceCheck = 1
        end
    else
        self.ChanceCheck = 0
    end
end

function XBuffScript10272040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib2 = self._proxy:GetNpcProtector(self._npcUUID) --取一下玩家的护盾值
    if self.originAttrib2 > 0 then
        self._proxy:RemoveProtector() --清除护盾
        self.dmgTriggerProtector = true
        self._proxy:ApplyMagic(self._npcUUID,self._enemyUUID,self.dmgExtraMagicId, 1, 0, 1) --对敌人造成一次附加伤害
    end
    self.originAttrib3 = self._proxy:GetBuffCountByKind(self._npcUUID,self.BlockBuffId) --取格挡层数
    if self.originAttrib3 > 0 then
        self._proxy:RemoveBuff(self._npcUUID,self.BlockBuffId) --清除格挡
        self.dmgTriggerBlock = true
    end
end

function XBuffScript10272040:BeforeDamageCalc(eventArgs)
    if not self.dmgTriggerBlock then return end
    if eventArgs.Launcher ~= self._npcUUID then return end
    if self.originAttrib3 > 0 then
        if eventArgs.Id ~= self.dmgMagicId then return end --因格挡造成的伤害倍率提升
        local extraDamage = self.originAttrib3 * self.DmgPerBlock
        local finalPermyriad = extraDamage + eventArgs.PhysicalPermyriad
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
        self.dmgTriggerBlock = false
    end
end

function XBuffScript10272040:AfterDamageCalc(eventArgs)
    if not self.dmgTriggerProtector then return end
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self.dmgExtraMagicId then return end --因护盾造成的附加伤害
    if self.originAttrib2 <= 0 then return end

    self.ExtraDmg = self.originAttrib2 * self.DmgPerProtector
    if self._proxy:GetBuffCountByKind(self._npcUUID,1025800) >= 1 then
        local DmgReduce = 1
        DmgReduce = DmgReduce * (1 + self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.PhysicalAmpP) / 10000)
        DmgReduce = DmgReduce * (1 - self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.PhysicalReductionP) / 10000)
        --self:LogError(".....打印下最终减伤"..DmgReduce)
        self._pendingExtraDamage = self._pendingExtraDamage * DmgReduce -- 存在PVP全减伤50%的特殊处理，伤害减半
        --self:LogError(".....触发减伤通知")
    end

    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.ExtraDmg, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    self.dmgTriggerProtector = false
end

function XBuffScript10272040:Terminate()
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
    XTheatre6SkillBase.Terminate(self)
end


return XBuffScript10272040
