local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---【超算】成功后，造成50%攻击伤害。
---扣除对手20点【体力值】；
---【超算】属性>230点时，伤害额外提高100%攻击。
---@class XBuffScript.10264030 : XTheatre6SkillBase
local XBuff10264030 = XDlcScriptManager.RegBuffScript(10264030, "XBuffScript10264030", XTheatre6SkillBase)

function XBuff10264030:ScriptInit(isGainControl) --初始化
    ---【击飞】计数
    self.hitFlyCount = 0
    self.staminaDamage = 25
    self.extraPermyriad = 10000
    self.targetOverClockThreshold = 230
    self._damageMagicId = 10250017
end

function XBuff10264030:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuff10264030:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    ---如果超算属性达标
    if self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) > self.targetOverClockThreshold then
        local finalPermyriad = self.extraPermyriad + eventArgs.PhysicalPermyriad
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    end
end

function XBuff10264030:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -self.staminaDamage,0)
end


return XBuff10264030
