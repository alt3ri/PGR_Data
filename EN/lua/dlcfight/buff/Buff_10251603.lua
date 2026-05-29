local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 累计造成12次攻击伤害时触发：
--  · 造成180%攻击伤害；
--  · 自身每有40点【体力值】，扣除10点【体力值】，造成1层<点燃>。
---@class XBuffScript.10251603 : XTheatre6SkillBase
local XBuff10251603 = XDlcScriptManager.RegBuffScript(10251603, "XBuffScript10251603", XTheatre6SkillBase)

function XBuff10251603:ScriptInit(isGainControl) --初始化
    ---伤害计次
    self.damageCount = 0
    self.targetCount = 12
    ---获取体力BuffId
    self.costStaminaBase = 10 --每层触发消耗的体力数量
end

function XBuff10251603:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuff10251603:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType,
                                        realDamage, isCritical)
    if launcherId ~= self._npcUUID then return end
    -- if targetId ~= self._enemyUUID then return end
    self.damageCount = self.damageCount + 1
    if self.damageCount >= 12 then
        self.damageCount = 0
        self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
    end
end

function XBuff10251603:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hasChangedDamage = false
    local effectStacks = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina) // 40
    local costStamina = effectStacks * self.costStaminaBase
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -costStamina, 0)
    self:GetEnemyNpc():GetBurnController():CastStackBuff(effectStacks, self._enemyUUID)
end

return XBuff10251603
