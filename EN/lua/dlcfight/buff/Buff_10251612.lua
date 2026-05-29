local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 【超算】成功后，造成200%攻击伤害。
--  · 扣除对手20点【体力值】；
--  · 【超算】属性>230点时，伤害额外提高100%攻击。
---@class XBuffScript.10251612 : XTheatre6SkillBase
local XBuff10251612 = XDlcScriptManager.RegBuffScript(10251612, "XBuffScript10251612", XTheatre6SkillBase)

function XBuff10251612:ScriptInit(isGainControl) --初始化
    self.staminaDamage = 20                      --体力伤害
    self.extraPermyriad = 10000                  --增伤倍率
    self.targetOverClockThreshold = 230          --目标超算属性
    self._damageMagicId = 10250017               --伤害magicid
    self.triggerPermyriad = false                --增伤开关
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuff10251612:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuff10251612:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.triggerPermyriad = true
end

function XBuff10251612:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if not self.triggerPermyriad then return end
    ---如果超算属性达标
    if self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) > self.targetOverClockThreshold then
        local finalPermyriad = self.extraPermyriad + eventArgs.PhysicalPermyriad
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad,
            eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.IsCrit)
        self.triggerPermyriad = false
    end
end

function XBuff10251612:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -self.staminaDamage, 0)
end

return XBuff10251612
