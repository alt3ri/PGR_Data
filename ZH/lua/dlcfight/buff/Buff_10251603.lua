local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---累计造成x次攻击伤害时触发：调用技能，自身每有40点【体力值】，扣除10点【体力值】，造成1层<点燃>。
---@class XBuffScript.10251603 : XTheatre6SkillBase
local XBuff10251603 = XDlcScriptManager.RegBuffScript(10251603, "XBuffScript10251603", XTheatre6SkillBase)

function XBuff10251603:ScriptInit(isGainControl) --初始化
    ---伤害计次
    self.damageCount = 0
    self.targetCount = 12
    ---获取体力BuffId
    self._buffId = 10250011
    self.originAttrib1 = 0
    self.originAttrib2 = 0
    self.originAttrib3 = 0
    --self:LogError(".....目标插入式技能7注册完成")
    self._exDamageRate_L1 = 2000
    self._exDamageRate_L2 = 3000
    self._exDamageRate_L3 = 4000
    self._damageMagicId = 10250035
end

function XBuff10251603:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuff10251603:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if launcherId ~= self._npcUUID then return end
    -- if targetId ~= self._enemyUUID then return end
    self.damageCount = self.damageCount + 1
    if self.damageCount >= 12 then
        self.damageCount = 0
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)                    --调用技能
        --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self._buffId, self._level) --恢复体力值的buff
    end
end


function XBuff10251603:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --self:LogError(".....打印技能id"..self._skillId)
    self._hasChangedDamage = false
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) // 40
    self.originAttrib2 = self.originAttrib1 * 10
    self.originAttrib3 = self.originAttrib3 + self.originAttrib2
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -self.originAttrib2, 0)
    self:GetEnemyNpc():GetBurnController():CastStackBuff(self.originAttrib1, self._enemyUUID)
end

--function XBuff10251603:ChangeDamageBeforeCalc(eventArgs)
    --if eventArgs.Launcher ~= self._npcUUID then return end
    --if eventArgs.Id ~= self._damageMagicId then return end
    --if self._hasChangedDamage then return end
    --if self._skillId == 10252071 then
        --local FinalDMGRate = eventArgs.PhysicalPermyriad + ( self._exDamageRate_L1 * self.originAttrib3 )
        --self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
        --self._hasChangedDamage = true
    --else
        --if self._skillId == 10252072 then
        --local FinalDMGRate = eventArgs.PhysicalPermyriad + ( self._exDamageRate_L2 * self.originAttrib3 )
        --self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
        --self._hasChangedDamage = true
        --else
            --local FinalDMGRate = eventArgs.PhysicalPermyriad + ( self._exDamageRate_L3 * self.originAttrib3 )
            --self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
            --self._hasChangedDamage = true
        --end
    --end
--end

return XBuff10251603
